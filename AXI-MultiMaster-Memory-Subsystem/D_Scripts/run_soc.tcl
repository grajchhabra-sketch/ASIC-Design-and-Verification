open_project AXI_SOC.xpr

update_compile_order -fileset sim_1

launch_simulation

restart

log_wave -r /*

run all

puts "Simulation Completed Successfully"

exit
