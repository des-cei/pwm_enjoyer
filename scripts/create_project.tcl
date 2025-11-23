##########################################################
##                                                      ##
##          Digital Embedded Systems (DES)              ##
##       Centro de Electronica Industrial (CEI)         ##
##      Universidad Politecnica de Madrid (UPM)         ##
##                                                      ##
##########################################################

set prj_name "VHDL_project"

create_project -force $prj_name $prj_name -part xc7z020clg400-1
set_property "target_language" "VHDL" [current_project]

## Add IPs
set_property ip_repo_paths "../ip" [current_project]
update_ip_catalog

## Import BD and genereate Top Wrapper
source ../scripts/pwm_enjoyer_bd.tcl
validate_bd_design
save_bd_design
set bd_name [current_bd_design]
set bd_file [get_files [format "%s.bd" $bd_name]]
set wrapper_file [make_wrapper -files $bd_file -top]
add_files $wrapper_file

## Add source files here
add_files -fileset sources_1 ../rtl/pwm_enjoyer_axi.vhd
add_files -fileset sources_1 ../rtl/pwm_enjoyer.vhd
add_files -fileset sources_1 ../rtl/control_unit.vhd
add_files -fileset sources_1 ../rtl/config_error.vhd
add_files -fileset sources_1 ../rtl/pwm_top.vhd
add_files -fileset sources_1 ../rtl/pwm_dp_mem.vhd
add_files -fileset sources_1 ../rtl/bram_dualport.vhd
add_files -fileset sources_1 ../rtl/state_ctrlr.vhd
add_files -fileset sources_1 ../rtl/pwm_counter.vhd
add_files -fileset sources_1 ../rtl/my_pkg.vhd

## Add simulation files here
add_files -fileset sim_1 ../tb/pwm_enjoyer_tb.vhd
add_files -fileset sim_1 ../tb/control_unit_tb.vhd
add_files -fileset sim_1 ../tb/config_error_tb.vhd
add_files -fileset sim_1 ../tb/pwm_top_autotest_tb.vhd
add_files -fileset sim_1 ../tb/pwm_top_tb.vhd
add_files -fileset sim_1 ../tb/pwm_dp_mem_autotest_tb.vhd
add_files -fileset sim_1 ../tb/pwm_dp_mem_tb.vhd
add_files -fileset sim_1 ../tb/state_ctrlr_autotest_tb.vhd
add_files -fileset sim_1 ../tb/state_ctrlr_tb.vhd
add_files -fileset sim_1 ../tb/pwm_counter_tb.vhd

## Top module files
set_property top pwm_enjoyer_bd_wrapper [get_filesets sources_1]
set_property top pwm_enjoyer_tb [get_filesets sim_1]

## Add constraint files here (only for FPGA implementation)
add_files -fileset constrs_1 ../constr/pynq.xdc

close_project
exit