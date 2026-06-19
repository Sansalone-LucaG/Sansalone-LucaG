library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity RO_FCC_5STG is port(
    en: in std_logic;
    osc_out: out std_logic
    );
end entity;

architecture Behavioral of RO_FCC_5STG is

-- Segnali per ingressi e uscite della CARRY4
    signal co1, out1, di1, s1: std_logic_vector(3 downto 0) := (others => '0');
    signal co2, out2, di2, s2: std_logic_vector(3 downto 0) := (others => '0');
    signal ci1, ci2, cy1, cy2: std_logic := '0';

-- Segnali per simulare le LUT del RO_FCC    
    signal lut_nand: std_logic := '0';
    signal lut_pass1, lut_pass2, lut_pass3, lut_pass4: std_logic_vector(1 downto 0) := "00";

begin

-- === 1� CARRY4 ===========================================================

lut_nand    <= en nand Co2(3);      -- Lut Nand, che avvia le oscillazioni con enable alto;
lut_pass1   <= '0' & out1(0);           -- Lut Pass, passa il segnale della XORCY precedente 
lut_pass2   <= '0' & out1(2);           --      all'uscita del MUXCY;

s1    <= lut_pass2(1) & '1' & lut_pass1(1) & lut_nand;      -- select MUXCY;
di1  <= lut_pass2(0) & '1' & lut_pass1(0) & '1';                    -- data in MUXCY;
cy1 <= '0';                                 -- carry di inizzializzazione;
ci1  <= '1';                                 -- carry in;

CARRY4_1 : CARRY4
port map (
   CO => co1,           -- 4-bit carry out;
   O => out1,           -- 4-bit carry chain XOR data out;
   CI => ci1,              -- 1-bit carry cascade input;
   CYINIT => cy1,   -- 1-bit carry initialization;
   DI => di1,             -- 4-bit carry-MUX data in;
   S => s1                  -- 4-bit carry-MUX select input;
);

-- === 2� CARRY4 =============================================================

lut_pass3   <= '0' & out2(0);
lut_pass4   <= '0' & out2(2);

s2   <= lut_pass4(1) & '1' & lut_pass3(1) & '1';     -- select MUXCY;
di2 <= lut_pass4(0) & '1' & lut_pass3(0) & '1';     -- data in MUXCY;
cy2 <= '0';                                 -- carry di inizzializzazione;
ci2  <= co1(3);                         -- carry in, carry out del primo carry4;

CARRY4_2 : CARRY4
port map (
   CO => co2,           -- 4-bit carry out;
   O => out2,           -- 4-bit carry chain XOR data out;
   CI => ci2,              -- 1-bit carry cascade input;
   CYINIT => cy2,   -- 1-bit carry initialization;
   DI => di2,             -- 4-bit carry-MUX data in;
   S => s2                  -- 4-bit carry-MUX select input;
);

-- === Uscita dell'oscillatore ====================================================

osc_out <= out2(3); -- Ultima XORCY della carry-chain

end Behavioral;
