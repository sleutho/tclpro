# lpage.tcl --
#
# Html Page Support for Ajuba Solutions License Server
#
# Copyright 1999-2000 Ajuba Solutions

package provide lpage 1.0
namespace eval lpage {
    namespace export *
}

# lpage::head
#
#	Generate the standard HTML page header.
#
# Arguments
#	section	Identifies major section
#	title	Page title
#
# Results
#	Html

proc lpage::head {section title} {
    global page
    set page(section) $section
    set page(title) $title
    set page(dynamic) 1
    set html "
<html>
<head>
<title>$section: $title</title>
</head>
<body bgcolor=white text=black>

<table>
<tr>
<td>
 <a href=/><img src=/images/AjubaLogo128.gif border=0></a>
 <img src=/images/LicenseServer.gif>
</td>
</tr>
<tr>

<td>
 <table cellpadding=6 cellspacing=0 border=0>
 <tr>
"
    set color white
    set col 0
    foreach {link label} $lpage::site(sections) {
	if {[string compare $label $section] == 0} {
	    set c #CCCCCC
	} else {
	    set c #999999
	}
	if {[Doc_IsLinkToSelf $link]} {
	    append html "<td bgcolor='$c'><font size=+1>$label</font></td>\n"	
	} else {
	    append html "<td bgcolor='$c'><a href='$link'><font size=+1>$label</font></a></td>\n"	
	}
	incr col
    }
    # A little elbow room for submenus
    append html "<td bgcolor='#999999' width=100><font size=+1>&nbsp;</font></td>\n"	
    incr col

    append html "</tr>\n"
    set color #CCCCCC
    if {[info exist lpage::site($section)]} {
	append html "<tr><td colspan='$col' bgcolor='$color'>\n"
	append html "<table cellpadding=6 cellspacing=0 border=0><tr>\n"
	foreach {link label} $lpage::site($section) {
	    if {[Doc_IsLinkToSelf $link]} {
		append html "<td bgcolor='$color'>$label</td>\n"	
	    } else {
		append html "<td bgcolor='$color'><a href='$link'>$label</a></td>\n"	
	    }
	}
	append html "</tr></table></td></tr>\n"
    }
    append html </table>\n

    append html "</td></tr></table>"

    if {[string compare $section "Home"] != 0} {
	append html "<h2>$title</h2>\n"
    }
    return $html
}

# lpage::headurl
#
#	Like lpage::head, but this sets up the page(url) global
#	variable because this is typically used from application-direct
#	URL handlers instead of page templates.
#
# Arguments
#	section	Identifies major section
#	title	Page title
#	url	Page url
#
# Results
#	Html

proc lpage::headurl {section title url} {
    global page
    set page(url) $url
    return [lpage::head $section $title]
}

# lpage::mainlink
#
#	Format a link
#
# Arguments
#	None
#
# Results
#	Html

proc lpage::mainlink {url label} {
    return "<p><font size=+1><a href='$url'>$label</a></font>"
}

# lpage::footer
#
#	Generate the standard HTML page footer.
#
# Arguments
#	None
#
# Results
#	Html

proc lpage::footer {} {
    variable footer
    variable site
    set html "<p>"
    append html "<font size=-1>"
    set sep ""

    set all {/index.tml Home}
    foreach {label sec} $site(sections) {
	if {[info exist site($sec)]} {
	    foreach {url label} $site($sec) {
		lappend all $url $label
	    }
	}
    }
    foreach {url page} $all {
	if {[Doc_IsLinkToSelf $url]} {
	    append html "$sep$page\n"
	} else {
	    append html "$sep<a href='$url'>$page</a>\n"
	}
	set sep " | "
    }
    if {[info exist ::version::copyright]} {
	append html "<p>$::version::copyright"
    }
    append html "</body></html>"
    return $html
}
