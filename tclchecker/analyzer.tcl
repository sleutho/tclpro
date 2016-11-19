# analyzer.tcl --
#
#	This file initializes the analyzer.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: analyzer.tcl,v 1.13 2000/10/31 23:30:53 welch Exp $

package provide analyzer 1.0
namespace eval analyzer {

    namespace export \
	    addCheckers addUserProc addWidgetOptions checkBoolean \
	    checkArgList checkScript checkBody checkChannelID checkColor \
	    checkCommand checkConfigure checkContext checkEvalArgs  \
	    checkExpr checkFileName checkFloatConfigure checkIndex \
	    checkIndexExpr checkInt checkFloat checkKeyword checkList \
	    checkListValues checkNamespacePattern checkOption \
	    checkWidgetOptions checkRedefined checkVariable checkWholeNum \
	    checkSimpleArgs checkSwitches checkVarName checkProcName \
	    checkProcCall checkWinName checkWord \
            getLiteral getLiteralPos getScript getTokenRange isLiteral \
	    getLiteralRange checkNumArgs checkVersion checkSwitchArg \
	    logError matchKeyword pushChecker popChecker setCmdRange \
            topChecker init

    # The twopass var is set to 1 when Checker should scan for
    # user defined procs, otherwise it will only analyze files
    # skipping the scan and collate phases.

    variable twoPass 1
    
    # The quiet var is set to 1 when the message should
    # print a minimal amount of output.

    variable quiet 0

    # The verbose var is set to 1 when we want to print summary
    # information.

    variable verbose 0

    # True if the current phase is scanning.
    
    variable scanning 0

    # Stores the set of command-specific checkers currently defined
    # for the global context.

    variable checkers
    array set checkers {}

    # Stores the set of commands to be scanned for proc definitions.
    # (e.g., proc, namespace eval, and class)
    variable scanCmds
    array set scanCmds {}

    # Store a list of known widget option checkers.  For example, a 
    # -background option should always use "checkColor"

    array set standardWidgetOpts {
	-activebackground checkColor
	-activeforeground checkColor
	-activerelief checkRelief
	-anchor {checkKeyword 0 {n ne e se s sw w nw center}}
	-background checkColor
	-bd checkPixels
	-bg checkColor
	-bigincrement checkFloat
	-borderwidth checkPixels
	-class checkWord
	-closeenough checkFloat
	-colormap checkColormap
	-command checkBody
	-confine checkBoolean
	-container checkBoolean
	-cursor checkCursor
	-default {checkKeyword 1 {normal active disabled}}
	-digits checkInt
	-disabledforeground checkColor
	-elementborderwidth checkPixels
	-exportselection checkBoolean
	-fg checkColor
	-font checkWord
	-foreground checkColor
	-from checkFloat
	-height checkPixels
	-highlightbackground checkColor
	-highlightcolor checkColor
	-highlightthickness checkPixels
	-image checkWord
	-indicatoron checkBoolean
	-insertbackground checkColor
	-insertborderwidth checkPixels
	-insertofftime checkInt
	-insertontime checkInt
	-insertwidth checkPixels
	-jump checkBoolean
	-justify {checkKeyword 0 {left center right}}
	-label checkWord
	-length checkPixels
	-menu checkWinName
	-offvalue checkWord
	-onvalue checkWord
	-orient {checkKeyword 0 {horizontal vertical}}
	-padx checkPixels
	-pady checkPixels
	-relief checkRelief
	-repeatdelay checkInt
	-repeatinterval checkInt
	-resolution checkFloat
	-scrollcommand checkWord
	-scrollregion {checkListValues 4 4 {checkPixels}}
	-selectbackground checkColor
	-selectborderwidth checkPixels
	-selectcolor checkColor
	-selectforeground checkColor
	-selectimage checkWord
	-selectmode {checkKeyword 1 {single browse multiple extended}}
	-setgrid checkBoolean
	-show checkWord
	-showvalue checkBoolean
	-sliderlength checkPixels
	-sliderrelief checkRelief
	-spacing1 checkPixels
	-spacing2 checkPixels
	-spacing3 checkPixels
	-takefocus checkWord
	-text checkWord
	-textvariable checkVarName
	-tickinterval checkFloat
	-to checkFloat
	-troughcolor checkColor
	-underline checkInt
	-value checkWord
	-variable checkVarName
	-width checkPixels
	-wrap {checkKeyword 1 {char none word}}
	-wraplength checkPixels
	-xscrollcommand checkWord
	-xscrollincrement checkPixels
	-yscrollcommand checkWord
	-yscrollincrement checkPixels
    }

    # Colors are only portable if they are defined in the tk?.?/xlib/xcolors.c
    # file.  The portableColors8.0 is the list of colors that are valid for
    # Tk8.0.  For now this is the only version checked.

    variable portableColors80 [list \
	"alice blue" "AliceBlue" "antique white" "AntiqueWhite" "AntiqueWhite1" \
	"AntiqueWhite2" "AntiqueWhite3" "AntiqueWhite4" "aquamarine" \
	"aquamarine1" "aquamarine2" "aquamarine3" "aquamarine4" "azure" \
	"azure1" "azure2" "azure3" "azure4" "beige" "bisque" "bisque1" \
	"bisque2" "bisque3" "bisque4" "black" "blanched almond" \
	"BlanchedAlmond" "blue" "blue violet" "blue1" "blue2" "blue3" "blue4" \
	"BlueViolet" "brown" "brown1" "brown2" "brown3" "brown4" "burlywood" \
	"burlywood1" "burlywood2" "burlywood3" "burlywood4" "cadet blue" \
	"CadetBlue" "CadetBlue1" "CadetBlue2" "CadetBlue3" "CadetBlue4" \
	"chartreuse" "chartreuse1" "chartreuse2" "chartreuse3" "chartreuse4" \
	"chocolate" "chocolate1" "chocolate2" "chocolate3" "chocolate4" "coral" \
	"coral1" "coral2" "coral3" "coral4" "cornflower blue" "CornflowerBlue" \
	"cornsilk" "cornsilk1" "cornsilk2" "cornsilk3" "cornsilk4" "cyan" \
	"cyan1" "cyan2" "cyan3" "cyan4" "dark blue" "dark cyan" \
	"dark goldenrod" "dark gray" "dark green" "dark grey" "dark khaki" \
	"dark magenta" "dark olive green" "dark orange" "dark orchid" "dark red" \
	"dark salmon" "dark sea green" "dark slate blue" "dark slate gray" \
	"dark slate grey" "dark turquoise" "dark violet" "DarkBlue" "DarkCyan" \
	"DarkGoldenrod" "DarkGoldenrod1" "DarkGoldenrod2" "DarkGoldenrod3" \
	"DarkGoldenrod4" "DarkGray" "DarkGreen" "DarkGrey" "DarkKhaki" \
	"DarkMagenta" "DarkOliveGreen" "DarkOliveGreen1" "DarkOliveGreen2" \
	"DarkOliveGreen3" "DarkOliveGreen4" "DarkOrange" "DarkOrange1" \
	"DarkOrange2" "DarkOrange3" "DarkOrange4" "DarkOrchid" "DarkOrchid1" \
	"DarkOrchid2" "DarkOrchid3" "DarkOrchid4" "DarkRed" "DarkSalmon" \
	"DarkSeaGreen" "DarkSeaGreen1" "DarkSeaGreen2" "DarkSeaGreen3" \
	"DarkSeaGreen4" "DarkSlateBlue" "DarkSlateGray" "DarkSlateGray1" \
	"DarkSlateGray2" "DarkSlateGray3" "DarkSlateGray4" "DarkSlateGrey" \
	"DarkTurquoise" "DarkViolet" "deep pink" "deep sky blue" "DeepPink" \
	"DeepPink1" "DeepPink2" "DeepPink3" "DeepPink4" "DeepSkyBlue" \
	"DeepSkyBlue1" "DeepSkyBlue2" "DeepSkyBlue3" "DeepSkyBlue4" "dim gray" \
	"dim grey" "DimGray" "DimGrey" "dodger blue" "DodgerBlue" "DodgerBlue1" \
	"DodgerBlue2" "DodgerBlue3" "DodgerBlue4" "firebrick" "firebrick1" \
	"firebrick2" "firebrick3" "firebrick4" "floral white" "FloralWhite" \
	"forest green" "ForestGreen" "gainsboro" "ghost white" "GhostWhite" \
	"gold" "gold1" "gold2" "gold3" "gold4" "goldenrod" "goldenrod1" \
	"goldenrod2" "goldenrod3" "goldenrod4" "gray" "gray0" "gray1" "gray10" \
	"gray100" "gray11" "gray12" "gray13" "gray14" "gray15" "gray16" \
	"gray17" "gray18" "gray19" "gray2" "gray20" "gray21" "gray22" "gray23" \
	"gray24" "gray25" "gray26" "gray27" "gray28" "gray29" "gray3" "gray30" \
	"gray31" "gray32" "gray33" "gray34" "gray35" "gray36" "gray37" "gray38" \
	"gray39" "gray4" "gray40" "gray41" "gray42" "gray43" "gray44" "gray45" \
	"gray46" "gray47" "gray48" "gray49" "gray5" "gray50" "gray51" "gray52" \
	"gray53" "gray54" "gray55" "gray56" "gray57" "gray58" "gray59" "gray6" \
	"gray60" "gray61" "gray62" "gray63" "gray64" "gray65" "gray66" "gray67" \
	"gray68" "gray69" "gray7" "gray70" "gray71" "gray72" "gray73" "gray74" \
	"gray75" "gray76" "gray77" "gray78" "gray79" "gray8" "gray80" "gray81" \
	"gray82" "gray83" "gray84" "gray85" "gray86" "gray87" "gray88" "gray89" \
	"gray9" "gray90" "gray91" "gray92" "gray93" "gray94" "gray95" "gray96" \
	"gray97" "gray98" "gray99" "green" "green yellow" "green1" "green2" \
	"green3" "green4" "GreenYellow" "grey" "grey0" "grey1" "grey10" \
	"grey100" "grey11" "grey12" "grey13" "grey14" "grey15" "grey16" \
	"grey17" "grey18" "grey19" "grey2" "grey20" "grey21" "grey22" "grey23" \
	"grey24" "grey25" "grey26" "grey27" "grey28" "grey29" "grey3" "grey30" \
	"grey31" "grey32" "grey33" "grey34" "grey35" "grey36" "grey37" "grey38" \
	"grey39" "grey4" "grey40" "grey41" "grey42" "grey43" "grey44" "grey45" \
	"grey46" "grey47" "grey48" "grey49" "grey5" "grey50" "grey51" "grey52" \
	"grey53" "grey54" "grey55" "grey56" "grey57" "grey58" "grey59" "grey6" \
	"grey60" "grey61" "grey62" "grey63" "grey64" "grey65" "grey66" "grey67" \
	"grey68" "grey69" "grey7" "grey70" "grey71" "grey72" "grey73" "grey74" \
	"grey75" "grey76" "grey77" "grey78" "grey79" "grey8" "grey80" "grey81" \
	"grey82" "grey83" "grey84" "grey85" "grey86" "grey87" "grey88" "grey89" \
	"grey9" "grey90" "grey91" "grey92" "grey93" "grey94" "grey95" "grey96" \
	"grey97" "grey98" "grey99" "honeydew" "honeydew1" "honeydew2" \
	"honeydew3" "honeydew4" "hot pink" "HotPink" "HotPink1" "HotPink2" \
	"HotPink3" "HotPink4" "indian red" "IndianRed" "IndianRed1" \
	"IndianRed2" "IndianRed3" "IndianRed4" "ivory" "ivory1" "ivory2" \
	"ivory3" "ivory4" "khaki" "khaki1" "khaki2" "khaki3" "khaki4" \
	"lavender" "lavender blush" "LavenderBlush" "LavenderBlush1" \
	"LavenderBlush2" "LavenderBlush3" "LavenderBlush4" "lawn green" \
	"LawnGreen" "lemon chiffon" "LemonChiffon" "LemonChiffon1" \
	"LemonChiffon2" "LemonChiffon3" "LemonChiffon4" "light blue" \
	"light coral" "light cyan" "light goldenrod" "light goldenrod yellow" \
	"light gray" "light green" "light grey" "light pink" "light salmon" \
	"light sea green" "light sky blue" "light slate blue" \
	"light slate gray" \
	"light slate grey" "light steel blue" "light yellow" "LightBlue" \
	"LightBlue1" \
	"LightBlue2" "LightBlue3" "LightBlue4" "LightCoral" "LightCyan" \
	"LightCyan1" "LightCyan2" "LightCyan3" "LightCyan4" "LightGoldenrod" \
	"LightGoldenrod1" "LightGoldenrod2" "LightGoldenrod3" \
	"LightGoldenrod4" \
	"LightGoldenrodYellow" "LightGray" "LightGreen" "LightGrey" \
	"LightPink" \
	"LightPink1" "LightPink2" "LightPink3" "LightPink4" "LightSalmon" \
	"LightSalmon1" "LightSalmon2" "LightSalmon3" "LightSalmon4" \
	"LightSeaGreen" "LightSkyBlue" "LightSkyBlue1" "LightSkyBlue2" \
	"LightSkyBlue3" "LightSkyBlue4" "LightSlateBlue" "LightSlateGray" \
	"LightSlateGrey" "LightSteelBlue" "LightSteelBlue1" "LightSteelBlue2" \
	"LightSteelBlue3" "LightSteelBlue4" "LightYellow" "LightYellow1" \
	"LightYellow2" "LightYellow3" "LightYellow4" "lime green" "LimeGreen" \
	"linen" "magenta" "magenta1" "magenta2" "magenta3" "magenta4" \
	"maroon" \
	"maroon1" "maroon2" "maroon3" "maroon4" "medium aquamarine" \
	"medium blue" "medium orchid" "medium purple" "medium sea green"  \
	"medium slate blue" "medium spring green" "medium turquoise" \
	"medium violet red" "MediumAquamarine" "MediumBlue" "MediumOrchid" \
	"MediumOrchid1" "MediumOrchid2" "MediumOrchid3" "MediumOrchid4" \
	"MediumPurple" "MediumPurple1" "MediumPurple2" "MediumPurple3" \
	"MediumPurple4" "MediumSeaGreen" "MediumSlateBlue" \
	"MediumSpringGreen" \
	"MediumTurquoise" "MediumVioletRed" "midnight blue" "MidnightBlue" \
	"mint cream" "MintCream" "misty rose" "MistyRose" "MistyRose1" \
	"MistyRose2" "MistyRose3" "MistyRose4" "moccasin" "navajo white" \
	"NavajoWhite" "NavajoWhite1" "NavajoWhite2" "NavajoWhite3" \
	"NavajoWhite4" "navy" "navy blue" "NavyBlue" "old lace" "OldLace" \
	"olive drab" "OliveDrab" "OliveDrab1" "OliveDrab2" "OliveDrab3" \
	"OliveDrab4" "orange" "orange red" "orange1" "orange2" "orange3" \
	"orange4" "OrangeRed" "OrangeRed1" "OrangeRed2" "OrangeRed3" \
	"OrangeRed4" "orchid" "orchid1" "orchid2" "orchid3" "orchid4" \
	"pale goldenrod" "pale green" "pale turquoise" "pale violet red" \
	"PaleGoldenrod" "PaleGreen" "PaleGreen1" "PaleGreen2" "PaleGreen3" \
	"PaleGreen4" "PaleTurquoise" "PaleTurquoise1" "PaleTurquoise2" \
	"PaleTurquoise3" "PaleTurquoise4" "PaleVioletRed" "PaleVioletRed1" \
	"PaleVioletRed2" "PaleVioletRed3" "PaleVioletRed4" "papaya whip" \
	"PapayaWhip" "peach puff" "PeachPuff" "PeachPuff1" "PeachPuff2" \
	"PeachPuff3" "PeachPuff4" "peru" "pink" "pink1" "pink2" "pink3" \
	"pink4" \
	"plum" "plum1" "plum2" "plum3" "plum4" "powder blue" "PowderBlue" \
	"purple" "purple1" "purple2" "purple3" "purple4" "red" "red1" "red2" \
	"red3" "red4" "rosy brown" "RosyBrown" "RosyBrown1" "RosyBrown2" \
	"RosyBrown3" "RosyBrown4" "royal blue" "RoyalBlue" "RoyalBlue1" \
	"RoyalBlue2" "RoyalBlue3" "RoyalBlue4" "saddle brown" "SaddleBrown" \
	"salmon" "salmon1" "salmon2" "salmon3" "salmon4" "sandy brown" \
	"SandyBrown" "sea green" "SeaGreen" "SeaGreen1" "SeaGreen2" \
	"SeaGreen3" \
	"SeaGreen4" "seashell" "seashell1" "seashell2" "seashell3" \
	"seashell4" \
	"sienna" "sienna1" "sienna2" "sienna3" "sienna4" "sky blue" "SkyBlue" \
	"SkyBlue1" "SkyBlue2" "SkyBlue3" "SkyBlue4" "slate blue" "slate gray" \
	"slate grey" "SlateBlue" "SlateBlue1" "SlateBlue2" "SlateBlue3" \
	"SlateBlue4" "SlateGray" "SlateGray1" "SlateGray2" "SlateGray3" \
	"SlateGray4" "SlateGrey" "snow" "snow1" "snow2" "snow3" "snow4" \
	"spring green" "SpringGreen" "SpringGreen1" "SpringGreen2" \
	"SpringGreen3" \
	"SpringGreen4" "steel blue" "SteelBlue" "SteelBlue1" "SteelBlue2" \
	"SteelBlue3" "SteelBlue4" "tan" "tan1" "tan2" "tan3" "tan4" "thistle" \
	"thistle1" "thistle2" "thistle3" "thistle4" "tomato" "tomato1" \
	"tomato2" "tomato3" "tomato4" "turquoise" "turquoise1" "turquoise2" \
	"turquoise3" "turquoise4" "violet" "violet red" "VioletRed" \
	"VioletRed1" "VioletRed2" "VioletRed3" "VioletRed4" "wheat" "wheat1" \
	"wheat2" "wheat3" "wheat4" "white" "white smoke" "WhiteSmoke" \
	"yellow" \
	"yellow green" "yellow1" "yellow2" "yellow3" "yellow4" "YellowGreen"]

