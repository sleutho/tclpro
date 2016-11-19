# moduleKnowledge.tcl
# -*- tcl -*-
#
#	This file implements functions to handle a static database
#	of build information about tcl modules.
#
# Copyright (c) 2001 by ActiveState Tool Corp.
# See the file license.terms.
#
# RCS: @(#) $Id: moduleKnowledge.tcl,v 1.1 2001/03/30 16:35:06 andreas_kupries Exp $

package require fileutil
package require log 1.0 ; # log facility from tcllib



package provide ModuleKnowledge 1.0
namespace eval  ModuleKnowledge {
    # No variables yet.
    namespace export 			\
	    setKnowledgeDir		\
	    getKnowledgeDir		\
	    listModules			\
	    getDependencies		\
	    getSrcDirectory		\
	    getSubmodules		\
	    getDerivedModules		\
	    getConfigurationFlags	\
	    getTestDirectories		\
	    getVersion			\
	    getPlatforms		\
	    getTopDir			\
	    isDerived			\
	    getParent			\
	    setParent			\
	    renameModule		\
	    known			\
	    unresolvedDependencies	\
	    getBuildVariables

    # Path to the knowledge directory currently in use. The initial
    # value used here means 'not initialized'. All files in this
    # directory are read and their contents is added to the internal
    # database.

    variable knowledge {}

    # Array and list of all modules whose build information was found in the
    # knowledge directory. An array was chosen to allow easier manipulation
    # later, the list can then be regenerated from it. Initially both
    # are generated during the scan.

    variable  modules {}
    variable  modarray
    array set modarray {}

    # Array mapping from modules to their dependencies. Modules
    # without dependencies have empty lists as their values. A missing
    # module means that the system was unable to determine its
    # dependencies.

    variable  dependencies
    array set dependencies {}

    # Array mapping from a module to the modules which depend on
    # it. This is the complement of the information in
    # 'dependencies'. 'dependencies' containts the forward mapping,
    # this array the backward one. The array is filled during the
    # consolidation phase (as part of the overall correction of
    # dependency references).

    variable  depBack
    array set depBack {}

    # Array mapping from modules to their src sub directories. This is
    # defined for all modules! Subdirectories of the knowledge for
    # which no src directory could be determined are not considered to
    # be modules at all.

    variable  srcsubdirs
    array set srcsubdirs {}

    # Array mapping from modules to the names of their
    # submodules. Modules without submodules have empty lists as their
    # values. A missing module means that the system was unable to
    # determine its submodules.

    variable  subModules
    array set subModules {}

    # Array mapping from modules to the names of their
    # derivatives. Modules without derivatives have empty lists as
    # their values. A missing module means that the system was unable
    # to determine its derivatives.

    variable  derivModules
    array set derivModules {}

    # Array mapping from modules to the configuration flags
    # Modules without flags have empty lists as their values. A
    # missing module means that the system was unable to determine its
    # flags.

    variable  configFlags
    array set configFlags {}

    # Array mapping from modules to their testsuites. Modules without
    # a testsuite have empty lists as their values. A missing module
    # means that the system was unable to locate its testsuite.

    variable  testDirs
    array set testDirs {}

    # Array mapping from modules to their version. Modules without
    # a version have empty lists as their values. A missing module
    # means that the system was unable to determine its version.

    variable  modVersion
    array set modVersion {}

    # Array mapping from modules to the platforms it is restricted
    # to. Modules without restrictions in that regard have empty lists
    # as their values. A missing module means that the system was
    # unable to determine its platforms.

    variable  modPlatform
    array set modPlatform {}

    # Array mapping from modules to their toplevel directories. Each
    # known module has to have an entry here. The path is relative to
    # the workspace and explictly specified in the module information.
    # This value can be used by higher levels of the build system to
    # look for modules which were not recognized by [ModuleWorkspace]
    # by itself.

    variable  topDirectory
    array set topDirectory {}

    # Array mapping from a derived module to its parent.

