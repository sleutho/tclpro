# compileAndWrap.tcl --
#
#    This file demonstrates TclPro Compiler and TclPro Wrapper by using
#    the tools to create standalone applications from the Factorial and
#    HiQ demo applications.
#
# Example:
#
#    protclsh<TclVersion> <TclProReleaseDir>/demos/compileAndWrap.tcl
#
# Result:
#
#    As a result of running this demo, a new directory called
#    "demo.${platform}" will be created in the demos directory.
#    To run the wrapped demo applications, type the following
#    at your command prompt:
#
#    demo.<platform>/fac 5
#
#    demo.<platform>/hiq
#
#
# Copyright (c) 1998-1999 by Scriptics Corporation
# All rights reserved
#
# RCS: @(#) $Id: compileAndWrap.tcl,v 1.2 2001/01/31 01:26:17 welch Exp $

#
# Set the platform variable to the platform you are currently using.
#

if {[regexp -nocase sun $tcl_platform(os)]} {
    set platform "solaris-sparc"
} elseif {[regexp -nocase hp $tcl_platform(os)]} {
    set platform "hpux-parisc"
} elseif {[regexp -nocase linux $tcl_platform(os)]} {
    set platform "linux-ix86"
} elseif {[regexp -nocase irix $tcl_platform(os)]} {
    set platform "irix-mips"
} elseif {[regexp -nocase freebsd $tcl_platform(os)]} {
    set platform "freebsd-ix86"
} else {
    set platform "win32-ix86"
}

#
# cd to the "demos" directory in your release.
#

set TclProDemoDir [file dirname [info script]]
cd $TclProDemoDir

#
# Find the tools in this TclPro distribution
#

set TclProBinDir [file join .. $platform bin]
foreach tool {procomp prowrap} {
    if {[string compare $platform "win32-ix86"] == 0} {
	set fileName [file join $TclProBinDir ${tool}.exe]
    } else {
	set fileName [file join $TclProBinDir $tool]
    }
    if {![file exists $fileName] || ![file executable $fileName]} {
	puts "Error:  can't find executable file:"
	puts "\t$fileName"
	puts "Check INSTALL.LOG to see if installation completed successfully."
	exit
    }
    set [subst $tool] $fileName
}

#
# Create $outDir in the current working directory to hold
# compiled Tcl code and wrapped apps.
#

set outDir demo.$platform
catch {file delete -force $outDir}
catch {file mkdir $outDir}

#
# Compile the factorial demo.
# - creates a compiled fac.tbc in the $outDir
#

set cmd [list $procomp -force -out $outDir fac.tcl]

catch {exec $procomp -nologo -force -out $outDir fac.tcl} procompResult
if {[regexp {License Manager} $procompResult]} {
    puts "\nWelcome to the TclPro Compiler and TclPro Wrapper demo."
    puts "Your license key must be entered to run this demo."
    puts "To enter the license key, please start TclPro License Manager,"
    puts "enter the key when prompted, and then restart this demo."
    exit
}
puts "\nThe following commands can be run from"
puts "    \"[pwd]\""
puts "to compile and wrap the factorial and HiQ demos."

puts "\nCompile the factorial application:\n"
puts $cmd

#
# Wrap the compiled factorial demo.
# - creates a stand-alone Factorial app called fac.exe
#   in the $outDir
# - note that the fac.tcl script takes a command line argument:
#   an integer for which to find the factorial.
#

set compiledFactorial [file join $outDir fac.tbc]
set wrappedFactorial [file join $outDir fac.exe]

set cmd [list $prowrap -out $wrappedFactorial \
	 -uses tclsh $compiledFactorial]

puts "\nWrap the factorial application:\n"
puts $cmd
catch {eval exec $cmd}

#
# Compile the HiQ demo.
# - creates compiled hiq.tcl, hiqState.tcl, and hiqGUI.tcl files
#   in the $outDir.
#

puts "\nCompile the HiQ application:\n"

foreach file [glob hiq*.tcl] {

    set outFile [file join $outDir $file]

    set cmd [list $procomp -force -out $outFile $file]

    puts $cmd
    catch {eval exec $cmd}
}

#
# Wrap the compiled HiQ demo.
# - creates a stand-alone HiQ app called hiq.exe
#   in the $outDir
# - hiq.exe starts up with the file "hiq.tcl"
# - the compiled Tcl files (hiq.tcl, hiqState.tcl, and hiqGUI.tcl)
#   are all wrapped in hiq.exe
#

set wrappedHiQ [file join $outDir hiq.exe]
set compiledHiQ [glob [file join $outDir hiq*.tcl]]

set cmd [list $prowrap -out $wrappedHiQ -uses wish \
	     -startup hiq.tcl -relativeto $outDir]

puts "\nWrap the HiQ application:\n"
puts "$cmd $compiledHiQ"
catch {eval exec $cmd $compiledHiQ}

puts "You can invoke the wrapped factorial and HiQ applications by"
puts "executing the following at the command prompt:"
puts "    [file join [pwd] $outDir fac.exe] <positive integer>"
puts "    [file join [pwd] $outDir hiq.exe]"
