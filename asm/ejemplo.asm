INCLUDE macros2.asm
INCLUDE number.asm

.MODEL LARGE
.386
.STACK 200h

TRUE		EQU		1
FALSE		EQU		0
MAXTEXTSIZE	EQU		32

.DATA
	a		dd		?
	b		dd		?
	c		dd		?
	d		dd		?
	e		db		MAXTEXTSIZE dup (?), '$'
	h		db		MAXTEXTSIZE dup (?), '$'
	f		dd		?
	g		dd		?
	_10		dd		10
	_T_FIN_PROGRAMA		db		"FIN PROGRAMA", '$', 18 dup (?)
	_1		dd		1
	auxR0	DD	0.0
	auxE0	DW	0

.CODE
.startup
	MOV AX,@DATA
	MOV DS,AX
;ASIGNACION ENTERA
	FILD	_10
	FISTP	a
;ASIGNACION CADENA
	MOV AX, @DATA
	MOV DS, AX
	MOV ES, AX
	MOV SI, OFFSET	_T_FIN_PROGRAMA
	MOV DI, OFFSET	e
	CLD
COPIA_CADENA_0:
	LODSB
	STOSB
	CMP AL,'$'
	JNE COPIA_CADENA_0
ET_6:
	FILD	_1
	FILD	a
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JE	ET_21
;RESTA DE ENTEROS
	FILD	_1
	FILD	a
	FSUBR
	FISTP	auxE0
;ASIGNACION ENTERA
	FILD	auxE0
	FISTP	a
;SALIDA POR CONSOLA
	DisplayInteger	a,3
	NewLine 1
	JMP	ET_6
ET_21:
;SALIDA POR CONSOLA
	DisplayString	e
	NewLine 1

MOV	AX, 4C00H
INT	21H
END