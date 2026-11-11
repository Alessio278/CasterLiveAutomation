# CasterLiveAutomation

**Automazione Windows per CasterLive DJ, sviluppata con AutoHotkey v2.**

[English](README.md) · [Installazione](docs/INSTALLAZIONE_IT.md) · [Sicurezza dei clic](docs/CLICK_SAFETY.md) · [Contributi](CONTRIBUTING.md)

**Versione 0.5 — Pre-release (`v0.5.0-rc.1`).** Creato da Alessio Natalucci. Progetto indipendente, non affiliato ai produttori di CasterLive DJ. Il software di terze parti non è incluso.

> [!WARNING]
> **Pre-release 0.5:** la più recente correzione della chiusura con finestra minimizzata non è stata ancora verificata con un test completo su Windows. Prima di utilizzare il sistema per una diretta non presidiata, esegui i test di [docs/TEST.md](docs/TEST.md) senza trasmissione attiva. Lo stato verde non certifica che l'audio sia in onda.

## Funzionalità

- **Schedulazioni multiple** non sovrapposte, ognuna con nome, giorni settimanali, date eccezionali, orario di avvio e di chiusura.
- Intervalli **a cavallo della mezzanotte**: scegli il giorno di inizio; una chiusura con orario inferiore cade nel giorno seguente.
- **Sequenze modificabili** con azioni `APRI`, `CLIC`, `ATTESA`, `CHIUDI`, ripetizioni e pause.
- **13 etichette predefinite**, tutte senza coordinate iniziali: `LOGIN`, `MUTE_MASTER`, `NEXT`, `PLAY`, `STOP`, `RESTART`, `SEND`, `RECEIVE`, `MONITOR`, `MONITOR_MIC`, `MONITOR_AUDIO`, `SETTINGS`, `ENTER`.
- **Clic prudenti**: ripristino della finestra minimizzata, ricalcolo delle coordinate dopo lo spostamento, blocco se la finestra non è identificata in modo sicuro.
- **Pannello scuro**, area di notifica, sezione Attività e diagnosi e selettore Italiano, English, Français, Español.
- **Primo avvio in pausa**, senza nessuna schedulazione preimpostata. Il pulsante Riprendi automazione abilita il calendario soltanto dopo la configurazione.

**Limite attuale:** le schedulazioni condividono il medesimo programma e le medesime sequenze START/CLOSE.

## Installazione rapida

1. Installa [AutoHotkey v2](https://www.autohotkey.com/) e, separatamente, CasterLive DJ.
2. Estrai lo ZIP sorgente della release in una cartella scrivibile; mantieni insieme tutti e tre i file `.ahk`.
3. Avvia `CasterLiveAutomation_V5.ahk` con doppio clic.
4. Imposta il percorso del programma, aggiungi una schedulazione e registra le coordinate dei pulsanti utilizzati.
5. Controlla le sequenze: **START** `APRI → LOGIN → STOP ×3 → SEND`; **CLOSE** `SEND → NEXT → CHIUDI`.
6. Premi **Riprendi automazione** solo quando è tutto pronto. Esegui un test di avvio e chiusura presidiato.

Leggi la [guida completa di installazione](docs/INSTALLAZIONE_IT.md) e il [piano di collaudo](docs/TEST.md).

Il nome dello script `CasterLiveAutomation_V5.ahk` viene mantenuto per compatibilità con i collegamenti di avvio Windows esistenti. **La versione pubblica è 0.5**, non 5.0.

## Privacy e sicurezza

L'applicazione non può verificare se la trasmissione sia realmente online. Per effettuare i clic, Windows deve essere acceso, con utente connesso e **desktop sbloccato**. Se CasterLive DJ cambia dimensioni o la finestra non viene identificata, l'operazione viene bloccata; non viene eseguito un clic casuale sul desktop.

I file `CasterLiveAutomation_Settings.ini`, `CasterLiveAutomation_Schedules.ini`, `CasterLiveAutomation_Runtime.ini` e `CasterLiveAutomation_Log.txt` contengono dati locali e **non devono essere caricati su GitHub**.

## Documentazione

- [Architettura](docs/ARCHITECTURE.md)
- [Guida alle lingue](docs/LANGUAGES.md)
- [Sicurezza dei clic](docs/CLICK_SAFETY.md)
- [Limitazioni conosciute](docs/KNOWN_LIMITATIONS.md)
- [Come contribuire](CONTRIBUTING.md)
- [Cronologia](CHANGELOG.md)

## Licenza

Codice sorgente con licenza [MIT](LICENSE). Copyright © 2026 Alessio Natalucci. CasterLive DJ rimane un prodotto di terze parti, non incluso nel repository.
