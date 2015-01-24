# assembly-musings
A small simple compiler written in racket for x86_64, very unfinished

This allows you to write x86_64 assembly in a language composed of S-Expressions much like a lisp.

Create a program in a similar form to this.

```Assembly

(_comment Some inlined data.)
(_inline
  (.data)
  (welcome: .ascii "Welcome!\n\0")
  (buffer: .ascii "Hello World.\n\0")
  (.text))
  
(_comment Program insertion point.)
(_function _main_ (optional argument bindings)
  (_comment Function call to one defined in our standard library.)
  (_print_string $welcome)
  (_user_defined_function $10 $buffer)
  (_comment Nested function calls are nice too
     this one gets returned as it's the last call in a function.)
  (_add $20 (_sub $5 (_mul $2 $3))))

(_comment A function that prints a message as many times as desired)
(_function _user_defined_function (times message)
  (_print_string message)
  (_if (_equal times $0)
    ((_identity $0))
    ((_user_defined_function (_sub times $1) message))))
  
```

After creating a program like this, run build.sh in the directory of the standard library and redo.rkt, as so.
./build.sh input.s output.out

and happily run your very own program!
