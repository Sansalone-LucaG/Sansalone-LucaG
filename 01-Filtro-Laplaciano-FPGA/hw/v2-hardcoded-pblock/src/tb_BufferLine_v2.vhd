library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_BufferLine is
-- Nessuna porta
end tb_BufferLine;

architecture Behavioral of tb_BufferLine is

    -- Dichiarazione del DUT
    component BufferLine is
    generic(ncol:integer:=32);
    port(
        s_axis_clk,s_axis_rstn:in std_logic;
        s_axis_tvalid:in std_logic;
        s_axis_tlast:in std_logic;
        s_axis_tready:out std_logic;
        s_axis_tdata:in std_logic_vector(7 downto 0);
        m_axis_tvalid:out std_logic;
        m_axis_tlast:out std_logic;
        m_axis_tready:in std_logic;
        m_axis_tdata:out std_logic_vector(15 downto 0));
    end component;

    -- Costanti
    constant clk_period : time := 10 ns;
    constant IMG_WIDTH  : integer := 32;
    constant IMG_HEIGHT : integer := 32;
    constant IMG_SIZE   : integer := IMG_WIDTH * IMG_HEIGHT; -- 1024 pixel

    -- Memoria immagine
    type rom_type is array (0 to IMG_SIZE-1) of std_logic_vector(7 downto 0);
    signal img_rom : rom_type;

    -- Segnali interni
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    -- Interfaccia AXI Stream
    signal s_tvalid : std_logic := '0';
    signal s_tlast  : std_logic := '0';
    signal s_tready : std_logic;
    signal s_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    
    signal m_tvalid : std_logic;
    signal m_tlast  : std_logic;
    signal m_tready : std_logic := '1';
    signal m_tdata  : std_logic_vector(15 downto 0);

    -- Indice scorrimento (Contatore semplice)
    signal pixel_idx : integer range 0 to IMG_SIZE := 0;

begin
    ----------------------------------------------------------------------------
    -- 1. Istanza Component
    ----------------------------------------------------------------------------
    DUT: BufferLine
    generic map ( ncol => IMG_WIDTH )
    port map (
        s_axis_clk    => clk,
        s_axis_rstn   => rst_n,
        s_axis_tvalid => s_tvalid,
        s_axis_tlast  => s_tlast,
        s_axis_tready => s_tready,
        s_axis_tdata  => s_tdata,
        m_axis_tvalid => m_tvalid,
        m_axis_tlast  => m_tlast,
        m_axis_tready => m_tready,
        m_axis_tdata  => m_tdata
    );
    
    ----------------------------------------------------------------------------
    -- 2. Generazione Clock
    ----------------------------------------------------------------------------
    clk_proc: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    ----------------------------------------------------------------------------
    -- 3. GENERAZIONE IMMAGINE 
    ----------------------------------------------------------------------------
    gen_rows: for i in 0 to IMG_HEIGHT-1 generate
        gen_cols: for j in 0 to IMG_WIDTH-1 generate
            
            -- Calcoliamo l'indice lineare costante per questa posizione
            constant idx : integer := i * IMG_WIDTH + j;
            
        begin
          -- Se la riga è tra 10 e 22, e la colonna è tra 10 e 22 -> Colore 100
            -- Altrimenti -> Colore 10
            img_rom(idx) <= std_logic_vector(to_unsigned(100, 8)) 
                            when (i >= 10 and i <= 22 and j >= 10 and j <= 22) 
                            else std_logic_vector(to_unsigned(10, 8));
            -- Stiamo generando un quadrato 32x32 con al centro un quadrato 13x13 ( 10<i<22, 10<j<22)
            -- ai bordi avremo colore 10 e nel quadrato centrale colore 100 (più chiaro)                
        end generate gen_cols;
    end generate gen_rows;
    
    ----------------------------------------------------------------------------
    -- 4. PROCESSO DI INVIO STREAMING 
    ----------------------------------------------------------------------------
    stimuli_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                pixel_idx <= 0;
                s_tvalid  <= '0';
                s_tlast   <= '0';
                s_tdata   <= (others => '0');
            else
                -- Controllo fine immagine
                if pixel_idx < IMG_SIZE then
                    
                    s_tvalid <= '1';
                    
                    -- Lettura dalla ROM
                    s_tdata <= img_rom(pixel_idx);
                    
                    -- Gestione TLAST (Ultimo pixel = 1023)
                    if pixel_idx = IMG_SIZE - 1 then
                        s_tlast <= '1';
                    else
                        s_tlast <= '0';
                    end if;

                    -- Incremento indice solo se il ricevitore è pronto
                    if s_tready = '1' then
                        pixel_idx <= pixel_idx + 1;
                    end if;
                    
                else
                    -- Abbiamo finito tutti i pixel
                    s_tvalid <= '0';
                    s_tlast  <= '0';
                    s_tdata  <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 5. Stimolo Reset iniziale
    ----------------------------------------------------------------------------
    reset_proc: process
    begin
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait; 
    end process;

end Behavioral;