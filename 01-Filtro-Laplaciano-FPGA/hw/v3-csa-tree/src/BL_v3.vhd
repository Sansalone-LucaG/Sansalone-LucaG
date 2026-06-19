library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity BufferLine_v3 is
generic(ncol:integer:=32);
port(s_axis_clk,s_axis_rstn:in std_logic;
     s_axis_tvalid:in std_logic;
     s_axis_tlast:in std_logic;
     s_axis_tready:out std_logic;
     s_axis_tdata:in std_logic_vector(7 downto 0);
     m_axis_tvalid:out std_logic;
     m_axis_tlast:out std_logic;
     m_axis_tready:in std_logic;
     m_axis_tdata:out std_logic_vector(15 downto 0)); -- siamo passati da 3 a 2 byte
end entity;

architecture Behavioral of BufferLine_v3 is

	component LaplacianFilter_v3 is
        Port (
            clk : in std_logic;
            rst_n : in std_logic;
            p00, p01, p02 : in std_logic_vector(7 downto 0);
            p10, p11, p12 : in std_logic_vector(7 downto 0);
            p20, p21, p22 : in std_logic_vector(7 downto 0);
            
            -- OTTIMIZZAZIONE: Output ridotto da 16 bit a 11 bit (10 dati + 1 segno)
            s00, s01, s02 : out std_logic_vector(10 downto 0);
            s10, s11, s12 : out std_logic_vector(10 downto 0);
            s20, s21, s22 : out std_logic_vector(10 downto 0)
        );
	end component;
	
	component AdderTree_v3 is
        Port (
            clk, rstn, en : in  std_logic;
            -- Ingressi a 11 bit dal Laplacian Filter
            p0, p1, p2, p3, p4, p5, p6, p7, p8 : in std_logic_vector(10 downto 0);
            -- Risultato finale a 15 bit
            result : out std_logic_vector(15 downto 0)
        );
	end component;

-- FSM gestione valid e ready
	type state is (s0,s1,s2,s3);
	signal state_curr, state_next: state;

-- Buffer line pixels
	signal d00,d01,d02,d10,d11,d12,d20,d21,d22,buffer1_out,buffer2_out:std_logic_vector(7 downto 0);
	type reg_array is array (ncol-4 downto 0) of std_logic_vector(7 downto 0);
	signal buffer1,buffer2:reg_array;

-- Pixels filtrati
	signal d0, d1, d2, d3, d4, d5, d6, d7, d8: std_logic_vector (10 downto 0);

-- Adder tree
	signal outputdata:std_logic_vector(15 downto 0);

-- Latenza
	signal count_latencyin, count_latencyout:unsigned(9 downto 0);
	
	signal data_valid, en_countout:std_logic;

-- REGISTRI DI OUTPUT 
    signal r_tvalid : std_logic := '0';
    signal r_tlast  : std_logic := '0';
    
    signal enable : std_logic := '0';

begin

	s_axis_tready<=m_axis_tready;
-- Assegnazione diretta dei registri alle porte di uscita
    m_axis_tvalid <= r_tvalid;
    m_axis_tlast  <= r_tlast;

	enable <= (s_axis_tvalid and m_axis_tready);
--------------------------------------------------------------
-- 1' Riga Buffer Line
--------------------------------------------------------------

process(s_axis_clk)
begin
   if(rising_edge(s_axis_clk))then
      if(s_axis_rstn='0')then
         d00<=(others=>'0');
         d01<=(others=>'0');
         d02<=(others=>'0');
      else
         if(s_axis_tvalid='1' and m_axis_tready='1')then
            d00<=s_axis_tdata;
         end if;
         if(m_axis_tready='1')then
            d01<=d00;
            d02<=d01;
         end if;
      end if;
   end if;
end process;

--------------------------------------------------------------
-- 1' Buffer
--------------------------------------------------------------

process(s_axis_clk)
begin
   if(rising_edge(s_axis_clk))then
      if(s_axis_rstn='0')then
         resetaLL: for j in 0 to ncol-4 loop
                       buffer1(j)<=(others=>'0');
                   end loop;
      else
         if(m_axis_tready='1')then
            genff: for j in 1 to ncol-4 loop
                       buffer1(j)<=buffer1(j-1);
                   end loop;
                   buffer1(0)<=d02;
         end if;
      end if;
   end if;
end process;

buffer1_out<=buffer1(ncol-4);

--------------------------------------------------------------
-- 2' Riga Buffer Line
--------------------------------------------------------------

process(s_axis_clk)
begin
   if(rising_edge(s_axis_clk))then
      if(s_axis_rstn='0')then
         d10<=(others=>'0');
         d11<=(others=>'0');
         d12<=(others=>'0');
      else
         if(m_axis_tready='1')then
            d10<=buffer1_out;
            d11<=d10;
            d12<=d11;
         end if;
      end if;
   end if;
