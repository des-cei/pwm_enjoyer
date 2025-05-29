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
add_files -fileset sources_1 ../rtl/counter.vhd

## Add simulation files here
add_files -fileset sim_1 ../tb/counter_tb.vhd

## Add constraint files here (only for FPGA implementation)
#add_files -fileset constrs_1 ../constr/pynq.xdc

close_project
exit