# licparse.tcl --
#
#	Ajuba Solutions License Key Management.
#	This file implements the key parser functions.
#	Only this half of the system is needed at runtime.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# This is proprietary source code.
#
# RCS: @(#) $Id: licparse.tcl,v 1.3 2000/08/01 01:49:54 welch Exp $

package provide lic 1.1
package require lclient

# We need the encoding definitions in the licdata module

package require licdata 2.0
if {"$tcl_platform(platform)" == "windows"} {
    package require registry
}

namespace eval lic {

    # config - configuration flags

    variable config
	
    # char - The "characters" of the key are kept here during processing
    # i - The current index into this array
    
    variable char
    variable i
    	
    namespace export *

    # This message is displayed when the license key cannot
    # be located in the appropriate location.  It is assumed
    # at this point that this is the first time the user is
    # using TclPro.

    variable welcome
    if {[info exist projectInfo::versString]} {
	set VERS $projectInfo::versString
    } else {
	set VERS ""
    }
    if {[info exist projectInfo::baseVersion]} {
	set BASEVERS $projectInfo::baseVersion
    } else {
	set BASEVERS ""
    }

    set title(title,gui) "TclPro License Manager"
    set title(title,text) "TclPro License Manager"

    set welcome(title,gui) "Welcome!"
    set welcome(msg,gui,text) "Welcome!"
    set welcome(msg,dbg) [concat \
	    "Welcome to TclPro Debugger, and thank you for using " \
 	    "TclPro $VERS.  Your must enter a license key or enter the "\
 	    "name of a Ajuba Solutions License Server to continue.  Press the "\
 	    "\"Ok\" button to run TclPro License Manager now, " \
 	    "then restart TclPro Debugger."]
    set welcome(msg,gui) [concat \
	    "Welcome to TclPro Debugger, and thank you for using " \
 	    "TclPro $VERS.  Your must enter a license key or enter the "\
 	    "name of a Ajuba Solutions License Server to continue.  Press the "\
 	    "\"Ok\" button to run TclPro License Manager now, " \
 	    "then restart TclPro Debugger."]
    set welcome(msg,gui,lic) [concat \
	    "Welcome to TclPro, and thank you for using TclPro " \
	    "$VERS.  Please enter your license key below and press OK."]
    set welcome(msg,text) [concat \
	    "Welcome to %1\$s, and thank you for using TclPro " \
	    "$VERS.  Your license key or the name of a " \
	    "Ajuba Solutions License Server must be entered to " \
	    "continue.  Please start TclPro License Manager, enter the " \
	    "appropriate information when prompted, and then  " \
	    "restart %1\$s."]
    set welcome(msg,text,lic) [concat \
	    "Welcome to TclPro, and thank you for using TclPro " \
	    "$VERS.  "]
    set welcome(msg,gui,licok) [concat \
	    "At this time you have a valid license key or are " \
	    "able to successfully contact a license server.  Press " \
	    "the OK button to exit."]
    set welcome(msg,text,licok) [concat \
	    "At this time you have a valid license key or are " \
	    "able to successfully contact a license server.  " \
	    "Would you like to either enter a new license key " \
	    "or a new license server name? \[y/n\] \[y\]:"]
    set welcome(msg,text,lic,options) [format "\n%s%s%s%s%s"  \
	    "Please select from one of the options below:\n" \
 	    "  1. Enter your license key\n" \
	    "  2. Enter the name of a License Server\n" \
	    "  3. Quit.\n" \
	    "Select \[\"1\", \"2\", or \"3\"\]: "]
    set welcome(msg,text,nolic,options) [format "\n%s%s%s%s"  \
	    "Please select from one of the options below:\n" \
	    "  1. Enter the name of a License Server\n" \
	    "  2. Quit.\n" \
	    "Select \[\"1\" or \"2\"\]: "]
    set welcome(msg,gui,lic,options) [concat \
	    "If you have a Named User License, enter your license key below.  " \
	    "The first time you enter a license key, you must also enter your " \
	    "user name, which is the name of the person who will be using this " \
	    "license."]
    set welcome(msg,text,lic,username) [concat \
	    "The first time you enter a license key, you must also enter your " \
	    "user name, which is the name of the person who will be using this " \
	    "license: "]
    set welcome(msg,gui,srv,options) [concat \
	    "Enter the host name and port of a Ajuba Solutions License Server. If " \
	    "you do not know this information, please contact your system " \
	    "administrator. Enter the information in the form \"host:port\" " \
	    "(for example, \"mars:2577\")."]
    set welcome(msg,gui,srv,toplevel) [concat \
	    "If you enter a valid Named User License, your TclPro applications " \
	    "will run using that license. Otherwise, your TclPro applications " \
	    "will attempt to obtain a Shared Network License from the Ajuba Solutions " \
	    "License Server specified below. If you do not have a valid license, " \
	    "you may purchase one from http://www.ajubasolutions.com/buy or obtain " \
	    "a free 15-day evaluation license from " \
	    "http://www.ajubasolutions.com/tclpro/eval."]
    set welcome(msg,gui,srv,describe-site) [concat \
	    "If you do not specify a Ajuba Solutions License Server in the field " \
	    "above, your TclPro applications will use the following host as a " \
	    "default Ajuba Solutions License Server:"]
    set welcome(msg,gui,srv,toplevel-site) [concat \
	    "Set the Default Ajuba Solutions License Server for this installation of " \
	    "TclPro.  All users running TclPro applications from this " \
	    "installation will by default obtain a Shared Network License from " \
	    "the Ajuba Solutions License Server specified below.  If you do not have " \
	    "a valid license, you may purchase one from " \
	    "http://www.ajubasolutions.com/buy or obtain a free 15-day evaluation " \
	    "license from http://www.ajubasolutions.com/tclpro/eval."]
    set welcome(msg,gui,srv,describe-site-site) [concat \
	    "Enter the host name and port of a Ajuba Solutions License Server.  " \
	    "Enter the information in the form \"host:port\" (for example, " \
	    "\"mars:2577\")."]
    set welcome(msg,text,lic,options,error) [concat \
	    "\"%s\" is not a valid selection.  "]
    set welcome(msg,text,short) ""
    set welcome(msg,gui,short) ""
    set welcome(msg,dbg,short) ""

