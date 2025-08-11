library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity Control_Unit_Top is
    Port ( 
        Op         : in  STD_LOGIC_VECTOR(6 downto 0);
        funct7     : in  STD_LOGIC_VECTOR(6 downto 0);
        funct3     : in  STD_LOGIC_VECTOR(2 downto 0);
        RegWrite   : out STD_LOGIC;
        ALUSrc     : out STD_LOGIC;
        MemWrite   : out STD_LOGIC;
        ResultSrc  : out STD_LOGIC;
        Branch     : out STD_LOGIC;
        ImmSrc     : out STD_LOGIC_VECTOR(1 downto 0);
        ALUControl : out STD_LOGIC_VECTOR(2 downto 0)
    );
end Control_Unit_Top;

architecture Control_Unit_Top of Control_Unit_Top is 
signal ALUOp: std_logic_vector (1 downto 0);
component Main_Decoder is
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
end component;
component ALU_Decoder is
    Port ( 
        ALUOp      : in  STD_LOGIC_VECTOR(1 downto 0);
        funct3     : in  STD_LOGIC_VECTOR(2 downto 0);
        funct7     : in  STD_LOGIC_VECTOR(6 downto 0);
        op         : in  STD_LOGIC_VECTOR(6 downto 0);
        ALUControl : out STD_LOGIC_VECTOR(2 downto 0)
    );
end component;
begin
   main_decoderrv: Main_Decoder port map (Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp);
   alu_decoderv: ALU_Decoder port map (ALUOp,funct3,funct7,op,ALUControl);
    end; 
