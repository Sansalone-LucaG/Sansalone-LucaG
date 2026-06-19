# ------------------------------------------------------------------------------
# 1. TIMING CONSTRAINTS
# ------------------------------------------------------------------------------
# Definiamo il clock a 100 MHz (Periodo 10ns) come nel testbench.
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports s_axis_clk]

# ------------------------------------------------------------------------------
# 2. INPUT DELAY (Vincoli per gli ingressi)
# ------------------------------------------------------------------------------
# Diciamo a Vivado che i dati arrivano 1ns dopo il fronte di clock (simulazione ritardi esterni).
# Applichiamo a tutti gli ingressi tranne il clock.
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_rstn]
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tvalid]
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tlast]
set_input_delay -clock sys_clk 1.000 [get_ports m_axis_tready]

set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tdata*]

# ------------------------------------------------------------------------------
# 3. OUTPUT DELAY (Vincoli per le uscite)
# ------------------------------------------------------------------------------
#Non diamo constraints così da non dare scadenze da rispettare sulle uscite a vivado

# ------------------------------------------------------------------------------
# 4. POWER CONSTRAINTS (Carico Capacitivo)
# ------------------------------------------------------------------------------
# Simuliamo un carico di 5pF su ogni pin di uscita per avere una stima di potenza realistica.

set_load 5.000 [get_ports s_axis_tready]
set_load 5.000 [get_ports m_axis_tvalid]
set_load 5.000 [get_ports m_axis_tlast]

set_load 5.000 [get_ports m_axis_tdata*]