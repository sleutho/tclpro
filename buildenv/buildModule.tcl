# buildModule.tcl --
#
#	This file implements functions for invoking various Makefile
#	targets for TEA compliant extensions.  Most of the routines
#	in this file take the same number and type of arguments.  This
#	allows us to use the procedure names as function pointers.
#
# Copyright (c) 1999-2000 by Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: buildModule.tcl,v 1.19 2001/03/15 11:53:29 karll Exp $

if {[catch {package require cmdline 1.0} result] == 1} {
    puts stderr $result
    puts stderr "This means that the Tcl library, tcllib, is not installed"
    puts stderr "in the Tcl you are using.  Please fix this, then"
    puts stderr "remove config.cache and run configure again."
    exit 10
}

package require ModuleHints 1.0
package provide BuildModule 1.0

namespace eval BuildModule {
    variable optionList {? h help recurse module.arg modulelist.arg flavor.arg\
	    makeAction.arg data.arg}
    variable usageStr {Bug Mike to write the usage string}

    variable makeDependentModules 0

    variable softStatusData
    variable softStatusFile

    variable makeFlags ""

    variable runDir [pwd]
}

# BuildModule::LoadSoftStatus --
#
#	Call to load "soft status" information.
#
# Arguments:
#	None
#
# Side Effects:
#	Each line of the soft status file is read into
#	the softStatusData array.
#
# Results:
#	None.

proc BuildModule::LoadSoftStatus {} {
    variable softStatusData
    variable softStatusFile

    set softStatusFile [file join [pwd] SOFTSTATUS]
    ModuleHints::logMessage "Soft Status File is '$softStatusFile'"
    set count 0
    if {[file readable SOFTSTATUS]} {
	set fp [open $softStatusFile r]
	while {[gets $fp line] >= 0} {
	    set softStatusData($line) ""
	    incr count
	}
	ModuleHints::logMessage "Soft Status File loaded, $count lines of status information"
    }
}

# BuildModule::CheckSoftStatus --
#
#	Call to check "soft status" information for args.
#
# Arguments:
#	args	        stuff to log in the soft status file.
#
# Side Effects:
#	None
#
# Results:
#	Returns 1 if the args were found in the soft status file,
#       otherwise 0.

proc BuildModule::CheckSoftStatus {args} {
    variable softStatusData
    variable makeDependentModules

    if {!$makeDependentModules} {
	return 0
    }

    return [info exists softStatusData($args)]
}

# BuildModule::SetSoftStatus --
#
#	Call to record "soft status" information for args.
#
# Arguments:
#	args	        stuff to log in the soft status file.
#
# Side Effects:
#	None
#
# Results:
#	None

proc BuildModule::SetSoftStatus {args} {
    variable softStatusFile

    # Check the soft status for these args.  If they're already found,
    # no need to write it into the soft status file as it's already there.
    if {[eval CheckSoftStatus $args] == 1} {
	return
    }

    set fp [open $softStatusFile a]
    puts $fp $args
    close $fp
}

# BuildModule::BuildModule --
#
#	Call to the system to execute "make foo" on a particular module.
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Type of build to perform (Release or Debug).
#			This argument is not used.
#	makeAction	Target to "make"
#
# Side Effects:
#	The current working directory is changed to the build directory
#	if it exists.
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
    # module.  Just skip it silently.

    if {[string equal $moduleName [ModuleHints::getPackageName]]} {
	return 1
    }

    if {[string length $moduleBuildDir] == 0} {
	ModuleHints::logError "No build directory is known for module $moduleName"
	return 0
    }

    if {![file isdir $moduleBuildDir]} {
	ModuleHints::logError "Build directory $moduleBuildDir does not exist"
	return 0
    }

    cd $moduleBuildDir

    # Let the user override the make program with the MAKE environment
    # variable.

    set makeProg make

    if {[info exists env(MAKE)]} {
	set makeProg $env(MAKE)
    }

    # If the action is reinstall, it's install with no soft status caching...
    set forceInstall 0
    if {$makeAction == "reinstall"} {
	set forceInstall 1
	set makeAction "install"
    }

    # If the module has not been TEA-ified, then we may need these
    # next steps:

    set moduleTargetList [ModuleHints::getMakeTargets $moduleName $makeAction]

    set result 1
    foreach target $moduleTargetList {

	# If the target is "install", check to see if we have successfully
	# installed this guy already.  If we have, skip it.
	if {$target == "install"} {
	    if {!$forceInstall && [CheckSoftStatus install $moduleName $flavorStr]} {
	        ModuleHints::logMessage "Soft status OK for 'install $moduleName $flavorStr', skipping..."
		continue
	    }
	}

	set makeCmd "$makeProg $BuildModule::makeFlags $target"

	# perform the make command
	ModuleHints::logMessage "BuildModule (module '$moduleName', flavor '$flavorStr', makeAction '$makeAction')"
	if {[ModuleHints::execViaPipe $makeCmd] != 1} {
	    set result 0
	    ModuleHints::logError "failed: $makeProg $target"
	    exit 1
	}

    }

    # If we got here, the make was successful.
    # If we just finished a "make install", make a note of it.
    if {$makeAction == "install"} {
	if {![CheckSoftStatus install $moduleName $flavorStr]} {
	    Snapshot $moduleName $Prefix
	    SetSoftStatus install $moduleName $flavorStr
	}
    }

    return $result
}