    # This message is displayed when we start prolicense but the
    # user already has a 
    # at this point that this is the first time the user is
    # using TclPro.

    variable valid
    set valid(title,gui) "Thank you!"
    set valid(msg,base) [concat \
	    "Thank you for purchasing TclPro $VERS.  To find out the latest " \
	    "information about TclPro, please go to the Ajuba Solutions Web site " \
	    "at http://www.ajubasolutions.com."]
    set valid(msg,gui) $valid(msg,base)
    set valid(msg,dbg) $valid(msg,base)
    set valid(msg,gui,lic) [concat \
	    $valid(msg,base) \
	    "To enter a new license key or license server, please enter " \
	    "them above and press Apply."]
    set valid(msg,text) [concat \
	    $valid(msg,base)]
    set valid(msg,text,lic) [concat \
	    $valid(msg,base) \
	    "To enter a new license key, please enter the key below and " \
	    "press enter."]
    set valid(msg,gui,short) ""
    set valid(msg,text,short) ""

    # This message is displayed if the license key could not
    # be validated.  Reasons for failure could be a missing 
    # key, invalid key file, checksum failure, or a bad version
    # or product number.  The message below should general 
    # enough to reflect all of these cases.

    variable invalidKey
    set invalidKey(title,gui) "Sorry!"
    set invalidKey(msg,gui) [concat \
	    "We are sorry, but your license key is invalid.  A " \
	    "valid license key must be entered to continue."]
    set invalidKey(msg,dbg) [concat \
	    "We are sorry, but your license key is invalid.  A " \
	    "valid license key must be entered to continue."]
    set invalidKey(msg,gui,lic) [concat \
	    "We are sorry, but your license key is invalid.  " \
	    "Please enter a valid key and press OK."]
    set invalidKey(msg,text) [concat \
	    "We are sorry, but your license key is invalid.  To enter a " \
	    "valid license key, please start TclPro License Manager, " \
	    "enter the key when prompted, and then restart %1\$s."]
    set invalidKey(msg,text,lic) [concat \
	    "We are sorry, but your license key is invalid.  Please enter " \
	    "a valid license key and press enter."]
    set invalidKey(msg,text,short) ""
    set invalidKey(msg,gui,short) ""


