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

package require cmdline 1.0
package require ModuleHints 1.0

namespace eval BuildModule {
    variable optionList {? h help recurse module.arg flavor.arg makeAction.arg data.arg}
    variable usageStr {Bug Mike to write the usage string}

    variable makeDependentModules 0
}

# BuildModule::BuildModule --
#
#	Run make on the module
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Type of build to perform (Release or Debug)
#	makeAction	Target to "make"
#
# Results:
#	Returns a list of submodules to be built (in order)

proc BuildModule::BuildModule {moduleName flavorStr makeAction} {
    global env

    set moduleTopDir [ModuleHints::getModuleTopDir $moduleName]
    set moduleSrcSubDir [ModuleHints::getModuleSrcSubDir $moduleName]
    set moduleSrcDir [file join $moduleTopDir $moduleSrcSubDir]

    set buildPrefix [ModuleHints::getValue build_prefix]
    set Prefix [ModuleHints::getValue prefix]
    set execPrefix [ModuleHints::getValue exec_prefix]
    set moduleBuildDir [file join $buildPrefix $moduleName $moduleSrcSubDir]

    # Don't print an error message if this is the main package's
    # module.  Just skip it.

    if {[string equal $moduleName [ModuleHints::getPackageName]]} {
	return 1
    }

    if {[string length $moduleBuildDir] == 0} {
	puts stderr "No build directory is known for module $moduleName"
	return 0
    }

    if {![file isdir $moduleBuildDir]} {
	puts stderr "Build directory $moduleBuildDir does not exist"
	return 0
    }

    cd $moduleBuildDir

    # If the module has not been TEA-ified, then we may need these
    # next steps:

    set moduleTargetList [ModuleHints::getMakeTargets $moduleName $makeAction]

    # Look in the environment for an alternate make program to use

    if {[info exists env(MAKE)]} {
	set makeProg $env(MAKE)
	puts "Using make program from the environment setting MAKE:  $env(MAKE)"
    } else {
	set makeProg make
    }

    set result 1
    foreach target $moduleTargetList {
	set makeCmd "$makeProg $target"
	if {[ModuleHints::execViaPipe $makeCmd] != 1} {
	    set result 0
	}
    }

    return $result
}

# BuildModule::ConfigureModule --
#
#	Run autoconf and configure on the specified module
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Build flavor (Debug or Release)
#	placeHolder	Not used
#
# Results:
#	Exec's autoconf and configure on the module

proc BuildModule::ConfigureModule {moduleName flavorStr placeHolder} {
    set moduleTopDir [ModuleHints::getModuleTopDir $moduleName]
    set moduleSrcSubDir [ModuleHints::getModuleSrcSubDir $moduleName]
    set moduleSrcDir [file join $moduleTopDir $moduleSrcSubDir]
    set buildPrefix [ModuleHints::getValue build_prefix]
    #set Prefix [ModuleHints::getValue prefix]
    #set execPrefix [ModuleHints::getValue exec_prefix]
    set platform [ModuleHints::getValue platform]

    # TEMPORARY:  Don't print an error message if this is the
    # main package's module.  Just skip it.

    if {[string equal $moduleName [ModuleHints::getPackageName]]} {
	return 1
    }

    if {[string length $moduleSrcDir] == 0} {
	puts stderr "No source directory is known for module $moduleName"
	return 0
    }

    # We could add a check to see if a configure script already exists
    # and only run autoconf if it does not.  This would prevent us from
    # duplicating some work, but might lead to problems where some
    # files get out of date and never rebuilt without doing a "make clean"

    # Mimic the layout of the module's directory tree.  Tclx, for example,
    # requires you to run configure from a subdirectory called "unix" 

    set moduleBuildDir [file join $buildPrefix $moduleName $moduleSrcSubDir]
    puts "file mkdir $moduleBuildDir"
    file mkdir $moduleBuildDir
    cd $moduleBuildDir

    # Check first for a configure script in the build directory, then in
    # the module src directory.
    # TEMPORARY:  Don't check for an existing configure script in the build
    # directory.  This seems to cause a lot of trouble when rebuilding
    # modules.

#    if {[file exists configure]} {
#	puts "RE-using configure script found in [pwd]."
#	puts "To rebuild the configure script, you should first remove it"
#	set configureScript configure
#    }

    if {[file exists [file join $moduleSrcDir $moduleSrcSubDir configure]]} {
	puts "Using distributed configure script found in [file join $moduleSrcDir $moduleSrcSubDir]"
	set configureScript [file join $moduleSrcDir $moduleSrcSubDir configure]
    } else {
	puts "Generating new configure script in [pwd]"
	cd [file join $moduleSrcDir]
	puts "Working directory:  [pwd]"
	#set autoconfCmd "bash autoconf -l $moduleSrcDir"
	set autoconfCmd "bash  autoconf configure.in "
	#append autoconfCmd " [file join $moduleSrcDir configure.in]"
	append autoconfCmd " > [file join $moduleBuildDir configure]"
	puts "-->\[$autoconfCmd\]"

	if {[catch {eval exec $autoconfCmd} errMsg]} {
	    puts "WARNING:  autoconf for $moduleName generated the following message:"
	    puts "$errMsg"
	}
	set configureScript ./configure
    }

    set configureSwitches [ModuleHints::getConfigureSwitches $moduleName $flavorStr $platform]
    set configureCmd "sh  $configureScript"
    append configureCmd " --srcdir=[ModuleHints::getCygpath $moduleSrcDir]"
    append configureCmd " $configureSwitches"
    #append configureCmd " --prefix=$Prefix"
    #append configureCmd " --exec-prefix=$execPrefix"

    # We could add a check to see if a Makefile already exists
    # and only run configure if it does not.  This would prevent us from
    # duplicating some work, but might lead to problems where some
    # files get out of date and never rebuilt without doing a "make clean"

    set moduleBuildDir [file join $buildPrefix $moduleName $moduleSrcSubDir]
    file mkdir $moduleBuildDir
    cd $moduleBuildDir

    # TEMPORARY:  Re-run the configure even if there's already a Makefile
    # in the build location.  Otherwise we run into hard-to-track build errors
    # with stale Makefiles.

    return [ModuleHints::execViaPipe $configureCmd]
}

