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

Se hicieron simulaciones en GTKwave en principio, de los módulos por separado, comprobando así el correcto funcionamiento de la suma de 4bits, la resta, multiplicaciín, XOR y corrimiento. Esto funcionó adecuadamente, no obstante, hubo inconvenientes a la hora de implementar un testbench general.

## Implementación
Las siguientes imágenes muestran el montaje utilizado para la **implementación de la ALU**.  
Se emplearon **switches externos** para las entradas `A[3:0]` y `B[3:0]`, los **switches de la tarjeta** para seleccionar el **opcode** (`op[2:0]`), y **10 LEDs** para las salidas: **8** asignados a la salida `Y[7:0]` y **2** a las banderas `zero` y `overflow`.  
Para garantizar niveles lógicos definidos, se usaron **resistencias pull-down** tanto en las **entradas** como en las **salidas**.

Para la implementación física del diseño y la verificación de su funcionamiento se empleó la FPGA Zybo Z7 como unidad de procesamiento principal. La carga del código se realiza a través del software Vivado de Xilinx. El procedimiento comienza con la creación de un nuevo proyecto, en el cual se añade el archivo del diseño como Design Source y, en caso de querer realizar simulaciones, el testbench como Simulation Source. Cabe aclarar que también se hizo simulación con el programa GTKWave.

Posteriormente, se lleva a cabo el flujo típico de diseño: análisis RTL, síntesis, implementación, generación del bitstream y, finalmente, la programación de la FPGA. Para garantizar el correcto funcionamiento del sistema, es necesario definir la asignación de pines utilizando el archivo Master.xdc (disponible en la carpeta de fuentes del repositorio en GitHub). Con base en dicha asignación, se conectan adecuadamente los elementos del circuito a sus correspondientes pines físicos.

La selección de pines se realizó tomando como referencia el manual de usuario oficial de la Zybo Z7, disponible en la página de Digilent. Con ayuda del diagrama ilustrativo y la tabla de pines, se definieron las conexiones de alimentación, tierra, señales de entrada y salida hacia la protoboard. En particular, se emplearon todos los pines disponibles(menos los de alimentación y GND) del conector Pmod JC para las señales de entrada (A y B), mientras que los mismos pines del conector Pmod JA se destinaron para los 8 bits de la señal de salida. los LEDs M14 y M15 fueron asignados a las señales de busy y done, lo que permitió monitorear en tiempo real el estado del proceso durante la ejecución. También se usaron los pines T15 y P14 para el overflow y el cero respectivamente. Y finalmente, los switches utilizados de la fpga para referirse a la operación fueron P15, W13 y T16.

![Montaje de la ALU](<implementacion1.jpg>)
![alt text](<implementacion2.jpg>)
A continuación se anexa link de una carpeta drive, la cuál contiene un video que evidencia el correcto funcionamiento de la ALU.
[Implementación](https://drive.google.com/drive/folders/109AuJ9VsYDqh0NAeJVt85cxnVNlal5TP?usp=sharing)

## Conclusiones


La implementación de la Unidad Aritmético-Lógica permitió comprender de manera práctica cómo se integran los diferentes bloques funcionales de un sistema digital —como sumadores, restadores, multiplicadores y operadores lógicos— dentro de una arquitectura estructural jerárquica. La correcta interacción entre módulos demuestra la solidez del diseño modular y la importancia de definir interfaces bien estructuradas en Verilog.

Diseño estructural y jerárquico:
El enfoque empleado, basado en la construcción de submódulos independientes y su posterior integración mediante un multiplexor controlado por el opcode, facilitó la depuración y verificación del sistema. Este método promueve la reutilización de código y la escalabilidad del diseño, cualidades esenciales en proyectos de hardware digital más complejos.

Simulación y validación funcional:
Las simulaciones realizadas en GTKWave confirmaron el funcionamiento correcto de las operaciones definidas (suma, resta, corrimiento, XOR y multiplicación). Estas pruebas fueron fundamentales para detectar y corregir errores antes de la implementación física, reafirmando la relevancia del proceso de verificación previa en el flujo de diseño digital.

Implementación en FPGA:
La programación de la ALU en la FPGA Zybo Z7 demostró la transición efectiva del diseño desde el entorno de simulación hasta el hardware real. La asignación de pines, la configuración de entradas y salidas mediante resistencias pull-down, y el uso de Vivado para síntesis e implementación, evidenciaron el dominio de un flujo de trabajo completo en diseño digital asistido por herramientas de desarrollo profesional.



## Referencias
[1] H. S. L. y S. (. Service), Eds., Digital Design and Computer Architecture, 2a ed. San Francisco, CA: Morgan Kaufmann, 2013.

[2] D. D. Gajski, Principles of Digital Design. Upper Saddle River, NJ: Prentice Hall, 1997.

[3] “Zybo Z7 Reference Manual,” Digilent, [Online]. Available: https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
[Accessed: Oct. 15, 2025].

[4] J. H. Ramírez, “Lab_electronica_digital_2,” GitHub repository, [Online]. Available: https://github.com/jharamirezma/Lab_electronica_digital_2
[Accessed: Oct. 15, 2025].

[5] Jharamirezma, “Lab_electronica_digital_2/labs/lab02/README.md at main · jharamirezma/Lab_electronica_digital_2,” GitHub. https://github.com/jharamirezma/Lab_electronica_digital_2/blob/main/labs/lab02/README.md#3-procedimiento
[Accessed: Oct. 15, 2025].

[6] “Vivado Design Suite User and Reference Guides,” AMD (Xilinx), [Online]. Available: https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Vivado-Design-Suite-User-and-Reference-Guides
[Accessed: Oct. 15, 2025].

[7] Lista de reproducción video implementación - (https://www.youtube.com/playlist?list=PL01D33s9LDzaNn2FQfO3uFua1hIZ8JVF4)