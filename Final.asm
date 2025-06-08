
INCLUDE asm\macros2.asm		;Biblioteca
INCLUDE asm\number.asm		;Biblioteca

INCLUDE macros2.asm		;Biblioteca
INCLUDE number.asm		;Biblioteca

.MODEL LARGE		;Modelo de memoria
.386		;Tipo de procesador
.STACK 200h		;Bytes en el stack
	
.DATA		;Inicializa el segmento de datos
	TRUE equ 1
	FALSE equ 0
	MAXTEXTSIZE equ 32
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
	mov AX,@DATA
	mov DS,AX
;ASIGNACION ENTERA
	fild 	_3
	fstp 	_b
;ASIGNACION ENTERA
	fild 	_b
	fstp 	_a

mov ax, 4C00h
int 21h
end