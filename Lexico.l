%{
#include <stdio.h>
#include <stdlib.h>

#include "y.tab.h"
FILE  *yyin;
int yylval;
char *yyltext;


int yyerror(void);

%}

%option noyywrap  
%option yylineno 

/* EXPRESIONES BASE */
Letra = [a-zA-Z]
Digito = [0-9]
Espacio = [ \t\r\n]+
Caracter = [=|>|<|!|:|+|-|*|/|?|¿|!|¡|@|%|#|&|°|´|^|`|~|/|\\|-|_|.|,|;|¬||]
ID = {Letra}({Letra}{Digito})*
AbrirComentario = "#+"
CerrarComentario = "+#"
ContenidoComentario = "([^+]|(\+[^#]))*"
Comentario  = {AbrirComentario}+{ContenidoComentario}{CerrarComentario}+ /* Falta completar el contenido */

/* PALABRAS RESERVADAS */

While = "while"
If = "if"
Else = "else"
Init = "init"
Read = "read"
Write = "write"
Float = "float"
String = "string"
Int = "int"

/* OPERADORES ARITMETICOS */

Mas = "+"
GuionMedio = "-"
Multiplicar = "*"
Dividir = "/"

/* OPERADORES COMPARACION */

Igual = "=="
Distinto = "!="
Menor = "<"
MenorIgual = "<="
Mayor = ">"
MayorIgual = ">="

/* CONDICIONES */

And = "AND"
Or = "OR"
Not "NOT"

/* ASIGNACION */

Asignacion = ":="

/* SIMBOLOS Y SEPARADORES */

AbrirParentesis = "("
CerrarParentesis = ")"
AbrirLlave = "{"
CerrarLlave = "}"
DosPuntos = ":"
Coma = ","
PuntoYComa = ";"


%%

{CTE}			{printf("\nConstante: %s\n", yytext);return CTE;}
{ID}			{printf("\nIdentificador: %s\n", yytext);return ID;}
{OP_SUM}		{printf("\nSuma: %s\n", yytext);return OP_SUM;}
{OP_AS}			{printf("\nAsignacion: %s\n", yytext);return OP_AS;}
{OP_MUL}		{printf("\nMultiplicacion: %s\n", yytext);return OP_MUL;}
{OP_RES}		{printf("\nResta: %s\n", yytext);return OP_RES;}
{OP_DIV}		{printf("\nDivision: %s\n", yytext);return OP_DIV;}
{PA}			{printf("\nParAbre: %s\n", yytext);return PA;}
{PC}			{printf("\nParCierra: %s\n", yytext);return PC;}
"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.			 { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}