    variable commonCursors [list \
	    "X_cursor" "arrow" "based_arrow_down" "based_arrow_up" "boat" \
	    "bogosity" "bottom_left_corner" "bottom_right_corner" \
	    "bottom_side" "bottom_tee" "box_spiral" "center_ptr" "circle" \
	    "clock" "coffee_mug" "cross" "cross_reverse" "crosshair" \
	    "diamond_cross" "dot" "dotbox" "double_arrow" "draft_large" \
	    "draft_small" "draped_box" "exchange" "fleur" "gobbler" "gumby" \
	    "hand1" "hand2" "heart" "icon" "iron_cross" "left_ptr" \
	    "left_side" "left_tee" "leftbutton" "ll_angle" "lr_angle" "man" \
	    "middlebutton" "mouse" "pencil" "pirate" "plus" "question_arrow" \
	    "right_ptr" "right_side" "right_tee" "rightbutton" "rtl_logo" \
	    "sailboat" "sb_down_arrow" "sb_h_double_arrow" "sb_left_arrow" \
	    "sb_right_arrow" "sb_up_arrow" "sb_v_double_arrow" "shuttle" \
	    "sizing" "spider" "spraycan" "star" "target" "tcross" \
	    "top_left_arrow" "top_left_corner" "top_right_corner" "top_side" \
	    "top_tee" "trek" "ul_angle" "umbrella" "ur_angle" "watch" "xterm"
    ]

    variable winCursors [list \
	    "starting" "no" "size" "size_ne_sw" "size_ns" "size_nw_se" \
	    "size_we" "uparrow" "wait"
    ]

    variable macCursors [list \
	    "text" "cross-hair"
    ]

}

# analyzer::init --
#
#	Initialize the analyzer. This will set all global variables
#       to their respective initial value.
#
# Arguments:
#       None.
#
# Results:
#	None.

proc analyzer::init {} {
    # Records the number of errors detected.

    variable errCount 0

    # Records the number of warnings detected.

    variable warnCount 0

    # Records the name of the file being analyzed.

    variable file {}

    # Records the script currently being analyzed.
    
    variable script {}

    # Records the line number of the command currently being analyzed.

    variable currentLine 1

    # Records the range of the command currently being analyzed.

    variable cmdRange {}

    # Stores a stack of command range and line number pairs.

    variable cmdStack {}

    # Store a list of commands that need to be renamed within
    # a given context.

    variable inheritCmds 
    catch "unset inheritCmds"
    array set inheritCmds {}

    # Store a list of commands that need to be renamed within
    # a given context.

    variable renameCmds 
    catch "unset renameCmds"
    array set renameCmds {}

    # Store a list of patterns for commands that need to be exported
    # from a namespace.

    variable exportCmds 
    catch "unset exportCmds"
    array set exportCmds {}

    # Store a list of patterns for commands that need to be imported
    # from a namespace.

    variable importCmds 
    catch "unset importCmds"
    array set importCmds {}

    # Store a list of commands that were executed but did not 
    # exists in the user-defined proc list or the globally 
    # defined proc list.

    variable unknownCmds {}

    # Reset other internal variables
    catch {unset ::context::knownContext}
    array set ::context::knownContext {}

    catch {unset ::uproc::userProc}
    array set ::uproc::userProc {}

    catch {unset ::uproc::userProcCount}
    array set ::uproc::userProcCount {}
}

# analyzer::setTwoPass --
#
#	Set the twoPass bit to 1 or 0 depending on the type
#	of checking requested from the user.
#
# Arguments:
#	twoPassBit	Boolean.  Indicates if output should be terse.
#
# Results:
#	None.

proc analyzer::setTwoPass {twoPassBit} {
    set analyzer::twoPass $twoPassBit
    return
}

# analyzer::isTwoPass --
#
#	Return the setting for the twoPass bit.
#
# Arguments:
#	None.
#
# Results:
#	Return 1 if we are in twoPass mode.

proc analyzer::isTwoPass {} {
    return $analyzer::twoPass
}

# analyzer::setQuiet --
#
#	Set the quiet bit to 1 or 0 depending on the type
#	of output requested from the user.
#
# Arguments:
#	quietBit	Boolean.  Indicates if output should be terse.
#
# Results:
#	None.

proc analyzer::setQuiet {quietBit} {
    set analyzer::quiet $quietBit
    return
}

# analyzer::getQuiet --
#
#	Return the setting for the quiet bit.
#
# Arguments:
#	None.
#
# Results:
#	Return 1 if we are in quiet mode.

proc analyzer::getQuiet {} {
    return $analyzer::quiet
}

# analyzer::setVerbose --
#
#	Set the verbose bit to 1 or 0 depending on the type
#	of output requested from the user.
#
# Arguments:
#	verboseBit	Boolean.  Indicates if summary info should print.
#
# Results:
#	None.

proc analyzer::setVerbose {verboseBit} {
    set analyzer::verbose $verboseBit
    return
}

# analyzer::getVerbose --
#
#	Return the setting for the verbose bit.
#
# Arguments:
#	None.
#
# Results:
#	Return 1 if we are in verbose mode.

proc analyzer::getVerbose {} {
    return $analyzer::verbose
}

# analyzer::getErrorCount --
#
#	Returns the number of errors that occured during the check.
#
# Arguments:
#	None.
#
# Results:
#	The number of errors.

proc analyzer::getErrorCount {} {
    return $analyzer::errCount
}

# analyzer::getWarningCount --
#
#	Returns the number of warnings that occured during the check.
#
# Arguments:
#	None.
#
# Results:
#	The number of warnings.

proc analyzer::getWarningCount {} {
    return $analyzer::warnCount
}

# analyzer::getFile --
#
#	Retrieve the current file name.
#
# Arguments:
#	None.
#
# Results:
#	Returns the current file name.

proc analyzer::getFile {} {
    return $::analyzer::file
}

# analyzer::getScript --
#
#	Retrieve the current script contents.
#
# Arguments:
#	None.
#
# Results:
#	Returns the current script string.

proc analyzer::getScript {} {
    return $::analyzer::script
}

# analyzer::getLine --
#
#	Retrieve the current line number.
#
# Arguments:
#	None.
#
# Results:
#	Returns the current line number.

proc analyzer::getLine {} {
    return $::analyzer::currentLine
}

# analyzer::getCmdRange --
#
#	Retrieve the current command range.
#
# Arguments:
#	None.
#
# Results:
#	Returns the current command range.

proc analyzer::getCmdRange {} {
    return $::analyzer::cmdRange
}

# analyzer::getTokenRange --
#
#	Extract the token's range from the token list.
#
# Arguments:
#	token	A token list.
#
# Results:
#	Returns the range of the token.

