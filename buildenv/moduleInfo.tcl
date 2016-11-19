# moduleInfo.tcl
# -*- tcl -*-
#
#	This file implements functionality which compares workspace and
#	knowledge databases and unifies them with respect to modulenames.
#	It additionally unifies the list of modules from both databases,
#	possibly dicovering more modules in the process.
#
# Copyright (c) 2001 by ActiveState Tool Corp.
# See the file license.terms.
#
# RCS: @(#) $Id: moduleInfo.tcl,v 1.1 2001/03/30 16:35:06 andreas_kupries Exp $

package require ModuleKnowledge 1.0
package require ModuleWorkspace 1.0
package require log ; # log facility from tcllib


package provide ModuleInfo 1.0
namespace eval  ModuleInfo {
    # No variables yet.
    namespace export 			\
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
	    getBuildVariables		\
	    isDerived			\
	    known

    # List of all modules, generated out of the list of modules found
    # in workspace and knowledge databases. This variable is a cache
    # and will be used if it is already initialized.

    variable modules     {}
    variable initialized 0

    # Boolean flag. Set to true when both databases were consolidated
    # with respect to module names.

    variable consolidatedNames 0

    # List of build-variables used by all configuration flags in all
    # known modules. Provided to higher level modules to allow them
    # checks that all build-variables have proper values.

    variable buildVariables {}
}

# ModuleInfo::listModules --
#
#	Returns a list containing the names of the found modules.
#
# Arguments:
#	None.
#
# Side Effects:
#	May add more modules to the workspace database.
#	May rename modules in the knowledge database.
#	May reparent modules in the knowledge database.
#
# Results:
#	A list of strings.

