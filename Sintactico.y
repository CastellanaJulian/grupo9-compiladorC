%{
/******************* Librerias *******************/

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include "y.tab.h"

/******************* Defines *******************/

#define LIMITE_SUPERIOR_ENTERO 65535
#define REGISTROS_MAXIMO 1000
#define CADENA_MAXIMA 32
#define TRUE 1
#define FALSE 0
#define ERROR -1
#define OK 3
#define VACIO ""

#define CMP "CMP"
#define BEQ "BEQ"
#define BNE "BNE"
#define BGT "BGT"
#define BGE "BGE"
#define BLT "BLT"
#define BLE "BLE"

/******************* Enums *******************/

enum EnumTipoSalto
{
	normal,
	inverso
};
enum and_or { and, or, condicionSimple };
enum tipoDato { tipoInt, tipoFloat, tipoString, sinTipo };
enum tipoCondicion { condicionIf, condicionWhile };
enum EnumOperacion
{
	asignacion,
	logica,
	texto,
};

/******************* Estructuras *******************/

typedef struct
{
	int cantExpresiones;
	int salto1;
	int salto2;
	int saltoElse;
	int nro;
	enum and_or andOr;
	enum tipoDato tipo;
} t_info;

typedef struct
{
    char lexema[50];
    char tipo[50];
    char valor[50];
    int longitud;
} t_symbol_table;

typedef struct
{
	char cadena[CADENA_MAXIMA];
	int nro;
} t_infoPolaca;

typedef struct s_nodoPolaca
{
	t_infoPolaca info;
	struct s_nodoPolaca* psig;
} t_nodoPolaca;

typedef t_nodoPolaca *t_polaca;

typedef struct s_nodoPila
{
	t_info info;
	struct s_nodoPila* psig;
} t_nodoPila;

typedef t_nodoPila *t_pila;
t_pila pilaIf;
t_pila pilaWhile;

/******************* Declaraciones Implicitas *******************/

extern int yyerrormsg(const char *);
extern int buscarEnTablaDeSimbolos(char*);
extern int crearTablaDeSimbolos();
extern t_symbol_table tablaDeSimbolos[REGISTROS_MAXIMO];
extern char*yytext;
extern int yylineno;

/******************* Funciones *******************/

void guardarPolaca(t_polaca*);
int ponerEnPolacaNro(t_polaca*,int, char *);
int ponerEnPolaca(t_polaca*, char *);
void crearPolaca(t_polaca*);
char* obtenerSalto(enum EnumTipoSalto);

void vaciarPila(t_pila*);
t_info* sacarDePila(t_pila*);
void crearPila(t_pila*);
int ponerEnPila(t_pila*,t_info*);
t_info* topeDePila(t_pila*);

t_info* topeDePila(t_pila*);
t_info* sacarDePila(t_pila*);
int yyerror();
int yylex();

bool is_prime (int n);

/******************* Variables Globales *******************/

t_polaca polaca;
int contadorPolaca = 0;
char ultimoComparador[3];
enum and_or ultimoOperadorLogico;

int indicesParaAsignarTipo[REGISTROS_MAXIMO];
int contadorListaVar=0;
enum EnumOperacion operacion;
enum EnumOperacion operacionAuxiliar;
char tipoAsignacion[50];
char tipoAsignacionAuxiliar[50];

int yystopparser = 0;
FILE  *yyin;

int contadorIf = 0;
int contadorWhile = 0;
enum tipoCondicion tipoCondicion;

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
%token OP_NE
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
	main
	{
		printf("Compilacion exitosa\n");
	}
;

main: 
	declaraciones resto_programa
	{
		printf("resto_programa\n");
	}
	| declaraciones
	| resto_programa
;

lista_variables:
	ID
	{
		int posicion=buscarEnTablaDeSimbolos($<vals>1);
		indicesParaAsignarTipo[contadorListaVar++] = posicion;
	}
	| lista_variables COMA ID
	{
		int posicion=buscarEnTablaDeSimbolos($<vals>3);
		indicesParaAsignarTipo[contadorListaVar++] = posicion;
	}
;
	
bloque_declaraciones:
	lista_variables OP_DP tipo
	{
		contadorListaVar=0;
	}
	| bloque_declaraciones lista_variables OP_DP tipo
	{
		contadorListaVar=0;
	}
;

tipo:
	INTEGER
	| FLOAT
	| STRING
;

declaraciones:
	INIT LLA bloque_declaraciones LLC
	{
		printf("declaraciones\n");
	}
;

resto_programa: 
	sentencia
	{
		printf("sentencia\n");
	} 
	| resto_programa sentencia
	{
		printf("resto_programa sentencia\n");
	}
;

sentencia:  	   
	asignacion
	{
		printf(" asignacion\n");
	} 
	| if
	{
		printf(" if\n");
	}
	| while
	{
		printf(" while\n");
	}
	| write
	{
		printf(" write\n");
	}
	| read
	{
		printf(" read\n");
	}
;

asignacion: 
	ID
	{
		// Comparar haciendo enums
		if (strcmp(tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo, VACIO) == 0)
		{
			yyerrormsg("Variable sin declarar");
		}
		operacion = asignacion;
		strcpy(tipoAsignacion,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo);
		ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].lexema);
	}
	OP_AS expresion
	{
		operacion = logica;
		strcpy(tipoAsignacion, "VARIABLE");
		ponerEnPolaca(&polaca, "=");
	}
	OP_ENDLINE
	{
		printf("\tID = Expresion es ASIGNACION\n");
	}
