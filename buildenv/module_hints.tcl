# module_hints.tcl --
#
#	Utility routines for the build environment.
#
# Copyright (c) 1999-2000 by Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: module_hints.tcl,v 1.10 2001/06/04 08:02:43 davygrvy Exp $

package provide ModuleHints 1.0

namespace eval ModuleHints {
    namespace export getCanonicalDependencies getModuleTopDir \
	    getDataFile setDataFile getBestIndex execViaPipe \
	    isValidModule getModuleSrcSubDir getPackageName \
	    logError logMessage

    variable dataFile {}
}

# ModuleHints::setDataFile --
#
#	Sets the path to the module data file
#
# Arguments:
#	fileName	Full path to the module data file
#
# Results:
#	Sets the variable "ModuleHints::dataFile"

proc ModuleHints::setDataFile {fileName} {
    variable dataFile

    set dataFile $fileName

    source $dataFile
}

# ModuleHints::getDataFile --
#
#	Returns the path to the module data file
#
# Arguments:
#	None
#
# Results:
#	Returns the path to the module data file

proc ModuleHints::getDataFile {} {
    variable dataFile

    return $dataFile
}

# ModuleHints::deleteModuleData --
#
#	Erase the information learned from the module data file.
#
# Arguments:
#	None
#
# Side Effects:
#	The ModuleData namespace is deleted.
#
# Results:
#	None.

proc ModuleHints::deleteModuleData {} {
    variable dataFile
    
    set dataFile {}
    if {[namespace children [namespace current] ModuleData] != ""} {
	namespace delete ModuleData
    }

    return
}

# ModuleHints::getModuleSrcSubDir --
#
#	Return the source directory containing configure.in for this module.
#
# Arguments:
#	module	name of module
#
# Results:
#	Returns the full path to the source directory

proc ModuleHints::getModuleSrcSubDir {moduleName} {
    set index [getBestIndex ModuleData::srcSubDir \
	    $moduleName $moduleName,$ModuleData::platform]

    return $index
}

# ModuleHints::getModuleTopDir --
#
#	Return the top level directory for the specified module
#
# Arguments:
#	module	name of module
#
# Results:
#	Returns the full path to the source directory

proc ModuleHints::getModuleTopDir {moduleName} {
    set index [getBestIndex ModuleData::topDir $moduleName]

    return $index
}

# ModuleHints::getCanonicalDependencies --
#
#	Return an ordered list of modules that need to be built in order
#	to build the specified module.  This routine also searches for the
#	the depedencies on the dependencies, ad nauseum, until the complete
#	list of dependent modules is found.
#
# Arguments:
#	module	name of module
#
# Results:
#	Returns a list of submodules to be built (in order).  Recursion is fun.

proc ModuleHints::getCanonicalDependencies {moduleName modulePath {callbackCmd {}} {modulePrefix {}}} {
    set modList {}

    if {$modulePrefix == ""} {
	set modulePrefix $moduleName
    }

    if {[lsearch $modulePath $moduleName] != -1} {
	lappend modulePath $moduleName
	logError "Poorly constructed module dependency list:"
	logError "Circular dependency found:  [join $modulePath -->]"
	error "Poorly constructed module dependency list:\nCircular dependency found:  [join $modulePath -->]"
    }

    lappend modulePath $moduleName

    foreach depModule [getDependencies $moduleName $callbackCmd $modulePrefix] {
	if {![isValidModule $depModule]} {
	    continue
	}
	set depModuleDepList [getCanonicalDependencies $depModule \
		$modulePath $callbackCmd $modulePrefix.$depModule]

	foreach mod $depModuleDepList {
	    if {[string length $mod] > 0} {
		if {[lsearch -exact $modList $mod] == -1 &&
		    [lsearch -exact $modulePath $mod] == -1} {

		    lappend modList $mod
		}
	    }
	}

	if {[lsearch -exact $modList $depModule] == -1 &&
		![string match $moduleName $depModule]} {
	    lappend modList $depModule
	}
    }

    return $modList
}