    # This message is displayed if a verified key has a 
    # built-in expiration date.  Keys with a "never" 
    # expire date will not show this warning.

    variable expireWarning
    set expireWarning(title,gui) "Warning"
    set expireWarning(msg,gui) [concat \
	    "This evaluation copy of TclPro will expire on %1\$s.  Prior " \
	    "to the expiration date, please go to the Ajuba Solutions Web site " \
	    "at http://www.ajubasolutions.com/buy to purchase TclPro $VERS. "]
    set expireWarning(msg,dbg) [concat \
	    "This evaluation copy of TclPro will expire on %1\$s.  Prior " \
	    "to the expiration date, please go to the Ajuba Solutions Web site " \
	    "at <http://www.ajubasolutions.com/buy> to purchase TclPro $BASEVERS. "]
    set expireWarning(msg,gui,lic) [concat \
	    "This evaluation copy of TclPro will expire on %1\$s.  To " \
	    "upgrade the license for TclPro, please enter a new license " \
	    "key below and press OK."]
    set expireWarning(msg,text) [concat \
	    "This evaluation copy of TclPro will expire on %1\$s."]
    set expireWarning(msg,text,lic) [concat \
	    "This evaluation copy of TclPro will expire on %1\$s.  " \
	    "To upgrade the license for TclPro, please enter a new " \
	    "license key and press enter."]
    set expireWarning(msg,gui,short) ""
    set expireWarning(msg,text,short) ""

    variable tempKey
    set tempKey(title,gui) "Warning"
    set tempKey(msg,gui) [concat \
	    "The temporary license key just entered overrides an existing " \
	    "key that never expires.  Do you want to continue and install " \
	    "the temporary key?"]
    set tempKey(msg,gui,lic) $tempKey(msg,gui)
    set tempKey(msg,text) [concat \
	    "The temporary license key just entered overrides an existing " \
	    "key that never expires.  Do you want to continue and install " \
	    "the temporary key?  \[y/n\] \[n\]:"]
    set tempKey(msg,text,lic) $tempKey(msg,text)
    set tempKey(msg,gui,lic,short) ""
    set tempKey(msg,text,lic,short) $tempKey(msg,gui,lic,short)

    # This message is displayed when the key has expired.

    variable expired
    set expired(title,gui) "Sorry!"
    set expired(msg,gui) [concat \
	    "Thank you for evaluating TclPro $VERS, but this evaluation " \
	    "copy has expired, and can no longer be run.  " \
	    "To purchase TclPro $BASEVERS, please go to the " \
	    "Ajuba Solutions Web site at http://www.ajubasolutions.com/buy."]
    set expired(msg,dbg) [concat \
	    "Thank you for evaluating TclPro $VERS, but this evaluation " \
	    "copy has expired, and can no longer be run.  " \
	    "To purchase TclPro $BASEVERS, please go to the " \
	    "Ajuba Solutions Web site at <http://www.ajubasolutions.com/buy>."]
    set expired(msg,gui,lic) [concat \
	    "Thank you for evaluating TclPro $VERS, but this evaluation " \
	    "copy has expired, and can no longer be run.  " \
	    "To continue using this version of TclPro enter your " \
	    "purchased license key below and press OK."]
    set expired(msg,text) [concat \
	    "Thank you for evaluating TclPro $VERS, but this evaluation " \
	    "copy has expired, and can no longer be run.  " \
	    "To purchase TclPro $VERS, please go the the Ajuba Solutions " \
	    "Web site at http://www.ajubasolutions.com/buy."]
    set expired(msg,text,lic) [concat \
	    "Thank you for evaluating TclPro $VERS, but this evaluation " \
	    "copy has expired, and can no longer be run.  " \
	    "To continue using this version of TclPro enter your " \
	    "purchased license key and press enter."]
    set expired(title,gui) "Sorry!"
    set expired(msg,gui,short) ""
    set expired(msg,text,short) $expired(msg,gui,short)

