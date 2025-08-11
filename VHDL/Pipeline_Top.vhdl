library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pipeline_top is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        Result : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Pipeline_top;

architecture Behavioral of Pipeline_top is

    -- Component declarations
    component fetch_cycle
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            PCSrcE : in STD_LOGIC;
            PCTargetE : in STD_LOGIC_VECTOR(31 downto 0);
            InstrD : out STD_LOGIC_VECTOR(31 downto 0);
            PCD : out STD_LOGIC_VECTOR(31 downto 0);
            PCPlus4D : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component decode_cycle
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            InstrD : in STD_LOGIC_VECTOR(31 downto 0);
            PCD : in STD_LOGIC_VECTOR(31 downto 0);
            PCPlus4D : in STD_LOGIC_VECTOR(31 downto 0);
            RegWriteW : in STD_LOGIC;
            RDW : in STD_LOGIC_VECTOR(4 downto 0);
            ResultW : in STD_LOGIC_VECTOR(31 downto 0);
            RegWriteE : out STD_LOGIC;
            ALUSrcE : out STD_LOGIC;
            MemWriteE : out STD_LOGIC;
            ResultSrcE : out STD_LOGIC;
            BranchE : out STD_LOGIC;
            ALUControlE : out STD_LOGIC_VECTOR(2 downto 0);
            RD1_E : out STD_LOGIC_VECTOR(31 downto 0);
            RD2_E : out STD_LOGIC_VECTOR(31 downto 0);
            Imm_Ext_E : out STD_LOGIC_VECTOR(31 downto 0);
            RD_E : out STD_LOGIC_VECTOR(4 downto 0);
            PCE : out STD_LOGIC_VECTOR(31 downto 0);
            PCPlus4E : out STD_LOGIC_VECTOR(31 downto 0);
            RS1_E : out STD_LOGIC_VECTOR(4 downto 0);
            RS2_E : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;
    
    component execute_cycle
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            RegWriteE : in STD_LOGIC;
            ALUSrcE : in STD_LOGIC;
            MemWriteE : in STD_LOGIC;
            ResultSrcE : in STD_LOGIC;
            BranchE : in STD_LOGIC;
            ALUControlE : in STD_LOGIC_VECTOR(2 downto 0);
            RD1_E : in STD_LOGIC_VECTOR(31 downto 0);
            RD2_E : in STD_LOGIC_VECTOR(31 downto 0);
            Imm_Ext_E : in STD_LOGIC_VECTOR(31 downto 0);
            RD_E : in STD_LOGIC_VECTOR(4 downto 0);
            PCE : in STD_LOGIC_VECTOR(31 downto 0);
            PCPlus4E : in STD_LOGIC_VECTOR(31 downto 0);
            ResultW : in STD_LOGIC_VECTOR(31 downto 0);
            ForwardA_E : in STD_LOGIC_VECTOR(1 downto 0);
            ForwardB_E : in STD_LOGIC_VECTOR(1 downto 0);
            ALU_ResultM : in STD_LOGIC_VECTOR(31 downto 0);
            PCSrcE : out STD_LOGIC;
            PCTargetE : out STD_LOGIC_VECTOR(31 downto 0);
            RegWriteM : out STD_LOGIC;
            MemWriteM : out STD_LOGIC;
            ResultSrcM : out STD_LOGIC;
            RD_M : out STD_LOGIC_VECTOR(4 downto 0);
            PCPlus4M : out STD_LOGIC_VECTOR(31 downto 0);
            WriteDataM : out STD_LOGIC_VECTOR(31 downto 0);
            ALU_ResultM_out : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component memory_cycle
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            RegWriteM : in STD_LOGIC;
            MemWriteM : in STD_LOGIC;
            ResultSrcM : in STD_LOGIC;
            RD_M : in STD_LOGIC_VECTOR(4 downto 0);
            PCPlus4M : in STD_LOGIC_VECTOR(31 downto 0);
            WriteDataM : in STD_LOGIC_VECTOR(31 downto 0);
            ALU_ResultM : in STD_LOGIC_VECTOR(31 downto 0);
            RegWriteW : out STD_LOGIC;
            ResultSrcW : out STD_LOGIC;
            RD_W : out STD_LOGIC_VECTOR(4 downto 0);
            PCPlus4W : out STD_LOGIC_VECTOR(31 downto 0);
            ALU_ResultW : out STD_LOGIC_VECTOR(31 downto 0);
            ReadDataW : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component writeback_cycle
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            ResultSrcW : in STD_LOGIC;
            PCPlus4W : in STD_LOGIC_VECTOR(31 downto 0);
            ALU_ResultW : in STD_LOGIC_VECTOR(31 downto 0);
            ReadDataW : in STD_LOGIC_VECTOR(31 downto 0);
            ResultW : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component hazard_unit
        Port (
            rst : in STD_LOGIC;
            RegWriteM : in STD_LOGIC;
            RegWriteW : in STD_LOGIC;
            RD_M : in STD_LOGIC_VECTOR(4 downto 0);
            RD_W : in STD_LOGIC_VECTOR(4 downto 0);
            Rs1_E : in STD_LOGIC_VECTOR(4 downto 0);
            Rs2_E : in STD_LOGIC_VECTOR(4 downto 0);
            ForwardAE : out STD_LOGIC_VECTOR(1 downto 0);
            ForwardBE : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- Internal signals (equivalent to wires)
    signal PCSrcE : STD_LOGIC;
    signal RegWriteW : STD_LOGIC;
    signal RegWriteE : STD_LOGIC;
    signal ALUSrcE : STD_LOGIC;
    signal MemWriteE : STD_LOGIC;
    signal ResultSrcE : STD_LOGIC;
    signal BranchE : STD_LOGIC;
    signal RegWriteM : STD_LOGIC;
    signal MemWriteM : STD_LOGIC;
    signal ResultSrcM : STD_LOGIC;
    signal ResultSrcW : STD_LOGIC;
    
    signal ALUControlE : STD_LOGIC_VECTOR(2 downto 0);
    signal RD_E : STD_LOGIC_VECTOR(4 downto 0);
    signal RD_M : STD_LOGIC_VECTOR(4 downto 0);
    signal RDW : STD_LOGIC_VECTOR(4 downto 0);
    signal RS1_E : STD_LOGIC_VECTOR(4 downto 0);
    signal RS2_E : STD_LOGIC_VECTOR(4 downto 0);
    
    signal ForwardBE : STD_LOGIC_VECTOR(1 downto 0);
    signal ForwardAE : STD_LOGIC_VECTOR(1 downto 0);
    
    signal PCTargetE : STD_LOGIC_VECTOR(31 downto 0);
    signal InstrD : STD_LOGIC_VECTOR(31 downto 0);
    signal PCD : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4D : STD_LOGIC_VECTOR(31 downto 0);
    signal ResultW : STD_LOGIC_VECTOR(31 downto 0);
    signal RD1_E : STD_LOGIC_VECTOR(31 downto 0);
    signal RD2_E : STD_LOGIC_VECTOR(31 downto 0);
    signal Imm_Ext_E : STD_LOGIC_VECTOR(31 downto 0);
    signal PCE : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4E : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4M : STD_LOGIC_VECTOR(31 downto 0);
    signal WriteDataM : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_ResultM : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4W : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_ResultW : STD_LOGIC_VECTOR(31 downto 0);
    signal ReadDataW : STD_LOGIC_VECTOR(31 downto 0);

begin

    -- Output assignment
    Result <= ResultW(15 downto 0);

    -- Component instantiations
    
    -- Fetch Cycle
    Fetch : fetch_cycle
        port map (
            clk => clk,
            rst => rst,
            PCSrcE => PCSrcE,
            PCTargetE => PCTargetE,
            InstrD => InstrD,
            PCD => PCD,
            PCPlus4D => PCPlus4D
        );

    -- Decode Cycle
    Decode : decode_cycle
        port map (
            clk => clk,
            rst => rst,
            InstrD => InstrD,
            PCD => PCD,
            PCPlus4D => PCPlus4D,
            RegWriteW => RegWriteW,
            RDW => RDW,
            ResultW => ResultW,
            RegWriteE => RegWriteE,
            ALUSrcE => ALUSrcE,
            MemWriteE => MemWriteE,
            ResultSrcE => ResultSrcE,
            BranchE => BranchE,
            ALUControlE => ALUControlE,
            RD1_E => RD1_E,
            RD2_E => RD2_E,
            Imm_Ext_E => Imm_Ext_E,
            RD_E => RD_E,
            PCE => PCE,
            PCPlus4E => PCPlus4E,
            RS1_E => RS1_E,
            RS2_E => RS2_E
        );

    -- Execute Cycle
    Execute : execute_cycle
        port map (
            clk => clk,
            rst => rst,
            RegWriteE => RegWriteE,
            ALUSrcE => ALUSrcE,
            MemWriteE => MemWriteE,
            ResultSrcE => ResultSrcE,
            BranchE => BranchE,
            ALUControlE => ALUControlE,
            RD1_E => RD1_E,
            RD2_E => RD2_E,
            Imm_Ext_E => Imm_Ext_E,
            RD_E => RD_E,
            PCE => PCE,
            PCPlus4E => PCPlus4E,
            ResultW => ResultW,
            ForwardA_E => ForwardAE,
            ForwardB_E => ForwardBE,
            ALU_ResultM => ALU_ResultM,
            PCSrcE => PCSrcE,
            PCTargetE => PCTargetE,
            RegWriteM => RegWriteM,
            MemWriteM => MemWriteM,
            ResultSrcM => ResultSrcM,
            RD_M => RD_M,
            PCPlus4M => PCPlus4M,
            WriteDataM => WriteDataM,
            ALU_ResultM_out => ALU_ResultM
        );

    -- Memory Cycle
    Memory : memory_cycle
        port map (
            clk => clk,
            rst => rst,
            RegWriteM => RegWriteM,
            MemWriteM => MemWriteM,
            ResultSrcM => ResultSrcM,
            RD_M => RD_M,
            PCPlus4M => PCPlus4M,
            WriteDataM => WriteDataM,
            ALU_ResultM => ALU_ResultM,
            RegWriteW => RegWriteW,
            ResultSrcW => ResultSrcW,
            RD_W => RDW,
            PCPlus4W => PCPlus4W,
            ALU_ResultW => ALU_ResultW,
            ReadDataW => ReadDataW
        );

    -- Writeback Cycle
    WriteBack : writeback_cycle
        port map (
            clk => clk,
            rst => rst,
            ResultSrcW => ResultSrcW,
            PCPlus4W => PCPlus4W,
            ALU_ResultW => ALU_ResultW,
            ReadDataW => ReadDataW,
            ResultW => ResultW
        );

    -- Hazard Unit
    Forwarding_block : hazard_unit
        port map (
            rst => rst,
            RegWriteM => RegWriteM,
            RegWriteW => RegWriteW,
            RD_M => RD_M,
            RD_W => RDW,
            Rs1_E => RS1_E,
            Rs2_E => RS2_E,
            ForwardAE => ForwardAE,
            ForwardBE => ForwardBE
        );

end Behavioral;