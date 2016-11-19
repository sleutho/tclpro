# moduleHints.tcl --
#
#	Utility routines for the build environment.
#	Modified to use the [ModuleInfo] and thusly
#	[ModuleWorkspace] and [ModuleKnowledge].
#
# Copyright (c) 1999-2000 by Ajuba Solutions
# Copyright (c) 2001      by ActiveState
# See the file license.terms.
#
# RCS: @(#) $Id: moduleHints.tcl,v 1.1 2001/03/30 16:35:06 andreas_kupries Exp $

package provide ModuleHintsB 1.0

package require ModuleKnowledge 1.0
package require ModuleWorkspace 1.0
package require ModuleInfo      1.0
package require log             1.0


namespace eval ModuleHints {
    namespace export getCanonicalDependencies getModuleTopDir \
	    getDataFile setDataFile execViaPipe \
	    isValidModule getModuleSrcSubDir getPackageName

    # Mapping from %..%-variables to the values to actually use.
    # 'substmap' is a serialized version of the same, usable by
    # [string map].

    variable  subst
    array set subst {}
    variable  substmap {}


    # The name of the data file containing the built-time information, i.e.
    # - location of the workspace directory
    # - location of the knowledge directory (optional!)
    # - platform the current built is done upon.
    # - values for additional %..%-variables.
    # - prefix and exec_prefix (for installation)
    # - build_prefix (optional!)
    #
    # knowledge, exec_prefix and build_prefix are optional. Their
    # respective defaults are:
    #
    # exec_prefix  := [file join $prefix $platform]
    # build_prefix := [file join [pwd]   $platform]
    # knowledge    := [file join [file dirname [info script] mk]]
    #
    # IOW, the knowledge should be found in the subdirectory 'mk' of
    # where this script is located itself.

    variable dataFile {}

    # And now the variables to hold the information coming from the datafile.

    variable  workspace   {}
    variable  knowledge   {}
    variable  platform    {}
    variable  substdef
    array set substdef    {}
    variable  prefix      {}
    variable  execPrefix  {}
    variable  buildPrefix {}

    # Remember the location/directory of this script.

    variable here [file join [pwd] [file dirname [info script]]]

    # Cache a list of modules to built. This list takes platform
    # restrictions into a account. It is a cahce filled through
    # information from [ModuleInfo].

    variable modules [list]
    variable modinit 0
}

# ModuleHints::setDataFile --
#
#	Sets the path to the module data file, also evaluates it.
#
# Side Effects:
#	Initializes the internal database and both the workspace and knowledge
#	databases.
#
# Arguments:
#	fileName	Full path to the module data file
#
# Results:
#	None.
#

proc ModuleHints::setDataFile {fileName} {
    variable dataFile
    variable workspace
    variable knowledge

    # Check that the file exists and is readable before committing the
    # changes to our state.

    if {![file exists $fileName]} {
	return -code error "Data file $fileName not found"
    }
    if {![file readable $fileName]} {
	return -code error "Data file $fileName is not readable"
    }
    if {![file isfile $fileName]} {
	return -code error "Data file $fileName is not a file"
    }

    set dataFile $fileName

    # Paranoia, don't source it, use a safe sub-interpreter and
    # special commands in it for the configuration.

    set script [read [set f [open $fileName r]]]
    close                $f

    set ip [interp create -safe]
    foreach {cmd       -> alias} {
	DeclWorkspace  -> workspace.at
	DeclKnowledge  -> knowledge.at
	DeclPlatform   -> platform.is
	DeclVar        -> buildvariable
	DeclPrefix     -> prefix
	DeclExecPrefix -> execPrefix
	DeclBuild      -> build.in
    } {
	interp alias $ip $alias {} ModuleHints::$cmd
    }
    interp eval   $ip $script
    interp delete $ip

    # Check the configuration and fills any missing optional values
    # with their defaults. Complain if there are non-optional values
    # missing. Path information was already validated by the declaring
    # commands.
    ValidateConfiguration
    ShowConfiguration

    # Propagate the configuration down to the imported databases. This
    # will also initialize them.

    ModuleWorkspace::setWorkspace    $workspace
    ModuleKnowledge::setKnowledgeDir $knowledge

    # Now it is possible to check that the data file provided all
    # external %..%-variables which were requested by the
    # configuration flags for all now known modules.

    ValidateSetupBuildVars
    return
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
    variable  dataFile
    variable  workspace
    variable  knowledge
    variable  platform
    variable  substdef
    variable  prefix
    variable  execPrefix
    variable  buildPrefix
    variable  subst
    variable  substmap

    set  dataFile    {}
    set  workspace   {}
    set  knowledge   {}
    set  platform    {}
    set  prefix      {}
    set  execPrefix  {}
    set  buildPrefix {}

    unset     substdef
    array set substdef {}

    unset subst
    array set subst {}

    set substmap {}

    #      *todo* - unlearn info, knowledge and workspace
    error "*todo* - unlearn info, knowledge and workspace"
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
    variable platform

    array set tmp [ModuleInfo::getSrcDirectory $moduleName]
    set index [getBestIndex tmp {} $platform]
    return $index
}

