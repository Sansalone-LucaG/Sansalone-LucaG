library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity AdderTree is
    Port (
        clk    : in  std_logic;
        rst	  : in  std_logic;
        en     : in  std_logic;
        -- 9 Ingressi da 16 bit (prodotti parziali estesi)
        p0, p1, p2, p3, p4, p5, p6, p7, p8 : in std_logic_vector(15 downto 0);
        -- Risultato finale a 20 bit
        result : out std_logic_vector(19 downto 0)
    );
end entity;

architecture Behavioral of AdderTree is

    component RCA is
		generic ( N : integer := 16 );
		Port ( A, B : in  std_logic_vector(N-1 downto 0);
			   Sum  : out std_logic_vector(N downto 0));
	end component;

    -- Segnali intermedi per gli stadi dell'albero
    signal s1_add0, s1_add1, s1_add2, s1_add3 : std_logic_vector(16 downto 0);
    signal s2_add01, s2_add23 : std_logic_vector(17 downto 0);
    signal s3_add0123 : std_logic_vector(18 downto 0);
    signal s4_final   : std_logic_vector(19 downto 0);

    -- Registri di pipeline per mantenere la sincronizzazione
    signal r1_add0, r1_add1, r1_add2, r1_add3 : std_logic_vector(16 downto 0);
    signal r2_add01, r2_add23 : std_logic_vector(17 downto 0);
    signal r3_add0123 : std_logic_vector(18 downto 0);
    signal r_p8_v1, r_p8_v2, r_p8_v3 : std_logic_vector(15 downto 0);
    -- Segnale per l'estensione del segno di p8 a 19 bit
	signal r_p8_v3_ext : std_logic_vector(18 downto 0);

begin

    -- STADIO 1: Somma delle prime 4 coppie (16 bit -> 17 bit)
    ADD1_0: RCA generic map(16) port map(p0, p1, s1_add0);
    ADD1_1: RCA generic map(16) port map(p2, p3, s1_add1);
    ADD1_2: RCA generic map(16) port map(p4, p5, s1_add2);
    ADD1_3: RCA generic map(16) port map(p6, p7, s1_add3);

    -- STADIO 2: Somma dei risultati r1 (17 bit -> 18 bit)
    ADD2_0: RCA generic map(17) port map(r1_add0, r1_add1, s2_add01);
    ADD2_1: RCA generic map(17) port map(r1_add2, r1_add3, s2_add23);

    -- STADIO 3: Somma dei risultati r2 (18 bit -> 19 bit)
    ADD3_0: RCA generic map(18) port map(r2_add01, r2_add23, s3_add0123);

	-- Estendiamo p8 da 16 a 19 bit replicando il bit di segno (MSB)
	r_p8_v3_ext <= r_p8_v3(15) & r_p8_v3(15) & r_p8_v3(15) & r_p8_v3;
    -- STADIO 4: Somma finale col 9° pixel (estensione segno manuale)
    ADD4_F: RCA generic map(19) port map(
        A => r3_add0123, 
        B => r_p8_v3_ext, 
        Sum => s4_final
    );

    -- Processo di sincronizzazione (Pipeline)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                r1_add0 <= (others => '0'); r1_add1 <= (others => '0');
                r1_add2 <= (others => '0'); r1_add3 <= (others => '0');
                r2_add01 <= (others => '0'); r2_add23 <= (others => '0');
                r3_add0123 <= (others => '0');
                r_p8_v1 <= (others => '0'); r_p8_v2 <= (others => '0'); r_p8_v3 <= (others => '0');
                result <= (others => '0');
            elsif en = '1' then
                -- Registrazione stadi
                r1_add0 <= s1_add0; r1_add1 <= s1_add1;
                r1_add2 <= s1_add2; r1_add3 <= s1_add3;
                
                r2_add01 <= s2_add01; r2_add23 <= s2_add23;
                
                r3_add0123 <= s3_add0123;
                
                -- Ritardo del 9° pixel per allinearlo alla pipeline
                r_p8_v1 <= p8;
                r_p8_v2 <= r_p8_v1;
                r_p8_v3 <= r_p8_v2;
                
                result <= s4_final;
            end if;
        end if;
    end process;

end architecture;