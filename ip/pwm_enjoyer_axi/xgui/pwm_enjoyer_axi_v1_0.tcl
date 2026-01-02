
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/pwm_enjoyer_axi_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "G_RST_POL" -widget comboBox
  ipgui::add_param $IPINST -name "G_PWM_N"
  ipgui::add_param $IPINST -name "G_MEM_SIZE_MAX_N"
  ipgui::add_param $IPINST -name "G_EN_REDUNDANCY" -widget comboBox

}

proc update_PARAM_VALUE.G_MEM_SIZE_MAX_L2 { PARAM_VALUE.G_MEM_SIZE_MAX_L2 PARAM_VALUE.G_MEM_SIZE_MAX_N } {
	# Procedure called to update G_MEM_SIZE_MAX_L2 when any of the dependent parameters in the arguments change
	
	set G_MEM_SIZE_MAX_L2 ${PARAM_VALUE.G_MEM_SIZE_MAX_L2}
	set G_MEM_SIZE_MAX_N ${PARAM_VALUE.G_MEM_SIZE_MAX_N}
	set values(G_MEM_SIZE_MAX_N) [get_property value $G_MEM_SIZE_MAX_N]
	set_property value [gen_USERPARAMETER_G_MEM_SIZE_MAX_L2_VALUE $values(G_MEM_SIZE_MAX_N)] $G_MEM_SIZE_MAX_L2
}

proc validate_PARAM_VALUE.G_MEM_SIZE_MAX_L2 { PARAM_VALUE.G_MEM_SIZE_MAX_L2 } {
	# Procedure called to validate G_MEM_SIZE_MAX_L2
	return true
}

proc update_PARAM_VALUE.G_PERIOD_MAX_L2 { PARAM_VALUE.G_PERIOD_MAX_L2 PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update G_PERIOD_MAX_L2 when any of the dependent parameters in the arguments change
	
	set G_PERIOD_MAX_L2 ${PARAM_VALUE.G_PERIOD_MAX_L2}
	set C_S_AXI_DATA_WIDTH ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}
	set values(C_S_AXI_DATA_WIDTH) [get_property value $C_S_AXI_DATA_WIDTH]
	set_property value [gen_USERPARAMETER_G_PERIOD_MAX_L2_VALUE $values(C_S_AXI_DATA_WIDTH)] $G_PERIOD_MAX_L2
}

proc validate_PARAM_VALUE.G_PERIOD_MAX_L2 { PARAM_VALUE.G_PERIOD_MAX_L2 } {
	# Procedure called to validate G_PERIOD_MAX_L2
	return true
}

proc update_PARAM_VALUE.G_STATE_MAX_L2 { PARAM_VALUE.G_STATE_MAX_L2 PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update G_STATE_MAX_L2 when any of the dependent parameters in the arguments change
	
	set G_STATE_MAX_L2 ${PARAM_VALUE.G_STATE_MAX_L2}
	set C_S_AXI_DATA_WIDTH ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}
	set values(C_S_AXI_DATA_WIDTH) [get_property value $C_S_AXI_DATA_WIDTH]
	set_property value [gen_USERPARAMETER_G_STATE_MAX_L2_VALUE $values(C_S_AXI_DATA_WIDTH)] $G_STATE_MAX_L2
}

proc validate_PARAM_VALUE.G_STATE_MAX_L2 { PARAM_VALUE.G_STATE_MAX_L2 } {
	# Procedure called to validate G_STATE_MAX_L2
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.G_EN_REDUNDANCY { PARAM_VALUE.G_EN_REDUNDANCY } {
	# Procedure called to update G_EN_REDUNDANCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_EN_REDUNDANCY { PARAM_VALUE.G_EN_REDUNDANCY } {
	# Procedure called to validate G_EN_REDUNDANCY
	return true
}

proc update_PARAM_VALUE.G_MEM_SIZE_MAX_N { PARAM_VALUE.G_MEM_SIZE_MAX_N } {
	# Procedure called to update G_MEM_SIZE_MAX_N when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_MEM_SIZE_MAX_N { PARAM_VALUE.G_MEM_SIZE_MAX_N } {
	# Procedure called to validate G_MEM_SIZE_MAX_N
	return true
}

proc update_PARAM_VALUE.G_PWM_N { PARAM_VALUE.G_PWM_N } {
	# Procedure called to update G_PWM_N when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_PWM_N { PARAM_VALUE.G_PWM_N } {
	# Procedure called to validate G_PWM_N
	return true
}

proc update_PARAM_VALUE.G_RST_POL { PARAM_VALUE.G_RST_POL } {
	# Procedure called to update G_RST_POL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_RST_POL { PARAM_VALUE.G_RST_POL } {
	# Procedure called to validate G_RST_POL
	return true
}


proc update_MODELPARAM_VALUE.G_RST_POL { MODELPARAM_VALUE.G_RST_POL PARAM_VALUE.G_RST_POL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_RST_POL}] ${MODELPARAM_VALUE.G_RST_POL}
}

proc update_MODELPARAM_VALUE.G_STATE_MAX_L2 { MODELPARAM_VALUE.G_STATE_MAX_L2 PARAM_VALUE.G_STATE_MAX_L2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_STATE_MAX_L2}] ${MODELPARAM_VALUE.G_STATE_MAX_L2}
}

proc update_MODELPARAM_VALUE.G_MEM_SIZE_MAX_N { MODELPARAM_VALUE.G_MEM_SIZE_MAX_N PARAM_VALUE.G_MEM_SIZE_MAX_N } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_MEM_SIZE_MAX_N}] ${MODELPARAM_VALUE.G_MEM_SIZE_MAX_N}
}

proc update_MODELPARAM_VALUE.G_MEM_SIZE_MAX_L2 { MODELPARAM_VALUE.G_MEM_SIZE_MAX_L2 PARAM_VALUE.G_MEM_SIZE_MAX_L2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_MEM_SIZE_MAX_L2}] ${MODELPARAM_VALUE.G_MEM_SIZE_MAX_L2}
}

proc update_MODELPARAM_VALUE.G_PERIOD_MAX_L2 { MODELPARAM_VALUE.G_PERIOD_MAX_L2 PARAM_VALUE.G_PERIOD_MAX_L2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_PERIOD_MAX_L2}] ${MODELPARAM_VALUE.G_PERIOD_MAX_L2}
}

proc update_MODELPARAM_VALUE.G_PWM_N { MODELPARAM_VALUE.G_PWM_N PARAM_VALUE.G_PWM_N } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_PWM_N}] ${MODELPARAM_VALUE.G_PWM_N}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.G_EN_REDUNDANCY { MODELPARAM_VALUE.G_EN_REDUNDANCY PARAM_VALUE.G_EN_REDUNDANCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_EN_REDUNDANCY}] ${MODELPARAM_VALUE.G_EN_REDUNDANCY}
}