proc analyzer::getTokenRange {token} {
    return [lindex $token 1]
}

# analyzer::setCmdRange --
#
#	Set the anchor at the beginning of the given range.
#
# Arguments:
#	range	Range to set anchor before.
#
# Results:
#	None.  Updates the current line counter.

proc analyzer::setCmdRange {range} {
    if {[lindex $range 0] < [lindex $::analyzer::cmdRange 0]} {
	incr ::analyzer::currentLine -[parse countnewline $::analyzer::script \
	    $range $::analyzer::cmdRange]
    } else {
	incr ::analyzer::currentLine [parse countnewline $::analyzer::script \
		$::analyzer::cmdRange $range]
    }
    set ::analyzer::cmdRange $range
    return
}

# analyzer::pushCmdInfo --
#
#	Save the current command information on a stack.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc analyzer::pushCmdInfo {} {
    set ::analyzer::cmdStack [linsert $::analyzer::cmdStack 0 \
	    [list $::analyzer::cmdRange $::analyzer::currentLine]]
    return
}

# analyzer::popCmdInfo --
#
#	Restore a previously saved command info.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc analyzer::popCmdInfo {} {
    set top [lindex $::analyzer::cmdStack 0]
    set ::analyzer::cmdRange [lindex $top 0]
    set ::analyzer::currentLine [lindex $top 1]
    set ::analyzer::cmdStack [lrange $::analyzer::cmdStack 1 end]
    return
}

# analyzer::addWidgetOptions --
#
#	Add common widget options to the list of known widget options.  The 
#	checkWidgetOptions checker uses the contents of this list to check
#	common options.
#
# Arguments:
#	optChkList	A list of "standard" widget options and the 
#			checker associated with the option.
#
# Results:
#	None.

proc analyzer::addWidgetOptions {optChkList} {
    array set analyzer::standardWidgetOpts $optChkList
}

# analyzer::check --
#
#	Main routine that pre-scans, collates data, checks
#	the files and displays summary information.
#
# Arguments:
#	files	The files to be checked.
#
# Results:
#	None.

proc analyzer::check {files} {

    if {[analyzer::isTwoPass]} {
	# Phase I - Scan the files and compile a list of procs to
	#	        check, handle namespaces and handle classes.
	
	set files [analyzer::scan $files]
	
	# Phase II - Collate the namespace imports/exports and class data.
	
	analyzer::collate
    }

    # Phase III - Check each file specified on the command line.  
	
    analyzer::analyze $files
    
    # If the verbose flag was set, print the summary info.
    
    if {[analyzer::getVerbose]} {
	message::showSummary
    }
}

# analyzer::isScanning --
#
#	Return true if the Checker is in the initial scanning phase.
#
# Arguments:
#	None.
#
# Results:
#	Boolean, 1 if the Checker is currently scanning all scripts.

proc analyzer::isScanning {} {
    return $analyzer::scanning
}

# analyzer::scan --
#
#	Scan the list of files, searching for all user-defined
#	procedures, class definitions and namespace imports/exports.
#
# Arguments:
#	files	A list of files to scan.
#
# Results:
#	Return the list of files that were successfully opened and 
#	scanned.

proc analyzer::scan {files} {
    # Set the scanning bit to true, so no output is displayed.

    set analyzer::scanning 1

    # Scan the files.  With the scanning bit set this
    # will only scan files looking into commands defined
    # in the various scanCmds lists of external packages.

    set files [analyzer::analyze $files]

    # Restore the system to the pervious state.

    set analyzer::scanning 0
    return $files
}

# analyzer::scanScript --
#
#	Scan a script.  This procedure may be called directly
#	to scan a new script, or recursively to scan subcommands
#	and control function arguments.  If called with only a 
#	block arg, it is assumed to be a new script and line
#	number information is initialized.
#
# Arguments:
#	scriptRange	The range in the script to analyze. A
#			default of {} indicates the whole script.
#
# Results:
#       None.

proc analyzer::scanScript {{scriptRange {}}} {
    upvar \#0 ::analyzer::script script
    # Iterate over all of the commands in the script range, advancing the
    # range at the end of each command.
    
    pushCmdInfo
    set first 1
    if {$scriptRange == ""} {
	set scriptRange [parse getrange $script]
    }
    for {} {[parse charlength $script $scriptRange] > 0} \
	    {set scriptRange $tail} {
	# Parse the next command
	setCmdRange $scriptRange
	if {[catch {foreach {comment cmdRange tail tree} \
		[parse command $script $scriptRange] {}}]} {
	    # Attempt to keep parsing at the next thing that looks
	    # like a command.
	    set errPos [lindex $::errorCode 2]
	    set scriptRange [list $errPos [expr {[lindex $scriptRange 0] \
		    + [lindex $scriptRange 1] - $errPos}]]
	    if {[regexp -indices "\[^\\\\]\[\n;\]" \
		    [parse getstring $script $scriptRange] match]} {
		set start [parse charindex $script $scriptRange]
		set end [expr {$start + [lindex $match 1] + 1}]
		set len [expr {$start \
			+ [parse charlength $script $scriptRange] - $end}]
		set tail [parse getrange $script $end $len]
		setCmdRange $tail
		continue
	    }
	    break
	}

	if {[parse charlength $script $cmdRange] <= 0} {
	    continue
	}

	# Set the anchor at the beginning of the command, skipping over
	# any comments or whitespace.

	setCmdRange $cmdRange

	set index 0
	while {$index < [llength $tree]} {
	    set cmdToken [lindex $tree $index]
	    if {[getLiteral $cmdToken cmdName]} {
		# The scan command checkers do not distinguish between 
		# commands with leading ::'s and those that do not.  In
		# order to see if this command is a scan command, the 
		# leading ::'s need to be stripped off.
		
		regsub {^::} $cmdName "" cmdName

		if {[analyzer::scanCmdExists $cmdName]} {
		    # Invoke the command checker on the arguments 
		    # to the command.
		    
		    incr index
		    set cmd [topChecker $cmdName]
		    if {$cmd == {}} {
			puts "ERROR: $cmdName is empty!!!"
		    }
		    set index [eval $cmd {$tree $index}]
		    continue
		}
	    }

	    # The command was not literal or the command was not a scan 
	    # command.  Invoke the generic command checker on all of the
	    # words in the statement.
	    
	    set index [checkCommand $tree 0]	    
	}
    }
    popCmdInfo
    return
}

# analyzer::scanCmdExists --
#
#	Determine if the command should be recursed into looking for
#	user-defined procs.
#
# Arguments:
#	cmdName		The name of the command to check.
#
# Results:
#	Return 1 if this command should be scanned, or 0 if it should not.

proc analyzer::scanCmdExists {cmdName} {
    return [expr {[info exists analyzer::scanCmds(${cmdName}-TPC-SCAN)] \
	    || [info exists analyzer::scanCmds($cmdName)]}]
}

# analyzer::addScanCmds --
#
#	Add to the table of commands that need to be
#	checked for proc definitions during the initial
#	scan phase.
#
# Arguments:
#	cmdList		List of command/action pairs for commands that
#			need to be searched for proc definitions.
#
# Results:
#	None.

proc analyzer::addScanCmds {cmdList} {
    foreach {name cmd} $cmdList {
	set analyzer::scanCmds($name) [list $cmd]
    }
    return
}

# analyzer::addContext --
#
#	Push the new context on its stack and push a new proc
#	info type onto its stack.  Then call the chain command
#	to analyze the command given the new state.  When the
#	command is done being checked by the chain command, see
#	if enough info was gathered to add a user defined proc.
#	Before exiting, pop all appropriate stacks.  This routine
#	should be called during the initial scanning phase
#	and passed a token tree and current index, where the
#	index is the name of the proc being defined.
#
# Arguments:
#	cIndex		The index to use to extract context info.
#	strip		Boolean indicating if the word containing
#			the context name should have the head stripped
#			off (i.e. "proc" vs. "namespace eval")
#	vCmd		The command to call to verify that enough info
#			was gathered to define a user proc.  Can be an
#			empty string.
#	cCmd		The command to call during the analyze step (phase III)
#			that verifies the user proc was called correctly.
#			Can be an empty string.
#	chainCmd	The chain command to eval in the new context.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::addContext {cIndex strip vCmd cCmd chainCmd tokens index} {
    # Extract the new context from the token list and push it onto 
    # the stack.  If the token pointed at by cIndex is a non-literal,
    # push the UNKNOWN descriptor.

    set word [lindex $tokens $cIndex]
    if {[getLiteral $word context]} {
	if {$strip} {
	    set context [context::head $context]
	}
	context::push [context::join [context::top] $context]
    } else {
	context::push UNKNOWN
    }

    # Add a new proc info type onto the stack.  This will get 
    # populated with data when the command is checked that 
    # creates a user proc.
    
    if {$cCmd == ""} {
	set cCmd "analyzer::checkUserProc"
    }
    if {$vCmd == ""} {
	set vCmd "analyzer::verifyUserProc"
    }
    set pInfo [uproc::newProcInfo]
    set pInfo [uproc::setVerifyCmd $pInfo $vCmd]
    set pInfo [uproc::setCheckCmd  $pInfo $cCmd]
    uproc::pushProcInfo $pInfo

    # Parse the remaining portion of the command with the
    # new context info.

    set index  [eval $chainCmd {$tokens $index}]

    # Return the stacks back to the previous state and add the 
    # user proc if enough info was gathered to define this user
    # proc.

    context::pop
    set pInfo [uproc::topProcInfo]
    if {[[uproc::getVerifyCmd $pInfo] $pInfo]} {
	uproc::add $pInfo $strip
    }
    uproc::popProcInfo

    return $index
}

# analyzer::addUserProc --
#
#	Add the user-defined proc to the list of commands 
#	to be checked during the final phase.  This routine
#	should be called during the initial scanning phase
#	and passed a token tree and current index, where the
#	index is the name of the proc being defined.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.  The
#	proc name will be added to the current pInfo type on top 
#	of the proc info stack.

proc analyzer::addUserProc {tokens index} {
    set argc [llength $tokens]
    set word [lindex $tokens $index]
    if {($argc != 4) || (![getLiteral $word procName])} {
	return [checkCommand $tokens $index]
    }

    # Turn procName into an unqualified name.  The context of
    # the procName is *already* defined in the system and can 
    # be retrieved by using the context::top command.
		
    set name [namespace tail $procName]
    set proc [context::join [context::top] $name]
    uproc::addUserProc $proc proc

    return [incr index]
}

# analyzer::addArgsList --
#
#	Add the user-defined proc's argList to the list of commands 
#	to be checked during the final phase.  This routine
#	should be called during the initial scanning phase
#	and passed a token tree and current index, where the
#	index is the argList to parse.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.  The
#	arg list will be added to the current pInfo type on top 
#	of the proc info stack.

proc analyzer::addArgList {tokens index} {
    # Get the argList.  If the value is nonLiteral, or is 
    # not a valid Tcl list, then do nothing and return without 
    # adding this proc to the database.
    
    set word [lindex $tokens $index]
    if {![getLiteral $word argList] \
	    || [catch {set len [llength $argList]}]} {
	return [checkCommand $tokens $index]
    }

    uproc::addArgList $argList
    return [incr index]
}

# analyzer::addRenameCmd --
#
#	Add the commands to be renamed in the current context.  The
#	command names to be renamed must be parsed from the token 
#	list.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::addRenameCmd {tokens index} {
    variable renameCmds

    # Extract the proc names from the token list.  If either
    # the source or destination proc name is a non-literal,
    # then bail and do nothing.

    set word [lindex $tokens $index]
    if {![getLiteral $word src]} {
	return [checkCommand $tokens $index]
    }
    incr index
    set word [lindex $tokens $index]
    if {![getLiteral $word dst]} {
	return [checkCommand $tokens $index]
    }

    # Get the fully qualified name of the source and destination
    # procs before adding them to the list.

    set srcCmd [context::join [context::top] $src]
    set dstCmd [context::join [context::top] $dst]
    set renameCmds($srcCmd,$dstCmd) [list $srcCmd $dstCmd]
    return [incr index]
}

