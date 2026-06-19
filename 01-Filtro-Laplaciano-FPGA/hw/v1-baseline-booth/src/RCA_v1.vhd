library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RCA is
    generic ( N : integer := 16 );
    Port ( A, B : in  std_logic_vector(N-1 downto 0);
           Sum  : out std_logic_vector(N downto 0));
end entity;

architecture Behavioral of RCA is

    component FullAdder is
        Port ( a, b, cin : in std_logic; 
        sum, cout : out std_logic);
    end component;
    
    signal c : std_logic_vector(N downto 0);
    
begin

    c(0) <= '0';
    
    gen_fa: for i in 0 to N-1 generate
		FA: FullAdder port map(A(i), B(i), c(i), Sum(i), c(i+1));
    end generate;
    
    -- Estensione Segno
    Sum(N) <= c(N) xor A(N-1) xor B(N-1) when (N > 0) else c(N); 
    
end architecture;