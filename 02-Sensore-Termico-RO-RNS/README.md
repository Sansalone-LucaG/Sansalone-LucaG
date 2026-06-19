# Sensore Termico On-Chip ad Alte Prestazioni (Co-Design Hardware/Software)

Benvenuto nella cartella dedicata al progetto della mia Tesi Triennale. Questo lavoro riguarda la progettazione di un **sensore di temperatura completamente digitale** integrato direttamente all'interno di un chip (FPGA), studiato per monitorare il calore del silicio in tempo reale e prevenire guasti o surriscaldamenti (hotspot).

La particolarità di questo progetto sta nell'approccio **Hardware/Software Co-Design**: una sinergia intelligente in cui la parte hardware e la parte software collaborano per ottenere la massima efficienza con il minor consumo di spazio possibile.

---

## Come Funziona il Sistema? (In parole semplici)

Il funzionamento si basa su un concetto fisico: all'interno del chip, la velocità di commutazione dei circuiti microscopici varia in base alla temperatura. 

1. **Il Termometro (Hardware):** Sfruttando alcune strutture native del chip (le catene di riporto veloce), abbiamo creato un "anello oscillante" (Ring Oscillator) che produce un segnale ad altissima frequenza. Più il chip si scalda, più questa frequenza cambia.
2. **Il Contatore Super-Leggero (Hardware):** Per misurare questa frequenza senza sprecare spazio sul chip, abbiamo utilizzato un contatore non convenzionale basato su un sistema matematico speciale (RNS - Sistema Numerico dei Residui). Questo contatore conta in parallelo senza rallentamenti, occupando la metà dello spazio di un contatore normale.
3. **Il Traduttore Intelligente (Software):** Il contatore hardware produce un risultato "in codice" (i residui). Invece di costruire un circuito hardware enorme e pesante per tradurre questo codice in numeri normali, abbiamo collegato il sensore a un piccolo processore virtuale interno (MicroBlaze) e affidato la traduzione matematica complessa a un semplice programma scritto in **Linguaggio C**.

---

## Perché questo approccio è Vincente?

* **Risparmio di Spazio (Area):** Delegando la matematica difficile al software (C) ed eseguendola sul processore, abbiamo risparmiato decine di componenti hardware logici (LUT e Flip-Flop). L'intero sensore è così leggero da poter essere replicato decine di volte in punti diversi del chip per creare una vera e propria "mappa termica".
* **Precisione:** Testato in camera climatica a temperature controllate (da 5°C a 65°C), il sensore ha dimostrato una sensibilità eccellente, catturando le microscopiche variazioni fisiche del silicio.

---

## Struttura dei File in questa Cartella

Per facilitare la lettura, il progetto è stato separato in modo pulito:

* **`hw/src/` (La mente Hardware):** Contiene i file in linguaggio **VHDL** che descrivono i circuiti fisici del sensore (l'oscillatore, il contatore speciale, la macchina a stati di controllo) e il guscio di collegamento (interfaccia AXI) per parlare con il processore.
* **`sw/src/` (Il braccio Software):** Contiene il file `main_thermal_sensor.c` in **Linguaggio C**. È il firmware che dice al processore quando attivare il sensore, per quanto tempo contare, ed esegue l'algoritmo matematico per mostrare la temperatura a schermo.
* **`docs/` (La documentazione):** Contiene il testo completo della mia tesi in PDF, ideale per chi desidera approfondire le equazioni matematiche, i grafici fisici e i dettagli accademici del progetto.