# BuildModule::ConfigureAndBuildModule --
#
#	Wrapper script to configure and build a module
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Build flavor (Debug or Release)
#	makeAction	Make target to trigger
#
# Results:
#	Calls routines to run autoconf, configure, and make on the module

proc BuildModule::ConfigureAndBuildModule {moduleName flavorStr makeAction} {
    set buildResult [ConfigureModule $moduleName $flavorStr $makeAction]

    incr buildResult [BuildModule $moduleName $flavorStr $makeAction]

    if {$buildResult == 2} {
	return 1
    } else {
	return 0
    }
}

# BuildModule::TestModule --
#
#	Run make test on the module
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Type of build to perform (Release or Debug)
#	makeAction	Target to "make"
#
# Results:
#	Returns a list of submodules to be built (in order)

proc BuildModule::TestModule {moduleName flavorStr makeAction} {
    set moduleTopDir [ModuleHints::getModuleTopDir $moduleName]
    set moduleSrcSubDir [ModuleHints::getModuleSrcSubDir $moduleName]
    set moduleSrcDir [file join $moduleTopDir $moduleSrcSubDir]

    set buildPrefix [ModuleHints::getValue build_prefix]
    set Prefix [ModuleHints::getValue prefix]
    set execPrefix [ModuleHints::getValue exec_prefix]
    set moduleBuildDir [file join $buildPrefix $moduleName \
	    $moduleSrcSubDir]

    set addFlags {}

    switch $moduleName {
	"tcl" {
	    if {[file exists [file join $moduleSrcDir dltest]]} {
		cd [file join $moduleSrcDir dltest]
		exec bash  autoconf
	    }
	}
	"tk" {
	    set addFlags "TCL_BIN_DIR=[ModuleHints::getCygpath \
		    [file join $buildPrefix tcl $moduleSrcSubDir]]"
	}
    }

    if {![file exists $moduleBuildDir]} {
	puts stderr "No build directory exists for module $moduleName"
	return 0
    }

    cd $moduleBuildDir

    # TEMPORARY:  Don't print an error message if this is the
    # main package's module.  Just skip it.

    if {[string equal $moduleName [ModuleHints::getPackageName]]} {
	return 1
    }

    if {[string length $moduleSrcDir] == 0} {
	puts stderr "No source directory is known for module $moduleName"
	return 0
    }

    # If the module has not been TEA-ified, then we may need these
    # next steps:

    set moduleTargetList [ModuleHints::getMakeTargets $moduleName $makeAction]

    set result 1
    foreach target $moduleTargetList {
	if {$addFlags == [list {}]} {
	    set makeCmd "make $target"
	} else {
	    set makeCmd "make $target $addFlags"
	}
	if {[ModuleHints::execViaPipe $makeCmd] != 1} {
	    set result 0
	}
    }

    return $result
}