    variable  parent
    array set parent {}

    # Special list holding the names of all modules which were used as
    # dependencies but could not be resolved in the consolidation
    # phase. These have to be handled by higher levels.

    variable unresolvedDependencies {}

    # List of build-variables used by all configuration flags in all
    # known modules. Provided to higher level modules to allow them
    # checks that all build-variables have proper values.

    variable buildVariables {}

    # ----------------------------------------

    # Internal array, used by the scanner to collect information about
    # a single module.

    variable  modInfo
    array set modInfo {}
}

# ModuleKnowledge::setKnowledgeDir --
#
#	Tells the package the location of the knowledge directory to read.
#
# Arguments:
#	path	Path of the knowledge directory. The command validates both
#		existence and accessibility (readability) of the path and
#		then read the information files in it.
#
# Side Effects:
#	Initializes the package by scanning the knowledge directory and
#	reading the information about the various modules declared inside.
#
# Results:
#	None.

proc ModuleKnowledge::setKnowledgeDir {path} {
    variable knowledge

    AlreadyInitialized?

    if {![file exists $path]} {
	return -code error "Path $path does not exist"
    }
    if {![file isdirectory $path]} {
	return -code error "Path $path is no directory"
    }
    if {![file readable $path]} {
	return -code error "Path $path is not readable"
    }

    set knowledge $path
    ScanKnowledge
    ConsolidateDependencies
    return
}

# ModuleKnowledge::getKnowledgeDir --
#
#	Returns the path to the currently used knowledge directory. Calling this
#	command without a preceding [setKnowledge] will result in an error
#	(system not initialized).
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	The path to the currently used knowledge.

proc ModuleKnowledge::getKnowledgeDir {} {
    variable knowledge
    Initialized?
    return $knowledge
}

# ModuleKnowledge::listModules --
#
#	Returns a list containing the names of the modules which were found in
#	the knowledge directory. Calling this command without a preceding [setKnowledgeDir]
#	will result in an error (system not initialized).
#
# Arguments:
#	None
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleKnowledge::listModules {} {
    variable modules
    Initialized?
    return $modules
}

# ModuleKnowledge::isModule --
#
#	Checks wether the specified string is the name of known module.
#
# Arguments:
#	module	The potential name of a module, the string to check.
#
# Side Effects:
#	None.
#
# Results:
#	A boolean value. 1 signals that the string is the name of a
#	known module.

proc ModuleKnowledge::isModule {module} {
    variable srcsubdirs
    Initialized?
    return [info exists srcsubdirs($module)]
}

# ModuleKnowledge::getDependencies --
#
#	Returns a list containing the names of the modules the specified module
#	is dependent upon. The system does not check wether the dependencies
#	actually exist in the knowledge. Calling this command without a
#	preceding [setKnowledge] will result in an error (system not initialized).
#	An error is also thrown if the system was unable to determine the
#	dependencies of the module in question.
#
# Arguments:
#	module	The name of the module whose dependencies we want to know.
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleKnowledge::getDependencies {module} {
    variable dependencies
    Initialized?
    if {[info exists dependencies($module)]} {
	return $dependencies($module)
    } else {
	return -code error "Unable to determine dependencies of $module"
    }
}

# ModuleKnowledge::getSrcDirectory --
#
#	Returns a serialized array containing the relative paths [x] to the
#	various configure.in files found in the module. Keys of the array are
#	the names of the known platforms and the empty string. The value
#	associated to the latter gives the path to a platform independent
#	configure.in file. It is the responsibility of the caller to pick the
#	correct path and configure.in for its purposes, especially as it is
#	only the caller who knows the platform the current build is done on.
#
#	[x] Relative to the toplevel directory of the module.
#
# Arguments:
#	module	The name of the module queried by the caller.
#
# Side Effects:
#	None.
#
# Results:
#	A serialized array.

proc ModuleKnowledge::getSrcDirectory {module} {
    variable srcsubdirs
    Initialized?
    return $srcsubdirs($module)
}

