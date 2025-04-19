%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

int yystopparser = 0;
FILE  *yyin;

int yyerror();
int yylex();
%}

%token ID
%token OP_AS
%token OP_SUM
%token OP_MUL
%token OP_RES
%token OP_DIV
%token PA
%token PC
%token CA
%token CC
%token LLA
%token LLC
%token READ
%token CTE_FLOAT
%token CTE_STR
%token BOOL
%token SFP
%token SAC
%token WRITE
%token IF
%token ELSE
%token WHILE
%token AND
%token OR
%token NOT
%token INIT
%token OP_LOW
%token OP_GREAT
%token OP_EQUAL
%token OP_LE
%token OP_GE
%token CHAR_BIT
%token CTE_INT
%token COMA
%token OP_ENDLINE
%token INTEGER
%token FLOAT
%token STRING
%token QUOTE
%token OP_DP

%%
programa: 
	main {printf("Compilacion exitosa\n");};

main: 
	declaraciones resto_programa {printf("resto_programa\n");}
	| declaraciones
	| resto_programa
	;

lista_variables:
	ID | lista_variables COMA ID 
	;

bloque_declaraciones:
	lista_variables OP_DP tipo
	| bloque_declaraciones lista_variables OP_DP tipo
	;

tipo:
	INTEGER | FLOAT | STRING
	;

declaraciones:
	INIT LLA bloque_declaraciones LLC	{printf("declaraciones\n");}
	;

resto_programa: 
	sentencia {printf("sentencia\n");} 
	| resto_programa sentencia {printf("resto_programa sentencia\n");};

sentencia:  	   
	asignacion {printf(" asignacion\n");} 
	| if {printf(" if\n");}
	| while {printf(" while\n");}
	| write {printf(" write\n");}
	| read {printf(" read\n");}
	;

asignacion: 
	ID OP_AS expresion OP_ENDLINE {printf("    ID = Expresion es ASIGNACION\n");}
	| ID OP_AS asignacion OP_ENDLINE {printf("    ID = Asignacion es ASIGNACION\n");}
	;

expresion:
	termino {printf("    Termino es Expresion\n");}
	| expresion OP_SUM termino {printf("    Expresion+Termino es Expresion\n");}
	| expresion OP_RES termino {printf("    Expresion-Termino es Expresion\n");}
	| CTE_STR {printf("    CTE_STR es Expresion\n");}
	| slice_and_concat {printf("    sliceAndConcat es Expresion\n");}
	;

termino: 
   factor {printf("    Factor es Termino\n");}
   | termino OP_MUL factor {printf("     Termino*Factor es Termino\n");}
   | termino OP_DIV factor {printf("     Termino/Factor es Termino\n");}
   ;
   
factor: 
	ID {printf("    ID es Factor \n");}
	| CTE_INT {printf("    CTE es Factor\n");}
	| CTE_FLOAT {printf("    CTE es Factor\n");}
	| PA expresion PC {printf("    Expresion entre parentesis es Factor\n");}
	| sum_first_primes {printf("    sumFirstPrimes es Factor\n");}
	;

elementos:
	elemento 
	| elemento COMA elementos 
	;
	
elemento:
	expresion
	;
	
sum_first_primes:
	SFP PA expresion PC {printf("     SFP(expresion) es sumFirstPrimes\n");}
	;

slice_and_concat:
	SAC PA expresion COMA expresion COMA expresion COMA expresion COMA BOOL PC {printf("     SAC(expresion,expresion,expresion,expresion,BOOL) es sliceAndConcat\n");}
	;

write:
    WRITE PA CTE_STR PC OP_ENDLINE
	| WRITE PA ID PC OP_ENDLINE
    ;

read: 
	READ PA ID PC OP_ENDLINE
	| READ PA CTE_STR PC OP_ENDLINE
	;

operador_comparacion:
	OP_LOW
	| OP_GREAT
	| OP_EQUAL
	| OP_LE
	| OP_GE
	;

operador_logico:
	AND
	| OR
	;

operador_negacion:
	NOT
	;

comparacion:
	expresion operador_comparacion expresion
	| expresion operador_comparacion expresion operador_comparacion expresion
	;

while:
	WHILE PA operador_negacion PA comparacion PC PC bloque_ejecucion
	| WHILE PA comparacion PC bloque_ejecucion
	| WHILE PA comparacion operador_logico comparacion PC bloque_ejecucion
	;

if:
	IF PA operador_negacion PA comparacion PC PC bloque_ejecucion
	| IF PA operador_negacion PA comparacion PC PC bloque_ejecucion else
	| IF PA comparacion PC bloque_ejecucion
	| IF PA comparacion PC bloque_ejecucion else
	| IF PA comparacion operador_logico comparacion PC bloque_ejecucion
	| IF PA comparacion operador_logico comparacion PC bloque_ejecucion else
	;

else:
	ELSE bloque_ejecucion
	;

bloque_ejecucion:
	LLA resto_programa LLC
	;
%%

int yyerror(void)
{
    printf("Error Sintactico\n");
	exit (1);
}
