library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM_CE_RST is port ( 
    CLK, EN, RST:       in std_logic;
    OUT1, OUT2, OUT3:   in std_logic;
    CE_1, CE_2, CE_3:   out std_logic 
    );
end entity;

architecture Behavioral of FSM_CE_RST is

    -- segnali che ci indicano la fase di riallineamento
    signal REALL_1:  std_logic   := '0'; -- segnale per il 1' SRL    
    signal REALL_2:  std_logic   := '0'; -- segnale per il 2' SRL
    signal REALL_3:  std_logic   := '0'; -- segnale per il 3' SRL
    
    type type_state is (RESET, REALLIGN, END_REALL, NORMAL);
    signal state: type_state := NORMAL;

begin

STATE_MGT:  process(CLK)
    begin
    -- valori di default
        if REALL_1 = '1' then
            CE_1 <= '1';
        else 
            CE_1 <= EN;
        end if;
        if REALL_2 = '1' then
            CE_2 <= '1';
        else 
            CE_2 <= EN;
        end if;
        if REALL_3 = '1' then
            CE_3 <= '1';
        else 
            CE_3 <= EN;
        end if;
        
    if rising_edge(CLK) then     
                
        case state is 
        -- Quando si attiva il reset, mettiamo in funzione gli SRL 
        --  per far tornare il bit '1' all'ultima posizione
            when RESET =>
                REALL_1 <= '1';
                REALL_2 <= '1';
                REALL_3 <= '1';
                CE_1 <= '1';
                CE_2 <= '1';
                CE_3 <= '1';
                state <= REALLIGN;
                
        -- Fase di riallinieamento del bit     
            when REALLIGN =>
                if REALL_1 = '1' then
                    if OUT1 = '1' then
                        REALL_1 <= '0'; 
                        CE_1 <= '0';
                    else
                        CE_1 <= '1';
                    end if;
                end if;
                if REALL_2 = '1' then
                    if OUT2 = '1' then
                        REALL_2 <= '0'; 
                        CE_2 <= '0';
                    else
                        CE_2 <= '1';
                    end if;
                end if;
                if REALL_3 = '1' then
                    if OUT3 = '1' then
                        REALL_3 <= '0'; 
                        CE_3 <= '0';
                    else
                        CE_3 <= '1';
                    end if;
                end if;     
                if REALL_1 = '0' then
                    if REALL_2 = '0' then
                        if REALL_3 = '0' then
                            state <= END_REALL;
                        end if;
                    end if;
                end if;
                
        -- Fase d'attesa, disattiviamo i registri riallineati 
        --  finch� non si disattiver� il reset
            when END_REALL =>
                CE_1 <= '0';
                CE_2 <= '0';
                CE_3 <= '0';
                if RST = '0' then
                    state <= NORMAL;
                end if;
                
        -- normale funzionamento del RNS
            when NORMAL =>                
                CE_1  <=  EN;
                CE_2  <=  EN;
                CE_3  <=  EN;
                if RST = '1' then
                    state <= RESET;
                else
                    state <= NORMAL;
                end if;            
        end case;
        
    end if;
    end process;

end architecture;
