# Plantilla para TP Integrador usando Flex y Bison (C)

## Prerequisitos. 

Para poder usar esta plantilla deberá:

1. Instalar [flex](https://github.com/westes/flex)

2. Instalar [bison](https://www.gnu.org/software/bison/)

3. Instalar [gcc](https://gcc.gnu.org/)


### Windows

Descargue los instaladores para Windows de las siguientes páginas:

1. [Flex](http://gnuwin32.sourceforge.net/packages/flex.htm)
2. [Bison](http://gnuwin32.sourceforge.net/packages/bison.htm)
3. [GCC](https://sourceforge.net/projects/mingw/files/)
4. Siga el siguiente [instructivo](https://issuu.com/lilianachisaguano/docs/instalacion_de_flex__bison_y_mingw)

* Tanto para los binarios instalados flex y bison, es recomendable instalarlos en C:\GnuWin32 y luego agregar "C:\GnuWin32\bin" en variables de entorno -> variables del sistema -> editar variable path y agregar a la lista.
* Lo mismo para gcc, agregar el path donde sea instalado (ej: C:\MinGW\bin) a las variables del sistema en la variable path.

### Ubuntu

1. Abra una terminal
2. Ejecute los siguientes comandos:

```sudo apt-get update
sudo apt-get upgrade
sudo apt-get install flex
sudo apt-get install bison
sudo apt install gcc
```

3. Verifique la instalación ha sido exitosa ejecutándo los siguientes comandos

```
which flex
which bison
which gcc
```

### Mac

1. Abra una terminal
2. Ejecute los siguientes comandos:

```sudo apt-get update
brew install flex
brew install bison
brew install gcc
```
3. Verifique la instalación ha sido exitosa ejecutándo los siguientes comandos

```
which flex
which bison
which gcc
```

## Ejecución  

### Windows

Ejecutar el archivo run.bat

### Linux / Unix

Ejecutar el archivo run.sh
