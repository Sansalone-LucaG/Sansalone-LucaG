library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity AdderTree_v2 is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        en     : in  std_logic;
        -- OTTIMIZZAZIONE: Ingressi ridotti da 16 a 11 bit
        p0, p1, p2, p3, p4, p5, p6, p7, p8 : in std_logic_vector(10 downto 0);
        -- OTTIMIZZAZIONE: Risultato finale ridotto da 20 a 15 bit
        result : out std_logic_vector(14 downto 0)
    );
end entity;

architecture Behavioral of AdderTree_v2 is

    component CLA_Adder is
        Generic (N : integer);
        Port (
            A, B : in std_logic_vector(N-1 downto 0);
            Cin  : in std_logic;
            Sum  : out std_logic_vector(N downto 0) 
        );
    end component;

    -- STADIO 1: 11 bit in -> 12 bit out
    signal s1_add0, s1_add1, s1_add2, s1_add3 : std_logic_vector(11 downto 0);
    signal r1_add0, r1_add1, r1_add2, r1_add3 : std_logic_vector(11 downto 0);

    -- STADIO 2: 12 bit in -> 13 bit out
    signal s2_add01, s2_add23 : std_logic_vector(12 downto 0);
    signal r2_add01, r2_add23 : std_logic_vector(12 downto 0);

    -- STADIO 3: 13 bit in -> 14 bit out
    signal s3_add0123 : std_logic_vector(13 downto 0);
    signal r3_add0123 : std_logic_vector(13 downto 0);

    -- STADIO 4 (Finale): 14 bit in -> 15 bit out
    signal s4_final   : std_logic_vector(14 downto 0);

    -- Pipeline per P8 (11 bit)
    signal r_p8_v1, r_p8_v2, r_p8_v3 : std_logic_vector(10 downto 0);
    
    -- Segnale per l'estensione del segno di p8 a 14 bit (uguale a r3_add0123)
    signal r_p8_v3_ext : std_logic_vector(13 downto 0);

begin


    -- STADIO 1: Somma delle prime 4 coppie (11 -> 12 bit)
    ADD1_0: CLA_Adder generic map(11) port map(p0, p1, '0', s1_add0);
    ADD1_1: CLA_Adder generic map(11) port map(p2, p3, '0', s1_add1);
    ADD1_2: CLA_Adder generic map(11) port map(p4, p5, '0', s1_add2);
    ADD1_3: CLA_Adder generic map(11) port map(p6, p7, '0', s1_add3);

    -- STADIO 2: Somma risultati r1 (12 -> 13 bit)
    ADD2_0: CLA_Adder generic map(12) port map(r1_add0, r1_add1, '0', s2_add01);
    ADD2_1: CLA_Adder generic map(12) port map(r1_add2, r1_add3, '0', s2_add23);

    -- STADIO 3: Somma risultati r2 (13 -> 14 bit)
    ADD3_0: CLA_Adder generic map(13) port map(r2_add01, r2_add23, '0', s3_add0123);


    -- Estensione di segno di p8 da 11 a 14 bit.
    r_p8_v3_ext <= r_p8_v3(10) & r_p8_v3(10) & r_p8_v3(10) & r_p8_v3;


    -- STADIO 4: Somma finale col 9° pixel (estensione segno manuale)   
    ADD4_F: CLA_Adder generic map(14) port map(
        A   => r3_add0123, 
        B   => r_p8_v3_ext, 
        Cin => '0',
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
                
                -- Ritardo del 9° pixel per allinearlo alla pipline
                r_p8_v1 <= p8;
                r_p8_v2 <= r_p8_v1;
                r_p8_v3 <= r_p8_v2;
                
                result <= s4_final;
            end if;
        end if;
    end process;

end architecture;