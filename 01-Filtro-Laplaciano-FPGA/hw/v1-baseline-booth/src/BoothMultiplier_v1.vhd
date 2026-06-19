library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BoothMultiplier is
    Port ( 
        pixel_in : in std_logic_vector(7 downto 0);   
        coeff_in : in std_logic_vector(3 downto 0);   
        product  : out std_logic_vector(13 downto 0)  
    );
end entity;

architecture Behavioral of BoothMultiplier is

    component RCA is
        generic ( N : integer := 16 );
        Port ( A, B : in  std_logic_vector(N-1 downto 0);
               Sum  : out std_logic_vector(N downto 0));
    end component;

    -- SEGNALI DI SUPPORTO
    signal CONST_ONE : std_logic_vector(13 downto 0); -- Vettore che vale "1"

    -- Segnali Moltiplicando
    signal A_pos     : std_logic_vector(13 downto 0); 
    signal A2_pos    : std_logic_vector(13 downto 0); 
    
    -- Segnali per le negazioni (Input e Output RCA)
    signal A_inverted    : std_logic_vector(13 downto 0);
    signal A2_inverted   : std_logic_vector(13 downto 0);
    
    signal A_neg_temp    : std_logic_vector(14 downto 0); -- Uscita RCA (N+1)
    signal A2_neg_temp   : std_logic_vector(14 downto 0); -- Uscita RCA (N+1)

    signal A_neg     : std_logic_vector(13 downto 0); -- Risultato finale -A
    signal A2_neg    : std_logic_vector(13 downto 0); -- Risultato finale -2A
    
    -- Prodotti parziali
    signal PP0         : std_logic_vector(13 downto 0);
    signal PP1         : std_logic_vector(13 downto 0);
    signal PP1_shifted : std_logic_vector(13 downto 0); 

    -- Booth encoding
    signal b0_grp : std_logic_vector(2 downto 0); 
    signal b1_grp : std_logic_vector(2 downto 0); 

    -- Somma finale
    signal sum_final_temp : std_logic_vector(14 downto 0);

begin

    -- Definiamo la costante "1" su 14 bit
    CONST_ONE <= (0 => '1', others => '0'); -- "000...001"

    -------------------------------------------------------------------------
    -- 1. PREPARAZIONE DEL MOLTIPLICANDO (A)
    -------------------------------------------------------------------------
    -- A = Estensione zero del pixel
    A_pos <= "000000" & pixel_in;
    
    -- 2A = Shift logico a sinistra
    A2_pos <= A_pos(12 downto 0) & '0';

    -------------------------------------------------------------------------
    -- CALCOLO DEL COMPLEMENTO A 2 (Sostituzione del +)
    -------------------------------------------------------------------------
    
    -- Calcolo -A: Passo 1 -> Inversione bit
    A_inverted <= not A_pos;

    -- Calcolo -A: Passo 2 -> Somma strutturale con 1
    Neg_A_Adder: RCA
        generic map ( N => 14 )
        port map ( 
            A   => A_inverted,
            B   => CONST_ONE,
            Sum => A_neg_temp 
        );
    -- Prendiamo solo i 14 bit bassi (ignorando il carry out dell'RCA per il complemento a 2)
    A_neg <= A_neg_temp(13 downto 0);


    -- Calcolo -2A: Passo 1 -> Inversione bit
    A2_inverted <= not A2_pos;

    -- Calcolo -2A: Passo 2 -> Somma strutturale con 1
    Neg_2A_Adder: RCA
        generic map ( N => 14 )
        port map ( 
            A   => A2_inverted,
            B   => CONST_ONE,
            Sum => A2_neg_temp 
        );
    A2_neg <= A2_neg_temp(13 downto 0);


    -------------------------------------------------------------------------
    -- 2. BOOTH ENCODER STAGE 0
    -------------------------------------------------------------------------
    b0_grp <= coeff_in(1) & coeff_in(0) & '0';

	-- Implementazione tabella
    -- 000 -> 0
    -- 001 -> +A
    -- 010 -> +A
    -- 011 -> +2A
    -- 100 -> -2A
    -- 101 -> -A
    -- 110 -> -A
    -- 111 -> 0
    process(b0_grp, A_pos, A_neg, A2_pos, A2_neg)
    begin
        case b0_grp is
            when "001" | "010" => PP0 <= A_pos;     
            when "011"         => PP0 <= A2_pos;    
            when "100"         => PP0 <= A2_neg;    
            when "101" | "110" => PP0 <= A_neg;     
            when others        => PP0 <= (others => '0'); 
        end case;
    end process;

    -------------------------------------------------------------------------
    -- 3. BOOTH ENCODER STAGE 1
    -------------------------------------------------------------------------
    b1_grp <= coeff_in(3) & coeff_in(2) & coeff_in(1);

    process(b1_grp, A_pos, A_neg, A2_pos, A2_neg)
    begin
        case b1_grp is
            when "001" | "010" => PP1 <= A_pos;     
            when "011"         => PP1 <= A2_pos;    
            when "100"         => PP1 <= A2_neg;    
            when "101" | "110" => PP1 <= A_neg;     
            when others        => PP1 <= (others => '0'); 
        end case;
    end process;

    -------------------------------------------------------------------------
    -- 4. SOMMA FINALE CON RCA
    -------------------------------------------------------------------------
    -- Il PP1 ha peso 2^2 rispetto a PP0
    -- Quindi dobbiamo shiftare PP1 a sinistra di 2 posizioni.
    PP1_shifted <= PP1(11 downto 0) & "00";

	-- Somma finale dei prodotti parziali
    Final_Adder: RCA
        generic map ( N => 14 )
        port map ( 
            A   => PP0,
            B   => PP1_shifted,
            Sum => sum_final_temp
        );

    product <= sum_final_temp(13 downto 0);

end architecture;