(_inline 
	(.data) 
		(buf: .ascii "Hello\n\0") 
		(filename: .ascii "barbaz.txt\0")
		(ERROR: .ascii "File not able to be created\n\0")
	(.text))

(_function onfile (name fd)
	(_set (_ref fd) (_open_file name (_or $2 (_or $1024 $64)) $0666))
	(_if (_equal_to fd $-1)
		((_print_string $ERROR $1)
		 (_exit_))
		((_print_string $buf fd)
		 (_close_file fd))))
	
(_function _main_ ()
	(onfile $filename $0))
