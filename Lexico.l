%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "y.tab.h"
#define MAX_REGS 1000
#define NOMBRE_ARCHIVO_TABLA_DE_SIMBOLOS "symbol-table.txt"

typedef struct {
    char lexema[50];
    char tipo[50];
    char valor[50];
    int longitud;
} t_symbol_table;

t_symbol_table tablaDeSimbolos[MAX_REGS];
int table_regs = 0;
FILE  *yyin;
int yylval;
char *yyltext;
int contVar = 0;

int yyparse();
int validarEntero(char* str);
int validarFlotante(char* str);
int validarCadena(char* str);
void agregarATablaDeSimbolos(char* str, int esConstante, int esTipo);
void mostrarTablaDeSimbolos();
int crearTablaDeSimbolos();

%}

%option noyywrap  
%option yylineno 

SPACE           [" "]
NUMBER          [0-9]
LETTER          [a-zA-Z]
ID              {LETTER}({LETTER}|{NUMBER})*
CTE_INT         {NUMBER}+
CTE_FLOAT       ({NUMBER})+"."({NUMBER})*|({NUMBER})*"."({NUMBER})+
CTE_STR         {QUOTE}.[^"]+.{QUOTE}
COMMENT_OP      "#+"
COMMENT_IN      [^"]
COMMENT_CL      "+#"
COMMENT         {COMMENT_OP}+{COMMENT_IN}*{COMMENT_CL}+
INTEGER         "INTEGER"|"integer"|"Int"|"int"
FLOAT           "FLOAT"|"float"|"Float"
STRING          "STRING"|"string"|"String"
COMA            ","
OP_AS           ":="|"="
OP_SUM          "+"
OP_MUL          "*"
OP_RES          "-"
OP_DIV          "/"
OP_DP           ":"
PA              "("
PC              ")"
CA              "["
CC              "]"
LLA             "{"
LLC             "}"
OP_LOW          "<"
OP_GREAT        ">"
OP_EQUAL        "=="
OP_LE           "<="
OP_GE           ">="
OP_ENDLINE      ";"
QUOTE   	    "\""
BOOL		    "TRUE"|"FALSE"

WRITE           "WRITE"|"write"
READ            "READ"|"read"
IF              "IF"|"if"
WHILE           "WHILE"|"while"
ELSE            "ELSE"|"else"
AND             "AND"|"and"
OR              "OR"|"or"
NOT             "NOT"|"not"
INIT            "init"|"INIT"
SAC 	        "sliceAndConcat"
SFP             "sumFirstPrimes"

%%

{OP_SUM}       { return OP_SUM; }
{OP_AS}        { return OP_AS; }
{OP_MUL}       { return OP_MUL; }
{OP_RES}       { return OP_RES; }
{OP_DIV}       { return OP_DIV; }
{PA}           { return PA; }
{PC}           { return PC; }
{CA}           { return CA; }
{CC}           { return CC; }
{LLA}          { return LLA; }
{LLC}          { return LLC; }

{COMMENT}       {   }

{OP_ENDLINE}   { return OP_ENDLINE; }

{INTEGER}      { agregarATablaDeSimbolos(yytext,0,1); return INTEGER; }
{FLOAT}        { agregarATablaDeSimbolos(yytext,0,1); return FLOAT; }
{STRING}       { agregarATablaDeSimbolos(yytext,0,1); return STRING; }
{BOOL}         { return BOOL; }

{CTE_INT}      { validarEntero(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_INT; }
{CTE_FLOAT}    { validarFlotante(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_FLOAT; }
{CTE_STR}      { validarCadena(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_STR; }

{WRITE}        { return WRITE; }
{READ}         { return READ; }
{IF}           { return IF; }
{ELSE}         { return ELSE; }
{WHILE}        { return WHILE; }
{AND}          { return AND; }
{OR}           { return OR; }
{NOT}          { return NOT; }
{INIT}         { return INIT; }
{COMA}         { return COMA; }
{SAC}          { return SAC; }
{SFP}          { return SFP; }

{OP_LOW}       { return OP_LOW; }
{OP_GREAT}     { return OP_GREAT; }
{OP_EQUAL}     { return OP_EQUAL; }
{OP_LE}        { return OP_LE; }
{OP_GE}        { return OP_GE; }
{QUOTE}        { return QUOTE; }
{OP_DP}        { return OP_DP; }

{ID}           { agregarATablaDeSimbolos(yytext,0,0); return ID; }

"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.               { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}

%%

int validarEntero(char* str)
{
    int aux = atoi(str);
    if(aux>=-65535 && aux<=65535) {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Entero fuera de rango -> \%s\n", str);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

int validarFlotante(char* str)
{
    int aux = atof(str);
    if(aux >= -1.17549e-38 && aux <= 3.40282e+38) {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Flotante fuera de rango -> \%s\n", str);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

int validarCadena(char* str)
{
    if(strlen(str) <= 32) {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Cadena fuera de rango -> \%s\n", str);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

void agregarATablaDeSimbolos(char* lexema, int esConstante, int esTipo){
    int i = 0, duplicado = 0;
	char memoria[50];
    while(i < table_regs && i < MAX_REGS && !duplicado && !esTipo)
    {
        if(!strcmp(tablaDeSimbolos[i].lexema, lexema)){
            duplicado = 1;
        }
        i++;
    }
    if(!duplicado && !esTipo)
    {
        tablaDeSimbolos[table_regs].longitud = strlen(lexema);
		strcpy(tablaDeSimbolos[table_regs].lexema, lexema);
        if(esConstante){
			strcpy(memoria, "_");
			strcat(memoria, lexema);
		    strcpy(tablaDeSimbolos[table_regs].lexema, memoria);
            strcpy(tablaDeSimbolos[table_regs].valor, lexema);
        }
        table_regs++;
		contVar++;
    }
	if(esTipo)
	{
		while(contVar!=0)
		{
			strcpy(tablaDeSimbolos[table_regs-contVar].tipo, lexema);
			contVar--;
		}
	}
};

int main(int argc, char *argv[])
{
    if ((yyin = fopen(argv[1], "rt")) == NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    } else { 
    	yyparse();
    }
    crearTablaDeSimbolos();
	fclose(yyin);
    return 0;
}

void mostrarTablaDeSimbolos(){
    int i;
    printf("\n---Tabla de Simbolos---\n");
    printf("\n%8s\t%8s\t%8s\t%8s\n","Nombre","Valor","Tipo","Longitud");
    for(i=0; i<table_regs; i++){
        printf("\n%8s\t%8s\t%8s\t%8d\n",tablaDeSimbolos[i].lexema,tablaDeSimbolos[i].valor,tablaDeSimbolos[i].tipo,tablaDeSimbolos[i].longitud);
    }
}

int crearTablaDeSimbolos(){
    int i;
	FILE *pf; 
	pf = fopen(NOMBRE_ARCHIVO_TABLA_DE_SIMBOLOS,"w+"); 
	char* tipo;
	if (!pf) {
        return 1;
    }
    fprintf(pf, "\n%8s\t|\t%8s\t|\t%8s\t|\t%8s\n","Nombre","Valor","Tipo","Longitud");
    for(i = 0; i < table_regs; i++) {
        fprintf(pf, "\n%8s\t|\t%8s\t|\t%8s\t|\t%8d\n",tablaDeSimbolos[i].lexema,tablaDeSimbolos[i].valor,tablaDeSimbolos[i].tipo,tablaDeSimbolos[i].longitud);
    }
    fclose(pf);
    return 0;
}
