# module_ops.tcl --
#
#	This file contains procedures to extract information about the
#	various modules.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: module_ops.tcl,v 1.9 2000/10/31 23:30:47 welch Exp $

package require ModuleHints
package require BuildModule
package provide ModuleOps 1.0

namespace eval ::ModuleOps {
    # The list of available modules is stored internally so that we don't
    # have to keep looking at the module_data file to see what they are.
    variable moduleList {}

    # This variable is used for sorting the module list so that we can ensure
    # that  a module's dependencies are built before the module.
    variable sortedModuleList {}

    # The following set of variables are set by the user via the graphical
    # interface.

    # Additional flags to pass to the master configure script.
    variable configureOptions {}

    # Engineers should be performing debug builds by default.
    variable buildFlavor Debug

    # This directory contains the configure.in file for the master module.
    variable masterDir {}

    # This directory is where the Makefile will be generated and run.
    # Temporary build files (.o, etc.) are also put here.
    variable buildDir {}

    # This is where output files are installed.
    variable installDir {}

    # This variable is used to record the action the user wants to take.
    # Valid values are "hose", "all", "test", "update"
    variable buildAction
    set buildActions [list hose update install test]
    set buildAction(hose)	0
    set buildAction(update)	0
    set buildAction(install)	0
    set buildAction(test)	0

    # The list of modules that the user wants to act upon.
    variable activeModuleList {}

    # The path to the master module's configure script.  If we have to
    # build it from configure.in, then it will be in the build directory.
    # If the module comes with one, then it will be in the master directory.
    variable masterConfigurePath {}

    # The name of the file containing the current project settings.
    variable projectFile {}
}

# ::ModuleOps::syncListing --
#
#       Synchronize the list of all possible modules with the listing in
#	the file "config.status"
#
# Arguments:
#       buildDir	Directory in which to find config.status
#
# Results:
#       Returns a list of module names.

proc ::ModuleOps::syncListing {buildDir} {
    variable moduleList
    set config_status [file join $buildDir config.status]

    if {![file exists $config_status]} {
	return {}
    }

    set chanId [open $config_status r]
    while {![eof $chanId]} {
	gets $chanId line
	if {[regexp {^s%@MODULE_LIST@%(.*)%g$} $chanId null moduleList]} {
	    break
	}
    }

    return $moduleList
}

# ::ModuleOps::getListing --
#
#       Return the list of all modules found during the last call to
#	syncListing.
#
# Arguments:
#       None.
#
# Results:
#       Returns a list of module names.

proc ::ModuleOps::getListing {} {
    variable moduleList

    return $moduleList
}

# ::ModuleOps::isValidModule --
#
#       Checks if a module is in the module list.
#
# Arguments:
#       moduleName
#
# Results:
#       Returns 1 if the module is in the list, 0 if not.

proc ::ModuleOps::isValidModule {moduleName} {
    variable moduleList

    if {[lsearch $moduleList $moduleName] != -1} {
	return 1
    } else {
	return 0
    }
}

# ::ModuleOps::addActiveModule --
#
#	Adds the specified module to the active module listing.
#
# Arguments:
#	module		Name of module to add.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::ModuleOps::addActiveModule {module} {
    variable activeModuleList

    if {![isValidModule $module]} {
	bgerror "$module is not a valid module!"
    }

    if {[lsearch -exact $activeModuleList $module] == -1} {
	lappend activeModuleList $module
    }

    return
}

# ::ModuleOps::removeActiveModule --
#
#	Removes the specified module from the active module listing.
#
# Arguments:
#	module		Name of module to remove.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::ModuleOps::removeActiveModule {module} {
    variable activeModuleList

    if {![isValidModule $module]} {
	bgerror "$module is not a valid module!"
    }

    set modIndex [lsearch -exact $activeModuleList $module]
    if {$index != -1} {
	set activeModuleList [lreplace $activeModuleList $index $index]
    }

    return
}

# ::ModuleOps::setActiveModules --
#
#	Sets the current list of active module to the specified list.
#
# Arguments:
#	modules		Tcl list of module names.
#
# Side Effects:
#	The activeModuleList variable may be updated.
#
# Results:
#	If an invalid module is found, no changes are made to the current
#	active module listing.

