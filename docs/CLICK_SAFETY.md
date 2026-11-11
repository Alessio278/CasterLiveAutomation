# Click safety / Sicurezza dei clic

## Modello

1. Le coordinate di ogni pulsante vengono registrate relativamente all'area **client** del processo CasterLive DJ.
2. `PointClientSize` memorizza le dimensioni dell'area client durante la cattura (Ctrl+Maiusc+C).
3. Ogni azione CLIC recupera la finestra, la ripristina e la attiva.
4. Con `GetClientRect` confronta dimensioni attuali e dimensioni registrate. Se non corrispondono, blocca il clic.
5. Con `ClientToScreen` ricalcola le coordinate schermo ogni volta, anche dopo spostamento su altro monitor.
6. Sposta il mouse, poi verifica che `MouseGetPos` e `GetAncestor` identifichino CasterLive DJ e che il punto sia ancora quello calcolato.
7. Ripete `ClientToScreen` appena prima del clic per intercettare spostamenti avvenuti in quel momento.
8. Se qualunque controllo fallisce, registra l'errore senza emettere `MouseClick`.

**Limiti:** questa procedura non riconosce semanticamente i pulsanti. Se CasterLive DJ cambia la disposizione interna mantenendo le stesse dimensioni, una calibrazione può diventare obsoleta. Non si può garantire atomicità perfetta contro un movimento di finestra nell'istante esatto tra verifica e evento del mouse. È indispensabile provare START e CLOSE con il desktop sbloccato e CasterLive DJ non in diretta.

## Migrazione

Le coordinate delle installazioni precedenti senza `[PointClientSize]` rimangono nel file INI ma non possono essere eseguite: registra ciascun pulsante usato dalla sequenza con il mouse e salva nuovamente. Le coordinate dei pulsanti inutilizzati possono restare vuote. La mancanza di calibrazione blocca la ripresa o l'esecuzione della sequenza e non cancella automaticamente i dati.

## Casi di prova manuale

- Avvia e chiudi a finestra normale, dopo una cattura nuova.
- Sposta CasterLive DJ nell'angolo opposto del monitor: gli stessi pulsanti devono essere trovati.
- Minimizza CasterLive DJ dopo START: CLOSE deve ripristinare e premere sulla finestra, non sul desktop.
- Sposta CasterLive DJ su un secondo monitor.
- Ridimensiona CasterLive DJ: deve apparire un `CLIC BLOCCATO`, non un clic.
- Copri la finestra con un'applicazione topmost: l'automazione deve riportare Caster in primo piano o bloccare il clic.
- Togli la calibrazione `PointClientSize` da una copia del file INI: il Worker deve rifiutare il CLIC.

## Recupero finestra dopo minimizzazione (v0.5 pre-release)

- Ogni clic completato salva nella sessione HWND e PID della finestra usata. Il Worker prova a ripristinare proprio quella nella chiusura successiva.
- Se la finestra non è più valida, il Worker esamina le finestre principali dello stesso eseguibile. Non si fida della prima finestra trovata: scarta finestre figlie e preferisce quelle con **area client valida e dimensioni uguali alla calibrazione**.
- Dopo WinRestore, attende fino a 4 secondi che la finestra abbia un'area client non nulla; se resta 0×0, tenta un altro candidato sicuro. Se nessun candidato supera i controlli, registra `RECUPERO FINESTRA`, `FINESTRE CASTER DISPONIBILI` e `CLIC BLOCCATO`, quindi interrompe la sequenza.
- Il recupero **non** cambia mai automaticamente le coordinate registrate e non utilizza clic ciechi su altre finestre.

### Test controllato consigliato

1. Verificare che il SEND di CasterLive DJ non sia già attivo e che non vi sia una diretta in corso.
2. Configurare due orari ravvicinati START/CLOSE, salvare e riprendere l'automazione.
3. Dopo START, ridurre CasterLive DJ a icona e lasciare il pannello nascosto nella tray.
4. All'ora CLOSE controllare nel log `TRIGGER CLOSE`, `RIPRISTINO`, `CLIC SEND`, `CLIC NEXT`, `FINESTRA CHIUSA`, `OK CLOSE`.
5. Controllare fisicamente che nessun clic sia partito sul desktop. In caso di errore `close_error`, controllare lo stato SEND manualmente prima di modificare/ritentare la sessione.
