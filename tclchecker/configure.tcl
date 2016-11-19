# configure.tcl --
#
#	This file configures the analyzer by loading checkers and
#	message tables based on command line arguments.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: configure.tcl,v 1.17 2001/03/13 19:02:53 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide configure 1.0
namespace eval configure {

    namespace export register 

    # The initPkgs variable is used to record which packages
    # were loaded.  This info is used when printing summary 
    # information.

    variable initPkgs {}

    # The versions variable stores the requested command line
    # version and the default version of every package being
    # loaded in the checker.  The requested command line version
    # is keyed based on pkg name (e.g., $versions($pkg)) the 
    # default version is keyed based on pkg name and the string
    # "default" (e.g., $versions($pkg,default)).

    variable versions

    # Store the list of in-built packages.

    variable builtInPkgList "expect, incrTcl, tcl, tclX, or tk"

    # Store a mapping from user specified package names to
    # Tcl package names.

    array set validPkgs {
	tcl 		coreTcl
	tk 		coreTk
	expect		expect
	incrTcl 	incrTcl
	tclX		tclX
    }

    # The verTable array maps package versions to specific versions
    # of Tcl packages.  This info is used when resolving which versions
    # should be loaded foreach package.

    variable verTable
    set verTable(coreTcl,7.3) 7.3
    set verTable(coreTcl,7.4) 7.4
    set verTable(coreTcl,7.5) 7.5
    set verTable(coreTcl,7.6) 7.6
    set verTable(coreTcl,8.0) 8.0
    set verTable(coreTcl,8.1) 8.1
    set verTable(coreTcl,8.2) 8.2
    set verTable(coreTcl,8.3) 8.3

    set verTable(coreTk,3.6)  7.3
    set verTable(coreTk,4.0)  7.4
    set verTable(coreTk,4.1)  7.5
    set verTable(coreTk,4.2)  7.6
    set verTable(coreTk,8.0)  8.0
    set verTable(coreTk,8.1)  8.1
    set verTable(coreTk,8.2)  8.2
    set verTable(coreTk,8.3)  8.3

    set verTable(incrTcl,1.5) 7.3
    set verTable(incrTcl,2.0) 7.4
    set verTable(incrTcl,2.1) 7.5
    set verTable(incrTcl,2.2) 7.6
    set verTable(incrTcl,3.0) 8.0
    set verTable(incrTcl,3.1) 8.3

    set verTable(expect,5.28) 8.0
    set verTable(expect,5.29) 8.1
    set verTable(expect,5.30) 8.1
    set verTable(expect,5.31) 8.3

    set verTable(tclX,8.0)    8.0
    set verTable(tclX,8.1)    8.1
    set verTable(tclX,8.2)    8.3

    # loadPCX          Allow/suppress the loading of the PCX files
    # usrPcxDirList    The user-specified list of dirs containing *.pcx files
    # usrPkgArgs       The user-specified -use args

    variable loadPCX 1
    variable usrPcxDirList {}
    variable usrPkgArgs {}
}

# configure::packageSetup --
#
#	Based on command line arguments, load type checkers
#	into the anaylyzer.
#
# Arguments:
#	pkgArgs          The selected packages, which will be loaded.
#
# Results:
#	1 for success, 0 if the package setup failed

