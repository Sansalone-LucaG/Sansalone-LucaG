<!--
-->
# Portfolio di Ingegneria Hardware/Software Codesign

## Profilo Professionale
Studente della Laurea Magistrale in Ingegneria Elettronica presso l'Università della Calabria (DIMES), specializzato nell'indirizzo **Hardware/Software Codesign**. Focalizzato sulla progettazione digitale su FPGA, ottimizzazione di architetture di calcolo ed elaborazione di segnali/immagini in tempo reale. Esperienza nel partizionamento HW/SW volto a massimizzare il throughput e minimizzare l'uso di risorse d'area e i consumi energetici su silicio.

---


## Competenze Tecniche

* **Linguaggi di Programmazione & HDL:** VHDL, C/C++, Assembly
* **Strumenti di Sviluppo & IDE:** Xilinx Vivado Design Suite, Xilinx SDK / Vitis, NI LabVIEW, Visual Studio / VS Code
* **Strumenti di Documentazione:** LaTeX, Markdown

---

## Progetti Ingegneristici Principali

### 1. Filtro Laplaciano 3x3 ad Aritmetica Ottimizzata su FPGA (Sintesi e Routing)
**Contesto:** Progetto d'esame per il corso di *Progettazione di Sistemi Digitali* (A.A. 2025/2026).
*   **Descrizione:** Sviluppo e ottimizzazione iterativa di un acceleratore hardware per il filtraggio spaziale e rilevamento dei contorni (Edge Detection) in tempo reale su immagini grayscale 32x32 a 8 bit, interfacciato tramite protocollo AXI-Stream.
*   **Evoluzione Architetturale & Ottimizzazioni:**
    *   *Versione 1 (Baseline):* Moltiplicatori basati su algoritmo di Booth Radix-4 e albero di somma a 4 stadi con Ripple Carry Adder (RCA).
    *   *Versione 2 (Hardcoded & Layout):* Rimozione dei moltiplicatori grazie alle proprietà fisse del kernel. Implementazione di shift cablati e negazioni tramite Carry Look-ahead Adder (CLA). Introduzione di un vincolo di piazzamento fisico (`pblock`) in Vivado, riducendo drasticamente il net delay del reset ad alto fanout.
    *   *Versione 3 (Carry Save Adder):* Introduzione di un albero di somma multi-operando basato su celle Carry Save Adder (CSA) per azzerare la propagazione del carry negli stadi intermedi, spostando il critical path solo sul sommatore RCA finale.
*   **Metriche di Sintesi (Xilinx Artix-7):**

| Versione Architetturale | WNS (ns) | Frequenza Max ($f_{max}$) | Slice LUT | Slice FF | Potenza Dinamica (W) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **V1 (Booth + RCA)** | 4.449 | ~180 MHz | 135 | 276 | 0.004[cite: 1] |
| **V2 (Hardcoded + CLA + Pblock)** | 4.515 | ~182 MHz | 117 | 256 | 0.003 |
| **V3 (Hardcoded + CSA Tree)** | 4.718 | ~190 MHz | 144 | 313 | 0.003 |

---

### 2. Sensore di Temperatura On-Chip basato su Ring Oscillator e Contatore RNS
**Contesto:** Tesi di Laurea Triennale in Ingegneria Elettronica (A.A. 2024/2025).
*   **Descrizione:** Progettazione di un sensore termico digitale on-chip ad alta precisione per supportare il Dynamic Thermal Management (DTM) e mitigare la formazione di hotspot locali su matrici FPGA.
*   **Dettagli Tecnici dell'Hardware:**
    *   *Ring Oscillator (RO):* Implementato configurando le catene di riporto veloce dedicate (`CARRY4`) della FPGA come stadi invertenti deterministici (fino a ~354 MHz su scheda Nexys4 DDR).
    *   *Contatore ad Anello RNS:* Sviluppo di un contatore non convenzionale basato sul Sistema numerico dei Residui (RNS) con moduli coprimi $[32, 33, 35]$ strutturato tramite primitive `SRLC32E`. Progettazione di una FSM custom per il controllo dinamico del Clock Enable (CE) per gestire le fasi di reset e riallineamento dell'hot-bit.
*   **Partizionamento Hardware/Software (Codesign):**
    *   Il sensore è integrato come IP proprietario connesso tramite bus AXI4-Lite a un microprocessore soft-core **MicroBlaze**.
    *   *Scelta di progetto:* La complessa decodifica matematica dei residui (Teorema Cinese del Resto e Algoritmo Euclideo Esteso per l'inverso modulare) è stata delegata interamente al firmware scritto in **linguaggio C** esguito sul MicroBlaze, risparmiando 28 LUT e 69 FF di logica combinatoria sul silicio.
*   **Risultati Fisici in Camera Climatica:**
    *   Caratterizzazione nell'intervallo 5°C - 65°C con riscontro del comportamento non lineare "a campana" dovuto al bilanciamento termico tra la tensione di soglia ($V_{TH}$) dominatante a basse temperature e la mobilità dei portatori ($\mu$) dominante ad alte temperature.
    *   *Sensibilità media:* 17.67 kHz/°C.

| Tipo di Contatore (15-bit equiv.) | Numero di LUT | Numero di FF | Primitiva CARRY4 | Range Dinamico |
| :--- | :---: | :---: | :---: | :---: |
| **Contatore Binario Classico** | 17 | 32 | 8 | 32.768 |
| **Contatore RNS Proposto** | 9 | 13 | 0 | **36.960** |

---

## Contatti
## Contatti
* **Università:** Università della Calabria (UNICAL) - DIMES
* **Curriculum Vitae:** [Scarica il mio CV in formato PDF](CV_Luca_Gaetano_Sansalone.pdf)
* **Email:** [sans.lu@outlook.it](mailto:sans.lu@outlook.it)
