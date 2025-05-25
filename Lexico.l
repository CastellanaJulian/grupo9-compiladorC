%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "y.tab.h"

#define LIMITE_SUPERIOR_ENTERO 65535
#define LIMITE_INFERIOR_ENTERO -65535
#define LIMITE_SUPERIOR_FLOTANTE 3.40282e+38
#define LIMITE_INFERIOR_FLOTANTE -1.17549e-38
#define LIMITE_CADENA 32

#define SALIDA_EXITOSA 0
#define ERROR_ARCHIVO 1
#define REGISTROS_MAXIMO 1000
#define NOMBRE_ARCHIVO_TABLA_DE_SIMBOLOS "symbol-table.txt"

#define TIPO_FLOAT  "CTE_FLOAT"
#define TIPO_INT    "CTE_INT"
#define TIPO_STR "CTE_STR"

typedef struct {
    char lexema[50];
    char tipo[50];
    char valor[50];
    int longitud;
} t_symbol_table;

t_symbol_table tablaDeSimbolos[REGISTROS_MAXIMO];
int registroTabla = 0;
FILE  *yyin;
char *yyltext;
int contVar = 0;
int comentarioAnidado = 0;

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

%x COMMENT

/* Conjuntos */
NUMERO                  [0-9]
LETRA                   [a-zA-Z]

