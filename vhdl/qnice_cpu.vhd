----------------------------------------------------------------------------------
-- FPGA implementation of the QNICE 16 bit CPU architecture version 1.7
-- 
-- done in 2015, 2016, 2020 by sy2002
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.cpu_constants.all;

entity QNICE_CPU is
port (
   -- clock
   CLK            : in std_logic;
   RESET          : in std_logic;
   
   WAIT_FOR_DATA  : in std_logic;                           -- 1=CPU adds wait cycles while re-reading from bus
   
   ADDR           : out std_logic_vector(15 downto 0);      -- 16 bit address bus
   
   -- bidirectional 16 bit data bus
   DATA_IN        : in std_logic_vector(15 downto 0);       -- receive data
   DATA_OUT       : out std_logic_vector(15 downto 0);      -- send data
   DATA_DIR       : out std_logic;                          -- 1=DATA is sending, 0=DATA is receiving
   DATA_VALID     : out std_logic;                          -- while DATA_DIR = 1: DATA contains valid data
   
   -- signals about the CPU state
   HALT           : out std_logic;                          -- 1=CPU halted due to the HALT command, 0=running
   INS_CNT_STROBE : out std_logic;                          -- goes high for one clock cycle for each new instruction
   
   -- interrupt system                                      -- refer to doc/intro/qnice_intro.pdf to learn how this works
   INT_N          : in std_logic   := '1';
   IGRANT_N       : out std_logic
);
end QNICE_CPU;

architecture beh of QNICE_CPU is

-- CPU's main state machine
type tCPU_States is (cs_reset,
                     
                     cs_fetch,

                     -- depending of adressing modes of the instruction, we
                     -- have a variable length execution that either jumps
                     -- directly from cs_decode to cs_execute (src and dst adressing
                     -- are direct) or run through either one of or both of the
                     -- cs_exeprep_get_* states
                     cs_decode,
                     
                     cs_exeprep_get_src_indirect,
                     cs_exeprep_get_dst_indirect,
                     
                     cs_execute,
                     
                     cs_exepost_store_dst_indirect,

                     cs_exepost_sub,                     
                     cs_exepost_prepfetch,
                     
                     cs_halt,
                     
                     -- interrupt handling
                     cs_int_wait_isr,           -- wait for ISR address to be put on the data bus
                     cs_int_jmp_isr,            -- read ISR address from data bus and prepare to "jump" into the ISR
                     cs_int_indirect_isr,       -- indirect ISR adress
                     
                     -- continue with standard sequence, used by fsmNextCpuState
                     cs_std_seq     
                    );
signal cpu_state           : tCPU_States := cs_reset;
signal cpu_state_next      : tCPU_States;

-- CPU i/o signals
signal ADDR_Bus            : std_logic_vector(15 downto 0) := (others => '0');
signal DATA_To_Bus         : std_logic_vector(15 downto 0) := (others => '0');

-- register bank signals for accessing R0 .. R13
signal reg_read_addr1      : std_logic_vector(3 downto 0) := (others => '0');
signal reg_read_addr2      : std_logic_vector(3 downto 0) := (others => '0');
signal reg_read_data1      : std_logic_vector(15 downto 0);
signal reg_read_data2      : std_logic_vector(15 downto 0);   
signal reg_write_addr      : std_logic_vector(3 downto 0) := (others => '0');
signal reg_write_data      : std_logic_vector(15 downto 0) := (others => '0');
signal reg_write_en        : std_logic := '0';
signal reg_revert_en       : std_logic := '0';
signal reg_force_shadowing : std_logic := '0';
signal reg_shadow_spr      : std_logic; --combinatorial signal to control the shadowing of special regs (SP, SR, PC)

-- direct access to the special registers within the register bank
signal SP                  : std_logic_vector(15 downto 0); -- stack pointer   (R13)
signal SR                  : std_logic_vector(15 downto 0); -- status register (R14)
signal PC                  : std_logic_vector(15 downto 0); -- program counter (R15)
signal PC_Org              : std_logic_vector(15 downto 0); -- shadow register copy of PC

-- interrupt handling
signal Int_Active          : std_logic := '0';                         -- interrupt / ISR currently active

-- CPU-internal registers that buffer instruction related data
signal Instruction         : std_logic_vector(15 downto 0) := (others => '0'); -- current instruction word
signal Src_Value           : std_logic_vector(15 downto 0) := (others => '0'); -- the value is coming from a register or from memory
signal Dst_Value           : std_logic_vector(15 downto 0) := (others => '0'); -- the value is coming from a register or from memory

-- shortcuts to "Instruction" register (combinatorial) 
signal Opcode              : std_logic_vector(3 downto 0);  -- current opcode, equals bits 15 .. 12
signal Src_RegNo           : std_logic_vector(3 downto 0);  -- current source register, equals bits 11 .. 8
signal Src_Mode            : std_logic_vector(1 downto 0);  -- current source mode, equals bits 7 .. 6
signal Dst_RegNo           : std_logic_vector(3 downto 0);  -- current destination register, equals bits 5 .. 2
signal Dst_Mode            : std_logic_vector(1 downto 0);  -- current destination mode, equals bits 1 .. 0
signal Bra_Mode            : std_logic_vector(1 downto 0);  -- branch mode (branch type)
signal Bra_Neg             : std_logic;                     -- branch condition negated
signal Bra_Condition       : std_logic_vector(2 downto 0);  -- flag number within lower 8 bits of SR
signal Ctrl_Cmd            : std_logic_vector(5 downto 0);  -- Control Command when Opcode = E