;

expresion:
	termino
	{
		printf("Termino es Expresion\n");
	}
	| expresion OP_SUM
		{
			// String e;
			// e = 2 + "HOLA MUNDO";
			// e = "HOLA MUNDO" + 2;
			if(operacion == asignacion && strcmp(tipoAsignacion,"String") == 0)
			{
				yyerrormsg("Operacion invalida con string");
			}
		}
		termino
		{
			ponerEnPolaca(&polaca,"+");
			printf("Expresion + Termino es Expresion\n");
		}
	| expresion OP_RES
		{
			// String e;
			// e = 2 - "HOLA MUNDO";
			// e = "HOLA MUNDO" - 2;
			if (operacion == asignacion && strcmp(tipoAsignacion, "String") == 0)
			{
				yyerrormsg("Operacion invalida con string");
			}
		}
		termino
		{
			ponerEnPolaca(&polaca,"-");
			printf("Expresion - Termino es Expresion\n");
		}
;

termino: 
	factor
	{
		printf("Factor es Termino\n");
	}
	| termino OP_MUL
		{
			if (operacion == asignacion && strcmp(tipoAsignacion, "String") == 0)
			{
				yyerrormsg("Operacion invalida con string");
			}
		}
		factor
		{
			ponerEnPolaca(&polaca,"*");
			printf(" Termino*Factor es Termino\n");
		}
	| termino OP_DIV
		{
			if(operacion == asignacion && strcmp(tipoAsignacion,"String")==0)
			{
				yyerrormsg("Operacion invalida con string");
			}
		}
		factor
		{
			ponerEnPolaca(&polaca,"/");
			printf(" Termino/Factor es Termino\n");
		}
;

