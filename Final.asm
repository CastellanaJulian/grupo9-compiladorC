
INCLUDE macros2.asm		;Biblioteca
INCLUDE number.asm		;Biblioteca

.MODEL LARGE		;Modelo de memoria
.386		;Tipo de procesador
.STACK 200h		;Bytes en el stack
	
.DATA		;Inicializa el segmento de datos
	TRUE EQU 1
	FALSE EQU 0
	MAXTEXTSIZE EQU 32
	_a dd ?
	_b dd ?
	_c dd ?
	_d dd ?
	_e db MAXTEXTSIZE dup(?), '$'
	_h db MAXTEXTSIZE dup(?), '$'
	_f dd ?
	_g dd ?

.CODE
.startup
	MOV AX,@DATA
	MOV DS,AX
;ASIGNACION ENTERA
	FILD 	_10
	FSTP 	_b
;SUMA DE ENTEROS
	FILD	_6
	FIADD	_b
	FISTP	_auxE0
;ASIGNACION ENTERA
	FILD 	_auxE0
	FSTP 	_a
;MULTIPLICACION DE ENTEROS
	FILD	_25
	FIMUL	_14
	FISTP	_auxE1
;ASIGNACION ENTERA
	FILD 	_auxE1
	FSTP 	_a
;ENTRADA POR CONSOLA
	obtenerEntero 	_a
;SALIDA POR CONSOLA
	mostrarEntero 	_b,3
	nuevaLinea 1
	FILD	_10
	FILD	_b
	FCOMP
	FSTSW	AX
	FWAIT
	SAHF
	JBE	ET_25
;ASIGNACION ENTERA
	FILD 	_5
	FSTP 	_a

MOV	X, 4C00H
INT	21H
END