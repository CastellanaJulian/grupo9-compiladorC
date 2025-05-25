#ifndef PILA_H
#define PILA_H

enum and_or {
    and,
    or,
    condicionSimple
};

enum tipoDato {
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
} Informacion;

typedef struct SNodoPila
{
	Informacion info;
	struct SNodoPila* psig;
} NodoPila;

typedef NodoPila *Pila;

void vaciarPila(Pila*);

Informacion* sacarDePila(Pila*);

void crearPila(Pila*);

int ponerEnPila(Pila*, Informacion*);

Informacion* topeDePila(Pila*);

Informacion* topeDePila(Pila*);

Informacion* sacarDePila(Pila*);

#endif
