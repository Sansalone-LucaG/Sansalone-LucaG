#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
//libreria per usare comunicare con gli elementi del block design
#include "xparameters.h"
//libreria per usare gli I/O del block design
#include "xil_io.h"
// libreria per lavorare con i binari
#include <stdint.h>
#include <stdlib.h>

// Definizione delle posizioni dei bit nel RNS_OUT
#define BIT_Q1        (0)
#define BIT_Q2        (1)
#define BIT_Q3        (2)
#define BIT_O1        (3)
#define BIT_O2        (4)
#define BIT_O3        (5)
#define BIT_FF33      (6)
#define BIT_FF35_0    (7)
#define BIT_FF35_1    (8)
#define BIT_FF35_2    (9)

// Definizione dei moduli del RNS
#define m1	32
#define m2	33
#define m3	35

// Definizione del numero di cicli di clock
#define reset	2048	// 2^10 cicli di clock
#define wait_ro	4096	// 2^12 cicli di clock tempo di assestamento del RO
#define cnt_100	732		// cicli per avere 100 us
#define cnt_50	354		// cicli per avere 50 us
#define op		64		// 2^6 	cicli di clock tempo d'attesa tra un operazione ed un'altra


//======================================================
//======= CRT DECODER ==================================
//======================================================

/*
Funzione per calcolare l'inverso modulare
(algoritmo di euclideo esteso)
*/
int modulo_inverso(int a, int m){
    int m0 = m;
    int x0 = 0;
    int x1 = 1;
    int temp, q;

    if (m == 1) return 0;

    while (a  > 1){
        q = a / m;  // Quoziente
        temp = m;

        m = a % m;  // Resto
        a = temp;

        temp = x0;
        x0 = x1 - q * x0;
        x1 = temp;  // Inverso modulare
    }

    if (x1 < 0) x1 += m0;
    return x1;
}

/*
Funzione per decodificare il numero originale utilizzando il CRT
*/
int decode_rns(int residue[], int moduli[]){
    // Prodotto totale dei moduli
    int M = moduli[0] * moduli[1] * moduli[2];

    int result = 0;

    for(int i = 0; i < 3; i++){
        int Mi = M / moduli[i];
        int inverse = modulo_inverso(Mi, moduli[i]);
        result += residue[i] * Mi * inverse;    // Somma totale a cui poi va applicato il modulo
    }
    return result % M;  // (Somma) mod M
}


//======================================================
//======= ESTRAZIONE RESIDUI ===========================
//======================================================


// Funzione per estrarre il valore di un singolo bit da un intero a 32 bit
uint8_t get_bit_value(uint32_t input_vector, uint8_t bit_position) {
    // con ">>" si sposta il bit desiderato nella posizione 0
    //e poi si applica "& 1" per ottenere il valore del bit
    return (input_vector >> bit_position) & 1;
}

//Funzione per l'estrazione dei residui dai registri
int* extract_residues() {
    // Inizializza il valore di rns_out
    int addr;
    uint32_t rns_out;
    uint32_t input_vector;
    // Allocazione memoria per un array di 3 interi
    int* residue = (int*)malloc(3 * sizeof(int));
    // Controlla se l'allocazione ha avuto successo
    if (residue == NULL) {
        perror("Errore di allocazione memoria");
        return NULL; // Restituisce NULL in caso di errore
    }

    for(int i=0; i<32; i++){
    	addr = (4228 * i) + 1;
    	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, addr);
    	for(int i=0; i<100; i++){}
    	rns_out=Xil_In32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR+0x4);
    	//printf("\n\t %u \n", rns_out);
    	//controllo del primo registro
    	input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_Q1) == 1){
    		if (i == 0)
				residue[0] = 32;
    		else
    			residue[0] = i;
    	}
    	//controllo del secondo registro
    	input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_Q2) == 1){
			if (i == 0)
				residue[1] = 33;
			else
				residue[1] = i;
		}
		input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_FF33) == 1){
    		residue[1] = 32;
    	}
    	// controllo del terzo registro
    	input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_Q3) == 1){
    		if(i == 0)
    			residue[2] = 35;
			else
				residue[2] = i;
    	}
		input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_FF35_0) == 1){
			residue[2] = 32;
		}
		input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_FF35_1) == 1){
			residue[2] = 33;
		}
		input_vector=rns_out;
    	if(get_bit_value(input_vector, BIT_FF35_2) == 1){
			residue[2] = 34;
		}
    	//Attendo 3 cicli di clock prima di passare al prossimo indirizzo
    	for(int i=0; i<3; i++){}

    }

    return residue;
}

