[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/sEFmt2_p)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=20979145&assignment_repo_type=AssignmentRepo)
# Lab02 - Unidad Aritmético-Lógica.

# Integrantes

* [David Enrique Barón Rubio](https://github.com/Dai-En)
* [Daniel Andrés Ramirez Morales](https://github.com/daramirezmor)
* [Indaliria Valentina Cardona Corredor](https://github.com/valentinacardona07)

# Informe

Indice:

- [Lab02 - Unidad Aritmético-Lógica.](#lab02---unidad-aritmético-lógica)
- [Integrantes](#integrantes)
- [Informe](#informe)
  - [Diseño implementado](#diseño-implementado)
    - [Descripción](#descripción)
    - [Estructura general del sistema](#estructura-general-del-sistema)
    - [Señales principales del diseño](#señales-principales-del-diseño)
    - [Operaciones implementadas](#operaciones-implementadas)
    - [Descripción de los modulos](#descripción-de-los-modulos)
  - [Simulaciones](#simulaciones)
  - [Implementación](#implementación)
  - [Conclusiones](#conclusiones)
  - [Referencias](#referencias)

## Diseño implementado
![alt text](image-1.png)
### Descripción
La Unidad Lógica y Aritmética (ALU) diseñada realiza operaciones entre dos operandos de 4 bits (A y B) mediante un código de control de tres bits (opcode). Todas las señales se manejan como **vectores sin signo**, lo que significa que los valores representados corresponden a enteros binarios positivos comprendidos entre 0 y 15.
En consecuencia, las operaciones de suma, resta, multiplicación, corrimiento y XOR se realizan considerando únicamente su magnitud binaria, sin interpretar ningún bit como signo.

#### ⚙️ Estructura general del sistema

El módulo principal (`ALU.v`) integra de manera **estructural** los distintos bloques funcionales desarrollados individualmente:

- `suma4bits.v` : operación de suma aritmética sin signo.  
- `Resta4bits.v` : resta sin signo implementada por complemento a dos.  
- `Multiplicador4bits.v` : multiplicación binaria entre operandos de 4 bits.  
- `ModuloXor.v` : operación lógica XOR bit a bit.  
- `Mover_Izquierda.v` : corrimiento lógico a la izquierda (máximo 3 posiciones).

Cada submódulo entrega su resultado parcial y una señal interna de `overflow` hacia la unidad superior, que selecciona el resultado final a través de un **multiplexor controlado por `opcode[2:0]`**.

#### 🧩 Señales principales del diseño

| Señal | Descripción | Tipo |
|-------|--------------|------|
| `A[3:0]`, `B[3:0]` | Operandos de entrada de 4 bits sin signo | Entrada |
| `opcode[2:0]` | Código que define la operación a realizar | Entrada |
| `Y[3:0]` | Resultado de la operación seleccionada | Salida |
| `overflow` | Bandera de desbordamiento | Salida |
| `zero` | Bandera de resultado nulo | Salida |

**Condiciones de las banderas:**
- `overflow` = 1 cuando se excede el rango de 4 bits (dependiendo de la operación).  
- `zero` = 1 si `Y == 4'b0000`.

#### 🧮 Operaciones implementadas

| Código `opcode` | Operación | Descripción | Expresión funcional |
|--------------|------------|-------------|----------------------|
| `000` | **Suma** | Suma binaria entre `A` y `B` | `result = A + B` |
| `001` | **Resta** | Diferencia `A - B` mediante complemento a dos | `result = A + (~B + 1)` |
| `010` | **Corrimiento Izquierda** | Desplaza `A` según `B[1:0]` (máx 3)|  `result = A << B[1:0]`|
| `011` | **XOR** | Operación lógica bit a bit | `result = A ^ B` |
| `100` | **Multiplicación** | Producto entre `A` y `B` (solo 4 LSB)  | `result = (A * B)[3:0]` |

#### 🧱 Descripción de los submódulos

##### 🔹 `suma4bits.v`
Implementa un sumador de 4 bits con acarreo.  
El resultado se obtiene concatenando el carry de salida y los bits de suma intermedios:
```verilog
assign {Cout, So} = A + B + Ci;
```
El bit Cout representa el overflow de la suma.

##### 🔹 `Resta4bits.v`
La resta se realiza aplicando complemento a dos sobre `B`:
```verilog
assign {Cout, Resta} = A + (~B + 1);
```
El overflow o borrow se produce cuando `A < B`.
El resultado se mantiene en aritmética sin signo, sin interpretación negativa.
##### 🔹 `Multiplicador4bits.v`
Genera un producto de 8 bits (`producto[7:0] = A * B`).
La ALU toma únicamente los cuatro bits menos significativos:
```verilog
assign result = producto[3:0];
assign overflow = |producto[7:4];
```
El `overflow` se activa si alguno de los bits altos es distinto de cero.
##### 🔹 `ModuloXor.v`
Realiza la operación lógica XOR bit a bit:
```verilog
assign result = A ^ B;
assign overflow = 1'b0;
```
No genera desbordamiento, ya que no se trata de una operación aritmética.
##### 🔹 `Mover_Izquierda.v`
Desplaza el valor de `A` hacia la izquierda según `B[1:0]`:
```verilog
assign result = A << B[1:0];
```
El overflow se activa cuando un bit ‘1’ es desplazado fuera del rango de 4 bits.
El desplazamiento máximo permitido es de 3 posiciones.


## Simulaciones 

## Implementación
Las siguientes imágenes muestran el montaje utilizado para la **implementación de la ALU**.  
Se emplearon **switches externos** para las entradas `A[3:0]` y `B[3:0]`, los **switches de la tarjeta** para seleccionar el **opcode** (`op[2:0]`), y **10 LEDs** para las salidas: **8** asignados a la salida `Y[7:0]` y **2** a las banderas `zero` y `overflow`.  
Para garantizar niveles lógicos definidos, se usaron **resistencias pull-down** tanto en las **entradas** como en las **salidas**.

![Montaje de la ALU](<implementacion1.jpg>)
![alt text](<implementacion2.jpg>)
A continuación se anexa link de una carpeta drive, la cuál contiene un video que evidencia el correcto funcionamiento de la ALU.
[Implementación](https://drive.google.com/drive/folders/109AuJ9VsYDqh0NAeJVt85cxnVNlal5TP?usp=sharing)

## Conclusiones

## Referencias
