%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"

/* defines */
/* REFACTORIZAR CON EL LEXICO*/
#define MAX_REGS 1000
#define CADENA_MAXIMA 32
#define TRUE 1
#define FALSE 0
#define ERROR -1
#define OK 3

/* enums */
enum tipoSalto{
	normal,
	inverso
};

enum and_or{
	and,
	or,
	condicionSimple
};

enum tipoDato{
	tipoInt,
	tipoFloat,
	tipoString,
	sinTipo
};

typedef struct
{
	int cantExpresiones;
	int salto1;
	int salto2;
	int saltoElse;
	int nro;
	enum and_or andOr;
	enum tipoDato tipo;
}t_info;

enum tipoCondicion{
	condicionIf,
	condicionWhile
};

/* structs */

typedef struct {
    char lexema[50];
    char tipo[50];
    char valor[50];
    int longitud;
} t_symbol_table;

typedef struct
{
	char cadena[CADENA_MAXIMA];
	int nro;
}t_infoPolaca;

typedef struct s_nodoPolaca{
	t_infoPolaca info;
	struct s_nodoPolaca* psig;
}t_nodoPolaca;

typedef t_nodoPolaca *t_polaca;

typedef struct s_nodoPila{
    	t_info info;
    	struct s_nodoPila* psig;
	}t_nodoPila;

typedef t_nodoPila *t_pila;
t_pila pilaIf;

t_pila pilaWhile;

/* DECLARACIONES IMPLICITAS */
extern int yyerrormsg(const char *);
extern int buscarEnTablaDeSimbolos(char*);
extern int crearTablaDeSimbolos();

/* funciones */
void guardarPolaca(t_polaca*);
int ponerEnPolacaNro(t_polaca*,int, char *);
int ponerEnPolaca(t_polaca*, char *);
void crearPolaca(t_polaca*);
char* obtenerSalto(enum tipoSalto);

void vaciarPila(t_pila*);
t_info* sacarDePila(t_pila*);
void crearPila(t_pila*);
int ponerEnPila(t_pila*,t_info*);
t_info* topeDePila(t_pila*);

t_info* topeDePila(t_pila*);
t_info* sacarDePila(t_pila*);
int contadorIf=0;
int contadorWhile=0;
enum tipoCondicion tipoCondicion;

/* variables globales */

extern t_symbol_table tablaDeSimbolos[MAX_REGS];

t_polaca polaca;
int contadorPolaca=0;
char ultimoComparador[3];
enum and_or ultimoOperadorLogico;

int indicesParaAsignarTipo[MAX_REGS];
int contadorListaVar=0;
int esAsignacion;
char tipoAsignacion[50];

int avgNumero=0;
int avg[MAX_REGS];
int contadorAvg[MAX_REGS];

extern char*yytext;
extern int yylineno;

int yystopparser = 0;
FILE  *yyin;

int yyerror();
int yylex();

%}

%union {
	int vali;
	double valf;
	char*vals;
}

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
	ID{int posicion=buscarEnTablaDeSimbolos($<vals>1); indicesParaAsignarTipo[contadorListaVar++]=posicion;}
	| lista_variables COMA ID{int posicion=buscarEnTablaDeSimbolos($<vals>3); indicesParaAsignarTipo[contadorListaVar++]=posicion;}
	;
	

bloque_declaraciones:
	lista_variables OP_DP tipo{contadorListaVar=0;}
	| bloque_declaraciones lista_variables OP_DP tipo{contadorListaVar=0;}
	;

tipo:
	INTEGER
	| FLOAT
	| STRING
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
	ID
	{
		// Comparar haciendo enums
		if(strcmp(tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo, "") == 0)
		{
			yyerrormsg("Variable sin declarar");
		}
		esAsignacion=1;
		strcpy(tipoAsignacion,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo);
		ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].lexema);
	}
		OP_AS expresion  {
		esAsignacion=0;
		strcpy(tipoAsignacion,"VARIABLE");
		ponerEnPolaca(&polaca,"=");
	} OP_ENDLINE {printf("    ID = Expresion es ASIGNACION\n");}
	;

expresion:
	termino {printf("Termino es Expresion\n");}
	| expresion OP_SUM{
			if(esAsignacion==1&&strcmp(tipoAsignacion,"STRING")==0)
			{
				yyerrormsg("Operacion invalida en suma(Intenta asignar un numero a un string)");
			}
		}termino{ponerEnPolaca(&polaca,"+");} {printf("Expresion+Termino es Expresion\n");}
	| expresion OP_RES{
			if(esAsignacion==1&&strcmp(tipoAsignacion,"STRING")==0)
			{
				yyerrormsg("Operacion invalida en resta(Intenta asignar un numero a un string)");
			}
		} termino{ponerEnPolaca(&polaca,"-");} {printf("Expresion-Termino es Expresion\n");}
	| CTE_STR{
			if(esAsignacion==1&&strcmp(tipoAsignacion,"STRING")!=0)
			{
				yyerrormsg("Operacion invalida, Intenta asignar un string a un numero");
			}
		} {printf("CTE_STR es Expresion\n");}
	/* AGREGAR COLOCAR EN POLACA*/
	| slice_and_concat {printf("    sliceAndConcat es Expresion\n");}
	;