    # This message is displayed when the license server could not be contacted

    variable noserver
    set noserver(title,gui) "Ajuba Solutions License Server Failure"
    set noserver(msg,gui) [concat \
	    "Ajuba Solutions License Server at \"%s\" is unavailable."]
    set noserver(msg,dbg) [concat \
	    "Ajuba Solutions License Server at \"%s\" is unavailable." \
	    "\n\nPossible causes include network difficulties or an" \
	    "incorrect server name or port."]
    set noserver(msg,gui,lic) $noserver(msg,gui)
    set noserver(msg,text) $noserver(msg,gui)
    set noserver(msg,text,lic) $noserver(msg,gui)
    set noserver(msg,gui,short) "Ajuba Solutions License Server at \"%s\" is unavailable."
    set noserver(msg,text,short) $noserver(msg,gui,short)

    # This message is displayed when the license server could not be contacted

    variable serverok
    set serverok(title,gui) "Ajuba Solutions License Server Success"
    set serverok(msg,gui) [concat \
	    "Ajuba Solutions License Server at \"%s\" is available and responding."]
    set serverok(msg,dbg) [concat \
	    "Ajuba Solutions License Server at \"%s\" is available and responding."]
    set serverok(msg,gui,lic) $serverok(msg,gui)
    set serverok(msg,text) $serverok(msg,gui)
    set serverok(msg,text,lic) $serverok(msg,gui)
    set serverok(msg,gui,short) $serverok(msg,gui) 
    set serverok(msg,text,short) $serverok(msg,gui)

    variable serveroverdraft
    set serveroverdraft(msg,gui) [concat \
	"Ajuba Solutions License Server at \"%s\" is in Overdraft status." \
	"You have exceeded the allowed number of concurrent users but" \
	"the server has granted a license anyway.\n\nYou have" \
	"%s overdraft days left."]
    set serveroverdraft(msg,dbg) [concat \
	"Ajuba Solutions License Server at \"%s\" is in Overdraft status." \
	"You have exceeded the allowed number of concurrent users but" \
	"this time the server has granted you a license for temporary" \
	"use.\n\nPlease contact your site administrator so that you are" \
	"ensured continuous access to TclPro in the future.\n\nYou have" \
	"%s overdraft days left."]
    set serveroverdraft(msg,text) $serveroverdraft(msg,gui)

    variable serverdenied
    set serverdenied(msg,gui) [concat \
	"Ajuba Solutions License Server at \"%s\" has no available licenses." \
	"You have exceeded the allowed number of concurrent users." ]
    set serverdenied(msg,dbg) $serverdenied(msg,gui)
    set serverdenied(msg,text) $serverdenied(msg,gui)

    variable prolicense
    set prolicense(title,gui) "Error"
    set prolicense(msg,dbg) [concat \
	    "The prolicense executable could not be located.\n"]
    
    set prolicense(msg,agree,gui) [concat \
	"BY CLICKING ON THE \"I ACCEPT\" BUTTON OR INSTALLING THE LICENSE KEY YOU " \
	"ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT (THIS " \
	"\"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, CLICK THE "  \
	"\"QUIT\" BUTTON AND DO NOT INSTALL THE LICENSE KEY.  If you have " \
	"purchased " \
	"the software, you should promptly return the software and you will " \
	"receive a refund of your money.  After installing the license key, you " \
	"can view a copy of this Agreement from the file \"license.txt\" in the " \
	"directory where the software was installed."]

    set prolicense(msg,agree,text) [concat \
	"BY TYPING \"ACCEPT\" OR INSTALLING THE LICENSE KEY YOU " \
	"ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT (THIS " \
	"\"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, TYPE \"QUIT\" "  \
	"AND DO NOT INSTALL THE LICENSE KEY.  If you have " \
	"purchased " \
	"the software, you should promptly return the software and you will " \
	"receive a refund of your money.  After installing the license key, you " \
	"can view a copy of this Agreement from the file \"license.txt\" in the " \
	"directory where the software was installed."]

