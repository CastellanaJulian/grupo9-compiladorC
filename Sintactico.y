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

#define CONSTANTE_FLOAT "CTE_FLOAT"
#define CONSTANTE_INT "CTE_INT"
#define CONSTANTE_STR "CTE_STR"

#define LIMITE_SUPERIOR_ENTERO 65535
#define REGISTROS_MAXIMO 1000
#define TRUE 1
#define FALSE 0
#define ERROR -1
#define OK 3

#define VACIO ""
#define RESTA "-"
#define SUMA "+"
#define MULTIPLICACION "*"
#define DIVISION "/"
#define ASIGNACION "="
#define MOV "MOV"

#define NOMBRE_ARCHIVO_ASSEMBLER "final.asm"

#define ES_STRING(tipo)   (strcmp((tipo), TIPO_STRING) == 0 || strcmp((tipo), CONSTANTE_STR) == 0)
#define ES_ENTERO(tipo)   (strcmp((tipo), TIPO_INT) == 0 || strcmp((tipo), CONSTANTE_INT) == 0)
#define ES_FLOAT(tipo)    (strcmp((tipo), TIPO_FLOAT) == 0 || strcmp((tipo), CONSTANTE_FLOAT) == 0)

#define SON_AMBOS_ENTEROS(op1, op2) (ES_ENTERO(op1) && ES_ENTERO(op2))
#define SON_AMBOS_FLOAT(op1, op2)   (ES_FLOAT(op1) && ES_FLOAT(op2))

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
} TablaDeSimbolos;

/******************* Declaraciones Implicitas *******************/

extern int crearTablaDeSimbolos();
extern int yyerrormsg(const char *);
extern int buscarEnTablaDeSimbolos(char*);
extern char* reemplazarCaracter(char const *, char const *, char const *);
extern void agregarATablaDeSimbolos(char* lexema, int esConstante, int esTipo);
extern TablaDeSimbolos tablaDeSimbolos[REGISTROS_MAXIMO];
extern char* yytext;
extern int yylineno;
extern int registroTabla;
extern FILE  *yyin;

/******************* Funciones *******************/

int yyerror();
int yylex();
bool esPrimo (int);
void removeQuotes(char *);
char* addQuotes(char *);
char* sliceAndConcat(int, int, char *, char *, bool);
void generarAssembler(Polaca*);
void generarCabeceraAssembler(FILE*);
void obtenerNombreAssembler(const char*, const char*, char*);
void declararVariablesEnAssembler();
void generarComienzoDePrograma(FILE*);
void manejarVariables(char*, char*, int*);
void manejarConstantes(char*, char*, int*);
void manejarOperacionArimetica(const char*, FILE*, char*, char*, int*, int*);
void manejarComparador(const char*, FILE*, int*);
void manejarAsignacion(const char*, FILE*, int*, int*);
void manejarComandoRead(char*, FILE*, const char*);
void manejarComandoWrite(char*, FILE*, const char*);
void finalizarEjecucionCodigoAssembler(FILE*);

/******************* Variables Globales *******************/

Pila pilaIf;
Pila pilaWhile;
Pila pilaASM;
Polaca polaca;
Polaca polacaASM;

enum and_or ultimoOperadorLogico;

int indicesParaAsignarTipo[REGISTROS_MAXIMO];
int contadorListaVar = 0;
int esAsignacion = 0;
char tipoAsignacion[50];

int contadorIf = 0;
int contadorWhile = 0;
enum EnumTipoCondicion tipoCondicion;

