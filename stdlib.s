.text
.global _start
.type _start, @function
_start:
	call	_program_insertion
	call	_exit
	ret

#std constant definitions and variables
.data
	NEWLINE_CHAR: .byte 10
	NULL_CHAR: .byte 0
.global NEWLINE_CHAR
.global NULL_CHAR

#function simplifyers

#16(%rbx) .equ arg0

#std functions
.text

#sets (arg1) to arg2
.global _set
.type _set, @function
_set:
	pushq %rsi
	movq	16(%rsp), %rsi
	movq	8(%rsp), %rax
	movq	%rsi, (%rax)
	popq	%rsi
	ret

#syscalls and quits our program
.global _exit_program
.type _exit_program, @function
_exit_program:
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
	ret

#adds arg1 and arg2 into rax
.global _add
.type _add, @function
_add:
	movq	8(%rsp), %rax #arg1->rax
	addq	16(%rsp), %rax #arg2+rax->rax
	ret
#subtracts arg2 from arg1 into rax
.global _sub
.type _sub, @function
_sub:
	movq	8(%rsp), %rax
	subq	16(%rsp), %rax
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

#.global _move
#.type _move, @function
#moves memory1 into memory 2
#_move:

#prints a single newline char
.global _print_newline
.type _print_newline, @function
_print_newline:
	pushq	$1 #length
	pushq	$NEWLINE_CHAR
	call	_write_string
	addq	$16, %rsp
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
	movq	$1,	%rdi
	syscall
	#load saved regs back
	movq	-8(%rbx), %rdi
	movq	-16(%rbx), %rsi
	movq	-24(%rbx), %rdx

	movq	%rbx,	%rsp
	pop	%rbx
	ret

#writes the string at addr arg1 to stdout (null terminated)
.global _print_string
.type _print_string, @function
_print_string:
	pushq	%rbx #save rbx
	movq	%rsp,	%rbx #save rsp
	
	#our arg to this fn is already on the stack in the right place
	push	16(%rbx)
	call	_string_length
	addq	$8, %rsp

	push	%rax #arg2 to _write_string
	push	16(%rbx) #addr of string
	call	_write_string
	addq	$16, %rsp

	movq	%rbx,	%rsp
	pop	%rbx
	ret

#prints a byte at addr arg1
.global _print_byte
.type _print_byte, @function
_print_byte:
	pushq	%rbx
	movq	%rsp,	%rbx
	#call _write_string on a string of length 1
	pushq	$1
	pushq	16(%rbx)
	call	_write_string
	#addq	$16,	%rsp

	movq	%rbx,	%rsp
	popq	%rbx
	ret

#(define (n->l i)
#	   (let ([out (make-string 20 #\space)])
#	     (let loop ([i i]
#			[index 0])
#	       (unless (<= i 0)
#		 (string-set! out index (integer->char (+ 48 (modulo i 10))))
#		 (loop (floor (/ i 10)) (+ index 1))))
#	     out))


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

.global _reverse_bytes
.type _reverse_bytes, @function
_reverse_bytes:
	pushq	%rbx
	movq	%rsp, %rbx
	pushq	%rdi #save one index
	

_loop3:
	
_lend3:
	
	movq	%rbx, %rsp
	popq	%rbx
	ret

#.global _putchar
#.type _putchar, @function
#.data
#	_putchar_tmp_slot: .byte 0
#.text
#_putchar:
#	pushq	%rbx
#	movq	%rsp,	%rbx
#	push	%rdi #save rdi
#
#	movb	9(%rbx), %dil #$_putchar_tmp_slot
#	movb	%dil,	_putchar_tmp_slot
#	pushq $_putchar_tmp_slot
#	call	_print_byte
#	#addq	$8, %rsp
#
#	movq	-8(%rbx), %rdi
#	movq	%rbx,	%rsp
#	popq	%rbx
#	ret

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
	movq	$0, %rdi #from stdin
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

	pushq	24(%rbx)
	pushq	%rdi
	call	_read_string #string length now in %rax
	addq	$8, %rsp
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
	movq	16(%rsp), %r12
	movq	24(%rsp), %r13
	movb	(%r12,%r13,1), %al
	ret

.global _if
.type _if, @function


#gets an amount of memory and returns an addr on the stack with that much above it
.global _allocate_memory
.type _allocate_memory, @function
	
