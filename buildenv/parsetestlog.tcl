# parsetestlog.tcl
#
#	This file contains some useful routines for parsing the nightly test
#	log files.
#

package provide parsetest 1.0

namespace eval parseTestLog {
    # Maintain a list of stats for the current test log

    variable failedTestFiles {}
    variable passedTestFiles {}
    variable miaTestFiles {}
    variable doaTestFiles {}

    # Failed test ids are stored in an array indexed by the module name

    variable failedTestIds

    # Current parsing state:  dirty ready active done

    variable state dirty

    variable currentTest {}
}

# parseTestlog::init --
#
#	Initialize the state for parsing a new log file
#
# Arguments:
#	None
#
# Side Effects:
#	State variables are initialized
#
# Results:
#	None

proc parseTestLog::init {} {
    variable failedTestFiles
    variable passedTestFiles
    variable miaTestFiles
    variable doaTestFiles
    variable failedTestIds

    set failedTestFiles {}
    set passedTestFiles {}
    set miaTestFiles {}
    set doaTestFiles {}

    catch {unset failedTestIds}
    set state ready

    return
}

# parseTestlog::parse --
#
#	Parse the test log file
#
# Arguments:
#	filename	Full path to log file that will be parsed.
#
# Side Effects:
#	Variables in the namespace will be updated to reflect the
#	results of the test run.
#
# Results:
#	Returns 1 if the file was successfully parsed, 0 if not.

proc parseTestLog::parse {filename} {
    variable failedTestFiles
    variable passedTestFiles
    variable miaTestFiles
    variable doaTestFiles
    variable failedTestIds

    set currentTestResult {}
    set currentTest {}
    set inputChanId [open $filename r]
    set success 1

    while {![eof $inputChanId]} {
	gets $inputChanId line

	# Keep track of the module name for the test results that we are
	# currently scanning.
	if {[regexp "^Testing module (.*)$" $line null module]} {
	    # If we haven't detected a result for the previous module
	    # then give it a result of "Missing in Action"

	    if {[string length $currentTest] > 0} {
		if {[string length $currentTestResult] == 0} {
		    lappend miaTestFiles $currentTest
		}
	    }

	    set currentTest $module
	    set currentTestResult {}
	}

	# Keep track of individual test failures
	if {[regexp {^==== ([^ ]+) FAILED$} $line null testId]} {
	    lappend failedTestIds($currentTest) $testId
	    if {[lsearch $failedTestFiles $currentTest] == -1} {
		lappend failedTestFiles $currentTest
	    }
	    set currentTestResult failed
	}

	# Test suites that print a summary line are marked either "passed"
	# or "failed" depending on the number of individual failed tests
	if {[regexp {^all.tcl:\tTotal\t([0-9]+)\tPassed\t([0-9]+)\tSkipped\t([0-9]+)\tFailed\t([0-9]+)} $line null total passed skipped failed]} {
	    if {$failed > 0 \
		    || $passed == 0 \
		    || [info exists failedTestIds($currentTest)]} {
		if {[lsearch $failedTestFiles $currentTest] == -1} {
		    lappend failedTestFiles $currentTest
		}
		set currentTestResult failed
	    } else {
		lappend passedTestFiles $currentTest
		set currentTestResult passed
	    }
	}

	if {[regexp "^\tFailed Command:  make test" $line]} {
	    # Test suites that exit nonzero, and don't have a summary line
	    # are counted as "Dead on Arrival"

	    if {[string length $currentTestResult] == 0} {
		set currentTestResult doa
		lappend doaTestFiles $currentTest
	    }
	}
    }

    return $success
}

# parseTestlog::report --
#
#	Show the summary from the parsing of the log file
#
# Arguments:
#	chanid		Channel on which to print the test summary.  If
#			not specified then results are printed to stdout.
#
# Side Effects:
#	Text will be dumped to the channel
#
# Results:
#	None

proc parseTestLog::report {args} {
    variable failedTestFiles
    variable passedTestFiles
    variable miaTestFiles
    variable doaTestFiles
    variable failedTestIds

    if {[string length $args] == 0} {
	set chanid stdout
    } else {
	set chanid $args
    }

    puts -nonewline $chanid "Passed:\t[llength $passedTestFiles]"
    puts -nonewline $chanid "\tDOA:\t[llength $doaTestFiles]"
    puts -nonewline $chanid "\tMIA:\t[llength $miaTestFiles]"
    puts $chanid "\tFailed:\t[llength $failedTestFiles]"

    puts $chanid "\nPassed test suites:"
    foreach module $passedTestFiles {
	puts $chanid "\t$module"
    }

    puts $chanid "\nDOA test suites:"
    foreach module $doaTestFiles {
	puts $chanid "\t$module"
    }

    puts $chanid "\nMIA test suites:"
    foreach module $miaTestFiles {
	puts $chanid "\t$module"
    }

    puts $chanid "\nFailed test suites:"
    foreach module $failedTestFiles {
	# It's possible to run into a situation where 0 tests passed and
	# 0 failed.  In this case, the module is marked as "failed", but
	# there are no test ids to report.

	if {[info exists failedTestIds($module)]} {
	    puts $chanid "\t$module ([llength $failedTestIds($module)])"
	    foreach testId $failedTestIds($module) {
		puts $chanid "\t\t$testId"
	    }
	} else {
	    puts $chanid "\t$module (0)"
	    puts $chanid "\t\tNo tests found?"
	}
    }

    return
}

