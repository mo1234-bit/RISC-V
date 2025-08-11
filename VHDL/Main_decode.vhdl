library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity Main_Decoder is
    Port ( 
        Op        : in  STD_LOGIC_VECTOR(6 downto 0);
        RegWrite  : out STD_LOGIC;
        ImmSrc    : out STD_LOGIC_VECTOR(1 downto 0);
        ALUSrc    : out STD_LOGIC;
        MemWrite  : out STD_LOGIC;
        ResultSrc : out STD_LOGIC;
        Branch    : out STD_LOGIC;
        ALUOp     : out STD_LOGIC_VECTOR(1 downto 0)
    );
end Main_Decoder;
architecture Main_Decoder of Main_Decoder is 
begin 
RegWrite <= '1' when op="0000011" or op="0110011" or op="0010011"else
'0';
ImmSrc <= "01"when op="0100011" else "10" when op="1100011" else "00";
ALUSrc<= '1' when op="0000011" or op="0100011" or op="0010011"else
'0';
MemWrite<= '1' when op="0100011" else '0';
ResultSrc<= '1' when op="0000011" else '0';
Branch<= '1' when op="1100011" else '0';
ALUOp<= "10" when op="0110011" else "01" when op="1100011" else "00";
end ;