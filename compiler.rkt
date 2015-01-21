;; will compile file of code into at&t x86_64 assembly as per my specifications
;; this file can include the standard library, and compiles as so
;; compiler file -o output.s
;; ->
;; as output.s -o output.o
;; ld output.o stdlibs.o -o a.out
;;
;; to add.. macros, variables and assignment and function definitions

(module compiler racket/base
  (provide (all-defined-out))
  (require racket/port)
  (require racket/string)
  (require racket/pretty)

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

  (define (index-of-matching-paren string place)
    (let loop ([i place]
               [parenlevel 1])
      (cond [(= parenlevel 0) i]
            [(>= i (string-length string)) #f]
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

  (define (code-string->code-tree s)
    (let ([start (index-of-char s #\()])
      (if start
          (let ([end (index-of-matching-paren s (add1 start))])
            (append
             (string-split (substring s 0 start) " ")
             (list (code-string->code-tree
                    (substring s
                               (add1 start) 
                               (sub1 (index-of-matching-paren s (add1 start))))))
             (if (>= end (string-length s))
                 '()
                 (code-string->code-tree (substring s (add1 end))))))
          (string-split s " "))))

  (define function-prelude "\tpushq\t%rbx\n\tmovq\t%rsp, %rbx\n")
  (define function-postlude "\tmovq\t%rbx, %rsp\n\tpopq\t%rbx\n\tret\n")
  (define (function-epilogue argcount)
    (string-append "\taddq\t$" (number->string (* argcount 8)) ", %rsp\n"))
  (define (function-argument number)
    (string-append (number->string (+ 16 (* number 8))) "(%rbx)"))
  (define (function-call name)
    (string-append "\tcall\t" name "\n"))
  (define insertion-header ".text\n.global _start\n_start:\n")

  (define (function-argument-push args)
    (apply string-append 
           (reverse (map (lambda (arg)
                           (if (list? arg)
                               (string-append (function-call-expand arg)
                                              "\tpushq\t%rax\n")
                               (if (and (>= (string-length arg) (string-length "LOCAL")) (string=? (substring arg 0 (string-length "LOCAL")) "LOCAL"))
                                   (string-append "\tpushq\t" (function-argument (string->number (substring arg (string-length "LOCAL")))) "\n")
                                   (if (string=? "" arg)
                                       ""
                                       (string-append "\tpushq\t" arg "\n")))))
                         args))))

  (define (function-call-expand list)
    (string-append
     (function-argument-push (cdr list))
     (function-call (car list))
     (function-epilogue (length (cdr list)))))

  (define (parse-code syntax-tree)
    (pretty-print syntax-tree)
    (newline)
    (let ([type (hash-ref special-expansions 
                          (if (pair? syntax-tree) 
                              (if (pair? (car syntax-tree)) 
                                  (car (car syntax-tree)) 
                                  #t)
                              #t)
                          #f)])
      (if type
          (type syntax-tree)
          (do-function-applications syntax-tree))))

  (define (do-function-applications syntax-tree)
    (apply string-append
           (let loop ([c syntax-tree])
                     (if (null? c)
                         '()
                         (cons (function-call-expand (car c))
                               (loop (cdr c)))))))

  (define special-expansions 
    (hash "_defmacro" (lambda (syntax-tree) "#macro output ;)")
          "_defn" (lambda (syntax-tree)
                    (write syntax-tree)
                    (newline)
                    (write (cdr (cdr (car syntax-tree))))
                    (newline)
                    (string-append (cadr (car syntax-tree)) ":\n" ;;function name label
                                   function-prelude
                                   ;;(do-function-applications (cdr (cdr (car syntax-tree))))
                                   (apply string-append (map (lambda (subtree)
                                                               (parse-code subtree))
                                                             (cdr (cdr (car syntax-tree)))))
                                   function-postlude))
          "_inline" (lambda (syntax-tree)
                      (let ([final
                             (apply string-append 
                                    (map (lambda (line)
                                           (string-append "\t" (string-join line " ") "\n"))
                                         (cdr (car syntax-tree))))])
                        (write final)
                        (newline)
                        final))))

  (define (clean-string-of-spaces-properly string)
    (list->string
     (let loop ([i 0]
                [mode 'normal]);;(string-length string)]
       (if (= i (string-length string)) ;;if at the end
           '()
           (let ([char (string-ref string i)])
             (if (char=? char #\") ;;if we've encountered an end-quote or begin-quote
                 (cons char (loop (add1 i) (if (eq? mode 'quoted) 'normal 'quoted)))
                 (if (eq? mode 'quoted)
                     (cons char (loop (add1 i) 'quoted))
                     (if (char=? char #\space) ;;if we've hit a space or a string of spaces
                         (if (eq? mode 'already-spaced)
                             (loop (add1 i) 'already-spaced)
                             (cons char (loop (add1 i) 'already-spaced)))
                         (cons char (loop (add1 i) 'normal))))))))))

  (define (clean-string string)
    (clean-string-of-spaces-properly (string-replace (string-replace string "\n" " ") "\t" " ")))
                                           
  (define (parse-code-string string)
    (let ([code (code-string->code-tree (clean-string string))])
      (parse-code code)))

  (define (run-on-file input-filename output-filename)
    (let ([in (open-input-file input-filename)]
          [out (open-output-file output-filename #:exists 'replace)])
      (write-string (parse-code-string (port->string in)) out)
      (close-output-port out)
      (close-input-port in)))

  ;;when run from command line with two args will run
  (let ([args (current-command-line-arguments)])
    (when (= (vector-length args) 2)
      (run-on-file (vector-ref args 0) (vector-ref args 1))))
  )