-- decoding shortcuts: during the cs_fetch state, the instruction is still on the data bus (DATA_IN)
signal diOpcode              : std_logic_vector(3 downto 0);
signal diSrc_RegNo           : std_logic_vector(3 downto 0);
signal diSrc_Mode            : std_logic_vector(1 downto 0);
signal diDst_RegNo           : std_logic_vector(3 downto 0);
signal diDst_Mode            : std_logic_vector(1 downto 0);
signal diBra_Mode            : std_logic_vector(1 downto 0);
signal diBra_Neg             : std_logic;
signal diBra_Condition       : std_logic_vector(2 downto 0);
signal diCtrl_Cmd            : std_logic_vector(5 downto 0);

-- delayed post increment situation (e.g. MOVE @R1++, @--R2) 
signal Delayed_PostInc     : std_logic;
signal DPI_RegNo           : std_logic_vector(3 downto 0);
signal DPI_Value           : std_logic_vector(15 downto 0);

-- state machine output buffers
signal fsmDataToBus        : std_logic_vector(15 downto 0);
signal fsmCpuAddr          : std_logic_vector(15 downto 0);
signal fsmCpuDataDirCtrl   : std_logic;
signal fsmCpuDataValid     : std_logic;
signal fsmSP               : std_logic_vector(15 downto 0);
signal fsmSR               : std_logic_vector(15 downto 0);
signal fsmPC               : std_logic_vector(15 downto 0);
signal fsmNextCpuState     : tCPU_States;

-- interrupt handling
signal fsmInt_Active       : std_logic;

signal fsmInstruction      : std_logic_vector(15 downto 0);
signal fsm_reg_read_addr1  : std_logic_vector(3 downto 0);
signal fsm_reg_read_addr2  : std_logic_vector(3 downto 0);
signal fsm_reg_write_addr  : std_logic_vector(3 downto 0);
signal fsm_reg_write_data  : std_logic_vector(15 downto 0);
signal fsm_reg_write_en    : std_logic;
signal fsm_reg_revert_en   : std_logic;
signal fsm_reg_force_shadowing : std_logic;

signal fsmSrc_Value        : std_logic_vector(15 downto 0);
signal fsmDst_Value        : std_logic_vector(15 downto 0);

signal fsmDelayed_PostInc  : std_logic;
signal fsmDPI_RegNo        : std_logic_vector(3 downto 0);
signal fsmDPI_Value        : std_logic_vector(15 downto 0);

-- ALU signals are purely combinatorical
signal Alu_Result          : IEEE.NUMERIC_STD.unsigned(15 downto 0); -- execution result
signal Alu_Result_v        : std_logic_vector(15 downto 0);
signal Alu_X               : std_logic;
signal Alu_C               : std_logic;
signal Alu_Z               : std_logic;
signal Alu_N               : std_logic;
signal Alu_V               : std_logic;

-- Fastpath handling
signal FastPath            : boolean;
signal Src_Value_Fast      : std_logic_vector(15 downto 0);
signal Dst_Value_Fast      : std_logic_vector(15 downto 0);

--attribute mark_debug                   : boolean;
--attribute mark_debug of CLK            : signal is true;
--attribute mark_debug of WAIT_FOR_DATA  : signal is true;
--attribute mark_debug of ADDR           : signal is true;
--attribute mark_debug of DATA_IN        : signal is true;
--attribute mark_debug of DATA_OUT       : signal is true;
--attribute mark_debug of DATA_DIR       : signal is true;
--attribute mark_debug of DATA_VALID     : signal is true;
--attribute mark_debug of HALT           : signal is true;
--attribute mark_debug of INT_N          : signal is true;
--attribute mark_debug of IGRANT_N       : signal is true;
--attribute mark_debug of Instruction    : signal is true;
--attribute mark_debug of PC             : signal is true;
--attribute mark_debug of SR             : signal is true;
--attribute mark_debug of SP             : signal is true;
--attribute mark_debug of cpu_state      : signal is true;
--attribute mark_debug of Int_Active     : signal is true;
--attribute mark_debug of Src_Value      : signal is true;
--attribute mark_debug of Dst_Value      : signal is true;
--attribute mark_debug of Opcode         : signal is true;
--attribute mark_debug of Src_RegNo      : signal is true;
--attribute mark_debug of Src_Mode       : signal is true;
--attribute mark_debug of Dst_RegNo      : signal is true;
--attribute mark_debug of Dst_Mode       : signal is true;
--attribute mark_debug of Bra_Mode       : signal is true;
--attribute mark_debug of Bra_Neg        : signal is true;
--attribute mark_debug of Bra_Condition  : signal is true;
--attribute mark_debug of Ctrl_Cmd       : signal is true;
--attribute mark_debug of FastPath       : signal is true;
--attribute mark_debug of Src_Value_Fast : signal is true;
--attribute mark_debug of Dst_Value_Fast : signal is true;
--attribute mark_debug of reg_read_addr1 : signal is true;
--attribute mark_debug of reg_read_addr2 : signal is true;
--attribute mark_debug of reg_read_data1 : signal is true;
--attribute mark_debug of reg_read_data2 : signal is true;

