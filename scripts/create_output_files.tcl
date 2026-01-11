# -------------------------------------
# Generación de archivos tras bitstream
# -------------------------------------
# Este script debe almacenarse en /scripts

# Rutas
set prj_dir 	[get_property DIRECTORY [current_project]]
set reports_dir [file normalize "$prj_dir/../../rpt"]
set bin_dir     [file normalize "$prj_dir/../../bin"]
set runs_dir 	"$prj_dir/[current_project].runs"
set top_name 	[get_property TOP [current_fileset]]

# Generar bitstream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Crear directorios si no existen
file mkdir $reports_dir
file mkdir $bin_dir

# Abrir diseño implementado
open_run impl_1

# Reportes y logs interesantes
report_utilization -hierarchical -file "$reports_dir/utilization.rpt"
report_drc -file "$reports_dir/drc.rpt"
report_timing_summary -file "$reports_dir/timing_summary.rpt"
file copy -force "$runs_dir/synth_1/runme.log" "$reports_dir/synth.log"
file copy -force "$runs_dir/impl_1/runme.log" "$reports_dir/impl.log"

# Binarios
set bitfile "$runs_dir/impl_1/${top_name}.bit"
file copy -force $bitfile "$bin_dir/${top_name}.bit"
set ltxfile "$runs_dir/impl_1/${top_name}.ltx"
if {[file exists $ltxfile]} {
    file copy -force $ltxfile "$bin_dir/${top_name}.ltx"
}
write_hw_platform -fixed -include_bit -force -file "$bin_dir/[current_project].xsa"

# Cerrar diseño
close_design