proc configure::packageSetup {} {
    variable initPkgs
    variable versions
    variable verTable
    variable validPkgs
    variable usrPkgArgs

    # Initialize the internal status variables.
    set initPkgs ""
    foreach element [array names versions] {
        unset versions($element)
    }
    array set versions {}
    
    # Stores the set of command-specific checkers currently defined
    # for the global context.
    catch {unset ::analyzer::checkers}
    array set ::analyzer::checkers {}

    # Stores the set of commands to be scanned for proc definitions.
    # (e.g., proc, namespace eval, and class)
    catch {unset ::analyzer::scanCmds}
    array set ::analyzer::scanCmds {}

    # Destroy the namespaces
    foreach element [namespace children ::] {
        if {"$element" == "::tcl" || "$element" == "::coreTcl" } {
            catch "namespace delete ::coreTcl"
            continue
        }
        if {"$element" == "::tk" || "$element" == "::coreTk"} {
            catch "namespace delete ::coreTk"
            continue
        }
        if {[info exists validPkgs([string range $element 2 end])]} {
            catch "namespace delete $element"
        }
    }
    
    # Remove package loading information
    foreach element [array names validPkgs] {
        catch "package forget $element"
    }

    # Make the packages known again....
    package ifneeded coreTcl 1.0 \
        [list ::checker::source [file join $::checker::libdir coreTcl.tcl]]
    package ifneeded coreTk  1.0 \
        [list ::checker::source [file join $::checker::libdir coreTk.tcl]]
    package ifneeded incrTcl 1.0 \
        [list ::checker::source [file join $::checker::libdir incrTcl.tcl]]
    package ifneeded expect  1.0 \
        [list ::checker::source [file join $::checker::libdir expect.tcl]]
    package ifneeded tclX    1.0 \
        [list ::checker::source [file join $::checker::libdir tclX.tcl]]
    package ifneeded tkTable 1.0 \
        [list ::checker::source [file join $::checker::libdir tkTable.tcl]]
    package ifneeded tclDP 	 1.0 \
        [list ::checker::source [file join $::checker::libdir tclDP.tcl]]
    package ifneeded blt 	 1.0 \
        [list ::checker::source [file join $::checker::libdir blt.tcl]]

    # Foreach package argument, call the "package require"
    # routine.  A side effect of calling this command should
    # be a call to "configure::register" for the specified 
    # package and all of its dependencies.

    set analyzerPkgs ""
    foreach pkg [join $usrPkgArgs] {

	# The package name is defined as the alpha chars
	# up to but not including the first number.  The numbers
	# after the package name must be a version number.
	# Look for <name><major>.<minor>.<whatever> patterns.

	if {![regexp {^([^0-9]+)(([0-9]+(.[0-9]+)?).*)$} \
		$pkg dummy name verStr ver]} {
	    set name   $pkg
	    set verStr {}
	    set ver    {}
	}
	
	# Search the list of valid packages.  If the match is found we
	# have successfully extracted the internal package name from
	# the external package name used by the users.  Otherwise, the
	# user specified an invalid package, log an error and return.
	#
	# The name of the package is not case sensitive.  Search the
	# list of valid packages by converting all the chars to lower-
	# case, then grab the case sensitive name out of the list.

	set vPkgs [array names validPkgs]
	set index [lsearch -exact [string tolower $vPkgs] \
		[string tolower $name]]

	if {$index == -1} {
	    configure::errorBadPkg $name
            return 0
	} else {
	    set name [lindex $vPkgs $index]
	}
		
	set pkgName $validPkgs($name)
	if {[catch {package require $pkgName}]} {
	    Puts "Error: unable to load package $pkgName"
	    return 0
	}

	# Validate the requested version number

	if {$ver != "" && ![info exists verTable($pkgName,$ver)]} {
	    set vers {}
	    foreach v [lsort [array names verTable ${pkgName},*]] {
		lappend vers \
			[string range $v [expr {[string last , $v] + 1}] end]
	    }
	    Puts "unsupported $name version $verStr, should be [humanList $vers or]"
	    return 0
	}
	    
	set versions($pkgName) $ver
	
	# If the package name is already on the list, remove it 
	# so the package is loaded only once.
	
	if {[set index [lsearch $analyzerPkgs $pkgName]] >= 0} {
	    set analyzerPkgs [lreplace $analyzerPkgs $index $index]
	}
	lappend analyzerPkgs $pkgName
    }
    
    # If no packages were specified, then implicitly load the default 
    # versions for tcl, and supported extensions.  If tcl was not 
    # specified, then add it to the beginning of the list.  Otherwise,
    # make sure that tcl is on the front of the list, because other 
    # pkgs may clobber tcl checkers (e.g., [incr Tcl].)
    
    if {$analyzerPkgs == {}} {
	# If no packages were specified, then implicitly load the
	# default versions of Tcl, Tk, and then the non-pcx extensions,
	# This is hardcoded so that when the same proc is defined in
	# multiple packages, the last definition of a proc is the one
	# that gets checked.

	set analyzerPkgs [concat coreTcl coreTk expect tclX incrTcl]

	foreach name $analyzerPkgs {
	    package require $name
	    set versions($name) {}
	}
    } elseif {[lsearch $analyzerPkgs coreTcl] < 0} {
	# If packages were specified but Tcl was not specified,
	# then add it to the beginning of the list.
    
	set analyzerPkgs [linsert $analyzerPkgs 0 coreTcl]
	package require coreTcl
	set versions(coreTcl) {}
    } elseif {[set index [lsearch $analyzerPkgs coreTcl]] > 0} {
	# If the Tcl package was specified, make sure that Tcl
	# is on the front of the list, so that other 
	# pkgs may clobber tcl checkers (e.g., [incr Tcl].)

	set analyzerPkgs [lreplace $analyzerPkgs $index $index]
	set analyzerPkgs [linsert $analyzerPkgs 0 coreTcl]
    }

    set pcxPkgs [configure::PcxSetup]

    # Now we have a list of all the packages to load, the requested
    # versions and the default versions.  Verify that all of the 
    # versions are compatible.  There are three steps to do this:
    #
    # (1) Iterate through all of the packages and see if a specific
    #     version was requested.  The first package to explicitly 
    #     request a version will set the version for coreTcl.  After
    #     this, any package that requests a version that does not
    #     map to the set coreTcl version generates an error.
    # (2) If a version of coreTcl wasn't set, use the default.
    # (3) Iterate through all of the packages that do not have a
    #     versions specified.  Use the version of the package that
    #     maps to the version of coreTcl being used.
    
    foreach pkg $analyzerPkgs {
	if {($pkg != "coreTcl") && ($versions($pkg) != {})} {
	    # If coreTcl has not specified a version, then set
	    # the version of coreTcl based on the version of
	    # this package.  If coreTcl has a version, then 
	    # verify the version of the package is compatible
	    # with the requested version of tcl.  Only do this 
	    # if a mapping between coreTcl and the package exists.
	    # (e.g., $coreVer != {})
	    
	    set ver $versions($pkg)
	    set coreVer [configure::getVersion $pkg $ver]
	    if {$versions(coreTcl) == {}} {
		set versions(coreTcl) $coreVer
	    } elseif {($coreVer != {}) && ($versions(coreTcl) != $coreVer)} {
		configure::errorVerConflicts $pkg $ver $versions(coreTcl)
                return 0
	    }
	}
    }

    # If coreTcl's version was not implicitly set by another
    # module, then use the default.

    if {$versions(coreTcl) == {}} {
	 set versions(coreTcl) $::projectInfo::baseTclVers
    }

    foreach pkg $analyzerPkgs {
	if {($pkg != "coreTcl") && ($versions($pkg) == {})} {
	    # If a version was not specified then calculate the
	    # version number from the table or just use the 
	    # default value.  Sort the list of array names and 
	    # take the most recent version of the package that maps
	    # to the coreTcl version.

	    foreach name [lsort [array names verTable "$pkg,*"]] {
		if {$verTable($name) == $versions(coreTcl)} {
		    set versions($pkg) [lindex [split $name ,] 1]
		}
	    }
	    if {[catch {
		if {$versions($pkg) == {}} {
		    # Set the version to the default version and continue
		    # because this package has no dependencies on the 
		    # requested version of coreTcl.
		    
		    set versions($pkg) $versions($pkg,default)
		}
		set ver $versions($pkg)
		set coreVer [configure::getVersion $pkg $ver]
	    }]} {
		configure::errorVerConflicts $pkg "" $versions(coreTcl)
		return 0
	    }
	    if {($coreVer == {}) || ($versions(coreTcl) != $coreVer)} {
		configure::errorVerConflicts $pkg $ver $versions(coreTcl)
		return 0
	    }
	}
    }

    # add pcx packages if their tcl version is the one that was chosen
    # or if no tcl version was specified.

    foreach pkg $pcxPkgs {
	set index [lindex [array names verTable "$pkg\,*"] 0]
	set pkgVers [lindex [split $index ,] 1]
	set tclVers $verTable($index)
	#set tclVers $versions($pkg\,default)
	set versions($pkg) $pkgVers
	if {($tclVers == "") || [string equal $tclVers $versions(coreTcl)]} {
	    #lappend analyzerPkgs $pkg
	    set analyzerPkgs [linsert $analyzerPkgs 1 $pkg]
	}
    }

    # Initialize all of the selected packages in order of 
    # their specification.

    foreach name $analyzerPkgs {
	if {[catch {${name}::init $versions($name)} err]} {
	    Puts $err
	    return 0
	} else {
	    # Record the package name and version.  This will
	    # be used later if summary info is printed out.

	    lappend initPkgs $name
	    lappend initPkgs $versions($name)
	}
    }
    return 1
}