proc ::ModuleOps::setActiveModules {modules} {
    variable activeModuleList

    set validModuleList {}
    foreach module $modules {
	if {[isValidModule $module]} {
	    lappend validModuleList $module
	} else {
	    bgerror "$module is not a valid module!"
	}
    }

    set activeModuleList $validModuleList

    return
}

# ::ModuleOps::configureMasterModule --
#
#       Run the configure script for the master module.  This should cause
#	the module_data.tcl file to be generated.
#
# Arguments:
#	None.
#
# Side Effects:
#	configure output files are generated in the build directory.
#
# Results:
#       Returns 1 if configure succeeded with no errors, 0 otherwise.

proc ::ModuleOps::configureMasterModule {} {
    variable buildFlavor
    variable buildDir
    variable installDir
    variable masterDir
    variable configureOptions
    variable masterConfigurePath

    cd $buildDir
    ::ModuleHints::execViaPipe "sh $masterConfigurePath --prefix=$installDir --srcdir=$masterDir --with-build-prefix=$buildDir --with-flavor=$buildFlavor $configureOptions"
}

# ::ModuleOps::autoconfMasterModule --
#
#       Run autoconf for the master module to produce its configure script.
#
# Arguments:
#       None.
#
# Side Effects:
#
#	A configure script is created in masterDir.
#
# Results:
#       Returns 1 if autoconf succeeded with no errors, 0 otherwise.

proc ::ModuleOps::autoconfMasterModule {} {
    variable masterDir
    variable buildDir
    variable masterConfigurePath

    cd $masterDir
    set autoconfResult [::ModuleHints::execViaPipe \
	    "autoconf configure.in > [file join $buildDir configure]"]
    if {[file exists [file join $buildDir configure]]} {
	set masterConfigurePath [file join $buildDir configure]
    } else {
	set autoconfResult 0
    }

    return $autoconfResult
}

# ::ModuleOps::takeBuildAction --
#
#       Take some action using the Makefile.
#
# Arguments:
#	None.
#
# Side Effects:
#
#	Files may be modified in the buildDir and installDir
#
# Results:
#       1 if action succeeded, 0 if errors were detected.

proc ::ModuleOps::takeBuildAction {} {
    variable activeModuleList
    variable buildAction
    variable buildActions
    variable buildDir
    variable buildFlavor
    set activeActions {}

    if {![file exists $buildDir]} {
	return 0
    }

    cd $buildDir

    foreach action $buildActions {
	if {$buildAction($action)} {
	    lappend activeActions $action
	}
    }

    foreach action $activeActions {
	switch -- $action {
	    hose {
		set makeArgs {}
		foreach module $activeModuleList {
		    lappend makeArgs $module-hose
		}
		::ModuleHints::execViaPipe "make $makeArgs"
	    }
	    update -
	    test -
	    all -
	    install {
		::BuildModule::runBuild -modulelist $activeModuleList \
			-flavor $buildFlavor -makeAction $action
	    }
	    default {
		::ModuleHints::logError "Invalid build action $buildAction"
		return 0
	    }
	}
    }
}

# ::ModuleOps::initMaster --
#
#       Initialize a new master module by running autoconf (if needed)
#	and configure in the master directory.  The module_data.tcl file
#	produced is then loaded.
#
# Arguments:
#	doConfigure	Boolean value specifying if we have to run
#			configure in the master module to generate the
#			module_data.tcl file.
#
# Side Effects:
#
#	The build directory will be created if necessary.  Files will be
#	created in the buildDir.  The ModuleData namespace will be created.
#
# Results:
#       1 if build succeeded, 0 if errors were detected.

proc ::ModuleOps::initMaster {{doConfigure 1}} {
    variable configureOptions
    variable masterDir
    variable buildDir
    variable installDir
    variable masterConfigurePath
    variable sortedModuleList

    # Validate the various directories that we're going to be using.

    if {$buildDir == ""} {
	bgerror "Build directory name can not be left blank"
	return 0
    }
    if {$installDir == ""} {
	bgerror "Install directory name can not be left blank"
	return 0
    }
    if {$masterDir == ""} {
	bgerror "Master directory name can not be left blank"
	return 0
    }

    if {![file exists [file join $buildDir]]} {
	file mkdir $buildDir
    }

    if {$doConfigure} {
	if {![file exists [file join $masterDir configure]]} {
	    if {![file exists [file join $masterDir configure]]} {
		::ModuleOps::autoconfMasterModule
	    }

	    if {![file exists [file join $masterDir configure]]} {
		::ModuleHints::logMessage "autoconf failed"
		return 0
	    }
	} else {
	    set masterConfigurePath [file join $masterDir configure]
	}

	set result [::ModuleOps::configureMasterModule]
    }

    ::ModuleHints::setDataFile [file join $buildDir module_data.tcl]

    # Generate the build order for the entire list of modules.

    set sortedModuleList [::ModuleHints::getCanonicalDependencies [::ModuleHints::getPackageName] {}]

    return $result
}