# ModuleHints::getDependencies --
#
#	Return an ordered list of modules that need to be built in order
#	to build the specified module.
#
# Arguments:
#	module	name of module
#
# Results:
#	Returns a list of submodules to be built (in order)

proc ModuleHints::getDependencies {moduleName {callbackCmd {}} {modulePrefix {}}} {
    set moduleTopDir [getModuleTopDir $moduleName]

    set depList {}

    # Dependencies can be specified in two places.  The DEPENDENCIES file
    # in the top level directory of a module is used if it exists, else
    # the information in module_data.tcl is used.

    set depFile [file join $moduleTopDir DEPENDENCIES]
    if {[file exists $depFile]} {
	set fileId [open $depFile r]
	while {![eof $fileId]} {
	    gets $fileId line
	    set line [string trim $line]
	    if {![eof $fileId] \
		    && [string length $line] > 0 \
		    && ![string equal [string index $line 0] "#"]} {
		lappend depList $line
	    }
	}
	close $fileId
    } else {
	set depList [getBestIndex ModuleData::moduleDep \
		$moduleName $moduleName,$ModuleData::platform]
    }

    # Invoke any user-supplied callback.

    if {$callbackCmd != ""} {
	eval $callbackCmd $moduleName [list $modulePrefix] $depList
    }

    return $depList
}

# ModuleHints::getConfigureSwitches --
#
#	Generates a set of configure switches specific for building
#	a given flavor of a module.
#
# Arguments:
#	module	name of module
#	flavor	flavor of build (Debug or Release)
#	platform Host platform type (win32-ix86, linux-ix86, solaris-sparc, ...)
#
# Results:
#	Returns a string to be appended to the configure line.  These
#	switches are loaded from module_data.tcl.

proc ModuleHints::getConfigureSwitches {moduleName flavorStr platform} {
    set result {}
    append result "[getValue configureSwitch(standard)]"
    append result " [getValue configureSwitch($moduleName)]"
    append result " [getValue configureSwitch($platform)]"
    append result " [getValue configureSwitch($flavorStr)]"
    append result " [getValue configureSwitch($moduleName,$platform)]"
    append result " [getValue configureSwitch($moduleName,$flavorStr)]"
    append result " [getValue configureSwitch($moduleName,$flavorStr,$platform)]"

    return $result
}

# ModuleHints::getMakeTargets --
#
#	Takes a xml-server make target and translates into an equivalent
#	make target for a given module.  If the module has been TEA-ified
#	then this returns the input makefile action/target.
#
# Arguments:
#	module	name of module
#	makeAction	Makefile target to translate
#
# Results:
#	Returns a list of makefile targest specific for this module.

proc ModuleHints::getMakeTargets {moduleName makeAction} {
    set index [getBestIndex ModuleData::makeTarget \
	    $moduleName $moduleName,$makeAction]

    # If nothing else was specified, then assume the module is TEA
    # compliant and use the normal target name.

    if {$index == ""} {
	return $makeAction
    } else {
	return $index
    }
}

# ModuleHints::getValue --
#
#	Return a value from the ModuleData namespace
#
# Arguments:
#	varName	Name of value to retrieve
#
# Results:
#	Returns the value requested, or an empty string if the variable doesn't
#	exist.

proc ModuleHints::getValue {varName} {
    if {[info exists ModuleData::$varName]} {
	return [set ModuleData::$varName]
    } else {
	return {}
    }
}

# ModuleHints::getBestIndex --
#
#	Find the value of the array's "best" existing index.  The best
#	index is determined by order of the args--the last existing one
#	is best.  If none exist, then the empty index is used.
#
# Arguments:
#	args	The first elt of args is the name of the global array.
#		The rest of the elts of args indexes of the global array
#		to be accessed (in order).
#
# Results:
#	Returns the value of the array's "best" existing index.

proc ModuleHints::getBestIndex {args} {
    set arrayName [lindex $args 0]

    if {![info exists [set arrayName]()]} {
	set result {}
    } else {
	set result [set [set arrayName]()]
    }

    foreach index [lrange $args 1 end] {
	if {[info exists [set arrayName]($index)]} {
	    set result [set [set arrayName]($index)]
	}
    }
    return $result
}

