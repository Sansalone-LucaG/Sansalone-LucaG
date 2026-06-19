library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity AdderTree_v3 is
    Port (
        clk, rstn, en : in  std_logic;
        -- Ingressi a 11 bit dal Laplacian Filter
        p0, p1, p2, p3, p4, p5, p6, p7, p8 : in std_logic_vector(10 downto 0);
        -- Risultato finale a 16 bit
        result : out std_logic_vector(15 downto 0)
    );
end entity;

architecture Behavioral of AdderTree_v3 is

    component CSA is
        Generic (N : integer := 15);
        Port (
            x, y, z : in std_logic_vector(N-1 downto 0);
            Sum, Carry    : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    component RCA is
        generic ( N : integer := 16 );
        Port ( A, B : in  std_logic_vector(N-1 downto 0);
               Sum  : out std_logic_vector(N downto 0)
            );
    end component;
    
    -- Segnali estesi a 15 bit per uniformare l'albero
        signal e0, e1, e2, e3, e4, e5, e6, e7, e8 : std_logic_vector(14 downto 0);
        
    -- Uscite Livello 1 (9 ingressi -> 6 uscite)
        signal S1_1, C1_1, S1_2, C1_2, S1_3, C1_3 : std_logic_vector(14 downto 0);
	-- Registri di Pipeline 1
		signal r0_S1, r0_C1, r0_S2, r0_C2, r0_S3, r0_C3 : std_logic_vector(14 downto 0);
		
    -- Uscite Livello 2 (6 ingressi -> 4 uscite)
        signal S2_1, C2_1, S2_2, C2_2 : std_logic_vector(14 downto 0);
    -- Registri di Pipeline 2
        signal r1_S1, r1_C1, r1_S2, r1_C2 : std_logic_vector(14 downto 0);
        
    -- Uscite Livello 3 (3 ingressi -> 2 uscite)
        signal S3_1, C3_1 : std_logic_vector(14 downto 0);
    -- Registri di Pipeline 3
    	signal r2_S1, r2_C1 : std_logic_vector(14 downto 0);
        
    -- Uscite Livello 4 (3 ingressi (2+C2_2) -> 2 uscite finali)
       signal S4_1, C4_1 : std_logic_vector(14 downto 0);
    -- Registri di Pipeline 4
        signal r3_S, r3_C : std_logic_vector(14 downto 0);

    -- Somma Finale Uscita RCA
        signal final_sum : std_logic_vector(15 downto 0);

begin

    -- Estensione del segno (da 11 a 15 bit) replicando il MSB (bit 10)
    e0 <= p0(10) & p0(10) & p0(10) & p0(10) & p0;
    e1 <= p1(10) & p1(10) & p1(10) & p1(10) & p1;
    e2 <= p2(10) & p2(10) & p2(10) & p2(10) & p2;
    e3 <= p3(10) & p3(10) & p3(10) & p3(10) & p3;
    e4 <= p4(10) & p4(10) & p4(10) & p4(10) & p4;
    e5 <= p5(10) & p5(10) & p5(10) & p5(10) & p5;
    e6 <= p6(10) & p6(10) & p6(10) & p6(10) & p6;
    e7 <= p7(10) & p7(10) & p7(10) & p7(10) & p7;
    e8 <= p8(10) & p8(10) & p8(10) & p8(10) & p8;

    -- =========================================================
    -- ALBERO CARRY-SAVE 
    -- =========================================================
    -- Livello 1
    CSA1_1: CSA generic map(15) port map(e0, e1, e2, S1_1, C1_1);
    CSA1_2: CSA generic map(15) port map(e3, e4, e5, S1_2, C1_2);
    CSA1_3: CSA generic map(15) port map(e6, e7, e8, S1_3, C1_3);
    -- Livello 2
    CSA2_1: CSA generic map(15) port map(r0_S1, r0_C1, r0_S2, S2_1, C2_1);
    CSA2_2: CSA generic map(15) port map(r0_C2, r0_S3, r0_C3, S2_2, C2_2);
    -- Livello 3 
    CSA3_1: CSA generic map(15) port map(r1_S1, r1_C1, r1_S2, S3_1, C3_1);
    -- Livello 4 
    CSA4_1: CSA generic map(15) port map(r2_S1, r2_C1, r1_C2, S4_1, C4_1);

    -- =========================================================
    -- SOMMATORE FINALE -- STEP 3 CSA
    -- =========================================================
    
    STE_3: RCA generic map(15) port map( r3_S,  r3_C, final_sum);

    -- =========================================================
    -- PIPELINE
    -- =========================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
            	r0_S1 <= (others=>'0'); r0_C1 <= (others=>'0'); 
            	r0_s2 <= (others=>'0'); r0_C2 <= (others=>'0'); 
            	r0_S3 <= (others=>'0'); r0_C3 <= (others=>'0'); 
                r1_S1 <= (others=>'0'); r1_C1 <= (others=>'0');
                r1_S2 <= (others=>'0'); r1_C2 <= (others=>'0');
                r2_S1 <= (others=>'0'); r2_C1 <= (others=>'0');
                r3_S  <= (others=>'0'); r3_C  <= (others=>'0');
                result <= (others=>'0');
            elsif en = '1' then
            	-- Registrazione dopo Livello 1            	
            	r0_S1 <= S1_1; 	r0_C1 <= C1_1;
				r0_S2 <= S1_2; 	r0_C2 <= C1_2;
				r0_S3 <= S1_3; 	r0_C3 <= C1_3;
			
                -- Registrazione dopo Livello 2
                r1_S1 <= S2_1; 	r1_C1 <= C2_1;
                r1_S2 <= S2_2; 	r1_C2 <= C2_2;
                
                --Registrazione dopo Livello 3
                r2_S1 <= S3_1; 	r2_C1 <= C3_1;
                
                -- Registrazione dopo Livello 4 
                r3_S <= S4_1; 	r3_C <= C4_1;
                
                -- Output
                result <= final_sum;
                
            end if;
        end if;
    end process;

end architecture;