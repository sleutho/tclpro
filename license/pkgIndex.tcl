# Tcl package index file, version 1.1

# This file is hand crafted to auto-detect compiled or non-compiled sources.

if {[file exists [file join $dir lclient.tcl]]} {

    package ifneeded lclient 1.0 [list source [file join $dir lclient.tcl]]
    package ifneeded lic 1.1 [list source [file join $dir licio.tcl]]\n[list source [file join $dir licparse.tcl]]
    package ifneeded licdata 2.0 [list source [file join $dir licdata.tcl]]
    package ifneeded linstall 1.0 [list source [file join $dir lserverInstall.tcl]]
    package ifneeded licenseWin 1.0 [list source [file join $dir licenseWin.tcl]]
    package ifneeded lictty 1.0 [list source [file join $dir lictty.tcl]]
    package ifneeded licttyStub 1.0 [list source [file join $dir licttyStub.tcl]]
    package ifneeded util 1.0 [list source [file join $dir util.tcl]]

} else {

    package ifneeded lclient 1.0 [list source [file join $dir lclient.tbc]]
    package ifneeded lic 1.1 [list source [file join $dir licio.tbc]]\n[list source [file join $dir licparse.tbc]]
    package ifneeded licdata 2.0 [list source [file join $dir licdata.tbc]]
    package ifneeded linstall 1.0 [list source [file join $dir lserverInstall.tbc]]
    package ifneeded licenseWin 1.0 [list source [file join $dir licenseWin.tbc]]
    package ifneeded lictty 1.0 [list source [file join $dir lictty.tbc]]
    package ifneeded licttyStub 1.0 [list source [file join $dir licttyStub.tbc]]
    package ifneeded util 1.0 [list source [file join $dir util.tbc]]

}
