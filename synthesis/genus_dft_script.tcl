set_db init_lib_search_path ../lib/
set_db init_hdl_search_path ../rtl/
read_libs slow_vdd1v0_basicCells.lib
read_hdl -sv core_pkg.sv fp_new.sv multiplier.sv ex_stage.sv
elaborate 
read_sdc ../constraints/constraints_top.sdc

 
set_db dft_scan_style muxed_scan 
set_db dft_prefix dft_
define_test_signal -function shift_enable -name SE -active high -create_port SE
check_dft_rules

set_db syn_generic_effort medium
syn_generic
set_db syn_map_effort medium
syn_map
set_db syn_opt_effort medium

check_dft_rules 
set_db design:multi .dft_min_number_of_scan_chains 1 
define_scan_chain -name top_chain -sdi scan_in -sdo scan_out -create_ports

#The following commands are used to remove the assign statements and replace it with BUFX20
#in the synthesized netlist
set_db remove_assigns true
add_assign_buffer_options -ports scan_out -buffer_or_inverter BUFX20
#

connect_scan_chains -auto_create_chains 
syn_opt 

report_scan_chains 
write_dft_atpg -library ../lib/slow_vdd1v0_basiccells.v
write_hdl > outputs/multi_netlist_dft.v
write_sdc > outputs/multi_sdc_dft.sdc
write_sdf -nonegchecks -edges check_edge -timescale ns -recrem split  -setuphold split > outputs/dft_delays.sdf
write_scandef > outputs/multi_scanDEF.scandef



