#include "Pila.h"
#include <stdlib.h>

void crearPila(Pila* pp)
{
    *pp = NULL;
}

int ponerEnPila(Pila* pp, Informacion* info)
{
    NodoPila* pn = (NodoPila*)malloc(sizeof(NodoPila));
    if(!pn)
	{
        return 0;
	}
    pn->info=*info;
    pn->psig=*pp;
    *pp=pn;
    return 1;
}

Informacion * sacarDePila(Pila* pp)
{
	Informacion* info = (Informacion *) malloc(sizeof(Informacion));
    if(!*pp){
    	return NULL;
    }
    *info=(*pp)->info;
    *pp=(*pp)->psig;
    return info;
}

void vaciarPila(Pila* pp)
{
    NodoPila* pn;
    while(*pp)
    {
        pn=*pp;
        *pp=(*pp)->psig;
        free(pn);
    }
}

Informacion* topeDePila(Pila* pila)
{
	return &((*pila)->info);
}
