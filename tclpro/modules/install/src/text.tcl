# text.tcl --
# 
#	This file contains the top-level script for the TclPro UNIX
#	installation application.
# 
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: text.tcl,v 1.8 2001/02/08 21:38:43 welch Exp $

package require Tclx

namespace eval textSetup {
    variable platformInfo
    variable componentInfo
    variable installComponents
    variable installPlatforms
    variable installDir
    variable serverInstallDir
    variable serverLogDir
    variable serverPort
    variable serverUser
    variable serverGroup
}

# textSetup::isWholeNum --
#
#	Verifies that the given value is a non-negative integer.
#
# Arguments:
#	value		The string to test.
#
# Results:
#	Returns 1 if the value is a whole number.

proc textSetup::isWholeNum {value} {
    if {[catch {incr value 0}] || ($value < 0)} {
	return 0
    } else {
	return 1
    }
}

# textSetup::format70ColumnLine --
#
#	Formats the given string to be of multiple lines, with each line no
#	longer than 70 characters.
#
# Arguments:
#	string		The long string to format into several lines.
#
# Results:
#	The formatted line, with embedded "\n" characters to break the lines
#	accordingly.

proc textSetup::format70ColumnLine {prompt} {
    set formattedPrompt ""
    set formattedLine ""
    foreach word [split $prompt] {
	if {[expr {[string length $formattedLine] \
		+ [string length $word]}] > 70} {
	    append formattedPrompt "$formattedLine\n"
	    set formattedLine ""
	}
	append formattedLine "$word "
    }
    append formattedPrompt $formattedLine
    return $formattedPrompt
}

# textSetup::selectItems --
#
#	This function displays a menu of choices and prompts the user
#	to select one or more items from the menu.  If there is only
#	one item in the list, then it will be returned immediately without
#	prompting the user.
#
# Arguments:
#	items		A list of items and descriptions.
#	header		The text to display before the menu.
#	prompt		The initial prompt to display.
#	default		The default item or items to select.
#	onlyOne		If set to 0, multiple choices are allowed, otherwise
#			only one item may be selected.
#
# Results:
#	Returns the list of items chosen.

proc textSetup::selectItems {items header prompt default {onlyOne 0}} {
    if {[llength $items] == 2} {
	return [lindex $items 0]
    }

    puts "[textSetup::format70ColumnLine $header]\n"

    set index 0
    set choices {}
    foreach {item description} $items {
	puts "[incr index]. $description"
	lappend choices $index
    }
    puts ""
    set done 0
    while {!$done} {
	getStdInput $prompt choice 0 0 $default
	if {$onlyOne} {
	    set prompt "$::MENU_TTY_ONLYONE"
	} else {
	    set prompt "$::MENU_TTY_MULTI"
	}
	if {[catch {llength $choice} numChoices]} {
	    continue
	}
	if {$onlyOne && $numChoices != 1} {
	    continue
	}
	set done 1
	foreach i $choice {
	    if {[lsearch -exact $choices $i] == -1} {
		set done 0
		break
	    }
	}
    }
    set result {}
    foreach i $choice {
	lappend result [lindex $items [expr {($i-1)*2}]]
    }
    return $result
}


# textSetup::getDirectory --
#
#	Prompt the user for a directory, creating a new one if necessary.
#
# Arguments:
#	prompt	The prompt to display.
#	default	The default directory to show.
#
# Results:
#	Returns the chosen directory.

proc textSetup::getDirectory {prompt default} {
    while {1} {
	getStdInput $prompt var 1 0 $default
        if {[file pathtype $var] == "relative"} {
	    puts [format "$::DEST_DIR_ENTER_REL_PATH\n" $var]
	} elseif {![file exists $var]} {
	    getStdInput "$::DEST_DIR_TTY_NOTEXIST" createDir 1 0 "y"
	    if {$createDir} {	                               
	        if {[catch {file mkdir $var} errMsg]} {
		    puts "$errMsg.\n"
		} else {
		    break
		}
	    }
	} elseif {![file writable $var]} {
	    puts "$::DEST_DIR_NO_WRITE_PERMISSION\n"
        } else {
	    break
        }
    }
    return $var
}

