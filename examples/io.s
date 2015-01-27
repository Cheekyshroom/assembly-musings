(_comment Reads lines one at a time into a buffer of 512 bytes, until "quit" is entered)

(_inline (.bss) (.lcomm input_buffer, 512) (.data) (quit: .ascii "quit\n\0") (.text))

(_function _main_ ()
	(read_print_lines))

(_function read_print_lines ()
	(_read_terminate_string $input_buffer $512 $0)
	(_print_string $input_buffer $1)
	(_if (_equal_to (_string_compare $quit $input_buffer) $-1)
		((_identity $20))
		((read_print_lines))))