factor: 
    ID
	{
        int posicion = buscarEnTablaDeSimbolos($<vals>1);
		// x = 1;
        if (strcmp(tablaDeSimbolos[posicion].tipo, "") == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
		// int a;
		// String e;
		// a = e;
        if (operacion == asignacion && strcmp(tablaDeSimbolos[posicion].tipo, "String") == 0 && strcmp(tipoAsignacion, "String") != 0)
        {
            yyerrormsg("Intenta asignar ID de distinto tipo (string)");
        }
		// int a;
		// float b;
		// a = b;
        if (operacion == asignacion && strcmp(tablaDeSimbolos[posicion].tipo, "Float") == 0 && strcmp(tipoAsignacion,"Int") == 0)
        {
            yyerrormsg("Intenta asignar variable float a un int");
        }
		// int a;
		// String e;
		// a = e;

		// float a;
		// String e;
		// a = e;
		if (operacion == asignacion && strcmp(tablaDeSimbolos[posicion].tipo, "String") != 0 && strcmp(tipoAsignacion, "String") == 0)
        {
            yyerrormsg("Intenta asignar ID de distinto tipo (Int o Float)");
        }
		// String e = "HOLA MUNDO";
		// if (e == "HOLA MUNDO") { }
		if (operacion == logica && strcmp(tablaDeSimbolos[posicion].tipo, "String") == 0)
        {
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
        }
		// int a = 1;
		// sliceAndConcat(3, 6, a, "verde", TRUE); (En el tercer parametro deberia ir un String)
		if (operacion == texto && strcmp(tablaDeSimbolos[posicion].tipo, "String") != 0)
        {
            yyerrormsg("Operacion invalida con string");
        }
        ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].lexema);
        printf("    ID es Factor \n");
	}
	| CTE_INT
	{
		// String a
		// a = 2
        if(operacion == asignacion && strcmp(tipoAsignacion, "String") == 0)
        {
            yyerrormsg("Intenta asignar CTE a un String");
        }
		// sliceAndConcat(3, 6, 200, "verde", TRUE); (En el tercer parametro deberia ir un String)
		if (operacion == texto)
        {
            yyerrormsg("Operacion invalida con string");
        }
        ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].valor);
        printf("    CTE es Factor\n");
	}
    | CTE_FLOAT
	{
		// String a
		// a = 2.5
        if (operacion == asignacion && strcmp(tipoAsignacion, "String") == 0)
        {
            yyerrormsg("Intenta asignar CTE de distinto tipo");
        }
		// Int a
		// a = 2.5
        if(operacion == asignacion && strcmp(tipoAsignacion, "Int") == 0)
        {
            yyerrormsg("Intenta asignar CTE float a un int");
        }
		// WRITE(2.5)
		if (operacion == texto)
        {
            yyerrormsg("Operacion invalida con string");
        }
        ponerEnPolaca(&polaca, tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].valor);
        printf("\tCTE es Factor\n");}
    | PA expresion PC
	{
		printf("    Expresion entre parentesis es Factor\n");
	}
	| CTE_STR
	{
		// int a
		// a = "hola"
		if (operacion == asignacion && strcmp(tipoAsignacion, "String") != 0)
		{
			yyerrormsg("Operacion invalida, Intenta asignar un string a un numero");
		}
		// "HOLA" == "MUNDO"
		if (operacion == logica)
		{
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
		}
		printf("CTE_STR es Expresion\n");
	}
	| slice_and_concat
	{
		if (operacion == asignacion && strcmp(tipoAsignacion, "String") != 0)
		{
			yyerrormsg("Operacion invalida, Intenta asignar un string a un numero");
		}
		if(operacion == logica && strcmp(tipoAsignacion, "String") != 0)
		{
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
		}
		printf("\tslice_and_concat es Factor\n");
	}
	| sum_first_primes
	{
        if(operacion == asignacion && strcmp(tipoAsignacion, "String") == 0)
        {
            yyerrormsg("Intenta asignar Int a un String");
        }
		if (operacion == texto)
        {
            yyerrormsg("Operacion invalida con string");
        }
        printf("\tsum_first_primes es Factor\n");
	}
	;

elementos:
	elemento 
	| elemento COMA elementos 
	;
	
elemento:
	expresion
	;
	
sum_first_primes:
	SFP PA
	{
		operacionAuxiliar = operacion;
		operacion = logica;
	}
	/*expresion
	{
		ponerEnPolaca(&polaca, "-");

	}*/
	CTE_INT
	{
		int valor = atoi($<vals>4);
		if (valor < 1)
		{
			yyerrormsg("El valor de SFP no puede ser menor a 1");
		}
		int x = 3;
		ponerEnPolaca(&polaca, "2");
		valor--;
		while(valor != 0)
		{
			if(is_prime(x))
			{
				valor--;
				char aux[50];
				ponerEnPolaca(&polaca, itoa(x, aux, 10));
				ponerEnPolaca(&polaca, "+");
			}
			x++;
			if(x >= LIMITE_SUPERIOR_ENTERO)
			{
				yyerrormsg("El valor resultante supera la cota de enteros");         
			}
		}
	}
	PC
	{
		printf("\tSFP(expresion) es sumFirstPrimes\n");
		operacion = operacionAuxiliar;
	}
;

slice_and_concat:
	SAC PA
	{
		operacionAuxiliar = operacion;
		operacion = logica;
	}
	expresion COMA expresion COMA
	{
		operacion = texto;
	}
	expresion COMA expresion COMA BOOL PC
	{
		printf("\tSAC(expresion,expresion,expresion,expresion,BOOL) es sliceAndConcat\n");
		operacion = operacionAuxiliar;
	}
;

