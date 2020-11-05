library ieee;
use ieee.std_logic_1164.all;

package cpu_constants is

   -- Instruction format is as follows
   subtype R_OPCODE     is natural range 15 downto 12;
   subtype R_SRC_REG    is natural range 11 downto  8;
   subtype R_SRC_MODE   is natural range  7 downto  6;
   subtype R_DEST_REG   is natural range  5 downto  2;
   subtype R_DEST_MODE  is natural range  1 downto  0;
   subtype R_BRA_MODE   is natural range  5 downto  4;
   constant R_BRA_NEGATE : integer := 3;
   subtype R_BRA_COND   is natural range  2 downto  0;

   -- Decode status bits
   constant C_SR_V : integer := 5;
   constant C_SR_N : integer := 4;
   constant C_SR_Z : integer := 3;
   constant C_SR_C : integer := 2;
   constant C_SR_X : integer := 1;

   -- Opcodes
   constant C_OP_MOVE : integer := 0;
   constant C_OP_ADD  : integer := 1;
   constant C_OP_ADDC : integer := 2;
   constant C_OP_SUB  : integer := 3;
   constant C_OP_SUBC : integer := 4;
   constant C_OP_SHL  : integer := 5;
   constant C_OP_SHR  : integer := 6;
   constant C_OP_SWAP : integer := 7;
   constant C_OP_NOT  : integer := 8;
   constant C_OP_AND  : integer := 9;
   constant C_OP_OR   : integer := 10;
   constant C_OP_XOR  : integer := 11;
   constant C_OP_CMP  : integer := 12;
   constant C_OP_RES  : integer := 13;
   constant C_OP_CTRL : integer := 14;
   constant C_OP_BRA  : integer := 15;

   -- Addressing modes
   constant C_MODE_REG  : integer := 0;   -- R
   constant C_MODE_MEM  : integer := 1;   -- @R
   constant C_MODE_POST : integer := 2;   -- @R++
   constant C_MODE_PRE  : integer := 3;   -- @--R

   -- Special registers
   constant C_REG_PC : integer := 15;
   constant C_REG_SR : integer := 14;
   constant C_REG_SP : integer := 13;

   -- Branch modes
   constant C_BRA_ABRA : integer := 0;
   constant C_BRA_ASUB : integer := 1;
   constant C_BRA_RBRA : integer := 2;
   constant C_BRA_RSUB : integer := 3;

   procedure disassemble(pc : std_logic_vector; inst : std_logic_vector);

end cpu_constants;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

package body cpu_constants is

   procedure disassemble(pc : std_logic_vector; inst : std_logic_vector) is
      function to_hstring(slv : std_logic_vector) return string is
         variable l : line;
      begin
         hwrite(l, slv);
         return l.all;
      end function to_hstring;

      function inst_str(slv : std_logic_vector) return string is
      begin
         case conv_integer(slv) is
            when C_OP_MOVE => return "MOVE";
            when C_OP_ADD  => return "ADD";
            when C_OP_ADDC => return "ADDC";
            when C_OP_SUB  => return "SUB";
            when C_OP_SUBC => return "SUBC";
            when C_OP_SHL  => return "SHL";
            when C_OP_SHR  => return "SHR";
            when C_OP_SWAP => return "SWAP";
            when C_OP_NOT  => return "NOT";
            when C_OP_AND  => return "AND";
            when C_OP_OR   => return "OR";
            when C_OP_XOR  => return "XOR";
            when C_OP_CMP  => return "CMP";
            when C_OP_RES  => return "???";
            when C_OP_CTRL => return "CTRL";
            when C_OP_BRA  => return "BRA";
            when others => return "???";
         end case;
         return "???";
      end function inst_str;

      function reg_str(reg : std_logic_vector; mode : std_logic_vector) return string is
      begin
         case conv_integer(mode) is
            when C_MODE_REG  => return "R" & integer'image(conv_integer(reg));
            when C_MODE_MEM  => return "@R" & integer'image(conv_integer(reg));
            when C_MODE_POST => return "@R" & integer'image(conv_integer(reg)) & "++";
            when C_MODE_PRE  => return "@--R" & integer'image(conv_integer(reg));
            when others => return "???";
         end case;
         return "???";
      end function reg_str;

   begin
      report to_hstring(pc) & " " &
             "(" & to_hstring(inst) & ") " &
             inst_str(inst(R_OPCODE)) & " " &
             reg_str(inst(R_SRC_REG), inst(R_SRC_MODE)) & ", " &
             reg_str(inst(R_DEST_REG), inst(R_DEST_MODE));
   end procedure disassemble;

end cpu_constants;