# BuildModule::Snapshot --
#
#	Record information about each file in the output directory,
#	for postprocessing to create the net-based install files.
#
# Arguments:
#	moduleName	name of module
#	outPrefix	The build's output directory.
#
# Side Effects:
#	The current working directory is changed to the output directory.
#
# Results:
#       For each file in the output directory, appends a line to
#	a file called SNAPSHOT containing a Tcl list consisting
#	of the name of the module currently being built, the modification
#	time of the file, and the name of the file.
#	

proc BuildModule::Snapshot {moduleName outPrefix} {
    variable runDir

    ModuleHints::logMessage "Snapshotting output tree '$outPrefix' for module '$moduleName'"

    set snapshotFile [ModuleHints::getWinpath [file join $runDir SNAPSHOT]]
    set fp [open $snapshotFile a]

    # process all files and directories in the output directory
    cd [ModuleHints::getWinpath $outPrefix]

    BuildModule::SnapshotDir $fp $moduleName .

    BuildModule::SnapshotPackages $fp tclsh $moduleName .

    close $fp
}

proc BuildModule::SnapshotPackages {fp program moduleName outPrefix} {
    set execPrefix [ModuleHints::getValue exec_prefix]
    set buildUtilDir [ModuleHints::getValue exec_prefix]
    set path_to_exe [glob -nocomplain $execPrefix/bin/$program*]
    if {$path_to_exe == ""} {
	ModuleHints::logError "Can't find path to '$program' executable in $outPrefix '[pwd]'"
	exit 11
    }
    if {[llength $path_to_exe] > 1} {
	ModuleHints::logError "Too many programs matched $program*: $path_to_exe"
	exit 12
    }
    ModuleHints::logMessage "Running $path_to_exe to collect package info"

    set ifp [open "|$path_to_exe ../../snapshot/listpackages.tcl $moduleName" r]
    while {[gets $ifp line] >= 0} {
	puts $fp $line
    }
    if {[catch {close $ifp} result] == 1} {
	ModuleHints::logError "Failed to collect package info info: $result"
    }
}


# BuildModule::SnapshotDir --
#
#	Record information about each file in the specified directory
#	for postprocessing to create the net-based install files.
#
#	Recursively call SnapshotDir for any subdirectories that are found.
#
# Arguments:
#	fp		file handle to write to.
#	moduleName	name of module
#	dir		The directory to process.
#
# Side Effects:
#
# Results:
#       For each file in the directory, write a line to the passed file
#	handle containing a Tcl list consisting
#	of the name of the module currently being built, the modification
#	time of the file, and the name of the file.
#
#	For any subdirectories, recursively calls SnapshotDir to process
#	them.
#
#	This would be unnecessary except fileutil::find doesn't return
#	relative pathnames.
#	