# analyzer::addInheritCmd --
#
#	Add the base classes that the derived class (the current context)
#	should inherit from.  The base class names to inherit must be 
#	parsed from the token list.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::addInheritCmd {tokens index} {
    variable inheritCmds

    # The inherit command could be called multiple times for the
    # same class if the class is deleted and recreated.  To handle
    # this case, and still be able to flatten the inheritance tree,
    # the inheritCmds array stores lists of inheritance order for
    # a given context.

    set result  {}
    set drvClass [context::top]

    while {$index < [llength $tokens]} {
	set word [lindex $tokens $index]
	if {[getLiteral $word baseClass]} {
	    incr index
	    lappend result $baseClass
	} else {
	    # The word is a non-literal value, check the word but
	    # do not append anything to the pattern list.

	    set index [checkWord $tokens $index]
	}
    }
    lappend inheritCmds($drvClass) $result
    return $index
}

# analyzer::addExportCmd --
#
#	Add the list of commands to the list of commands to
#	be exported for this namespace context.  The command
#	names to export must be extracted from the token list 
#	and be literal values.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::addExportCmd {tokens index} {
    variable exportCmds

    set start $index
    set context [context::top]
    while {$index < [llength $tokens]} {
	set word [lindex $tokens $index]
	if {[getLiteral $word literal]} {
	    # If this is the first word, check for the -clear option.
	    # Do nothing if the -clear option is specified, because
	    # we cannot determine when this command will be called.

	    incr index
	    if {($index == [expr {$start + 1}]) && ($literal == "-clear")} {
		continue
	    }

	    # Do not append patterns that specify a namespace.
	    # This is illegal and is logged as an error during
	    # phase III.

	    if {[string first "::" $literal] >= 0} {
		continue
	    }

	    lappend exportCmds($context) $literal
	} else {
	    # The word is a non-literal value, check the word but
	    # do not append anything to the pattern list.

	    set index [checkWord $tokens $index]
	}
    }
    return $index
}

# analyzer::addImportCmd --
#
#	Add the pattern to the list of imported namespace patterns.  The
#	pattern string must be extracted from the token list and must
#	be a literal value.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::addImportCmd {tokens index} {
    variable importCmds

    set start $index
    set context [context::top]
    while {$index < [llength $tokens]} {
	set word [lindex $tokens $index]
	if {[getLiteral $word literal]} {
	    # If this is the first word, check for the -force option.
	    # Do nothing if the -force option is specified, because
	    # we cannot determine when this command will be called.

	    incr index
	    if {($index == [expr {$start + 1}]) && ($literal == "-force")} {
		continue
	    }
	    lappend importCmds($context) $literal
	} else {
	    # The word is a non-literal value, check the word but
	    # do not append anything to the pattern list.

	    set index [checkWord $tokens $index]
	}
    }
    return $index
}

# analyzer::verifyUserProc --
#
#	Verify the information contained in the proc info type
#	is enough to check the user defined proc.  This routine
#	should be called after a command that defines a user
#	proc has been parsed and checked. (see analyzer::addContext)
#
# Arguments:
#	pInfo	The proc info opaque type.
#
# Results:
#	Return a boolean, 1 if there is enough data, 0 otherwise.

proc analyzer::verifyUserProc {pInfo} {
    set name [uproc::getName $pInfo]
    set def  [uproc::getDef  $pInfo]
    return [expr {($name != {}) && $def}]
}

# analyzer::collate --
#
#	Collate the namespace import and export commands and
#	add any imported commands to the user-defined proc
#	database.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc analyzer::collate {} {
    variable inheritCmds
    variable renameCmds
    variable exportCmds
    variable importCmds

    # Foreach context that imports a proc (i.e., namespace import,
    # inherit, or rename), import all of the procs into the import 
    # context from specified export context.  Do a transitive 
    # closure searching until there are no more commands to be 
    # imported.  This is important because one cycle of importing 
    # may add new commands to a context that should have been 
    # imported to a different context.

    set search 1
    while {$search} {
	set search 0

	# Import the list of commands that have been renamed.

	foreach rename [array names renameCmds] {
	    foreach {srcCmd dstCmd} $renameCmds($rename) {}
	    set search [uproc::copyUserProc $dstCmd $srcCmd renamed]
	}

	# Import all of the commands that have been imported
	# or exported from a namespace.

	foreach impCtx [array names importCmds] {
	    foreach impPat $importCmds($impCtx) {
		foreach expCmd [analyzer::getExportedCmds $impCtx $impPat] {
		    set name   [namespace tail $expCmd]
		    set impCmd [context::join $impCtx $name]
		    set search [uproc::copyUserProc $impCmd $expCmd imported]
		}
	    }
	}

	# Import all of the public or protected class procs from all 
	# base classes into the derived class.  Although there can be
	# only one inherit call per class, we have to handle the case
	# where a class is deleted and recreated.  Therefore we could
	# have multiple inheritance lists.  Make a union of all of 
	# the inherited class procs.

	foreach drvClass [array names inheritCmds] {
	    foreach baseClasses $inheritCmds($drvClass) {
		foreach baseCmd [analyzer::getInheritedCmds \
			$drvClass $baseClasses] {
		    set name   [namespace tail $baseCmd]
		    set drvCmd [context::join $drvClass $name]
		    set search [uproc::copyUserProc $drvCmd $baseCmd inherit]
		}
	    }
	}
    }
    return
}

# analyzer::getExportedCmds --
#
#	Given an import context and an import pattern, compile
#	a list of commands that will be imported into the import
#	context.
#
# Arguments:
#	impCtx		The import context.
#	impPat		The import pattern.
#
# Results:
#	A list of commands to import into the import context.

proc analyzer::getExportedCmds {impCtx impPat} {
    variable exportCmds

    set expCtx  [context::locate $impCtx $impPat]
    if {![info exists exportCmds($expCtx)]} {
	return
    }

    set impPat  [namespace tail $impPat]
    set impCmds [uproc::searchThisContext $expCtx $impPat]

    set result {}
    foreach expPat $exportCmds($expCtx) {
	foreach expCmd [uproc::searchThisContext $expCtx $expPat] {
	    # Add the command if it exists in the import pattern
	    # list and does not already exist in the result list.

	    set qualExpCmd [context::join $expCtx $expCmd]
	    if {([lsearch $impCmds $qualExpCmd] >= 0) \
		    && ([lsearch $result $qualExpCmd] < 0)} {
		lappend result $qualExpCmd
	    }
	}
    }
    return $result
}

# analyzer::getInheritedCmds --
#
#	Given an ordered list of base classes to inherit, create a 
#	list of public and protected commands that should be 
#	inherited (imported.)
#
# Arguments:
#	drvClass	The derived class.
#	baseClasses	The ordered list of base classes to inherit.
#
# Results:
#	A list of quialified proc names to inherit into the derived 
#	class.

proc analyzer::getInheritedCmds {drvClass baseClasses} {
    # Search the list in reverse order clobbering commands that
    # appear first.  This is done to maintain the correct inheritance 
    # hierarchy.

    set context [context::head $drvClass]

    for {set i [expr {[llength $baseClasses] - 1}]} {$i >= 0} {incr i -1} {
	set baseClass [lindex $baseClasses $i]
	set baseClass [context::locate $context $baseClass 0]
        foreach baseCmd [uproc::searchThisContext $baseClass "*"] {
	    set cmds([namespace tail $baseCmd]) $baseCmd
	}
    }

    # Take the flatten list of procs and make a list of the fully 
    # qualified command names.

    set result {}
    foreach {tail cmd} [array get cmds] {
	lappend result $cmd
    }
    return $result
}

# analyzer::analyze --
#
#	Perform syntactic analysis of a tcl script.  At this
# 	point, glob patterns have already been expanded.  If the
# 	-quiet flag was not specified, print the filename before
# 	checking.
#
# Arguments:
#	files		A list of file names to analyze.
#
# Results:
#	Return the list of files that were successfully opened and 
#	scanned.

proc analyzer::analyze {files} {
    set result {}
    set pwd    [pwd]

    if {[llength $files] == 0} {
	if {[analyzer::isScanning] || ![analyzer::isTwoPass]} {
	    if {![analyzer::getQuiet]} {
		Puts "scanning: stdin"
	    }
	    set ::analyzer::script [read stdin]
	    set ::analyzer::file stdin
	    set ::analyzer::currentLine 1
	    analyzer::checkScript
	} else {
	    if {![analyzer::getQuiet]} {
		Puts "checking: stdin"
	    }
	    analyzer::checkScript
	}
	return $result
    }
    
    foreach file $files {
	if {[catch {set fd [open $file r]} msg] == 1} {
	    Puts $msg
	    continue
	} else {
	    lappend result $file
	}

	if {![analyzer::getQuiet]} {
	    cd [file dirname $file]
	    set path [file join [pwd] [file tail $file]]
	    cd $pwd
	    if {[analyzer::isScanning]} {
		Puts "scanning: $path"
	    } else {
		Puts "checking: $path"
	    }
	}

	set ::analyzer::script [read $fd]
	close $fd
	set ::analyzer::file $file
	set ::analyzer::currentLine 1
	analyzer::checkScript
    }
    return $result
}

# analyzer::analyzeScript --
#
#	Analyze a script.  This procedure may be called directly
#	to analyze a new script, or recursively to analyze
#	subcommands and control function arguments.  If called with
#	only a block arg, it is assumed to be a new script and line
#	number information is initialized.
#
# Arguments:
#	scriptRange	The range in the script to analyze. A
#			default of {} indicates the whole script.
#
# Results:
#       None.

proc analyzer::analyzeScript {{scriptRange {}}} {
    upvar \#0 ::analyzer::script script
    # Iterate over all of the commands in the script range, advancing the
    # range at the end of each command.

    pushCmdInfo
    set first 1
    if {$scriptRange == ""} {
	set scriptRange [parse getrange $script]
    }
    for {} {[parse charlength $script $scriptRange] > 0} \
	    {set scriptRange $tail} {
	# Parse the next command

	setCmdRange $scriptRange
	if {[catch {foreach {comment cmdRange tail tree} \
		[parse command $script $scriptRange] {}}]} {

	    # An error occurred during parsing so generate the error.
	    set errPos [lindex $::errorCode 2]
	    set errLen [expr {[lindex $scriptRange 1] \
		    - ($errPos - [lindex $scriptRange 0])}]
	    set errMsg [lindex $::errorCode end]
	    logError parse [list $errPos $errLen] $errMsg

	    # Attempt to keep parsing at the next thing that looks
	    # like a command.

	    set scriptRange [list $errPos [expr {[lindex $scriptRange 0] \
		    + [lindex $scriptRange 1] - $errPos}]]
	    if {[regexp -indices "\[^\\\\]\[\n;\]" \
		    [parse getstring $script $scriptRange] match]} {
		set start [parse charindex $script $scriptRange]
		set end [expr {$start + [lindex $match 1] + 1}]
		set len [expr {$start \
			+ [parse charlength $script $scriptRange] - $end}]
		set tail [parse getrange $script $end $len]
		setCmdRange $tail
		continue
	    }
	    break
	}

	if {[parse charlength $script $cmdRange] <= 0} {
	    continue
	}

	# Set the anchor at the beginning of the command, skipping over
	# any comments or whitespace.

	setCmdRange $cmdRange

	set index 0
	while {$index < [llength $tree]} {
	    set cmdToken [lindex $tree $index]
	    if {[getLiteral $cmdToken cmdName]} {
		# The system command checkers do not distinguish between 
		# commands with leading ::'s and those that do not.  In
		# order to see if this command is a system command, the 
		# leading ::'s need to be stripped off.

		set systemCmdName [string trimleft $cmdName :]

		if {[uproc::exists [context::top] $cmdName pInfo]} {
		    # Check the argList for the user-defined proc.
		    
		    incr index
		    set index [uproc::checkUserProc $cmdName $pInfo \
			    $tree $index]
		} elseif {[info exists analyzer::checkers($systemCmdName)]} {
		    # Eval the command checker for the globally defined 
		    # command.
		    
		    incr index
		    set cmd [topChecker $systemCmdName]
		    set index [eval $cmd {$tree $index}]
		} elseif {[analyzer::isTwoPass]} {
		    # Currently, Tk is not defininig widget names as procs.
		    # Ignore all unknown commands that start with period.

		    if {[string index $cmdName 0] != "."} {
			# This is a command that is neither defined by the 
			# user or defiend to be a global proc.

			if {[lsearch -exact $analyzer::unknownCmds $cmdName] \
				== -1} {
			    # Give a warning if this is the 1st time the
			    # undefined proc is called.

			    lappend analyzer::unknownCmds $cmdName
			    logError warnUndefProc $cmdRange $cmdName
			}
		    }
		    set index [checkCommand $tree $index]
		} else {
		    # Nothing special is to be done, just check command.

		    set index [checkCommand $tree $index]
		}		    
	    } else {
		# Invoke the generic command checker on all of the words in
		# the statement.
		
		set index [checkCommand $tree 0]
	    }
	}
    }
    popCmdInfo
    return
}

