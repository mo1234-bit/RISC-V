library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;
entity ALU_Decoder is
    Port ( 
        ALUOp      : in  STD_LOGIC_VECTOR(1 downto 0);
        funct3     : in  STD_LOGIC_VECTOR(2 downto 0);
        funct7     : in  STD_LOGIC_VECTOR(6 downto 0);
        op         : in  STD_LOGIC_VECTOR(6 downto 0);
        ALUControl : out STD_LOGIC_VECTOR(2 downto 0)
    );
end ALU_Decoder;

architecture ALU_Decoder of ALU_Decoder is
    begin
        process (ALUOp,funct3,funct7, op) is
            begin
                case ALUOp is
                    when "00"=>
                    ALUControl<="000";
                    when "01"=>
                    ALUControl<="001";
                    when "10"=>
                    case funct3 is
                        when "000"=>
                        if not( op(5)='1' and funct7(5)='1') then
                        ALUControl<="000";
                        else 
                        ALUControl<="001";
                        end if ;
                        when "010"=>
                        ALUControl<="101";
                        when "110"=>
                        ALUControl<="011";
                        when "111"=>
                        ALUControl<="010";
                        when others =>
                        ALUControl<="000";
                        end case ;
                    when others=>
                    ALUControl<="000";
                    end case;
                    end process;
                    end;