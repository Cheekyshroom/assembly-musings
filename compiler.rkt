;; will compile file of code into at&t x86_64 assembly as per my specifications
;; this file can include the standard library, and compiles as so
;; compiler file -o output.s
;; ->
;; as output.s -o output.o
;; ld output.o stdlibs.o -o a.out
;;
;; todo: write a gensym function for loops, then inline asm and function call
;;

(module compiler racket/base
  ;;(require racket/string)

  (define (string-index-of str char (start-index 0))
    (let ([length (string-length str)])
      (let loop ([i start-index])
        (if (< i string-length)
            (if (char=? char (string-ref str i))
                i
                (loop (add1 i)))
            #f)))) 

  (define (find-substring str substr (start-index 0))
    (let ([substr (string->list substr)])
      
  
  (define (make-gensym-generator (pconc-name "sym_"))
    (let ([current-value 0])
      (lambda ()
        (begin0
            (string-append pconc-name (number->string current-value))
          (set! current-value (+ current-value 1))))))
  
  (define name-gensym (make-gensym-generator))
  (define loop-gensym (make-gensym-generator "loop_"))
  (define loop-end-gensym (make-gensym-generator "lend_"))
  
  ;;converts a list into a long string of assembly
  (define (parse-list list)
    ())
     
  ;;spit string into lists of function applications
  (define (parse-string string)
    (let* ([start-i (find-substring string "___")]
           [end-i (find-substring string "___" (add1 start-i))])
      (if (and start-i end-i) ;;if we have a special directive
          (let ([word (substring string start-i end-i)])
            (cond [(string=? word "inline") #t]
                  [(string=? word "code") #t])))))