proc ModuleInfo::listModules {} {
    variable modules
    variable initialized

    # The namespace variable is a cache. If it is set use it.

    if {$initialized} {
	return $modules
    }

    Consolidation
    set initialized 1
    return $modules
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

proc ModuleInfo::getDependencies {module} {
    Consolidation

    if {[catch {set d [ModuleWorkspace::getDependencies $module]}]} {
	if {[catch {set d [ModuleKnowledge::getDependencies $module]}]} {
	    return -code error "Unable to determine dependencies of $module"
	}
    }

    return $d
}

# ModuleInfo::getSrcDirectory --
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

proc ModuleInfo::getSrcDirectory {module} {
    Consolidation

    if {[catch {set src [ModuleWorkspace::getSrcDirectory $module]}]} {
	if {[catch {set src [ModuleKnowledge::getSrcDirectory $module]}]} {
	    return -code error "Unable to determine source directory of $module"
	}
    }

    return $src
}

# ModuleInfo::getSubmodules --
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

proc ModuleInfo::getSubmodules {module} {
    Consolidation

    if {[catch {set sub [ModuleWorkspace::getSubmodules $module]}]} {
	if {[catch {set sub [ModuleKnowledge::getSubmodules $module]}]} {
	    return -code error "Unable to determine the subModules of $module"
	}
    }

    return $sub
}

# ModuleInfo::getDerivedModules --
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

proc ModuleInfo::getDerivedModules {module} {
    Consolidation

    if {[catch {set derived [ModuleWorkspace::getDerivedModules $module]}]} {
	if {[catch {set derived [ModuleKnowledge::getDerivedModules $module]}]} {
	    return -code error "Unable to determine the derived modules of $module"
	}
    }

    return $derived
}

# ModuleInfo::getConfigurationFlags --
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

proc ModuleInfo::getConfigurationFlags {module} {
    Consolidation

    if {[catch {set cfg [ModuleWorkspace::getConfigurationFlags $module]}]} {
	if {[catch {set cfg [ModuleKnowledge::getConfigurationFlags $module]}]} {
	    return -code error "Unable to determine the configuration flags of $module"
	}
    }

    return $cfg
}

# ModuleInfo::getTestDirectories --
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

proc ModuleInfo::getTestDirectories {module} {
    Consolidation

    if {[catch {set testdirs [ModuleWorkspace::getTestDirectories $module]}]} {
	if {[catch {set testdirs [ModuleKnowledge::getTestDirectories $module]}]} {
	    return -code error "Unable to determine the testsuite of $module"
	}
    }

    return $testdirs
}

# ModuleInfo::getVersion --
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

proc ModuleInfo::getVersion {module} {
    Consolidation

    if {[catch {set version [ModuleWorkspace::getVersion $module]}]} {
	if {[catch {set version [ModuleKnowledge::getVersion $module]}]} {
	    return -code error "Unable to determine the version of $module"
	}
    }

    return $version
}

# ModuleInfo::getPlatforms --
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

proc ModuleInfo::getPlatforms {module} {
    Consolidation

    if {[catch {set platforms [ModuleWorkspace::getPlatforms $module]}]} {
	if {[catch {set platforms [ModuleKnowledge::getPlatforms $module]}]} {
	    return -code error "Unable to determine the platforms of $module"
	}
    }

    return $platforms
}

# ModuleInfo::getTopDir --
#
#	Returns the path of the toplevel directory for the specified
#	module, relative to the workspace (or build directory!)
#
# Arguments:
#	module	The name of the module which is queried
#
# Side Effects:
#	None.
#
# Results:
#	A path

proc ModuleInfo::getTopDir {module} {
    Consolidation

    # The top directory (sources!) of derived modules is the same as
    # their parent module, independent of what is actually stored in
    # the databases for the module itself.

    set actualModule $module

    if {[ModuleWorkspace::isDerived $module]} {
	set module [ModuleWorkspace::getParent $module]
    } elseif {[ModuleKnowledge::isDerived $module]} {
	set module [ModuleKnowledge::getParent $module]
    }

    if {[catch {set top [ModuleWorkspace::getTopDir $module]}]} {
	if {[catch {set top [ModuleKnowledge::getTopDir $module]}]} {
	    return -code error "Unable to determine the top directory of $actualModule"
	}
    }

    return $top
}

# ModuleInfo::getBuildVariables --
#
#	Returns a list containing the names of all used build
#	variables. Actually the list is a serialized array with the
#	names as keys. The values are of no importance. This
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
#	A serialized array.

proc ModuleInfo::getBuildVariables {} {
    variable buildVariables

    if {$buildVariables == {}} {
	array set tmp [ModuleWorkspace::getBuildVariables]
	array set tmp [ModuleKnowledge::getBuildVariables]
	set buildVariables [array get tmp]
	unset     tmp
    }

    return $buildVariables
}

# ModuleInfo::isDerived --
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

proc ModuleInfo::isDerived {module} {
    if {[ModuleWorkspace::isModule $module]} {
	return [ModuleWorkspace::isDerived $module]
    } else {
	return [ModuleKnowledge::isDerived $module]
    }
}

# ModuleInfo::known --
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

proc ModuleInfo::known {m {variantVar {}}} {
    if {$variantVar != {}} {
	upvar $variantVar v
    } else {
	# Dummy variable
	set v !
    }

    if {![ModuleWorkspace::known $m v]} {
	return [ModuleKnowledge::known $m v]
    }
    return 1
}

# ------------------------------------------------------------
# Internal commands from now on
# ------------------------------------------------------------

proc ModuleInfo::Consolidation {} {
    variable consolidatedNames

    if {$consolidatedNames} {
	return
    }

    # Phases of consolidation:
    #
    # I.   Iterate through the list of modules known to the
    #      knowledge. If they are known to the workspace their names are
    #      made matching (ModuleKnowledge::renameModule). Unknown
    #      modules are given to the workspace for further lookup using
    #      the location information from the knowledge.
    #
    # II.  After phase I the max. amount of real modules is known. It
    #      is now possible to go through the derived modules in the
    #      knowledge and try to find their parents in the workspace.
    #      Here we create the unified list of modules as well.
    #
    # III. After phase II. the max. amount of all modules is known. We
    #      can now go through the unresolved dependencies in both
    #      databases and try to find them again.

    QuestForMoreModules
    AttachLocateDerived
    ResolveMoreDependencies

    set consolidatedNames 1
    return
}


proc ModuleInfo::QuestForMoreModules {} {
    variable modules

    # Merge the information from [moduleWorkspace] and
    # [moduleKnowledge]. The most interesting thing here is that we
    # can use the information from [moduleKnowledge] about modules and
    # their locations to detect more modules in the worksapce than the
    # scanner did alone. Due to the fact that the scanner checks only
    # the first level of directories in the workspace and is thus
    # unable to find embedded modules without the help of BUILDINFO
    # files. Here the static database can point us to more locations.

    set ws [file join [pwd] [ModuleWorkspace::getWorkspace]]

    foreach m [ModuleKnowledge::listModules] {
	if {![string compare $m "**standard**"]} {
	    # Ignore fake module for standard switches.
	    continue
	}

	log::logMsg "Checking up on $m ____________________________"

	if {[ModuleWorkspace::known $m vm]} {
	    # If a variant of m was found in the workspace then rename
	    # the entry in the knowledge.

	    if {[string compare $m $vm]} {
		log::logMsg "- Renaming $m to $vm"
		ModuleKnowledge::renameModule $m $vm
	    }
	    continue
	}

	# From now on we have to distinguish between normal and
	# derived modules.

	if {[ModuleKnowledge::isDerived $m]} {
	    # Skip derived modules for now, we have to make sure about
	    # their parents first.
	    log::logMsg "- Skip derived."
	    continue
	}

	# Now, for normal modules we try to get a location from
	# the knowledge, and if that succeeds ask the workspace to
	# check either that location or the versioned variants of
	# it.

	if {[catch {set entry [ModuleKnowledge::getTopDir $m]}]} {
	    # Module is not known and the knowledge has no location
	    # for it. Skip it as we can do nothing. Sorry.
	    log::logMsg "- Not known, no location either."
	    continue
	}

	# Now we have a module which is known to the knowledge, but
	# not to the workspace, and the knowledge has a possible
	# location. Check this location and ask the workspace! to
	# scan it (So that that we get the prefered information).

	log::logMsg "- Possible new module: $m @ $entry"

	# The [processEntry] command checks for the existence of the
	# path, but we do it here as well, so that we are able to try
	# some variations of the proposed location (basically we try
	# to find a versioned variant if we can't find the unadorned
	# directory).

	set fentry [file join $ws $entry]

	if {![file exists $fentry] || ![file isdirectory $fentry]} {
	    set dir [file dirname $fentry]

	    if {[file exists $dir] && [file isdirectory $dir]} {
		set here [pwd]
		cd $dir
		set candidates [glob -nocomplain "[file tail $entry]\[0-9\]*"]
		cd $here

		foreach c [lsort -dict $candidates] {
		    log::logMsg "- Using $c for $m (instead of $entry)"		    

		    # Check that the versioned candidate is not known either as a module!
		    if {[ModuleWorkspace::known [file tail $c]]} {
			# Module is known, nothing to do.
			log::logMsg "- Known"
			continue
		    }

		    set entryv [file join [file dirname $entry] $c]
		    ModuleWorkspace::processEntry $entryv $m
		}
	    }
	} else {
	    ModuleWorkspace::processEntry $entry $m
	}
    }

    # Now the workspace is scanned as fully as was possible with the
    # information we have.

    set modules [ModuleWorkspace::listModules]
}


proc ModuleInfo::AttachLocateDerived {} {
    variable modules

    log::logMsg "Checking up on the derived modules ___________"

    foreach m [ModuleKnowledge::listModules] {
	if {![ModuleKnowledge::isDerived $m]} {
	    continue
	}
	log::logMsg "=== $m ======================"

	# Cases for a derived module X.
	#
	# a) X is already known                => Nothing to do.
	# b) Neither X nor its parent is known => Nothing to do, without the parent
	#                                         the derivation is nothing.
	# c) X is not known, but its parent    => The parent obviously didn't declare
	#                                         the derived module. Add the module
	#                                         now to the list.

	if {[ModuleWorkspace::known $m]} {
	    # (a)
	    log::logMsg "  Derived known: Skip"
	    continue
	}
	set p [ModuleKnowledge::getParent $m]
	if {![ModuleWorkspace::known $p vp]} {
	    # (b)
	    log::logMsg "  Neither derived nor parent known: Skip"
	    continue
	}
	# (c)
	log::logMsg "  Derived not known, but parent ($p): Add"
	lappend modules $m

	# Check for differences between official parent and matching
	# entry. If there are some reroute the derived module to the
	# real name. This makes it for other (higher) modules easier
	# to match the information in the workspace with the knowledge
	# and vice versa.

	if {[string compare $p $vp]} {
	    log::logMsg "- Changing parent of $m to $vp"
	    ModuleKnowledge::setParent $m $vp
	}
    }
}


proc ModuleInfo::ResolveMoreDependencies {} {

    # Go through the lists of unresolved dependencies for workspace
    # and knowledge and try to resolve them again, now that more
    # modules can be known.

    foreach m [ModuleKnowledge::unresolvedDependencies] {
	if {[ModuleKnowledge::known $m vm]} {
	    if {[string compare $m $vm]} {
		ModuleKnowledge::renameModule $m $vm
	    }
	    continue
	}
	if {[ModuleWorkspace::known $m vm]} {
	    if {[string compare $m $vm]} {
		ModuleKnowledge::renameModule $m $vm
	    }
	    continue
	}
    }

    foreach m [ModuleWorkspace::unresolvedDependencies] {
	if {[ModuleWorkspace::known $m vm]} {
	    if {[string compare $m $vm]} {
		#ModuleWorkspace::rename $m $vm
	    }
	    continue
	}

	if {[ModuleKnowledge::known $m vm]} {
	    if {[string compare $m $vm]} {
		ModuleWorkspace::renameModule $m $vm
	    }
	    continue
	}
    }
}