begin
   -- Instruction is a register
   -- these signals are shortcuts to decode the components of the instruction
   Opcode         <= Instruction(15 downto 12);
   Src_RegNo      <= Instruction(11 downto 8);
   Src_Mode       <= Instruction(7 downto 6);
   Dst_RegNo      <= Instruction(5 downto 2);
   Dst_Mode       <= Instruction(1 downto 0);
   Bra_Mode       <= Instruction(5 downto 4);
   Bra_Neg        <= Instruction(3);
   Bra_Condition  <= Instruction(2 downto 0);
   Ctrl_Cmd       <= Instruction(11 downto 6);
   
   -- while the CPU is in the state cs_fetch, the "Instruction" register is not loaded, yet
   -- these signals are shortcuts to decode the data bus (DATA_IN) as if it would be an instruction
   diOpcode         <= DATA_IN(15 downto 12);
   diSrc_RegNo      <= DATA_IN(11 downto 8);
   diSrc_Mode       <= DATA_IN(7 downto 6);
   diDst_RegNo      <= DATA_IN(5 downto 2);
   diDst_Mode       <= DATA_IN(1 downto 0);
   diBra_Mode       <= DATA_IN(5 downto 4);
   diBra_Neg        <= DATA_IN(3);
   diBra_Condition  <= DATA_IN(2 downto 0);
   diCtrl_Cmd       <= DATA_IN(11 downto 6);
   
   
   -- type cast for more elegant access
   Alu_Result_v   <= std_logic_vector(Alu_Result);
   
   -- external signals
   ADDR           <= ADDR_Bus;
   HALT           <= '1' when cpu_state = cs_halt else '0';

   -- Fastpath: When we have a direct register to register operation or a branch, where the address is in a register
   -- In cs_fetch, the Instruction register is not set, yet, so we need to listen to the data bus
   FastPath       <= true when (cpu_state = cs_fetch and diOpcode /= opcCTRL and (
                                 (diOpcode /= opcBRA and diSrc_Mode = amDirect and diDst_Mode = amDirect) or
                                 (diOpcode  = opcBRA and diSrc_Mode = amDirect)
                               ))
                               or 
                               (cpu_state = cs_execute and Opcode /= opcCTRL and (
                                 (Opcode /= opcBRA and Src_Mode = amDirect and Dst_Mode = amDirect) or
                                 (Opcode  = opcBRA and Src_Mode = amDirect))
                               )
                               else false;                           
   Src_Value_Fast <= reg_read_data1 when FastPath and cpu_state = cs_execute else Src_Value;
   Dst_Value_Fast <= reg_read_data2 when FastPath and cpu_state = cs_execute else Dst_Value;
      
   -- Registers
   Registers : entity work.register_file
      port map
      (
         clk            => CLK,
         SP             => SP,
         SR             => SR,
         PC             => PC,
         PC_Org         => PC_Org,
         fsmSP          => fsmSP,
         fsmSR          => fsmSR,
         fsmPC          => fsmPC,
         sel_rbank      => SR(15 downto 8),
         read_addr1     => reg_read_addr1,
         read_addr2     => reg_read_addr2,
         read_data1     => reg_read_data1,
         read_data2     => reg_read_data2,
         write_addr     => reg_write_addr,
         write_data     => reg_write_data,
         write_en       => reg_write_en,
         revert_en      => reg_revert_en,
         
         -- the upper registers are shadowed at each write operation, so that they can
         -- be restored any time (e.g. when returning from an interrupt) using revert_en
         shadow_en      => (not Int_Active) or reg_force_shadowing,
         shadow_spr_en  => reg_shadow_spr
      );
      
   -- ALU
   QNICE_ALU : entity work.alu
      port map
      (
         opcode      => Opcode,
         input1      => IEEE.NUMERIC_STD.unsigned(Src_Value_Fast),
         input2      => IEEE.NUMERIC_STD.unsigned(Dst_Value_Fast),
         c_in        => SR(2),
         x_in        => SR(1),
         result      => Alu_Result,
         X           => Alu_X,
         C           => Alu_C,
         Z           => Alu_Z,
         N           => Alu_N,
         V           => Alu_V
      );
             
   -- state machine: advance to next state and transfer output values
   fsm_advance_state : process (CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then
            cpu_state <= cs_reset;
            
            DATA_To_Bus <= (others => '0');
            ADDR_Bus <= x"0000";
            DATA_DIR <= '0';
            DATA_VALID <= '0';
            
            Int_Active <= '0';
            
            Instruction <= (others => '0');            
            Src_Value <= (others => '0');
            Dst_Value <= (others => '0');
            
            Delayed_PostInc <= '0';
            DPI_RegNo <= (others => '0');
            DPI_Value <= (others => '0');
                           
            reg_read_addr1 <= (others => '0');
            reg_read_addr2 <= (others => '0');
            reg_write_addr <= (others => '0');
            reg_write_data <= (others => '0');
            reg_write_en <= '0';
            reg_force_shadowing <= '0';                  
         else
            if fsmNextCpuState = cs_std_seq then
               cpu_state <= cpu_state_next;
            else
               cpu_state <= fsmNextCpuState;
            end if;
                        
            DATA_To_Bus <= fsmDataToBus;
            ADDR_Bus <= fsmCpuAddr;
            DATA_DIR <= fsmCpuDataDirCtrl;
            DATA_VALID <= fsmCpuDataValid;
            
            Int_Active <= fsmInt_Active;
            
            Instruction <= fsmInstruction;
            Src_Value <= fsmSrc_Value;
            Dst_Value <= fsmDst_Value;
            
            Delayed_PostInc <= fsmDelayed_PostInc;
            DPI_RegNo <= fsmDPI_RegNo;
            DPI_Value <= fsmDPI_Value;
                        
            reg_read_addr1 <= fsm_reg_read_addr1;
            reg_read_addr2 <= fsm_reg_read_addr2;            
            reg_write_addr <= fsm_reg_write_addr;
            reg_write_data <= fsm_reg_write_data;
            reg_write_en <= fsm_reg_write_en;  
            reg_force_shadowing <= fsm_reg_force_shadowing;
         end if;
      end if;
   end process;
   
   fsm_revert : process(clk)
   begin
      if falling_edge(clk) then
         if RESET = '1' then
            reg_revert_en <= '0';
         else
            reg_revert_en <= fsm_reg_revert_en;
         end if;
      end if;
   end process;
      
   fsm_output_decode : process (cpu_state, ADDR_Bus, SP, SR, PC, PC_org,
                                DATA_IN, DATA_To_Bus, WAIT_FOR_DATA, INT_N, Int_Active,
                                Instruction, Opcode, diOpcode, Ctrl_Cmd, diCtrl_Cmd, FastPath,
                                Src_RegNo, diSrc_RegNo, Src_Mode, diSrc_Mode, Src_Value,
                                Dst_RegNo, diDst_RegNo, Dst_Mode, diDst_Mode, Dst_Value,
                                Src_Value_Fast, Dst_Value_Fast,
                                Bra_Mode, diBra_Mode, Bra_Condition, diBra_Condition, Bra_Neg, diBra_Neg,
                                Delayed_PostInc, DPI_RegNo, DPI_Value,
                                reg_read_addr1, reg_read_data1, reg_read_addr2, reg_read_data2,
                                reg_write_addr, reg_write_data, reg_write_en, reg_revert_en, reg_force_shadowing,
                                Alu_Result, Alu_Result_v, Alu_V, Alu_N, Alu_Z, Alu_C, Alu_X)
                                                                
   variable varResult  : std_logic_vector(15 downto 0);
   variable var_C      : std_logic;
   variable var_V      : std_logic;
   variable var_X      : std_logic;
   variable var_SR_tbw : std_logic_vector(15 downto 0);
   
   procedure writeReg(signal   dstreg   : in std_logic_vector(3 downto 0);
                      signal   value    : in std_logic_vector(15 downto 0);
                      constant modifier : integer) is
   variable
      value_w : std_logic_vector(15 downto 0);
   begin
      value_w := value + modifier;
      case dstreg is
         when regSP => fsmSP <= value_w;
         when regSR => fsmSR <= value_w; 
         when regPC => fsmPC <= value_w;
         when others =>
            fsm_reg_write_addr <= dstreg;
            fsm_reg_write_data <= value_w;
            fsm_reg_write_en <= '1';            
      end case;
   end procedure;
        
   begin
      DATA_OUT <= (others => '0');
      INS_CNT_STROBE <= '0';
      IGRANT_N <= '1';
         
      fsmDataToBus <= (others => '0');
      fsmSP <= SP;
      fsmSR <= SR(15 downto 1) & "1";
      fsmPC <= PC;
      fsmCpuAddr <= ADDR_Bus;
      fsmCpuDataDirCtrl <= '0';
      fsmCpuDataValid <= '0';
      fsmNextCpuState <= cs_std_seq;
      fsmInstruction <= Instruction;
      fsmSrc_Value <= Src_Value;
      fsmDst_Value <= Dst_Value;      
      fsmDelayed_PostInc <= Delayed_PostInc;
      fsmDPI_RegNo <= DPI_RegNo;
      fsmDPI_Value <= DPI_Value;   
      fsm_reg_read_addr1 <= reg_read_addr1;
      fsm_reg_read_addr2 <= reg_read_addr2;
      fsm_reg_write_addr <= reg_write_addr;
      fsm_reg_write_data <= reg_write_data;
      fsm_reg_write_en <= '0';
      fsm_reg_revert_en <= '0';
      fsm_reg_force_shadowing <= '0';
      fsmInt_Active <= Int_Active;
      
      reg_shadow_spr <= not reg_force_shadowing;
               
      -- as fsm_advance_state is clocking the values on rising edges,
      -- the below-mentioned output decoding is to be read as:
      -- "what will be the output variables at the NEXT state (after the current state)"
      case cpu_state is
         when cs_reset =>
            fsmSP <= x"0000";
            fsmSR <= x"0001";
            fsmPC <= x"0000";
            fsmCpuAddr <= x"0000";
            fsmCpuDataDirCtrl <= '0';
            fsmCpuDataValid <= '0';
            fsmNextCpuState <= cs_std_seq;
            fsmInstruction <= (others => '0');
              
         -- as the previous state sets the direction control to read and the address to a meaningful value
         -- (i.e. 0 after cs_reset or current PC afterwards), we can be sure, that at the
         -- falling edge of cs_fetch's clock cycle, the bus (DATA) will contain the next opcode
         when cs_fetch =>
            -- add wait cycles, if necessary (e.g. due to slow RAM)
            if WAIT_FOR_DATA = '1' then
               fsmNextCpuState <= cs_fetch;
               
            -- data from bus is available
            else              
               -- interrupt will only be handled, if not currently already handling another
               if Int_Active = '0' and INT_N = '0' then
                  fsmInt_Active <= '1';
                  fsmNextCpuState <= cs_int_wait_isr;
               else
                  INS_CNT_STROBE <= '1';  -- count next instruction            
                  fsmInstruction <= DATA_IN; -- valid at falling edge
                  fsmPC <= PC + 1;
                  fsm_reg_read_addr1 <= diSrc_RegNo; -- read Src register number
                  fsm_reg_read_addr2 <= diDst_RegNo; -- rest Dst register number
                  
                  -- In case of a MOVE to SR, the new value has not arrived in SR, yet, so we need to take it from
                  -- reg_write_data. And if it was a MOVE 0, SR, we need to make sure, that bit 0 is always 1, otherwise
                  -- for example a "RSUB XYZ, 1" directly after a "MOVE 0, SR" would fail.
                  if reg_write_en = '1' and reg_write_addr = regSR then
                     var_SR_tbw := reg_write_data(15 downto 1) & "1";
                  else
                     var_SR_tbw := SR(15 downto 1) & "1";
                  end if;
                  
                  -- if a branch is meant to be executed but the branch will *not* be taken, then return directly to cs_fetch
                  -- this is on the one hand an optimization (speed increase) and on the other hand this implements
                  -- the new ISA of V1.7 where predec and postinc of registers inside branches are only performed,
                  -- if the branching condition holds (i.e. the branch would have been taken)
                  if diOpcode = opcBRA and var_SR_tbw(conv_integer(diBra_Condition)) = diBra_Neg then
                     -- special treatment for postincremented R15/PC: the postincrement is always executed, even if
                     -- the branch is not taken; this is an exception due to constant addresses being implemented
                     -- as something like ABRA @R15++, Z
                     if diSrc_RegNo = regPC and diSrc_Mode = amIndirPostInc then                     
                        fsmPC <= PC + 2;              -- +1 is the default, so due to postinc it is +2
                        fsmCpuAddr <= PC + 2;
                     else
                        fsmCpuAddr <= PC + 1;
                     end if;
                     fsmNextCpuState <= cs_fetch;
                  
                  -- for direct register to register operations or a branch based on a register, we can 
                  -- skip the decode phase, but we must then make sure that the Alu has the right
                  -- input value: see FastPath handling above and the special "if FastPath" in cs_execute
                  elsif FastPath then
                     fsmNextCpuState <= cs_execute;
                  
                  -- INCRB and DECRB can be done in one cycle   
                  elsif diOpcode = opcCTRL and (diCtrl_Cmd = ctrlINCRB or diCtrl_Cmd = ctrlDECRB) then
                     fsmNextCpuState <= cs_fetch;
                     fsmCPUAddr <= PC + 1;
                                      
                     if diCtrl_Cmd = ctrlINCRB then
                        -- increment the register bank address by one and leave the SR alone while doing so                     
                        fsmSR(15 downto 8) <= var_SR_tbw(15 downto 8) + 1;
                     else
                        -- decrement the register bank address by one and leave the SR alone while doing so                     
                        fsmSR(15 downto 8) <= var_SR_tbw(15 downto 8) - 1;
                     end if;                     
                  end if;
               end if;
            end if;
                                    
         when cs_decode =>
            -- source and destination values in case of direct register addressing modes
            fsmSrc_Value <= reg_read_data1;
            fsmDst_Value <= reg_read_data2;
            
            -- Control Opcode (HALT, RTI, INT)
            if Opcode = opcCTRL then
               case Ctrl_Cmd is
                  -- HALT
                  when ctrlHALT =>
                     fsmNextCpuState <= cs_halt;
                     
                  -- RTI
                  when ctrlRTI =>                     
                     if Int_Active = '1' then
                        fsmInt_Active <= '0';
                        fsm_reg_revert_en <= '1'; -- revert R8..R15
                        fsmCPUAddr <= PC_Org;
                        fsmNextCpuState <= cs_fetch;
                     -- rogue RTI: HALT
                     else
                        fsmNextCpuState <= cs_halt;
                     end if;
                     
                  -- INT
                  when ctrlINT =>
                     if Int_Active = '0' then
                        fsmInt_Active <= '1';                        
                        -- select INT's destination addressing mode
                        case Dst_Mode is
                           when amDirect =>
                              fsmCPUAddr <= reg_read_data2;
                              fsmPC <= reg_read_data2;
                              reg_shadow_spr <= '0';                              
                              fsmNextCpuState <= cs_fetch;
                                                         
                           when amIndirect =>
                              fsmNextCpuState <= cs_int_indirect_isr;
                              fsmCPUAddr <= reg_read_data2;
                                                                                         
                           when amIndirPreDec =>
                              fsmNextCpuState <= cs_int_indirect_isr;                           
                              fsmCPUAddr <= reg_read_data2 - 1;
                              writeReg(Dst_RegNo, reg_read_data2, -1);
                              fsm_reg_force_shadowing <= '1';
                              
                           when amIndirPostInc =>
                              fsmNextCpuState <= cs_int_indirect_isr;
                              fsmCPUAddr <= reg_read_data2;
                              writeReg(Dst_RegNo, reg_read_data2, +1);
                              fsm_reg_force_shadowing <= '1';
                              
                           when others =>
                              fsmNextCpuState <= cs_halt;
                        end case;
                     -- rogue INT: HALT
                     else
                        fsmNextCpuState <= cs_halt;
                     end if;
                                                                                 
                  -- illegal command: HALT
                  when others =>
                     fsmNextCpuState <= cs_halt;
               end case;
               
            -- Any other Opcode
            else                       
               -- decode addressing modes for source and destination
               -- if source is alrady indirect, then ignore destination for now
               -- (will be decoded within cs_exeprep_get_src_indirect)
               if Src_Mode /= amDirect then
                  fsmNextCpuState <= cs_exeprep_get_src_indirect;
                  
                  -- perform pre decrement, if necessary and then put
                  -- the address on the data bus for reading
                  if Src_Mode = amIndirPreDec then
                  
                     -- put pre decremented address on the data bus for reading
                     fsmCpuAddr <= reg_read_data1 - 1;
                     
                     -- in case the destination register is equal to the source register,
                     -- make sure, that the buffer flip/flop Dst_Value is updated
                     if Dst_RegNo = Src_RegNo then
                        fsmDst_Value <= reg_read_data1 - 1;
                     end if;
                     
                     -- write back the decremented values
                     writeReg(Src_RegNo, reg_read_data1, -1);
                  else
                     fsmCpuAddr <= reg_read_data1; -- normal (non decremented) address on the bus for reading
                  end if;
              
               -- in case of a branch, Dst_Mode would contain garbage, therefore perform an explicit check
               -- optimization: in case of MOVE the destination value is ignored anyway, so we can skip
               -- the whole indirect parameter fetch in this case
               elsif Opcode /= opcBRA and Dst_Mode /= amDirect and (Opcode /= opcMOVE or Dst_Mode = amIndirPreDec) then
                  fsmNextCpuState <= cs_exeprep_get_dst_indirect;
                  
                  -- pre decrement for destination register
                  if Dst_Mode = amIndirPreDec then
                     fsmCpuAddr <= reg_read_data2 - 1;
                     writeReg(Dst_RegNo, reg_read_data2, -1);
                  
                  -- normal (non decremented) address on the bus for reading
                  else
                     fsmCpuAddr <= reg_read_data2;
                  end if;
               end if;
            end if;
            
         when cs_exeprep_get_src_indirect =>
            -- add wait cycles, if necessary (e.g. due to slow RAM)
            if WAIT_FOR_DATA = '1' then
               fsmNextCpuState <= cs_exeprep_get_src_indirect;
               
            -- data from bus is available
            else
               -- read the indirect value from the bus and store it
               fsmSrc_Value <= DATA_IN;
                             
               -- perform post increment
               if Src_Mode = amIndirPostInc then
                  writeReg(Src_RegNo, Src_Value, +1);
                  varResult := Src_Value + 1;
                  
                  -- in case of postinc and the destination is the source: make sure the updated destination (!) value
                  -- (not the source value) goes to the ALU, but only if we are executing an opcode that calculates something
                  -- (not necessary for SP, SR and PC because they are separate explicit CPU registers) 
                  if Src_RegNo = Dst_RegNo and Src_RegNo < 13 and Opcode /= opcMOVE and Opcode /= opcSWAP and
                     Opcode /= opcBRA and Opcode /= opcCTRL and Opcode /= opcCMP then
                     fsmDst_Value <= varResult;
                  end if;
               else
                  varResult := reg_read_data2;
               end if;
                                 
               -- decode the destination addressing mode (and avoid garbage due to a branch opcode)
               -- optimization: in case of MOVE the destination value is ignored anyway, so we can skip
               -- the whole indirect parameter fetch in this case               
               if Opcode /= opcBRA and Dst_Mode /= amDirect and (Opcode /= opcMOVE or Dst_Mode = amIndirPreDec) then
                  -- this code is nearly identical to the above-mentioned code
                  -- within "elsif Dst_Mode /= amDirect then"
                  fsmNextCpuState <= cs_exeprep_get_dst_indirect;                  
                  if Dst_Mode = amIndirPreDec then
                  
                     -- The register bank is only able to write one register per cycle. If we need to
                     -- post-increment any register between 0 and 12 and in parallel pre-decrement any
                     -- register between 0 and 12, then this will not work in parallel and needs extra
                     -- work in the next state cs_exeprep_get_dst_indirect.
                     -- An exception are the registers SP, SR and PC, because they are not stored as
                     -- part of the register bank, but modeled as CPU internal explicit registers
                     if Src_Mode = amIndirPostInc and Src_RegNo < 13 and
                        Dst_Mode = amIndirPreDec  and Dst_RegNo < 13 then
                           fsmDelayed_PostInc <= '1';
                           fsmDPI_RegNo <= Src_RegNo;
                           
                           if Src_RegNo /= Dst_RegNo then
                              fsmDPI_Value <= varResult;
                              fsmCpuAddr <= reg_read_data2 - 1;
                              
                           -- doing a predec and then a postinc on the very same register results in no change at all                              
                           else
                              fsmDPI_Value <= Dst_Value;
                              fsmCpuAddr <= reg_read_data2;                       
                           end if;
                     else                     
                        fsmCpuAddr <= reg_read_data2 - 1;
                     end if;
                     
                     writeReg(Dst_RegNo, Dst_Value, -1);
                  else
                     -- if the second parameter is also to be fetched indirect and if it
                     -- is identical to the first parameter, then make sure, that the address
                     -- bus is setup with the result of the above-mentioned postincrement (if applicable)
                     if (Dst_Mode = amIndirect or Dst_Mode = amInDirPostInc) and Dst_RegNo = Src_RegNo then
                        fsmCpuAddr <= varResult;
                     else
                        fsmCpuAddr <= reg_read_data2;
                     end if;
                     
                  end if;               
               end if;
            end if;

         when cs_exeprep_get_dst_indirect =>
            -- add wait cycles, if necessary (e.g. due to slow RAM)
            if WAIT_FOR_DATA = '1' then
               fsmNextCpuState <= cs_exeprep_get_dst_indirect;
               
            -- data from bus is available
            else               
               -- read the indirect value from the bus and store it
               fsmDst_Value <= DATA_IN;
               
               -- handle delayed post-increment
               if Delayed_PostInc = '1' then
                  writeReg(DPI_RegNo, DPI_Value, 0);
                  fsmDelayed_PostInc <= '0';
               end if;               
            end if;                        
                        
         when cs_execute =>       
            -- When we arrived here via FastPath we still need to store Src and Dst
            if FastPath then
               fsmSrc_Value <= reg_read_data1;
               fsmDst_Value <= reg_read_data2;
            end if;
          
            -- execute branches: if we arrive here, it is granted, that the branch needs to be executed
            if Opcode = opcBRA then
               fsmNextCpuState <= cs_fetch;
               fsmCpuAddr <= PC;
               
               case Bra_Mode is
                  when bmABRA =>
                     fsmPC <= Src_Value_Fast;
                     fsmCpuAddr <= Src_Value_Fast;
               
                  when bmRBRA =>
                     fsmPC <= PC + Src_Value_Fast;
                     fsmCpuAddr <= PC + Src_Value_Fast;
                     
                  when bmASUB | bmRSUB =>
                     -- decrease stack pointer and store the current program
                     -- counter to the memory address where the decreased
                     -- stack pointer is pointing to
                     fsmSP <= SP - 1;
                     fsmCpuAddr <= SP - 1;
                     fsmDataToBus <= PC;
                     fsmCpuDataDirCtrl <= '1';
                     fsmCpuDataValid <='1';
                     fsmNextCpuState <= cs_exepost_sub;
                                            
                  when others =>
                     fsmNextCpuState <= cs_halt;
               end case;
            
            -- execute all comands other than branches
            else               
               -- As the ALU is a purely combinatorical circuit, ALU's calculation is
               -- immediatelly done, when cs_execute is entered. We need to make sure,
               -- that all ALU inputs contain valid data at this moment in time
               
               -- shift instructions must only modify Z, N, C and X
               if Opcode = opcSHL then
                  -- fill with X and shift to C
                  fsmSR <= SR(15 downto 8) & "00" & SR(5) & Alu_N & Alu_Z & Alu_C & SR(1) & "1";
               elsif Opcode = opcSHR then
                  -- fill with C and shift to X
                  fsmSR <= SR(15 downto 8) & "00" & SR(5) & Alu_N & Alu_Z & SR(2) & Alu_X & "1";
                     
               -- all other opcodes
               else
                  -- the following defaults are overwritten by the "if Opcode..." section below
                  var_V := SR(5);   -- default: V is not changed by the ALU
                  var_C := SR(2);   -- default: C is not changed by the ALU
                  var_X := SR(1);   -- default: X is not changed by the ALU
            
                  -- only additions and subtractions are allowed to change V and C
                  if Opcode = opcADD or Opcode = opcADDC or Opcode = opcSUB or Opcode = opcSUBC then
                     var_V := Alu_V;
                     var_C := Alu_C;
                     
                  -- CMP is allowed to change Z, V and N (Alu_Z and Alu_N is already set in fsmSR below)
                  elsif Opcode = opcCMP then
                     var_V := Alu_V;
                  end if;
                  
                  fsmSR <= SR(15 downto 8) & "00" & var_V & Alu_N & Alu_Z & var_C & var_X & "1";
               end if;
               
               -- store result: direct
               if Dst_Mode = amDirect then
               
                  -- store result in register
                  -- but when doing a compare, then do not write back the old SR value
                  if (Opcode /= opcCMP) or (Dst_RegNo /= regSR) then
                     writeReg(Dst_RegNo, Alu_Result_v, 0);
                  end if;
                                          
                  -- prepare next fetch by outputting the next instruction's address:
                  -- in case we just calculated it, use the ALU result, else use the existing PC
                  if Dst_RegNo = regPC then
                     fsmCpuAddr <= Alu_Result_v;
                  else                     
                     fsmCpuAddr <= PC;
                  end if;
                  
               -- store result: indirect
               else
                  fsmNextCpuState <= cs_exepost_store_dst_indirect; -- also go there in the CMP case due to a possible post increment
                  if Opcode /= opcCMP then
                     fsmCpuAddr <= reg_read_data2;
                     fsmDataToBus <= Alu_Result_v;
                     fsmCpuDataDirCtrl <= '1';
                     fsmCpuDataValid <='1';
                  end if;
               end if;               
            end if;
                               
         when cs_exepost_store_dst_indirect =>
            -- Do the actual indirect storing, the target address is already there, thanks to the
            -- fsmCpuAddr in the previous step. But in a CMP case: Do not store anything. Still,
            -- we are executing this step to make sure any post increment works: CMP R1, @R2++
            if Opcode /= opcCMP then
               DATA_OUT <= DATA_To_Bus;
               fsmDataToBus <= DATA_To_Bus;
               fsmCpuDataDirCtrl <= '1';
               fsmCpuDataValid <= '1';
            end if;
            
            -- add wait cycles if necessary
            if WAIT_FOR_DATA = '1' then
               fsmNextCpuState <= cs_exepost_store_dst_indirect;

            else
               fsmCpuDataDirCtrl <= '0';
               fsmCpuDataValid <= '0';
               fsmCpuAddr <= PC;
                  
               -- perform post increment
               if Dst_Mode = amIndirPostInc then
                  writeReg(Dst_RegNo, reg_read_data2, +1);            
               
                  -- in case we post increment the PC, then the CPU address needs this value already at the next state 
                  if Dst_RegNo = regPC then
                     fsmCpuAddr <= PC + 1;
                  end if;
               end if;
            end if;
                  
         when cs_exepost_sub =>
            DATA_OUT <= DATA_To_Bus;
            fsmDataToBus <= DATA_To_Bus;
            fsmCpuDataDirCtrl <= '0';
            fsmCpuDataValid <= '0';
            
            -- absolute or relative?
            if Bra_Mode = bmASUB then
               fsmPC <= Src_Value;
               fsmCpuAddr <= Src_Value;
            else
               fsmPC <= PC + Src_Value;
               fsmCpuAddr <= PC + Src_Value;
            end if;

         when cs_exepost_prepfetch =>
            DATA_OUT <= DATA_To_Bus;
            fsmCpuAddr <= PC;
            
         when cs_halt =>
            fsmCpuAddr <= ADDR_Bus;
            
         when cs_int_wait_isr =>
            if Int_Active = '1' then
               IGRANT_N <= '0';
            
               -- requester signals ISR address is on DATA
               if INT_N = '1' then
                  fsmNextCPUState <= cs_int_jmp_isr;
                  fsmCpuAddr <= DATA_IN; -- put ISR address in CPU's address register
                  fsmPC <= DATA_IN;
               else
                  fsmNextCPUState <= cs_int_wait_isr;
               end if;
            end if;

         -- IGRANT_N goes back to high, new PC and CpuAddr is being clocked in            
         when cs_int_jmp_isr =>
            if Int_Active = '1' then
               fsmNextCPUState <= cs_fetch;
            end if;
            
         when cs_int_indirect_isr =>
            if Int_Active = '1' then
               fsmCpuAddr <= DATA_IN;
               fsmPC <= DATA_IN;
               fsmNextCpuState <= cs_fetch;
            end if;
        
         when others =>
            null;            
      end case;
   end process;
   
   -- main CPU state machine that runs through the enum cpu_state
   fsm_next_state_decode : process (cpu_state)
   begin
      case cpu_state is
         when cs_reset                       => cpu_state_next <= cs_fetch;         
         when cs_fetch                       => cpu_state_next <= cs_decode;
         when cs_decode                      => cpu_state_next <= cs_execute;
         when cs_exeprep_get_src_indirect    => cpu_state_next <= cs_execute;
         when cs_exeprep_get_dst_indirect    => cpu_state_next <= cs_execute;
         when cs_execute                     => cpu_state_next <= cs_fetch;
         when cs_exepost_store_dst_indirect  => cpu_state_next <= cs_fetch;
         when cs_exepost_sub                 => cpu_state_next <= cs_fetch;
         when cs_exepost_prepfetch           => cpu_state_next <= cs_fetch;
         when cs_halt                        => cpu_state_next <= cs_halt;
         when cs_int_wait_isr                => cpu_state_next <= cs_halt;  -- if unexpected situation: halt CPU
         when cs_int_jmp_isr                 => cpu_state_next <= cs_halt;  -- ditto
         when cs_int_indirect_isr            => cpu_state_next <= cs_halt;  -- ditto
         when others                         => cpu_state_next <= cs_halt;  -- ditto
      end case;
   end process;
                  
end beh;
