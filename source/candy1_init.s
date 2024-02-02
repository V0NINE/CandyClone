@;=                                                          	     	=
@;=== candy1_init.s: rutinas para inicializar la matriz de juego	  ===
@;=                                                           	    	=
@;=== Programador tarea 1A: victor.fosch@estudiants.urv.cat				  ===
@;=== Programador tarea 1B: victor.fosch@estudiants.urv.cat				  ===
@;=                                                       	        	=



.include "../include/candy1_incl.i"



@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; matrices de recombinación: matrices de soporte para generar una nueva matriz
@;	de juego recombinando los elementos de la matriz original.
	mat_recomb1:	.space ROWS*COLUMNS
	mat_recomb2:	.space ROWS*COLUMNS



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1A;
@; inicializa_matriz(*matriz, num_mapa): rutina para inicializar la matriz de
@;	juego, primero cargando el mapa de configuración indicado por parámetro (a
@;	obtener de la variable global 'mapas'), y después cargando las posiciones
@;	libres (valor 0) o las posiciones de gelatina (valores 8 o 16) con valores
@;	aleatorios entre 1 y 6 (+8 o +16, para gelatinas)
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocará la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocará la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = número de mapa de configuración
	.global inicializa_matriz
inicializa_matriz:
		push {r0-r9, lr}			@;guardar registros utilizados
		
		mov r4, r0			@;R4=direcció base de la matriu
		ldr r5, =mapas		@;R5=direcció base primer mapa de configuració
		mov r3, #ROWS*COLUMNS	@;tamany del mapa
		mul r6, r1, r3		@;R6=direcció base del n mapa de configuració
		
		mov r1, #0			@;R1=índex de files
		mov r2, #0			@;R2=índex de columnes
		mov r7, #0			@;R7=#desplaçaments
		
	.LforFilesI:
		mov r2, #0
	.LforColumnesI:
		ldrb r8, [r5,r6]	@;R8=valor de la casella (R1,R2)
		and r9, r8, #0x07
		cmp r9, #0			@;si R9=0, R8=casella buida(en o sense gelatina)
		beq	.LselecObjecte
		strb r8, [r4,r7]	@;copiem objecte fixe a la matriu de joc
		b .LfiSelecObjecte
		
		.LselecObjecte:
			mov r0, #6			@;mod_random retornara un número entre 0 i 5
			bl mod_random
			add r0, #1			@;R0=rang entre 1 i 6
			add r0, r8 			@;R0=nou objecte + possible gelatina
			strb r0, [r4,r7]	@;copiem objecte a la matriu de joc
			
			mov r0, r4			
			mov r3, #3 			@;orientació nord
			bl cuenta_repeticiones
			cmp r0, #3			@;si R0=3, hi ha seqüènica vertical
			beq .LselecObjecte
			
			mov r0, r4
			mov r3, #2			@;orientació oest
			bl cuenta_repeticiones
			cmp r0, #3			@;si R0=3, hi ha seqüència horitzontal
			beq .LselecObjecte
		.LfiSelecObjecte:
		
		add r6, #1
		add r7, #1
		add r2, #1
		cmp r2, #COLUMNS
		blo .LforColumnesI
		
		add r1, #1
		cmp r1, #ROWS
		blo .LforFilesI
		
		pop {r0-r9, pc}			@;recuperar registros y volver



@;TAREA 1B;
@; recombina_elementos(*matriz): rutina para generar una nueva matriz de juego
@;	mediante la reubicación de los elementos de la matriz original, para crear
@;	nuevas jugadas.
@;	Inicialmente se copiará la matriz original en 'mat_recomb1', para luego ir
@;	escogiendo elementos de forma aleatoria y colocandolos en 'mat_recomb2',
@;	conservando las marcas de gelatina.
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocará la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocará la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;		* para determinar si existen combinaciones en la nueva matriz, se
@;			invocará la rutina 'hay_combinacion' (ver fichero "candy1_comb.s")
@;		* se supondrá que siempre existirá una recombinación sin secuencias y
@;			con combinaciones
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
	.global recombina_elementos
