# build_module.tcl
#
#	Run "make $action" on a specified module
#
# Usage:  tclsh8.2 build_module.tcl -module foo ?-module bar? \
#	?-recurse? \
#	-flavor Release|Debug \
#	-makeAction all|binaries|libraries|doc|install-binaries|...
#

lappend auto_path [file dirname [info script]]

package require BuildModuleB 1.0

if {[eval BuildModule::runBuild $argv] == 0} {
    exit 1
}