termino: 
   factor {printf("Factor es Termino\n");}
   | termino OP_MUL{
			if(esAsignacion==1&&strcmp(tipoAsignacion,"STRING")==0)
			{
				yyerrormsg("Operacion invalida en multiplicacion(multiplica un numero a un string)");
			}
		} factor{ponerEnPolaca(&polaca,"*");} {printf(" Termino*Factor es Termino\n");}
   | termino OP_DIV{
			if(esAsignacion==1&&strcmp(tipoAsignacion,"STRING")==0)
			{
				yyerrormsg("Operacion invalida en division(Divide un numero a un string)");
			}
		} factor{ponerEnPolaca(&polaca,"/");} {printf(" Termino/Factor es Termino\n");}
   ;

/* VER DE CAMBIARLO CON EL SINTACTICO DEL OTRO TP*/
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

int yyerrormsg(const char * msg)
{
	printf("[Linea %d] ",yylineno);
	printf("Error Sintactico: %s\n",msg);
  	system ("Pause");
    exit (1);
}

/* primitivas de polaca */


void crearPolaca(t_polaca* pp)
{
    *pp=NULL;
}

int ponerEnPolaca(t_polaca* pp, char *cadena)
{
	printf("ponerEnPolaca: cadena %s\n",cadena);
    t_nodoPolaca* pn = (t_nodoPolaca*)malloc(sizeof(t_nodoPolaca));
    if(!pn)
    {
    	printf("ponerEnPolaca: Error al solicitar memoria\n");
        return ERROR;
    }
    t_nodoPolaca* aux;
    strcpy(pn->info.cadena,cadena);
    pn->info.nro=contadorPolaca++;
    pn->psig=NULL;
    if(!*pp)
    {
    	*pp=pn;
    	return OK;
    }
    else
    {
    	aux=*pp;
    	while(aux->psig)
        	aux=aux->psig;
        aux->psig=pn;
    	return OK;
    }
}

int ponerEnPolacaNro(t_polaca* pp,int pos, char *cadena)
{
	t_nodoPolaca* aux;
	aux=*pp;
    while(aux!=NULL && aux->info.nro<pos)
    {
    	aux=aux->psig;
    }
    if(aux->info.nro==pos)
    {
    	strcpy(aux->info.cadena,cadena);
    	return OK;
    }
    else
    {
    	printf("NO ENCONTRADO\n");
    	return ERROR;
    }
    return ERROR;
}

void guardarPolaca(t_polaca *pp)
{
	FILE*pt=fopen("intermedia.txt","w+");
	t_nodoPolaca* pn;
	if(!pt)
	{
		printf("Error al crear el archivo intermedio.\n");
		return;
	}
	while(*pp)
    {
        pn=*pp;
        fprintf(pt, "%s\n",pn->info.cadena);
        *pp=(*pp)->psig;
        free(pn);
    }
	
	fclose(pt);
}

char* obtenerSalto(enum tipoSalto tipo)
{
	switch(tipo)
	{
		case normal:
			if(strcmp(ultimoComparador,"==")==0)
				return("BEQ");
			if(strcmp(ultimoComparador,">")==0)
				return("BGT");
			if(strcmp(ultimoComparador,"<")==0)
				return("BLT");
			if(strcmp(ultimoComparador,">=")==0)
				return("BGE");
			if(strcmp(ultimoComparador,"<=")==0)
				return("BLE");
			if(strcmp(ultimoComparador,"!=")==0)
				return("BNE");
			break;

		case inverso:
			if(strcmp(ultimoComparador,"==")==0)
				return("BNE");
			if(strcmp(ultimoComparador,">")==0)
				return("BLE");
			if(strcmp(ultimoComparador,"<")==0)
				return("BGE");
			if(strcmp(ultimoComparador,">=")==0)
				return("BLT");
			if(strcmp(ultimoComparador,"<=")==0)
				return("BGT");
			if(strcmp(ultimoComparador,"!=")==0)
				return("BEQ");
			break;
	}
}

// Métodos pila
/* primitivas de pila */

void crearPila(t_pila* pp)
{
    *pp=NULL;
}

int ponerEnPila(t_pila* pp,t_info* info)
{
    t_nodoPila* pn=(t_nodoPila*)malloc(sizeof(t_nodoPila));
    if(!pn)
        return 0;
    pn->info=*info;
    pn->psig=*pp;
    *pp=pn;
    return 1;
}

t_info * sacarDePila(t_pila* pp)
{
	t_info* info = (t_info *) malloc(sizeof(t_info));
    if(!*pp){
    	return NULL;
    }
    *info=(*pp)->info;
    *pp=(*pp)->psig;
    return info;

}

void vaciarPila(t_pila* pp)
{
    t_nodoPila* pn;
    while(*pp)
    {
        pn=*pp;
        *pp=(*pp)->psig;
        free(pn);
    }
}

t_info* topeDePila(t_pila* pila)
{
	return &((*pila)->info);
}

int main(int argc, char *argv[])
{
	crearPila(&pilaIf);
	crearPolaca(&polaca);
    if ((yyin = fopen(argv[1], "rt")) == NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    } else { 
    	yyparse();
    }
	
    // showSymbolTable(); Función para realizar el debug de la tabla de simbolos.
    crearTablaDeSimbolos();
	fclose(yyin);
	guardarPolaca(&polaca);
  return 0;
}