    set messages(bad_serverPort) [concat \
	"\"%s\" is invalid. Please enter a string of the form \"host:port\" " \
	"where \"host\" is the name of a Ajuba Solutions License Server and \"port\" " \
	"is an integer (e.g., \"mars:2577\")."]
    set messages(bad_serverPort,short) [concat \
	"\"%s\" is invalid."]
    set messages(bad_registeredName,short) "UNREGISTERED"
    set messages(registered_to,short) \
	"This product is registered to the following user: %s"
}

# lic::configure --
#
#	Set debugging and site-wide flags.
#
# Arguments:
#	flag/value pairs
#
# Results:
#	None

proc lic::configure {args} {
    variable config
    if {[llength $args] == 0} {
	return [array get config]
    }
    array set config $args
}

# lic::keyTrim --
#
#	Trims away spaces, hyphens, and non-alphanumeric from the given key
#	string.  Also uppercases the entire key string.
#
# Arguments:
#	key	The key string to process.
#
# Results:
#	A string that conitain neither spaces, hyphens, nor non-alphanumeric
#	characters.

proc lic::keyTrim {key} {
    set key [string toupper $key]    
    regsub -all {[^A-Z0-9]} $key {} key
    return $key
}

# lic::formatKey --
#
#	Format the key string, so the a "-" separates every 4th char.
#
# Arguments:
#	key
#
# Results:
#	Return the formatted string.

proc lic::formatKey {key} {
    set s ""
    set j 0
    foreach c [split [keyTrim $key] {}] {
	if {($j > 0) && (($j % 4) == 0)} {
	    append s -
	}
	append s $c
	incr j
    }
    return $s
}

# lic::parseServerHost --
#
#	Parses the given string and verifies whether it conforms to the
#	"host:port" (where port is an integer) syntax.
#
# Arguments:
#	parseServerHost	The server string to process.
#
# Results:
#	Returns 1 if the string contains is of the valid form, 0 otherwise.

proc lic::serverParse {serverPortStr} {
    return [regexp {[^:]+:[0-9]} $serverPortStr]
}

# lic::getMsg --
#
#	Construst a message based on the status of the license key,
#	the license key itself, and the expiration date.
#
# Arguments:
#	type	The type of message to construct (gui or text)
#	key	The key to use for constructing the message.  Possibly null.
#	msgVar	The variable to set the message into.
#
# Results:
#	Returns status of the license key:
# 		ok means the license is valid and will never expire.
# 		warnTempKey means the license is valid but will expire.
#		warnOverdraft means the license server is in overdraft
# 		errorInvalid means the license has expired or is invalid.
#		errorNoKey means the license is missing.
#		errorNoServer means the license server is unavailable
#		errorDenied means the license server is over the limit

proc lic::getMsg {type key msgVar productName registeredNameVar} {
    upvar 1 $msgVar msg $registeredNameVar registeredName

    set status [getPersonalKey $type $key msg]
    set registeredName [GetCompany $lic::messages(bad_registeredName,short)]
    if {$status == "ok"} {
	# Use this valid, never expires, personal key
	return $status
    }
	
    # We may still decide to use a temporary key, so save state about it

    set state(key,status) $status
    set state(key,msg) $msg
    set state(key,name) $registeredName

    # Look for the license server in the local registry or prefs file.

    if {![catch {getKeyServerLocal} info]} {
	set status [ContactServer $info $type msg registeredName]
	if {$status == "ok"} {
	    return $status
	}
	set state(myServer,status) $status
	set state(myServer,msg) $msg
	set state(myServer,name) $registeredName
    }

    # Now look for the license server based on the site-wide file.

    set info [getKeyServerSite]
    if {[string length [join $info ""]] != 0} {

	set status [ContactServer $info $type msg registeredName]
	if {$status == "ok"} {
	    return $status
	}
	set state(siteServer,status) $status
	set state(siteServer,msg) $msg
	set state(siteServer,name) $registeredName
    }

    # Use a temporary key if we have one

    foreach source {key myServer siteServer} {
	if {![info exist state($source,status)]} {
	    continue
	}
	if {[string match warn* $state($source,status)]} {
	    set msg $state($source,msg)
	    set registeredName $state($source,name)
	    return $state($source,status)
	}
    }

    # Return the "best" error message

    foreach source {myServer siteServer key} {
	if {![info exist state($source,status)]} {
	    continue
	}
	set msg $state($source,msg)
	set registeredName $state($source,name)
	return $state($source,status)
    }

    # Assert we cannot get here because state(key,status) is defined
}