# analyzer::addCheckers --
#
#	Add a set of checkers to the analyzer::checkers array.
#
# Arguments:
#	chkList 	An ordered list of checkers where the first
#			element is the command name and the second
#			element is the checker to execute.
#
# Results:
#	None.

proc analyzer::addCheckers {chkList} {
    foreach {name cmd} $chkList {
	set analyzer::checkers($name) [list $cmd]
    }
    return
}

# analyzer::pushChecker --
#
#	Push a new command onto the checker array.
#
# Arguments:
#	cmdName		The name of the command.
#	cmd		The command to run to analyze cmdName
#
# Results:
#	None.

proc analyzer::pushChecker {cmdName cmd} {
    variable scanCmds
    variable checkers

    if {[analyzer::isScanning]} {
	if {[info exists scanCmds($cmdName)]} {
	    set scanCmds($cmdName) [linsert $scanCmds($cmdName) 0 $cmd]
	} else {
	    set scanCmds($cmdName) [list $cmd]
	}
    } else {
	if {[info exists checkers($cmdName)]} {
	    set checkers($cmdName) [linsert $checkers($cmdName) 0 $cmd]
	} else {
	    set checkers($cmdName) [list $cmd]
	}
    }
    return
}

# analyzer::popChecker --
#
#	Pop the command checker off the command list.
#	If the list is empty, remove the checker for 
#	the command from the checkers array.
#
# Arguments:
#	cmdName		The command name to pop.
#
# Results:
#	None.

proc analyzer::popChecker {cmdName} {
    variable scanCmds
    variable checkers

    if {[analyzer::isScanning] && [info exists scanCmds($cmdName)]} {
	set scanCmds($cmdName) [lrange $scanCmds($cmdName) 1 end]
	if {[llength $scanCmds($cmdName)] == 0} {
	    unset scanCmds($cmdName)
	}
    } elseif {![analyzer::isScanning] && [info exists checkers($cmdName)]} {
	set checkers($cmdName) [lrange $checkers($cmdName) 1 end]
	if {[llength $checkers($cmdName)] == 0} {
	    unset checkers($cmdName)
	}
    }
    return
}

# analyzer::topChecker --
#
#	Get the cmd to execute for the cmdName.
#
# Arguments:
#	cmdName		The command name to get the checker for.
#
# Results:
#	Returns the command to eval for the cmdName.

proc analyzer::topChecker {cmdName} {
    variable scanCmds
    variable checkers

    if {[analyzer::isScanning] && [info exists scanCmds($cmdName)]} {
	return [lindex $scanCmds($cmdName) 0]
    } elseif {[info exists checkers($cmdName)]} {
	return [lindex $checkers($cmdName) 0]
    } else {
	return {}
    }
}

# analyzer::logError --
#
#	This routine is called whenever an error is detected.  It is
#	responsible for invoking the filtering mechanism and then
#	recording any errors that aren't filtered out.
#
# Arguments:
#	mid		The message id that identifies a unique message.
#	errRange	The range where the error occured.
#	args		Any additional type specific arguments.
#
# Results:
#	None.

proc analyzer::logError {mid errRange args} {
    if {![analyzer::isScanning]} {
	set types [message::getTypes $mid]
	if {![filter::suppress $types $mid]} {
	    
	    # Record the occurence of errors and warnings.
	    if {[lsearch $types err] >= 0} {
		incr ::analyzer::errCount
	    } else {
		incr ::analyzer::warnCount
	    }
	    
	    # Show the message.
	    message::show $mid $errRange $args
	}
    }
    return
}

# analyzer::isLiteral --
#
#	Check to see if a word only contains text that doesn't need to
#	be substituted.
#
# Arguments:
#	word		The token for the word to check.
#
# Results:
#	Returns 1 if the word contains no variable or command substitutions,
#	otherwise returns 0.

proc analyzer::isLiteral {word} {
    if {[lindex $word 0] != "simple"} {
	foreach token [lindex $word 2] {
	    set type [lindex $token 0]
	    if {$type != "text" && $type != "backslash"} {
		return 0
	    }
	}

	# The text contains backslash sequences.  Bail if the text is
	# not in braces because this would require complicated substitutions.
	# Braces are a special case because only \newline is interesting and
	# this won't interfere with recursive parsing.

	if {[string index $::analyzer::script \
		[parse charindex $::analyzer::script [lindex $word 1]]] \
		== "\{"} {
	    return 1
	} else {
	    return 0
	}
    }
    return 1
}

# analyzer::getLiteral --
#
#	Retrieve the string value of a word without quotes or braces.
#
# Arguments:
#	word		The token for the word to fetch.
#	resultVar	The name of a variable where the text should be
#			stored.
#
# Results:
#	Returns 1 if the text contained no variable or command substitutions,
#	otherwise returns 0.

proc analyzer::getLiteral {word resultVar} {
    upvar $resultVar result
    set result ""
    foreach token [lindex $word 2] {
	set type [lindex $token 0]
	if {$type == "text"} {
	    append result [parse getstring $::analyzer::script \
		    [lindex $token 1]]
	} elseif {$type == "backslash"} {
	    append result [subst [parse getstring $::analyzer::script \
		    [lindex $token 1]]]
	} else {
	    set result [parse getstring $::analyzer::script \
		    [lindex $word 1]]
	    return 0
	}
    }
    return 1
}

# analyzer::getLiteralPos --
#
#	Given an index into a literal, compute the corresponding position
#	within the word from the script.
#
# Arguments:
#	word		The original word for the literal.
#	pos		The index within the literal.
#
# Results:
#	Returns the byte offset within the original script that corresponds
#	to the given literal index.

proc analyzer::getLiteralPos {word pos} {
    set tokens [lindex $word 2]
    set count [llength $tokens]
    for {set i 0} {$i < $count} {incr i} {
	set token [lindex $tokens $i]
	set range [lindex $token 1]
	if {[lindex $token 0] == "backslash"} {
	    set len [string length [subst \
		    [parse getstring $::analyzer::script $range]]]
	} else {
	    set len [lindex $range 1]
	}
	if {$pos < $len} {
	    return [expr {[lindex $range 0]+$pos}]
	}
	incr pos -$len
    }

    # We fell off the end add the remainder to the first character after
    # the last token.

    return [expr {[lindex $range 0] + [lindex $range 1] + $pos}]
}

# analyzer::getLiteralRange --
#
#	Given a range into a literal, compute the corresponding range
#	within the word from the script.
#
# Arguments:
#	word		The original word for the literal.
#	range		The range within the literal.
#
# Results:
#	Returns the range within the original script that corresponds
#	to the given literal range.

proc analyzer::getLiteralRange {word range} {
    set start [lindex $range 0]
    set end [expr {$start+[lindex $range 1]}]
    set origStart [getLiteralPos $word $start]
    set origLen [expr {[getLiteralPos $word $end] - $origStart}]
    return [list $origStart $origLen]
}

# analyzer::checkScript --
#
#	Call the appropriate command based on the phase of checking
#	we are currently doing.
#
# Arguments:
#	scriptRange	The range in the script to analyze. A
#			default of {} indicates the whole script.
#
# Results:
#       None.

proc analyzer::checkScript {{scriptRange {}}} {
    if {[analyzer::isScanning]} {
	analyzer::scanScript $scriptRange
    } else {
	analyzer::analyzeScript $scriptRange
    }
    return
}

# analyzer::checkContext --
#
#	Push the new context on its stack and call the chain command
#	to analyze the command inside the new state.  When the
#	command is done being checked by the chain command, pop the
#	context stack.  This routine should be called during the 
#	final analyze phase and passed a token tree and current
#	index, where the index is the name of the proc being defined.
#
# Arguments:
#	cIndex		The index to use to extract context info.
#	strip		Boolean indicating if the word containing
#			the context name should have the head stripped
#			off (i.e. "proc" vs. "namespace eval")
#	chainCmd	The chain cmd to eval in the new context.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkContext {cIndex strip chainCmd tokens index} {
    # Push the new context onto the stack.  If the token
    # pointed at by cIndex is a non-literal, push the
    # UNKNOWN descriptor.

    set word [lindex $tokens $cIndex]
    if {[getLiteral $word context]} {
	if {$strip} {
	    set context [namespace qualifier $context]
	}
	context::push [context::join [context::top] $context]
    } else {
	context::push UNKNOWN
    }

    # Parse the remaining portion of the command with the
    # new context info.

    set index  [eval $chainCmd {$tokens $index}]

    # Return the context stack back to the previous state.

    context::pop
    return $index
}

# analyzer::checkUserProc --
#
#	Check the user-defined proc for the correct number
#	of arguments.  For procs that have been multiply 
#	defined, check all of the argLists before flagging
#	an error.  This routine should be called during the
#	final analyzing phase of checking, after the proc
#	names have been found.
#
# Arguments:
#	pInfo		The proc info type of the proc to check.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the commands to call to log an error if this
#	user proc failed.  Otherwise, return empty string if
#	the user proc passed.

proc analyzer::checkUserProc {pInfo tokens index} {
    set argc  [llength $tokens]
    set min   [uproc::getMin  $pInfo]
    set max   [uproc::getMax  $pInfo]

    # Check for the correct number of arguments.
    
    if {($argc >= ($min + $index)) \
	    && (($max == -1) || ($argc <= ($max + $index)))} {
	return {}
    } else {
	set name [uproc::getName $pInfo]
	if {[string match "::*" $name]} {
	    set name [string range $name 2 end]
	}
	return [list [list logError procNumArgs {} $name]]
    }
}

