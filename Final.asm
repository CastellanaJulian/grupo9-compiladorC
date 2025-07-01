INCLUDE macros2.asm
INCLUDE number.asm

.MODEL LARGE
.386
.STACK 200h

TRUE		EQU		1
FALSE		EQU		0
MAXTEXTSIZE	EQU		320

.DATA
	a		dd		?
	b		dd		?
	c		dd		?
	d		dd		?
	e		db		MAXTEXTSIZE dup (?), '$'
	h		db		MAXTEXTSIZE dup (?), '$'
	f		dd		?
	g		dd		?
	_T_Slice_and_Concat		db		"Slice and Concat", '$', 302 dup (?)
	_2		dd		2
	_4		dd		4
	_T_leandro		db		"leandro", '$', 311 dup (?)
	_T_verde		db		"verde", '$', 313 dup (?)
	_T_verdeand		db		"verdeand", '$', 310 dup (?)
	_T_Sum_First_Primes		db		"Sum First Primes", '$', 302 dup (?)
	_5		dd		5
	_28		dd		28
	_T_Sentencias_de_Control_anidadas		db		"Sentencias de Control anidadas", '$', 288 dup (?)
	_T_Resultado_inicial_de_B		db		"Resultado inicial de B", '$', 296 dup (?)
	_6		dd		6
	_3		dd		3
	_1		dd		1
	_T_Dentro_del_if_b_vale		db		"Dentro del if b vale", '$', 298 dup (?)
	_NEG_525		dd		-525
	_T_Resultado_final_de_B		db		"Resultado final de B", '$', 298 dup (?)
	_5_75		dd		5.75
	_3_25		dd		3.25
	auxR0	DD	0.0
	auxR1	DD	0.0
	auxR2	DD	0.0
	auxE0	DW	0
	auxE1	DW	0
	auxE2	DW	0

.CODE
.startup
	MOV AX,@DATA
	MOV DS,AX
;SALIDA POR CONSOLA
	DisplayString	_T_Slice_and_Concat
	NewLine 1
;ASIGNACION CADENA
	MOV AX, @DATA
	MOV DS, AX
	MOV ES, AX
	MOV SI, OFFSET	_T_verdeand
	MOV DI, OFFSET	e
	CLD
COPIA_CADENA_0:
	LODSB
	STOSB
	CMP AL,'$'
	JNE COPIA_CADENA_0
;SALIDA POR CONSOLA
	DisplayString	e
	NewLine 1
;SALIDA POR CONSOLA
	DisplayString	_T_Sum_First_Primes
	NewLine 1
;ASIGNACION ENTERA
	FILD	_28
	FISTP	a
;SALIDA POR CONSOLA
	DisplayInteger	a,3
	NewLine 1
;SALIDA POR CONSOLA
	DisplayString	_T_Sentencias_de_Control_anidadas
	NewLine 1
;ASIGNACION ENTERA
	FILD	_5
	FISTP	b
;SALIDA POR CONSOLA
	DisplayString	_T_Resultado_inicial_de_B
	NewLine 1
;SALIDA POR CONSOLA
	DisplayInteger	b,3
	NewLine 1
	FILD	_5
	FILD	a
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JE	ET_33
	FILD	_6
	FILD	a
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JNE	ET_39
ET_33:
;ASIGNACION ENTERA
	FILD	_4
	FISTP	a
	JMP	ET_43
ET_39:
;ASIGNACION ENTERA
	FILD	_3
	FISTP	a
ET_43:
ET_44:
	FILD	_1
	FILD	a
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JBE	ET_86
ET_50:
	FILD	_1
	FILD	b
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JBE	ET_78
;RESTA DE ENTEROS
	FILD	_1
	FILD	b
	FSUBR
	FISTP	auxE0
;ASIGNACION ENTERA
	FILD	auxE0
	FISTP	b
;SALIDA POR CONSOLA
	DisplayInteger	b,3
	NewLine 1
	FILD	_2
	FILD	b
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JNE	ET_75
;SALIDA POR CONSOLA
	DisplayString	_T_Dentro_del_if_b_vale
	NewLine 1
;SALIDA POR CONSOLA
	DisplayInteger	b,3
	NewLine 1
;ASIGNACION ENTERA
	FILD	_NEG_525
	FISTP	b
ET_75:
	JMP	ET_50
ET_78:
;RESTA DE ENTEROS
	FILD	_1
	FILD	a
	FSUBR
	FISTP	auxE1
;ASIGNACION ENTERA
	FILD	auxE1
	FISTP	a
	JMP	ET_44
ET_86:
;SALIDA POR CONSOLA
	DisplayString	_T_Resultado_final_de_B
	NewLine 1
;SALIDA POR CONSOLA
	DisplayInteger	b,3
	NewLine 1
;RESTA DE REALES
	FLD	_3_25
	FLD	_5_75
	FSUBR
	FSTP	auxR0
;ASIGNACION FLOAT
	FLD	auxR0
	FSTP	f
;SALIDA POR CONSOLA
	DisplayFloat	f,3
	NewLine 1

MOV	AX, 4C00H
INT	21H
END