library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.numeric_std_unsigned.all;
use IEEE.std_logic_textio.all;

entity Register_File is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        WE3 : in STD_LOGIC;
        A1 : in STD_LOGIC_VECTOR(4 downto 0);
        A2 : in STD_LOGIC_VECTOR(4 downto 0);
        A3 : in STD_LOGIC_VECTOR(4 downto 0);
        WD3 : in STD_LOGIC_VECTOR(31 downto 0);
        RD1 : out STD_LOGIC_VECTOR(31 downto 0);
        RD2 : out STD_LOGIC_VECTOR(31 downto 0)
    );
end Register_File;

architecture Behavioral of Register_File is
    type register_array is array (31 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
    signal mem : register_array := (others => (others => '0'));
    
begin
    -- Write process (synchronous)
    write_process : process(clk)
    begin
        if rising_edge(clk) then
            if WE3 = '1' and A3 /= 0 then
                mem(to_integer(A3)) <= WD3;
            end if;
        end if;
    end process write_process;
    RD1 <= (others => '0') when rst = '0' else mem(to_integer(unsigned(A1)));
    RD2 <= (others => '0') when rst = '0' else mem(to_integer(unsigned(A2)));

end Behavioral;