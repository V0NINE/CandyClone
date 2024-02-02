@;=                                                          	     	=
@;=== RSI_timer0.s: rutinas para mover los elementos (sprites)		  ===
@;=                                                           	    	=
@;=== Programador tarea 2E: victor.fosch@estudiants.urv.cat				  ===
@;=== Programador tarea 2G: yyy.yyy@estudiants.urv.cat				  ===
@;=== Programador tarea 2H: zzz.zzz@estudiants.urv.cat				  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"


@;-- .data. variables (globales) inicializadas ---
.data
		.align 2
		.global update_spr
	update_spr:	.hword	0			@;1 -> actualizar sprites
		.global timer0_on
	timer0_on:	.hword	0 			@;1 -> timer0 en marcha, 0 -> apagado
	divFreq0: .hword	-23000			@;divisor de frecuencia inicial para timer 0


@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
	divF0: .space	2				@;divisor de frecuencia actual


@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm

@;TAREAS 2Ea,2Ga,2Ha;
@;rsi_vblank(void); Rutina de Servicio de Interrupciones del retrazado vertical;
@;Tareas 2E,2F: actualiza la posición y forma de todos los sprites
@;Tarea 2G: actualiza las metabaldosas de todas las gelatinas
@;Tarea 2H: actualiza el desplazamiento del fondo 3
	.global rsi_vblank
rsi_vblank:
		push {r0-r2, lr}
		
@;Actualitza los sprites 
		ldr r2, =update_spr
		ldrh r1, [r2]
		cmp r1, #0		@; si update_spr és 0 no hi ha res a actualitzar
		beq .LspritesActualizados
		mov r0, #0x07000000		@;Direcció base dels sprites per al processador gràfic principal
		ldr r1, =n_sprites
		ldr r1, [r1]
		bl SPR_actualizarSprites
		mov r1, #0
		strh r1, [r2]
		
	.LspritesActualizados:

@;Tarea 2Ga


@;Tarea 2Ha

		
		pop {r0-r2, pc}




@;TAREA 2Eb;
@;activa_timer0(init); rutina para activar el timer 0, inicializando o no el
@;	divisor de frecuencia según el parámetro init.
@;	Parámetros:
@;		R0 = init; si 1, restablecer divisor de frecuencia original divFreq0
	.global activa_timer0
activa_timer0:
	push {r0-r2, lr}
		cmp r0, #0
		beq .LfiActualitzaDivFreq
		ldr r0, =divFreq0
		ldrh r0, [r0]
		ldr r1, =divF0
		strh r0, [r1]	@;Guardem el valor de divFreq0 a divF0
		ldr r1, =0x04000100	@;@TIMER0_DATA
		strh r0, [r1]	@;Guardem el valor de divFreq0 a TIMER0_DATA
		
	.LfiActualitzaDivFreq:
		ldr r0, =timer0_on
		mov r1, #1
		strh r1, [r0]	@;Activa la variable global timer0_on
		
		ldr r0, =0x04000102		@;@TIMER0_CR
		mov r1, #0xC1	@;Activa timer 0 amb freqüència d'entreda F/1024
		strh r1, [r0]
	
	pop {r0-r2, pc}


@;TAREA 2Ec;
@;desactiva_timer0(); rutina para desactivar el timer 0.
	.global desactiva_timer0
desactiva_timer0:
	push {r0-r1, lr}
		ldr r0, =0x04000102		@;@TIMER0_CR
		mov r1, #0
		strh r1, [r0]	@;Desactiva el timer 0
		
		ldr r0, =timer0_on
		strh r1, [r0]	@;Desactiva la variable global timer0_on
	
	pop {r0-r1, pc}



@;TAREA 2Ed;
@;rsi_timer0(); rutina de Servicio de Interrupciones del timer 0: recorre todas
@;	las posiciones del vector vect_elem y, en el caso que el código de
@;	activación (ii) sea mayor o igual a 0, decrementa dicho código y actualiza
@;	la posición del elemento (px, py) de acuerdo con su velocidad (vx,vy),
@;	además de mover el sprite correspondiente a las nuevas coordenadas.
@;	Si no se ha movido ningún elemento, se desactivará el timer 0. En caso
@;	contrario, el valor del divisor de frecuencia se reducirá para simular
@;  el efecto de aceleración (con un límite).
	.global rsi_timer0
rsi_timer0:
	push {r0-r7, lr}
		ldr r3, =n_sprites	@;Nombre total de sprites
		ldr r3, [r3]
		ldr r7, =vect_elem	@;Direcció vase de vect_elem
		mov r6, #0	@;R6=0 no s'ha mogut cap sprite, =1 s'han mogut sprites
		mov r0, #0	@;index per a SPR_moverSprite
		
	.Lbucle:
		ldsh r4, [r7, #ELE_II]	@;Valor de ii per a vect_elem[X]
		cmp r4, #0		@;Si vect_elem[X].ii = 0 o =-1
		ble .LseguentIteracio
		
		mov r6, #1	@;Moviment d'algun element
		
		sub r4, #1
		strh r4, [r7, #ELE_II]	@;Decrementar ii
		
		ldrh r1, [r7, #ELE_PX]	@;Valor de px
		ldrh r5, [r7, #ELE_VX]	@;Valor de vx
		add r1, r5
		strh r1, [r7, #ELE_PX]
		
		ldrh r2, [r7, #ELE_PY]	@;Valor de py
		ldrh r5, [r7, #ELE_VY]	@;Valor de vy
		add r2, r5
		strh r2, [r7, #ELE_PY]
		
		bl SPR_moverSprite
		add r0, #1
		
	.LseguentIteracio:
		sub r3, #1	
		cmp r3, #0
		beq .LfiBucle
		add r7, #ELE_TAM	@;Variable ii de la seguent posició de vect_elem[] (5 variables de 2 bytes)
		b .Lbucle
		
	.LfiBucle:
		
		cmp r6, #0		@;Si no hi ha hagut moviment, desactiva timer
		bleq desactiva_timer0
		beq .Lfi
		
		ldr r0, =update_spr
		mov r1, #1
		strh r1, [r0]
		
		ldr r7, =vect_elem	@;Direcció vase de vect_elem
		ldsh r4, [r7, #ELE_II]	@;Valor de ii per a vect_elem[X]
		cmp r4, #13
		bls .Lfi
		
		ldr r0, =divF0
		ldrh r1, [r0]
		add r1, #1020
		strh r1, [r0]
		ldr r0, =0x04000100		@;TIMER0_DATA
		strh r1, [r0]
		
	.Lfi:
		
	pop {r0-r7, pc}


	.global prova
prova:
	push {r0,r4,lr}
		ldr r0, =vect_elem	@;Direcció vase de vect_elem
		mov r4, #20
		strh r4, [r0, #ELE_II]	@;20 a ii
	pop {r0,r4,pc}

.end
