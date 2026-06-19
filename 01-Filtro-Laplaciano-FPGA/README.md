# Acceleratore Hardware per Elaborazione Immagini (Filtro Laplaciano su FPGA)

Questo progetto, sviluppato per il corso d'esame di *Progettazione di Sistemi Digitali*, consiste nella realizzazione di un **coprocessore hardware ad alte prestazioni** specializzato nell'elaborazione di immagini in tempo reale, in particolare nell'operazione di **Edge Detection** (rilevamento dei contorni).

Il sistema riceve un flusso continuo di pixel (tramite il protocollo standard AXI-Stream), analizza l'immagine attraverso una finestra mobile 3x3 e applica un filtro matematico Laplaciano per far risaltare i contorni degli oggetti.

---

## L'Approccio Ingegneristico: Ottimizzazione Iterativa

La parte più significativa di questo lavoro non è stata semplicemente far funzionare il filtro, ma l'evoluzione del circuito attraverso **3 versioni successive**, studiate per renderlo sempre più veloce e leggero sul silicio:

### 1. Versione 1 (La Base)

Abbiamo creato l'architettura di base utilizzando moltiplicatori matematici tradizionali (Algoritmo di Booth) per elaborare i pixel della griglia 3x3 e un albero di sommatori standard per calcolare il risultato. Il sistema funzionava correttamente, ma i moltiplicatori occupavano molto spazio e rallentavano la frequenza massima.

### 2. Versione 2 (Astuzia Matematica e Vincoli Fisici)

Abbiamo sfruttato una proprietà fissa del filtro Laplaciano: i suoi coefficienti numerici sono sempre gli stessi (0, -1 e +4).

* **Matematica furba:** Abbiamo **eliminato completamente tutti i moltiplicatori hardware**. Moltiplicare un numero binario per 4 significa semplicemente spostare i fili logici a sinistra (operazione che sulla FPGA costa zero spazio e zero tempo). Le negazioni sono state semplificate con somme dirette.
* **Controllo fisico del chip:** Per evitare che il software Vivado disponesse i componenti a caso sul chip creando ritardi nei collegamenti, abbiamo racchiuso il circuito dentro un perimetro fisico definito (**`pblock`**). Questo ha accorciato le distanze dei segnali critici (come il reset), aumentando la velocità del sistema.

### 3. Versione 3 (Velocizzazione dell'Aritmetica)

Nell'ultima evoluzione ci siamo concentrati sull'albero di somma. Nei sommatori normali, il bit di "riporto" (il carry) deve viaggiare attraverso tutto il circuito prima di dare il risultato, creando una coda. Abbiamo sostituito la struttura con un sistema **Carry Save Adder (CSA)**: i riporti vengono semplicemente accumulati in parallelo e risolti solo all'ultimo stadio. Questo ha permesso di spingere la frequenza massima del circuito fino a **~190 MHz**.

---

## Struttura della Cartella

I file del progetto sono organizzati in modo da evidenziare l'evoluzione incrementale dell'hardware attraverso le tre sotto-architetture:

* **`hw/` (Logica Hardware suddivisa per versione):**
  * **`v1-baseline-booth/`:** Contiene i file sorgente VHDL di partenza (moltiplicatori basati sull'algoritmo di Booth, alberi di somma Ripple Carry Adder) e il file dei vincoli temporali base.
  * **`v2-hardcoded-pblock/`:** Contiene i file VHDL ottimizzati nell'area (moltiplicazioni cablate tramite shift strutturali, sommatori Carry Lookahead) e il file `.xdc` che definisce i confini fisici del `pblock` sul chip.
  * **`v3-csa-tree/`:** Contiene l'architettura spinta alla massima frequenza (albero multi-operando Carry Save Adder), il sommatore finale e il testbench di simulazione completo (`tb_V3.vhd`) con la generazione dell'immagine sintetica di test.

* **`docs/` (Documentazione):**
  * Contiene la relazione tecnica d'esame completa (`Relazione_PSD.pdf`), con tabelle comparative dell'utilizzo delle risorse (LUT e Flip-Flop), consumi di potenza e analisi dei percorsi critici temporali (WNS/WHS).

---

## 👥 Gruppo di Lavoro

Progetto accademico realizzato in collaborazione per il corso di *Progettazione di Sistemi Digitali*:

* **Francesco Di Bruno**
* **Mariafrancesca Lamerata**
* **Rosa Marino**
* **Luca Gaetano Sansalone**
