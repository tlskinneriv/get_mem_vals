# Thomas Skinner
# Fall 2018, EEL5934
# Exp10, get_mem_vals.tcl

# Gets values from memory in binary and prints to a file. Waits for human input.
# This script needs to be sourced into the quartus_stp_tcl.exe executable.
# This executable is located in the path "<quartus_install_path>/quartus/bin64" 
# in an install on a Windows 10 x64 machine.

# In the TCL console, change to the directory of the script [using pwd and cd] 
# (ensure there are write permissions here), then run the command "source get_mem_vals.tcl"
# to bring in the contents of the script. Simply run the command "get_mem_vals [start_count]"
# to start collecting and writing values. Setting the argument "start_count" to a number will
# start the pattern counter at that point. When "start_count" is set to a number other than 0,
# then the script simply appends the file if it exists, otherwise if set to zero (is this way
# by default), then it will overwrite the file if it exists.


proc pause {{message "Hit Enter to continue ==> "}} {
    puts -nonewline $message
    flush stdout
    gets stdin
}

#copied from https://wiki.tcl-lang.org/page/Binary+representation+of+numbers
proc dec2bin {i {width {}}} {
    #returns the binary representation of $i
    # width determines the length of the returned string (left truncated or added left 0)
    # use of width allows concatenation of bits sub-fields

    set res {}
    if {$i<0} {
        set sign -
        set i [expr {abs($i)}]
    } else {
        set sign {}
    }
    while {$i>0} {
        set res [expr {$i%2}]$res
        set i [expr {$i/2}]
    }
    if {$res eq {}} {set res 0}

    if {$width ne {}} {
        append d [string repeat 0 $width] $res
        set res [string range $d [string length $res] end]
    }
    return $sign$res
}

proc get_mem_vals { {start_count 0} } {
	# get the start count as an integer
	set count 0; list
	scan $start_count %d count; list
	if {$start_count < 0 || $start_count > 128} {
		puts "start_count must be in the range \[0, 128\]"
		return
	}
	
	# get the device (should be index 0 in the JTAG chain)
	set hw "[lindex [get_hardware_names] 0]"; list
	set dev "[lindex [get_device_names -hardware_name $hw] 0]"; list

	set filename "output.txt"; list
	# clears out the file if starting count
	if {$count == 0} {
		set fileId [open $filename w]; list
		close $fileId; list
	}
	
	# test getting memory
	begin_memory_edit -device_name $dev -hardware_name $hw; list
	set mem_content_bin [read_content_from_memory -instance_index 0 -start_address 0 -word_count 1]; list
	end_memory_edit; list
	
	# loop through and wait for human action to get memory vals, last pattern is no fault
	while {1} {
		if { $count == 128 } {
			set pattern "no fault (S9:0)"; list
		} else {
			set pattern "fault in bit $count (S9:1, S6-S0:[dec2bin $count 7])"; list
		}
		set msg "Set the pattern to $pattern, then press enter"; list
		pause $msg
		begin_memory_edit -device_name $dev -hardware_name $hw; list
		set mem_content_bin [read_content_from_memory -instance_index 0 -start_address 0 -word_count 1]; list
		set fileId [open $filename a+]; list
		puts $fileId "$count:$mem_content_bin"; list
		close $fileId; list
		incr count; list
		end_memory_edit; list
		if {$count == 129} {
			puts "Done capturing"
			return
		}
	}
}