write:
    WRITE PA CTE_STR PC OP_ENDLINE
	| WRITE PA ID
	{
		int posicion = buscarEnTablaDeSimbolos($<vals>3);
        if (strcmp(tablaDeSimbolos[posicion].tipo, "") == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
	}
	PC OP_ENDLINE
	;

read: 
	READ PA CTE_STR PC OP_ENDLINE
	| READ PA ID
	{
		int posicion = buscarEnTablaDeSimbolos($<vals>3);
        if (strcmp(tablaDeSimbolos[posicion].tipo, "") == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
	}
	PC OP_ENDLINE
;

operador_comparacion:
	OP_LOW { strcpy(ultimoComparador,$<vals>1); }
	| OP_GREAT { strcpy(ultimoComparador,$<vals>1);	}
	| OP_EQUAL { strcpy(ultimoComparador,$<vals>1); }
	| OP_LE { strcpy(ultimoComparador,$<vals>1); }
	| OP_GE { strcpy(ultimoComparador,$<vals>1); }
	| OP_NE { strcpy(ultimoComparador,$<vals>1); }
;

operador_logico:
	AND { ultimoOperadorLogico = and; }
	| OR { ultimoOperadorLogico = or; }
;

operador_negacion: NOT ;

while:
	WHILE
	{
		t_info info;
		info.nro = contadorWhile++;
		info.saltoElse = contadorPolaca;
		ponerEnPila(&pilaWhile, &info);
		tipoCondicion = condicionWhile;
		ponerEnPolaca(&polaca, "ET");
	} 
	PA condicion PC bloque_ejecucion	
	{
		char aux[20];
		sprintf(aux, "%d", topeDePila(&pilaWhile)->saltoElse);
		ponerEnPolaca(&polaca,"BI");
		ponerEnPolaca(&polaca, aux);
		sprintf(aux, "%d", contadorPolaca);
		switch (topeDePila(&pilaWhile)->andOr)
		{
			case condicionSimple:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto1, aux);
				break;
			case and:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto1, aux);
				ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto2, aux);
			case or:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto2, aux);
				break;
		}
		sacarDePila(&pilaWhile);
	}
;

condicion:
	comparacion
	{
		switch(tipoCondicion)
		{
			case condicionIf:
				ponerEnPolaca(&polaca, CMP);
				ponerEnPolaca(&polaca,obtenerSalto(inverso));
				topeDePila(&pilaIf)->salto1=contadorPolaca;
				ponerEnPolaca(&polaca,"");
				topeDePila(&pilaIf)->andOr = condicionSimple;
				break;

			case condicionWhile:
				ponerEnPolaca(&polaca, CMP);
				ponerEnPolaca(&polaca,obtenerSalto(inverso));
				topeDePila(&pilaWhile)->salto1=contadorPolaca;
				ponerEnPolaca(&polaca,"");
				topeDePila(&pilaWhile)->andOr = condicionSimple;
				break;
		}
	}
	|operador_negacion comparacion
			{
				switch(tipoCondicion)
				{
					case condicionIf:
						ponerEnPolaca(&polaca, CMP);
						ponerEnPolaca(&polaca,obtenerSalto(normal));
						topeDePila(&pilaIf)->salto1=contadorPolaca;
						ponerEnPolaca(&polaca,"");
						topeDePila(&pilaIf)->andOr = condicionSimple;
						break;

					case condicionWhile:
						ponerEnPolaca(&polaca, CMP);
						ponerEnPolaca(&polaca,obtenerSalto(normal));
						topeDePila(&pilaWhile)->salto1=contadorPolaca;
						ponerEnPolaca(&polaca,"");
						topeDePila(&pilaWhile)->andOr = condicionSimple;
						break;
				}
			}
	| comparacion operador_logico
			{
				switch(tipoCondicion)
				{
					case condicionIf:
						switch(ultimoOperadorLogico){
							case and:
								ponerEnPolaca(&polaca, CMP);
								ponerEnPolaca(&polaca,obtenerSalto(inverso));
								topeDePila(&pilaIf)->salto1=contadorPolaca;
								ponerEnPolaca(&polaca,"");
								printf("%d", topeDePila(&pilaIf)->salto1);
								topeDePila(&pilaIf)->andOr = and;
								break;
							case or:
								ponerEnPolaca(&polaca, CMP);
								ponerEnPolaca(&polaca,obtenerSalto(normal));
								topeDePila(&pilaIf)->salto1=contadorPolaca;
								ponerEnPolaca(&polaca,"");
								topeDePila(&pilaIf)->andOr = or;
								break;
						}
						break;

					case condicionWhile:
						switch(ultimoOperadorLogico){
							case and:
								ponerEnPolaca(&polaca, CMP);
								ponerEnPolaca(&polaca,obtenerSalto(inverso));
								topeDePila(&pilaWhile)->salto1=contadorPolaca;
								ponerEnPolaca(&polaca,"");
								topeDePila(&pilaWhile)->andOr = and;
								break;

							case or:
								ponerEnPolaca(&polaca, CMP);
								ponerEnPolaca(&polaca,obtenerSalto(normal));
								topeDePila(&pilaWhile)->salto1=contadorPolaca;
								ponerEnPolaca(&polaca,"");
								topeDePila(&pilaWhile)->andOr = or;
								break;
						}
						break;
				}
			}
			comparacion
				{
					switch(tipoCondicion)
					{
						case condicionIf:
							ponerEnPolaca(&polaca, CMP);
							ponerEnPolaca(&polaca,obtenerSalto(inverso));
							topeDePila(&pilaIf)->salto2=contadorPolaca;
							ponerEnPolaca(&polaca,"");
							if(topeDePila(&pilaIf)->andOr == or){
								char aux[20];
								sprintf(aux, "%d", contadorPolaca);
								ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
							}
							break;

						case condicionWhile:
							ponerEnPolaca(&polaca, CMP);
							ponerEnPolaca(&polaca,obtenerSalto(inverso));
							topeDePila(&pilaWhile)->salto2=contadorPolaca;
							ponerEnPolaca(&polaca,"");
							if(topeDePila(&pilaWhile)->andOr == or){
								char aux[20];
								sprintf(aux, "%d", contadorPolaca);
								ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto1, aux);
							}
							break;
					}
	            }
	
	comparacion:
		expresion operador_comparacion expresion
		| PA comparacion PC
