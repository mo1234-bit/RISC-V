library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory_cycle is
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
end memory_cycle;

architecture Behavioral of memory_cycle is

    component Data_Memory
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            WE : in STD_LOGIC;
            A : in STD_LOGIC_VECTOR(31 downto 0);
            WD : in STD_LOGIC_VECTOR(31 downto 0);
            RD : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    signal ReadDataM : STD_LOGIC_VECTOR(31 downto 0);
    signal RegWriteM_r : STD_LOGIC;
    signal ResultSrcM_r : STD_LOGIC;
    signal RD_M_r : STD_LOGIC_VECTOR(4 downto 0);
    signal PCPlus4M_r : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_ResultM_r : STD_LOGIC_VECTOR(31 downto 0);
    signal ReadDataM_r : STD_LOGIC_VECTOR(31 downto 0);

begin

    dmem : Data_Memory
        port map (
            clk => clk,
            rst => rst,
            WE => MemWriteM,
            A => ALU_ResultM,
            WD => WriteDataM,
            RD => ReadDataM
        );

 process(clk, rst)
    begin
        if rst = '0' then
            RegWriteM_r <= '0';
            ResultSrcM_r <= '0';
            RD_M_r <= (others => '0');
            PCPlus4M_r <= (others => '0');
            ALU_ResultM_r <= (others => '0');
            ReadDataM_r <= (others => '0');
        elsif rising_edge(clk) then
            RegWriteM_r <= RegWriteM;
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M;
            ALU_ResultM_r <= ALU_ResultM;
            ReadDataM_r <= ReadDataM;
        end if;
    end process;

    RegWriteW <= RegWriteM_r;
    ResultSrcW <= ResultSrcM_r;
    RD_W <= RD_M_r;
    PCPlus4W <= PCPlus4M_r;
    ALU_ResultW <= ALU_ResultM_r;
    ReadDataW <= ReadDataM_r;

end Behavioral;