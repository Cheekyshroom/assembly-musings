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
  (provide (all-defined-out))
  (require racket/port)

  (define (index-of-char str char (start-index 0))
    (let ([length (string-length str)])
      (let loop ([i start-index])
        (if (< i length)
            (if (char=? char (string-ref str i))
                i
                (loop (add1 i)))
            #f))))

  (define (index-of-substring str substr (start-index 0))
    (let ([sublist (string->list substr)])
      (let outer-loop ([start-index 
                        (index-of-char str (car sublist) start-index)])
        (if start-index
            (let inner-loop ([i start-index]
                             [cs sublist])
              (cond [(null? cs) start-index]
                    [(>= i (string-length str)) #f]
                    [(char=? (car cs) (string-ref str i)) 
                     (inner-loop (add1 i) (cdr cs))]
                    [else 
                     (outer-loop (index-of-char str (car sublist) (add1 i)))]))
            #f))))
        
  (define (make-gensym-generator (pconc-name "sym_"))
    (let ([current-value 0])
      (lambda ()
        (begin0
            (string-append pconc-name (number->string current-value))
          (set! current-value (+ current-value 1))))))
  
  (define name-gensym (make-gensym-generator))
  (define loop-gensym (make-gensym-generator "loop_"))
  (define loop-end-gensym (make-gensym-generator "lend_"))
  (define function-prelude "\tpushq\t%rbx\n\tmovq\t%rsp, %rbx\n")
  (define function-postlude "\tmovq\t%rbx, %rsp\n\tpopq\t%rbx\n\tret\n")
  
  ;;i points to the first # in ##token
  (define (get-token string i)
    (list->string (for/list ([ch (in-string string (+ i 2))]
                             #:break (or (char=? ch #\newline)
                                         (char=? ch #\space)))
                    ch)))

  ;;gets a list of the locations of all the 'special tokens' in a string
  ;;and token data as a string
  (define (special-tokens string)
    (let loop ([i (index-of-substring string "##")])
      (if i
          (cons (cons (get-token string i) i) 
                (loop (index-of-substring string "##" (add1 i))))
          '())))

  (define (handle-token string token token-handlers)
    ((hash-ref token-handlers (car token)) string token))

  (define (token-string-start token)
    (+ (cdr token) 2 (string-length (car token))))

  (define (parse-string string token-handlers)
    (let loop ([tokens (special-tokens string)])
      (if (null? tokens)
          ""
          (string-append 
           (handle-token 
            (substring string
                       (token-string-start (car tokens))
                       (if (null? (cdr tokens))
                           (string-length string)
                           (cdr (cadr tokens))))
            (car tokens)
            token-handlers)
           (loop (cdr tokens))))))

  ;;parses a code string into a list of (perhaps nested) function calls
  ;;like
  ;;(foo 1 2 3)
  ;;(bar 2)
  ;;(fi (foo 4 5 6) 10)
  ;;becomes
  ;;'((foo 1 2 3) (bar 2) (fi (foo 4 5 6) 10))
  (define (index-of-matching-paren string place)
    (let loop ([i place]
               [parenlevel 1])
      (cond [(>= i (string-length string)) #f]
            [(= parenlevel 0) i]
            [else (loop (add1 i)
                        (case (string-ref string i)
                          [(#\() (add1 parenlevel)]
                          [(#\)) (sub1 parenlevel)]
                          [else parenlevel]))])))

  (define (get-index-of-matching-paren string start-index)
    (let ([first-paren (index-of-char string #\( start-index)])
      (if first-paren
          (index-of-matching-paren string (add1 first-paren))
          #f)))

  (define (code-string->code-tree string)
    (let loop ([i (index-of-char string #\( 0)])
      (if i
          (let ([end (index-of-matching-paren string (add1 i))])
            (if (and (< i (string-length string)) end)
                (cons (substring string i end) 
                      (loop (index-of-char string #\( (add1 end))))
                '()))
          '())))
          
  (define (parse-code-string string token)
    (let ([code (code-string->code-tree string)])
      code))
  
  (define (parse-inline-string string token)
    string)

  (define token-handlers
    (hash "inline" parse-inline-string
          "code" parse-code-string
          "comment" (lambda (string token) "")))

  (define (run-on-file input-filename output-filename)
    (let ([in (open-input-file input-filename)]
          [out (open-output-file output-filename #:exists 'replace)])
      (write-string (parse-string (port->string in) token-handlers) out)
      (close-output-port out)
      (close-input-port in)))

  (define (run)
    (let ([args (current-command-line-arguments)])
      (run-on-file (vector-ref args 0) (vector-ref args 1))))
  ;;(run)
  )