// Funzione per la sola stampa dei residui
void print_residues(int* residue) {
    if (residue != NULL) {
        printf("Residui estratti:\n");
        for (int i = 0; i < 3; i++) {
            printf("Residuo %d: %d\n", i + 1, residue[i]);
        }
    } else {
        printf("Nessun residuo estratto.\n");
    }
}

// Funzione per la stampa dei residui e per la decodifica
void decode_residues(int* residue, int mod[]){
    int X;
    if (residue != NULL) {
    // Stampa i residui estratti
    printf("Residui:\n");
        for (int i = 0; i < 3; i++) {
            printf("Residuo %d: %d\n", i + 1, residue[i]);
        }
    X = decode_rns(residue, mod);
    printf("Numero decodificato: %d\n", X);
    }
    else {
        printf("Errore nell'estrazione dei residui.\n");
    }
}


//======================================================
//======= MAIN =========================================
//======================================================


int main()
{
    init_platform();
    print("\n\n ==== Inizio ==== \n\r");


    //Definizione del set di moduli per il CRT DECODER
    int mod[3] = {m1,m2,m3};

    // ==== INIZIALIZZAZIONE =========================================

    //Primo reset per inizializzare i registri e attivo il
    // Ring Oscillator  "reg0[31]=1 + reg0[0]=1 others 0"
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 131073);
    for(int i=0; i<reset; i++){}	// aspetto 2^10 cicli di clock

    //Abilito il Ring Oscillator "reg0[0]=1 others 0"
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
    for(int i=0; i<wait_ro; i++){}	// aspetto 2^10 cicli di clock


    // ===== PRIMO CONTEGGIO 100 us ==================================
    //Abilito il contatore RNS tenendo attivato il RO => reg0[1]=1
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 3);
    for(int i=0; i<cnt_100; i++){}	// conto per circa 100us

    //Disabilito il contatore ed inizio il controllo nei registri
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
    for(int i=0; i<op; i++){}

    decode_residues(extract_residues(), mod);
    for(int i=0; i<op; i++){}

    // === reset ===
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 131073);
	for(int i=0; i<reset; i++){}	// aspetto 2^10 cicli di clock

/*
    // ==== SECONDO CONTEGGIO 100 us =================================
    //Abilito il contatore RNS tenendo attivato il RO => reg0[1]=1
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 3);
    for(int i=0; i<cnt_100; i++){}	// conto per circa 100us

    //Disabilito il contatore ed inizio il controllo nei registri
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
    for(int i=0; i<op; i++){}

    decode_residues(extract_residues(), mod);
    for(int i=0; i<op; i++){}

    // === reset ===
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 131073);
	for(int i=0; i<reset; i++){}	// aspetto 2^10 cicli di clock



    // ==== TERZO CONTEGGIO 100 us ===================================
    //Abilito il contatore RNS tenendo attivato il RO => reg0[1]=1
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 3);
    for(int i=0; i<cnt_100; i++){}	// conto per circa 100us

    //Disabilito il contatore ed inizio il controllo nei registri
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
    for(int i=0; i<op; i++){}

    decode_residues(extract_residues(), mod);
    for(int i=0; i<op; i++){}

    // === reset ===
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 131073);
	for(int i=0; i<reset; i++){}	// aspetto 2^10 cicli di clock


    // ===== PRIMO CONTEGGIO 50 us ===================================
    //Abilito il contatore RNS tenendo attivato il RO => reg0[1]=1
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 3);
	for(int i=0; i<cnt_50; i++){}	// conto per circa 50us

    //Disabilito il contatore ed inizio il controllo nei registri
    Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
    for(int i=0; i<op; i++){}

    decode_residues(extract_residues(), mod);
    for(int i=0; i<op; i++){}

    // === reset ===
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 131073);
	for(int i=0; i<reset; i++){}	// aspetto 2^10 cicli di clock



    // ===== SECONDO CONTEGGIO 50 us =================================
	//Abilito il contatore RNS tenendo attivato il RO => reg0[1]=1
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 3);
	for(int i=0; i<cnt_50; i++){}	// conto per circa 50us

	//Disabilito il contatore ed inizio il controllo nei registri
	Xil_Out32(XPAR_MY_TEMP_SENSOR_IP_0_S00_AXI_BASEADDR, 1);
	for(int i=0; i<op; i++){}

	decode_residues(extract_residues(), mod);
	for(int i=0; i<op; i++){}
*/


    cleanup_platform();
    return 0;
}
