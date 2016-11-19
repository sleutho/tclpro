puts "testing stack..."

source itclstack.tcl

ItclStack a

set nums [list]

for {set i 0} {$i < 45} {incr i} {
    a push [set num [expr {int(rand() * 131070) - 65535}]]
    set nums [lreplace $nums 0 0 $num]
}


foreach x $nums {
    if {[set y [a pop]] != $x} {puts "error got $y not $x!"}
}

puts "done.  Press return to exit"
gets stdin
exit

