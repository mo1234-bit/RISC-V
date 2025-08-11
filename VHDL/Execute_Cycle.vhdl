library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity execute_cycle is
    Port (
        clk,rst,RegWriteE,MemWriteE,ResultSrcE,BranchE,ALUSrcE : in STD_LOGIC;
        ALUControlE : in STD_LOGIC_VECTOR(2 downto 0);
        RD1_E,RD2_E,Imm_Ext_E,PCE,PCPlus4E,ResultW,ALU_ResultM : in STD_LOGIC_VECTOR(31 downto 0);
        RD_E : in STD_LOGIC_VECTOR(4 downto 0);
        ForwardA_E,ForwardB_E : in STD_LOGIC_VECTOR(1 downto 0);
        PCSrcE,RegWriteM,MemWriteM,ResultSrcM : out STD_LOGIC;
        RD_M : out STD_LOGIC_VECTOR(4 downto 0);
        PCPlus4M,WriteDataM,ALU_ResultMout,PCTargetE : out STD_LOGIC_VECTOR(31 downto 0)
    );
end execute_cycle;

architecture execute_cycle of execute_cycle is 
component Mux_3 is
    port(a,b,c:in std_logic_vector (31 downto 0);
    s:in std_logic_vector (1 downto 0);
    d:out std_logic_vector (31 downto 0));
end component ;
component mux is 
    port(a:in std_logic_vector(31 downto 0);
    b:in std_logic_vector(31 downto 0);
    s:in std_logic;
    c:out std_logic_vector(31 downto 0));
end component;
component ALU is
    port(A,B:in std_logic_vector(31 downto 0);
         ALUControl:in std_logic_vector(2 downto 0);
         Carry,OverFlow,Zero,Negative:out std_logic;
         Result:out std_logic_vector (31 downto 0));
end component ALU;
component PC_Adder is
    port (a,b:in std_logic_vector(31 downto 0);
          c:out std_logic_vector(31 downto 0));
 end component PC_Adder;
 signal Src_A : STD_LOGIC_VECTOR(31 downto 0);
    signal Src_B_interim,Src_B,ResultE,PCPlus4E_r,RD2_E_r,ResultE_r : STD_LOGIC_VECTOR(31 downto 0);
    signal ZeroE,RegWriteE_r,MemWriteE_r,ResultSrcE_r,alu_overflow,alu_carry,alu_negative : STD_LOGIC;
    signal RD_E_r : STD_LOGIC_VECTOR(4 downto 0);
    begin
        max1 : Mux_3
        port map ( a => RD1_E, b => ResultW, c => ALU_ResultM,s => ForwardA_E, d => Src_A);
    mux2 : Mux_3
        port map (  a => RD2_E,  b => ResultW,  c => ALU_ResultM,  s => ForwardB_E, d => Src_B_interim );
    alu_mux : mux
        port map ( a => Src_B_interim, b => Imm_Ext_E, s => ALUSrcE, c => Src_B);
    
    alu1 : ALU
        port map ( A => Src_A, B => Src_B, ALUControl => ALUControlE,Result => ResultE,OverFlow => alu_overflow,
         Carry => alu_carry, Zero => ZeroE,Negative => alu_negative);
    adder : PC_Adder
        port map ( a => PCE,  b => Imm_Ext_E,  c => PCTargetE  );

     process(clk, rst)
    begin
        if rst = '0' then
            RegWriteE_r <= '0';
            MemWriteE_r <= '0';
            ResultSrcE_r <= '0';
            RD_E_r <= (others => '0');
            PCPlus4E_r <= (others => '0');
            RD2_E_r <= (others => '0');
            ResultE_r <= (others => '0');
        elsif rising_edge(clk) then
            RegWriteE_r <= RegWriteE;
            MemWriteE_r <= MemWriteE;
            ResultSrcE_r <= ResultSrcE;
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E;
            RD2_E_r <= Src_B_interim;
            ResultE_r <= ResultE;
        end if;
    end process ;
    PCSrcE <= ZeroE and BranchE;
    RegWriteM <= RegWriteE_r;
    MemWriteM <= MemWriteE_r;
    ResultSrcM <= ResultSrcE_r;
    RD_M <= RD_E_r;
    PCPlus4M <= PCPlus4E_r;
    WriteDataM <= RD2_E_r;
    ALU_ResultMout <= ResultE_r;

end ;
