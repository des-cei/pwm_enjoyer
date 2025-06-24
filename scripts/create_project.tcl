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

## Add source files here
add_files -fileset sources_1 ../rtl/state_ctrlr.vhd
add_files -fileset sources_1 ../rtl/pwm_counter.vhd
add_files -fileset sources_1 ../rtl/my_pkg.vhd

## Add simulation files here
add_files -fileset sim_1 ../tb/state_ctrlr_tb.vhd
add_files -fileset sim_1 ../tb/pwm_counter_tb.vhd

## Top module files
set_property top state_ctrlr [get_filesets sources_1]
set_property top state_ctrlr_tb [get_filesets sim_1]

## Add constraint files here (only for FPGA implementation)
#add_files -fileset constrs_1 ../constr/pynq.xdc

close_project
exit