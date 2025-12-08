# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "G_PERIOD_MAX_US" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_RST_POL" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "G_SYS_CLK_HZ" -parent ${Page_0}


}

proc update_PARAM_VALUE.G_PERIOD_MAX_US { PARAM_VALUE.G_PERIOD_MAX_US } {
	# Procedure called to update G_PERIOD_MAX_US when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_PERIOD_MAX_US { PARAM_VALUE.G_PERIOD_MAX_US } {
	# Procedure called to validate G_PERIOD_MAX_US
	return true
}

proc update_PARAM_VALUE.G_RST_POL { PARAM_VALUE.G_RST_POL } {
	# Procedure called to update G_RST_POL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_RST_POL { PARAM_VALUE.G_RST_POL } {
	# Procedure called to validate G_RST_POL
	return true
}

proc update_PARAM_VALUE.G_SYS_CLK_HZ { PARAM_VALUE.G_SYS_CLK_HZ } {
	# Procedure called to update G_SYS_CLK_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_SYS_CLK_HZ { PARAM_VALUE.G_SYS_CLK_HZ } {
	# Procedure called to validate G_SYS_CLK_HZ
	return true
}


proc update_MODELPARAM_VALUE.G_SYS_CLK_HZ { MODELPARAM_VALUE.G_SYS_CLK_HZ PARAM_VALUE.G_SYS_CLK_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_SYS_CLK_HZ}] ${MODELPARAM_VALUE.G_SYS_CLK_HZ}
}

proc update_MODELPARAM_VALUE.G_RST_POL { MODELPARAM_VALUE.G_RST_POL PARAM_VALUE.G_RST_POL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_RST_POL}] ${MODELPARAM_VALUE.G_RST_POL}
}

proc update_MODELPARAM_VALUE.G_PERIOD_MAX_US { MODELPARAM_VALUE.G_PERIOD_MAX_US PARAM_VALUE.G_PERIOD_MAX_US } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_PERIOD_MAX_US}] ${MODELPARAM_VALUE.G_PERIOD_MAX_US}
}

