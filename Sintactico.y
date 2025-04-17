// Usa Lexico_ClasePractica
//Solo expresiones sin ()
%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
int yystopparser=0;


  int yyerror();
  int yylex();


%}
%token LOG_AND
%token LOG_OR
%token LOG_NOT
%token CTE_INT
%token CTE_FLOAT
%token CTE_STR
%token ID

%token OP_SUM
%token OP_RES
%token OP_MUL
%token OP_DIV

%token COMP_IGUAL
%token COMP_DISTINTO
%token COMP_MENOR
%token COMP_MENOR_IGUAL
%token COMP_MAYOR
%token COMP_MAYOR_IGUAL



%token OP_AS

%token PA  /* Paréntesis abrir */
%token PC  /* Paréntesis cerrar */
%token LA  /* Llave abrir */
%token LC  /* Llave cerrar */
%token DOS_PUNTOS
%token COMA
%token PUNTO_Y_COMA

%token WHILE
%token IF
%token ELSE
%token INIT
%token READ
%token WRITE
%token TIPO_FLOAT
%token TIPO_STRING
%token TIPO_INT

%%
programa: 
	CTE_INT {printf("Compilacion ok\n");};
%%

extern FILE *yyin;

int main(int argc, char *argv[])
{
    if((yyin = fopen(argv[1], "rt"))==NULL)
    {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
       
    }
    else
    { 
        
        yyparse();
        
    }
	fclose(yyin);
        return 0;
}
int yyerror(void)
     {
       printf("Error Sintactico\n");
	 exit (1);
     }

