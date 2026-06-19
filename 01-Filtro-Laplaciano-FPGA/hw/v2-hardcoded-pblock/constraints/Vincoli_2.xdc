#-----------------------------------------------------------------------
# 1. TIMING CONSTRAINTS
#-----------------------------------------------------------------------

create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports s_axis_clk]

#-----------------------------------------------------------------------
# 2. INPUT DELAY (Vincoli per gli ingressi)
#-----------------------------------------------------------------------

set_input_delay -clock sys_clk 1.000 [get_ports s_axis_rstn]
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tvalid]
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tlast]
set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tready]

set_input_delay -clock sys_clk 1.000 [get_ports s_axis_tdata*]

#-----------------------------------------------------------------------
# 3. OUTPUT DELAY (Vincoli per le uscite)
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# 4. POWER CONSTRAINTS (Carico capacitivo)
#-----------------------------------------------------------------------

set_load 5.000 [get_ports  s_axis_tready]
set_load 5.000 [get_ports m_axis_tvalid]
set_load 5.000 [get_ports m_axis_tlast]

set_load 5.000 [get_ports s_axis_tdata*]


# Pblock per concentrare il placement nella stessa area 
create_pblock pblock_design
add_cells_to_pblock [get_pblocks pblock_design] [get_cells -hierarchical]
resize_pblock [get_pblocks pblock_design] -add {SLICE_X100Y45:SLICE_X120Y70}