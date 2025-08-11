library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.numeric_std_unsigned.all;
use IEEE.std_logic_textio.all;
entity dmem is 
port(a,wd:in std_logic_vector(31 downto 0);
      rd:out std_logic_vector(31 downto 0);
      clk,we:in std_logic);
      end entity dmem;
      architecture dmem of dmem is
        begin
            process is 
            type ramtype is array (1023 downto 0)of std_logic_vector(31 downto 0);
            variable mem:ramtype;
            begin
                loop
                    if rising_edge (clk)then
                        if(we='1')then mem(to_integer(a(11 downto 2))):=wd;
                        end if ;
                        end if ;
                        rd<=mem(to_integer(a(11 downto 2)));
                        wait on clk,a;
                end loop ;
                end process;
                end ; 