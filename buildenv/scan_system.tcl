#!/usr/local/bin/tclsh
# -*- tcl -*-
#
# scan_system.tcl
#
#	Dumps either the workspace, the knowledge or a list of all
#	modules which can be found in the worksapce (with the help
#	from the knowledge)
#
# Usage: scan_system.tcl workspace|knowledge|list|list-dump

lappend auto_path [set where [file dirname [info script]]]

package require ModuleWorkspace 1.0
package require ModuleKnowledge 1.0
package require ModuleInfo      1.0


proc dump {where} {
    namespace import ${where}::*

    puts stdout ""
    puts stdout ""
    puts stdout "$where _____________"
    puts stdout "Variables = [getBuildVariables]"
    puts stdout ""
    puts stdout "Modules = \{"
    foreach m [listModules] {
	puts "    $m ::"
	if {![catch {set d [getVersion $m]} msg]} {
	    puts stdout "\tVersion       = $d"
	} else {
	    puts stdout "\tVersion       undetermined ($msg)"
	}
	if {![catch {set d [getTopDir $m]} msg]} {
	    puts stdout "\tLocation      = $d"
	} else {
	    puts stdout "\tLocation      undetermined ($msg)"
	}
	if {![catch {set d [getDependencies $m]} msg]} {
	    puts stdout "\tDependencies  = $d"
	} else {
	    puts stdout "\tDependencies  undetermined ($msg)"
	}
	if {![catch {set d [getSubmodules $m]} msg]} {
	    puts stdout "\tSubmodules    = $d"
	} else {
	    puts stdout "\tSubmodules    undetermined ($msg)"
	}
	if {![catch {set d [getDerivedModules $m]} msg]} {
	    puts stdout "\tDerived       = $d"
	} else {
	    puts stdout "\tDerived       undetermined ($msg)"
	}
	if {![catch {set d [getPlatforms $m]} msg]} {
	    puts stdout "\tPlatforms     = $d"
	} else {
	    puts stdout "\tPlatforms     undetermined ($msg)"
	}
	if {![catch {set d [getTestDirectories $m]} msg]} {
	    puts stdout "\tTestsuite     = $d"
	} else {
	    puts stdout "\tTestsuite     undetermined ($msg)"
	}
	if {![catch {set d [getConfigurationFlags $m]} msg]} {
	    puts stdout "\tConfiguration = $d"
	} else {
	    puts stdout "\tConfiguration undetermined ($msg)"
	}
	if {![catch {set d [getSrcDirectory $m]} msg]} {
	    puts stdout "\tconfigure.in  = $d"
	} else {
	    puts stdout "\tconfigure.in  undetermined ($msg)"
	}
    }
    puts stdout "\}"
    return
}


switch -exact -- [set cmd [lindex $argv 0]] {
    workspace {
	# Build the workspace database
	ModuleWorkspace::setWorkspace [pwd]
	dump ModuleWorkspace
    }
    knowledge {
	# Build the knowledge database
	ModuleKnowledge::setKnowledgeDir [file join $where mk]
	dump ModuleKnowledge
    }
    list {
	# Build both databases, then unify the list of modules.

	ModuleWorkspace::setWorkspace [pwd]
	ModuleKnowledge::setKnowledgeDir [file join $where mk]

	puts _____________________________________________________

	puts "Modules = [ModuleInfo::listModules]"
    }
    list-dump {
	# See list, also dump all databases (workspace, knowledge and
	# unified).

	ModuleWorkspace::setWorkspace    [pwd]
	ModuleKnowledge::setKnowledgeDir [file join $where mk]

	puts _____________________________________________________
	puts "Modules = [ModuleInfo::listModules]"
	puts _____________________________________________________
	dump ModuleKnowledge
	namespace forget ModuleKnowledge::*
	puts _____________________________________________________
	dump ModuleWorkspace
	namespace forget ModuleWorkspace::*
	puts _____________________________________________________
	dump ModuleInfo
	namespace forget ModuleInfo::*
    }

    default {
	puts "Error, unknown command '$cmd'."
	puts "Usage: $argv workspace|knowledge|list|list-dump"
	exit -1
    }
}

exit 0
