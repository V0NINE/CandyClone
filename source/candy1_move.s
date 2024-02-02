@;=                                                         	      	=
@;=== candy1_move: rutinas para contar repeticiones y bajar elementos ===
@;=                                                          			=
@;=== Programador tarea 1E: xxx.xxx@estudiants.urv.cat				  ===
@;=== Programador tarea 1F: yyy.yyy@estudiants.urv.cat				  ===
@;=                                                         	      	=


.include "../include/candy1_incl.i"


@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm


@;TAREA 1E;
@; cuenta_repeticiones(*matriz,f,c,ori): rutina para contar el número de
@;	repeticiones del elemento situado en la posición (f,c) de la matriz, 
@;	visitando las siguientes posiciones según indique el parámetro de
@;	orientación 'ori'.
@;	Restricciones:
@;		* sólo se tendrán en cuenta los 3 bits de menor peso de los códigos
@;			almacenados en las posiciones de la matriz, de modo que se ignorarán
@;			las marcas de gelatina (+8, +16)
@;		* la primera posición también se tiene en cuenta, de modo que el número
@;			mínimo de repeticiones será 1, es decir, el propio elemento de la
@;			posición inicial
@;	Parámetros:
@;		R0 = dirección base de la matriz
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R3 = orientación 'ori' (0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte)
@;	Resultado:
@;		R0 = número de repeticiones detectadas (mínimo 1)
.global cuenta_repeticiones    
cuenta_repeticiones:           
		push {r1-r2,r4-r9, lr}  
		
		mov r4, #ROWS             
		mov r5, #COLUMNS          
		
		@; Càlcul de posició inicial de la matriu (apliquem fòrmula)
		mul r6, r1, r5            @; Índex de fila * nombre de columnes
		add r6, r6, r2            @; r2 + l'índex de fila * nombre de columnes
		add r6, r6, r0            @; Direcció base de la matriu + r6
		ldrb r7, [r6]             @; Carrega a r7 el valor de la posició inicial
		and r7, r7, #0x07         @; Guardem sol 3 bits de menor pes per obtenir valor de 0-7
		
		mov r9, #1               @; r9 = num de repeticions
		
	.BuclePrincipal:
		cmp r3, #0                @; (0 -> Est)
		beq .Est
		cmp r3, #1                @; (1 -> Sud)
		beq .Sud
		cmp r3, #2                @; (2 -> Oest)
		beq .Oest
		cmp r3, #3                @; (3 -> Nord)
		beq .Nord
		b .FinalPrograma          @; Gestió d'errors: si no es compleix cap orientació es surt del bucle
		
	.Est:
		add r2, r2, #1            @; Columna++
		cmp r2, r5                
		bhs .FinalPrograma       
		add r6, r6, #1            @; Actualitza la posició a la matriu
		b .ComprovarFinal
		
	.Sud:
		add r1, r1, #1            @; Fila++
		cmp r1, r4                
		bhs .FinalPrograma        
		add r6, r6, r5            @; Nova posició de memòria actualitzat
		b .ComprovarFinal
		
	.Oest:
		sub r2, r2, #1            @; Columna--
		cmp r2, #0                
		blt .FinalPrograma        
		sub r6, r6, #1            @; Nova posició de memòria actualitzat
		b .ComprovarFinal
		
	.Nord:
		sub r1, r1, #1            @; Fila--
		cmp r1, #0                
		blt .FinalPrograma        
		sub r6, r6, r5            @; Nova posició de memòria actualitzat
		
	.ComprovarFinal:
		ldrb r8, [r6]             
		and r8, r8, #0x07         
		cmp r8, r7                
		bne .FinalPrograma        
		add r9, r9, #1          @; Augmenterem el contador de repeticions si el nou element i el 1r element son iguals
		b .BuclePrincipal         
		
	.FinalPrograma:
		mov r0, r9               @; Guardem resultat a r0
		pop {r1-r2,r4-r9, pc}  


@;TAREA 1F;
@; baja_elementos(*matriz): rutina para bajar elementos hacia las posiciones
@;	vacías, primero en vertical y después en sentido inclinado; cada llamada a
@;	la función sólo baja elementos una posición y devuelve cierto (1) si se ha
@;	realizado algún movimiento, o falso (0) si está todo quieto.
@;	Restricciones:
@;		* para las casillas vacías de la primera fila se generarán nuevos
@;			elementos, invocando la rutina 'mod_random' (ver fichero
@;			"candy1_init.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica se ha realizado algún movimiento, de modo que puede que
@;				queden movimientos pendientes. 
.global baja_elementos
baja_elementos:
		push {r4, lr}
		
		mov r4, r0				@; Passem la direccio de la matriu a r4 per a poder cridar les funcions
		bl baja_verticales	
		cmp r0, #1				@; Si retorna un 1 acabem i no entrem a laterals
		beq .LFinal
		bl baja_laterales
	.LFinal:
		
		pop {r4, pc}


@;:::RUTINAS DE SOPORTE:::

@; baja_verticales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en vertical; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento. 
.global baja_verticales
baja_verticales:
		push {r4-r6, lr}
		
		mov r4, #ROWS       @; Nombre total de files
		mov r5, #COLUMNS    @; Nombre total de columnes
		
	.BucleFiles:
		mov r6, r5          @; Columna actual (l'última és la primera)
		
	.BucleColumnes:
		add r0, r6          @; Direcció de la posició actual a la matriu
		
		@; Comprovar si la posició actual no és la més alta
		subs r6, r6, #1     @; Disminueix la columna actual
		beq .SkipColumna    @; Si és la primera fila, salta a la següent columna
		
		@; Trobar la fila de destí
	BuscarFilaDestino:
		subs r0, r0, r5     @; Disminueix la fila de destí (mou la direcció un rengló amunt)
		
		@; Comprovar si la fila de destí està buida
		ldrb r6, [r0]
		cmp r6, #0
		bne FerMoviment 	@; Si la fila de destí no està buida, realitza el moviment
		b BuscarFilaDestino
		
	FerMoviment:
		@; Realitzar el moviment i marcar la posició de fila actual com a buida
		ldrb r6, [r0]
		strb r6, [r0, #-1]  @; Mou l'element de la fila actual a la fila de destí
		strb r5, [r0]       @; Marca la posició actual com a buida
		
	.SkipColumna:
		@; Disminueix la columna actual
		subs r6, r6, #1
		bne .BucleColumnes  @; Si no s'ha arribat a la columna més a l'esquerra, continua amb la següent columna
		
		@; Disminueix la fila actual
		subs r4, r4, #1
		bne .BucleFiles     @; Si no s'ha arribat a la primera fila, continua amb la següent fila
		
		mov r0, r5          @; Retorna si s'ha realitzat algun moviment
		
		pop {r4-r6, pc}


@; baja_laterales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en diagonal; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento. 
baja_laterales:
	push {lr}
		
		
	pop {pc}


.end