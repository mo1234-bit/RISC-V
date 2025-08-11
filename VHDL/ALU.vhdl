library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;
entity ALU is
    port(A,B:in std_logic_vector(31 downto 0);
         ALUControl:in std_logic_vector(2 downto 0);
         Carry,OverFlow,Zero,Negative:out std_logic;
         Result:out std_logic_vector (31 downto 0));
end entity ALU;

architecture ALU of ALU is
    signal Sum:std_logic_vector (32 downto 0);
     signal Result_temp :std_logic_vector(31 downto 0);
     signal cout:std_logic;
    begin 
    Sum<= A+B when ALUControl(0)='0' else A+(not B+1) ; 
    process(Sum,ALUControl,A,B,Result_temp)is 
    begin
    case ALUControl is
    when "000"=>
    Result_temp <= Sum(31 downto 0);
    when "001"=>
    Result_temp <= Sum(31 downto 0);
    when "010"=>
    Result_temp <=A and B;
    when "011"=>
    Result_temp <=A or B;
    when "101"=>
    Result_temp<=(0=>Sum(31) ,others=>'0');
     when others => 
        Result_temp <= (others => '0');
    end case ;
    end process;
      Result<=Result_temp;
      OverFlow <= (Sum(31) xor A(31)) and 
                (not (ALUControl(0) xor B(31) xor A(31))) and
                (not ALUControl(1));
        cout<=Sum(32);
    
    Carry <= (not ALUControl(1))and cout;
    
    Zero <= '1' when Result_temp = (x"0000000") else '0';
    
    Negative <= Result_temp(31);
end;

