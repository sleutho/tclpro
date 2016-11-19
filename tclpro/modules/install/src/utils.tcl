# utils.tcl

# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.

# SCCS: @(#) utils.tcl 1.10 97/06/26 15:10:59

package provide utils 1.0

# Stderr - print to standard error

proc Stderr {string} {
    catch {puts stderr $string}
}
# iscommand - returns true if the command is defined  or lives in auto_index.

proc iscommand {name} {
    global auto_index
    expr {([info command $name] == $name) || [info exists auto_index($name)]}
}

# lappendOnce - add to a list if not already there

proc lappendOnce {listName value} {
    upvar $listName list
    if ![info exists list] {
	lappend list $value
    } else {
	set ix [lsearch $list $value]
	if {$ix < 0} {
	    lappend list $value
	}
    }
}

# setmax - set the variable to the maximum of its current value
# or the value of the second argument
# return 1 if the variable's value was changed.

proc setmax {varName value} {
    upvar $varName var
    if {![info exists var] || ($value > $var)} {
	set var $value
	return 1
    } 
    return 0
}

# setmin - set the variable to the minimum of its current value
# or the value of the second argument
# return 1 if the variable's value was changed.

proc setmin {varName value} {
    upvar $varName var
    if {![info exists var] || ($value < $var)} {
	set var $value
	return 1
    } 
    return 0
}

# Incr - version of incr that handles undefined variables.

proc Incr {varName {value 1}} {
    upvar $varName var
    if {![info exists var]} {
	set var $value
    }  else {
	set var [expr $var + $value]
    }
}

# Assign a set of variables from a list of values, a la TclX.
# If there are more values than variables, they are returned.
# If there are fewer values than variables, the variables get the empty string.

proc lassign {valueList args} {
    if {[llength $args] == 0} {
	error "wrong # args: lassign list varname ?varname..?"
    }
    if {[llength $valueList] == 0} {
	foreach x $args {
	    uplevel 1 [list set $x {}]
	}
    } else {
	uplevel 1 [list foreach $args $valueList {break}]
    }
    return [lrange $valueList [llength $args] end]
}
# Assign a set of variables from a list of values.
# If there are more values than variables, they are ignored.
# If there are fewer values than variables, the variables get the empty string.

proc lassign-brent {varList value} {
    if {[string length $value] == 0} {
	foreach var $varList {
	    uplevel [list set $var {}]
	}
    } else {
	uplevel [list foreach $varList $value { break }]
    }
}

# Delete a list item by value.  Returns 1 if the item was present, else 0

proc ldelete {varList value} {
    upvar $varList list
    if ![info exist list] {
	return 0
    }
    set ix [lsearch $list $value]
    if {$ix >= 0} {
	set list [lreplace $list $ix $ix]
	return 1
    } else {
	return 0
    }
}

# see if an option matches a list of options
# return full option name if it does, otherwise ""
#  option:  the name of the option (or unique prefix)
#  list:    the list of valid options (e.g. -foo -bar ...)

proc matchOption {option list} {
    if {![regexp -- {-[a-zA-Z0-9:_-]+} $option]} {
    	error "Invalid option: \"$option\""
    }
    if {[regsub -all -- "$option\[^ \]*" $list {} {}] == 1} {
    	regexp -- "$option\[^ \]*" $list result
    	return $result
    } else {
    	return ""
    }
}

# Set local variables based on defaults - passed in as an array, and
# a set of name value pairs.  The "params" always override the current setting
# of the local variables; the defaults only get set if no vars exist.
#   array: name of the array (with default values)
#   params:  The "-name value" pairs to set

proc optionSet {array params} {
    upvar $array options
    set list [array names options -*]
    foreach {option value} $params {
	set realoption [matchOption $option $list]
	if {$realoption != ""} {
	    regexp -- {-(.*)} $realoption {} var
	    uplevel [list set $var $value]
	}
    }

    foreach {name value} [array get options -*] {
	regexp -- {-(.*)} $name {} var
	upvar $var set
	if {![info exists set]} {
	    uplevel [list set $var $value]
	}
    }
}

# "configure" for options in an array
#   name:  The name of the array containing the options
#   args:  The name value pairs

proc optionConfigure {name args} {
    upvar $name data

    set len [llength $args]
    set list [array names data -*]
    if {$len > 1 && ($len % 2) == 1} {
    	return -code error "optionConfigure Must have 1 or even number of arguments"
    }
    set result ""

    # return entire configuration list

    if {$len == 0} {
    	foreach option [lsort $list] {
	    lappend result $option $data($option)
	}

    # return a single configuration value

    } elseif {$len == 1} {
    	set option [matchOption $args $list]
    	if {$option == ""} {
	    return -code error "$args is an invalid option, should be one of: [join $list ", "]."
	}
	set result $data($option)

    # Set a bunch of options

    } else {
    	foreach {option value} $args {
	    set realoption [matchOption $option $list]
	    if {$realoption == ""} {
		return -code error "$option is an invalid option, should be one of: [join $list ", "]."
	    }
	    if {[info exists data(validate$realoption)]} {
	    	eval $data(validate$realoption) {data $realoption $value}
	    } else {
		set data($realoption) $value
	    }
	}
    }
    return $result
}


# print an import array 

proc poptions {array args} {
    upvar $array data
    puts "*** $array *** $args"
    foreach name [array names data] {
    	regexp -- {-(.*)} $name {} var
    	upvar $var value
    	if {[info exists value]} {
	    puts "${array}($var) = $value"
    	} else {
	    puts "${array}($var) = <unset>"
    	}
    }
}

proc ChopLine {line {limit 72}} {
    regsub -all " *\n" $line " " line
    set new {}
    while {[string length $line] > $limit} {
	set hit 0
	for {set c $limit} {$c >= 0} {incr c -1} {
	    set char [string index $line $c]
	    if [regexp \[\ \t\n>/\] $char] {
		set hit 1
		break
	    }
	}
	if !$hit {
	    set c $limit
	}
	append new [string trimright [string range $line 0 $c]]\n
	incr c
	set line [string range $line $c end]
    }
    append new "$line"
    return $new
}

# boolean --
#
#	Convert boolean values to 0/1
#
# Arguments:
#	value	boolean value: true/false, on/off, yes/no, etc
#
# Results:
#	Returns 0 or 1.

proc boolean value {
    if {!([regsub {^(1|yes|true|on)$} $value 1 value] || \
	  [regsub {^(0|no|false|off)$} $value 0 value])} {
	error "boolean value expected"
    }
    return $value
}
