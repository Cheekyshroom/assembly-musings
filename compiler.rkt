; will compile file of code into at&t x86_64 assembly as per my specifications
; this file can include the standard library, and compiles as so
; compiler file -o output.s
; as output.s -o output.o
; ld output.o stdlibs.o -o a.out
;
; todo: write a gensym function for loops, then inline asm and function call
;

(define (make-gensym-generator (pconc-name "sym_"))
  (let ([current-value 0])
    (lambda ()
      (begin0
	  (string-append pconc-name (number->string current-value))
	(set! current-value (+ current-value 1))))))

(define my-gensym (make-gensym-generator))

;converts a list into a long string of assembly
(define (parse-list list)
  (

; spit string into lists of function applications
(define (parse-string 
