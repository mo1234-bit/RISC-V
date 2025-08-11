library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity Mux_3 is
    port(a,b,c:in std_logic_vector (31 downto 0);
    s:in std_logic_vector (1 downto 0);
    d:out std_logic_vector (31 downto 0));
end entity Mux_3;
architecture Mux_3 of Mux_3 is
    begin
        process (a,b,c,s) is
            begin
                if(s="00")then
                d<=a;
                elsif (s="01")then 
                d<=b;
                elsif (s="10")then
                d<=c;
                else
                d<=(others=>'0');
                end if ;
                end process;
                end architecture Mux_3;