# lic::probe --
#
#	Construst a message based on the status of the license key,
#	the license key itself, and the expiration date.  Tests the
#	existance of the license server if a local key is invalid or
#	non-existent.
#
# Arguments:
#	type		The type of message to construct (gui or text)
#	keyVar		The in/out key variable.
#			If null, key is fetched from disk.
#	keyMsgVar	The variable to set the key status message into.
#	srvVar		The in/out server location variable.
#			If null, info fetched from disk.
#	srvMsgVar	The variable to set the server local status message into.
#	srvSiteVar	The in/out server site location variable.
#			If null, info fetched from disk.
#	srvSiteMsgVar	The variable to set the server site status message into.
#
# Results:
#	Nothing.

proc lic::probe {type companyVar
		 keyVar	     keyStatusVar      keyMsgVar
		 srvVar      srvStatusVar      srvMsgVar
		 srvSiteVar  srvSiteStatusVar  srvSiteMsgVar} {
    variable noserver
    variable serverok

    upvar 1 $companyVar		company		\
	    $keyVar		key		\
	    $keyStatusVar	keyStatus	\
	    $keyMsgVar		keyMsg		\
	    $srvVar		srvInfo		\
	    $srvMsgVar		srvMsg		\
	    $srvStatusVar	srvStatus	\
	    $srvSiteVar		srvSiteInfo	\
	    $srvSiteMsgVar	srvSiteMsg	\
	    $srvStatusVar	srvSiteStatus

    set keyMsg ""
    set srvMsg ""
    set srvSiteMsg ""

    set company [GetCompany]

    if {[string length $key] == 0} {
        set key [GetKey]
    }

    set keyStatus [getPersonalKey $type $key keyMsg]

    set keyMsg [string trim $keyMsg]

    # Look for the license server in the local registry or prefs file

    if {[string length [join $srvInfo ""]] == 0} {
	if {[catch {getKeyServerLocal} srvInfo]} {
	    set srvStatus $srvInfo
	    set srvInfo ""
	}
    }
    if {[string length [join $srvInfo ""]] != 0} {
	if {[catch {lclient::probe $srvInfo [info hostname]} error]} {
	    set srvMsg [format $noserver(msg,$type) \
		    "[lindex $srvInfo 0]:[lindex $srvInfo 1]" $error]
	    set srvStatus errorNoServer
	} else {
	    set srvMsg [format $serverok(msg,$type) \
		    "[lindex $srvInfo 0]:[lindex $srvInfo 1]"]
	    set srvStatus ok
	}
    }

    # Look for the license server in the site location.

    if {[string length [join $srvSiteInfo ""]] == 0} {
	if {[catch {getKeyServerSite} srvSiteInfo]} {
	    set srvSiteStatus $srvSiteInfo
	    set srvSiteInfo ""
	}
    }
    if {[string length [join $srvSiteInfo ""]] != 0} {
	if {[catch {lclient::probe $srvSiteInfo [info hostname]} error]} {
	    set srvSiteMsg [format $noserver(msg,$type) \
		    "[lindex $srvSiteInfo 0]:[lindex $srvSiteInfo 1]" $error]
	    set srvSiteStatus errorNoServer
	} else {
	    set srvSiteMsg [format $serverok(msg,$type) \
		    "[lindex $srvSiteInfo 0]:[lindex $srvSiteInfo 1]"]
	    set srvSiteStatus ok
	}
    }

    return
}

# lic::getPersonalKey --
#
#	Construst a message based on the status of the license key,
#	the license key itself, and the expiration date.
#
# Arguments:
#	type	The type of message to construct (gui or text)
#	key	The key to use for constructing the message.  Possibly null.
#	msgVar	The variable to set the message into.
#
# Results:
#	Returns the status of the license key (see getMsg)
#	Calls licdata::init if a null key was passed