int yystopparser = 0;
int auxiliaresNecesarios = 0;

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
			auxiliaresNecesarios++;
			// String e;
			// e = 2 + "HOLA MUNDO";
			// e = "HOLA MUNDO" + 2;
			if(esAsignacion && strcmp(tipoAsignacion, TIPO_STRING) == 0)
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
			auxiliaresNecesarios++;
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
			auxiliaresNecesarios++;
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
			auxiliaresNecesarios++;
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
        printf("\tCTE es Factor\n");
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
		ponerEnPolaca(&polaca, tablaDeSimbolos[buscarEnTablaDeSimbolos($<vals>1)].valor);
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
		int suma = 2;
		int x = 3;
		valor--;
		while(valor != 0)
		{
			if(esPrimo(x))
			{
				valor--;
				suma += x;
			}
			x++;
			if(x >= LIMITE_SUPERIOR_ENTERO)
			{
				yyerrormsg("El valor resultante supera la cota de enteros");         
			}
		}
		char aux[50];
		snprintf(aux, sizeof(aux), "%d", suma);
		ponerEnPolaca(&polaca, aux);
		agregarATablaDeSimbolos(aux, 1, 0);
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
		int limiteInicial = atoi($<vals>3);
		int limiteFinal = atoi($<vals>5);
		char* palabra1 = $<vals>7;
		char* palabra2 = $<vals>9;
		bool concatenarEnPalabra1 = strcmp("TRUE", $<vals>11) == 0;
		char* resultado = sliceAndConcat(limiteInicial, limiteFinal, palabra1, palabra2, concatenarEnPalabra1);
		ponerEnPolaca(&polaca, resultado);
		agregarATablaDeSimbolos(resultado, 1, 0);
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
		char etiqueta[20];
		strcpy(etiqueta, "#");
		char tmp[12];
		itoa(contadorPolaca, tmp, 10);
		strcat(etiqueta, tmp); 
		ponerEnPolaca(&polaca, etiqueta);
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
				break;
			case or:
				ponerEnPolacaNro(&polaca, topeDePila(&pilaWhile)->salto2, aux);
				break;
		}
		sacarDePila(&pilaWhile);
		char etiqueta[20];
		strcpy(etiqueta, "#");
		char tmp[12];
		itoa(contadorPolaca, tmp, 10);
		strcat(etiqueta, tmp); 
		ponerEnPolaca(&polaca, etiqueta);
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
	| operador_negacion comparacion
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
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
				break;
		}
		char aux2[CADENA_MAXIMA];
		strcpy(aux2, "#");
		strcat(aux2, aux);
		ponerEnPolaca(&polaca, aux2);
	}
	bloque_ejecucion
	{
		char aux[20];
		sprintf(aux, "%d", contadorPolaca);
		ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->saltoElse, aux);
		char aux2[20];
		strcpy(aux2, "#");
		strcat(aux2, aux);
		ponerEnPolaca(&polaca, aux2);
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
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto1, aux);
				ponerEnPolacaNro(&polaca, topeDePila(&pilaIf)->salto2, aux);
				break;
		}
		char aux2[20];
		strcpy(aux2, "#");
		strcat(aux2, aux);
		ponerEnPolaca(&polaca, aux2);
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

/******************* Funciones Especiales *******************/

bool esPrimo (int numero)
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

void eliminarComillas (char* cadena)
{
    char *origen = cadena, *destino = cadena;
    while (*origen)
	{
        if (*origen != '"')
		{
            *destino++ = *origen;
        }
        origen++;
    }
    *destino = '\0';
}

char* agregarComillas (char* cadena)
{
    int longitud = strlen(cadena);
    char* resultado = (char*)malloc((longitud + 3) * sizeof(char));
    if (!resultado)
	{
        fprintf(stderr, "Error de memoria\n");
        exit(EXIT_FAILURE);
    }
    resultado[0] = '"';
    memcpy(resultado + 1, cadena, longitud);
    resultado[longitud + 1] = '"';
    resultado[longitud + 2] = '\0';
    return resultado;
}

