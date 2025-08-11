library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_unit is
    Port ( 
        rst        : in  STD_LOGIC;
        RegWriteM  : in  STD_LOGIC;
        RegWriteW  : in  STD_LOGIC;
        RD_M       : in  STD_LOGIC_VECTOR(4 downto 0);
        RD_W       : in  STD_LOGIC_VECTOR(4 downto 0);
        Rs1_E      : in  STD_LOGIC_VECTOR(4 downto 0);
        Rs2_E      : in  STD_LOGIC_VECTOR(4 downto 0);
        ForwardAE  : out STD_LOGIC_VECTOR(1 downto 0);
        ForwardBE  : out STD_LOGIC_VECTOR(1 downto 0)
    );
end hazard_unit;
architecture hazard_unit of hazard_unit is
    begin
        ForwardAE<= "00" when rst='1' else "10" when (RegWriteM='1' and RD_M/="00000" and RD_M=Rs1_E)
        else "01" when (RegWriteW='1' and RD_W/="00000" and RD_W=Rs1_E) else "00";

         ForwardBE<= "00" when rst='1' else "10" when (RegWriteM='1' and RD_M/="00000" and RD_M=Rs2_E)
        else "01" when (RegWriteW='1' and RD_W/="00000" and RD_W=Rs2_E) else "00";
        end ;