# analyzer::checkRedefined --
#
#	Check to see if the proc is defined more then once.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkRedefined {tokens index} {
    set word [lindex $tokens $index]
    if {[getLiteral $word name]} {
	uproc::isRedefined [context::join [context::top] $name] proc
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

# analyzer::checkBody --
#
#	Parse a script body by stripping off any quote characters.
#
#	Attempt to parse a word like it is the body of a control
#	structure.  If the word is a simple string, it passes it to
#	checkScript, otherwise it just treats it like a normal word
#	and looks for subcommands.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkBody {tokens index} {
    set word [lindex $tokens $index]
    if {[isLiteral $word]} {
	set quote [string index $::analyzer::script \
		[parse charindex $::analyzer::script [lindex $word 1]]]
	set range [lindex $word 1]
	if {$quote == "\"" || $quote == "\{"} {
	    set range [list [expr {[lindex $range 0] + 1}] \
		    [expr {[lindex $range 1] - 2}]]
	}
	checkScript $range
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

# analyzer::checkWord --
#
#	Examine a word for subcommands. 
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkWord {tokens index} {
    set word [lindex $tokens $index]
    set type [lindex $word 0]
    switch -- $type {
	variable {
	    set range [lindex [lindex [lindex $word 2] 0] 1]
	    set name [parse getstring $::analyzer::script $range]
	    checkVariable $name $range
	    foreach subword [lindex $word 2] {
		checkWord [list $subword] 0
	    }
	}
	subexpr -
	word {
	    foreach subword [lindex $word 2] {
		checkWord [list $subword] 0
	    }
	}
	command {
	    set range [lindex $word 1]
	    set range [list [expr {[lindex $range 0] + 1}] \
		    [expr {[lindex $range 1] - 2}]]
	    checkScript $range
	}
    }

    incr index

    # Check for unmatched trailing brackets or braces in all words.

    if {$type != "simple" && $type != "word"} {
	return $index
    }
    set lasttok [lindex [lindex $word 2] end]
    set type [lindex $lasttok 0]
    if {$type == "command" || $type == "backslash"} {
	return $index
    }

    set range [lindex $lasttok 1]
    set range [list [expr {[lindex $range 0]+[lindex $range 1]-1}] 1]

    CheckExtraCloseChar "\[" "\]" $word $range
    CheckExtraCloseChar "\{" "\}" $word $range
    return $index
}

# analyzer::CheckExtraCloseChar --
#
#	If the word ends in the closeChar character, make sure there is an
#	openChar character somewhere in the word.
#
# Arguments:
#	openChar	The opening char the match agains a closing char,
#			either "\{" or "\[".
#	closeChar	The closing char the make sure is matched with an open char,
#			either "\]" or "\}".
#	word		The word to check.
#	range		The range to report for the word.
#
# Side Effects:
#	Logs a warnExtraClose warning if an unmatched close brace is detected.
#
# Results:
#	None.

proc analyzer::CheckExtraCloseChar {openChar closeChar word range} {
    # Check for unmatched trailing brackets or braces in all words.  We only
    # check if the last character in the word is an unquoted bracket/brace that
    # isn't part of a subcommand invocation.  If we see a trailing bracket/brace,
    # we thenscan each subtoken to see if it contains an open bracket/brace that
    # isn'tquoted or part of a subcommand.  If there are no open brackets/braces
    # we generate the warning.  Note that this algorithm should handle most
    # common cases.  It will not detect unmatched brackets/braces in the middle of
    # a word.
    # 
    # Note that this check is only a warning because Tcl is perfectly happy
    # to pass a naked close bracket/brace to a command without complaining and
    # people occasionally take advantage of this fact.  This is not
    # recommended practice, so we will still flag it as a potential error.

    if {![string equal [parse getstring $::analyzer::script $range] $closeChar]} {
	return
    }

   foreach subword [lindex $word 2] {
	set type [lindex $subword 0]
	if {$type == "command"} {
	    continue
	}
	if {([string first $openChar [parse getstring $::analyzer::script \
		[lindex $subword 1]]] != -1)} {
	    return
	}
    }
    
    logError warnExtraClose $range
}

# analyzer::checkVariable --
#
#	Check a variable name against a list of special names.
#
# Arguments:
#	name		The variable name to check.
#	range		The range to report for the variable.
#
# Results:
#	None.

proc analyzer::checkVariable {varName range} {
    if {$varName == "tcl_precision"} {
	logError nonPortVar $range "tcl_precision"
    } elseif {$varName == "tkVersion"} {
	logError warnUnsupported $range "tk_version"
    }
    return
}

# analyzer::checkExpr --
#
#	Attempt to parse a word like it is an expression.
#	If the word is a simple string, it is examined for subcommands
#	within the expression, otherwise it is handled like a normal word.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkExpr {tokens index} {
    set word [lindex $tokens $index]

    #  Don't attempt to parse as an expression if the text contains
    #  substitutions.
    
    if {![isLiteral $word]} {
	if {![getLiteral $word str]} {
	    logError warnExpr [getTokenRange $word]
	}
	return [checkWord $tokens $index]
    }

    # Compute the range of the expression from the first and last token in
    # the word.

    set start [lindex [lindex [lindex [lindex $word 2] 0] 1] 0]
    set end [lindex [lindex [lindex $word 2] end] 1]
    set range [list $start [expr {[lindex $end 0] + [lindex $end 1] - $start}]]

    # Parse the word as an expression looking for subcommands.

    if {[catch {parse expr $::analyzer::script $range} tree]} {
	logError parse [getTokenRange $word] $::errorCode
    } else {
	# TODO: Add more complete expression tests here
	checkWord [list $tree] 0
    }
    return [incr index]
}

# analyzer::checkCommand --
#
#	This is the generic command wrapper.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkCommand {tokens index} {
    set argc [llength $tokens]
    while {$index < $argc} {
	set index [checkWord $tokens $index]
    }
    return $argc
}

# analyzer::checkSimpleArgs --
#
#	This function checks any command that consists of a set of
#	fixed arguments followed by a set of optional arguments that
#	must appear in a fixed sequence.
#
# Arguments:
#	min		The minimum number of arguments.
#	max		The maximum number of arguments.  If -1, then the
#			last argument may be repeated.
#	argList		A list of scripts that should be called for
#			the corresponding argument.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkSimpleArgs {min max argList tokens index} {

    # Verify that there are the correct number of fixed arguments and
    # not too many optional arguments.

    set argc [llength $tokens]
    if {($argc < ($min + $index)) \
	    || (($max != -1) && ($argc > ($max + $index)))} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }

    # Starting with the first argument after the command name, invoke
    # the type checker associated with each argument.  If there are more
    # arguments than type commands, use the last command for all of the
    # remaining arguments.

    set i $index
    while {$i < $argc} {
	set i [eval [lindex $argList 0] {$tokens $i}]
	if {[llength $argList] > 1} {
	    set argList [lrange $argList 1 end]
	}
    }
    return $argc
}
    
# analyzer::checkTailArgs --
#
#	This command checks, in reverse order, the arguments to a command.  
#	This checker is useful for commands where the last N elements are
#	known, but the middle arguments are undetermined.

#
# Arguments:
#	headCmd		Checker to apply to middle arguments.
#	tailCmd		Checker to apply to tail arguments.
#	backup		Number of tail arguments.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkTailArgs {headCmd tailCmd backup tokens index} {
    # Calculate the index where the tail command checker should
    # begin checking command arguments. 

    set tailIdx [expr {[llength $tokens] - $backup}]

    # Evaluate the head command checker and save the index where it 
    # stopped checking.  Many checkers will not check a word that is
    # non-literal.  So if the stop index is less then the tail index
    # call "checkWord" on each word up to the tail index.

    set stopIdx $index 
    while {$stopIdx < $tailIdx} {
	set nextIdx [eval $headCmd {$tokens $stopIdx}]
	if {$nextIdx == $stopIdx} {
	    if {[isLiteral [lindex $tokens $nextIdx]]} {
		break
	    } else {
		set nextIdx [checkWord $tokens $nextIdx]
	    }
	}
	set stopIdx $nextIdx
    }

    # Evaluate the tail checker.

    set stopIdx [eval $tailCmd {$tokens $stopIdx}]
    return $stopIdx
}

# analyzer::checkTailArgsFirst --
#
#	This command checks the arguments to a command in 2 parts: 
#	First it checks the last "numTailArgs".  Then it checks the
#	args from index to the first tail arg.
#
# Arguments:
#	headCmd		Checker to apply to head arguments.
#	tailCmd		Checker to apply to tail arguments.
#	numTailArgs	Number of tail arguments.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkTailArgsFirst {headCmd tailCmd numTailArgs tokens index} {
    # Calculate the index where the tail command checker should
    # begin checking command arguments & check the tail first.

    set tailIdx [expr {[llength $tokens] - $numTailArgs}]
    set stopIdx [eval $tailCmd {$tokens $tailIdx}]

    # Create a token list where the last numTailArgs tokens are removed.
    # Evaluate the head command checker on this reduced token list.

    set reducedTokens [lrange $tokens 0 [expr {$tailIdx - 1}]]
    eval $headCmd {$reducedTokens $index}

    return $stopIdx
}

# analyzer::checkSwitchArg --
#
#	This command checks switch arguments similar to the checkSimpleArgs
#	checker.  It checks to see if the minimum number of words can be
#	found in the current command, and then checks "num" args.  This
#	checker is designed to be used inside custom checkers to assist
#	checking switch arguments (e.g., the "expect" command.)
#
# Arguments:
#	switch		The name of the switch being checked.  Used for
#			logging errors.
#	min		The minimum number of arguments.
#	num		The number of words to check.
#	cmds		A list of scripts that should be called for
#			the corresponding argument.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkSwitchArg {switch min num cmds tokens index} {
    # Verify that there are the correct number of fixed arguments and
    # not too many optional arguments.

    set argc [llength $tokens]
    if {$argc < ($min + $index)} {
	set word [lindex $tokens [expr {$argc - 1}]]
	logError noSwitchArg [getTokenRange $word] $switch
    }

    set i   $index
    set end [expr {$i + $num}]

    while {($i < $argc) && ($i < $end)} {
	set i [eval [lindex $cmds 0] {$tokens $i}]
	if {[llength $cmds] > 1} {
	    set cmds [lrange $cmds 1 end]
	}
    }
    return $i
}

# analyzer::checkOption --
#
#	Check a command to see if it matches the allowed set of options
#	and dispatch on the given option table.  Allows abbreviations.
#
# Arguments:
#	optionTable	The list of option/action pairs.
#	default		The default action to take if no options match, may
#			be null to indicate that an error should be generated.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkOption {optionTable default tokens index} {
    if {($index == [llength $tokens]) && ($default == "")} {
	logError numArgs {}
	return [incr index]
    }
	
    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkCommand $tokens $index]
    }
    
    set keywords {}
    foreach keyword $optionTable {
	lappend keywords [lindex $keyword 0]
    }

    if {![matchKeyword $optionTable $value 0 script]} {
	if {$default != ""} {
	    return [eval $default {$tokens $index}]
	}
	logError badOption [getTokenRange $word] $keywords $value
	set script checkCommand
    }
    if {[llength $script] == 0} {
	Puts "internal error: bad script for '$value' in table: $optionTable"
    }
    incr index
    return [eval $script {$tokens $index}]
}

# analyzer::checkWidgetOptions --
#
#	Check widget configuration options.  The commonOptions are
#	passed as a list of switches which will be looked up in the
#	standardWidgetOptions array.  These standard options will be
#	added to the widget specific options for checking purposes.
#
# Arguments:
#	allowSingle	If 1, this is a "configure" context and a single
#			option name without a value is allowed.
#	commonOptions	A list of standard widget options.
#	options		A list of additional option/action pairs.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkWidgetOptions {
    allowSingle commonOpts widgetOpts tokens index
} {
    variable standardWidgetOpts

    foreach option $commonOpts {
	lappend widgetOpts [list $option $standardWidgetOpts($option)]
    }
    return [checkConfigure $allowSingle $widgetOpts $tokens $index]
}

# analyzer::checkKeyword --
#
#	Check a word against a list of possible values, allowing for
#	unique abbreviations.
#
# Arguments:
#	exact		If 0, abbreviations are allowed.
#	keywords	The list of allowed keywords.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkKeyword {exact keywords tokens index} {
    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkWord $tokens $index]
    }

    if {![matchKeyword $keywords $value $exact script]} {
	logError badKey [getTokenRange $word] $keywords $value
    }
    return [incr index]
}

# analyzer::checkSwitches --
#
#	Check the argument list for optional switches, possibly followed
#	by additional arguments.  Switch names may not be abbreviated.
#
# Arguments:
#	exact		Boolean value.  If true, then switches have to match
#			exactly. 
#	switches	A list of switch/action pairs.  The action may be
#			omitted if the switch does not take an argument.
#			If "--" is included, it acts as a terminator.
#	chainCmd	The command to use to check the remainder of the
#			command line arguments.  May be null for trailing
#			switches.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkSwitches {exact switches chainCmd tokens index} {
    set argc [llength $tokens]
    while {$index < $argc} {
	set word [lindex $tokens $index]
	if {![getLiteral $word value]} {
	    break
	}
	if {[string index $value 0] != "-"} {
	    break
	}

	set script ""
	if {![matchKeyword $switches $value $exact script]} {
	    logError badSwitch [getTokenRange $word] $value
	    incr index
	} else {
	    incr index
	    if {$value == "--"} {
		break
	    }
	    if {$script != ""} {
		if {$index >= $argc} {
		    logError noSwitchArg [getTokenRange $word] $value
		    return $argc
		}
		
		set index [eval $script {$tokens $index}]
	    }
	}
    }
    if {$chainCmd != ""} {
	return [eval $chainCmd {$tokens $index}]
    }
    if {$index != $argc} {
 	logError numArgs {}
    }
    return $argc
}

# analyzer::checkHeadSwitches --
#
#	Modified version of checkSwitches.  It does not require the chain
#	command to exist, it will not log an error if there are arguments
#	remaining after the switches are doen being checked, and it will 
#	stop checking on a designated index.
#
# Arguments:
#	exact		Boolean value.  If true, then switches have to match
#			exactly. 
#	backup		The number of words to backup from the end of the
#			token list.  This will be used to calculate the index
#			to stop checking for switches.
#	switches	A list of switch/action pairs.  The action may be
#			omitted if the switch does not take an argument.
#			If "--" is included, it acts as a terminator.
#	chainCmd	The command to use to check the remainder of the
#			command line arguments.  May be null for trailing
#			switches.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkHeadSwitches {exact backup switches chainCmd tokens index} {
    # Calculate the index where the tail command checker should
    # begin checking command arguments. 

    set argc    [llength $tokens]
    set stopIdx [expr {$argc - $backup}]

    while {$index < $stopIdx} {
	set word [lindex $tokens $index]
	if {![getLiteral $word value]} {
	    break
	}
	if {[string index $value 0] != "-"} {
	    break
	}

	set script ""
	if {![matchKeyword $switches $value $exact script]} {
	    logError badSwitch [getTokenRange $word] $value
	    incr index
	} else {
	    incr index
	    if {$value == "--"} {
		break
	    }
	    if {$script != ""} {
		if {$index >= $argc} {
		    logError noSwitchArg [getTokenRange $word] $value
		    return $argc
		}
		
		set index [eval $script {$tokens $index}]
	    }
	}
    }
    if {$chainCmd != ""} {
	return [eval $chainCmd {$tokens $index}]
    }
    return $index
}

