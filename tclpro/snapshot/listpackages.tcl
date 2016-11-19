#
# TclPro
#
# Little program to list all the packages that are available in a Tcl
# interpreter and their version information.
#
# Writes a line to stdout for each package found consisting of
#     package moduleName packageName versionInfo
# as a Tcl list.  Where package is the text "package", module name is
# passed as an argument to the script, package name is the name of
# a package found and versionInfo is the data returned by "package version"
# on that package.
#
# Used as part of the snapshot technology to help figure out which modules
# provided which packages.
#
# This script is invoked by a Tcl interpreter (tclsh* or wish*)
# invoked by buildModule.tcl
#
# $Id: listpackages.tcl,v 1.1 2001/03/15 10:39:26 karll Exp $
#

set moduleName $argv

catch {package require no-such-package}

foreach package [lsort [package names]] {
    puts [list package $moduleName $package [package version $package]]
}