# ModuleKnowledge::getSubmodules --
#
#	Returns a list containing the names of the modules which are defined as
#	submodules of the specified module.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleKnowledge::getSubmodules {module} {
    variable subModules
    Initialized?
    if {[info exists subModules($module)]} {
	return $subModules($module)
    } else {
	return -code error "Unable to determine the subModules of $module"
    }
}

# ModuleKnowledge::getDerivedModules --
#
#	Returns a list containing the names of the modules which are defined as
#	derivations of the specified module. A derivation of a module is
#	essentially the module itself, but configured differently than the base.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleKnowledge::getDerivedModules {module} {
    variable derivModules
    Initialized?
    if {[info exists derivModules($module)]} {
	return $derivModules($module)
    } else {
	return -code error "Unable to determine the derived modules of $module"
    }
}

# ModuleKnowledge::getConfigurationFlags --
#
#	Returns a serialized array containing the configuration flags for the
#	module for the various platforms and build flavors. It is the
#	responsibility of the caller to select the appropriate flags as only
#	it knows the platform the current build is done on, and its flavor.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A serialized array.

proc ModuleKnowledge::getConfigurationFlags {module} {
    variable configFlags
    Initialized?
    if {[info exists configFlags($module)]} {
	return $configFlags($module)
    } else {
	return -code error "Unable to determine the configuration flags of $module"
    }
}

# ModuleKnowledge::getTestDirectories --
#
#	Returns a list containing the relative paths of the directories which
#	contain the testsuite of the specified module.
#
#	[x] Relative to the toplevel directory of the module.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A list of paths.

proc ModuleKnowledge::getTestDirectories {module} {
    variable testDirs
    Initialized?
    if {[info exists testDirs($module)]} {
	return $testDirs($module)
    } else {
	return -code error "Unable to determine the testsuite of $module"
    }
}

# ModuleKnowledge::getVersion --
#
#	Returns the version of the specified module which was found when
#	scanning the knowledge.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A string.

proc ModuleKnowledge::getVersion {module} {
    variable modVersion
    Initialized?
    if {[info exists modVersion($module)]} {
	return $modVersion($module)
    } else {
	return -code error "Unable to determine the version of $module"
    }
}

# ModuleKnowledge::getPlatforms --
#
#	Returns a list containing the names of the platforms the module is
#	restricted to. An empty list means that the module can be used and
#	compiled for all platforms.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleKnowledge::getPlatforms {module} {
    variable modPlatform
    Initialized?
    if {[info exists modPlatform($module)]} {
	return $modPlatform($module)
    } else {
	return -code error "Unable to determine the platforms of $module"
    }
}

# ModuleKnowledge::getTopDir --
#
#	Returns the path of the toplevel directory for the specified
#	module, relative to the workspace directory.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A path

proc ModuleKnowledge::getTopDir {module} {
    variable topDirectory
    Initialized?

    if {[info exists topDirectory($module)]} {
	return $topDirectory($module)
    } else {
	return -code error "Unable to determine the toplevel directory of $module"
    }
}

# ModuleKnowledge::isDerived --
#
#	Checks wether the specified module was derived from some other
#	module.
#
# Arguments:
#	module	Name of the module.
#
# Side Effects:
#	None.
#
# Results:
#	A boolean value. True signals that the module is derived.

proc ModuleKnowledge::isDerived {module} {
    variable parent
    return [info exists parent($module)]
}

# ModuleKnowledge::getParent --
#
#	Returns the parent of the specified derived module.
#
# Arguments:
#	module	Name of the module.
#
# Side Effects:
#	None.
#
# Results:
#	A string.

proc ModuleKnowledge::getParent {module} {
    variable parent
    return $parent($module)
}

# ModuleKnowledge::setParent --
#
#	Change the parent of the specified derived module.
#
# Arguments:
#	module		Name of the module to change.
#	newParent	Name of its new parent.
#
# Side Effects:
#	See above.
#
# Results:
#	None.

