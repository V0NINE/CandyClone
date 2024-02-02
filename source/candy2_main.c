/*------------------------------------------------------------------------------

	$ candy2_main.c $

	Programa principal para la práctica de Computadores: candy-crash para NDS
	(2º curso de Grado de Ingeniería Informática - ETSE - URV)
	
	Analista-programador: santiago.romani@urv.cat
	Programador 1: victor.fosch@estudiants.urv.cat
	Programador 2: yyy.yyy@estudiants.urv.cat
	Programador 3: zzz.zzz@estudiants.urv.cat
	Programador 4: uuu.uuu@estudiants.urv.cat

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>
#include <time.h>
#include <candy2_incl.h>


/* variables globales */
char matrix[ROWS][COLUMNS];		// matriz global de juego
int seed32;						// semilla de números aleatorios
int level = 0;					// nivel del juego (nivel inicial = 0)
int points;						// contador global de puntos
int movements;					// número de movimientos restantes
int gelees;						// número de gelatinas restantes

/* actualizar_contadores(code): actualiza los contadores que se indican con el
	parámetro 'code', que es una combinación binaria de booleanos, con el
	siguiente significado para cada bit:
		bit 0:	nivel
		bit 1:	puntos
		bit 2:	movimientos
		bit 3:	gelatinas  */
void actualizar_contadores(int code)
{
	if (code & 1) printf("\x1b[38m\x1b[1;8H %d", level);
	if (code & 2) printf("\x1b[39m\x1b[2;8H %d  ", points);
	if (code & 4) printf("\x1b[38m\x1b[1;28H %d ", movements);
	if (code & 8) printf("\x1b[37m\x1b[2;28H %d ", gelees);
}


void inicializa_interrupciones()
{
	irqSet(IRQ_VBLANK, rsi_vblank);
	TIMER0_CR = 0x00;  		// inicialmente el timer no genera interrupciones
	irqSet(IRQ_TIMER0, rsi_timer0);		// cargar direcciones de las RSI
	irqEnable(IRQ_TIMER0);				// habilitar la IRQ correspondiente
}


int main(void)
{
	int i = 0;
	seed32 = time(NULL);			// fijar semilla de números aleatorios
	init_grafA();					// cargamos información gráfica
	inicializa_interrupciones();	// inicializamos timer y habilitamos su IRQ
	
	consoleDemoInit();			// inicialización de pantalla de texto
	printf("candyNDS (prueba tarea 2A)\n");
	printf("\x1b[38m\x1b[1;0H  nivel:");
	actualizar_contadores(1);
	
	inicializa_matriz(matrix, level);
	genera_sprites(matrix);
	escribe_matriz(matrix);

	do							// bucle principal de pruebas
	{
		printf("\x1b[39m\x1b[3;8H (pulse A)");
		printf("\x1b[39m\x1b[4;8H (pulse B)");
		printf("\x1b[39m\x1b[5;8H (pulse UP para 2Ia)");
		
		
		do
		{	swiWaitForVBlank();
			scanKeys();					// esperar pulsación tecla 'A', 'B' o 'UP'
		} while (!(keysHeld() & (KEY_A | KEY_B | KEY_UP)));
		
		printf("\x1b[3;8H              ");
		printf("\x1b[4;8H              ");
		printf("\x1b[5;8H                          ");
		printf("\x1b[6;8H                         ");
		printf("\x1b[7;8H                         ");
		retardo(3);		
		
		if (keysHeld() & KEY_A)			// si pulsa 'A',
		{								// pasa a siguiente nivel
			level = (level + 1) % MAXLEVEL;
			inicializa_matriz(matrix, level);
			genera_sprites(matrix);
			escribe_matriz(matrix);
			actualizar_contadores(1);
			i=0;
		}
		
		if (keysHeld() & KEY_B)			// si pulsa 'B'
		{								// recombina la matriz
			recombina_elementos(matrix);
			activa_timer0(1);		// activar timer de movimientos
			while (timer0_on) swiWaitForVBlank();	// espera final
			genera_sprites(matrix);
			escribe_matriz(matrix);
			
			i=0;
		}
		
		//						   si pulsa 'UP' 
		if (keysHeld() & KEY_UP) //Condicional per provar el funcionament de 2Ia (millor amb mapes 10 i 11) al mapa 10 tots
		{						 //estan a -1 p.q. no hi ha elements, al mapa 11 els 2 primers estan a 32 per recombinacio
			recombina_elementos(matrix);
			printf("\x1b[41m\x1b[6;8H ELEM_ii[%d]: %d", i, getVectElem(i).ii);
			i++;
		}
		
	} while (1);
	
	return(0);
}