recombina_elementos:
	push {r0-r12,lr}
		
		mov r4, r0			@;R4=direcció base de la matriu
		ldr r5, =mat_recomb1	
		ldr r6, =mat_recomb2
		
	@;Primera part. Inicialitza mat_recomb1 i mat_recomb2
	.LprimeraPart:
		mov r1, #0			@;R1=índex de files
		mov r2, #0			@;R2=índex de columnes
		mov r7, #0			@;R7=#desplaçaments
		mov r8, #ROWS*COLUMNS	@;FILES * COLUMNES
		
	.Lfor1a:
		ldrb r9, [r4,r7]	@;R9=element de la casella (R1,R2)
		
		and r10, r9, #0x07	@;R10=tres bits baixos del element (s'utilitza a LelementSimple)
		cmp r10, #0
		beq .LelementFixe
		cmp r10, #7
		beq .LelementFixe
		mov r9, r9, lsr #3	
		mov r9, r9, lsl #3	@;Eliminem l'element i ens quedem amb la gelatina
		strb r9, [r6,r7]	@;Guardem el codi de gelatina a mat_recomb2
		b .LelementSimple
		
		.LelementFixe:
			strb r9, [r6,r7]	@;Guardem l'element fixe a mat_recomb2
			b .Lfi1a
			
		.LelementSimple:
			strb r10, [r5,r7]		@;Guardem l'element a mat_recomb1
	.Lfi1a:
		add r7, #1
		cmp r7, r8
		blo .Lfor1a
		
	@;Segona part. Reordena la matriu
		mov r7, #0
		
	.LforFiles2a:
		mov r2, #0
	.LforColumnes2a:
		ldrb r9, [r4,r7]		@;R9=element de la casella (R1,R2) de la matriu de joc
		
		and r10, r9, #0x07
		cmp r10, #0		@;si l'element es 0, 8 o 16 (buit)
		beq .Lfi2a		@;anem al següent element 
		cmp r10, #7		@;si l'element es 7 o 15	(solid)
		beq .Lfi2a		@;anem al següent element
		
		.LelementMat1:
			mov r0, #COLUMNS	@;Obtenim una columna aleatoria
			bl mod_random
			mov r11, r0				
			
			mov r0, #ROWS		@;Obtenim una fila aleatoria		
			bl mod_random
			mov r12, r0
			
			mov r3, #COLUMNS
			mul r0, r12, r3
			add r8, r11, r0		@; FÓRMULA -> desplaçament = (fila*COLUMNS)+columna
			
			ldrb r9, [r5, r8]		@;carreguem el valor de mat_recomb1
			cmp r9, #0				@;si el valor es 0 escollim una altra posició
			beq .LelementMat1
		
		ldrb r10, [r6,r7]
		add r9, r10
		strb r9, [r6,r7]			@;guardem a mat_recomb2 l'element amb la possible gelatina
		
		mov r0, r6			
		mov r3, #3 					@;orientació nord
		bl cuenta_repeticiones
		cmp r0, #3					@;si R0=3, hi ha seqüènica vertical
		beq .LtotsValorsIguals
		
		mov r0, r6
		mov r3, #2					@;orientació oest
		bl cuenta_repeticiones
		cmp r0, #3					@;si R0=3, hi ha seqüència horitzontal
		beq .LtotsValorsIguals
		
		mov r0, #0
		strb r0, [r5,r8]			@;posem a 0 la posició de mat_recomb1 utilitzada
		b .LactivaMovimentSPR
		
		.LtotsValorsIguals:
			mov r8, #ROWS*COLUMNS
			strb r10, [r6,r7]		@;resustituim el valor de mat_recomb2
			mov r10, #0
		.Lbucle:
			ldrb r0, [r5,r10]		@;carreguem element de mat_recomb1
			cmp r0, #0
			beq .Lfbucle
			cmp r0, r9				@;comparem l'element que ha donat combinació la resta
			bne .LelementMat1		@;si no són tots iguals en triem un altre
		.Lfbucle:
			add r10, #1
			cmp r10, r8
			blo .Lbucle
			b .LprimeraPart			@;si tots els elements restants són iguals tornem a començar
		
	.LactivaMovimentSPR:
		mov r8, r1
		mov r9, r2
		
		mov r0, r12			@; r0 -> fila origen
		mov r3, r2			@; r3 -> columna destí
		mov r2, r1			@; r2 -> fila destí
		mov r1, r11			@; r1 -> columna origen
		bl activa_elemento
		
		mov r1, r8
		mov r2, r9
		
	.Lfi2a:
		add r7, #1
		add r2, #1
		cmp r2, #COLUMNS
		blo .LforColumnes2a		@;Següent columna
		
		add r1, #1
		cmp r1, #ROWS
		blo .LforFiles2a		@;Següent fila
		
		sub r7, #1
	.LcopiaMat2:			@;Copiem mat_recomb2 a matrix. Es copia de baix a dalt, de dreta a esquerra
		ldrb r1, [r6,r7]
		strb r1, [r4,r7]
		sub r7, #1
		cmp r7, #0
		bge .LcopiaMat2
		
	pop {r0-r12,pc}


