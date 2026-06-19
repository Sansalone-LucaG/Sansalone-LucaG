library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL; -- Fondamentale per la matematica signed

entity LaplacianFilter is
    Port ( 
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        -- I 9 pixel della finestra 3x3
        p00, p01, p02 : in std_logic_vector(7 downto 0);
        p10, p11, p12 : in std_logic_vector(7 downto 0);
        p20, p21, p22 : in std_logic_vector(7 downto 0);
        -- Output filtrato
        s00, s01, s02 : out std_logic_vector(15 downto 0);
        s10, s11, s12 : out std_logic_vector(15 downto 0);
        s20, s21, s22 : out std_logic_vector(15 downto 0)
    );
end entity;

architecture Behavioral of LaplacianFilter is

    component BoothMultiplier is
		Port ( 
			pixel_in : in std_logic_vector(7 downto 0);   
			coeff_in : in std_logic_vector(3 downto 0);   
			product  : out std_logic_vector(13 downto 0)  
		);
	end component;

    -- Coefficienti (std_logic_vector) (filtro laplaciano)
    constant K_00 : std_logic_vector(3 downto 0) := "0000"; -- 0
    constant K_01 : std_logic_vector(3 downto 0) := "1111"; -- -1
    constant K_02 : std_logic_vector(3 downto 0) := "0000"; -- 0
    
    constant K_10 : std_logic_vector(3 downto 0) := "1111"; -- -1
    constant K_11 : std_logic_vector(3 downto 0) := "0100"; -- 4
    constant K_12 : std_logic_vector(3 downto 0) := "1111"; -- -1
    
    constant K_20 : std_logic_vector(3 downto 0) := "0000"; -- 0
    constant K_21 : std_logic_vector(3 downto 0) := "1111"; -- -1
    constant K_22 : std_logic_vector(3 downto 0) := "0000"; -- 0

    -- Segnali per i risultati delle moltiplicazioni (9 risultati da 14 bit)
    signal m0, m1, m2, m3, m4, m5, m6, m7, m8 : std_logic_vector(13 downto 0);

    -- Segnali estesi a 16 bit per la somma
    signal s0, s1, s2, s3, s4, s5, s6, s7, s8 : std_logic_vector(15 downto 0);
    
    -- Segnale di somma totale
    -- signal total_sum : std_logic_vector(15 downto 0);

begin

    -- 1. Istanza dei 9 Moltiplicatori
    -- Prima riga
    BM0: BoothMultiplier port map(p00, K_00, m0);
    BM1: BoothMultiplier port map(p01, K_01, m1);
    BM2: BoothMultiplier port map(p02, K_02, m2);
    -- Seconda riga
    BM3: BoothMultiplier port map(p10, K_10, m3);
    BM4: BoothMultiplier port map(p11, K_11, m4);
    BM5: BoothMultiplier port map(p12, K_12, m5);
    -- Terza riga
    BM6: BoothMultiplier port map(p20, K_20, m6);
    BM7: BoothMultiplier port map(p21, K_21, m7);
    BM8: BoothMultiplier port map(p22, K_22, m8);

    -- 2. Processo di Pipeline (Registri) + Somma
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                s0 <= (others => '0'); s1 <= (others => '0'); s2 <= (others => '0');
                s3 <= (others => '0'); s4 <= (others => '0'); s5 <= (others => '0');
                s6 <= (others => '0'); s7 <= (others => '0'); s8 <= (others => '0');
            else
                -- Estensione del segno manuale da 14 a 16 bit
                s0 <= m0(13) & m0(13) & m0;
                s1 <= m1(13) & m1(13) & m1;
                s2 <= m2(13) & m2(13) & m2;
                
                s3 <= m3(13) & m3(13) & m3;
                s4 <= m4(13) & m4(13) & m4;
                s5 <= m5(13) & m5(13) & m5;
                
                s6 <= m6(13) & m6(13) & m6;
                s7 <= m7(13) & m7(13) & m7;
                s8 <= m8(13) & m8(13) & m8;

                
            end if;
        end if;
    end process;

		s00<=s0;
		s01<=s1;
		s02<=s2;
		
		s10<=s3;
		s11<=s4;
		s12<=s5;
		
		s20<=s6;
		s21<=s7;
		s22<=s8;

end architecture;