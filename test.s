(_inline
	(.data)
	(strings: .ascii "Zero \0" "One  \0" "Two  \0" "Three\0" "Four \0" "Five \0" "Six  \0")
	(.text))

(_function _print_string_by_number (number)
	(_print_string (_add (_mul number $6) $strings))
	(_print_newline))

(_function _main_ ()
	(_inline 
		(movq	$6, %rsi)
		(_loop_start:))
	(_print_string_by_number %rsi)
	(_inline
		(decq	%rsi) 
		(cmpq	$0, %rsi)
		(jne	_loop_start)))