proc BuildModule::SnapshotDir {fp moduleName dir} {
    variable runDir

    #ModuleHints::logMessage "Snapshotting directory '$dir'"

    foreach file [glob -nocomplain [file join $dir *]] {
	file stat $file stat
	if {$stat(type) == "directory"} {
	    BuildModule::SnapshotDir $fp $moduleName $file
	    continue
	}

	# make note of the mtime 
	puts $fp [list file $moduleName $stat(mtime) $file]
	#ModuleHints::logMessage [list $moduleName $stat(mtime) $file]
    }
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
# Side Effects:
#	The current working directory is changed to the build directory
#	if it exists.
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
	ModuleHints::logError "No source directory is known for module $moduleName"
	return 0
    }

    # We could add a check to see if a configure script already exists
    # and only run autoconf if it does not.  This would prevent us from
    # duplicating some work, but might lead to problems where some
    # files get out of date and never rebuilt without doing a "make clean"

    # Mimic the layout of the module's directory tree.  Tclx, for example,
    # requires you to run configure from a subdirectory called "unix" 

    set moduleBuildDir [file join $buildPrefix $moduleName $moduleSrcSubDir]
    ModuleHints::logMessage "file mkdir $moduleBuildDir"
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

    # this uses the configure script if it's found, rather than running
    # autoconf -- we have it disabled because we got bit by a shipped
    # configure script not quite matching what autoconf would have
    # generated
    if {0 && [file exists [file join $moduleSrcDir configure]]} {
	ModuleHints::logMessage "Using configure script found in\
		[file join $moduleSrcSubDir]"

	set configureScript [file join $moduleSrcDir configure]
    } else {
	cd [file join $moduleSrcDir]
	ModuleHints::logMessage "Working directory:  [pwd]"
	set autoconfCmd "bash autoconf configure.in "
	set configTarget [file join $moduleBuildDir configure]
	append autoconfCmd " > $configTarget"

        if {[catch {file mtime configure.in} configureMtime] == 1} {
	    ModuleHints::logError "configure.in not found in [pwd]"
	    exit 2
	}

	set doAutoconf 1
	if {[catch {file mtime $configTarget} targetMtime] != 1} {
	    if {$targetMtime > $configureMtime} {
	        ModuleHints::logMessage "$configTarget is up to date."
		set doAutoconf 0
	    }
	}

        if {$doAutoconf} {
	    ModuleHints::logMessage "-->\[$autoconfCmd\]"

	    if {[catch {eval exec $autoconfCmd} errMsg]} {
		ModuleHints::logMessage "WARNING:  autoconf for $moduleName generated the following message:"
		ModuleHints::logMessage "$errMsg"
	    }
	}
	set configureScript ./configure
    }

    set configureSwitches [ModuleHints::getConfigureSwitches $moduleName \
	    $flavorStr $platform]
    set configureCmd "bash $configureScript"
    append configureCmd " --srcdir=[ModuleHints::getCygpath $moduleSrcDir]"
    append configureCmd " $configureSwitches"

    # We could add a check to see if a Makefile already exists
    # and only run configure if it does not.  This would prevent us from
    # duplicating some work, but might lead to problems where some
    # files get out of date and never rebuilt without doing a "make clean"

    set moduleBuildDir [file join $buildPrefix $moduleName $moduleSrcSubDir]
    file mkdir $moduleBuildDir
    cd $moduleBuildDir

    if {[CheckSoftStatus configure $moduleName $flavorStr]} {
	ModuleHints::logMessage "Soft status OK for 'configure $moduleName $flavorStr', skipping..."
	return 1
    }
    ModuleHints::logMessage "ConfigureModule (module $moduleName, flavor $flavorStr)"

    if {[ModuleHints::execViaPipe $configureCmd] != 1} {
	ModuleHints::logError "failed: $configureCmd"
	exit 1
    }
    SetSoftStatus configure $moduleName $flavorStr
    return 1
}

