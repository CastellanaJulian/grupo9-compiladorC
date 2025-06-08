#include "Polaca.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int contadorPolaca = 0;
char ultimoComparador[3];

void crearPolaca(Polaca* pp)
{
    *pp=NULL;
}

int ponerEnPolaca(Polaca* pp, char *cadena)
{
	printf("ponerEnPolaca: cadena %s\n",cadena);
    NodoPolaca* pn = (NodoPolaca*)malloc(sizeof(NodoPolaca));
    if(!pn)
    {
    	printf("ponerEnPolaca: Error al solicitar memoria\n");
        return ERROR;
    }
    NodoPolaca* aux;
    strcpy(pn->info.cadena,cadena);
    pn->info.nro = contadorPolaca++;
    pn->psig = NULL;
    if(!*pp)
    {
    	*pp = pn;
    	return OK;
    }
    else
    {
    	aux = *pp;
    	while(aux->psig)
        {
        	aux = aux->psig;
        }
        aux->psig = pn;
    	return OK;
    }
}

int ponerEnPolacaNro (Polaca* pp, int pos, char *cadena)
{
	NodoPolaca* aux;
	aux = *pp;
    while(aux != NULL && aux->info.nro<pos)
    {
    	aux = aux->psig;
    }
    if(aux->info.nro == pos)
    {
    	strcpy(aux->info.cadena, cadena);
    	return OK;
    }
    else
    {
    	printf("NO ENCONTRADO\n");
    	return ERROR;
    }
    return ERROR;
}

void guardarPolaca(Polaca* pp, Polaca* ppASM)
{
	FILE*pt=fopen("intermediate-code.txt","w+");
	NodoPolaca* pn;
	if(!pt)
	{
		printf("Error al crear el archivo intermedio.\n");
		return;
	}
	while(*pp)
    {	
        pn = *pp;
		ponerEnPolaca(ppASM, pn->info.cadena);
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
				return(BEQ);
			if(strcmp(ultimoComparador,">")==0)
				return(BGT);
			if(strcmp(ultimoComparador,"<")==0)
				return(BLT);
			if(strcmp(ultimoComparador,">=")==0)
				return(BGE);
			if(strcmp(ultimoComparador,"<=")==0)
				return(BLE);
			if(strcmp(ultimoComparador,"!=")==0)
				return(BNE);
			break;

		case inverso:
			if(strcmp(ultimoComparador,"==")==0)
				return(BNE);
			if(strcmp(ultimoComparador,">")==0)
				return(BLE);
			if(strcmp(ultimoComparador,"<")==0)
				return(BGE);
			if(strcmp(ultimoComparador,">=")==0)
				return(BLT);
			if(strcmp(ultimoComparador,"<=")==0)
				return(BGT);
			if(strcmp(ultimoComparador,"!=")==0)
				return(BEQ);
			break;
	}
}
