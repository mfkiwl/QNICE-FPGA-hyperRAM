library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity read_instruction is
   port (
      clk_i         : in  std_logic;
      rst_i         : in  std_logic;

      -- To register file
      pc_i          : in  std_logic_vector(15 downto 0);
      pc_o          : out std_logic_vector(15 downto 0);

      -- To memory subsystem
      mem_valid_o   : out std_logic;
      mem_ready_i   : in  std_logic;
      mem_address_o : out std_logic_vector(15 downto 0);
      mem_data_i    : in  std_logic_vector(15 downto 0);

      -- To next pipeline stage
      instruction_o : out std_logic_vector(15 downto 0)
   );
end entity read_instruction;

architecture synthesis of read_instruction is

begin

   mem_address_o <= pc_i;
   mem_valid_o   <= '1';
   pc_o          <= pc_i + 1;

   p_next_stage : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if mem_ready_i = '1' then
            instruction_o <= mem_data_i;
         end if;

         if rst_i = '1' then
            instruction_o <= (others => '0');
         end if;
      end if;
   end process p_next_stage;

end architecture synthesis;

