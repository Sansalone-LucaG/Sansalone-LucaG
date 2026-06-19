library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CLA_Adder is
    Generic (N : integer := 16);
    Port (
        A, B : in std_logic_vector(N-1 downto 0);
        Cin  : in std_logic;
        Sum  : out std_logic_vector(N downto 0) -- Output a N+1 bit
    );
end entity;

architecture Behavioral of CLA_Adder is
    -- Ingressi estesi
    signal A_ext, B_ext :   std_logic_vector(N downto 0);
    -- Generate, Propagate e Carry dimensionati per la somma finale N+1
    signal G : std_logic_vector(N downto 0);  
    signal P : std_logic_vector(N downto 0);  
    signal C : std_logic_vector(N+1 downto 0);    
    
begin

    -- Estensione del segno
    A_ext   <=  A(N-1) & A;
    B_ext   <=  B(N-1) & B;
    
    -- Logica di Generazione e Propagazione
    gen_pg: for i in 0 to N generate
        G(i) <= A_ext(i) and B_ext(i);
        P(i) <= A_ext(i) xor B_ext(i);
    end generate;

    -- Calcolo dei riporti (Look-Ahead)
    C(0) <= Cin;
    gen_carry: for i in 0 to N generate
            C(i+1) <= G(i) or (P(i) and C(i));
        end generate;

    -- Calcolo della Somma finale
    gen_sum: for i in 0 to N generate
        Sum(i) <= P(i) xor C(i);
    end generate;

end architecture;