proc ModuleKnowledge::setParent {module newParent} {
    variable parent
    if {[info exists parent($module)]} {
	set parent($module) $newParent
	return
    } else {
	return -code error "Tried to reparent the non-derived module $module"
    }
}


# ModuleKnowledge::renameModule --
#
#	Renames the specified module, changing all references to it too. It is
#	allowed to rename a module which was not declared to the knowledge.
#	This is as it can be referenced as a dependency of some known module!
#	In such a case only these dependency references are changed.
#
# Arguments:
#	module		Name of the module to change.
#	newName		New name of the module.
#
# Side Effects:
#	See above.
#
# Results:
#	None.

proc ModuleKnowledge::renameModule {module newName} {
    variable  modules
    variable  modarray
    variable  srcsubdirs
    variable  dependencies
    variable  depBack
    variable  subModules
    variable  derivModules
    variable  configFlags
    variable  testDirs
    variable  modVersion
    variable  modPlatform
    variable  topDirectory
    variable  parent

    # Move the basic information first. This will not fail if the module
    # does not exist.

    foreach var {
	srcsubdirs dependencies subModules derivModules configFlags
	testDirs modVersion modPlatform topDirectory parent depBack
    } {
	if {[info exists ${var}($module)]} {
	    set ${var}($newName) [set ${var}($module)]
	    unset ${var}($module)
	}
    }

    # Now go through the list of derived modules and change their
    # parent references. If they exist

    if {[info exists derivModules($module)]} {
	foreach d $derivModules($newName) {
	    set parent($d) $newName
	}
    }

    # Now go through the list of modules depending on this module and
    # change their dependency references too. (And the back references!)

    if {[info exists depBack($newName)]} {
	foreach m $depBack($newName) {
	    set dn [list $newName]
	    foreach d $dependencies($m) {
		if {[string compare $d $module] && [string compare $d $newName]} {
		    lappend dn $d
		}
	    }
	    set dependencies($m) $dn
	}
    }

    # Go through the list of modules I depend on and change their back
    # references to me.

    if {[info exists dependencies($newName)]} {
	foreach m $dependencies($newName) {
	    set dn [list $newName]
	    foreach d $depBack($m) {
		if {[string compare $d $module] && [string compare $d $newName]} {
		    lappend dn $d
		}
	    }
	    set depBack($m) $dn
	}
    }

    # At last change the global list of modules. Easy because of the
    # array representation. Only done for known modules.

    if {[info exists modarray($module)]} {
	unset modarray($module)
	set   modarray($newName) !
	set   modules [array names modarray]
    }
    return
}

# ModuleKnowledge::known --
#
#	Tests for existance of a module in the database. Looks for versioned
#	variants if the plain name was not found.
#
# Arguments:
#	m		The name of the module to look for.
#	variantVar	Optional. Name of a variable to store the matching name into.
#
# Side Effects:
#	If 'variantVar' is specified it will contain a string after a call
#	returning true. This string will be name of the first matching entry in
#	'mi'. This can be used by the caller to determine whether a versioned
#	variant had to be found.
#
# Results:
#	A boolean value. True signals that the module is known.

proc ModuleKnowledge::known {m {variantVar {}}} {
    variable modarray

    if {$variantVar != {}} {
	upvar $variantVar v
    } else {
	# Dummy variable
	set v !
    }

    if {[info exists modarray($m)]} {
	# Module is known under this name.
	set v $m
	return 1
    }

    # Plain name not found, look for versioned variants.
    if {[llength [set ll [array names modarray "${m}\[0-9\]*"]]] > 0} {
	set v [lindex $ll 0]
	return 1
    }

    # No luck, everything failed, module not known.
    return 0
}

# ModuleKnowledge::unresolvedDependencies --
#
#	Returns the list of unresolved dependencies.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	A list of module names.

proc ModuleKnowledge::unresolvedDependencies {} {
    variable unresolvedDependencies
    return  $unresolvedDependencies
}

