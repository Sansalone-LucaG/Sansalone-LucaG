library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LaplacianFilter_v3 is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        p00, p01, p02 : in std_logic_vector(7 downto 0);
        p10, p11, p12 : in std_logic_vector(7 downto 0);
        p20, p21, p22 : in std_logic_vector(7 downto 0);
        
        -- Output a 11 bit (10 dati + 1 segno)
        s00, s01, s02 : out std_logic_vector(10 downto 0);
        s10, s11, s12 : out std_logic_vector(10 downto 0);
        s20, s21, s22 : out std_logic_vector(10 downto 0)
    );
end entity;

architecture Behavioral of LaplacianFilter_v3 is

    component RCA is
        generic ( N : integer := 16 );
        Port ( A, B : in  std_logic_vector(N-1 downto 0);
               Sum  : out std_logic_vector(N downto 0)
        );
    end component;

    -- Costante '1' da dare all'RCA per il complemento a 2
    constant ONE : std_logic_vector(9 downto 0) := (0 => '1', others => '0');

    -- Segnali interni a 10 bit (not A)
    signal p01_inv, p10_inv, p12_inv, p21_inv : std_logic_vector(9 downto 0);
    
    -- Output somma temporaneo del complemento a 2 (RCA N=10 -> 11 bit)
    signal sum_01, sum_10, sum_12, sum_21 : std_logic_vector(10 downto 0);

    -- Segnale per il pixel centrale (x4)
    signal p_center : std_logic_vector(10 downto 0);
    
    -- Registri di uscita 
    signal s0, s1, s2, s3, s4, s5, s6, s7, s8 : std_logic_vector(10 downto 0);

begin

    -- Filtro Laplaciano:
    -- | 0  -1  0 |
    -- |-1   4 -1 |
    -- | 0  -1  0 |

    -- =========================================================
    -- 1. PREPARAZIONE DATI
    -- =========================================================

    -- Centro (x4): bit di segno '0' (positivo), pixel, shift sx di 2 (x4)
    p_center <= '0' & p11 & "00";

    -- Vicini: estensione a 10 bit con zeri e inversione per complemento a 2
    p01_inv <= not ("00" & p01);
    p10_inv <= not ("00" & p10);
    p12_inv <= not ("00" & p12);
    p21_inv <= not ("00" & p21);

    -- =========================================================
    -- 2. CALCOLO COMPLEMENTO A 2 (+1 tramite RCA)
    -- =========================================================
    RCA_01: RCA generic map (N => 10) port map (A => p01_inv, B => ONE, Sum => sum_01);
    RCA_10: RCA generic map (N => 10) port map (A => p10_inv, B => ONE, Sum => sum_10);
    RCA_12: RCA generic map (N => 10) port map (A => p12_inv, B => ONE, Sum => sum_12);
    RCA_21: RCA generic map (N => 10) port map (A => p21_inv, B => ONE, Sum => sum_21);

    -- =========================================================
    -- 3. REGISTRAZIONE OUTPUT
    -- =========================================================
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                s0 <= (others => '0'); s1 <= (others => '0'); s2 <= (others => '0');
                s3 <= (others => '0'); s4 <= (others => '0'); s5 <= (others => '0');
                s6 <= (others => '0'); s7 <= (others => '0'); s8 <= (others => '0');
            else
                s0 <= (others => '0');                          -- k = 0
                s1 <= sum_01(9) & sum_01(9 downto 0);          -- k = -1
                s2 <= (others => '0');                          -- k = 0
                
                s3 <= sum_10(9) & sum_10(9 downto 0);          -- k = -1
                s4 <= p_center;                                 -- k = +4
                s5 <= sum_12(9) & sum_12(9 downto 0);          -- k = -1
                
                s6 <= (others => '0');                          -- k = 0
                s7 <= sum_21(9) & sum_21(9 downto 0);          -- k = -1
                s8 <= (others => '0');                          -- k = 0
            end if;
        end if;
    end process;

    s00 <= s0; s01 <= s1; s02 <= s2;
    s10 <= s3; s11 <= s4; s12 <= s5;
    s20 <= s6; s21 <= s7; s22 <= s8;

end architecture;