# ::ModuleOps::getProjectFile --
#
#	Retrieve the name of the current project file, if it exists.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	The name of the current project file.  This may be the empty string
#	if there is no project file.

proc ::ModuleOps::getProjectFile {} {
    variable projectFile

    return  $projectFile
}

# ::ModuleOps::setProjectFile --
#
#	Set the name of the current project file.
#
# Arguments:
#	fileName	Name to use for the new project file.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::ModuleOps::setProjectFile {fileName} {
    variable projectFile

    set projectFile $fileName

    return
}

# ::ModuleOps::saveProject --
#
#	Dump the current project settings to a named file in a format that
#	can later be loaded.
#
# Arguments:
#	filename	Name of file in which to dump the project settings.
#
# Side Effects:
#	The file may be created if it does not exist.
#
# Results:
#	None.

proc ::ModuleOps::saveProject {filename} {
    set fileId [open $filename w]
    foreach el "buildFlavor masterDir buildDir installDir" {
	variable $el
	puts $fileId [list $el [set $el]]
    }
    close $fileId

    return
}

# ::ModuleOps::closeProject --
#
#	Delete the current project settings.
#
# Arguments:
#	None.
#
# Side Effects:
#	The current project will no longer be available.
#
# Results:
#	None.

proc ::ModuleOps::closeProject {} {
    variable masterDir
    variable buildDir
    variable installDir
    variable buildFlavor
    variable moduleList
    variable projectFile

    set masterDir {}
    set buildDir {}
    set installDir {}
    set buildFlavor {}
    set moduleList {}
    set projectFile {}

    ::ModuleHints::deleteModuleData

    return
}

# ::ModuleOps::openProject --
#
#	Load new project settings from a file.
#
# Arguments:
#	|>args<|
#
# Side Effects:
#	|>args<|
#
# Results:
#	Returns a list of 2 elements.  The first element is 1 or 0 indicating
#	if the procedure completed successfully or not.  The second
#	element contains the error message, if an error was found.

proc ::ModuleOps::openProject {filename} {
    if {[catch {
	set fileId [open $filename r]
	while {![eof $fileId]} {
	    gets $fileId line

	    if {[eof $fileId]} {
		# Skip eof
	    } elseif {[string length $line] == 0} {
		# Skip empty lines
	    } elseif {[regexp ^# $line]} {
		# Skip comments
	    } elseif {[llength $line] != 2} {
		error "Bad line found in project file:  $line"
	    } else {
		set varName [lindex $line 0]
		set value [lindex $line 1]

		if {![info exists [namespace current]::$varName]} {
		    error "Invalid parameter found in project file: \
			    $varName"
		}

		set ::ModuleOps::$varName $value
	    }
	}
    } errMsg]} {
	global errorInfo
	set result 0
	set resultString $errMsg\n$errorInfo
    } else {
	set result 1
	set resultString {}
    }

    return [list $result $resultString]
}

# ::ModuleOps::CompareModuledep --
#
#	Comparison routine that is passed to Tcl's lsort procedure.  This
#	compares the position of two modules in the sorted array.
#
# Arguments:
#	modA	First module in comparison.
#	modB	Second module in comparison.
#
# Side Effects:
#	None.
#
# Results:
#	>0 if modA appears after modB in the dependency list, or if modA
#	   does not appear in the dependency list.
#	0  if modA and modB are the same
#	<0 if modA appears before modB in the dependency list, or if modB
#	   does not appear in the dependency list.

proc ::ModuleOps::CompareModuledep {modA modB} {
    variable sortedModuleList

    set indexA [lsearch -exact $sortedModuleList $modA]
    set indexB [lsearch -exact $sortedModuleList $modB]

    if {$indexA == -1} {
	return 1
    }
    if {$indexB == -1} {
	return -1
    }
    if {$indexA == $indexB} {
	return 0
    }

    return [expr $indexA - $indexB]
}