# parseTestlog::saveState --
#
#	Save the summary from the parsing of the log file.  The summary is
#	copied to a new namespace.
#
# Arguments:
#	key		Unique identifier for storing the state of this
#			log report.
#
# Side Effects:
#	If an existing report exists with the same state key, it will be
#	overridden.
#
# Results:
#	None

proc parseTestLog::saveState {key} {
    variable failedTestFiles
    variable passedTestFiles
    variable miaTestFiles
    variable doaTestFiles
    variable failedTestIds

    # Force the key namespace into existence.
    namespace eval $key {
	variable failedTestFiles {}
	variable passedTestFiles {}
	variable miaTestFiles {}
	variable doaTestFiles {}

	# Failed test ids are stored in an array indexed by the module name

	variable failedTestIds
    }

    set ${key}::failedTestFiles $failedTestFiles
    set ${key}::passedTestFiles $passedTestFiles
    set ${key}::miaTestFiles $miaTestFiles
    set ${key}::doaTestFiles $doaTestFiles
    array set ${key}::failedTestIds [array get failedTestIds]

    return
}

# parseTestlog::multiReport --
#
#	Show the summary from the parsing of multiple log files.
#
# Arguments:
#	chanid		Channel on which to print the test summary.  If
#			not specified then results are printed to stdout.
#
# Side Effects:
#	Text will be dumped to the channel
#
# Results:
#	None

proc parseTestLog::multiReport {args} {
    if {[string length $args] == 0} {
	set chanid stdout
    } else {
	set chanid $args
    }

    set savedStates {}

    foreach child [namespace children] {
	lappend savedStates [namespace tail $child]
    }

    puts $chanid {
Test result matrix:

Key:  Passed = All tests passed without errors being detected
      Failed = One more more tests were reported to fail
      MIA    = Test suite did not report a summary line.  This is usually
               caused by a nonexistent test suite.
      DOA    = "make test" generated an error before it could report
               a test summary.  Usually caused by a crash in the test suite.

Platform totals by module:
==========================

	Passed	Failed	MIA	DOA}

    foreach state $savedStates {
	puts -nonewline $chanid "$state"
	puts -nonewline $chanid "\t[llength [set ${state}::passedTestFiles]]"
	puts -nonewline $chanid "\t[llength [set ${state}::failedTestFiles]]"
	puts -nonewline $chanid "\t[llength [set ${state}::miaTestFiles]]"
	puts -nonewline $chanid "\t[llength [set ${state}::doaTestFiles]]"
	puts $chanid ""
    }

    puts $chanid {
Number failed per module:
=========================

Host		Module		#Failed	Reason}

    foreach state $savedStates {
	puts $chanid "$state"
	foreach failedModule \
		[lsort -dictionary [set ${state}::failedTestFiles]] {
	    if {[info exists ${state}::failedTestIds($failedModule)]} {
		puts $chanid [format "\t\t%-16s%4d" $failedModule \
			[llength [set ${state}::failedTestIds($failedModule)]]]
	    } else {
		puts $chanid [format "\t\t%-16s%4d\tNone passed" \
			$failedModule 0]
	    }
	}
    }

    puts $chanid {

MODULE             Passed          Failed          DOA             MIA}

    # The last section of the report sorts the test results by module.
    # We need to get a list of all of the module names for each platform
    # and then prune out the duplicates.  We can't just use the list of
    # modules for a single platform because some modules are only built
    # on certain platforms.

    set allModuleNames {}
    foreach state $savedStates {
	eval lappend allModuleNames [set ${state}::failedTestFiles]
	eval lappend allModuleNames [set ${state}::passedTestFiles]
	eval lappend allModuleNames [set ${state}::doaTestFiles]
	eval lappend allModuleNames [set ${state}::miaTestFiles]
    }
    set allModuleNames [lsort -dictionary -unique $allModuleNames]

    foreach module $allModuleNames {
	array set token {
	    niece	WIN
	    zamora	LIN
	    weasel	SOL
	}

	puts -nonewline $chanid [format %-16s $module]
	foreach status "passed failed doa mia" {
	    puts -nonewline $chanid "||  "
	    foreach state $savedStates {
		if {[lsearch [set ${state}::${status}TestFiles] \
			$module] != -1} {
		    puts -nonewline $chanid [format %-4s $token($state)]
		} else {
		    puts -nonewline $chanid [format %-4s ""]
		}
	    }
	}
	puts $chanid ""
    }

    return
}
