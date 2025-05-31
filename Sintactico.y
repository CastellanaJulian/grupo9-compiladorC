%{
/******************* Librerias *******************/

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include "y.tab.h"
#include "Pila.h"
#include "Polaca.h"

/******************* Defines *******************/

#define TIPO_INT "Int"
#define TIPO_FLOAT "Float"
#define TIPO_STRING "String"
#define LIMITE_SUPERIOR_ENTERO 65535
#define REGISTROS_MAXIMO 1000
#define TRUE 1
#define FALSE 0
#define VACIO ""

/******************* Enums *******************/

enum EnumTipoCondicion
{
	condicionIf,
	condicionWhile
};

enum EnumOperacion
{
	asignacion,
	logica,
	texto,
};

/******************* Estructuras *******************/

typedef struct
{
    char lexema[50];
    char tipo[50];
    char valor[50];
    int longitud;
} t_symbol_table;

/******************* Declaraciones Implicitas *******************/

extern int yyerrormsg(const char *);
extern int buscarEnTablaDeSimbolos(char*);
extern int crearTablaDeSimbolos();
extern t_symbol_table tablaDeSimbolos[REGISTROS_MAXIMO];
extern char* yytext;
extern int yylineno;

/******************* Funciones *******************/

int yyerror();
int yylex();
bool is_prime (int numero);

/******************* Variables Globales *******************/

Pila pilaIf;
Pila pilaWhile;
Polaca polaca;

enum and_or ultimoOperadorLogico;

int indicesParaAsignarTipo[REGISTROS_MAXIMO];
int contadorListaVar = 0;
int esAsignacion = 0;
char tipoAsignacion[50];

int contadorIf = 0;
int contadorWhile = 0;
enum EnumTipoCondicion tipoCondicion;

int yystopparser = 0;
FILE  *yyin;

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
		int posicion = buscarEnTablaDeSimbolos($<vals>1);
		indicesParaAsignarTipo[contadorListaVar++] = posicion;
	}
	| lista_variables COMA ID
	{
		int posicion = buscarEnTablaDeSimbolos($<vals>3);
		indicesParaAsignarTipo[contadorListaVar++] = posicion;
	}
;
	