# analyzer::checkConfigure --
#
#	Check a configuration option list where there may be a single
#	argument that specifies an option to retrieve or a list of
#	option/value pairs to be set.  Option names may be abbreviated.
#
# Arguments:
#	allowSingle	If 1, a single argument is ok, otherwise it's an error.
#	options		A list of switch/action pairs.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkConfigure {allowSingle options tokens index} {
    set argc [llength $tokens]
    set start $index

    while {$index < $argc} {
	set word [lindex $tokens $index]
	set script ""
	if {[getLiteral $word value]} {
	    if {![matchKeyword $options $value 0 script]} {
		logError badSwitch [getTokenRange $word] $value
	    }
	}

	# Check to see if there is a value for this option.

	if {$index == ($argc - 1)} {
	    # If this is the first and last option, we're done.

	    if {$allowSingle && ($index == $start)} {
		return $argc
	    }
	    logError noSwitchArg [getTokenRange $word] $value
	    break
	}
	if {$script == ""} {
	    set script checkWord
	}
	incr index
	set index [eval $script {$tokens $index}]
    }
    return $argc
}

# analyzer::checkFloatConfigure --
#
#	Similar to checkConfigure except it keywords are not
#	requires to have a script associated to the next word.
#
# Arguments:
#	options		A list of switch/action pairs.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkFloatConfigure {exact options default tokens index} {
    set argc [llength $tokens]
    set start $index

    set script {}
    while {$index < $argc} {
	set word [lindex $tokens $index]
	if {![getLiteral $word value] \
		|| (![matchKeyword $options $value $exact script])} {
	    break
	}
	incr index
	if {$script != ""} {
	    set index [eval $script {$tokens $index}]
	}
    }

    if {$index < $argc} {
	if {$default != ""} {
	    set index [eval $default {$tokens $index}]
	}
	if {$index < $argc} {
	    set range [getTokenRange [lindex $tokens $index]]
	    if {$default != ""} {
		logError numArgs $range
	    } else {
		logError badSwitch $range $value
	    }
	    set index [checkCommand $tokens $index]
	}
    }
    return $index
}


# analyzer::matchKeyword --
#
#	Find the unique match for a string in a keyword table and return
#	the associated value.
#
# Arguments:
#	table	A list of keyword/value pairs.
#	str	The string to match.
#	exact	If 1, only exact matches are allowed, otherwise unique
#		abbreviations are considered valid matches.
#	varName	The name of a variable that will hold the resulting value.
#
# Results:
#	Returns 1 on a successful match, else 0.

proc analyzer::matchKeyword {table str exact varName} {
    upvar $varName result
    if {$str == ""} {
	foreach pair $table {
	    set key [lindex $pair 0]
	    if {$key == ""} {
		set result [lindex $pair 1]
		return 1
	    }
	}
	return 0
    }
    if {$exact} {
	set end end
    } else {
	set end [expr {[string length $str] - 1}]
    }
    set found ""
    foreach pair $table {
	set key [lindex $pair 0]
	if {[string compare $str [string range $key 0 $end]] == 0} {
	    # If the string matches exactly, return immediately.

	    if {$exact || ($end == ([string length $key]-1))} {
		set result [lindex $pair 1]
		return 1
	    } else {
		lappend found [lindex $pair 1]
	    }
	}
    }
    if {[llength $found] == 1} {
	set result [lindex $found 0]
	return 1
    } else {
	return 0
    }
}

# analyzer::checkNumArgs --
#
#	This function checks the command based on the number
#	of args in the command.  If the number of args in the
#	command is not in the command list, then a numArgs 
#	error is logged.
#
# Arguments:
#	chainList	A list of tuples.  The first element is
#			the number of args required in order to
#			eval the command.  The second element is
#			the cmd to eval.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkNumArgs {chainList tokens index} {
    set argc [expr {[llength $tokens] - $index}]
    set prevNum -1

    # LogError is called if argc does not match any of
    # the numArgs in the nested lists or does not have
    # the minimum required num args for infinite num args.
    # For example:  
    #   - "foo" can take 1 3 or many args.
    #   - The list looks like {{1 cmd} {3 cmd} {-1 cmd}}
    #   - LogError is only called when argc == 2 or argc == 0.

    foreach numCmds $chainList {
	foreach {nextNum cmd} $numCmds {}
	if {($nextNum == $argc) || ($nextNum == -1)} {
	    return [eval $cmd {$tokens $index}]
	} elseif {($prevNum < $argc) && ($argc < $nextNum)} {
	    break
	}
	set prevNum $nextNum
    }
    logError numArgs {}
    return [checkCommand $tokens $index]
}

# analyzer::checkListValues --
#
#	This function checks the elements of a list in the manner as checkSimpleArgs.
#
# Arguments:
#	min		The minimum number of list elements
#	max		The maximum number of list elements.  If -1, then the
#			last argument may be repeated.
#	argList		A list of scripts that should be called for
#			the corresponding element.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkListValues {min max argList tokens index} {
    set word [lindex $tokens $index]

    # First perform generic list checks

    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {[catch {parse list $literal {}} ranges]} {
	logError badList \
		[list [getLiteralPos $word [lindex $::errorCode 2]] 1] $ranges
	return [incr index]
    }


    # Construct an artificial token list for the elements of the list.
    # Note that this algorithm is incorrect if the list elements contain
    # backslash substitutions because it does not properly unquote things.

    set listTokens {}
    foreach range $ranges {
	set origRange [getLiteralRange $word $range]
	set quote [string index $literal [parse charindex $literal $range]]
	if {$quote == "\{" || $quote == "\""} {
	    set textRange [getLiteralRange $word \
		    [list [expr {[lindex $range 0]+1}] \
		    [expr {[lindex $range 1] - 2}]]]
	} else {
	    set textRange [getLiteralRange $word $range]
	}

	# We are constructing an artificial token list, in order for the
	# checkVarRef checker to flag warnings, we need to check for a
	# preceeding dollar sign, and give that token a "variable" type
	# instead of the generic "text" type.

	set type "text"
	if {[string index $literal [lindex $range 0]] == "\$"} {
	    set type "variable"
	}
	lappend listTokens [list word $origRange [list \
		[list $type $textRange {}]]]
    }

    # Verify that there are the correct number of fixed list elts and
    # not too many optional list elts.

    set eltc [llength $listTokens]
    if {$eltc < $min} {
	logError numListElts [getTokenRange $word]
    } elseif {($max != -1) && ($eltc > $max)} {
	logError numListElts [getTokenRange $word]
	set eltc $max
    }

    # Starting with the first element after the command name, invoke
    # the type checker associated with each element.  If there are more
    # elements than type commands, use the last command for all of the
    # remaining elements.

    set i 0
    while {$i < $eltc} {
	set i [eval [lindex $argList 0] {$listTokens $i}]
	if {[llength $argList] > 1} {
	    set argList [lrange $argList 1 end]
	}
    }
    return [incr index]
}

# analyzer::checkLevel --
#
#	This function attempts to determine if the next
#	word is a valid level.  If it is then it increments
#	the index and calls the chainCmd.  Otherwise it calls
#	the chainCmd without updating the index.
#
# Arguments:
#	chainCmd	The command to use to check the remainder of the
#			command line arguments.  This can not be null.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkLevel {chainCmd tokens index} {
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[string index $literal 0] == "#"} {
	    incr index
	    set level [string range $literal 1 end]
	    if {[catch {incr level}]} {
		logError badLevel [getTokenRange $word] $literal
	    }
	} elseif {![catch {incr literal}]} {
	    incr index
	}
    } elseif {[string index $literal 0] == "#"} {
	incr index
    }
    return [eval $chainCmd {$tokens $index}]
}

# analyzer::warn
#
#	Generate a warning and call another checker.
#
# Arguments:
#	type		The message id to use.
#	detail		The detail string for the message.
#	chainCmd	The command to use to check the remainder of the
#			command line arguments.  This may be null.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::warn {type detail chainCmd tokens index} {
    logError $type [getTokenRange [lindex $tokens [expr {$index - 1}]]] $detail
    if {$chainCmd != ""} {
	return [eval $chainCmd {$tokens $index}]
    } else {
	return [checkCommand $tokens $index]
    }
}