proc lic::getPersonalKey {type key msgVar} {
    upvar 1 $msgVar msg
    variable welcome
    variable invalidMsg
    variable expired
    variable expireWarning
    variable valid
    variable invalidKey

    set prod $projectInfo::productID
    set ver  $projectInfo::versString

    if {$key == {}} {
	licdata::init $ver
        set key [GetKey]
	if {[string length $key] == 0} {
	    # A key doesn't exist, assume this is the initial startup.

	    set msg $welcome(msg,$type)
	    return errorNoKey
	}
    }

    if {[catch {set status [lic::verify $prod $ver expSec $key]} err]} {
	# An error occured while verifying the key.  Show the 
	# error message explaining why.

	if {$err == "missingKey"} {
	    # A key doesn't exist, assume this is the initial startup.

	    set msg $welcome(msg,$type)
	    return errorNoKey
	} else {
	    # The key was invalid.

	    set msg $invalidKey(msg,$type)
	    append msg "\n\nInvalid Key: [lic::formatKey $key]"
	    return errorInvalid
	}
    } elseif {$status == -1} {
	# The license has expired.
	
	set time [clock format $expSec -format "%B %d, %Y"]
	set msg $expired(msg,$type)
	append msg "\n\nLicense Key: [lic::formatKey $key]"
	append msg "\nExpired: $time"
	return errorInvalid
    } elseif {$status == 1} {
	# The license has yet to expire but will someday.

	set time [clock format $expSec -format "%B %d, %Y"]
	set msg [format $expireWarning(msg,$type) $time]
	append msg "\n\nLicense Key: [lic::formatKey $key]"
	append msg "\nExpires: $time"
	return warnTempKey
    } else {
	# The license never expires.

	set msg $valid(msg,$type)
	append msg "\n\nLicense Key: [lic::formatKey $key]"
	append msg "\nExpires: Never"
	return ok
    }
}

# lic::ContactServer --
#
#	Construst a message based on the status of the license key,
#	the license key itself, and the expiration date.
#
# Arguments:
#	info	Server manager location information
#	type	The type of message to construct (gui or text)
#	msgVar	The variable to set the message into.
#
# Results:
#	Returns the status of the license key (see getMsg)

proc lic::ContactServer {srvinfo type msgVar registeredNameVar} {
    upvar 1 $msgVar msg $registeredNameVar registeredName
    global env tcl_platform

    set registeredName "(no company registration)"

    set prod $projectInfo::productID
    set ver  $projectInfo::versString
    set appname [list [file tail [info nameofexecutable]] $ver]
    if {[info exist tcl_platform(user)]} {
	set user $tcl_platform(user)
    } elseif {[info exist env(LOGNAME)]} {
	set user $env(LOGNAME)
    } elseif {[info exist env(USER)]} {
	set user $env(USER)
    } else {
	set user tclprouser@[info hostname]
    }

    set result [lclient::checkout $srvinfo $prod $user \
		    [info hostname] $appname]
    set status [lindex $result 0]
    set arg [lindex $result 1]

    # Defining the company name is a side effect of checkout

    if {[info exist ::lclient::appinfo(org)]} {
	set registeredName $::lclient::appinfo(org)
    }
    switch -glob -- $status {
	ok {
	    variable serverok
	    set msg [format $serverok(msg,$type) \
		    "[lindex $srvinfo 0]:[lindex $srvinfo 1]"]
	}
	errorDenied {
	    variable serverdenied
	    set msg [format $serverdenied(msg,$type) \
		    "[lindex $srvinfo 0]:[lindex $srvinfo 1]"]
	}
	errorInvalid {
	    variable expired
	    set msg $expired(msg,$type)\n
	    append msg "License Server [lindex $srvinfo 0]:[lindex $srvinfo 1]"
	}
	error* -
	errorNoServer {
	    variable noserver
	    set msg [format $noserver(msg,$type) \
		    "[lindex $srvinfo 0]:[lindex $srvinfo 1]"]
	}
	warnOverdraft {
	    variable serveroverdraft
	    set msg [format $serveroverdraft(msg,$type) \
		    "[lindex $srvinfo 0]:[lindex $srvinfo 1]" $arg]
	}
	warn* -
	warnTempKey {
	    variable expireWarning
	    set msg [format $expireWarning(msg,$type) $arg]
	    append msg "\n\nLicense Server: [lindex $srvinfo 0]:[lindex $srvinfo 1]"
	    append msg "\nKey Expires: $arg"
	}
    }
    return $status
}