# configure::PcxSetup --
#
#	Source the .pcx extension files unless the -nopcx flag was
#	specified on the commandline.
#
# Arguments:
#	none.
#
# Results:
#	1 for success, 0 if the package setup failed

proc configure::PcxSetup {} {
    variable loadPCX
    variable usrPcxDirList
    variable versions

    set pcxPkgs {}

    if {$loadPCX} {

	# Source .pcx extension files that are specified in projectInfo and
        # located adjacent to checker source files--don't use glob, as these
        # files are wrapped.  Do this first so users can override
	# .pcs definitions of built-in commands they have changed.

	foreach stem $::projectInfo::pcxPkgs {

	    set file [file join $::checker::libdir "$stem.pcx"]
	    lappend files $file
	} 

	# Load any external extensions from ::projectInfo::pcxPdxDir,
	# from env(::projectInfo::pcxPdxVar), and from dirs specified by
	# users on the command line.
    
	set files [glob -nocomplain [file join $::projectInfo::pcxPdxDir *.pcx]]
	if {[info exists ::env($::projectInfo::pcxPdxVar)]} {
	    set files [concat $files [glob -nocomplain \
		    [file join $::env($::projectInfo::pcxPdxVar) *.pcx]]]
	}

	foreach dir $usrPcxDirList {
	    if {[catch {set usrFiles [glob [file join $dir "*.pcx"]]}]} {
		Puts "Warning: no pcx file matching [file join $dir *.pcx]"
	    } else {
		set files [concat $files $usrFiles]
	    }
	}

	foreach file $files {

	    # If the pcx file can't be sourced, do not continue.
	    
	    if {[catch {uplevel \#0 [list source $file]} err]} {
		Puts "Error loading extension $file:\n$err\n$::errorInfo"
		return 0
	    }

	    set pkg [file tail [file root $file]]
	    package require $pkg
	    set versions($pkg) {}
	    lappend pcxPkgs $pkg
	}
    }
    return $pcxPkgs
}

# configure::setFilter --
#
#	This sets the filter array that determines what
#       kind of warnings are displayed.
#
# Arguments:
#	filter	The filter string, or W1, W2, W3, Wa or Wall. The
#               W* strings are predefined filters commonly used.
#
# Results:
#	The side effect is, if the package name does not exist in
#	versions array, the version is added to the array.

proc configure::setFilter {filter} {

    filter::clearFilters
    switch -- $filter {
        {W1} {
            # filter all warnings.
	    filter::addFilters {warn nonPortable performance upgrade usage}
        }
        {W2} {
	    # filter aux warnings.
	    filter::addFilters {warn nonPortable performance upgrade}
        }
        {W3} -
        {Wa} -
        {Wall} {
            # filter nothing.
        }
        {default} {
	    filter::addFilters $filter
        }
    }
}

# configure::setPasses --
#
#	This sets the number of passes for the checker.
#
# Arguments:
#	passes	1 for one pass, 2 for two passes.
#
# Results:
#	The global flag for the state is changed.

proc configure::setPasses {passes} {

    if {$passes == 1} {
        analyzer::setTwoPass 0
    } else {
        analyzer::setTwoPass 1
    }
}

# configure::setSuppressors --
#
#	This sets the array that determines what message
#       ids are displayed.
#
# Arguments:
#	mids	The message id's to suppress.
#
# Results:
#	None.

proc configure::setSuppressors {mids} {

   filter::clearSuppressors
   filter::addSuppressor $mids
}

# configure::register --
#
#	This is the well-known procedure that each analyzer
#	package calls to tell the analyzer that it's package
#	needs to be loaded into the analyzer's checker.
#
# Arguments:
#	name	The name of the analyzer package.
#	ver	The default version of the anzlyzer package.
#
# Results:
#	The side effect is, if the package name does not exist in
#	versions array, the version is added to the array.

proc configure::register {name ver} {
    variable versions
    variable validPkgs

    # Map the extension name to the same package name if a mapping isn't
    # already established.

    if {![info exists validPkgs($name)]} {
	set validPkgs($name) $name
    }

    set versions($name,default) $ver
    return
}

# configure::getInitPkgs --
#
#	Returns the list of packages and versions that were loaded.
#
# Arguments:
#	None.
#
# Results:
#	An list of package/version pairs.

proc configure::getInitPkgs {} {
    return $configure::initPkgs
}

# configure::getVersion --
#
#	Return the version of coreTcl to request based on the
#	package name and version.
#
# Arguments:
#	pkg	The name of the package.
#	ver	The version requested for the package.
#
# Results:
#	The version of coreTcl to load, or null if the version is invalid.

proc configure::getVersion {pkg ver} {
    variable verTable
    if {[info exists verTable($pkg,$ver)]} {
	return $verTable($pkg,$ver)
    } else {
	return {}
    }
}

# configure::getCheckVersion --
#
#	Return the version of pkg that is being checked.
#
# Arguments:
#	pkg	The name of the package.
#
# Results:
#	The version number, or -1 if the package is nopt loaded.

proc configure::getCheckVersion {pkg} {
    variable versions
    if {[info exists versions($pkg)]} {
	return $versions($pkg)
    } else {
	return -1
    }
}

# configure::errorVerConflicts --
#
#	Print the error message for version conflicts.
#
# Arguments:
#	pkg	The name of the package.
#	ver	The version requested for the package,
#		"" if no specific version was requested.
#	tclVer	The version requested for the Tcl package.
#
# Results:
#	None.

proc configure::errorVerConflicts {pkg ver tclVer} {
    switch $pkg {
	coreTcl {
	    set message "Can't run Tcl $ver"
	}
	coreTk {
	    set message "Can't run Tk $ver with Tcl $tclVer"
	}
	default {
	    set message "Can't run $pkg $ver with Tcl $tclVer"
	}
    }
    Puts "Error: $message"
    Puts "See $::projectInfo::usersGuide for compatible versions."
    return
}

# configure::errorBadPkg --
#
#	Print the error message for bad package requests.
#
# Arguments:
#	name	The name of the package.
#
# Results:
#	None.

proc configure::errorBadPkg {name} {
    variable builtInPkgList

    # This algorithm is a little complex because it parses the 
    # validPkgs list to convert the Tcl List to the string:
    # pkg1, pkg2 or pkg3.  This is done so the output is not
    # hard coded and is dynamic based on avaliable packages.

    Puts "invalid package \"$name\" must be $builtInPkgList"
    return
}

# configure::humanList --
#
#	Convert a Tcl List to a list separated by commas and
#	and a final "and" or "or" keyword.
#
# Arguments:
#	tclList		The Tcl List to convert.
#	ending		The final ending keyword.
#
# Results:
#	A human readable list.

proc configure::humanList {tclList ending} {
    if {[llength $tclList] == 1} {
	return [lindex $tclList 0]
    }
    set result {}
    while {1} {
	set element [lindex $tclList 0]
	if {[llength $tclList] > 1} {
	    append result "$element, "
	} else {
	    append result "$ending $element"
	    break
	}
	set tclList [lrange $tclList 1 end]
    }
    return $result
}
