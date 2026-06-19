library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CSA is
    Generic (N : integer := 15);
    Port (
        x, y, z : in std_logic_vector(N-1 downto 0);
        Sum, Carry    : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture Behavioral of CSA is
    signal C_temp : std_logic_vector(N-1 downto 0);
begin
    --=== STEP 1 ===--
    -- Somma bit a bit (XOR a 3 ingressi)
    Sum <= x xor y xor z;
    
    -- Calcolo del Carry bit a bit 
    C_temp <= (x and y) or (x and z) or (y and z);
    
    --=== STEP 2 ===--
    -- Shift a sinistra di 1 posizione del vettore dei riporti
    Carry <= C_temp(N-2 downto 0) & '0';
end architecture;