# textSetup::getStdInput --
#
#	Prompts the user at standard-input for a 
#
# Arguments:
#	prompt		The prompt the user should see.
#	varName		A variable name that will hold the entered result.
#	minStrLen	The minimum string length the user should enter.
#	fileMustExist	If the entry is a for a file name, setting this to 1
#			will automatically test for the file's existance.
#			This value defaults to 0 if not provided.
#	defaultValue	If this value is non-empty, it will appear as part of
#			the prompt, and will be the value of the response if
#			if the user simply presses ENTER.  If this default
#			value is not specified no default value is offered.
#
# Results:
#	None.  The variable referenced by 'varName' is updated with either
#	the user's input or the default value, if one is provided.

proc textSetup::getStdInput {prompt varName minStrLen \
	{fileMustExist 0} {defaultValue ""}} {
    lappend putsCommand puts
    lappend putsCommand -nonewline
    lappend putsCommand stdout
    if {[string length $defaultValue]} {
        set prompt "$prompt \[\"$defaultValue\"]"
    }
    set prompt "$prompt:"
    set formattedPrompt [textSetup::format70ColumnLine $prompt]
    lappend putsCommand $formattedPrompt
    while {1} {
	eval $putsCommand
	flush stdout
	set input [gets stdin]
	if {![string length $input] &&
	    [string length $defaultValue]} {
	    set input $defaultValue
	} elseif {[string length $input] < $minStrLen} {
	    puts "ERROR: Your input must be at least $minStrLen character(s). - Retry."
	    continue
	}
	if {$fileMustExist && ![file exist $input]} {
	    puts "ERROR: The file \"$input\" does not exist. - Retry."
	    continue
	} else {
	    upvar $varName vName
	    set vName $input
	    break
	}
    }

    puts -nonewline "\n"
    return
}


# textSetup::setupLogProc --
#
#	Prints a string to stdout and wipes it out on the next call and 
#	replaces it with the newly provided string.
#
# Arguments:
#	logString	String to dump to stdout.
#
# Results:
#	None.