end process;

--------------------------------------------------------------
-- 2' Buffer
--------------------------------------------------------------

process(s_axis_clk)
begin
   if(rising_edge(s_axis_clk))then
      if(s_axis_rstn='0')then
         resetaLL: for j in 0 to ncol-4 loop
                       buffer2(j)<=(others=>'0');
                   end loop;
      else
         if(m_axis_tready='1')then
            genff: for j in 1 to ncol-4 loop
                       buffer2(j)<=buffer2(j-1);
                   end loop;
                   buffer2(0)<=d12;
         end if;
      end if;
   end if;
end process;

buffer2_out<=buffer2(ncol-4);

--------------------------------------------------------------
-- 3' Riga Buffer Line
--------------------------------------------------------------

process(s_axis_clk)
begin
   if(rising_edge(s_axis_clk))then
      if(s_axis_rstn='0')then
         d20<=(others=>'0');
         d21<=(others=>'0');
         d22<=(others=>'0');
      else
         if(m_axis_tready='1')then
            d20<=buffer2_out;
            d21<=d20;
            d22<=d21;
         end if;
      end if;
   end if;
end process;

--------------------------------------------------------------
-- Applicazione del Filtro
--------------------------------------------------------------

LF: LaplacianFilter_v3 port map(
	clk => s_axis_clk,
	rst_n => s_axis_rstn,
	p00 => d00, 	p01 => d01,	p02 => d02,
	p10 => d10,	p11 => d11,	    p12 => d12,
	p20 => d20,	p21 => d21,	p22 => d22,
	s00 => d0,	    s01 => d1,	    s02 => d2,
	s10 => d3,	    s11 => d4,	    s12 => d5,
	s20 => d6,	    s21 => d7,      s22 => d8
);

--------------------------------------------------------------
-- Adder Tree
--------------------------------------------------------------

AT: AdderTree_v3 port map(
	clk => s_axis_clk,
	rstn => s_axis_rstn,
	en => enable,
	p0 => d0,	p1 => d1,	p2 => d2,
	p3 => d3,	p4 => d4,	p5 => d5,
	p6 => d6,	p7 => d7,	p8 => d8,
	result => outputdata
);

--==================================
--  FSM Gestione valid e ready
--==================================

process(s_axis_clk)
    begin
    if(rising_edge(s_axis_clk)) then
       if(s_axis_rstn='0')then
          state_curr <= s0;
          r_tvalid   <= '0';
          r_tlast    <= '0';
       else
          -- Default assignments
          r_tlast <= '0'; 
          
          case state_curr is
          
          when s0 =>
             r_tvalid <= '0';
             if(s_axis_rstn='1')then
                state_curr <= s1;
             end if;

          when s1 =>
             -- In attesa di riempire la pipeline
             if(count_latencyin > 2*ncol+5) then
                state_curr <= s2;
                r_tvalid   <= '1'; -- Preparo il Valid ALTO per il prossimo ciclo (S2)
             else
                state_curr <= s1;
                r_tvalid   <= '0';
             end if;

          when s2 =>
             -- Streaming dati attivi
             r_tvalid <= '1'; -- Mantengo alto
             
             if(s_axis_tlast='1')then
                state_curr <= s3;
             end if;

          when s3 =>
             -- Svuotamento pipeline finale
             r_tvalid <= '1'; -- Mantengo alto finché non finisco
             
             -- Gestione TLAST Registrata
             if(count_latencyout = 4) then
                 r_tlast <= '1';
             end if;

             if(count_latencyout > 5) then
                state_curr <= s0;
                r_tvalid   <= '0'; -- Fine trasmissione
             end if;
             
          end case;
       end if;
    end if;
    end process;

    -- Contatori Latency
    process(s_axis_clk)
    begin
    if(rising_edge(s_axis_clk)) then
       if(s_axis_rstn='0')then
          en_countout<='0';
          count_latencyin<=(others=>'0');
          count_latencyout<=(others=>'0');
       else
          if(s_axis_tvalid='1' and m_axis_tready='1')then 
             count_latencyin<=count_latencyin+1;
          end if;
          
          if(s_axis_tlast='1')then
             en_countout<='1';
          end if;
          
          if(en_countout='1')then
             if (m_axis_tready='1') then -- Conta solo se il master downstream accetta dati
                 count_latencyout<=count_latencyout+1;
             end if;
             
             -- Reset contatori alla fine
             if(count_latencyout > 5) then
                 en_countout <= '0';
                 count_latencyin <= (others=>'0');
                 count_latencyout <= (others=>'0');
             end if;
          else
             count_latencyout<=(others=>'0');
          end if;
       end if;
    end if;
    end process;

m_axis_tdata<= outputdata;


end architecture;
