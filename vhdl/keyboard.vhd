-- PS2 keyboard component that outputs ASCII
-- meant to be connected with the QNICE CPU as data I/O controled through MMIO
-- output goes zero when not enabled
-- done by sy2002 in December 2015 and January 2016

-- heavily inspired by Scott Larson's component
-- https://eewiki.net/pages/viewpage.action?pageId=28279002
-- which has been enhanced by sy2002 to support special keys and locales
--
-- IMPORTANT: kbd_constants.vhd contains locales, special characters, modifiers
--
-- Registers:
--
-- Register $FF04: State register
--    Bit  0 (read only):      New ASCII character avaiable for reading
--                             (bits 7 downto 0 of Read register)
--    Bit  1 (read only):      New special key available for reading
--                             (bits 15 downto 8 of Read register)
--    Bits 2..4 (read/write):  Locales: 000 = US English keyboard layout,
--                             001 = German layout, others: reserved for more locales
--    Bits 5..7 (read only):   Modifiers: 5 = shift, 6 = alt, 7 = ctrl
--                             Only valid, when bits 0 and/or 1 are '1'
-- Register $FF05: Read register
--    Contains the ASCII character in bits 7 downto 0  or the special key code
--    in 15 downto 0. The "or" is meant exclusive, i.e. it cannot happen that
--    one transmission contains an ASCII character PLUS a special character.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
port (
   clk           : in std_logic;               -- system clock
   reset         : in std_logic;               -- system reset
   
   -- PS/2
   ps2_clk       : in std_logic;               -- clock signal from PS/2 keyboard
   ps2_data      : in std_logic;               -- data signal from PS/2 keyboard
   
   -- conntect to CPU's data bus (data output zero when all reg_* are 0)
   kbd_en        : in std_logic;
   kbd_we        : in std_logic;
   kbd_reg       : in std_logic_vector(1 downto 0);   
   cpu_data_in   : in std_logic_vector(15 downto 0);
   cpu_data_out  : out std_logic_vector(15 downto 0)
);
end keyboard;

architecture beh of keyboard is

-- signals for communicating with the ps2_keyboard_to_ascii component
signal ascii_new           : std_logic;
signal ascii_code          : std_logic_vector(7 downto 0);
signal spec_new            : std_logic;
signal spec_code           : std_logic_vector(7 downto 0);

-- signals that together form the status register
signal ff_ascii_new        : std_logic;
signal ff_spec_new         : std_logic;
signal ff_locale           : std_logic_vector(2 downto 0);
signal modifiers           : std_logic_vector(2 downto 0);

begin

   kbd : entity work.ps2_keyboard_to_ascii
      port map (
         clk => clk,
         ps2_clk => ps2_clk,
         ps2_data => ps2_data,
         ascii_new => ascii_new,
         ascii_code => ascii_code,
         spec_new => spec_new,
         spec_code => spec_code,
         locale => ff_locale,
         modifiers => modifiers
      );

   ff_new_handler : process(clk)
   begin
      if rising_edge(clk) then
         if kbd_en = '1' and kbd_we = '0' and kbd_reg = "01" then
            ff_ascii_new <= '0';
            ff_spec_new <= '0';
         end if;

         if ascii_new = '1' then
            ff_ascii_new <= '1';
         end if;

         if spec_new = '1' then
            ff_spec_new <= '1';
         end if;

         if reset = '1' then
            ff_ascii_new <= '0';
            ff_spec_new <= '0';
         end if;
      end if;
   end process;

   write_ff_locale: process(clk)
   begin
      if rising_edge(clk) then
         if kbd_en = '1' and kbd_we = '1' and kbd_reg = "00" then
            ff_locale <= cpu_data_in(4 downto 2);
         end if;

         if reset = '1' then
            ff_locale <= (others => '0');
         end if;
      end if;
   end process;

      
   read_registers : process(kbd_en, kbd_we, kbd_reg, ff_locale, ff_spec_new, ff_ascii_new, ascii_code, spec_code, modifiers)
   begin
      if kbd_en = '1' and kbd_we = '0' then
         case kbd_reg is
         
            -- read status register
            when "00" =>
               cpu_data_out <= "00000000" &
                           modifiers & -- bits 7 .. 5: ctrl/alt/shift
                           ff_locale &    -- bits 4 .. 2: 000 = US, 001 = DE
                           ff_spec_new &  -- bit 1: new special key
                           ff_ascii_new;  -- bit 0: new ascii key
               
            -- read data register
            when "01" =>
               cpu_data_out <= spec_code & ascii_code;
               
            when others =>
               cpu_data_out <= (others => '0');
         
         end case;
      else
         cpu_data_out <= (others => '0');
      end if;   
   end process;

end beh;

