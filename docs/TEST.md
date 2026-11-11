# Collaudo manuale — CasterLiveAutomation 0.5 pre-release (internal V5/RC2 base)

**Eseguire solo in ambiente controllato, senza diretta in corso.** Il motore multiplo NON è ancora validato su Windows.

## Preparazione

- [ ] Conservare backup completo della cartella V3.11/V4.2 funzionante.
- [ ] Chiudere i vecchi Worker e pannelli, CasterLive DJ chiuso e SEND spento.
- [ ] Installare AutoHotkey v2, copiare il pacchetto V5 in cartella scrivibile.
- [ ] Eseguire in una cartella pulita senza file INI: `CasterLiveAutomation_Schedules.ini` deve contenere **zero** schedulazioni e il pannello deve mostrare **IN PAUSA** / **Riprendi automazione**.
- [ ] Verificare che premere **Riprendi automazione** senza schedulazioni abilitate sia rifiutato e non avvii il Worker.
- [ ] Aggiungere e abilitare una schedulazione: deve comparire solo dopo il salvataggio esplicito.
- [ ] Con un calendario già esistente, riavviare il programma: non deve sovrascrivere le schedulazioni e deve conservare lo stato di pausa esplicitamente salvato.
- [ ] Con una configurazione vecchia ma senza il file calendario, verificarne la creazione vuota e la sospensione (nessuna importazione automatica).
- [ ] Verificare nessun riferimento alla vecchia scheda Profili; le righe del calendario siano visibili a 640×640 e a schermo intero.

## Azioni, etichette e salvataggio

- [ ] Nuova installazione: 13 etichette standard nell’ordine documentato, tutte con X e Y vuote.
- [ ] Nuova installazione: CLOSE = **SEND ×1, NEXT ×1, CHIUDI**, non PLAY. Le sequenze CLOSE precedentemente salvate devono rimanere intatte.
- [ ] Creare una nuova etichetta con X/Y vuote e salvare senza errori; il salvataggio non deve innescare clic.
- [ ] Inserire in una sequenza il **Clic** su un’etichetta senza coordinate: Salva deve riuscire, ma mettere in pausa lo scheduler e indicare le coordinate mancanti.
- [ ] Tentare **Riprendi automazione** con Clic senza coordinate: deve essere bloccato con messaggio esplicito.
- [ ] Assegnare coordinate valide alle etichette necessarie, salvare e riavviare: il pulsante diventa eseguibile; quelli non utilizzati possono rimanere vuoti.
- [ ] Inserire **Apri** come prima azione di START: il programma si apre una volta, poi proseguono i clic.
- [ ] Spostare **Apri** più avanti nella sequenza con una **Attesa** precedente: la prima attesa deve precedere l’apertura.
- [ ] Aprire manualmente il programma e usare il test di **Apri**: non deve avviare una seconda istanza.
- [ ] Importare una sequenza START vecchia senza Apri: deve continuare ad aprire Caster implicitamente.
- [ ] Premere **Default**: ritorno alle sole 13 etichette vuote, sequenze esistenti preservate; salvare mette in pausa se i loro Clic sono senza X/Y.
- [ ] Verificare che **Reset pulsanti e sequenze** sia distinto da Default, con conferma e backup.
- [ ] Cambiare il valore X/Y in vuoto, salvare, riaprire e controllare che rimanga vuoto.
- [ ] Verificare il nuovo pulsante Default a 640×640 e a finestra massimizzata; righe ListView con altezza invariata.

## Calendario e conflitti

- [ ] Schedulazione **Sabato e Domenica 00:01–02:00**: valida.
- [ ] Schedulazione **Venerdì 23:00–Sabato 02:00**: valida e correttamente mostrata `(+1g)`.
- [ ] Due schedulazioni del venerdì 23:00–02:00 e sabato 01:00–03:00: **rifiutate**, perché sovrapposte.
- [ ] Venerdì 23:00–02:00 e sabato 02:00–04:00: consentite (intervalli contigui, ma testare margini reali).
- [ ] Schedulazioni sovrapposte con una **disattivata**: consentite; attivandola: rifiutate.
- [ ] Eccezione 31 dicembre 2026, 23:00–02:00: fine 1 gennaio 2027 alle 02:00.
- [ ] Eccezione 1 gennaio 2027 che si sovrappone alla precedente: rifiutata.
- [ ] Una data extra già inclusa nel giorno settimanale non genera due avvii.
- [ ] Duplica crea copia **disattivata**, non modifica l'originale.
- [ ] Modifica/elimina/attiva/disattiva si salvano e riappaiono dopo riavvio.

## Motore e sessione

- [ ] Con programma chiuso e desktop sbloccato, programmare START tra 3–4 minuti e CLOSE 2–3 minuti dopo (sufficienti per la sequenza completa).
- [ ] Nascondere il pannello nella tray. Attendere log `TRIGGER START` e `OK START`.
- [ ] Minimizzare CasterLive DJ; controllare `TRIGGER CLOSE`, `CLIC SEND`, `CLIC NEXT`, `FINESTRA CHIUSA`, `OK CLOSE`.
- [ ] Ripetere con un secondo evento non sovrapposto **nello stesso giorno**; deve partire regolarmente.
- [ ] Riavviare il Worker quando la sessione è `running`; deve **ricordare la chiusura**.
- [ ] Dopo chiusura riuscita, non deve ripetere SEND per la stessa sessione.
- [ ] Con Caster aperto manualmente, START programmato deve essere bloccato.
- [ ] Sospendi automazione impedisce nuovi eventi; Riprendi abilita di nuovo il Worker.
- [ ] Con desktop Windows bloccato: non devono essere eseguiti clic non verificabili; al rientro controllare eventuali errori.
- [ ] In stato di errore post-clic, non deve esserci ripetizione automatica dello stesso evento.
- [ ] Durante una sessione attiva, modifiche a calendario, programma, pulsanti e reset devono essere rifiutate.

## Distribuzione

- [ ] Avvio diretto `.ahk` senza BAT o PowerShell; in tray dopo login Windows.
- [ ] Tema scuro e leggibile anche a DPI 125%; righe delle ListView sempre a altezza fissa.
- [ ] Nessun file personale INI, runtime o log incluso nello ZIP GitHub.
- [ ] `README`, `LICENSE`, `.gitignore` e sorgenti inclusi.

**Non segnare la release come stabile finché l'intero ciclo non è stato verificato su Windows.**

## Test di calendario senza CasterLive DJ

Per verificare automaticamente le regole sugli intervalli, apri `tests/schedule_cases.ahk` con **AutoHotkey v2**. Il test non esegue clic né apre CasterLive DJ. Controlla casi a cavallo della mezzanotte, date extra, intervalli contigui e conflitti. **Non sostituisce** un test reale del Worker.
