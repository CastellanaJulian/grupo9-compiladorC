## Script para Unix
flex Lexico.l
bison -dyv Sintactico.y
gcc lex.yy.c y.tab.c Pila.c Polaca.c -o compilador
./compilador prueba.txt
rm lex.yy.c
rm y.tab.c
rm y.output
rm y.tab.h
rm compilador