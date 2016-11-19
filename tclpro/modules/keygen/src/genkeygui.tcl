# genkeygui.tcl --
#
#	This script can be used to manually generate a new license key for
#	TclPro.  IT SHOULD NOT BE SHIPPED WITH THE PRODUCT IN ANY WAY.
#	To use this script run wish on this script in this directory.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: genkeygui.tcl,v 1.2 2000/10/31 23:31:17 welch Exp $

if {![info exist tcl_platform(isWrapped)]} {

    # non-wrapped case

    source [file join [file dirname [info script]] .. projectInfo projectInfo.tcl]
    source [file join [file dirname [info script]] .. license licdata.tcl]
    source [file join [file dirname [info script]] licgen.tcl]
    source [file join [file dirname [info script]] .. license licparse.tcl]
} else {

    # wrapped case

    source [file join lib projectInfo1.4 projectInfo.tcl]
    source [file join lib license1.4 licdata.tbc]
    source [file join lib license1.4 licparse.tbc]
    source licgen.tcl
}

# createInterface --
#
#	Create the simple interface for generating new keys by hand.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc createInterface {} {
    # Create widgets
    message .m -text "License Key generator for $projectInfo::versString.  The \
	    product Id & Version are preset to match the current version.  \
	    The customer  1 = eng testing, 2 = special eval promo.  The \
	    expire key is the date it expires or 0 for never expires."
    label .prodL -text "Product Id" -justify right
    entry .prodE
    global CustLabel
    label .custL -textvar CustLabel -justify right
    set CustLabel "Customer Id"
    entry .custE
    label .versL -text "TclPro Version" -justify right
    entry .versE
    label .expireL -text "Expire Date" -justify right
    entry .expireE

    frame .con
    global NetLicense
    set NetLicense 0
    checkbutton .con.net -text "Net License" -variable NetLicense \
	-command TweakGui
    TweakGui
    button .con.b1 -text "Gen key" -command "generateNewKey"
    button .con.b2 -text "Gen never-key" -command "generateNewKey never"
    button .con.b3 -text "Gen 15 day key" -command "generateNewKey 15" 
    button .con.b4 -text "Gen old key" -command "generateNewKey old"
    label .newL -text "New Key"
    entry .newE -width 30
    label .data -text ""

    # Layout all the widgets
    grid .m -columnspan 2 -sticky we
    grid .prodL .prodE 
    grid .custL .custE 
    grid .versL .versE 
    grid .expireL .expireE
    pack .con.net .con.b1 .con.b2 .con.b3 .con.b4 -side left
    grid .con -columnspan 2 
    grid .newL .newE
    grid .data -columnspan 2 
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1

    # Populate the defaults
    .prodE insert 0 $projectInfo::productID
    .custE insert 0 1
    .versE insert 0 $projectInfo::versString
    set oneWeek [expr {[clock seconds] + (7 * 24 * 60 * 60)}]
    .expireE insert 0 [clock format $oneWeek -format "%D"]
}

# TweakGui
#
#	Change the state depending on license or personal key
#	This is called from the NetLicense checkbutton command.
#

proc TweakGui {args} {
    global CustLabel NetLicense
    if {$NetLicense} {
	set CustLabel "Num Seats"
    } else {
	set CustLabel "Customer Id"
    }
}

# generateNewKey --
#
#	Generate a new key based on the given information.
#
# Arguments:
#	opt	May be "never", "15", "old" or nothing.
#
# Results:
#	None.

proc generateNewKey {{opt {}}} {
    global NetLicense
    set custid [.custE get]
    set prodid [.prodE get]
    set version [.versE get]
    set expire [.expireE get]
    if {$opt == "15"} {
	# Make expire date 15 days out
	set expire [clock scan "15 days"]
    } elseif {$opt == "old"} {
	# Gen an expired key
	set expire [clock scan "5 days ago"]
    } elseif {$opt == "never"} {
	# Gen a never key
	set expire 0
    } else {
	if {$expire != 0} {
	    set expire [clock scan $expire]
	}
    }

    if {$NetLicense} {
	set result [licgen::gennetkey $custid $prodid $version $expire]
    } else {
	set result [licgen::genkey $custid $prodid $version $expire]
    }
    .newE delete 0 end
    .newE insert 0 "$result"
    .data configure -text [lic::parsekey $result]
}

# Main script
createInterface
