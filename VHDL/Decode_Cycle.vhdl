library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decode_cycle is
    Port ( 
        clk,rst,RegWriteW: in  STD_LOGIC;
        InstrD , PCD,PCPlus4D ,ResultW    : in  STD_LOGIC_VECTOR(31 downto 0);
        RDW          : in  STD_LOGIC_VECTOR(4 downto 0);
        RegWriteE    : out STD_LOGIC;
        ALUSrcE      : out STD_LOGIC;
        MemWriteE    : out STD_LOGIC;
        ResultSrcE   : out STD_LOGIC;
        BranchE      : out STD_LOGIC;
        ALUControlE  : out STD_LOGIC_VECTOR(2 downto 0);
        RD1_E        : out STD_LOGIC_VECTOR(31 downto 0);
        RD2_E        : out STD_LOGIC_VECTOR(31 downto 0);
        Imm_Ext_E    : out STD_LOGIC_VECTOR(31 downto 0);
        RD_E         : out STD_LOGIC_VECTOR(4 downto 0);
        PCE          : out STD_LOGIC_VECTOR(31 downto 0);
        PCPlus4E     : out STD_LOGIC_VECTOR(31 downto 0);
        RS1_E        : out STD_LOGIC_VECTOR(4 downto 0);
        RS2_E        : out STD_LOGIC_VECTOR(4 downto 0)
    );
end decode_cycle;

architecture Behavioral of decode_cycle is
    signal RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD : STD_LOGIC;
    signal ImmSrcD : STD_LOGIC_VECTOR(1 downto 0);
    signal ALUControlD : STD_LOGIC_VECTOR(2 downto 0);
    signal RD1_D, RD2_D, Imm_Ext_D : STD_LOGIC_VECTOR(31 downto 0);
    signal RegWriteD_r, ALUSrcD_r, MemWriteD_r, ResultSrcD_r, BranchD_r : STD_LOGIC;
    signal ALUControlD_r : STD_LOGIC_VECTOR(2 downto 0);
    signal RD1_D_r, RD2_D_r, Imm_Ext_D_r : STD_LOGIC_VECTOR(31 downto 0);
    signal RD_D_r, RS1_D_r, RS2_D_r : STD_LOGIC_VECTOR(4 downto 0);
    signal PCD_r, PCPlus4D_r : STD_LOGIC_VECTOR(31 downto 0);
    
    component Control_Unit_Top
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
    end component;
    component Register_File
        Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            WE3  : in  STD_LOGIC;
            WD3  : in  STD_LOGIC_VECTOR(31 downto 0);
            A1   : in  STD_LOGIC_VECTOR(4 downto 0);
            A2   : in  STD_LOGIC_VECTOR(4 downto 0);
            A3   : in  STD_LOGIC_VECTOR(4 downto 0);
            RD1  : out STD_LOGIC_VECTOR(31 downto 0);
            RD2  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component Sign_Extend
        Port ( 
            input      : in  STD_LOGIC_VECTOR(31 downto 0);
            ImmSrc  : in  STD_LOGIC_VECTOR(1 downto 0);
            Imm_Ext : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin
    controlunit: Control_Unit_Top
        port map (
            Op => InstrD(6 downto 0), RegWrite   => RegWriteD, ImmSrc     => ImmSrcD, ALUSrc     => ALUSrcD,
             MemWrite => MemWriteD, ResultSrc => ResultSrcD, Branch     => BranchD,
             funct3 => InstrD(14 downto 12), funct7 => InstrD(31 downto 25), ALUControl => ALUControlD
        );
    
    regfile: Register_File
        port map (
            clk => clk, rst => rst,WE3 => RegWriteW,WD3 => ResultW, A1  => InstrD(19 downto 15), A2  => InstrD(24 downto 20), A3  => RDW, RD1 => RD1_D, RD2 => RD2_D
        );
    
    extend: Sign_Extend
        port map ( input=> InstrD,Imm_Ext => Imm_Ext_D, ImmSrc  => ImmSrcD );
    
    process(clk, rst)
    begin
        if rst = '0' then
            RegWriteD_r <= '0';
            ALUSrcD_r <= '0';
            MemWriteD_r <= '0';
            ResultSrcD_r <= '0';
            BranchD_r <= '0';
            ALUControlD_r <= "000";
            RD1_D_r <= (others => '0');
            RD2_D_r <= (others => '0');
            Imm_Ext_D_r <= (others => '0');
            RD_D_r <= (others => '0');
            PCD_r <= (others => '0');
            PCPlus4D_r <= (others => '0');
            RS1_D_r <= (others => '0');
            RS2_D_r <= (others => '0');
        elsif rising_edge(clk) then
            RegWriteD_r <= RegWriteD;
            ALUSrcD_r <= ALUSrcD;
            MemWriteD_r <= MemWriteD;
            ResultSrcD_r <= ResultSrcD;
            BranchD_r <= BranchD;
            ALUControlD_r <= ALUControlD;
            RD1_D_r <= RD1_D;
            RD2_D_r <= RD2_D;
            Imm_Ext_D_r <= Imm_Ext_D;
            RD_D_r <= InstrD(11 downto 7);
            PCD_r <= PCD;
            PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD(19 downto 15);
            RS2_D_r <= InstrD(24 downto 20);
        end if;
    end process;
    RegWriteE <= RegWriteD_r;
    ALUSrcE <= ALUSrcD_r;
    MemWriteE <= MemWriteD_r;
    ResultSrcE <= ResultSrcD_r;
    BranchE <= BranchD_r;
    ALUControlE <= ALUControlD_r;
    RD1_E <= RD1_D_r;
    RD2_E <= RD2_D_r;
    Imm_Ext_E <= Imm_Ext_D_r;
    RD_E <= RD_D_r;
    PCE <= PCD_r;
    PCPlus4E <= PCPlus4D_r;
    RS1_E <= RS1_D_r;
    RS2_E <= RS2_D_r;

end Behavioral;