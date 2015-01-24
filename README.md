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

####Currently this language supports a few different constructs;
#####All code is entered in a parenthetical, S-EXP based structure.
#####Inlined x86_64 assembly:
```Assembly
(_inline
  (.data)
  (heres_a_data_label: .quad 0, 100, 200, 300, 400, 500)
  (.text))
```
#####Comments
```Assembly
(_comment This is all a comment!)
(_comment This is a comment too!)
```
#####Function definitions (recursion will soon be tail call optimized):
```Assembly
(_function name_of_function (arg1 arg2 arg3 arg4)
  (_comment Functions can contain any form, even other function definitions.
    But it's best if they just contain inlined code and nested applications of other functions)
  (_sub (_add arg1 arg2) (_mul arg3 arg4))) (_comment the last line's return value in a function is it's return value!)
```
#####Conditional branches:
```Assembly
(_comment The whoops message)
(_inline
  (.data)
  (msg: .ascii "Whoops\n\0")
  (.text))

(_comment If 4 == 4 this will return 10, else print "Whoops" and return 20
(_if (_equal $4 $4)
  ((_identity $10))
  ((_print_string $msg)
   (_identity $20)))
```
#####Nested function application
```Assembly
(_some_function (another_function some_argument some_other_argument))
```
#####Variable mutation and reference passing
```Assembly
(_comment Sets a pointer it's given to 30)
(_function mutate_var (var_ptr)
  (_set var_ptr $30))

(_comment Will always return 30)
(_function use_var (local_variable)
  (mutate_var (_ref local_variable))
  (_identity local_variable))
```
#####A quick tutorial!:
```Assembly

(_comment Currently data labels must be inlined.)
(_inline (.data) (string: .ascii "They're equal!\n\0") (.text))

(_comment The program insertion point is at _main_)
(_function _main_ ()
  (_do_some_thing $1 $20 $21 $string))

(_comment Function definitions are pretty self explanatory)
(_function _do_some_thing (amount amount2 amount3 output_string)
  (_if (_equal (_add amount amount2) amount3) (_comment If amount+amount2 == amount3, print the string we got, else return 1
    ((_print_string output_string))
    ((_identity $1)))))
```
