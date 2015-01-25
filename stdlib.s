#std constant definitions and variables
.global NEWLINE_CHAR
.global NULL_CHAR
.data
	NEWLINE_CHAR: .byte 10
	NULL_CHAR: .byte 0
.text

.global _start
.type _start, @function
_start:
	call	_main_
	call	_exit_
	ret

#syscalls and quits our program
.global _exit_
.type _exit_, @function
_exit_:
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
	ret

#adds arg1 and arg2 into rax
.global _add
.type _add, @function
_add:
	movq	16(%rsp), %rax #arg1->rax
	addq	8(%rsp), %rax #arg2+rax->rax
	ret
#subtracts arg2 from arg1 into rax
.global _sub
.type _sub, @function
_sub:
	movq	8(%rsp), %rax
	subq	16(%rsp), %rax
	ret

#multiplies arg1 by arg2 into rax
.global _mul
.type _mul, @function
_mul:
	movq	8(%rsp), %rax
	imulq	16(%rsp), %rax
	ret

#divides arg1 by arg2 into rax
.global _div
.type _div, @function
_div:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdx #save rdx
	
	movq	16(%rbx), %rax
	cqto	#sign extend rax to rdx:rax
	idivq	24(%rbx) #quotient now in rax, remainder in rdx
	
	movq	-8(%rbx), %rdx #restore rdx
	movq	%rbx, %rsp
	popq	%rbx
	ret

#divides arg1 by arg2 and puts remainder in rax
.global _mod
.type _mod, @function
_mod:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdx #save rdx
	
	movq	16(%rbx), %rax
	cqto	#sign extend rax to rdx:rax
	idivq	24(%rbx) #quotient now in rax, remainder in rdx
	movq	%rdx, %rax #remainder now in rax
	
	movq	-8(%rbx), %rdx #restore rdx
	movq	%rbx, %rsp
	popq	%rbx
	ret

#prints a single newline char
.global _print_newline
.type _print_newline, @function
_print_newline:
	pushq	$0
	pushq	$1 #length
	pushq	$NEWLINE_CHAR
	call	_write_string
	addq	$24, %rsp
	ret

#writes a string at addr arg1 of length arg2 to stdout
.global _write_string
.type _write_string, @function
_write_string:
	pushq	%rbx #save rbx
	movq	%rsp,	%rbx #save rsp
	#save regs used (except rax)
	push	%rdi
	push	%rsi
	push	%rdx
	#call sys_write
	movq	16(%rbx),	%rsi
	movq	24(%rbx), %rdx
	movq	$1,	%rax
	movq	32(%rbx),	%rdi
	syscall
	#load saved regs back
	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx

	movq	%rbx,	%rsp
	pop	%rbx
	ret

#writes the string at addr arg1 to some file descriptor
.global _print_string
.type _print_string, @function
_print_string:
	pushq	%rbx #save rbx
	movq	%rsp,	%rbx #save rsp
	
	#our arg to this fn is already on the stack in the right place
	pushq	16(%rbx)
	call	_string_length
	addq	$8, %rsp

	pushq	24(%rbx)
	pushq	%rax #arg2 to _write_string
	pushq	16(%rbx) #addr of string
	call	_write_string
	addq	$24, %rsp

	movq	%rbx,	%rsp
	pop	%rbx
	ret

#prints a byte at addr arg1 to some descriptor arg2
.global _print_byte
.type _print_byte, @function
_print_byte:
	pushq	%rbx
	movq	%rsp,	%rbx
	#call _write_string on a string of length 1
	pushq	24(%rbx)
	pushq	$1
	pushq	16(%rbx)
	call	_write_string
	addq	$24,	%rsp

	movq	%rbx,	%rsp
	popq	%rbx
	ret

.global _open_file
.type _open_file, @function
_open_file:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx

	movq	16(%rbx), %rdi
	movq	24(%rbx), %rsi
	movq	32(%rbx), %rdx
	movq	$2, %rax
	syscall

	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _close_file
.type _close_file, @function
_close_file:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdi

	movq	16(%rbx), %rdi
	movq	$3, %rax
	syscall

	movq	-8(%rbx), %rdi
	movq	%rbx, %rsp
	popq	%rbx
	ret

#converts its first argument (a quadword) to a decimal string
#arg1 contains the quadword, and arg2 the address of a string in which
#to put the word
#rax will contain the length of our target string
.global _quadword_to_string
.type _quadword_to_string, @function
_quadword_to_string:
	pushq	%rbx
	movq	%rsp, %rbx	
	pushq	%rdi #save two regs
	pushq	%rsi

	movq	16(%rbx), %rdi #the number in our current iteration
	movq	$0, %rsi #index in our output string
_loop1:
	
	incq	%rsi
_lend1:
	cmpq	$0, %rdi
	jg		_loop1

	movq	%rsi, %rax
	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	%rbx, %rsp
	pushq	%rbx
	ret