# lic::verify --
#
#	Retrieve the license key and verify it.
#
# Arguments:
#	prodid		The product ID number, which is used to
#			differentiate beta from final releases.
#	version		The product version number, N.N[ab.]N
#	varName		pass-by-name for the expire time.
#	key		The license key to verify.  If null this
#			routine will goto the file system and
#			retrieve the key.
#
# Results:
#	Return 1 if the version is still valid, 0 if the version 
#	never expires and -1 if the version has expired.  The 
#	expiration date is stored in varName.
#	Otherwise the following errors are raised:
#		missingKey
#		badKey
#		invalidFile
#		checksumFailed
#		oldVersion
#		wrongVersion	(beta, not final)

proc lic::verify {prodid version varName {key {}}} {
    upvar $varName expires
    licdata::init $version

    if {$key == {}} {
	set key [lic::GetKey]
        if {[string length $key] == 0} {
            error "missingKey"
        }
    }
    array set keyFields [lic::parsekey $key]

    # make sure product ID's match

    if {$keyFields(prodid) != $prodid} {
	error "wrongVersion"
    }

    # Make sure it isn't a network license key

    if {![string match 1* $key]} {
	error "wrongKeyType"
    }

    # Test date stamps

    if {[string compare $keyFields(expires) "never"] == 0} {
	set expires "never"
	return 0
    }

    set expires [clock scan $keyFields(expires)]
    if {$expires < [clock seconds]} {
	return -1
    } else {
	return 1
    }
}

# lic::parsekey --
#
#	Extract the fields from a key and verify its checksum
#
# Arguments:
#	key		The human-readable form of the key
#
# Results:
#	A list of alternating name value items that describe the key fields
#	This raises an error if the key checksum fails

proc lic::parsekey {key} {
    global ::licdata::size

    licdata::unpack $key
    set keytype [licdata::getInt $size(K)]
    switch $keytype {
	1 {
	    set custid  [licdata::getInt $size(C)]
	    set prodid  [licdata::getInt $size(P)]
	    set version [licdata::getInt $size(V1)].[licdata::getInt $size(V2)]
	    append version .[licdata::getInt $size(V3)]
	    set month   [licdata::getInt $size(M)]
	    set day     [licdata::getInt $size(D)]
	    set year    [licdata::getInt $size(Y)]
	    if {$month == 13 && $day == 33 && $year == 3915} {
		set date "never"
	    } else {
		set date [format "%02d" $month]/[format "%02d" $day]/$year

		# sanity check against forged keys

		if {[catch {
		    clock scan $date	
		}]} {
		    error invalidKey
		}
	    }
	    return [list custid $custid prodid $prodid version $version \
		    expires $date]
	}
	2 {
	    #set stringx  [licdata::getInt $size(SX)]
	    set seats  [licdata::getInt $size(ST)]
	    set prodid  [licdata::getInt $size(P)]
	    set version [licdata::getInt $size(V1)].[licdata::getInt $size(V2)]
	    set patch [licdata::getInt $size(V3)]
	    set release [licdata::getInt $size(R)]
	    array set map {0 a 1 b 2 .}
	    if {![info exist map($release)]} {
		error invalidKey
	    }
	    append version $map($release)$patch
	    set month   [licdata::getInt $size(M)]
	    set day     [licdata::getInt $size(D)]
	    set year    [licdata::getInt $size(Y)]
	    if {$month == 13 && $day == 33 && $year == 3915} {
		set date "never"
	    } else {
		set date [format "%02d" $month]/[format "%02d" $day]/$year

		# sanity check against forged keys

		if {[catch {
		    clock scan $date	
		}]} {
		    error invalidKey
		}
	    }
	    return [list seats $seats prodid $prodid \
		    version $version expires $date]
	}
	default {
	    error invalidKey
	}
    }
}