# Checkers for specific types --
#
#	Each type checker performs one or more checks on the type
#	of a given word.  If the word is not a literal value, then
#	it falls through to the generic checkWord procedure.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkBoolean {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a boolean value

    if {[getLiteral $word literal]} {
	if {[catch {clock format 1 -gmt $literal}]} {
	    logError badBoolean [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkInt {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's an integer (as opposed to a float.)

    if {[getLiteral $word literal]} {
	if {[catch {incr literal}]} {
	    logError badInt [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkFloat {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a float

    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    } 
    if {[catch {expr {abs($literal)}}]} {
	logError badFloat [getTokenRange $word]
    }
    return [incr index]
}

proc analyzer::checkWholeNum {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's an integer that is >= 0.

    if {[getLiteral $word literal]} {
	if {[catch {incr literal 0}]} {
	    logError badWholeNum [getTokenRange $word] $literal
	} elseif {$literal < 0} {
	    logError badWholeNum [getTokenRange $word] $literal
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkIndex {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a string then verify it's "end".
    # - it's an integer (as opposed to a float.)

    if {[getLiteral $word literal]} {
	if {[catch {incr literal}]} {
	    if {$literal != "end"} {
		logError badIndex [getTokenRange $word]
	    }
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkIndexExpr {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a string then verify it's "end", or "end-<integer>"
    # - it's an integer (as opposed to a float.)

    if {[getLiteral $word literal]} {
	set length [string length $literal]
	if {[string equal -length [expr {($length > 3) ? 3 : $length}] \
		"end" $literal]} {
	    if {$length <= 3} {
		return [incr index]
	    } elseif {[string equal "-" [string index $literal 3]]} {
		set literal [string range $literal 4 end]
		if {[catch {incr literal}]} {
		    logError badIndex [getTokenRange $word]
		}
		return [incr index]
	    } else {
		logError badIndex [getTokenRange $word]
	    }
		
	} elseif {[catch {incr literal}]} {
	    logError badIndex [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkByteNum {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's an integer between 0 and 255

    if {[getLiteral $word literal]} {
	if {[catch {incr literal}]} {
	    logError badByteNum [getTokenRange $word]
	} elseif {($literal < 1) || ($literal > 256)} {
	    logError badByteNum [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkList {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - the list command can parse it.

    if {[getLiteral $word literal]} {
	if {[catch {parse list $literal {}} msg]} {
	    logError badList \
		    [list [getLiteralPos $word [lindex $::errorCode 2]] 1] $msg
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkVarName {tokens index} {
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	checkVariable $literal [getTokenRange $word]
	return [incr index]
    } else {
	set subtokens [lindex $word 2]
	if {([llength $subtokens] >= 1) \
		&& ([lindex [lindex $subtokens 0] 0] == "variable")} {
	    logError warnVarRef [getTokenRange $word]
	} else {
	    return [checkWord $tokens $index]
	}
    }
    return [incr index]
}

proc analyzer::checkProcName {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a non-literal
    # - it's a built-in command
    # - it's a user-defined procedure
    # - it's an object command (starts with '.')

    if {[getLiteral $word cmdName]} {

	set systemCmdName [string trimleft $cmdName :]

	if {(![uproc::exists [context::top] $cmdName pInfo]) \
		&& (![info exists analyzer::checkers($systemCmdName)]) \
		&& ([string index $cmdName 0] != ".")} {

	    # This is a command that is neither defined by the 
	    # user or defiend to be a global proc.

	    if {[lsearch -exact $analyzer::unknownCmds $cmdName] == -1} {
		# Give a warning if this is the 1st time the
		# undefined proc is called.

		lappend analyzer::unknownCmds $cmdName
		logError warnUndefProc [getTokenRange $word] $cmdName
	    }
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

# analyzer::checkProcCall --
#
#	This function checks a procedure call where some fixed number of args
#	will be appended implicitly.  This proc fixes bugs 826, 883, and 1039.
#
#	Limitation:  If the proc is a system command, is non-literal or begins
#	with a dot, we don't check the number or validity of the args.
#
# Arguments:
#	argsToAdd	Number of non-literal args to append to the proc call.
#			Currently, this value is ignored, as we do not yet
#			check the number and validity of the proc's args.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc analyzer::checkProcCall {argsToAdd tokens index} {
    # If it's a non-literal proc call, just check that it's a valid word.
    # Otherwise, check that the first elt of the list is a valid proc name.

    set word [lindex $tokens $index]
    if {[getLiteral $word cmdName]} {
	if {[uproc::exists [context::top] $cmdName pInfo]} {
	    # HACK:  append "argsToAdd" extra empty elements to the "tokens"
	    # list.  This works because checkUserProc only uses "tokens" for
	    # its length.

	    set fakeTokens [list $word]
	    for {set i 1} {$i <= $argsToAdd} {incr i} {
		lappend fakeTokens $word
	    }

	    # Don't return the result of checkUserProc because it is affected
	    # by the fact that we've purturbed the token list.  Just assume the
	    # checkUserProc call went well and return the next index to check.

	    uproc::checkUserProc $cmdName $pInfo $fakeTokens 1
	    return [expr {$index + 1}]
	} else {
	    return [checkListValues 1 -1 {checkProcName checkWord} \
		    $tokens $index]
	}
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkFileName {tokens index} {
    set word [lindex $tokens $index]
    set hasSubst 0
    set result ""

    # Check to see if the word contains both a substitution and a directory
    # separator character.  This is probably a situation where "file join"
    # should be used.

    foreach token [lindex $word 2] {
	set type [lindex $token 0]
	if {($type == "variable") || ($type == "command")} {
	    set hasSubst 1
	} elseif {$type == "backslash"} {
	    append result [subst [parse getstring $::analyzer::script \
		    [lindex $token 1]]]
	} else {
	    append result [parse getstring $::analyzer::script \
		    [lindex $token 1]]
	}
    }
    if {$hasSubst && [regexp {[/\\:]} $result]} {
	logError nonPortFile [getTokenRange $word]
    }
    return [checkWord $tokens $index]
}

proc analyzer::checkChannelID {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - the id is file0, file1, or file2

    if {[getLiteral $word literal]} {
	if {[string match {file[0-2]} $literal]} {
	    logError nonPortChannel [getTokenRange $word] \
		    [lindex {stdin stdout stderr} [string index $literal 4]]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkArgList {tokens index} {
    set word [lindex $tokens $index]

    # Check to see if:
    # - the list command can parse it.
    # - no arguments follow "args".
    # - no args are variable references.
    # - no non-default args follow defaulted args (unless args.)
    # - defaulted args is a list of only two elements.
    # - args is not defaulted (e.g., proc foo {{args 2}} {})

    if {[getLiteral $word literal]} {
	checkList $tokens $index
    
	set defaultFound 0
	set argsFound    0
	set argAfterArgsFound   0
	set nonDefAfterDefFound 0

	# Ignore list parsing errors because they have already been reported
	# by checkList.
	catch {
	    foreach arg $literal {
		set defaultFlag  0
		set argsFlag     0
		
		if {[string index $arg 0] == "\$"} {
		    logError warnVarRef [getTokenRange $word]
		}
		if {[llength $arg] > 2} {
		    logError tooManyFieldArg [getTokenRange $word]
		    continue
		}

		if {[llength $arg] == 2} {
		    set defaultFlag 1
		    set arg [lindex $arg 0]
		}
		if {$arg == "args"} {
		    set argsFlag 1
		}
		
		if {$defaultFlag} {
		    set defaultFound 1
		} elseif {$defaultFound && !$argsFlag} {
		    if {!$nonDefAfterDefFound} {
			logError nonDefAfterDef [getTokenRange $word]
			set nonDefAfterDefFound 1
		    }
		}
		if {$argsFlag && !$argsFound} {
		    if {$defaultFlag} {
			logError argsNotDefault [getTokenRange $word]
		    }
		    set argsFound 1
		} elseif {$argsFound && !$argAfterArgsFound} {
		    logError argAfterArgs [getTokenRange $word]
		    set argAfterArgsFound 1
		}
	    }
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkEvalArgs {tokens index} {
    # Check to see if:
    # - there is a single literal argument that can be recursed into

    set argc [llength $tokens]
    if {($index != ($argc - 1)) \
	    || ![isLiteral [lindex $tokens $index]]} {
	return [checkCommand $tokens $index]
    }
    return [checkBody $tokens $index]
}

proc analyzer::checkNamespace {tokens index} {
    # Check to see if:
    # - the namespace is correctly qualified.
    
    return [checkWord $tokens $index]
}

proc analyzer::checkNamespacePattern {tokens index} {
    # Check to see if:
    # - there are glob characters before the last :: in a namespace pattern
    
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[regexp {[][\\*?]+.*::} $literal]} {
	    logError warnNamespacePat [getTokenRange $word]
	}
    }
    return [checkPattern $tokens $index]
}

proc analyzer::checkExportPattern {tokens index} {
    # Check to see if:
    # - there are any namespace qualifiers in the string
    
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[regexp {::} $literal]} {
	    logError warnExportPat [getTokenRange $word]
	}
	return [checkPattern $tokens $index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkPattern {tokens index} {
    # Check to see if:
    # - a pattern has a word with a mix of sub-commands and
    #   non-sub-commands.  If it does then they might have
    #   a bracketed sequence that was not correctly delimited.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	return [incr index]
    } else {
	set subCmdFound 0
	set nonCmdFound 0
	foreach subWord [lindex $word 2] {
	    if {[lindex $subWord 0] == "command"} {
		set subCmdFound 1
	    } else {
		set nonCmdFound 1
	    }
	    if {$subCmdFound && $nonCmdFound} {
		logError warnPattern [getTokenRange $word]
		break
	    }
	}
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkAccessMode {tokens index} {
    # If the word is a literal and begins with a capital letter
    # then check against POSIX access list.  Otherwise check 
    # against the standard Tcl access list.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[string match {[a-z]} [string index $literal 0]]} {
	    return [checkKeyword 1 {r r+ w w+ a a+} $tokens $index]
	}

	if {[catch {parse list $literal {}} ranges]} {
	    logError badList [list [getLiteralPos $word \
		    [lindex $::errorCode 2]] 1] $ranges
	    return [incr index]
	}
	
	# Make sure at least one of the read/write flags was 
	# specified (RDONLY, WRONLY or RDWR).  It is an error
	# to specify other w/o a read/write flag.

	set gotRW 0
	set modes {RDONLY WRONLY RDWR APPEND CREAT EXCL NOCTTY NONBLOCK TRUNC}
	foreach mode $literal range $ranges {
	    set i [lsearch -exact $modes $mode]
	    if {$i == -1} {
		logError badKey [getLiteralRange $word $range] $modes $mode
	    } elseif {$i >= 0 && $i <= 2} {
		set gotRW 1
	    }
	}
	if {!$gotRW} {
	    logError badMode [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }    
}

proc analyzer::checkResourceType {tokens index} {
    # Check to see if:
    # - The resource is a four letter word.  If it is not 
    #   just warn them of the error.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[string length $literal] != 4} {
	    logError badResource [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::checkVersion {tokens index} {
    # Check to see if:
    # - it's a valid version (it must have a decimal in it:  X.XX)

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }

    foreach ver [split $literal .] {
	if {[catch {incr ver}]} {
	    logError badVersion [getTokenRange $word]
	}
    }
    return [incr index]
}

proc analyzer::checkWinName {tokens index} {
    # Check to see if:
    # - the first character is "."
    # - the second character is a number or lowercase letter

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	
	if {[string index $literal 0] != "."} {
	    logError winBeginDot [getTokenRange $word]
	} else {
	    analyzer::CheckWinNameInternal $literal $word
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc analyzer::CheckWinNameInternal {name word} {
    set errIndex [lindex [getTokenRange $word] 0]
    set errLen   [lindex [getTokenRange $word] 1]
    set errPos   0
    
    foreach win [split [string range $name 1 end] .] {
	incr errPos 
	if {$win == {}} {
	    set errRange [list [expr {$errIndex + $errPos}] \
		    [expr {$errLen + $errPos}]]
	    logError winNotNull $errRange
	} elseif {[string match {[A-Z]*} $win]} {
	    set errRange [list [expr {$errIndex + $errPos}] \
		    [expr {$errLen + $errPos}]]
	    logError winAlpha $errRange
	}
	incr errPos [string length $win]
    }
    return
}

proc analyzer::checkColor {tokens index} {
    # Check #RBG format and known Windows colors for 8.0

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    analyzer::CheckColorInternal $literal $word
    return [incr index]
}

proc analyzer::CheckColorInternal {color word} {
    variable portableColors80

    # If the literal begind with a # sign, then check to
    # see if it the correct format.  Otherwise, verify
    # the specified color is portable.

    if {[string index $color 0] == "#"} {
	# If the length is not the correct number of 
	# digits, or the value of "integer" is not 
	# an integer, then log a color format error.
	
	set hex [string range $color 1 end]
	set len [string length $hex]
	if {[lsearch -exact {3 6 9 12} $len] < 0} {
	    logError badColorFormat [getTokenRange $word]
	} else {
	    set index 0
	    set range [expr {$len / 3}]
	    while {$index < $len} {
		set c "0x[string range $hex $index [expr {$index + $range - 1}]]"
		if {[catch {expr {abs($c)}}]} {
		    logError badColorFormat [getTokenRange $word]
		    break
		}
		incr index $range
	    }
	}	    
    } elseif {[lsearch -exact $portableColors80 $color] < 0} {
	logError nonPortColor [getTokenRange $word]
    }
    return
}

proc analyzer::checkPixels {tokens index} {
    # Check the pixel format: <float>?c,i,m,p?

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    
    set last [expr {[string length $literal] - 1}]
    if {[lsearch -exact {c i m p} [string index $literal $last]] >= 0} {
	set float [string range $literal 0 [expr {$last - 1}]]
    } else {
	set float $literal
    }
    if {[catch {expr {abs($float)}}]} {
	logError badPixel [getTokenRange $word]
    }
    return [incr index]
}

proc analyzer::checkCursor {tokens index} {
    # Check the followig patterns:
    # ""
    # name
    # "name fgColor"
    # "@sourceFile fgColor"
    # "name fgColor bgColor"
    # "@sourceFile maskFile fgColor bgColor"

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {[catch {llength $literal}]} {
	logError badCursor [getTokenRange $word] 
	return [incr index]
    }
    set parts [split $literal]
    switch -- [llength $parts] {
	0 {
	    # No-op
	}
	1 {
	    analyzer::CheckCursorInternal $parts $word  
	}
	2 {
	    logError nonPortCmd [getTokenRange $word]
	    set cursor [lindex $parts 0]
	    set color  [lindex $parts 1]
	    if {[string index $cursor 0] != "@"} {
		analyzer::CheckCursorInternal $cursor $word
	    }
	    analyzer::CheckColorInternal $color $word
	}
	3 {
	    logError nonPortCmd [getTokenRange $word]
	    set cursor [lindex $parts 0]
	    set color  [lindex $parts 1]
	    set mask   [lindex $parts 2]
	    analyzer::CheckCursorInternal $cursor $word
	    analyzer::CheckColorInternal $color $word
	    analyzer::CheckColorInternal $mask $word
	}
	4 {
	    logError nonPortCmd [getTokenRange $word]
	    set file  [lindex $parts 0]
	    set color [lindex $parts 2]
	    set mask  [lindex $parts 3]
	    if {[string index $file 0] != "@"} {
		logError badCursor [getTokenRange $word] 
	    }
	    analyzer::CheckColorInternal $color $word
	    analyzer::CheckColorInternal $mask $word
	}
	default {
	    logError badCursor [getTokenRange $word] 
	}
    }
    return [incr index]
}

proc analyzer::CheckCursorInternal {name word} {
    variable commonCursors
    variable winCursors
    variable macCursors

    # Verify the cursor name is defined across all platforms.

    if {[lsearch $commonCursors $name] < 0} {
	if {[lsearch $winCursors $name] >= 0} {
	    logError nonPortCursor [getTokenRange $word]
	} elseif {[lsearch $macCursors $name] >= 0} {
	    logError nonPortCursor [getTokenRange $word]
	} else {
	    logError badCursor [getTokenRange $word]
	}
    }
    return
}

proc analyzer::checkRelief {tokens index} {
    # Check the relief.  This is defined as a proc because there are three
    # switches that call the same routine (-relief, -activerelief and
    # -sliderelief.)

    return [checkKeyword 1 {raised sunken flat ridge solid groove} \
		$tokens $index]
}

