library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;
entity PC_Adder is
    port (a,b:in std_logic_vector(31 downto 0);
          c:out std_logic_vector(31 downto 0));
          end entity PC_Adder;

architecture PC_Adder of PC_Adder is
    begin
        c<=a + b;
        end architecture PC_Adder; 