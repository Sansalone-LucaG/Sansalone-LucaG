library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FullAdder is
    Port ( a, b, cin : in std_logic;
           sum, cout : out std_logic);
end entity;

architecture Behavioral of FullAdder is

begin

    sum  <= a xor b xor cin;
    cout <= (a and b) or (cin and (a xor b));
    
end architecture;