# ModuleKnowledge::getBuildVariables --
#
#	Returns a list containing the names of all used build
#	variables. Actually the list is a serialized array with the
#	names as keys. The values are of no importance. The
#	representation was chosen to make the manipulation of the
#	information by higher levels easier. For example it is easy to
#	assign the list to an array and then extend into a mapping
#	from build-variables to the values they have to be substituted
#	with.
#
# Arguments:
#	None.
#
# Side Effects:
#	Populates an internal cache.
#
# Results:
#	A list.

proc ModuleKnowledge::getBuildVariables {} {
    variable buildVariables
    variable configFlags

    if {$buildVariables == {}} {
	# Create an array with all known build-variables as keys. Only
	# 'configFlags' has to be checked.
	array set tmp {}

	foreach key [array names configFlags] {
	    foreach {k v} $configFlags($key) {
		array set tmp [GetBuildVariables $v]
	    }
	}

	set buildVariables [array get tmp]
	unset     tmp
    }

    return $buildVariables
}

# ------------------------------------------------------------
# Internal commands from now on
# ------------------------------------------------------------

# ModuleKnowledge::Initialized? --
#
#	Checks that the system is initialized and throw an error if not.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ModuleKnowledge::Initialized? {} {
    variable knowledge
    if {$knowledge == {}} {
	return -code error "ModuleKnowledge not initialized"
    }
}

# ModuleKnowledge::AlreadyInitialized? --
#
#	Checks that the system is not initialized and throw an error if it is.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ModuleKnowledge::AlreadyInitialized? {} {
    variable knowledge
    if {$knowledge != {}} {
	return -code error "ModuleKnowledge already initialized"
    }
}

# ModuleKnowledge::ScanKnowledge --
#
#	Scans the provided knowledge directory and extracts the descriptive
#	information from the files in it.
#
# Arguments:
#	None.
#
# Side Effects:
#	Populates the internal database with module information.
#
# Results:
#	None.

proc ModuleKnowledge::ScanKnowledge {} {
    variable knowledge
    # Paranoia, guard against programming errors in caller
    # (setKnowledge), it has to set 'knowledge' *before* executing
    # this command.
    Initialized?

    # Get list of entries in the knowledge, weed out everything
    # which is clearly no module at all and process the rest.

    set hereIs [pwd]
    cd [file join [pwd] $knowledge]
    set entries [glob -nocomplain *]
    cd $hereIs

    foreach entry $entries {
	set fullentry [file join [pwd] $knowledge $entry]
	if {[file isdirectory $fullentry]} {
	    # Skip subdirectories. Only files count.
	    continue
	}

	log::logMsg "Processing $entry"
	if {![file readable $fullentry]} {
	    log::logMsg "- Warning: $entry is not readable, skipped"
	    continue
	}
	# Softlinks are possibly dangerous, warn the user.
	if {[file type $fullentry] == "link"} {
	    log::logMsg "- Warning: $entry is a soft-link, possibly trouble"
	}

	ProcessEntry $entry
    }
    return
}

# ModuleKnowledge::ConsolidateDependencies --
#
#	Goes through all declared modules and corrects the dependency information
#	in them, if possible. It also fills the backward mapping.
#
# Arguments:
#	None.
#
# Side Effects:
#	Modifies the internal database.
#
# Results:
#	None.

proc ModuleKnowledge::ConsolidateDependencies {} {
    variable dependencies
    variable depBack
    variable modules
    variable modarray
    variable unresolvedDependenciesxs

    # Go through all modules,
    #   then through their dependencies and look for the real names.
    #   Set the real names. Also fill the backward array as part of
    #   this operation

    foreach m $modules {
	set dep_orig $dependencies($m)
	set dep_new  [list]
	foreach d $dep_orig {
	    if {![known $d vd]} {
		# Unknown dependencies are retained, they are possibly
		# known to the knowledge. We also remember them in a
		# special list to allow higher levels to query for them
		set vd $d
		lappend unresolvedDependencies $vd
	    }
	    lappend dep_new $vd
	    lappend depBack($vd) $m
	}

	set dependencies($m) $dep_new
    }
}

