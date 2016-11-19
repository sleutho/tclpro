# module_deps.tcl
#
#	Prints a list of the dependent modules
#
# Usage:  tclsh8.2 module_desp.tcl -module foo
#

lappend auto_path [file dirname [info script]]

package require cmdline 1.0
package require ModuleHints 1.0

namespace eval ModuleDeps {
    variable optionList {? h help noecho module.arg data.arg}
    variable usageStr {Bug Mike to write the usage string}
}

proc ModuleDeps::getModuleDependencies {args} {
    variable optionList
    variable usageStr
    # Set values from command line

    set moduleName {}
    set echoBaseModule 1
    while {[set err [cmdline::getopt args $optionList opt arg]]} {
	if {$err < 0} {
	    append errorMsg "error:  [cmdline::getArgv0]: " \
		    "$arg (use \"-help\" for legal options)"
	    set errorCode 1
	    break
	} else {
	    switch -exact $opt {
		? -
		h -
		help {
		    set errorMsg $usageStr
		    set errorCode 0
		    break
		}
		module {
		    set moduleName $arg
		}
		data {
		    ModuleHints::setDataFile $arg
		}
		noecho {
		    set echoBaseModule 0
		}
	    }
	}
    }

    if {![file exists [ModuleHints::getDataFile]]} {
	puts stderr "Data file '[ModuleHints::getDataFile]' does not exist"
	exit 1
    }

    if {[string match $moduleName {}]} {
	puts stderr "No module name specified!"
	exit 1
    }

    # The main package name is a valid module, but shouldn't be used
    # as a valid module here.

    if {![ModuleHints::isValidModule $moduleName] && \
		![string match $moduleName [ModuleHints::getPackageName]]} {
	puts stderr "Invalid module name:  $moduleName"
	exit 1
    }

    set moduleList [ModuleHints::getCanonicalDependencies $moduleName {}]

    if {$echoBaseModule} {
	lappend moduleList $moduleName
    }

    return $moduleList
}

set moduleList [eval ModuleDeps::getModuleDependencies $argv]

# Don't blindly print the list.  If it's empty, then the Windows
# Makefile will interpret that as being a module named "" and try
# to build it.

if {[llength $moduleList] > 0} {
    puts $moduleList
}