#reads a string of maximum length arg2 into addr arg1 and following
#returns length of string read
.global _read_string
.type _read_string, @function
_read_string:
	pushq	%rbx #save rbx
	movq	%rsp,	%rbx #save rsp
	#save regs used (except rax)
	push	%rdi
	push	%rsi
	push	%rdx

	#call the read syscall
	movq	$0, %rax #sys_read
	movq	32(%rbx), %rdi #from stdin
	movq	16(%rbx), %rsi #the addr to read into
	movq	24(%rbx), %rdx #the max length
	syscall

	#restore regs and quit
	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx
	movq	%rbx,	%rsp
	pop	%rbx
	ret

#reads a string of max length arg2 into addr arg1
#rax contains length too
.global _read_terminate_string
.type _read_terminate_string, @function
_read_terminate_string:
	pushq	%rbx
	movq	%rsp,	%rbx
	pushq	%rdi #save rdi
	movq	16(%rbx), %rdi

	pushq	32(%rbx)
	pushq	24(%rbx)
	pushq	%rdi
	call	_read_string #string length now in %rax
	addq	$24, %rsp
	movq	$0, (%rdi,%rax,1) #null terminate it
	
	movq	-8(%rbx), %rdi #restore rdi
	movq	%rbx,	%rsp
	popq	%rbx
	ret

#gets length of a null terminated string at addr arg1
.global _string_length
.type _string_length, @function
_string_length:	
	pushq	%rbx
	movq	%rsp,	%rbx
	pushq	%rdi #save rdi
	
	movq	16(%rbx), %rdi
	movq	$0, %rax #return value is length of string
	jmp	_lend0
_loop0:
	incq	%rax
_lend0:
	cmpb	$0x00, (%rdi,%rax,1)
	jne	_loop0

	movq	-8(%rbx), %rdi
	movq	%rbx,	%rsp
	popq	%rbx
	ret

.global _string_compare
.type _string_compare, @function
_string_compare:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	movq	16(%rbx), %rdi #addr of first string
	movq	24(%rbx), %rsi #addr of second string
	movq	$0, %rax #current string offset
	movb	$0, %dl #one byte's temp storage

_loop2:
	movb	(%rdi,%rax,1), %dl
	cmpb	%dl, (%rsi,%rax,1)
	jne	_string_compare_exit #exit failure as bytes aren't equal return index in string
	cmpb	$0, %dl #if both are equal, see if null, if yes, exit success
	je		_string_compare_exit_success
	incq	%rax
	jmp	_loop2

_string_compare_exit_success:
	movq	$-1, %rax #-1 is success for this subr

_string_compare_exit:
	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _char_at
.type _char_at, @function
_char_at:
	movq	8(%rsp), %r12
	movq	16(%rsp), %r13
	movb	(%r12,%r13,1), %al
	ret

.global _identity
.type _identity, @function
_identity:
	movq	8(%rsp), %rax
	ret

.global _equal_to
.type _equal_to, @function
_equal_to:
	movq	8(%rsp), %rax
	subq	16(%rsp), %rax
	ret

.global _greater_than
.type _greater_than, @function
_greater_than:
	pushq %rbx
	movq	%rsp, %rbx
	pushq	%rdi

	movq	16(%rbx), %rax
	cmpq	24(%rbx), %rax
	movq	$1, %rdi
	cmovlq %rdi, %rax
	movq	$0, %rdi
	cmovgq %rdi, %rax

	movq	-8(%rbx), %rdi
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _less_than
.type _less_than, @function
_less_than:
	pushq %rbx
	movq	%rsp, %rbx
	pushq	%rdi

	movq	16(%rbx), %rax
	cmpq	24(%rbx), %rax
	movq	$1, %rdi
	cmovgq %rdi, %rax
	movq	$0, %rdi
	cmovlq %rdi, %rax

	movq	-8(%rbx), %rdi
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _deref
.type _deref, @function
_deref:
	movq 8(%rsp), %rax
	movq	(%rax), %rax
	ret

.global _set
.type _set, @function
_set:
	pushq %rbx
	movq	%rsp, %rbx
	pushq	%rdi

	movq	16(%rbx), %rax
	movq	24(%rbx), %rdi
	movq	%rdi, (%rax)

	movq	-8(%rbx), %rdi
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _system_call
.type _system_call, @function
_system_call:
	pushq %rbx
	movq	%rsp, %rbx
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%r10
	pushq	%r8
	pushq	%r9

	movq 	16(%rbx), %rax
	movq	24(%rbx), %rdi
	movq	32(%rbx), %rsi
	movq	40(%rbx), %rdx
	movq	48(%rbx), %r10
	movq	56(%rbx), %r8
	movq	64(%rbx), %r9
	syscall

	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx
	movq	-32(%rbx), %r10
	movq	-40(%rbx), %r8
	movq	-48(%rbx), %r9
	movq	%rbx, %rsp
	popq	%rbx
	ret

.global _xor
.type _xor, @function
_xor:
	movq	8(%rsp), %rax
	xorq	16(%rsp), %rax
	ret

.global _and
.type _and, @function
_and:
	movq	8(%rsp), %rax
	andq	16(%rsp), %rax
	ret

.global _or
.type _or, @function
_or:
	movq	8(%rsp), %rax
	orq	16(%rsp), %rax
	ret

.global _not
.type _not, @function
_not:
	movq	8(%rsp), %rax
	notq	%rax
	ret