;

if:
	IF 
		{
			t_info info;
			info.nro=contadorIf++;
			ponerEnPila(&pilaIf,&info);
			tipoCondicion=condicionIf;
		}
	PA condicion PC resto
	{
		sacarDePila(&pilaIf);
	}
	;

else:
	ELSE
	{
		char aux[20];
		sprintf(aux, "%d", contadorPolaca);
		switch (topeDePila(&pilaIf)->andOr)
		{
		case condicionSimple:
			ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
			break;
		case and:
			ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
			ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
		case or:
			ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
			break;
		}
	}
	bloque_ejecucion
	{
		char aux[20];
		sprintf(aux, "%d", contadorPolaca);
		ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->saltoElse, aux);
	}
	;

bloque_ejecucion: LLA resto_programa LLC ;

resto: 
	bloque_ejecucion
	{
		char aux[20];
		sprintf(aux, "%d", contadorPolaca);
		switch (topeDePila(&pilaIf)->andOr)
		{
			case condicionSimple:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
				break;
			case and:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
			case or:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
				break;
		}
	}
	| bloque_ejecucion
	{
		char aux[20];
		ponerEnPolaca(&polaca,"BI");
		topeDePila(&pilaIf)->saltoElse = contadorPolaca;
		ponerEnPolaca(&polaca, "");
		if(topeDePila(&pilaIf)->andOr != or){
			sprintf(aux, "%d", contadorPolaca);
			ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
		}
	}
	else
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

/****************************** Métodos Polaca (Primitivas) ******************************/

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
	FILE*pt = fopen("intermediate-code.txt","w+");
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

char* obtenerSalto(enum EnumTipoSalto tipo)
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

/****************************** Métodos pila (Primitivas) ******************************/

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

/*********************************************************************************/

int main(int argc, char *argv[])
{
	crearPila(&pilaIf);
	crearPolaca(&polaca);
    if ((yyin = fopen(argv[1], "rt")) == NULL)
	{
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    }
	else
	{ 
    	yyparse();
    }
    // mostrarTablaDeSimbolos(); Función para realizar el debug de la tabla de simbolos.
    crearTablaDeSimbolos();
	fclose(yyin);
	guardarPolaca(&polaca);
  	return 0;
}

bool is_prime (int n)
{
  if (n % 2 == 0)
  {
    return n == 2;
  }
  for (int test_factor = 3; test_factor <= n / test_factor; test_factor += 2)
  {
    if (n % test_factor == 0)
	{
      return FALSE;
    }
  }
  return n > 1;
}
