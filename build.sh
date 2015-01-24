#!/bin/env bash
racket -t ./redo.rkt $1 $2
as $2 -o temp1234.o
as stdlib.s -o temp4321.o
ld temp1234.o temp4321.o -o $2
rm temp1234.o temp4321.o
