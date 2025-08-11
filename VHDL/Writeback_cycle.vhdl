library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity write_back_cycle is 
port (ALU_ResultW:in std_logic_vector(31 downto 0);
      ReadDataW: in std_logic_vector(31 downto 0);
      ResultSrcW: in std_logic ;
       ResultW:out std_logic_vector(31 downto 0));
 end entity write_back_cycle;
 
 architecture write_back of write_back_cycle is
    component mux is 
    port(a:in std_logic_vector(31 downto 0);
    b:in std_logic_vector(31 downto 0);
    s:in std_logic;
    c:out std_logic_vector(31 downto 0));
    end component;
    begin 
    muxy:mux port map (ALU_ResultW,ReadDataW,ResultSrcW,ResultW);
    end architecture write_back;