char* sliceAndConcat (int limiteInicial, int limiteFinal, char *palabra1, char *palabra2,  bool concatenarEnPalabra1)
{
	if(limiteInicial < 0 || limiteFinal < 0)
	{
		yyerrormsg("Los limites deben ser mayores o iguales a 0");
	}
	if(limiteInicial > limiteFinal)
	{
		yyerrormsg("El limite inicial debe ser menor al limite final");
	}
	if(limiteFinal >= strlen(!concatenarEnPalabra1? palabra1 : palabra2) - 2)
	{
		yyerrormsg("Los limites deben estar dentro del rango de la cadena");
	}
	if(limiteFinal - limiteInicial + strlen(concatenarEnPalabra1? palabra1 : palabra2) >= CADENA_MAXIMA)
	{
		yyerrormsg("La longitud de la cadena resultante supera el limite de caracteres");
	}
	eliminarComillas(palabra1);
	eliminarComillas(palabra2);
	char* resultado = (char*)malloc(CADENA_MAXIMA * sizeof(char));
	strcpy(resultado, concatenarEnPalabra1 ? palabra1 : palabra2);
	const char* origen = concatenarEnPalabra1 ? palabra2 : palabra1;
	char * inicioResultado = resultado;
	while(*resultado != '\0')
	{
		resultado++;
	}
	origen += limiteInicial;
	limiteFinal -= limiteInicial;
	while(limiteFinal >= 0)
	{
		*resultado = *origen;
		resultado++;
		origen++;
		limiteFinal--;
	}
	*resultado = '\0';
	return agregarComillas(inicioResultado);
}

/******************* Funciones Assembler *******************/

void generarCabeceraAssembler(FILE* pf)
{
	fprintf(pf, "INCLUDE macros2.asm\n");
	fprintf(pf, "INCLUDE number.asm\n");
	fprintf(pf, "\n");
	fprintf(pf, ".MODEL LARGE\n");
	fprintf(pf, ".386\n");
	fprintf(pf, ".STACK 200h\n");
	fprintf(pf, "\n");
    fprintf(pf, "TRUE\t\tEQU\t\t1\n");
    fprintf(pf, "FALSE\t\tEQU\t\t0\n");
    fprintf(pf, "MAXTEXTSIZE\tEQU\t\t%d\n", CADENA_MAXIMA);
	fprintf(pf, "\n");
	fprintf(pf, ".DATA\n");
}

void obtenerNombreAssembler(const char *lex, const char *tipo, char *nombreAsm)
{
    char tmp[64];
    if (strcmp(tipo, TIPO_INT) == 0 || strcmp(tipo, TIPO_FLOAT) == 0 || strcmp(tipo, TIPO_STRING) == 0)
    {
        if (lex[0] == '_')
		{
            strcpy(nombreAsm, lex + 1);
		}
        else
		{
            strcpy(nombreAsm, lex);
		}
    }
    else if (strcmp(tipo, CONSTANTE_INT) == 0)
    {
		const char *start = lex;
		if (*start == '_')
		{
			start++;
		}
		if(*start == '-')
		{
			start++;
			snprintf(nombreAsm, 64, "_NEG_%s", start);
		}
		else
		{
			snprintf(nombreAsm, 64, "_%s", start);
		}		
    }
    else if (strcmp(tipo, CONSTANTE_FLOAT) == 0)
    {
		const char *start = lex;
		if (*start == '_')
		{
			start++;
		}
		strcpy(tmp, start);
		for (char *p = tmp; *p; ++p)
		{
			if (*p == '.')
			{
				*p = '_';
			}
		}
		if(*tmp == '-')
		{
			snprintf(nombreAsm, 64, "_NEG_%s", tmp + 1);
		}
		else
		{
			snprintf(nombreAsm, 64, "_%s", tmp);
		}
    }
    else if (strcmp(tipo, CONSTANTE_STR) == 0)
    {
		const char *start = lex;
		if (*start == '_')
			start++;
		if (*start == '"' || *start == '\'')
			start++;
		size_t len = strlen(start);
		if (len > 0 && (start[len-1] == '"' || start[len-1] == '\''))
			len--;
		size_t pos = 0;
		for (size_t i = 0; i < len; ++i) {
			char c = start[i];
			tmp[pos++] = (c == ' ' ? '_' : c);
		}
		tmp[pos] = '\0';
		snprintf(nombreAsm, 128, "_T_%s", tmp);
    }
}