@;:::RUTINAS DE SOPORTE:::



@; mod_random(n): rutina para obtener un número aleatorio entre 0 y n-1,
@;	utilizando la rutina 'random'
@;	Restricciones:
@;		* el parámetro 'n' tiene que ser un valor entre 2 y 255, de otro modo,
@;		  la rutina lo ajustará automáticamente a estos valores mínimo y máximo
@;	Parámetros:
@;		R0 = el rango del número aleatorio (n)
@;	Resultado:
@;		R0 = el número aleatorio dentro del rango especificado (0..n-1)
	.global mod_random
mod_random:
		push {r1-r4, lr}
		
		cmp r0, #2				@;compara el rango de entrada con el mínimo
		bge .Lmodran_cont
		mov r0, #2				@;si menor, fija el rango mínimo
	.Lmodran_cont:
		and r0, #0xff			@;filtra los 8 bits de menos peso
		sub r2, r0, #1			@;R2 = R0-1 (número más alto permitido)
		mov r3, #1				@;R3 = máscara de bits
	.Lmodran_forbits:
		cmp r3, r2				@;genera una máscara superior al rango requerido
		bhs .Lmodran_loop
		mov r3, r3, lsl #1
		orr r3, #1				@;inyecta otro bit
		b .Lmodran_forbits
		
	.Lmodran_loop:
		bl random				@;R0 = número aleatorio de 32 bits
		and r4, r0, r3			@;filtra los bits de menos peso según máscara
		cmp r4, r2				@;si resultado superior al permitido,
		bhi .Lmodran_loop		@; repite el proceso
		mov r0, r4				@; R0 devuelve número aleatorio restringido a rango
			
		pop {r1-r4, pc}



@; random(): rutina para obtener un número aleatorio de 32 bits, a partir de
@;	otro valor aleatorio almacenado en la variable global 'seed32' (declarada
@;	externamente)
@;	Restricciones:
@;		* el valor anterior de 'seed32' no puede ser 0
@;	Resultado:
@;		R0 = el nuevo valor aleatorio (también se almacena en 'seed32')
random:
	push {r1-r5, lr}
		
	ldr r0, =seed32				@;R0 = dirección de la variable 'seed32'
	ldr r1, [r0]				@;R1 = valor actual de 'seed32'
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2
	add r4, r3					@;R5:R4 = nuevo valor aleatorio (64 bits)
	str r4, [r0]				@;guarda los 32 bits bajos en 'seed32'
	mov r0, r5					@;devuelve los 32 bits altos como resultado
		
	pop {r1-r5, pc}	



.end
