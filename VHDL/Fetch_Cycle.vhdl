library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fetch_cycle is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        PCSrcE : in STD_LOGIC;
        PCTargetE : in STD_LOGIC_VECTOR(31 downto 0);
        InstrD : out STD_LOGIC_VECTOR(31 downto 0);
        PCD : out STD_LOGIC_VECTOR(31 downto 0);
        PCPlus4D : out STD_LOGIC_VECTOR(31 downto 0)
    );
end fetch_cycle;

architecture Behavioral of fetch_cycle is
    component Mux
        Port (
            a : in STD_LOGIC_VECTOR(31 downto 0);
            b : in STD_LOGIC_VECTOR(31 downto 0);
            s : in STD_LOGIC;
            c : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component PC_Module
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            PC_Next : in STD_LOGIC_VECTOR(31 downto 0);
            PC : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component Instruction_Memory
        Port (
            rst : in STD_LOGIC;
            A : in STD_LOGIC_VECTOR(31 downto 0);
            RD : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component PC_Adder
        Port (
            a : in STD_LOGIC_VECTOR(31 downto 0);
            b : in STD_LOGIC_VECTOR(31 downto 0);
            c : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    signal PC_F : STD_LOGIC_VECTOR(31 downto 0);
    signal PCF : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4F : STD_LOGIC_VECTOR(31 downto 0);
    signal InstrF : STD_LOGIC_VECTOR(31 downto 0);
    signal InstrF_reg : STD_LOGIC_VECTOR(31 downto 0);
    signal PCF_reg : STD_LOGIC_VECTOR(31 downto 0);
    signal PCPlus4F_reg : STD_LOGIC_VECTOR(31 downto 0);

begin
    PC_MUX : Mux
        port map (
            a => PCPlus4F,
            b => PCTargetE,
            s => PCSrcE,
            c => PC_F
        );
    Program_Counter : PC_Module
        port map (
            clk => clk,
            rst => rst,
            PC_Next => PC_F,
            PC => PCF
        );
    IMEM : Instruction_Memory
        port map (
            rst => rst,
            A => PCF,
            RD => InstrF
        );
    adder1 : PC_Adder
        port map (
            a => PCF,
            b => x"00000004",
            c => PCPlus4F
        );
         process(clk, rst)
    begin
        if rst = '0' then
            InstrF_reg <= (others => '0');
            PCF_reg <= (others => '0');
            PCPlus4F_reg <= (others => '0');
        elsif rising_edge(clk) then
            InstrF_reg <= InstrF;
            PCF_reg <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end if;
    end process;
    InstrD <= (others => '0') when rst = '0' else InstrF_reg;
    PCD <= (others => '0') when rst = '0' else PCF_reg;
    PCPlus4D <= (others => '0') when rst = '0' else PCPlus4F_reg;

end Behavioral;