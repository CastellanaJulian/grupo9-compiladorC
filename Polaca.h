#ifndef POLACA_H
#define POLACA_H

#define ERROR -1
#define OK 3
#define CADENA_MAXIMA 320

#define CMP "CMP"
#define BEQ "BEQ"
#define BNE "BNE"
#define BGT "BGT"
#define BGE "BGE"
#define BLT "BLT"
#define BLE "BLE"
#define BI "BI"
#define ET "ET"

extern int contadorPolaca;
extern char ultimoComparador[3];

enum EnumTipoSalto
{
	normal,
	inverso
};

typedef struct
{
	char cadena[CADENA_MAXIMA];
	int nro;
} InformacionPolaca;

typedef struct SNodoPolaca
{
	InformacionPolaca info;
	struct SNodoPolaca* psig;
} NodoPolaca;

typedef NodoPolaca* Polaca;

void guardarPolaca(Polaca*, Polaca*);

int ponerEnPolacaNro(Polaca*, int, char *);

int ponerEnPolaca(Polaca*, char *);

void crearPolaca(Polaca*);

char* obtenerSalto(enum EnumTipoSalto);

#endif
