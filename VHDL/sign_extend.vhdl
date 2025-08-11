library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Sign_Extend is
    Port ( 
        input      : in  STD_LOGIC_VECTOR(31 downto 0);
        ImmSrc  : in  STD_LOGIC_VECTOR(1 downto 0);
        Imm_Ext : out STD_LOGIC_VECTOR(31 downto 0)
    );
end Sign_Extend;

architecture Sign_Extend of Sign_Extend is
    begin 
    Imm_Ext <= (31 downto 12 => input(31)) & input(31 downto 20) when ImmSrc = "00" else
               (31 downto 12 => input(31)) & input(31 downto 25) & input(11 downto 7) when ImmSrc = "01" else
               (others => '0');
    end;