bloque_declaraciones:
	lista_variables OP_DP tipo
	{
		contadorListaVar = 0;
	}
	| bloque_declaraciones lista_variables OP_DP tipo
	{
		contadorListaVar = 0;
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
	asignacion { printf(" asignacion\n"); } 
	| if { printf(" if\n"); }
	| while { printf(" while\n"); }
	| write { printf(" write\n"); }
	| read { printf(" read\n"); }
;

asignacion: 
	ID
	{
		if (strcmp(tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo, VACIO) == 0)
		{
			yyerrormsg("Variable sin declarar");
		}
		esAsignacion = 1;
		strcpy(tipoAsignacion, tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].tipo);
		ponerEnPolaca(&polaca, tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].lexema);
	}
	OP_AS expresion
	{
		esAsignacion = 0;
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
			if( esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
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
			if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
			{
				yyerrormsg("Operacion invalida con String");
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
			if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
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
			if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
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
        if (strcmp(tablaDeSimbolos[posicion].tipo, VACIO) == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
		// int a;
		// String e;
		// a = e;
        if (esAsignacion && strcmp(tablaDeSimbolos[posicion].tipo, TIPO_STRING) == 0 && strcmp(tipoAsignacion, TIPO_STRING) != 0)
        {
            yyerrormsg("Intenta asignar un string a un ID de distinto tipo");
        }
		// int a;
		// float b;
		// a = b;
        if (esAsignacion && strcmp(tablaDeSimbolos[posicion].tipo, TIPO_FLOAT) == 0 && strcmp(tipoAsignacion, TIPO_INT) == 0)
        {
            yyerrormsg("Intenta asignar un ID Float a un Int");
        }
		// int a;
		// String e;
		// a = e;

		// float a;
		// String e;
		// a = e;
		if (esAsignacion && strcmp(tablaDeSimbolos[posicion].tipo, TIPO_STRING) != 0 && strcmp(tipoAsignacion, TIPO_STRING) == 0)
        {
            yyerrormsg("Intenta asignar un ID de distinto tipo a un string");
        }
		// String e = "HOLA MUNDO";
		// if (e == "HOLA MUNDO") { }
		if ( !esAsignacion && strcmp(tablaDeSimbolos[posicion].tipo, TIPO_STRING) == 0)
        {
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
        }
        ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].lexema);
        printf("    ID es Factor \n");
	}
	| CTE_INT
	{
		// String a
		// a = 2
        if(esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
        {
            yyerrormsg("Intenta asignar CTE int a un String");
        }
        ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].valor);
        printf("    CTE es Factor\n");
	}
    | CTE_FLOAT
	{
		// String a
		// a = 2.5
        if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
        {
            yyerrormsg("Intenta asignar CTE float a un string");
        }
		// Int a
		// a = 2.5
        if(esAsignacion && strcmp(tipoAsignacion, TIPO_INT) == 0)
        {
            yyerrormsg("Intenta asignar CTE Float a un Int");
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
		if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) != 0)
		{
			yyerrormsg("Operacion invalida, Intenta asignar un string a un numero");
		}
		// "HOLA" == "MUNDO"
		if (!esAsignacion)
		{
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
		}
		ponerEnPolaca(&polaca,tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].valor);
		printf("CTE_STR es Expresion\n");
	}
	| slice_and_concat
	{
		if (esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) != 0)
		{
			yyerrormsg("Operacion invalida, Intenta asignar un string a un numero");
		}
		if (!esAsignacion)
		{
            yyerrormsg("Operacion invalida, intenta usar string en operacion logica");
		}
		printf("\tslice_and_concat es Factor\n");
	}
	| sum_first_primes
	{
        if(esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
        {
            yyerrormsg("Intenta asignar un Int a un String");
        }
        printf("\tsum_first_primes es Factor\n");
	}
	;
	
sum_first_primes:
	SFP PA
	CTE_INT
	{
		int valor = atoi($<vals>3);
		printf("Valor de SFP: %d\n", valor);
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
	}
;

slice_and_concat:
	SAC PA CTE_INT 	

	COMA CTE_INT 

	COMA CTE_STR 

	COMA CTE_STR 

	COMA BOOL PC
	{
		if(!strcmp("FALSE",$<vals>11))
		{
			ponerEnPolaca(&polaca, $<vals>7);
			ponerEnPolaca(&polaca, $<vals>3);
			ponerEnPolaca(&polaca, "CUTL");
			ponerEnPolaca(&polaca, $<vals>5);
			ponerEnPolaca(&polaca, "CUTU");
			ponerEnPolaca(&polaca, $<vals>9);
			ponerEnPolaca(&polaca, "CONCAT");
		}
		if(!strcmp("TRUE",$<vals>11))
		{
			ponerEnPolaca(&polaca, $<vals>9);
			ponerEnPolaca(&polaca, $<vals>3);
			ponerEnPolaca(&polaca, "CUTL");
			ponerEnPolaca(&polaca, $<vals>5);
			ponerEnPolaca(&polaca, "CUTU");
			ponerEnPolaca(&polaca, $<vals>7);
			ponerEnPolaca(&polaca, "CONCAT");
		}
		printf("\tSAC(expresion,expresion,expresion,expresion,BOOL) es sliceAndConcat\n");
	}
;

write:
    WRITE PA CTE_STR 
	{
		ponerEnPolaca(&polaca, $<vals>3);
		ponerEnPolaca(&polaca, "WRITE");
	}
	PC OP_ENDLINE
	| WRITE PA ID
	{
		int posicion = buscarEnTablaDeSimbolos($<vals>3);
        if (strcmp(tablaDeSimbolos[posicion].tipo, VACIO) == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
		ponerEnPolaca(&polaca, $<vals>3);
		ponerEnPolaca(&polaca, "WRITE");
	}
	PC OP_ENDLINE
	;

read: 
	READ PA ID
	{
		int posicion = buscarEnTablaDeSimbolos($<vals>3);
        if (strcmp(tablaDeSimbolos[posicion].tipo, VACIO) == 0)
        {
            yyerrormsg("Variable sin declarar");
        }
		ponerEnPolaca(&polaca, $<vals>3);
		ponerEnPolaca(&polaca, "READ");
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
		Informacion info;
		info.nro = contadorWhile++;
		info.saltoElse = contadorPolaca;
		ponerEnPila(&pilaWhile, &info);
		tipoCondicion = condicionWhile;
		ponerEnPolaca(&polaca, ET);
	} 
	PA condicion PC bloque_ejecucion	
	{
		char aux[20];
		sprintf(aux, "%d", topeDePila(&pilaWhile)->saltoElse);
		ponerEnPolaca(&polaca, BI);
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
				topeDePila(&pilaIf)->salto1 = contadorPolaca;
				ponerEnPolaca(&polaca, VACIO);
				topeDePila(&pilaIf)->andOr = condicionSimple;
				break;

			case condicionWhile:
				ponerEnPolaca(&polaca, CMP);
				ponerEnPolaca(&polaca,obtenerSalto(inverso));
				topeDePila(&pilaWhile)->salto1 = contadorPolaca;
				ponerEnPolaca(&polaca, VACIO);
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
				topeDePila(&pilaIf)->salto1 = contadorPolaca;
				ponerEnPolaca(&polaca, VACIO);
				topeDePila(&pilaIf)->andOr = condicionSimple;
				break;

			case condicionWhile:
				ponerEnPolaca(&polaca, CMP);
				ponerEnPolaca(&polaca,obtenerSalto(normal));
				topeDePila(&pilaWhile)->salto1 = contadorPolaca;
				ponerEnPolaca(&polaca, VACIO);
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
							ponerEnPolaca(&polaca, obtenerSalto(inverso));
							topeDePila(&pilaIf)->salto1 = contadorPolaca;
							ponerEnPolaca(&polaca, VACIO);
							printf("%d", topeDePila(&pilaIf)->salto1);
							topeDePila(&pilaIf)->andOr = and;
							break;
						case or:
							ponerEnPolaca(&polaca, CMP);
							ponerEnPolaca(&polaca, obtenerSalto(normal));
							topeDePila(&pilaIf)->salto1 = contadorPolaca;
							ponerEnPolaca(&polaca, VACIO);
							topeDePila(&pilaIf)->andOr = or;
							break;
					}
					break;

				case condicionWhile:
					switch(ultimoOperadorLogico){
						case and:
							ponerEnPolaca(&polaca, CMP);
							ponerEnPolaca(&polaca, obtenerSalto(inverso));
							topeDePila(&pilaWhile)->salto1 = contadorPolaca;
							ponerEnPolaca(&polaca, VACIO);
							topeDePila(&pilaWhile)->andOr = and;
							break;

						case or:
							ponerEnPolaca(&polaca, CMP);
							ponerEnPolaca(&polaca,obtenerSalto(normal));
							topeDePila(&pilaWhile)->salto1 = contadorPolaca;
							ponerEnPolaca(&polaca, VACIO);
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
					ponerEnPolaca(&polaca, obtenerSalto(inverso));
					topeDePila(&pilaIf)->salto2 = contadorPolaca;
					ponerEnPolaca(&polaca, VACIO);
					if(topeDePila(&pilaIf)->andOr == or){
						char aux[20];
						sprintf(aux, "%d", contadorPolaca);
						ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
					}
					break;

				case condicionWhile:
					ponerEnPolaca(&polaca, CMP);
					ponerEnPolaca(&polaca,obtenerSalto(inverso));
					topeDePila(&pilaWhile)->salto2 = contadorPolaca;
					ponerEnPolaca(&polaca, VACIO);
					if(topeDePila(&pilaWhile)->andOr == or)
					{
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
		Informacion info;
		info.nro = contadorIf++;
		ponerEnPila(&pilaIf, &info);
		tipoCondicion = condicionIf;
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
		ponerEnPolaca(&polaca, BI);
		topeDePila(&pilaIf)->saltoElse = contadorPolaca;
		ponerEnPolaca(&polaca, VACIO);
		if(topeDePila(&pilaIf)->andOr != or)
		{
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
	// Función para realizar el debug de la tabla de simbolos.
	// mostrarTablaDeSimbolos();
	crearTablaDeSimbolos();
	fclose(yyin);
	guardarPolaca(&polaca);
	return 0;
}

bool is_prime (int numero)
{
	if (numero % 2 == 0)
	{
		return numero == 2;
	}
	for (int test_factor = 3; test_factor <= numero / test_factor; test_factor += 2)
	{
		if (numero % test_factor == 0)
		{
		return FALSE;
		}
	}
	return numero > 1;
}