# ModuleHints::getModuleTopDir --
#
#	Returns the top level directory for the specified module
#
# Arguments:
#	module	name of module
#
# Results:
#	Returns the absolute path to the source directory

proc ModuleHints::getModuleTopDir {moduleName} {
    variable workspace
    return [file join $workspace [ModuleInfo::getTopDir $moduleName]]
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

proc ModuleHints::getCanonicalDependencies {
    moduleName modulePath {callbackCmd {}} {modulePrefix {}}
} {
    set modList {}

    if {$modulePrefix == ""} {
	set modulePrefix $moduleName
    }

    if {[lsearch $modulePath $moduleName] != -1} {
	lappend modulePath $moduleName
	log::logError "Poorly constructed module dependency list:"
	log::logError "Circular dependency found:  [join $modulePath -->]"
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
		if {
		    [lsearch -exact $modList    $mod] == -1 &&
		    [lsearch -exact $modulePath $mod] == -1
		} {
		    lappend modList $mod
		}
	    }
	}

	if {
	    [lsearch -exact $modList   $depModule] == -1 &&
	    ![string match $moduleName $depModule]
	} {
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

    set depList [ModuleInfo::getDependencies $moduleName]

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
    variable substmap

    set result [list]

    array set std [ModuleInfo::getConfigurationFlags **standard**]

    if {[catch {array set mod [ModuleInfo::getConfigurationFlags $moduleName]}]} {
	# No module information available. Just use the standard flags.

	lappend result [GetValue std standard]
	lappend result [GetValue std $platform]
	lappend result [GetValue std $flavorStr]
    } else {
	# Module information available, interweave with standard flags

	lappend result [GetValue std standard]
	lappend result [GetValue mod {}]
	lappend result [GetValue std $platform]
	lappend result [GetValue std $flavorStr]
	lappend result [GetValue mod $platform]
	lappend result [GetValue mod $flavorStr]
	lappend result [GetValue mod $flavorStr,$platform]
    }

    # Postprocess result, especially replace %..% sequences with their
    # values.

    set result [join $result]
    #regsub -all "\[ \t\n\]+" $result { } result
    set result [string map $substmap $result]
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

    # -- makeTarget array not in original module_data available -- !
    # -- Maybe for Ajuba (aka ScripticsConnect) ?

    # For now the force the index to "" and thus return of the 2nd argument

    ## set index [getBestIndex ModuleData::makeTarget $moduleName $moduleName,$makeAction]
    set index ""

    # If nothing else was specified, then assume the module is TEA
    # compliant and use the normal target name.

    if {$index == ""} {
	return $makeAction
    } else {
	return $index
    }
}

# <>::<> --
#
#	*todo*
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ModuleHints::getValue {code} {
    switch -exact -- $code {
	build_prefix {variable buildPrefix; return $buildPrefix}
	prefix       {variable prefix;      return $prefix}
	exec_prefix  {variable execPrefix;  return $execPrefix}
	platform     {variable platform;    return $platform}
	default {
	    return -code error "Unknown value $code requested"
	}
    }
}

# ModuleHints::GetValue -- *todo* FIXME
#
#	Return a value from the ModuleData namespace *todo* FIXME
#
# Arguments:
#	varName	Name of value to retrieve
#
# Results:
#	Returns the value requested, or an empty string if the variable doesn't
#	exist.

proc ModuleHints::GetValue {varName index} {
    upvar $varName v

    if {[info exists v($index)]} {
	return $v($index)
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

proc ModuleHints::getBestIndex {aVar args} {
    upvar $aVar array

    set result {}
    foreach index $args {
	if {[info exists array($index)]} {
	    set result $array($index)
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
    log::logMsg "\nWorking directory:  [pwd]"
    log::logMsg "-->\[$cmd\]\n"
    set chanId [open "| $cmd |& cat -u" r]
    fconfigure $chanId -buffering line
    while {![eof $chanId]} {
	gets $chanId line
	log::logMsg $line
    }
    if {[catch {close $chanId}]} {
	log::logError "***ERROR:  command returned nonzero exit status"
	log::logError "\tWorking Directory:  [pwd]"
	log::logError "\tFailed Command:  $cmd"
	log::logError "\n"
	return 0
    }
    log::logMsg "\n"
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
    variable platform
    if {[IsWindows $platform]} {
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
    variable platform
    if {[IsWindows $platform]} {
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
    variable modules
    variable modinit

    if {!$modinit} {
	getModuleListing ; # Initialize cache
    }

    if {[lsearch -exact $modules $moduleName] >= 0} {
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
#	Initializes the cache list.
#
# Results:
#	A Tcl list containing module names is returned.

proc ModuleHints::getModuleListing {} {
    variable modules
    variable modinit
    variable platform

    if {!$modinit} {
	foreach m [ModuleInfo::listModules] {
	    # Consider only modules which are either available for all
	    # platforms or the platform we are building for, and also
	    # modules for which we have no information about platform
	    # restriction (no information is good information here,
	    # i.e. no restrictions).

	    if {[catch {set p [ModuleInfo::getPlatforms $m]}]} {
		lappend modules $m
	    } elseif {$p == {}} {
		lappend modules $m
	    } elseif {[lsearch -exact $p $platform] >= 0} {
		lappend modules $m
	    } ; # else ignore
	}
	set modinit 1
    }

    return $modules
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

    # The build system doesn't know a prefered package now. (Under the
    # old regime the main package contained the configure/Makefile to
    # configure the build itself. Skipping it during Configuration and
    # Build steps made sense. No more.)
    #return $ModuleData::packageName
    return ""
}

# ------------------------------------------------------------
# Internal commands from now on
# ------------------------------------------------------------


# ------------------------------------------------------------
# Commands for the safe-interpreter reading the provided data file.
# ------------------------------------------------------------

# ModuleHints::DeclWorkspace --
#
#	Declares the path to the workspace containing the modules to
#	build. The value is not optional. In the safe-interpreter
#	reading the data file this command is seen as [workspace.at].
#
# Arguments:
#	path	The path to the workspace-directory.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclWorkspace {path} {
    #  -> workspace.at
    variable workspace

    if {![file exists      $path]} {return -code error "workspace.at: Path $path does not exist"}
    if {![file isdirectory $path]} {return -code error "workspace.at: Path $path is no directory"}
    if {![file readable    $path]} {return -code error "workspace.at: Path $path is not readable"}

    set workspace $path
    return
}

# ModuleHints::DeclKnowledge --
#
#	Declares the path to the knowledge about the modules to
#	build. The value is not optional. In the safe-interpreter
#	reading the data file this command is seen as [knowledge.at].
#
# Arguments:
#	path	The path to the knowledge-directory.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclKnowledge {path} {
    # -> knowledge.at
    variable knowledge

    if {![file exists      $path]} {return -code error "knowledge.at: Path $path does not exist"}
    if {![file isdirectory $path]} {return -code error "knowledge.at: Path $path is no directory"}
    if {![file readable    $path]} {return -code error "knowledge.at: Path $path is not readable"}

    set knowledge $path
    return
}

# ModuleHints::DeclPlatform --
#
#	Declares the platform the current build is done for/upon
#	The value is not optional. In the safe-interpreter reading
#	the data file this command is seen as [platform.is].
#
# Arguments:
#	name	The name of the platform.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclPlatform {name} {
    # -> platform.is
    variable platform
    set platform $name
    return
}

# ModuleHints::DeclVar --
#
#	Declares the value associated to %..%-variable. The command is
#	not able to overide/change the values of builtin variables. In
#	the safe-interpreter reading the data file this command is
#	seen as [buildvariable].
#
# Arguments:
#	var	The name of the variable to set.
#	value	The value the variable is set to.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclVar {var value} {
    # -> buildvariable
    variable substdef
    set      substdef($var) $value
    return
}

# ModuleHints::DeclPrefix --
#
#	Declares the path to the installation directory for platform
#	independent files. The value is not optional. In the
#	safe-interpreter reading the data file this command is seen as
#	[prefix].
#
# Arguments:
#	path	The path to the installation-directory.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclPrefix {path} {
    # -> prefix
    variable prefix

    if {[file exists $path]} {
	if {![file isdirectory $path]} {return -code error "prefix: Path $path is no directory"}
	if {![file writable    $path]} {return -code error "prefix: Path $path is not writeable"}
    }

    set prefix $path
    return
}

# ModuleHints::DeclExecPrefix --
#
#	Declares the path to the installation directory for platform
#	dependent files. The value is optional and defaults to
#	<prefix>/<platform>. In the safe-interpreter reading the data
#	file this command is seen as [execPrefix].
#
# Arguments:
#	path	The path to the installation-directory.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclExecPrefix {path} {
    # -> execPrefix
    variable execPrefix

    if {[file exists $path]} {
	if {![file isdirectory $path]} {return -code error "exec_prefix: Path $path is no directory"}
	if {![file writable    $path]} {return -code error "exec_prefix: Path $path is not writable"}
    }

    set execPrefix $path
    return
}

# ModuleHints::DeclBuild --
#
#	Declares the path to the build directory, where intermediary
#	files of the build are located and placed in. The value is
#	optional and defaults to `pwd`/build. In the safe-interpreter
#	reading the data file this command is seen as [build.in].
#
# Arguments:
#	path	The path to the build-directory.
#
# Side Effects:
#	Manipulates the configuration of the module.
#
# Results:
#	None.

proc ModuleHints::DeclBuild {path} {
    # -> build.in
    variable buildPrefix

    if {[file exists $path]} {
	if {![file isdirectory $path]} {return -code error "build.in: Path $path is no directory"}
	if {![file writable    $path]} {return -code error "build.in: Path $path is not writable"}
    }

    set buildPrefix $path
    return
}

# ------------------------------------------------------------

# <>::<> --
#
#	*todo*
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ModuleHints::ShowConfiguration {} {
    variable  workspace
    variable  knowledge
    variable  platform
    variable  substdef
    variable  prefix
    variable  execPrefix
    variable  buildPrefix

    log::logMsg "Workspace  = $workspace"
    log::logMsg "Knowledge  = $knowledge"
    log::logMsg "Platform   = $platform"
    log::logMsg "Prefix     = $prefix"
    log::logMsg "ExecPrefix = $execPrefix"
    log::logMsg "Build      = $buildPrefix"

    parray substdef ; # *future* *todo* - Dump in better format.
    return
}

# ModuleHints::ValidateConfiguration --
#
#	*todo*
#
# Arguments:
#	None.
#
# Side Effects:
#	May change the configuration of the module (defaults for optional data).
#
# Results:
#	None.

proc ModuleHints::ValidateConfiguration {} {
    variable  workspace
    variable  knowledge
    variable  platform
    variable  substdef
    variable  prefix
    variable  execPrefix
    variable  buildPrefix
    variable  here

    set err [list]

    # Check must-have values first and bail out if there are any
    # errors in that section.

    if {$workspace == {}} {
	lappend err "- The workspace is unknown"
    }
    if {$platform == {}} {
	lappend err "- The platform is unknown"
    }
    if {$prefix == {}} {
	lappend err "- The installation directory is unknown"
    }

    if {[llength $err] > 0} {
	return -code error "Invalid configuration, build impossible:\n[join $err \n]"
    }

    # No errors in the must-have section, now go through the optional
    # values and use their defaults if that is necessary.

    if {$execPrefix == {}} {
	set path [file join $prefix $platform]
	if {[file exists $path]} {
	    if {![file isdirectory $path]} {
		lappend err "- exec_prefix: Path $path is no directory"
	    } elseif {![file writable $path]} {
		lappend err "- exec_prefix: Path $path is not writable"
	    }
	}
	set execPrefix $path
    }
    if {$buildPrefix == {}} {
	set path [file join [pwd] $platform]
	if {[file exists $path]} {
	    if {![file isdirectory $path]} {
		lappend err "- build.in: Path $path is no directory"
	    } elseif {![file writable $path]} {
		lappend err "- build.in: Path $path is not writable"
	    }
	}
	set buildPrefix $path
    }
    if {$knowledge == {}} {
	set path [file join $here mk]
	if {![file exists $path]} {
	    lappend err "- knowledge.at: Path $path does not exist"
	} elseif {![file isdirectory $path]} {
	    lappend err "- knowledge.at: Path $path is no directory"
	} elseif {![file readable $path]} {
	    lappend err "- knowledge.at: Path $path is not readable"
	} else {
	    set knowledge $path
	}
    }

    if {[llength $err] > 0} {
	return -code error "Invalid configuration, build impossible:\n[join $err \n]"
    }

    return
}


# ModuleHints::ValidateConfiguration --
#
#	*todo*
#
# Arguments:
#	None.
#
# Side Effects:
#	May change the configuration of the module (subst-array).
#
# Results:
#	None.

proc ModuleHints::ValidateSetupBuildVars {} {
    variable  subst
    variable  substmap
    variable  substdef

    variable  workspace
    variable  knowledge
    variable  platform 
    variable  prefix
    variable  execPrefix
    variable  buildPrefix

    # Go through the variables and set their values up. Create the
    # list for [string map] in the same run. Values for the builtins
    # come from our state and the databases. All other values come
    # from the variables defined by the configuration (= substdef).

    array set subst [ModuleInfo::getBuildVariables]
    set err [list]

    foreach key [array names subst] {
	switch -glob -- $key {
	    build_dir {
		set value $buildPrefix
		regsub {^~} $value $::env(HOME) value
	    }
	    build_id {
		set value [clock format [clock seconds] -format "%Y%m%d%H%M"]
	    }
	    workspace {
		set value $workspace
		regsub {^~} $value $::env(HOME) value
	    }
	    arch {
		switch $platform {
		    win32-ix86 {
			set arch win
		    }
		    default {
			set arch unix
		    }
		}
		set value $arch
	    }
	    platform {
		set value $platform
	    }
	    prefix {
		set value $prefix
		regsub {^~} $value $::env(HOME) value
	    }
	    exec_prefix {
		set value $execPrefix
		regsub {^~} $value $::env(HOME) value
	    }
	    top:* {
		regsub {^top:} $key {} module
		if {![ModuleInfo::known $module vmodule]} {
		    # Unknown module is referenced
		    set value ""
		} elseif {[catch {set value [ModuleInfo::getTopDir $vmodule]}]} {
		    # Module known, but without top directory.
		    set value ""
		} else {
		    # value is set, but relative to the workspace, so
		    set value [file join $workspace $value]
		    regsub {^~} $value $::env(HOME) value
		}
	    }
	    bld:* {
		regsub {^bld:} $key {} module
		if {![ModuleInfo::known $module vmodule]} {
		    # Unknown module is referenced
		    set value ""
		} else {
		    set value [file join $buildPrefix $vmodule]
		    regsub {^~} $value $::env(HOME) value
		}
	    }
	    version:* -
	    vmajor:* -
	    vminor:* -
	    vpatchlvl:* {
		regsub {^v[^:]+:} $key {} module
		if {![ModuleInfo::known $module vmodule]} {
		    # Unknown module is referenced
		    set value ""
		} elseif {[catch {set value [ModuleInfo::getVersion $vmodule]}]} {
		    # Module known, but without version information
		    set value ""
		} else {
		    # value is set, split into parts and use only the requested one
		    # value = [0-9]+[.][0-9]+[abp.][0-9]+

		    foreach v {major minor code patch} {set $v {}}
		    regexp {^([0-9]+)[.]([0-9]+)(([abp.])([0-9]+))?$} $value \
			    -> major minor dummy code patch

		    switch -glob -- $key {
			version:*   {# do nothing, use value as is}
			vmajor:*    {set value $major}
			vminor:*    {set value $minor}
			vpatchlvl:* {
			    switch -exact -- $code {
				a - b {set value 0 ; # alpha/beta - no patchlevel}
				p - . {set value $patch}
				""    {set value 0}
			    }
			}
		    }
		}
	    }
	    default {
		# Query 'substdef' for everything else.
		if {[info exists substdef($key)]} {
		    set value $substdef($key)
		} else {
		    set value bogus
		    lappend err "- Variable $key not declared by build configuration"
		}
	    }
	}

	set subst($key)           $value
	lappend substmap %${key}% $value
    }

    if {[llength $err] > 0} {
	return -code error "Invalid configuration, build impossible:\n[join $err \n]"
    }

    #parray subst
    return
}
