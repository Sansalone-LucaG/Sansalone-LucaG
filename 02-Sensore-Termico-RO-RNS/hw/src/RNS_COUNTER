library IEEE;
library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RNS_COUNTER is port (
    CLK, EN, RST    : in std_logic;                     -- uscita RO + segnali di sistema 
    A32, A33, A35   : in std_logic_vector(4 downto 0);  -- indirizzi per la lettura
    Q32, Q33, Q35   : out std_logic;                    -- uscite per il decoder
    O32, O33, O35   : out std_logic;                     -- uscite del contatore (fisse)
    -- per CRT
    OFF33   :   out std_logic;
    OFF35   :   out std_logic_vector(2 downto 0)
    );
end entity;

architecture Behavioral of RNS_COUNTER is

component FSM_CE_RST is port ( 
    CLK, EN, RST:       in std_logic;
    OUT1, OUT2, OUT3:   in std_logic;
    CE_1, CE_2, CE_3:   out std_logic 
    );
end component;

    -- Flip_Flop per l'SRL33 e SRL35
    signal FF33     : std_logic := '1';
    signal FF35_0   : std_logic := '0';
    signal FF35_1   : std_logic := '0';
    signal FF35_2   : std_logic := '1';

    -- segnali d'uscita SRL
    signal out32, out33, out35: std_logic := '0';
    
    --Enable d'ingresso agli SRL
    signal CE1, CE2, CE3: std_logic := '0';
    
begin

-- ====== Gestione del Reset ============================
RST_MGT: FSM_CE_RST port map(
    CLK     => CLK,
    EN      => EN,
    RST     => RST,
    OUT1 => out32,
    OUT2 => FF33,
    OUT3 => FF35_2,
    CE_1  => CE1,
    CE_2  => CE2,
    CE_3  => CE3
    );


-- ==================================================
-- ========= SRL di conteggio ==========================

-- SRL modulo 32 (profondit� 32,  A = "11111" -> di default)
SRL32:  SRLC32E
    generic map (
        INIT => X"80000000",     -- inizializzato 1 bit in ultima pos.
        IS_CLK_INVERTED => '0'
    )
    port map (
        Q    => Q32,
        Q31  => out32,
        A    => A32,    -- profondit� di 32 bit di default, indirizzo A32 dinamico
        CE   => CE1,
        CLK  => CLK,
        D    => out32
    );

-- ==================================================
-- SRL modulo 33: 32 bit + flip-flop
SRL33:  SRLC32E
    generic map (
        INIT => X"00000000",     -- inizializzato a 0
        IS_CLK_INVERTED => '0'
    )
    port map (
        Q    => Q33,
        Q31  => out33,
        A    => A33,    -- profondit� di 32 bit di default, indirizzo A33 dinamico
        CE   => CE2,
        CLK  => CLK,
        D    => FF33
    );

-- Flip-flop per 33' bit -> inizializzato a 1 -> bit in ultima pos.
SRL33_FF:   process(clk)
    begin
        if rising_edge(clk) then
            if CE2 = '1' then
                FF33 <= out33;
            end if;
        end if;
    end process;
        
-- ==================================================        
-- SRL modulo 35:  32 + 3 flip-flop
SRL35:  SRLC32E
    generic map (
        INIT => X"00000000",     -- inizializzato a 0
        IS_CLK_INVERTED => '0'
    )
    port map (
        Q    => Q35,
        Q31  => out35,
        A    => A35,    -- profondit� di 32 bit di default, indirizzo A35 dinamico
        CE   => CE3,
        CLK  => CLK,
        D    => FF35_2
    );

-- Flip-Flop per 33', 34' e 35' bit -> FF35_2 inizializzato a 1 -> bit in ultima pos.
SRL35_FF:   process(CLK)
    begin
        if rising_edge(CLK) then
            if CE3 = '1' then
                FF35_2 <= FF35_1;
                FF35_1 <= FF35_0;
                FF35_0 <= out35; 
            end if;
        end if;
    end process;


-- ======================================================
-- ===== Uscite contatore ===============================

    -- uscite del l'ultima posizione -> Q31
    O32 <= out32;
    O33 <= FF33;
    O35 <= FF35_2;
    
    -- uscite per CRT 
    OFF33 <= FF33;
    OFF35(2) <= FF35_2; 
    OFF35(1) <= FF35_1; 
    OFF35(0) <= FF35_0;

end architecture;