# ModuleKnowledge::ProcessEntry --
#
#	Retrieves the module information in the specified file contained in the
#	knowledge directory.
#
# Arguments:
#	entry	Path of the file to scan, relative to the knowledge directory.
#
# Side Effects:
#	Populates the internal database with module information.
#
# Results:
#	None.

proc ModuleKnowledge::ProcessEntry {entry} {
    variable knowledge
    variable modInfo

    ClearModInfo
    set infoFile [file join [pwd] $knowledge $entry]

    # Readability of the file was already assured by the caller
    # (ScanKnowledge). Use a safe interpreter to interpret the
    # contents of the file.

    set script [read [set f [open $infoFile]]]
    close                $f

    set ip [interp create -safe]
    foreach {command -> alias} {
	ReadBuildInfo -> module 
    } {
	interp alias $ip $alias {} ModuleKnowledge::$command
    }

    interp eval   $ip $script
    interp delete $ip
    return
}

# ModuleKnowledge::ClearModInfo --
#
#	Remove all old information from the array holding the
#	information about the currently scanned module.
#
# Arguments:
#	None.
#
# Side Effects:
#	Clears the internal database of the scanner.
#
# Results:
#	None.

proc ModuleKnowledge::ClearModInfo {} {
    variable modInfo
    foreach item [array names modInfo] {
	unset modInfo($item)
    }
    return
}

# ModuleKnowledge::ReadBuildInfo --
#
#	Called when the current entry contains a BUILDINFO file.
#	Process the file and validates its contents.
#
# Arguments:
#	module	The name of the module described by the script.
#	script	The script describing the module.
#
# Side Effects:
#	Populates the internal database of the scanner.
#	Populates the internal database of the package.
#
# Results:
#	As of [ProcessEntry]

proc ModuleKnowledge::ReadBuildInfo {module script} {
    variable modInfo

    # Generate a safe interpreter, link the description commands into
    # it and let have it a go at the contents of BUILDINFO. But first
    # we have to read the file.

    set ip [interp create -safe]
    foreach {command   -> alias} {
	BITopDir       -> location
	BISrcSubDir    -> configure.loc
	BIDependencies -> depends.on
	BIDerivModule  -> derived
	BIConfigFlags  -> configure.with
	BITestsuite    -> testsuite
	BIVersion      -> version
	BIPlatform     -> platform
	BI_file        -> file
    } {
	interp alias $ip $alias {} ModuleKnowledge::$command
    }

    ClearModInfo
    # The top directory defaults to the name of the module.
    set modInfo(top)    $module
    set modInfo(dep)    [list]
    set modInfo(subm)   [list]
    set modInfo(deriv)  [list]
    set modInfo(test)   [list]
    set modInfo(vers)   ""
    set modInfo(plat)   ""
    set modInfo(module) $module

    interp eval   $ip $script
    interp delete $ip

    MoveInfoIntoDatabase $module
    return 1
}

# ModuleKnowledge::MoveInfoIntoDatabase --
#
#	Moves the information in the scanner database (modInfo) into
#	the global database.
#
# Arguments:
#	entry	The entry in the knowledge under consideration.
#
# Side Effects:
#	Populates the internal database of the package.
#
# Results:
#	None.

