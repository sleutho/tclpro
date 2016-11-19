#!/usr/local/bin/tclsh
# -*- tcl -*-
#
# dump_knowledge.tcl
#
#	Run "make $action" on a specified module
#
# Usage:  tclsh8.2 dump_knowledge.tcl

lappend auto_path [file dirname [info script]]

package require  ModuleKnowledge 1.0
namespace import ModuleKnowledge::*

# Build the database

set kd [lindex $argv 0]
if {$kd == {}} {
    puts stdout "Usage: $argv0 knowledge-directory"
    exit -1
}

setKnowledgeDir [lindex $argv 0]

# Now dump it in human readable form

puts stdout ""
puts stdout ""
puts stdout "Module knowledge /Knowledge _____________"
puts stdout "Knowledge from = [getKnowledgeDir]"
puts stdout "Modules = \{"
foreach m [listModules] {
    puts "    $m"
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
	puts stdout "\tVirtual       = $d"
    } else {
	puts stdout "\tVirtual       undetermined ($msg)"
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
	puts stdout "\tconfigure.in  ="
    } else {
	puts stdout "\tconfigure.in  undetermined ($msg)"
    }
}
puts stdout "\}"

#parray ::ModuleKnowledge::configFlags

exit 0