proc textSetup::setupLogProc {logString} {
    variable installDir
    global prevLogString

    if {![info exists prevLogString]} {
	set prevLogString ""
    }
    set values [split $logString :]
    set logString [string trim [lindex $values 1]]
    if {[string match ${installDir}/* $logString]} {
	set action [string trim [lindex $values 0]]
	set file [string range $logString [string length ${installDir}/] end]
	set logString "$action $file"
    } elseif {[string match "creating ${installDir}/*" $logString]} {
	set index [string length "creating ${installDir}/"]
	set logString  "creating [string range $logString $index end]"
    } elseif {[string match "Patching ${installDir}/*" $logString]} {
	set index [string length "Patching ${installDir}/"]
	set logString  "patching [string range $logString $index end]"
    }

    puts -nonewline $prevLogString
    puts -nonewline $logString
    flush stdout

    regsub -all .? $logString "\b \b" prevLogString
}

# textSetup::TclProLicense --
#
#	Display the TclPro license and prompt the user to accept.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProLicense {} {
    # Display the license terms and ask if they agree.
    # Extract the license from the wrapped application.
    # Write the contents to the file system, and then 
    # exec "more" on the temp file to display the license
    # terms.

    set file [open $::LICENSE_TXT r]
    set data [read $file]
    close $file
    
    if {[catch {
	set moreComplete 0
	set fileName "/tmp/temp[pid].txt"
	set temp [open $fileName w]
	puts $temp $data
	close $temp
	exec more $fileName 2>@stderr >@stdout <@stdin
	set moreComplete 1
	file delete $fileName
    }]} {
	if {!$moreComplete} {
	    puts $data
	}
    }

    puts "\n"
    puts "[format70ColumnLine $::LICENSE_TTY_TERMS]\n"
    getStdInput "$::LICENSE_TTY_AGREE" agree 0
    while {$agree != $::LICENSE_AGREE_STR && $agree != $::LICENSE_QUIT_STR} {
	getStdInput "$::LICENSE_TTY_LOOP" agree 0
    }
    
    if {$agree == $::LICENSE_QUIT_STR} {
	exit
    }
    return
}

# textSetup::TclProPlatform --
#
#	Prompt the user to select one or more of the available platforms.
#	If only one platform is available, the user is not prompted.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProPlatform {} {
    variable installPlatforms
    variable platformInfo

    # Get the list of platforms.  Make the current platform be the default
    # choice.

    set platforms [install::getPlatforms $::installImageRoot]
    array set platformInfo $platforms
    set index 1
    set default 1
    foreach {platform descr} $platforms {
	if {$platform == $::tclproPlatform} {
	    set default $index
	    break
	}
	incr index
    }
    set installPlatforms [selectItems $platforms \
	    $::PLATFORM_TTY $::PLATFORM_TTY_CHOOSE $default]
    return
}

# textSetup::TclProComponents --
#
#	Prompt the user to select one or more of the available
#	components. If only one component is available, the user
#	is not prompted.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProComponents {} {
    variable installComponents
    variable installPlatforms
    variable componentInfo

    # Display the list of components based on the specified platforms.

    # change the formatted text of the components to include the
    # disk requirements

    set components {}
    set max 0
    foreach {comp desc} [install::getComponents $::installImageRoot \
	    $installPlatforms] {

	# Find the longest description

	set l [string length $desc]
	if {$l > $max} {
	    set max $l
	}
    }

    foreach {comp desc} [install::getComponents $::installImageRoot \
	    $installPlatforms] {
	set size [install::componentSize $comp $installPlatforms]
	lappend components $comp \
		[format "%-*s   %6d k" $max $desc $size]
    }

    array set componentInfo $components

    set installComponents [selectItems $components \
	    $::COMPONENT_TTY $::COMPONENT_TTY_CHOOSE "1 2"]

    return
}

# textSetup::TclProDestination --
#
#	Prompt the user to select a destination directory.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProDestination {} {
    variable installDir

    # Prompt the user to enter the parent of the TclPro installation
    # directory.  Attempt to create the TclPro directory and continue
    # prompting until successful creation.

    set installDir [getDirectory $::DEST_DIR_CHOOSE $::DEFTCLPRODIR]
    return
}

# textSetup::TclProReady --
#
#	Display the list of components that are about to be installed
#	and prompt the user before continuing.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProReady {} {
    variable installPlatforms
    variable installComponents
    variable platformInfo
    variable componentInfo
    variable installDir

    # give user one more chance to bail the installation.

    set first 1
    set count 0
    set platforms {}
    foreach plat $installPlatforms {
	incr count
	if {$first} {
	    append platforms "$platformInfo($plat)\n"
	    set first 0
	} else {
	    append platforms "\t\t\t$platformInfo($plat)\n"
	}	    
    }
    # count must be at least 1
    if {$count == 1} {
	set platformPlurality " "
    } else {
	set platformPlurality "s"
    }

    set first 1
    set count 0
    set components {}
    foreach comp $installComponents {
	incr count
	if {$first} {
	    append components "$componentInfo($comp)\n"
	    set first 0
	} else {
	    append components "\t\t\t$componentInfo($comp)\n"
	}	    
    }
    # count must be at least 1
    if {$count == 1} {
	set componentPlurality " "
    } else {
	set componentPlurality "s"
    }

    puts [format $::INSTALL_TTY_READY $platforms $installDir $components \
	    $platformPlurality $componentPlurality]
    textSetup::getStdInput $::INSTALL_TTY_READY_PROMPT dummy 0
    return
}


# textSetup::TclProInstall --
#
#	Install the selected platforms/components.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProInstall {} {
    variable installPlatforms
    variable installComponents
    variable installDir
    global installImageRoot
    
    # Open the log file and begin the installation.


    if {[catch {
	install::installPro $installImageRoot $installDir \
		textSetup::setupLogProc $installPlatforms $installComponents
    } msg]} {
	set message [format $::INSTALL_ERROR $msg]
	puts "\n\n$message"
	catch {setup::openLogFile $installDir}
	catch {setup::writeLogFile "\n$message\n"}
	catch {setup::closeLogFile}
	exit
    }

    # Clear the output line and close the log file.

    textSetup::setupLogProc ""
    return
}

# textSetup::TclProInstallKey --
#
#	Ask the user if they want to install a named user key.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProInstallKey {} {
    variable installDir
    variable installPlatforms
    variable installComponents

    # Don't install a key unless the tools were installed on this platform.

    if {([lsearch $installComponents common] == -1) \
	    || ([lsearch $installPlatforms $::tclproPlatform] == -1)} {
	return
    }

    puts "\n[format70ColumnLine $::INSTALL_TTY_KEY]\n"
    textSetup::getStdInput "$::INSTALL_TTY_KEY_PROMPT" installLicense 1 0 "y"
    if {[string tolower [string index $installLicense 0]] == "y"} {
	catch {
	    # Invoke "prolicensetty".
            exec [file join $installDir \
		    $::tclproPlatform bin $::TCLPRO_LICENSETTY] -nolicense \
		    2>@stderr >@stdout <@stdin
	} errMsg
    }
    return
}

# textSetup::TclProFinish --
#
#	Indicate that the installation is done that that the user
#	can return to the installation menu
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::TclProFinish {} {
    variable installDir

    regsub "%PATH%" $::INSTALL_TTY_DONE \
	    [file join $installDir $::tclproPlatform bin] doneMsg

    puts "\n[format70ColumnLine $doneMsg]\n"
    textSetup::getStdInput "$::INSTALL_TTY_DONE_PROMPT" dummy 0
    return
}

# textSetup::SharedHostPort --
#
#	Collect the host and port information for a site install.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::SharedHostPort {} {
    variable installDir
    variable installPlatforms
    variable installComponents

    # Don't install a key unless the tools were installed on this platform.

    if {([lsearch $installComponents common] == -1)} {
	return
    }

    puts "[format70ColumnLine $::SHARED_GUI_HOST_PORT]\n"
    getStdInput $::SHARED_HOST_TTY serverHost 0 0 [info hostname]
    while {1} {
	getStdInput $::SHARED_PORT_TTY serverPort 0 0 $::DEFAULT_SHARED_PORT
	if {![isWholeNum $serverPort]} {
	    puts "$::SHARED_BAD_PORT"
	} else {
	    break
	}
    }
    install::saveLicenseFile $serverHost $serverPort $installDir
    return
}

# textSetup::ServerUserGroup --
#
#	Collect the user and group id information.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerUserGroup {} {
    variable serverUser
    variable serverGroup

    puts "[format70ColumnLine $::SERVER_USER_GROUP_TTY]\n"
    while {1} {
	getStdInput $::SERVER_USER_TTY serverUser 0 0 $::DEFSERVERUID
	if {![catch {id convert user $serverUser} id] \
		|| ![catch {id convert userid $serverUser} id]} {
	    set user $id
	    break
	}
	puts "$id\n$::SERVER_BAD_USER_TTY"
    }
    while {1} {
	getStdInput $::SERVER_GROUP_TTY serverGroup 0 0 $::DEFSERVERGID
	if {![catch {id convert group $serverGroup} id] \
		|| ![catch {id convert groupid $serverGroup} id]} {
	    set group $id
	    break
	}
	puts "$id\n$::SERVER_BAD_GROUP_TTY"
    }
    return
}

# textSetup::ServerPort --
#
#	Get the server port.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerPort {} {
    variable serverPort

    puts "[format70ColumnLine $::SHARED_GUI_HOST_PORT]\n"

    while {1} {
	getStdInput $::SHARED_PORT_TTY serverPort 0 0 $::DEFSERVERPORT
	if {![isWholeNum $serverPort]} {
	    puts "$::SHARED_BAD_PORT"
	} else {
	    break
	}
    }
    return
}


# textSetup::ServerDirs --
#
#	Query for the server installation directories.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerDirs {} {
    variable serverInstallDir
    variable serverLogDir

    # Prompt the user to enter the parent of the TclPro installation
    # directory.  Attempt to create the TclPro directory and continue
    # prompting until successful creation.

    set serverInstallDir [getDirectory $::SERVER_INSTALL_DIR_CHOOSE \
	    $::DEFSERVERDIR]
    set serverLogDir [getDirectory $::SERVER_LOG_DIR_CHOOSE \
	    $::DEFSERVERLOGDIR]
    return
}

# textSetup::ServerReady --
#
#	Indicate
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerReady {} {
    variable serverInstallDir
    variable serverLogDir
    variable serverPort
    variable serverUser
    variable serverGroup

    puts [format $::INSTALL_SERVER_TTY_READY $serverInstallDir \
	    $serverLogDir $serverUser $serverGroup $serverPort]
    textSetup::getStdInput $::INSTALL_TTY_READY_PROMPT dummy 0
    return
}

# textSetup::ServerInstall --
#
#	Install the server.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerInstall {} {
    variable serverInstallDir
    variable serverLogDir
    variable serverPort
    variable serverUser
    variable serverGroup
    
    puts [install::installServer $::installImageRoot \
	    $serverInstallDir $serverLogDir \
	    $serverUser $serverGroup $serverPort]
    return
}

# textSetup::ServerFinish --
#
#	Indicate that the installation is done that that the user
#	can return to the installation menu
#
# Arguments:
#	None.
#
# Results:
#	None.

proc textSetup::ServerFinish {} {
    variable installDir
    variable serverInstallDir
    variable serverPort

    puts ""
    getStdInput "$::INSTALL_SERVER_TTY_DONE_PROMPT" start 1 0 "y"
    if {$start} {
	if {[catch {
	    set pid [exec [file join $serverInstallDir ${::SERVER_EXE}] \
		    start &]
	} msg]} {
	    puts "Error starting server: $msg"
	} else {
	    puts "Server PID: $msg"
	}
    }
    puts ""
    puts "\n[format70ColumnLine $::INSTALL_SERVER_TTY_DONE]"
    puts "\n\t[file join [file nativename $serverInstallDir] $::SERVER_EXE]"

    set url [format "http://%1\$s:%2\$s" [info hostname] $serverPort]

    puts "\n[format70ColumnLine $::INSTALL_SERVER_TTY_HTTP]\n"
    puts "\n\t$url\n"
    textSetup::getStdInput $::PRESS_ENTER_CONTINUE dummy 0

    return
}

proc textSetup::start {} {
    global installImageRoot
    variable installDir
    # Display the Welcome messages.

    puts "[textSetup::format70ColumnLine $::WELCOME_TTY]\n"
    #puts "[textSetup::format70ColumnLine $::WELCOME_WARNING]\n"
    #puts "[textSetup::format70ColumnLine $::WELCOME_LAWYER]\n"
    #textSetup::getStdInput $::PRESS_ENTER_CONTINUE dummy 0

    # Build the menu list.

    lappend menu tclpro $::SINGLE
    if {[install::hasServer $::installImageRoot $::tclproPlatform]} {
	regsub -all "\n" $::SHARED { } shared
	lappend menu server $shared
    }
    if {[install::hasAcrobat $::installImageRoot $::tclproPlatform]} {
	lappend menu acrobat $::ACROBAT
    }
    lappend menu quit $::QUIT_BUT


    # calculate file sizes & file counts now
    install::calculateSizeAndCount $::installImageRoot


    set first 1
    while {1} {
	# If the menu's length is four, we only have the TclPro install files.
	# Skip displaying the menu and jump right to the TclPro install.  If
	# this is the second iteration of an install woth only one option, 
	# simply exit, otherwise loop providing alternative install options.

	if {([llength $menu] == 4) && ($first)} {
	    set choice tclpro
	} elseif {[llength $menu] == 4} {
	    set choice quit
	} else {
	    set choice [selectItems $menu \
		    $::MAIN_MENU_TTY $::MENU_TTY_CHOOSE 1 1]
	}
	set first 0

	switch $choice {
	    quit {
		exit
	    }
	    tclpro {
		TclProDestination
		TclProPlatform
		TclProComponents
		TclProReady
		TclProInstall
		TclProFinish
	    }
	    server {
		set serverMenu [list \
			tclpro $::TCLPRO \
			server $::SERVER]
		set choice [selectItems $serverMenu \
			"$::SHARED_MENU_TTY\n$::SHARED_MENU_NOTE" \
			$::MENU_TTY_CHOOSE 1 1]
		switch $choice {
		    tclpro {
			TclProPlatform
			TclProComponents
			TclProDestination
			TclProReady
			TclProInstall
			SharedHostPort
			TclProFinish
		    }
		    server {
			ServerUserGroup
			ServerPort
			ServerDirs
			ServerReady
			ServerInstall
			ServerFinish
		    }
		}
	    }
	    acrobat {
		puts "$::INSTALL_TTY_ACROBAT"
		install::installAcrobat $::installImageRoot $::tclproPlatform
		puts "\n"
	    }
	}
    }

    # Never reaches here
    return
}
