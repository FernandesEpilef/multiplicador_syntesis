# coloca 3.0 ns para forçar
create_clock -name clk -period 2.0 -waveform {0 0.5} [get_ports clk]

# para 2.0 ns, que é 500 MHz, dá uma violação de slack de -452 ps

# deixando quse sem tempo
set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]
set_clock_uncertainty 0.01 [get_clocks clk]

# delay para entradas (1.0), exceto o clock
set_input_delay -max 1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]

# delay para todas as saidas (1.0)
# (Nota: "multiplier" no seu script original parecia ser o nome de um módulo, não uma porta)
set_output_delay -max 1.0 -clock clk [all_outputs]

#impede que o Genus ache que as saídas estão conectadas ao nada e calcule o tempo errado
#recomendação divina
set_load 0.010 [all_outputs]