# BuildModule::UpdateModule --
#
#	Run "cvs update" on the module.  The contents of the CVSUPARGS
#	environment variable are added to the end of the "cvs update" command.
#	This makes it possible to switch code branches.
#
# Arguments:
#	moduleName	name of module
#	dummyArg1	Unused
#	dummyArg2	Unused
#
# Results:
#	Returns 1 if the update succeeded, 0 if not.

proc BuildModule::UpdateModule {moduleName dummyArg1 dummyArg2} {
    set moduleTopDir [ModuleHints::getModuleTopDir $moduleName]

    if {[string length $moduleTopDir] == 0} {
	puts stderr "No source directory is known for module $moduleName"
	return 0
    }

    set result 1

    set updateCmd "cvs update"

    if {[info exists ::env(CVSUPARGS)]} {
	append updateCmd " $::env(CVSUPARGS)"
    }

    cd $moduleTopDir
    if {[ModuleHints::execViaPipe $updateCmd] != 1} {
	set result 0
    }

    return $result
}

# BuildModule::runBuild --
#
#	Entry point to the BuildModule routines
#
# Arguments:
#	args	Command line arguments
#
# Side effects:
#	Exec's autoconf and configure on the module
#
# Results:
#	Returns 1 if the build ran successfully for all modules.  0 if not.

proc BuildModule::runBuild {args} {
    variable optionList
    variable usageStr
    variable makeDependentModules

    set flavorStr Release
    set moduleList {}
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
		    lappend moduleList $arg
		}
		flavor {
		    set flavorStr $arg
		}
		makeAction {
		    set makeAction $arg
		}
		recurse {
		    set makeDependentModules 1
		}
		data {
		    ModuleHints::setDataFile $arg
		}
	    }
	}
    }

    if {![file exists [ModuleHints::getDataFile]]} {
	puts stderr "Data file '[ModuleHints::getDataFile]' does not exist"
	return 0
    }

    switch $makeAction {
	test {
	    set makeProc TestModule
	    set makeDesc "Testing"
	}
	all -
	install {
	    set makeProc ConfigureAndBuildModule
	    set makeDesc "Building"
	}
	update {
	    set makeProc UpdateModule
	    set makeDesc "Updating"
	}
	default {
	    set makeProc BuildModule
	    set makeDesc "Building"
	}
    }

    puts "Using makeProc=$makeProc"

    set failedModules {}
    set succeededModules {}
    if {$makeDependentModules} {
	if {[llength $moduleList] == 1} {
	    set depModuleList [ModuleHints::getCanonicalDependencies $moduleList {}]
	    puts "$makeDesc dependent modules $depModuleList"

	    # Do an install for each dependent module

	    foreach module $depModuleList {
		set buildResult [$makeProc $module $flavorStr $makeAction]

		if {$buildResult != 1} {
		    lappend failedModules $module
		} else {
		    lappend succeededModules $module
		}
	    }
	} else {
	    puts stderr "You can't build multiple modules with the -recurse option!"
	    exit 1
	}
    }

    if {[llength $moduleList] > 1} {
	puts "$makeDesc modules: $moduleList"
    } else {
	puts "$makeDesc module: $moduleList"
    }

    foreach moduleName $moduleList {
	# ConfigureModule and BuildModule both return 1 if the operation
	# completed successfully.  Add their return values to see if both
	# operations completed successfully.

	set buildResult [$makeProc $moduleName $flavorStr $makeAction]

	if {$buildResult != 1} {
	    lappend failedModules $moduleName
	} else {
	    lappend succeededModules $moduleName
	}
    }

    if {[llength $succeededModules] != 0} {
	puts stdout ""
	puts stdout ""
	puts stdout "The following modules built with no errors:"
	foreach module $succeededModules {
	    puts stdout "\t$module"
	}
    }

    if {[llength $failedModules] != 0} {
	puts stderr ""
	puts stderr ""
	puts stderr "***Errors during build***"
	puts stderr "The following module(s) generated errors during the build:"
	foreach module $failedModules {
	    puts stderr "\t$module"
	}

	return 0
    }

    return 1
}

if {[eval BuildModule::runBuild $argv] == 0} {
    exit 1
}