/* Regex */
CTE_FLOAT               ({NUMERO})+"."({NUMERO})*|({NUMERO})*"."({NUMERO})+
CTE_INT                 -?{NUMERO}+
CTE_STR                 {QUOTE}.[^"]+.{QUOTE}
ID                      {LETRA}({LETRA}|{NUMERO})*

/* Caracteres */
PA                      "("
PC                      ")"
CA                      "["
CC                      "]"
LLA                     "{"
LLC                     "}"
COMA                    ","
OP_DP                   ":"
OP_ENDLINE              ";"
QUOTE   	            "\""

/* Operadores */
OP_AS                   ":="|"="
OP_SUM                  "+"
OP_MUL                  "*"
OP_RES                  "-"
OP_DIV                  "/"
OP_LOW                  "<"
OP_GREAT                ">"
OP_EQUAL                "=="
OP_LE                   "<="
OP_GE                   ">="
OP_NE                   "!="
AND                     "AND"|"and"
OR                      "OR"|"or"
NOT                     "NOT"|"not"
BOOL		            "TRUE"|"FALSE"

/* Palabras Reservadas */
INIT                    "init"|"INIT"
INTEGER                 "INTEGER"|"integer"|"Int"|"int"
FLOAT                   "FLOAT"|"float"|"Float"
STRING                  "STRING"|"string"|"String"
READ                    "READ"|"read"
WRITE                   "WRITE"|"write"
IF                      "IF"|"if"
ELSE                    "ELSE"|"else"
WHILE                   "WHILE"|"while"
SAC 	                "sliceAndConcat"
SFP                     "sumFirstPrimes"

/* Comentarios */
COMMENT_OP              "#+"
COMMENT_CL              "+#"

%%

{OP_SUM}                { return OP_SUM; }
{OP_AS}                 { return OP_AS; }
{OP_MUL}                { return OP_MUL; }
{OP_RES}                { return OP_RES; }
{OP_DIV}                { return OP_DIV; }
{PA}                    { return PA; }
{PC}                    { return PC; }
{CA}                    { return CA; }
{CC}                    { return CC; }
{LLA}                   { return LLA; }
{LLC}                   { return LLC; }

{COMMENT_OP}            { comentarioAnidado++; BEGIN(COMMENT); }
<COMMENT>{COMMENT_OP}   { comentarioAnidado++; }
<COMMENT>{COMMENT_CL}   { if (--comentarioAnidado == 0) BEGIN(INITIAL); }
<COMMENT>\n             {    }
<COMMENT>.              {    }

{OP_ENDLINE}            { return OP_ENDLINE; }

{INTEGER}               { agregarATablaDeSimbolos(yytext,0,1); return INTEGER; }
{FLOAT}                 { agregarATablaDeSimbolos(yytext,0,1); return FLOAT; }
{STRING}                { agregarATablaDeSimbolos(yytext,0,1); return STRING; }
{BOOL}                  { return BOOL; }

{CTE_INT}               { validarEntero(yytext); yylval.vals=strdup(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_INT; }
{CTE_FLOAT}             { validarFlotante(yytext); yylval.vals=strdup(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_FLOAT; }
{CTE_STR}               { validarCadena(yytext); yylval.vals=strdup(yytext); agregarATablaDeSimbolos(yytext,1,0); return CTE_STR; }

{WRITE}                 { return WRITE; }
{READ}                  { return READ; }
{IF}                    { return IF; }
{ELSE}                  { return ELSE; }
{WHILE}                 { return WHILE; }
{AND}                   { return AND; }
{OR}                    { return OR; }
{NOT}                   { return NOT; }
{INIT}                  { return INIT; }
{COMA}                  { return COMA; }
{SAC}                   { return SAC; }
{SFP}                   { return SFP; }

{OP_LOW}                { yylval.vals=strdup(yytext); return OP_LOW; }
{OP_GREAT}              { yylval.vals=strdup(yytext); return OP_GREAT; }
{OP_EQUAL}              { yylval.vals=strdup(yytext); return OP_EQUAL; }
{OP_LE}                 { yylval.vals=strdup(yytext); return OP_LE; }
{OP_GE}                 { yylval.vals=strdup(yytext); return OP_GE; }
{OP_NE}                 { yylval.vals=strdup(yytext); return OP_NE; }
{QUOTE}                 { return QUOTE; }
{OP_DP}                 { return OP_DP; }

{ID}                    { yylval.vals=strdup(yytext); agregarATablaDeSimbolos(yytext,0,0); return ID; }

"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.                   { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}

%%

int validarEntero(char* posibleLexema)
{
    int aux = atoi(posibleLexema);
    if(aux >= LIMITE_INFERIOR_ENTERO && aux <= LIMITE_SUPERIOR_ENTERO)
    {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Entero fuera de rango -> \%s\n", posibleLexema);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

int validarFlotante(char* posibleLexema)
{
    int aux = atof(posibleLexema);
    if(aux >= LIMITE_INFERIOR_FLOTANTE && aux <= LIMITE_SUPERIOR_FLOTANTE)
    {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Flotante fuera de rango -> \%s\n", posibleLexema);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

int validarCadena(char* posibleLexema)
{
    if(strlen(posibleLexema) <= LIMITE_CADENA)
    {
        return 1;            
    }
    fprintf(stderr, "Error lexico. Cadena fuera de rango -> \%s\n", posibleLexema);
    fprintf(stderr, "Abort.\n");
    exit(0);
    return 0;
};

void agregarATablaDeSimbolos(char* lexema, int esConstante, int esTipo)
{
    int i = 0, duplicado = 0;
	char nombreClave[50];
    if (esConstante)
    {
        strcpy(nombreClave, "_");
        strcat(nombreClave, lexema);
    }
    else
    {
        strcpy(nombreClave, lexema);
    }
    while (i < registroTabla && i < REGISTROS_MAXIMO && !duplicado && !esTipo)
    {
        if (!strcmp(tablaDeSimbolos[i].lexema, nombreClave))
        {
            duplicado = 1;
        }
        i++;
    }
    if (!duplicado && !esTipo)
    {
        
		strcpy(tablaDeSimbolos[registroTabla].lexema, nombreClave);
        if (esConstante)
        {
            strcpy(tablaDeSimbolos[registroTabla].valor, lexema);
            
            if (lexema[0] == '"' && lexema[strlen(lexema)-1] == '"') {
                strcpy(tablaDeSimbolos[registroTabla].tipo, TIPO_STR);
                tablaDeSimbolos[registroTabla].longitud = strlen(lexema);
            }
            else if (strchr(lexema, '.') != NULL)
                strcpy(tablaDeSimbolos[registroTabla].tipo, TIPO_FLOAT);
            else
                strcpy(tablaDeSimbolos[registroTabla].tipo, TIPO_INT);
        }
        else
        {
            contVar++;
        }
        registroTabla++;
    }
	if (esTipo)
	{
		while (contVar > 0)
		{
			strcpy(tablaDeSimbolos[registroTabla - contVar].tipo, lexema);
			contVar--;
		}
	}
};

/*int main(int argc, char *argv[])
{
    if ((yyin = fopen(argv[1], "rt")) == NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    }
    else
    { 
    	yyparse();
    }
    crearTablaDeSimbolos();
	fclose(yyin);
    return SALIDA_EXITOSA;
}*/

void mostrarTablaDeSimbolos()
{
    int i;
    printf("\n---Tabla de Simbolos---\n");
    printf("\n%8s\t%8s\t%8s\t%8s\n","Nombre", "Valor", "Tipo", "Longitud");
    for(i = 0; i < registroTabla; i++)
    {
        printf("\n%8s\t%8s\t%8s\t%8d\n", tablaDeSimbolos[i].lexema, tablaDeSimbolos[i].valor, tablaDeSimbolos[i].tipo, tablaDeSimbolos[i].longitud);
    }
}

int crearTablaDeSimbolos()
{
    int i;
	FILE *pf; 
	pf = fopen(NOMBRE_ARCHIVO_TABLA_DE_SIMBOLOS, "w+"); 
	if (!pf)
    {
        return ERROR_ARCHIVO;
    }
    fprintf(pf, "%8s\t|\t%8s\t|\t%8s\t|\t%8s\n", "Nombre", "Valor", "Tipo", "Longitud");
    for(i = 0; i < registroTabla; i++)
    {
        fprintf(pf, "%8s\t|\t%8s\t|\t%8s\t|\t%8d\n", tablaDeSimbolos[i].lexema, tablaDeSimbolos[i].valor, tablaDeSimbolos[i].tipo, tablaDeSimbolos[i].longitud);
    }
    fclose(pf);
    return SALIDA_EXITOSA;
}

int buscarEnTablaDeSimbolos (char* nombre)
{
	int i;
	for(i = 0; i < REGISTROS_MAXIMO; i++)
    {
        if(strcmp(tablaDeSimbolos[i].lexema, nombre) == 0)
		{
			return i;
		}
        if(strcmp(tablaDeSimbolos[i].valor, nombre) == 0)
        {
            return i;
        }
	}
	return -1;
}
