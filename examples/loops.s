(_comment counts down from 10 to 0)

(_inline (.data) (mes: .ascii "Helloooo\n\0") (.text))
(_inline (.data) (digits: .ascii "0123456789\0") (.text))

(_function pn (n fd)
	(_if (_or (_equal_to n $0) (_less_than n $0))
		((_identity n))
		((pn (_div n $10) fd)
		 (_print_byte (_add $digits (_mod n $10)) fd))))

(_function _print_number (n fd)
	(_if (_equal_to n $0)
		((_print_byte $digits fd))
		((pn n fd))))

(_function other_fn (times message)
	(_loop (_greater_than times $0)
		((_print_number times (_deref $STDOUT))
		 (_print_newline (_deref $STDOUT))
		 (_set (_ref times) (_sub times $1)))))

(_function _main_ ()
	(other_fn $10 $mes))
