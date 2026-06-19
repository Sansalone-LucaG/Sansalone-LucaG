library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LaplacianFilter_v2 is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        p00, p01, p02 : in std_logic_vector(7 downto 0);
        p10, p11, p12 : in std_logic_vector(7 downto 0);
        p20, p21, p22 : in std_logic_vector(7 downto 0);
        
        -- OTTIMIZZAZIONE: Output ridotto da 16 bit a 11 bit (10 dati + 1 segno)
        s00, s01, s02 : out std_logic_vector(10 downto 0);
        s10, s11, s12 : out std_logic_vector(10 downto 0);
        s20, s21, s22 : out std_logic_vector(10 downto 0)
    );
end entity;

architecture Behavioral of LaplacianFilter_v2 is

    component CLA_Adder is
        Generic (N : integer);
        Port (
            A, B : in std_logic_vector(N-1 downto 0);
            Cin  : in std_logic;
            Sum  : out std_logic_vector(N downto 0) 
        );
    end component;

    -- Costante zero dimensionata a 11 bit
    constant ZERO: std_logic_vector(10 downto 0) := (others => '0');

    -- Segnali interni a 11 bit (not A)
    signal p01_inv, p10_inv, p12_inv, p21_inv : std_logic_vector(10 downto 0);
    
    -- Output somma temporaneo del complemento a 2
    signal sum_01, sum_10, sum_12, sum_21 : std_logic_vector(11 downto 0);

    -- Segnale per il pixel centrale
    signal p_center : std_logic_vector(10 downto 0);

begin

    -- Filtro Laplaciano
    -- |0 -1 0 |    => p01 x -1
    -- |-1 4 -1|    => p10, p12 x -1    p11 x 4
    -- |0 -1 0 |    => p21 x -1
    
    -- 1. PREPARAZIONE DATI (11 BIT)
    
    -- Centro (x4): Estendiamo il pixel (8 bit) con un bit 0 di segno davanti e due shift (moltiplicazione x4) "00" dietro
    p_center <= '0' & p11 & "00"; 

    -- Vicini (Inversione per complemento a 2):
    -- Estendiamo a 11 bit (con zeri davanti) e poi neghiamo tutto.
    p01_inv <= not ("000" & p01);
    p10_inv <= not ("000" & p10);
    p12_inv <= not ("000" & p12);
    p21_inv <= not ("000" & p21);


    -- 2. CALCOLO COMPLEMENTO A 2 (ADDER 11 BIT)
    -- Input invertito + 1
    
    CLA_01: CLA_Adder generic map (N => 11) port map (A => p01_inv, B => ZERO, Cin => '1', Sum => sum_01);
    CLA_10: CLA_Adder generic map (N => 11) port map (A => p10_inv, B => ZERO, Cin => '1', Sum => sum_10);
    CLA_12: CLA_Adder generic map (N => 11) port map (A => p12_inv, B => ZERO, Cin => '1', Sum => sum_12);
    CLA_21: CLA_Adder generic map (N => 11) port map (A => p21_inv, B => ZERO, Cin => '1', Sum => sum_21);


    -- 3. REGISTRAZIONE OUTPUT
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                s00 <= (others => '0'); s01 <= (others => '0'); s02 <= (others => '0');
                s10 <= (others => '0'); s11 <= (others => '0'); s12 <= (others => '0');
                s20 <= (others => '0'); s21 <= (others => '0'); s22 <= (others => '0');
            else
                -- Coefficienti 0
                s00 <= (others => '0'); s02 <= (others => '0');
                s20 <= (others => '0'); s22 <= (others => '0');

                -- Coefficienti -1 (Prendiamo gli 11 bit del risultato)
                s01 <= sum_01(10 downto 0);
                s10 <= sum_10(10 downto 0);
                s12 <= sum_12(10 downto 0);
                s21 <= sum_21(10 downto 0);

                -- Coefficiente 4
                s11 <= p_center;
            end if;
        end if;
    end process;

end architecture;