----------------------------------------------------------------------------------
-- QNICE CPU private constants (e.g. opcodes, addressing modes, ...)
-- 
-- done in 2015 by sy2002
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.qnice_tools.all;

package env1_globals is

-- Clock frequency of CPU (in Hz)
constant SYSTEM_SPEED          : natural  := 50_000_000;

-- file name and file size (in lines) of the file that is converted to the ROM located at 0x0000
constant ROM_FILE              : string   := "../monitor/monitor.rom";
--constant ROM_FILE              : string   := "../demos/q-tris.rom";

-- file name of file and file size (in lines) of the file containing the Power On & Reset Execution (PORE) ROM
constant PORE_ROM_FILE         : string   := "../pore/pore.rom";

-- size of lower register bank: should be 256
-- set to 16 during development for faster synthesis, routing, etc.
--
-- SYNTHESIS OPTIMIZATION 
-- set always:
--    Synthesis: Optimization Goal: Speed
--    Xilinx Specific: Register Balancing: Yes (and the following move register stages should be also ON)
-- set only for a size greater 16, e.g. when using 256
--    Synthesis: Optimization Effort: HIGH (was NORMAL)
--    HDL: Resource Sharing OFF (was ON)
--    Xilinx Specific: LUT Combining NO (was AUTO)
--                     Optimize Privitives ON (was OFF)
constant SHADOW_REGFILE_SIZE   : natural  := 256;

-- size of the block RAM in 16bit words: should be 32768
-- set to 256 during development for tracability during simulation
constant BLOCK_RAM_SIZE        : natural  := 32768;

-- VGA screen memory (should be a multiple of 80x40 = 3.200)
constant VGA_RAM_SIZE          : natural  := 64000;

-- UART is in 8-N-1 mode
constant UART_FIFO_SIZE        : natural  := 32; -- size of the UART's FIFO buffer in bytes
constant UART_BAUDRATE_DEFAULT : natural  := 115200;  -- Set upon reset when switch(3) = OFF
constant UART_BAUDRATE_FAST    : natural  := 1000000; -- Set upon reset when switch(3) = ON

-- Amount of CPU cycles, that the reset signal shall be active
constant RESET_DURATION        : natural  := 16;

end env1_globals;

package body env1_globals is
end env1_globals;

