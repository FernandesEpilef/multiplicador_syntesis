


# 1. Definição do Clock
# Cria o clock 'clk' amarrado à porta física 'clk_i'
# Mudando de 10.0 para 3.0 ns
create_clock -name clk -period 3.0 -waveform {0 1.5} [get_ports clk_i]

# 2. Modelagem do Clock (Transição e Incerteza)
# Aplicado ao objeto 'clk', não à porta. 
# 0.01 ns (10 ps) é um valor agressivo/apertado para incerteza, mas válido.
set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]
set_clock_uncertainty 0.01 [get_clocks clk]

# 3. Delays de Entrada e Saída
# Aplica um atraso de 1.0 ns para TODAS as entradas (exceto o próprio pino de clock)
set_input_delay -max 1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk_i]]

# Aplica um atraso de 1.0 ns para TODAS as saídas
# (Nota: "multiplier" no seu script original parecia ser o nome de um módulo, não uma porta)
set_output_delay -max 1.0 -clock clk [all_outputs]

# 4. Regras de Ambiente (Opcional, mas muito recomendado)
# Define que as portas de saída vão alimentar um pequeno fio/porta externa (ex: 10 fF)
# Isso impede que o Genus ache que as saídas estão conectadas ao nada e calcule o tempo errado.
set_load 0.010 [all_outputs]