library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PC_Module is
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        PC_Next : in  STD_LOGIC_VECTOR(31 downto 0);
        PC      : out STD_LOGIC_VECTOR(31 downto 0)
    );
end PC_Module;

architecture PC_Module of PC_Module is 
begin 
process (clk) is 
begin 
if rising_edge(clk)then 
if(rst='0') then 
PC<=(others=>'0');
else 
PC<=Pc_Next;
end if ; 
end if ;
end process;
end ;
