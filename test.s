(_inline
	(.data)
	(string0: .ascii "Zero \0")
	(string1: .ascii "One  \0")
	(string2: .ascii "Two  \0")
	(string3: .ascii "Three\0")
	(string4: .ascii "Four \0")
	(string5: .ascii "Five \0")
	(string6: .ascii "Six  \0")
	(.text))

(_function _print_string_by_number (number)
	(_print_string (_add (_mul number $6) $string0))
	(_print_newline))

(_function _main_ ()
	(_inline 
		(movq	$5, %rsi)
		(_loop_start:))
	(_print_string_by_number %rsi)
	(_inline
		(decq	%rsi) 
		(cmpq	$0, %rsi)
		(jne	_loop_start)))



