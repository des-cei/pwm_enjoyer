##########################################################
##                                                      ##
##          Digital Embedded Systems (DES)              ##
##       Centro de Electronica Industrial (CEI)         ##
##      Universidad Politecnica de Madrid (UPM)         ##
##                                                      ##
##########################################################


default: project open-gui

project:
	mkdir build
	cd build && vivado -mode batch -source ../scripts/create_project.tcl

open-gui:
	cd build && vivado VHDL_project/VHDL_project.xpr

clean:
	rm -R build

HELP_COMMANDS = \
"   help        = display this help" \
" [ project  ]  = generate the Vivado project with the files specified in 'scripts/create_project.tcl'" \
" [ open-gui ]  = open the Vivado project" \
"   clean       = remove all project and intermediate files" \
"" 

HELP_LINES = "" \
	" General commands:" \
	" -----------------------------" \
	$(HELP_COMMANDS) \
	""

help:
	@for line in $(HELP_LINES); do echo "$$line"; done