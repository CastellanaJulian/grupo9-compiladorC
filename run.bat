:: Script para windows
flex Lexico.l
bison -dyv Sintactico.y

gcc.exe lex.yy.c y.tab.c Pila.c Polaca.c -o lyc-compiler-3.0.0.exe

lyc-compiler-3.0.0.exe prueba.txt

@echo off
del lyc-compiler-3.0.0.exe
del lex.yy.c
del y.tab.c
del y.tab.h
del y.output

pause
