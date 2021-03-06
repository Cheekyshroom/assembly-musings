(_inline (.data) (digits: .ascii "0123456789-\0") (.text))
(_function pn (n fd)
	(_if (_equal_to n $0)
		((_identity n))
		(_if (_less_than n $0)
			((_print_byte (_add $digits $10) fd)
			 (pn (_sub $0 n) fd))
  			((pn (_div n $10) fd)
			 (_print_byte (_add $digits (_mod n $10)) fd)))))

(_function _print_number (n fd)
	(_if (_equal_to n $0)
		((_print_byte $digits fd))
		((pn n fd))))

(_function _main_ ()
	(_print_number $-3469102 (_deref $STDOUT))
	(_print_newline (_deref $STDOUT)))