# BuildModule::ConfigureAndBuildModule --
#
#	Wrapper for performing both configure and build on a module.
#
# Arguments:
#	moduleName	name of module
#	flavorStr	Build flavor (Debug or Release)
#	makeAction	Make target to trigger
#
# Side Effects:
#	None.
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
# Side Effects:
#	The current working directory is changed to the build directory
#	if it exists.
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

    # Tcl and Tk are not completely TEA compliant.  We need to perform
    # additional steps before we can run their test suites.

    switch -- $moduleName {
	"tcl" {
	    if {[file exists [file join $moduleSrcDir dltest]]} {
		cd [file join $moduleSrcDir dltest]
		exec bash autoconf
	    }
	}
	"tk" {
	    set addFlags "TCL_BIN_DIR=[ModuleHints::getCygpath \
		    [file join $buildPrefix tcl $moduleSrcSubDir]]"
	}
    }

    # TEMPORARY:  Don't print an error message if this is the
    # main package's module.  Just skip it.

    if {[string equal $moduleName [ModuleHints::getPackageName]]} {
	return 1
    }

    if {![file exists $moduleBuildDir]} {
	ModuleHints::logError "No build directory exists for module $moduleName"
	return 0
    }

    cd $moduleBuildDir

    # Let the user override the make program with the MAKE environment
    # variable.

    set makeProg make

    if {[info exists env(MAKE)]} {
	set makeProg $env(MAKE)
    }

    # If the module has not been TEA-ified then we can still build assuming
    # that we can still call various Makefile targets to build the module.
    # Currently none of the modules use this.  It really shouldn't be here
    # since it gives a weak excuse for not TEA-ifying a module.

    set moduleTargetList [ModuleHints::getMakeTargets $moduleName $makeAction]

    set result 1
    foreach target $moduleTargetList {
	if {$addFlags == [list {}]} {
	    set makeCmd "$makeProg $target"
	} else {
	    set makeCmd "$makeProg $target $addFlags"
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
# Side Effects:
#	The current working directory is changed to the top source directory
#	if it exists.
#
# Results:
#	Returns 1 if the update succeeded, 0 if not.

proc BuildModule::UpdateModule {moduleName dummyArg1 dummyArg2} {
    set moduleTopDir [ModuleHints::getModuleTopDir $moduleName]

    if {[string length $moduleTopDir] == 0} {
	ModuleHints::logError "No source directory is known for module $moduleName"
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
#	None.
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
	    switch -exact -- $opt {
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
		modulelist {
		    set moduleList $arg
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
		startmod {
		    set startModule $arg
		}
	    }
	}
    }

    if {![file exists [ModuleHints::getDataFile]]} {
	ModuleHints::logError "Data file '[ModuleHints::getDataFile]' does not exist"
	return 0
    }

    # load the soft status data so we can avoid many configures, makes and installs
    LoadSoftStatus

    switch $makeAction {
	test {
	    set makeProc TestModule
	    set makeDesc "Testing"
	}

	all -
	binaries -
	libraries -
	doc -
	install-binaries -
	install-libraries -
	install-doc -
	depend -
	clean -
	distclean {
	    set makeProc BuildModule
	    set makeDesc "Make $makeAction"
	}

	configure {
	    set makeProc ConfigureModule
	    set makeDesc "Configuring"
	}

	install {
	    set makeProc ConfigureAndBuildModule
	    set makeDesc "Configuring and building"
	}

	reinstall {
	    set makeProc ConfigureAndBuildModule
	    set makeDesc "Configuring, building and reinstalling"
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

    ModuleHints::logMessage "Using makeProc=$makeProc"

    set failedModules {}
    set succeededModules {}
    if {$makeDependentModules} {
	if {[llength $moduleList] == 1} {
	    set depModuleList \
		    [ModuleHints::getCanonicalDependencies $moduleList {}]
	    ModuleHints::logMessage "$makeDesc dependent modules $depModuleList"

	    # Do an install for each dependent module.

	    foreach module $depModuleList {
		ModuleHints::logMessage "$makeDesc module $module"
		ModuleHints::logMessage "Time:  [clock format [clock seconds]]"
		set buildResult [$makeProc $module $flavorStr $makeAction]

		if {$buildResult != 1} {
		    ModuleHints::logMessage "build failed, exiting"
		    exit 1
		    lappend failedModules $module
		} else {
		    lappend succeededModules $module
		}
	    }
	} else {
	    ModuleHints::logError \
		    "You can't build multiple modules with the -recurse option!"
	    exit 1
	}
    }

    set stamp [clock format [clock seconds] -format "%H:%M:%S"]
    if {[llength $moduleList] > 1} {
	ModuleHints::logMessage "$stamp $makeDesc modules: $moduleList"
    } else {
	ModuleHints::logMessage "$stamp $makeDesc module: $moduleList"
    }
    ModuleHints::logMessage "Time:  [clock format [clock seconds]]"

    foreach moduleName $moduleList {
	set buildResult [$makeProc $moduleName $flavorStr $makeAction]

	if {$buildResult != 1} {
	    lappend failedModules $moduleName
	ModuleHints::logMessage "$makeProc $moduleName failed"
	    exit 1
	} else {
	    lappend succeededModules $moduleName
	}
    }

    if {[llength $succeededModules] != 0} {
	ModuleHints::logMessage ""
	ModuleHints::logMessage ""
	ModuleHints::logMessage "$makeDesc completed with no errors for:"
	ModuleHints::logMessage "\t$succeededModules"
    }

    if {[llength $failedModules] != 0} {
	ModuleHints::logError ""
	ModuleHints::logError ""
	ModuleHints::logError "***Errors during build***"
	ModuleHints::logError "$makeDesc generated errors for:"
	ModuleHints::logError "\t$failedModules"

	return 0
    }

    return 1
}


