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

  (define (clean-string-of-spaces-properly string)
    (list->string
     (let loop ([i 0]
                [m 'n])
       (if (= i (string-length string))
           '()
           (let ([char (string-ref string i)])
             (cond [(char=? char #\") 
                    (cons char (loop (add1 i) (if (eq? m 'q) 'n 'q)))]
                   [(eq? m 'q)
                    (cons char (loop (add1 i) 'q))]
                   [(char=? char #\space)
                    (if (eq? m 'a)
                        (loop (add1 i) 'a)
                        (cons char (loop (add1 i) 'a)))]
                   [else
                    (cons char (loop (add1 i) 'n))]))))))

  (define (clean-string string)
    (clean-string-of-spaces-properly 
     (string-replace (string-replace string "\n" " ") "\t" " ")))

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






  (define (do-function-applications tree)
    (format "FUNCTION_APPLICATION ~a  ~%" tree))

  (define (make-gensym-generator (pconc-name "sym_"))
    (let ([current-value 0])
      (lambda ()
        (begin0
            (string-append pconc-name (number->string current-value))
          (set! current-value (+ current-value 1))))))


  (define (function-globalize-name name)
    (string-append ".global " name "\n.type " name ", @function\n"))
  (define function-prologue "\tpushq\t%rbx\n\tmovq\t%rsp, %rbx\n")
  (define function-epilogue "\tmovq\t%rbx, %rsp\n\tpopq\t%rbx\n\tret\n")
  (define (function-argument-cleanup argcount)
    (string-append "\taddq\t$" (number->string (* argcount 8)) ", %rsp\n"))
  (define (function-argument number)
    (string-append (number->string (+ 16 (* number 8))) "(%rbx)"))
  (define (function-call name)
    (string-append "\tcall\t" name "\n"))

  (define (index-of-binding vars var)
    (let loop ([c vars] [i 0])
      (cond [(null? c) #f]
            [(string=? var (car c)) i]
            [else
             (loop (cdr c) (add1 i))])))

  (define (function-argument-push args variable-names)
    (apply
     string-append
     (reverse
      (map (lambda (arg)
             (if (list? arg)
                 (string-append (function-application-expand arg variable-names)
                                "\tpushq\t%rax\n")
                 (let ([var (index-of-binding variable-names arg)])
                   (if var ;;if it matches a variable name
                       (string-append "\tpushq\t" (function-argument var) "\n")
                       (if (string=? "" arg)
                           ""
                           (string-append "\tpushq\t" arg "\n"))))))
           args))))

  (define (function-application-expand tree arg-environment)
    (string-append
     (function-argument-push (cdr tree) arg-environment)
     (function-call (car tree))
     (function-argument-cleanup (length (cdr tree)))))

  (define (macro-creation-expand tree)
    "")

  (define (function-creation-expand tree)
    (string-append (function-globalize-name (cadr tree)) ;;.global fn.. etc
                   (cadr tree) ":\n" ;;function name label
                   function-prologue
                   (apply string-append
                          (map (lambda (subtree)
                                 (parse-code subtree (caddr tree)))
                               (cdr (cdr (cdr tree)))))
                   function-epilogue))

  (define (inline-creation-expand tree)
    (apply string-append
           (map (lambda (line)
                  (string-append "\t" (string-join line " ") "\n"))

                (cdr tree))))

  (define (loop-creation-expand tree)
    "")

  (define special-tokens 
    (hash "_macro" macro-creation-expand
          "_function" function-creation-expand
          "_inline" inline-creation-expand
          "_loop" loop-creation-expand
          "_comment" (lambda (tree) "")))

  (define (parse-code tree (arg-environment '()))
    (printf "Parse-Code~%")
    (pretty-print tree)
    (if (list? tree)
        (apply 
         string-append
         (for/list ([subtree (in-list tree)])
           (if (list? subtree)
               (let ([special (hash-ref special-tokens (car subtree) #f)])
                 (if special
                     (special subtree) ;;if it's a special token
                     ;;if it's a funcall
                     (function-application-expand subtree arg-environment)))
               "")))
        "****NOTLIST*****"))

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
