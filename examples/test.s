(_inline
	(.data)
	(strings: .ascii "Zero \0" "One  \0" "Two  \0" "Three\0" "Four \0" "Five \0" "Six  \0")
	(.text))

(_function _print_string_by_number (number)
	(_print_string (_add (_mul number $6) $strings))
	(_print_newline))

(_function _print_strings (i)
	(_if (_equal i $0)
		((_identity i))
		((_print_string_by_number i)
		 (_print_strings (_sub i $1)))))

(_function _fn_with_mutation (foo bar)
	(_comment mutate foo to 30 (only affects it locally as we didn't get a ref of it from outside this fn))
	(_set (_ref foo) $30)
	(_identity foo))

(_function _make_var_10 (var)
	(_set var $10))

(_function _test (foo bar baz)
	(_make_var_10 (_ref foo))
	(_identity foo))

(_function _main_ ()
	(_print_strings $6)
	(_fn_with_mutation $10 $4)
	(_test $1 $2 $3))
