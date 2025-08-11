library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.numeric_std_unsigned.all;
use IEEE.std_logic_textio.all;
entity imem is 
port(a:in std_logic_vector(31 downto 0);
      rd:out std_logic_vector(31 downto 0));
      end entity imem;

architecture imem of imem is
    type ramtype is array (1023 downto 0)of std_logic_vector(31 downto 0);
    impure function init_ram_hex return ramtype is
    file text_file:text open read_mode is "memfile.hex";
    variable text_line:line;
    variable ram_content:ramtype;
    variable i: integer:=0;
    begin
        for i in 0 to 1023  loop 
        ram_content(i):=(others=>'0');
        end loop ;
        while not endfile(text_file)loop
            readline(text_file,text_line);
            hread(text_line,ram_content(i));
            i:=i+1;
            end loop ;
            return ram_content;

            end function ;
            signal mem: ramtype :=init_ram_hex;
            begin
                process (a) is 
                begin 
                rd<=mem(to_integer(a(31 downto 2)));
                end process;
                end ;