void declararVariablesEnAssembler(FILE* pf)
{
	int i;
	char nombreAssembler[64];

	for(i = 0; i < registroTabla; i++)
    {
        const char *lexema  = tablaDeSimbolos[i].lexema;
        const char *tipoDeDato = tablaDeSimbolos[i].tipo;
        const char *valor  = tablaDeSimbolos[i].valor;
        obtenerNombreAssembler(lexema, tipoDeDato, nombreAssembler);

		// INTEGER
		if(strcmp(tipoDeDato, TIPO_INT) == 0  && atoi(valor) == 0)
		{
			fprintf(pf, "\t%s\t\tdd\t\t?\n", nombreAssembler);
		}
		
		// CTE_INT
		if(strcmp(tipoDeDato, CONSTANTE_INT) == 0)
		{
			fprintf(pf, "\t%s\t\tdd\t\t%s\n", nombreAssembler, valor);
		}
		
		// FLOAT
		if(strcmp(tipoDeDato, TIPO_FLOAT) == 0 && atof(valor) == 0)
		{
			fprintf(pf, "\t%s\t\tdd\t\t?\n", nombreAssembler);
		}
		
		// CTE_FLOAT
		if((strcmp(tipoDeDato, CONSTANTE_FLOAT) == 0) && atof(valor))
		{
			fprintf(pf, "\t%s\t\tdd\t\t%s\n", nombreAssembler, valor);
		}

		// STRING
		if(strcmp(tipoDeDato, TIPO_STRING) == 0 && strcmp(valor, VACIO) == 0)
		{
			fprintf(pf, "\t%s\t\tdb\t\tMAXTEXTSIZE dup (?), '$'\n", nombreAssembler);
		}
		
		// CTE_STR
		if((strcmp(tipoDeDato, CONSTANTE_STR) == 0) && strcmp(valor, VACIO) != 0)
		{
			int longitud = (tablaDeSimbolos[i]).longitud;
			int size = CADENA_MAXIMA - longitud;
			fprintf(pf, "\t%s\t\tdb\t\t%s, '$', %d dup (?)\n", nombreAssembler, valor, size);
		}
	}

	for(i = 0; i < auxiliaresNecesarios; i++)
	{
		fprintf(pf,"\tauxR%d\tDD\t0.0\n", i);
	}
	
	for(i = 0; i < auxiliaresNecesarios; i++)
	{
		fprintf(pf,"\tauxE%d\tDW\t0\n", i);
	}

	fprintf(pf, "\n");
}

void generarComienzoDePrograma(FILE* pf)
{
	fprintf(pf,".CODE\n");
	fprintf(pf, ".startup\n");
	fprintf(pf, "\tMOV AX,@DATA\n");
	fprintf(pf, "\tMOV DS,AX\n");
}

void manejarVariables(char* linea, char* ultimoTipo, int* huboAsignacion)
{
	int posicion = buscarEnTablaDeSimbolos(linea);
	if(posicion != ERROR && strcmp(tablaDeSimbolos[posicion].valor, VACIO) == 0)
	{
		Informacion informacion;
		informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		strcpy(informacion.cadena, linea);
		informacion.tipoDeDato = tablaDeSimbolos[posicion].tipo;
		*huboAsignacion = pilaASM || *huboAsignacion == FALSE ? TRUE : FALSE;
		ponerEnPila(&pilaASM, &informacion);
		strcpy(ultimoTipo, informacion.tipoDeDato);
	}
}