proc ModuleKnowledge::MoveInfoIntoDatabase {entry} {
    variable  modules
    variable  modarray
    variable  modInfo
    variable  srcsubdirs
    variable  dependencies
    variable  subModules
    variable  derivModules
    variable  configFlags
    variable  testDirs
    variable  modVersion
    variable  modPlatform
    variable  topDirectory
    variable  parent

    # SrcSubdir information, requires post processing.
    set sub [list]
    foreach key [array names modInfo srcDir,*] {
	set sfx [lindex [split $key ,] 1]
	lappend sub $sfx $modInfo($key)
    }
    set srcsubdirs($entry) $sub

    foreach {key var} {
	top    topDirectory
	dep    dependencies
	subm   subModules
	deriv  derivModules
	test   testDirs
	vers   modVersion
	plat   modPlatform
	parent parent
    } {
	if {[info exists modInfo($key)]} {
	    set ${var}($entry) $modInfo($key)
	}
    }

    set cfg [list]
    foreach key [array names modInfo cfg,*] {
	set sfx [lindex [split $key ,] 1]
	lappend cfg $sfx $modInfo($key)
    }
    if {[llength $cfg] > 0} {
	set configFlags($entry) $cfg
    }

    lappend modules  $entry
    set     modarray($entry) !
    return
}

# ModuleKnowledge::IsConfigureIn --
#
#	Helper command. Determines wether the file looked at by
#	fileutil::find is of interest to us (= a configure.in).
#
# Arguments:
#	file	The name of the file under scrutiny by fileutil::find
#
# Side Effects:
#	None.
#
# Results:
#	A boolean value. 0/False means the file is of no interest.

proc ModuleKnowledge::IsConfigureIn {file} {
    expr {![string compare [file tail $file] configure.in]}
}

# ModuleKnowledge::IsTestDir --
#
#	Helper command. Determines wether the file looked at by
#	fileutil::find is of interest to us (= 'tests').
#
# Arguments:
#	file	The name of the file under scrutiny by fileutil::find
#
# Side Effects:
#	None.
#
# Results:
#	A boolean value. 0/False means the file is of no interest.

proc ModuleKnowledge::IsTestDir {file} {
    expr {![string compare [file tail $file] tests]}
}

# ModuleKnowledge::BISrcSubDir --
#
#	Part of the description processor. Reads the declaration of paths
#	containing 'configure.in' files
#
# Arguments:
#	args	List of platform names and associated paths.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BISrcSubDir {args} {
    variable modInfo

    if {[llength $args] % 2 == 1} {
	# Illegal length, uneven
	return -code error "- configure.loc: #args not a multiple of 2"
    }

    # The configure.in paths can't be checked here.

    foreach {key path} $args {
	set modInfo(srcDir,$key) $path
    }
    return
}

# ModuleKnowledge::BIDependencies --
#
#	Part of the description processor. Reads the list of module
#	dependencies.
#
# Arguments:
#	args	List of module names
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BIDependencies {args} {
    variable modInfo

    if {([llength $args] == 1) && ("*clear*" == "[lindex $args 0]")} {
	# clear operation requested.
	set modInfo(dep) [list]
	return
    }

    foreach module $args {
	lappend modInfo(dep) $module
    }
    return
}

# ModuleKnowledge::BIDerivModule --
#
#	Part of the description processor. A derived module is declared,
#	together with its description.
#
# Arguments:
#	module		Name of the derived module.
#	description	Description of the derived module.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BIDerivModule {module description} {
    variable modInfo

    # Generate a safe interpreter, link the description commands into
    # it and let have it a go at the description we got. Differences
    # between this setup and the setup for normal modules:
    #
    # - Submodules are not allowed here.
    # - Nor are derivations of derived modules.
    # - The modInfo database is not cleared, but inherited.
    # - Version information cannot change, nor can the platform
    #   restrictions. But it might have different dependencies

    set ip [interp create -safe]
    foreach {command -> alias} {
	BISrcSubDir    -> configure.loc
	BIDependencies -> depends.on
	BIConfigFlags  -> configure.with
	BITestsuite    -> testsuite
	BI_file        -> file
    } {
	interp alias $ip $alias {} ModuleKnowledge::$command
    }

    set saved [array get modInfo]
    set parent $modInfo(module)

    # Don't clear, inherit (most) contents.
    set modInfo(top) $module

    interp eval   $ip $description
    interp delete $ip

    # Insert a back reference to the module this one is derived from.
    set modInfo(parent) $parent
    MoveInfoIntoDatabase $module

    # Clear and restore database contents for the caller.
    ClearModInfo
    array set modInfo $saved
    lappend  modInfo(deriv) $module
    return
}

