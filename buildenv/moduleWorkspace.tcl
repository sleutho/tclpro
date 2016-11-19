# moduleWorkspace.tcl
# -*- tcl -*-
#
#	This file implements functions to handle the workspace
#	of a build as a database of information about the modules
#	contained in the workspace.
#
# Copyright (c) 2001 by ActiveState Tool Corp.
# See the file license.terms.
#
# RCS: @(#) $Id: moduleWorkspace.tcl,v 1.1 2001/03/30 16:35:06 andreas_kupries Exp $

package require fileutil
package require log 1.0 ; # log facility from tcllib



package provide ModuleWorkspace 1.0
namespace eval  ModuleWorkspace {
    # No variables yet.
    namespace export 			\
	    setWorkspace		\
	    getWorkspace		\
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
	    processEntry		\
	    isDerived			\
	    getParent			\
	    renameModule		\
	    known			\
	    unresolvedDependencies	\
	    getBuildVariables

    # Path to the workspace currently in use. The initial value used
    # here means 'not initialized'.

    variable workspace {}

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
    # defined for all modules! Subdirectories of the workspace for
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
    # the workspace.

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

# ModuleWorkspace::setWorkspace --
#
#	Tells the package the location of the workspace used for the build.
#
# Arguments:
#	path	Path of the workspace directory. The command validates both
#		existence and accessibility (readability) of the path and
#		the modules inside it.
#
# Side Effects:
#	Initializes the package by scanning the workspace directory and
#	extracting information about and from the modules contained in
#	it.
#
# Results:
#	None.

proc ModuleWorkspace::setWorkspace {path} {
    variable workspace

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

    set workspace $path
    ScanWorkspace
    ConsolidateDependencies
    return
}

# ModuleWorkspace::getWorkspace --
#
#	Returns the path to the currently used workspace. Calling this command
#	without a preceding [setWorkspace] will result in an error (system not
#	initialized).
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	The path to the currently used workspace.

proc ModuleWorkspace::getWorkspace {} {
    variable workspace
    Initialized?
    return $workspace
}

# ModuleWorkspace::listModules --
#
#	Returns a list containing the names of the modules which were found in
#	the workspace. Calling this command without a preceding [setWorkspace]
#	will result in an error (system not initialized).
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	A list of strings.

proc ModuleWorkspace::listModules {} {
    variable modules
    Initialized?
    return $modules
}

# ModuleWorkspace::isModule --
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

proc ModuleWorkspace::isModule {module} {
    variable srcsubdirs
    Initialized?
    return [info exists srcsubdirs($module)]
}

# ModuleWorkspace::getDependencies --
#
#	Returns a list containing the names of the modules the specified module
#	is dependent upon. The system does not check wether the dependencies
#	actually exist in the workspace. Calling this command without a
#	preceding [setWorkspace] will result in an error (system not initialized).
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

proc ModuleWorkspace::getDependencies {module} {
    variable dependencies
    Initialized?
    if {[info exists dependencies($module)]} {
	return $dependencies($module)
    } else {
	return -code error "Unable to determine dependencies of $module"
    }
}

# ModuleWorkspace::getSrcDirectory --
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

proc ModuleWorkspace::getSrcDirectory {module} {
    variable srcsubdirs
    Initialized?
    return $srcsubdirs($module)
}

# ModuleWorkspace::getSubmodules --
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

proc ModuleWorkspace::getSubmodules {module} {
    variable subModules
    Initialized?
    if {[info exists subModules($module)]} {
	return $subModules($module)
    } else {
	return -code error "Unable to determine the subModules of $module"
    }
}

# ModuleWorkspace::getDerivedModules --
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

proc ModuleWorkspace::getDerivedModules {module} {
    variable derivModules
    Initialized?
    if {[info exists derivModules($module)]} {
	return $derivModules($module)
    } else {
	return -code error "Unable to determine the derived modules of $module"
    }
}

# ModuleWorkspace::getConfigurationFlags --
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

proc ModuleWorkspace::getConfigurationFlags {module} {
    variable configFlags
    Initialized?
    if {[info exists configFlags($module)]} {
	return $configFlags($module)
    } else {
	return -code error "Unable to determine the configuration flags of $module"
    }
}

# ModuleWorkspace::getTestDirectories --
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

proc ModuleWorkspace::getTestDirectories {module} {
    variable testDirs
    Initialized?
    if {[info exists testDirs($module)]} {
	return $testDirs($module)
    } else {
	return -code error "Unable to determine the testsuite of $module"
    }
}

# ModuleWorkspace::getVersion --
#
#	Returns the version of the specified module which was found when
#	scanning the workspace.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A string.

proc ModuleWorkspace::getVersion {module} {
    variable modVersion
    Initialized?
    if {[info exists modVersion($module)]} {
	return $modVersion($module)
    } else {
	return -code error "Unable to determine the version of $module"
    }
}

# ModuleWorkspace::getPlatforms --
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

proc ModuleWorkspace::getPlatforms {module} {
    variable modPlatform
    Initialized?
    if {[info exists modPlatform($module)]} {
	return $modPlatform($module)
    } else {
	return -code error "Unable to determine the platforms of $module"
    }
}

# ModuleWorkspace::getTopDir --
#
#	Returns the path of the toplevel directory for the specified
#	module, relative to the workspace.
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A path

proc ModuleWorkspace::getTopDir {module} {
    variable topDirectory
    Initialized?
    return $topDirectory($module)
}

# ModuleWorkspace::processEntry --
#
#	Scans the specified entry in the workspace for module information.
#	This procedure is used by the internal command [ScanWorkspace]
#	and can also be used from the outside to enter additional modules
#	not found by the scanner itself (see package [moduleList] for an
#	example).
#
# Arguments:
#	entry	Path of the possible module, relative to the workspace.
#	module	Name of the module.
#
# Side Effects:
#	Populates the internal database with module information.
#
# Results:
#	None.

proc ModuleWorkspace::processEntry {entry module} {
    variable workspace

    set fullentry [file join [pwd] $workspace $entry]
    if {![file isdirectory $fullentry]} {
	log::logMsg "- Warning: $entry is no directory, skipped"
	return
    }

    log::logMsg "Processing $entry"
    if {![file readable $fullentry]} {
	log::logMsg "- Warning: $entry is not readable, skipped"
	return
    }
    # Softlinks are possibly dangerous, warn the user.
    if {[file type $fullentry] == "link"} {
	log::logMsg "- Warning: $entry is a soft-link, possibly trouble"
    }

    if {![ProcessEntry $entry $module]} {
	log::logMsg "- Warning: $entry seems to be no module, skipped"
	return
    }

    return
}

# ModuleWorkspace::isDerived --
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

proc ModuleWorkspace::isDerived {module} {
    variable parent
    return [info exists parent($module)]
}

# ModuleWorkspace::getParent --
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

proc ModuleWorkspace::getParent {module} {
    variable parent
    return $parent($module)
}

# ModuleWorkspace::renameModule --
#
#	Renames the specified module, allowed only if does *not* exist.
#	This command is just here to adjust dependency information.
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

proc ModuleWorkspace::renameModule {module newName} {
    variable  modules
    variable  modarray
    variable  dependencies
    variable  depBack

    if {[info exists modarray($module)]} {
	return -code error "Can't rename existing module"
    }

    # Go through the list of modules depending on the renamed
    # module and change their dependency references.

    if {[info exists depBack($module)]} {
	foreach m $depBack($module) {
	    set dn [list $newName]
	    foreach d $dependencies($m) {
		if {[string compare $d $module] && [string compare $d $newName]} {
		    lappend dn $d
		}
	    }
	    set dependencies($m) $dn
	}

	set db $depBack($module)
	unset   depBack($module)
	set     depBack($newName) $db
    }

    # Go through the list of modules I depend on and change their back
    # references to me.

    if {[info exists dependencies($module)]} {
	foreach m $dependencies($module) {
	    set dn [list $newName]
	    foreach d $depBack($m) {
		if {[string compare $d $module] && [string compare $d $newName]} {
		    lappend dn $d
		}
	    }
	    set depBack($m) $dn
	}

	set db $dependencies($module)
	unset   dependencies($module)
	set     dependencies($newName) $db
    }

    return
}

# ModuleWorkspace::known --
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

proc ModuleWorkspace::known {m {variantVar {}}} {
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

# ModuleWorkspace::unresolvedDependencies --
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

proc ModuleWorkspace::unresolvedDependencies {} {
    variable unresolvedDependencies
    return  $unresolvedDependencies
}

# ModuleWorkspace::getBuildVariables --
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

proc ModuleWorkspace::getBuildVariables {} {
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

# ModuleWorkspace::Initialized? --
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

proc ModuleWorkspace::Initialized? {} {
    variable workspace
    if {$workspace == {}} {
	return -code error "ModuleWorkspace not initialized"
    }
}

# ModuleWorkspace::AlreadyInitialized? --
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

proc ModuleWorkspace::AlreadyInitialized? {} {
    variable workspace
    if {$workspace != {}} {
	return -code error "ModuleWorkspace already initialized"
    }
}

# ModuleWorkspace::ScanWorkspace --
#
#	Scans the provided workspace for modules and extracts the descriptive
#	information from them.
#
# Arguments:
#	None.
#
# Side Effects:
#	Populates the internal database with module information.
#
# Results:
#	None.

proc ModuleWorkspace::ScanWorkspace {} {
    variable workspace
    # Paranoia, guard against programming errors in caller
    # (setWorkspace), it has to set 'workspace' *before* executing
    # this command.
    Initialized?

    # Get list of entries in the workspace, weed out everything
    # which is clearly no module at all and process the rest.

    set hereIs [pwd]
    cd [file join [pwd] $workspace]
    set entries [glob -nocomplain *]
    cd $hereIs

    foreach entry $entries {
	processEntry $entry $entry
    }
    return
}

# ModuleWorkspace::ConsolidateDependencies --
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

proc ModuleWorkspace::ConsolidateDependencies {} {
    variable dependencies
    variable depBack
    variable modules
    variable modarray
    variable unresolvedDependencies

    # Go through all modules,
    #   then through their dependencies and look for the real names.
    #   Set the real names. Also fill the backward array as part of
    #   this operation

    foreach m $modules {
	if {![info exists dependencies($m)]} {
	    # Ignore modules for which we have no dependeny information.
	    continue
	}

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

# ModuleWorkspace::ProcessEntry --
#
#	Scans the specified entry in the workspace for module information.
#
# Arguments:
#	entry	Path of the possible module, relative to the workspace.
#	module	Name of the module.
#
# Side Effects:
#	Populates the internal database with module information.
#
# Results:
#	A boolean value. False is returned if the entry is deemed to be no
#	module at all.

proc ModuleWorkspace::ProcessEntry {entry module} {
    variable workspace
    variable modInfo

    ClearModInfo

    set modInfo(topDir) [set top [file join [pwd] $workspace $entry]]
    set modInfo(relTop) $entry
    set modInfo(entry)  $entry
    set modInfo(module) $module
    set buildinfo [file join $top BUILDINFO]

    if {
	![file exists   $buildinfo] ||
	![file readable $buildinfo]
    } {
	# BUILDINFO either does not exist or is not usable.
	if {
	     [file exists   $buildinfo] &&
	    ![file readable $buildinfo]
	} {
	    log::logMsg "- Warning: BUILDINFO exists, but was not readable."
	}

	log::logMsg "- Gathering as much as possible indirectly."
	return [GatherIndirectInformation $entry]
    }

    # We have a BUILDINFO file. This declares everything we need to
    # know.

    return [ReadBuildInfo $entry $buildinfo]
}

# ModuleWorkspace::ClearModInfo --
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

proc ModuleWorkspace::ClearModInfo {} {
    variable modInfo
    foreach item [array names modInfo] {
	unset modInfo($item)
    }
    return
}

# ModuleWorkspace::GatherIndirectInformation --
#
#	Called when the current entry does not contain a BUILDINFO
#	file. Tries to gather as much information from the directory
#	itself. Assumes a fairly "standard" module without oddities.
#
# Arguments:
#	entry	The entry in the workspace under consideration.
#
# Side Effects:
#	Populates the internal database of the scanner.
#	Populates the internal database of the package.
#
# Results:
#	As of [ProcessEntry]

proc ModuleWorkspace::GatherIndirectInformation {entry} {
    variable modInfo

    #  4 SrcSubdir		- Search for configure.in
    #				  If nothing was found => Entry is no module!
    #  5 Dependencies		- Try file DEPENDENCIES, else undetermined
    #  6 Submodules		- undetermined
    #  7 Derived modules	- undetermined
    #  8 Configuration Flags	- undetermined
    #  9 Testsuite directories	- Try some directories, else undetermined
    # 10 Version information	- undetermined
    # 11 Platform availability	- undetermined

    if {![FindSrcDirectory $entry]} {
	# No usable directory found, this is not an operable
	# module. Skip the rest of the matter, don't change the
	# database we are building.
	return 0
    }

    FindDependencies     $entry
    FindTestDirectories  $entry
    MoveInfoIntoDatabase $modInfo(module)
    return 1
}

# ModuleWorkspace::::FindSrcDirectory --
#
#	Searches for a directory containing a configure.in
#
# Arguments:
#	entry	The entry under considration.
#
# Side Effects:
#	Populates 'modInfo', keys 'srcDir' and 'srcDir,win32-ix86'.
#
# Results:
#	As of [ProcessEntry]

proc ModuleWorkspace::FindSrcDirectory {entry} {
    variable modInfo
    set top $modInfo(topDir)

    # We have to find the directory containing the configure.in
    # required by the framework.

    # Heuristics: Check toplevel directory first. If the configure.in
    # is here, assume a TEA-based extension. Don't check for
    # platform-dependent configure.in's anymore.
    #
    # Else look for subdirectories tea, unix and win.
    #
    # tea => Basically TEA compatible extension, but not quite (like
    # memchan, ...). Handle as before.
    #
    # unix, win => Make the first one the general information and set
    # the second one as a platform-dependent overide.
    #
    # At last try to find a configure.in anywhere.
    #
    # If nothing can be found query the knowledge base. Give up and
    # signal failure afterward.

    if {[file exists [file join $top configure.in]]} {
	set modInfo(srcDir,) .
	return 1
    }
    if {[file exists [file join $top tea configure.in]]} {
	set modInfo(srcDir,) tea
	return 1
    }
    if {[file exists [file join $top unix configure.in]]} {
	set modInfo(srcDir,) unix

	if {[file exists [file join $top win configure.in]]} {
	    set modInfo(srcDir,win32-ix86) win
	}
	return 1
    }

    set files [::fileutil::find $top ModuleWorkspace::IsConfigureIn]

    if {[llength $files] > 1} {
	# Multiple configure.in files found. Ambiguous. Take the first
	# and warn the user.

	set path [file dirname [lindex $files 0]]

	# The next operation deserves some explanation. We have an
	# absolute 'path' below an equally absolute 'top' directory
	# and now want to make this path relative to the 'top'
	# directory. So, we compute the number of components in top
	# and pop that many components from the beginning of
	# 'path'. To do this 'top' has to be a list and 'path' as well
	# for a short time. Phew. And portable too :)

	set path [file join [lrange [file split $path] [llength [file split $top]] end]]

	set modInfo(srcDir) $path

	log::logMsg "- Warning: Multiple configure.in files found"
	log::logMsg "         : Using the first one ([file join $path configure.in])."
	return 1

    } elseif {[llength $files] == 1} {
	# Exactly one file found, determine its path relative to the
	# toplevel directory.

	set path [file dirname [lindex $files 0]]

	# See explanation above.
	set path [file join [lrange [file split $path] [llength [file split $top]] end]]

	set modInfo(srcDir) $path
	return 1
    }

    # Nothing found, signal that this entry is not a module usable by
    # the build framework.
    return 0
}

# ModuleWorkspace::FindDependencies --
#
#	Searches for dependency information concerning the
#	specified module.
#
# Arguments:
#	entry	The entry under considration.
#
# Side Effects:
#	Populates 'modInfo', key 'dep'.
#
# Results:
#	None.

proc ModuleWorkspace::FindDependencies {entry} {
    variable modInfo
    set top $modInfo(topDir)

    # First tries to get the dependency information directly from
    # the module. Only if that fails it will ask the global module
    # knowledgebase for this information.
    #
    # Back to the module itself: 
    # The code expects that the dependency information is stored in
    # a file called DEPENDENCIES (in the toplevel directory), one
    # module per line. Empty lines and comment lines (specified as
    # for Tcl) are ignored. Module names may contain version
    # information. In that case the current module depends on that
    # exact version of the named module.
    #
    # *future* : Expand upon this to include conflict-information as
    #          : well, also allow versions comparisons (>=, <=).

    set dfile [file join $top DEPENDENCIES]

    if {[file exists $dfile]} {
	if {[file readable $dfile]} {
	    log::logMsg "- Using DEPENDENCIES."

	    set f [open $dfile r]
	    set depList [list]
	    while {![eof $f]} {
		gets $f line
		set line [string trim $line]
		if {
		    ![eof $f] &&
		    ([string length $line] > 0) &&
		    ![string equal [string index $line 0] "#"]
		} {
		    lappend depList $line
		}
	    }
	    close $f

	    set modInfo(dep) $depList
	    return
	} else {
	    log::logMsg "- Warning: $dfile exists but is not readable."
	}
    }

    # Nothing to enter into the scanner database.
    return
}

# ModuleWorkspace::FindTestDirectories --
#
#	Searches for the directories containing the testsuite of
#	the module.
#
# Arguments:
#	entry	The entry under considration.
#
# Side Effects:
#	Populates 'modInfo', key 'test'.
#
# Results:
#	None.

proc ModuleWorkspace::FindTestDirectories {entry} {

    # Find all sub directories of name 'tests' and assume that they
    # contain the testsuite.

    variable modInfo
    set top $modInfo(topDir)

    set testdirs [::fileutil::find $top ModuleWorkspace::IsTestDir]

    if {[llength $testdirs] > 0} {

	# Go through the list of directories and check their
	# validity. Delete unaccessible directories and warn the
	# users. Also warn the user if no directory could be validated.

	set tList [list]
	foreach dir $testdirs {
	    if {![file isdirectory $dir]} {
		log::logMsg "- Warning: Testsuite directory $d is no directory"
		continue
	    }
	    if {![file readable $dir]} {
		log::logMsg "- Warning: Testsuite directory $d not readable"
		continue
	    }

	    # Convert the absolute path into directory relative to the
	    # toplevel directory.

	    regsub "^$top" $dir {} dir
	    set dir [string trimleft $dir /]
	    lappend tList $dir
	}

	if {[llength $tList] > 0} {
	    set modInfo(test) $tList
	} else {
	    log::logMsg "- Warning: No testsuite available"
	}
    }
    return
}

# ModuleWorkspace::ReadBuildInfo --
#
#	Called when the current entry contains a BUILDINFO file.
#	Process the file and validates its contents.
#
# Arguments:
#	entry	The entry in the workspace under consideration.
#
# Side Effects:
#	Populates the internal database of the scanner.
#	Populates the internal database of the package.
#
# Results:
#	As of [ProcessEntry]

proc ModuleWorkspace::ReadBuildInfo {entry buildinfo} {
    variable modInfo
    set top $modInfo(topDir)

    # Generate a safe interpreter, link the description commands into
    # it and let have it a go at the contents of BUILDINFO. But first
    # we have to read the file.

    set script [read [set f [open $buildinfo]]]
    close                $f

    set ip [interp create -safe]
    foreach {command -> alias} {
	BISrcSubDir    -> configure.loc
	BIDependencies -> depends.on
	BISubModule    -> subModule
	BIDerivModule  -> derived
	BIConfigFlags  -> configure.with
	BITestsuite    -> testsuite
	BIVersion      -> version
	BIPlatform     -> platform
	BISquash       -> squash-this
	BI_file        -> file
    } {
	interp alias $ip $alias {} ModuleWorkspace::$command
    }

    set modInfo(dep)   [list]
    set modInfo(subm)  [list]
    set modInfo(deriv) [list]
    set modInfo(test)  [list]
    set modInfo(vers)  ""
    set modInfo(plat)  ""

    interp eval   $ip $script
    interp delete $ip

    MoveInfoIntoDatabase $modInfo(module)
    return 1
}

# ModuleWorkspace::MoveInfoIntoDatabase --
#
#	Moves the information in the scanner database (modInfo) into
#	the global database. Ignores squashed data.
#
# Arguments:
#	entry	The entry in the workspace under consideration.
#
# Side Effects:
#	Populates the internal database of the package.
#
# Results:
#	None.

proc ModuleWorkspace::MoveInfoIntoDatabase {entry} {
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

    if {[info exists modInfo(squashed)]} {
	# Ignore squashed information
	return
    }

    # SrcSubdir information, requires post processing.
    set sub [list]
    foreach key [array names modInfo srcDir,*] {
	set sfx [lindex [split $key ,] 1]
	lappend sub $sfx $modInfo($key)
    }
    set srcsubdirs($entry) $sub

    foreach {key var} {
	dep    dependencies
	subm   subModules
	deriv  derivModules
	test   testDirs
	vers   modVersion
	plat   modPlatform
	relTop topDirectory
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

# ModuleWorkspace::IsConfigureIn --
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

proc ModuleWorkspace::IsConfigureIn {file} {
    expr {![string compare [file tail $file] configure.in]}
}

# ModuleWorkspace::IsTestDir --
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

proc ModuleWorkspace::IsTestDir {file} {
    expr {![string compare [file tail $file] tests]}
}

# ModuleWorkspace::BISrcSubDir --
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

proc ModuleWorkspace::BISrcSubDir {args} {
    variable modInfo

    if {[llength $args] % 2 == 1} {
	# Illegal length, uneven
	return -code error "- configure.loc: #args not a multiple of 2"
    }

    set top $modInfo(topDir)

    foreach {key path} $args {
	set p [file join $top $path]
	if {![file exists $p]} {
	    log::logMsg "- Warning: $path does not exist"
	    continue
	}
	if {![file readable $p]} {
	    log::logMsg "- Warning: $path is not readable"
	    continue
	}
	set cin [file join $p configure.in]
	if {![file exists $cin]} {
	    log::logMsg "- Warning: $path: configure.in does not exist"
	    continue
	}
	if {![file readable $cin]} {
	    log::logMsg "- Warning: $path: configure.in is not readable"
	    continue
	}

	set modInfo(srcDir,$key) $path
    }
    return
}

# ModuleWorkspace::BIDependencies --
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

proc ModuleWorkspace::BIDependencies {args} {
    variable modInfo
    foreach module $args {
	lappend modInfo(dep) $module
    }
    return
}

# ModuleWorkspace::BISubModule --
#
#	Part of the description processor. A submodule is declared, together
#	with its path inside the current module.
#
# Arguments:
#	module	Name of the sub module.
#	path	Path to the sub module.
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleWorkspace::BISubModule {module path} {
    variable modInfo

    set top   $modInfo(topDir)
    set entry $modInfo(entry)

    set p [file join $top $path]

    if {![file isdirectory $p]} {
	log::logMsg "- Warning: Submodule $module: $p is no directory, skipped"
	return
    }
    if {![file readable $p]} {
	log::logMsg "- Warning: Submodule $module: $p is not readable, skipped"
	return
    }
    # Softlinks are possibly dangerous, warn the user.
    if {[file type $p] == "link"} {
	log::logMsg "- Warning: Submodule $module: $p is a soft-link, possibly trouble"
    }

    # Now process the submodule as a new module. We have to save and
    # restore the scanner database to avoid confusion and mixtures.
    # Clearing for the new module is done inside the processor.
    
    set entry [file join $entry $path]
    set saved [array get modInfo]

    if {![ProcessEntry $entry $module]} {
	log::logMsg "- Warning: $entry seems to be no module"
	ClearModInfo
	array set modInfo $saved
	return
    }

    ClearModInfo
    array set modInfo $saved
    lappend  modInfo(subm) $module
    return
}

# ModuleWorkspace::BIDerivModule --
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

proc ModuleWorkspace::BIDerivModule {module description} {
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
    foreach {command   -> alias} {
	BISrcSubDir    -> configure.loc
	BIDependencies -> depends.on
	BIConfigFlags  -> configure.with
	BITestsuite    -> testsuite
	BI_file        -> file
    } {
	interp alias $ip $alias {} ModuleWorkspace::$command
    }

    set saved [array get modInfo]
    set parent $modInfo(module)
    # Don't clear, inherit contents.

    interp eval   $ip $description
    interp delete $ip

    # Insert a back reference to the module this one is derived from.
    set modInfo(parent) $parent
    MoveInfoIntoDatabase $module

    # Clear and restore database contents for the caller.
    ClearModInfo
    array set modInfo $saved
    lappend   modInfo(deriv) $module
    return
}

# ModuleWorkspace::BIConfigFlags --
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

proc ModuleWorkspace::BIConfigFlags {args} {
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

# ModuleWorkspace::BITestsuite --
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

proc ModuleWorkspace::BITestsuite {args} {
    variable modInfo
    set top $modInfo(topDir)

    foreach path $args {
	set p [file join $top $path]
	if {![file exists $p]} {
	    log::logMsg "- Warning, testsuite: $path does not exist"
	    continue
	}
	if {![file readable $p]} {
	    log::logMsg "- Warning, testsuite: $path is not readable"
	    continue
	}
	lappend modInfo(test) $path
    }
    return
}

# ModuleWorkspace::BIVersion --
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

proc ModuleWorkspace::BIVersion {version} {
    variable modInfo

    if {![regexp {[0-9]+[.][0-9]+([abp.][0-9]+)?} $version]} {
	log::logMsg "- Warning, syntax in error in proposed version $version"
	return
    }

    set modInfo(vers) $version
    return
}

# ModuleWorkspace::BIVersion --
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

proc ModuleWorkspace::BIPlatform {args} {
    variable modInfo
    foreach platform $args {
	lappend modInfo(plat) $platform
    }
    return
}

# ModuleWorkspace::BISquash --
#
#	Part of the description processor. Called by descriptions to declare
#	that the module is actually no such, but just a container for
#	submodules.
#
# Arguments:
#	args	List of platform names
#
# Side Effects:
#	Populates the internal database
#
# Results:
#	None.

proc ModuleWorkspace::BISquash {} {
    variable modInfo
    set modInfo(squashed) !
    return
}

# ModuleWorkspace::BI_file --
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

proc ModuleWorkspace::BI_file {cmd args} {
    switch -exact -- $cmd {
	join    {return [eval file join $args]}
	default {}
    }
    return -code error "Illegal file operation '$cmd'"
}

# ModuleWorkspace::GetBuildVariables --
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


proc ModuleWorkspace::GetBuildVariables {string} {
    set res [list]

    while {[regexp -indices {^[^%]*%([^%]+)%} $string -> var]} {
	foreach {start end} $var break ; # lassign idiom

	lappend res [string range $string $start $end] !
	set string [string range $string [incr end 2] end]
    }

    return $res
}