void manejarConstantes(char* linea, char* ultimoTipo, int* huboAsignacion)
{
	int posicion = buscarEnTablaDeSimbolos(linea);
	if(posicion != ERROR && (strcmp(tablaDeSimbolos[posicion].valor, VACIO) != 0 || atoi((tablaDeSimbolos[posicion]).valor) != 0))
	{
		Informacion informacion;
		informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		strcpy(informacion.cadena, linea);
		informacion.tipoDeDato = tablaDeSimbolos[posicion].tipo;
		ponerEnPila(&pilaASM, &informacion);
		if(!pilaASM && (strcmp(informacion.tipoDeDato, TIPO_STRING) != 0 || strcmp(informacion.tipoDeDato, CONSTANTE_STR) == 0))
		{
			*huboAsignacion = FALSE;
		}
		strcpy(ultimoTipo, informacion.tipoDeDato);
	}
}

void manejarOperacionArimetica(const char* linea, FILE* pf, char* aux1, char* aux2, int* numeroAuxiliarEntero, int* numeroAuxiliarReal)
{
	char nombreOperando1[64], nombreOperando2[64];
	
	if(strcmp(linea, MULTIPLICACION) == 0)
	{
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		Informacion informacion;
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if(SON_AMBOS_ENTEROS(operando1->tipoDeDato, operando2->cadena))
		{
			fprintf(pf, ";MULTIPLICACION DE ENTEROS\n");
			fprintf(pf, "\tFILD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFILD\t%s\n", nombreOperando2);
			fprintf(pf, "\tFMUL\n");
			strcpy(aux1, "auxE");
			itoa(*numeroAuxiliarEntero, aux2, 10);
			strcat(aux1, aux2);
			fprintf(pf, "\tFISTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_INT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarEntero)++;
		}
		else
		{
			fprintf(pf,";MULTIPLICACION DE REALES\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando2->tipoDeDato) ? "FILD" : "FLD", nombreOperando2);
			fprintf(pf, "\tFMUL\n");
			strcpy(aux1, "auxR");
			itoa(*numeroAuxiliarReal, aux2, 10);
			strcat(aux1, aux2);
			fprintf(pf, "\tFSTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_FLOAT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarReal)++;
		}
	}

	if (strcmp(linea, SUMA) == 0 )
	{
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		Informacion informacion;
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if(SON_AMBOS_ENTEROS(operando1->tipoDeDato, operando2->tipoDeDato))
		{
			fprintf(pf, ";SUMA DE ENTEROS\n");
			fprintf(pf, "\tFILD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFILD\t%s\n", nombreOperando2);
			fprintf(pf, "\tFADD\n");
			strcpy(aux1, "auxE");
			itoa(*numeroAuxiliarEntero, aux2, 10);
			strcat(aux1, aux2);
			fprintf(pf,"\tFISTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_INT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarEntero)++;
		}
    	else
		{
			fprintf(pf, ";SUMA DE REALES\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando2->tipoDeDato) ? "FILD" : "FLD", nombreOperando2);
			fprintf(pf, "\tFADD\n");
			strcpy(aux1, "auxR");
			itoa(*numeroAuxiliarReal, aux2, 10);
			strcat(aux1, aux2);
			fprintf(pf, "\tFSTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_FLOAT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarReal)++;
		}
	}

	if(strcmp(linea, DIVISION) == 0 )
	{
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		Informacion informacion;
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if(SON_AMBOS_ENTEROS(operando1->tipoDeDato, operando2->tipoDeDato))
		{
			fprintf(pf,";DIVISION DE ENTEROS\n");
			fprintf(pf, "\tFILD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFILD\t%s\n", nombreOperando2);
		}
		else
		{
			fprintf(pf,";DIVISION DE REALES\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando2->tipoDeDato) ? "FILD" : "FLD", nombreOperando2);
		}
		fprintf(pf,"\tFDIVR\n");
		strcpy(aux1,"auxR");
		itoa(*numeroAuxiliarReal, aux2, 10);
		strcat(aux1, aux2);
		fprintf(pf,"\tFSTP\t%s\n", aux1);
		informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
		strcpy(informacion.tipoDeDato, TIPO_FLOAT);
		strcpy(informacion.cadena, aux1);
		ponerEnPila(&pilaASM, &informacion);
		(*numeroAuxiliarReal)++;	
	}

	if(strcmp(linea, RESTA) == 0)
	{
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		Informacion informacion;
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if(SON_AMBOS_ENTEROS(operando1->tipoDeDato, operando2->tipoDeDato))
		{
			fprintf(pf, ";RESTA DE ENTEROS\n");
			fprintf(pf, "\tFILD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFILD\t%s\n", nombreOperando2);
			fprintf(pf, "\tFSUBR\n"); 
			strcpy(aux1, "auxE");
			itoa(*numeroAuxiliarEntero, aux2, 10);
			strcat(aux1,aux2);
			fprintf(pf,"\tFISTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_INT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarEntero)++;
		}
		else
		{
			fprintf(pf, ";RESTA DE REALES\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando2->tipoDeDato) ? "FILD" : "FLD", nombreOperando2);
			fprintf(pf, "\tFSUBR\n");
			strcpy(aux1, "auxR");
			itoa(*numeroAuxiliarReal, aux2, 10);
			strcat(aux1, aux2);
			fprintf(pf, "\tFSTP\t%s\n", aux1);
			informacion.tipoDeDato = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			informacion.cadena = (char*)malloc(sizeof(char)*CADENA_MAXIMA);
			strcpy(informacion.tipoDeDato, TIPO_FLOAT);
			strcpy(informacion.cadena, aux1);
			ponerEnPila(&pilaASM, &informacion);
			(*numeroAuxiliarReal)++;
		}
	}
}

void manejarComparador(const char* operacion, FILE* pf, int* huboSalto)
{
	if(strcmp(operacion, CMP) == 0)
	{
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		char nombreOperando1[64], nombreOperando2[64];
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if(strcmp(operando1->tipoDeDato, TIPO_FLOAT) == 0 || strcmp(operando1->tipoDeDato, CONSTANTE_FLOAT) == 0)
		{
			fprintf(pf, "\tFLD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFLD\t%s\n", nombreOperando2);
		}
		else
		{	
			fprintf(pf, "\tFILD\t%s\n", nombreOperando1);
			fprintf(pf, "\tFILD\t%s\n", nombreOperando2);
		}
	}

	if(*huboSalto == TRUE)
	{
		fprintf(pf, "\tET_%s\n", operacion);
		*huboSalto = FALSE;
	}

	//>
	if(strcmp(operacion, BLE) == 0)
	{	
		fprintf(pf, "\tFCOMP\n\tFSTSW\tAX\n\tFWAIT\n\tSAHF\n\tJBE");
		*huboSalto = TRUE;
	}

	//<
	if(strcmp(operacion, BGE) == 0)
	{
		fprintf(pf, "\tFCOMP\n\tFSTSW\tAX\n\tFWAIT\n\tSAHF\n\tJAE");
		*huboSalto = TRUE;
	}

	//!=
	if(strcmp(operacion, BEQ) == 0)
	{
		fprintf(pf, "\tFCOMP\n\tFSTSW\tAX\n\tFWAIT\n\tSAHF\n\tJE");
		*huboSalto = TRUE;
	}

	//==
	if(strcmp(operacion, BNE) == 0)
	{
		fprintf(pf, "\tFCOMP\n\tFSTSW\tAX\n\tFWAIT\n\tSAHF\n\tJNE");
		*huboSalto=TRUE;
	}

	//>=
	if(strcmp(operacion, BLT) == 0)
	{
		fprintf(pf, "\tFCOMP\n\tFSTSW\tAX\n\tFWAIT\n\tSAHF\n\tJB");
		*huboSalto = TRUE;
	}

	//<=
	if(strcmp(operacion, BGT) == 0)
	{
		fprintf(pf, "\tFCOMP\n");
		fprintf(pf, "\tFSTSW\tAX\n");
		fprintf(pf, "\tFWAIT\n");
		fprintf(pf, "\tSAHF\n");
		fprintf(pf, "\tJA");
		*huboSalto = TRUE;
	}	

	if(strcmp(operacion, BI) == 0)
	{
		fprintf(pf, "\tJMP");
		*huboSalto = TRUE;
	}
}

void manejarEtiqueta(char* linea, FILE* pf)
{
	if(strchr(linea, '#') != 0)
	{
		fprintf(pf, "ET_%s:\n", reemplazarCaracter(linea, "#", VACIO));
	}
}

void manejarAsignacion(const char* operacion, FILE* pf, int* huboAsignacion, int* etiquetaString)
{
	if(strcmp(operacion, ASIGNACION) == 0)
	{	
		char nombreOperando1[64], nombreOperando2[64];
		Informacion* operando1 = sacarDePila(&pilaASM);
		Informacion* operando2 = sacarDePila(&pilaASM);
		obtenerNombreAssembler(operando1->cadena, operando1->tipoDeDato, nombreOperando1);
		obtenerNombreAssembler(operando2->cadena, operando2->tipoDeDato, nombreOperando2);
		if (ES_STRING(operando2->tipoDeDato))
		{
			fprintf(pf, ";ASIGNACION CADENA\n");
			fprintf(pf, "\tMOV AX, @DATA\n");
			fprintf(pf, "\tMOV DS, AX\n");
			fprintf(pf, "\tMOV ES, AX\n");
			fprintf(pf, "\tMOV SI, OFFSET\t%s\n", nombreOperando1);
			fprintf(pf, "\tMOV DI, OFFSET\t%s\n", nombreOperando2);
			fprintf(pf, "\tCLD\n");
			fprintf(pf, "COPIA_CADENA_%d:\n", (*etiquetaString)++);
			fprintf(pf, "\tLODSB\n");
			fprintf(pf, "\tSTOSB\n");
			fprintf(pf, "\tCMP AL,'$'\n");
			fprintf(pf, "\tJNE COPIA_CADENA_%d\n", (*etiquetaString) - 1);
		}
		else if (ES_ENTERO(operando2->tipoDeDato))
		{
			fprintf(pf, ";ASIGNACION ENTERA\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf,"\tFISTP\t%s\n", nombreOperando2);
			*huboAsignacion = TRUE;
		}
		else if (ES_FLOAT(operando2->tipoDeDato))
		{
			fprintf(pf,";ASIGNACION FLOAT\n");
			fprintf(pf, "\t%s\t%s\n", ES_ENTERO(operando1->tipoDeDato) ? "FILD" : "FLD", nombreOperando1);
			fprintf(pf,"\tFSTP\t%s\n", nombreOperando2);
			*huboAsignacion = TRUE;
		}
	}
}

void manejarComandoWrite(char* linea, FILE* pf, const char* ultimoTipo)
{
	if(strcmp(linea, "WRITE") == 0)
	{
		fprintf(pf, ";SALIDA POR CONSOLA\n");
		Informacion* info = sacarDePila(&pilaASM);
		char operando[64];
		obtenerNombreAssembler(info->cadena, info->tipoDeDato, operando);
		if (strcmp(ultimoTipo, TIPO_INT) == 0 || strcmp(ultimoTipo, CONSTANTE_INT) == 0)
		{
			fprintf(pf, "\tDisplayInteger\t%s,3\n\tNewLine 1\n", operando);	
		}
		else if (strcmp(ultimoTipo, TIPO_FLOAT) == 0 || strcmp(ultimoTipo, CONSTANTE_FLOAT) == 0)
		{
			fprintf(pf, "\tDisplayFloat\t%s,3\n\tNewLine 1\n", operando);	
		}
		else if (strcmp(ultimoTipo, TIPO_STRING) == 0 || strcmp(ultimoTipo, CONSTANTE_STR) == 0)
		{
			fprintf(pf, "\tDisplayString\t%s\n\tNewLine 1\n", operando);
		}
	}
}

void manejarComandoRead(char* linea, FILE* pf, const char* ultimoTipo)
{
	if(strcmp(linea, "READ") == 0)
	{
		fprintf(pf, ";ENTRADA POR CONSOLA\n");
		Informacion* info = sacarDePila(&pilaASM);
		char operando[64];
		obtenerNombreAssembler(info->cadena, info->tipoDeDato, operando);
		if(strcmp(ultimoTipo, TIPO_STRING) == 0 || strcmp(ultimoTipo, CONSTANTE_STR) == 0)
		{
			fprintf(pf, "\tGetString\t%s\n", operando);
		}
		else if(strcmp(ultimoTipo, TIPO_INT) == 0 || strcmp(ultimoTipo, CONSTANTE_INT) == 0)
		{
			fprintf(pf, "\tGetInteger\t%s\n", operando);
		}
		else if(strcmp(ultimoTipo, TIPO_FLOAT) == 0 || strcmp(ultimoTipo, CONSTANTE_FLOAT) == 0)
		{
			fprintf(pf, "\tGetFloat\t%s\n", operando);
		}
	}
}

void finalizarEjecucionCodigoAssembler(FILE* pf)
{
	fprintf(pf, "\nMOV\tAX, 4C00H");
	fprintf(pf, "\nINT\t21H");
	fprintf(pf, "\nEND");
}

void generarAssembler(Polaca* pp)
{
	NodoPolaca* auxPolaca;
	auxPolaca = *pp;
	
	int numeroAuxiliarReal = 0;
	int numeroAuxiliarEntero = 0;
	int etiquetaString = 0;

	char aux1[CADENA_MAXIMA] = "aux\0";
	char aux2[CADENA_MAXIMA];

	char ultimoTipo[CADENA_MAXIMA] = "none";
	char ultimaCadena[CADENA_MAXIMA];
	
	int huboAsignacion = TRUE;
	int huboSalto = FALSE;
	
	FILE* pf = fopen(NOMBRE_ARCHIVO_ASSEMBLER, "w");
	if (pf == NULL)
	{
		printf("Error al abrir el archivo %s\n", NOMBRE_ARCHIVO_ASSEMBLER);
		exit(1);
	}

	generarCabeceraAssembler(pf);
	declararVariablesEnAssembler(pf);
	generarComienzoDePrograma(pf);
	while(*pp)
    {
		NodoPolaca* auxPolaca = *pp;
		char linea[CADENA_MAXIMA];
		strcpy(linea, auxPolaca->info.cadena);
		manejarVariables(linea, ultimoTipo, &huboAsignacion);
		manejarConstantes(linea, ultimoTipo, &huboAsignacion);
		manejarOperacionArimetica(linea, pf, aux1, aux2, &numeroAuxiliarEntero, &numeroAuxiliarReal);
		manejarComparador(linea, pf, &huboSalto);
		manejarEtiqueta(linea, pf);
		manejarAsignacion(linea, pf, &huboAsignacion, &etiquetaString);
		manejarComandoWrite(linea, pf, ultimoTipo);
		manejarComandoRead(linea, pf, ultimoTipo);
		*pp = (*pp)->psig;
	}
	finalizarEjecucionCodigoAssembler(pf);
	fclose(pf);
}

/******************* Main *******************/

int main(int argc, char *argv[])
{
	crearPila(&pilaIf);
	crearPolaca(&polaca);
	crearPolaca(&polacaASM);
	crearPila(&pilaASM);
	if ((yyin = fopen(argv[1], "rt")) == NULL)
	{
		printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
	}
	else
	{ 
		yyparse();
	}
	crearTablaDeSimbolos();
	fclose(yyin);
	guardarPolaca(&polaca, &polacaASM);
	printf("\nPOLACA GENERADA\n");	
	generarAssembler(&polacaASM);
	printf("\nASSEMBLER GENERADO\n");
  	return 0;
}
