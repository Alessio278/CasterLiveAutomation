# Architettura di CasterLiveAutomation 0.5 (sorgenti interni V5)

## Componenti

- `CasterLiveAutomation_V5.ahk`: GUI, coordinate e editor delle sequenze. Gestisce il file delle schedulazioni e la diagnostica, non esegue il controllo orario automatico.
- `CasterLiveAutomation_ScheduleLib.ahk`: libreria condivisa per serializzazione, validazione, risoluzione di ricorrenze/date eccezionali e controllo conflitti.
- `CasterLiveAutomation_Worker.ahk`: motore indipendente (timer a 5 secondi) con funzioni di esecuzione dei clic ricavate dalla V3.11 funzionante.

## Schema

Le schedulazioni sono in `CasterLiveAutomation_Schedules.ini`, **separato** dalla configurazione principale e dallo stato runtime. Alla prima esecuzione il file viene creato con `Ids=` vuoto; **nessuna schedulazione viene aggiunta né importata automaticamente**. Ogni voce registra `Id`, `Name`, `Enabled`, `StartTime`, `EndTime`, `Days`, `Dates`. Le date in `Dates` sono giorni di **inizio** dell'evento e si sommano alle ricorrenze.

Il sistema usa un solo programma `Config.ExePath` e sequenze `StepsStart`/`StepsClose`, condivisi da tutte le righe. Non esegue schedulazioni simultanee.

La libreria riconosce un intervallo `23:00–02:00` come fine nel giorno successivo. Gli intervalli durano sempre meno di 24 ore. Il validator confronta le ricorrenze su due settimane e ciascuna eccezione con i giorni vicini, distinguendo gli eventi contigui da quelli sovrapposti.

## Stato e idempotenza

`CasterLiveAutomation_Runtime.ini` conserva lo stato `idle → starting → running → closing → complete`, il token dell'evento e la fine pianificata. `starting`/`closing` diventano errori incerti se una sequenza non si completa. Il tentativo viene registrato **prima** dei clic. Lo stato `running` persiste tra riavvii del Worker. Un evento già tentato non viene ritentato automaticamente.

Durante `running`, il Worker controlla esclusivamente la fine della sessione attiva. La chiusura non può partire senza START automatico riuscito. L'operatore può ripristinare manualmente uno stato incerto solo dopo aver chiuso CasterLive DJ e verificato SEND.

## Limiti

- Il programma richiede desktop Windows interattivo sbloccato e non può verificare lo stato reale della trasmissione.
- Finestra di tolleranza START: 180 secondi; CLOSE: 900 secondi.
- La compatibilità con fusi orari diversi, cambi ora legale e sospensione prolungata di Windows deve essere verificata in collaudo; il scheduler usa l'orologio locale Windows.
- Il Worker V5 è nuovo per la scelta del momento di avvio/chiusura. Solo le routine dei clic derivano dal Worker V3.11.

## Azioni e etichette (base RC2 aggiornata)

Le sezioni INI `StepsStart` e `StepsClose` utilizzano `kind|button|repeat|pause`.
I valori `kind` supportati sono `open`, `click`, `wait`, `close`. Il passo `open||1|0` apre il programma nel punto scelto, mentre gli START storici senza `open` continuano ad aprire l'eseguibile automaticamente. Un pulsante senza coordinate può essere presente in `Buttons.Names` e non in `Points`, ma i passi `click` corrispondenti vengono bloccati dalla prevalidazione.

Al primo avvio, `V3.Paused=1` e il pannello propone **Riprendi automazione**: il Worker non avvia il timer operativo finché l'utente non abilita l'automazione. Se il calendario viene ricreato perché assente, lo stato viene nuovamente messo in pausa. Il comando Riprendi richiede almeno una schedulazione attiva, un eseguibile valido e coordinate valide per i clic previsti. Le sequenze predefinite sono START `open, LOGIN, STOP×3, SEND` e CLOSE `SEND, NEXT, close`; le sequenze esistenti non vengono sovrascritte.

La GUI permette il salvataggio di una configurazione incompleta, segnala gli eventuali passi non pronti e imposta `V3.Paused=1` prima di aggiornare l'INI. Il Worker verifica le coordinate richieste prima di eseguire uno START o un CLOSE. La logica di calendario in `CasterLiveAutomation_ScheduleLib.ahk` non è stata modificata.
