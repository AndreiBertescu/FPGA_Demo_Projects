# input string
set input_string "
~~~~~
                 Hello world! :)
~~~~~~
          This FPGA has been alive for:
~~~~
               <----------------->
~
                  ` seconds.
~
	              <----------------->
~~~~~~~
"

# character code decoder 
proc get_hex_code {char} {
    switch $char {
        "a" { return 61 }
        "b" { return 62 }
        "c" { return 63 }
        "d" { return 64 }
        "e" { return 65 }
        "f" { return 66 }
        "g" { return 67 }
        "h" { return 68 }
        "i" { return 69 }
        "j" { return 6A }
        "k" { return 6B }
        "l" { return 6C }
        "m" { return 6D }
        "n" { return 6E }
        "o" { return 6F }
        "p" { return 70 }
        "q" { return 71 }
        "r" { return 72 }
        "s" { return 73 }
        "t" { return 74 }
        "u" { return 75 }
        "v" { return 76 }
        "w" { return 77 }
        "x" { return 78 }
        "y" { return 79 }
        "z" { return 7A }
        "A" { return 41 }
        "B" { return 42 }
        "C" { return 43 }
        "D" { return 44 }
        "E" { return 45 }
        "F" { return 46 }
        "G" { return 47 }
        "H" { return 48 }
        "I" { return 49 }
        "J" { return 4A }
        "K" { return 4B }
        "L" { return 4C }
        "M" { return 4D }
        "N" { return 4E }
        "O" { return 4F }
        "P" { return 50 }
        "Q" { return 51 }
        "R" { return 52 }
        "S" { return 53 }
        "T" { return 54 }
        "U" { return 55 }
        "V" { return 56 }
        "W" { return 57 }
        "X" { return 58 }
        "Y" { return 59 }
        "Z" { return 5A }
        "0" { return 30 }
        "1" { return 31 }
        "2" { return 32 }
        "3" { return 33 }
        "4" { return 34 }
        "5" { return 35 }
        "6" { return 36 }
        "7" { return 37 }
        "8" { return 38 }
        "9" { return 39 }
        "!" { return 3a }
        "#" { return 3b }
        "$" { return 3c }
        "%" { return 3d }
        "&" { return 3e }
        "(" { return 3f }
        ")" { return 20 }
        "*" { return 21 }
        "+" { return 22 }
        "." { return 23 }
        "-" { return 24 }
        ":" { return 25 }
        "<" { return 26 }
        "+" { return 27 }
        ">" { return 28 }
        "?" { return 29 }
        "@" { return 2a }
        "/" { return 2b }
        "~" { return 02 }
        default { return 00 }
    };
}

# infinite loop
set condition 0
while {$condition != 1} {

	set condition 0

	# itterate over each character
	for {set i 0} {$i < [string length $input_string]} {incr i} {
		set char [string index $input_string $i]
		set hex_code [get_hex_code $char]
		
		if {$char == "`"} {
			set seconds_dec [get_property INPUT_VALUE [get_hw_probes second_counter -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]]
			
			foreach digit [split $seconds_dec ""] {
				set hex_code [get_hex_code $digit]
		
				# set character
				set_property OUTPUT_VALUE $hex_code [get_hw_probes char_i -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
				commit_hw_vio [get_hw_probes {char_i} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]

				# increment change_cntr
				set current_value [get_property OUTPUT_VALUE [get_hw_probes change_cntr -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]]
				set new_value [expr ($current_value + 1) % 4]
				
				set_property OUTPUT_VALUE $new_value [get_hw_probes change_cntr -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
				commit_hw_vio [get_hw_probes {change_cntr} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
			}
		} else {
			# set character
			set_property OUTPUT_VALUE $hex_code [get_hw_probes char_i -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
			commit_hw_vio [get_hw_probes {char_i} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]

			# increment change_cntr
			set current_value [get_property OUTPUT_VALUE [get_hw_probes change_cntr -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]]
			set new_value [expr ($current_value + 1) % 4]
			
			set_property OUTPUT_VALUE $new_value [get_hw_probes change_cntr -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
			commit_hw_vio [get_hw_probes {change_cntr} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z010_1] -filter {CELL_NAME=~"vio_i"}]]
		}
	}
}