%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

char *yyltext;


int yyerror(void);

%}

%option noyywrap  
%option yylineno 

While           "while | WHILE"
If              "if | IF"
Else            "else | ELSE"
Init            "init | INIT"
Read            "read | READ"
Write           "write | WRITE"
Float           "float | FLOAT"
String          "string | STRING"
Int             "int | INIT"
And             "AND | and"
Or              "OR | or"
Not             "NOT | not"


Letra           [a-zA-Z]
Digito          [0-9]
Caracter        [=><!:+\-*/?¿!¡@%#&°´^`~\\\|_\.,;¬]
ID              {Letra}({Letra}|{Digito})*
Cadena          \"[^\"]*\"
Entero          {Digito}+
Flotante        {Digito}+"."{Digito}+

Mas             "+"
GuionMedio      "-"
Multiplicar     "*"
Dividir         "/"


Igual           "=="
Distinto        "!="
Menor           "<"
MenorIgual      "<="
Mayor           ">"
MayorIgual      ">="

Asignacion      ":="

AbrirParentesis "("
CerrarParentesis ")"
AbrirLlave      "{"
CerrarLlave     "}"
DosPuntos       ":"
Coma            ","
PuntoYComa      ";"



%%

{Entero}            {printf("Constante entera: %s\n", yytext); return CTE_INT;}
{Flotante}          {printf("Constante float: %s\n", yytext); return CTE_FLOAT;}
{Cadena}            {printf("Constante string: %s\n", yytext); return CTE_STR;}
{ID}                {printf("Identificador: %s\n", yytext); return ID;}
{Mas}               {printf("Suma: %s\n", yytext); return OP_SUM;}
{GuionMedio}        {printf("Resta: %s\n", yytext); return OP_RES;}
{Multiplicar}       {printf("Multiplicacion: %s\n", yytext); return OP_MUL;}
{Dividir}           {printf("Division: %s\n", yytext); return OP_DIV;}
{Igual}             {printf("Igual: %s\n", yytext); return COMP_IGUAL;}
{Distinto}          {printf("Distinto: %s\n", yytext); return COMP_DISTINTO;}
{Menor}             {printf("Menor: %s\n", yytext); return COMP_MENOR;}
{MenorIgual}        {printf("Menor o igual: %s\n", yytext); return COMP_MENOR_IGUAL;}
{Mayor}             {printf("Mayor: %s\n", yytext); return COMP_MAYOR;}
{MayorIgual}        {printf("Mayor o igual: %s\n", yytext); return COMP_MAYOR_IGUAL;}
{And}               {printf("AND: %s\n", yytext); return LOG_AND;}
{Or}                {printf("OR: %s\n", yytext); return LOG_OR;}
{Not}               {printf("NOT: %s\n", yytext); return LOG_NOT;}
{Asignacion}        {printf("Asignacion: %s\n", yytext); return OP_AS;}
{AbrirParentesis}   {printf("Parentesis abre: %s\n", yytext); return PA;}
{CerrarParentesis}  {printf("Parentesis cierra: %s\n", yytext); return PC;}
{AbrirLlave}        {printf("Llave abre: %s\n", yytext); return LA;}
{CerrarLlave}       {printf("Llave cierra: %s\n", yytext); return LC;}
{DosPuntos}         {printf("Dos puntos: %s\n", yytext); return DOS_PUNTOS;}
{Coma}              {printf("Coma: %s\n", yytext); return COMA;}
{PuntoYComa}        {printf("Punto y coma: %s\n", yytext); return PUNTO_Y_COMA;}
{While}             {printf("Palabra reservada WHILE: %s\n", yytext); return WHILE;}
{If}                {printf("Palabra reservada IF: %s\n", yytext); return IF;}
{Else}              {printf("Palabra reservada ELSE: %s\n", yytext); return ELSE;}
{Init}              {printf("Palabra reservada INIT: %s\n", yytext); return INIT;}
{Read}              {printf("Palabra reservada READ: %s\n", yytext); return READ;}
{Write}             {printf("Palabra reservada WRITE: %s\n", yytext); return WRITE;}
{Float}             {printf("Palabra reservada FLOAT: %s\n", yytext); return TIPO_FLOAT;}
{String}            {printf("Palabra reservada STRING: %s\n", yytext); return TIPO_STRING;}
{Int}               {printf("Palabra reservada INT: %s\n", yytext); return TIPO_INT;}

"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.			    { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}
%%