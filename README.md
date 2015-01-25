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
####Functions provided in the standard library:
#####Arithmetic operators
Addition, subtraction, division, multiplication, and modulus implemented with the `_add`, `_sub`, `_div`, `_mul`, `_mod` functions respectively
```Assembly
(_add $2 3)
(_mul $100 $3)
```
#####String operations:
######Strings can be compared with `_string_compare`:
```Assembly
(_inline (.data) (string1: .ascii "Hello\0") (string2: .ascii "Foobar!\0"))
(_string_compare $string1 $string2) (_comment Will obviously return false)
```
######Read from stdin with `_read_string` or `_read_terminate_string`:
```Assembly
(_inline (.bss) (.lcomm input_buffer, 512) (.text)) (_comment A 512 byte input buffer)
(_read_terminate_string $input_buffer $512)
```
######Printed to stdout with `_print_string` or `_write_string`, or as bytes individually with `_print_byte`:
```Assembly
(_inline (.data) (string: .ascii "Hello\n\0") (.text))
(_print_string $string)
```
######You can find their length with `_string_length`:
```Assembly
(_inline (.data) (string: .ascii "Hello\n\0") (.text))
(_string_length $string)
```
#####Other notable functions include:
######`_identity`, which returns its argument:
```Assembly
(_identity $10)
(_identity $300)
```
######`_equal`,which returns true (0) on equality of arguments and another number on inequality:
```Assembly
(_equal $1 $1)
(_equal $-1 $500)
```
######`_exit_`, which kills the program at any specified point:
```Assembly
(_exit_)
```
######And `_set`, which sets the memory location at its first argument to its second:
```Assembly
(_function foo (variable)
	(_set (_ref variable) (_add variable $20)))
```

###That's pretty much it so far, look forward to TCO, loops, and various other fun things soon enough!
