library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity mux is 
    port(a:in std_logic_vector(31 downto 0);
    b:in std_logic_vector(31 downto 0);
    s:in std_logic;
    c:out std_logic_vector(31 downto 0));
end entity mux;
architecture mux of mux is 
begin 
c<= b when s='1' else a;
end architecture mux;