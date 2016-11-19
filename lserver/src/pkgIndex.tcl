# Tcl package index file, version 1.1

# Hand crafted to deal with either .tbc or .tcl files

if {[file exists [file join $dir lserver.tbc]]} {
    set _ext tbc
    if {[string compare $dir "."] == 0} {
	# Wrapper things ./foo.tcl is different than foo.tcl
	set dir ""
    }
} else {
    set _ext tcl
}

package ifneeded form 1.0 [list source [file join $dir form.$_ext]]
package ifneeded lpage 1.0 [list source [file join $dir page.$_ext]]
package ifneeded lserver 1.0 [list source [file join $dir audit.$_ext]]\n[list source [file join $dir install.$_ext]]\n[list source [file join $dir lserver.$_ext]]
unset _ext
