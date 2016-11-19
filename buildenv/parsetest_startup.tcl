package require parsetest 1.0

set hostCount 0

if {[llength $argv] > 1} {
    foreach testLog $argv {
	set testLog $testLog
	if {![regexp {test-([a-z]+)-.*} $testLog null hostName]} {
	    set hostName host$hostCount
	}
	incr hostCount

	parseTestLog::init

	parseTestLog::parse $testLog

	parseTestLog::saveState $hostName
    }

    parseTestLog::multiReport
} else {
    set infile $argv
    parseTestLog::init

    parseTestLog::parse $infile

    set outputFile $infile.summary
    set chanId [open $outputFile w]
    parseTestLog::report $chanId
    close $chanId

    parseTestLog::report
}
