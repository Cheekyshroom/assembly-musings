# assembly-musings
A small simple compiler written in racket for x86_64, very unfinished

This allows you to write x86_64 assembly in a language composed of S-Expressions much like a lisp.

Create a program in a similar form to this.

```Assembly

#Some inlined data.
(_inline
  (.data)
  (buffer: .ascii "Hello World.\n\0")
  (.text))
  
#Program insertion point.
(_function _main_ (optional argument bindings)
  #Function call to one defined in our standard library.
  (_print_string $buffer)
  (_user_defined_function $10 $buffer)
  #Nested function calls are nice too, this one gets returned as it's the last call in a function
  (_add $20 (_sub $5 (_mul $2 $3))))

#A function that prints our message several times (infinitely :^))
(_function _user_defined_function (times message)
  (_print_string message)
  (_user_defined_function times message))
  
```

After creating a program like this, run build.sh in the directory of the standard library and redo.rkt, as so.
./build.sh input.s output.out

and happily run your very own program!