# ModuleHints::execViaPipe --
#
#	Run a command in a pipe and send the output to stdout line by line.
#	This allows the user to watch what the command is doing.
#
# Arguments:
#	cmd	Command to execute
#
# Results:
#	Returns 1 if command completed successfully, 1 if successful.

proc ModuleHints::execViaPipe {cmd} {
    logMessage "\nWorking directory:  [pwd]"
    logMessage "-->\[$cmd\]\n"
    set chanId [open "| $cmd |& cat -u" r]
    fconfigure $chanId -buffering line
    while {![eof $chanId]} {
	gets $chanId line
	logMessage $line
    }
    if {[catch {close $chanId}]} {
	logError "***ERROR:  command returned nonzero exit status"
	logError "\tWorking Directory:  [pwd]"
	logError "\tFailed Command:  $cmd"
	logError "\n"
	return 0
    }
    logMessage "\n"
    return 1
}

# ModuleHints::getCygpath --
#
#	Convert a path from Windows style to Cygnus style.
#
# Arguments:
#	pathName	Path to translate
#
# Results:
#	Returns the translated path.  No effect if a non-cygnus path is used.

proc ModuleHints::getCygpath {pathName} {
    if {[IsWindows $ModuleData::platform]} {
	if {[regexp ^(.): $pathName null driveLetter]} {
	    regsub ^.: $pathName {} pathName
	    regsub -all {\\} $pathName / pathName
	    set pathName /cygdrive/$driveLetter/$pathName
	}
    }

    return $pathName
}

# ModuleHints::getWinpath --
#
#	Convert a path from Cygnus style to Windows Tcl style.
#
#       For example, /cygdrive/e/frammistan -> E:/frammistan
#
# Arguments:
#	pathName	Path to translate
#
# Results:
#	Returns the translated path.  No effect if a non-cygnus path is used.

proc ModuleHints::getWinpath {pathName} {
    if {[IsWindows $ModuleData::platform]} {
	regsub -nocase {^/cygdrive/([a-z])/(.*)$} $pathName {\1:/\2} pathName
    }
    return $pathName
}


# ModuleHints::IsWindows --
#
#	Determine if a given platform is Windows based or not.
#
# Arguments:
#	platform	Platform name
#
# Results:
#	Returns 1 if this is a Windows platform, 0 if not.

proc ModuleHints::IsWindows {platform} {
    return [regexp -nocase {win} $platform]
}

# ModuleHints::isValidModule --
#
#	Determine if a given module is valid for the current platform
#
# Arguments:
#	moduleName	Name of module to check
#
# Results:
#	Returns 1 if this module is in the current platform's module list,
#	0 if not.

proc ModuleHints::isValidModule {moduleName} {
    if {[lsearch $ModuleData::MODULE_LIST $moduleName] != -1} {
	return 1
    } else {
	return 0
    }
}

# ModuleHints::getModuleListing --
#
#	Return the entire list of available modules.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	A Tcl list containing module names is returned.

proc ModuleHints::getModuleListing {} {
    if {[info exists ModuleData::MODULE_LIST]} {
	return $ModuleData::MODULE_LIST
    } else {
	return {}
    }
}

# ModuleHints::getPackageName --
#
#	Returns the name of the main software package
#
# Arguments:
#	None.
#
# Results:
#	Returns a string containing the name of the main package.

proc ModuleHints::getPackageName {} {
    return $ModuleData::packageName
}

# ModuleHints::logError --
#
#	Redefinable routine for logging error messages.
#
# Arguments:
#	string		Error message to log.
#
# Results:
#	None.

proc ModuleHints::logError {string} {
    puts stderr $string
}

# ModuleHints::logMessage --
#
#	Redefinable routine for logging output messages.
#
# Arguments:
#	string		Status message to log.
#
# Results:
#	None.

proc ModuleHints::logMessage {string} {
    puts stdout $string
}