# ModuleKnowledge::BIConfigFlags --
#
#	Part of the description processor. Reads the platform and flavor
#	dependent configuration options.
#
# Arguments:
#	args	List of keys and configuration options.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BIConfigFlags {args} {
    variable modInfo

    if {[llength $args] == 1} {
	if {[lindex $args 0] == "*clear*"} {
	    # Clearing of the configuration flags was requested.
	    foreach key [array names cfg,*] {
		unset modInfo($key)
	    }
	    return
	}
    }

    if {[llength $args] % 2 == 1} {
	# Illegal length, uneven
	return -code error "- configure.with: #args not a multiple of 2"
    }

    foreach {key options} $args {
	set options [string trim $options]
	regsub -all "\[ \t\n\]+" $options { } options
	set modInfo(cfg,$key) $options
    }
    return
}

# ModuleKnowledge::BITopDir --
#
#	Part of the description processor. Declares the toplevel path
#	of the module in relation to the workspace.
#
# Arguments:
#	path	The path.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BITopDir {path} {
    variable modInfo

    # Static knowledge, can't check the supplied paths.
    set modInfo(top) $path
    return
}

# ModuleKnowledge::BITestsuite --
#
#	Part of the description processor. Declares the paths to the testsuite
#	of the module.
#
# Arguments:
#	args	List of paths.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BITestsuite {args} {
    variable modInfo

    # Static knowledge, can't check the supplied paths.

    foreach path $args {
	lappend modInfo(test) $path
    }
    return
}

# ModuleKnowledge::BIVersion --
#
#	Part of the description processor. Declares the version of the module.
#
# Arguments:
#	version	The version number of the module.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BIVersion {version} {
    variable modInfo

    if {![regexp {[0-9]+[.][0-9]+([abp.][0-9]+)?} $version]} {
	log::logMsg "- Warning, syntax in error in proposed version $version"
	return
    }

    set modInfo(vers) $version
    return
}

# ModuleKnowledge::BIVersion --
#
#	Part of the description processor. Declares to which platforms the
#	module is restricted to.
#
# Arguments:
#	args	List of platform names
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleKnowledge::BIPlatform {args} {
    variable modInfo
    foreach platform $args {
	lappend modInfo(plat) $platform
    }
    return
}

# ModuleKnowledge::BI_file --
#
#	Part of the description processor. Implements [file join] for
#	the safe sub-interpreter.
#
# Arguments:
#	cmd	Has to be 'join'.
#	args	List of path components.
#
# Side Effects:
#	None.
#
# Results:
#	A string

proc ModuleKnowledge::BI_file {cmd args} {
    switch -exact -- $cmd {
	join    {return [eval file join $args]}
	default {}
    }
    return -code error "Illegal file operation '$cmd'"
}

# ModuleKnowledge::GetBuildVariables --
#
#	Extracts the build variables (%...%) from the string and
#	returns them as a serialized array with the variables as keys
#	and irrelevant values. This representation was chosen to make
#	the manipulation of the information by higher levels
#	easier. For example it is easy to assign the list to an array
#	and then extend into a mapping from build-variables to the
#	values they have to be substituted with. Another possibility
#	is easy merging of such information coming from different
#	sources.
#
# Arguments:
#	string	The string which is searches for build-variables.
#
# Side Effects:
#	None.
#
# Results:
#	A serialized array.


proc ModuleKnowledge::GetBuildVariables {string} {
    set res [list]

    while {[regexp -indices {^[^%]*%([^%]+)%} $string -> var]} {
	foreach {start end} $var break ; # lassign idiom

	lappend res [string range $string $start $end] !
	set string [string range $string [incr end 2] end]
    }

    return $res
}
