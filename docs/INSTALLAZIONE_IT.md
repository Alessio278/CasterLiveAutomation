# Installazione - CasterLiveAutomation 1.0

## Avvio da sorgenti

1. Installa [AutoHotkey v2](https://www.autohotkey.com/) e CasterLive DJ separatamente.
2. Metti `CasterLiveAutomation.ahk`, `CasterLiveAutomation_Worker.ahk` e `CasterLiveAutomation_ScheduleLib.ahk` nella stessa cartella scrivibile.
3. Apri `CasterLiveAutomation.ahk` con doppio clic. Non servono BAT o PowerShell per avviarlo.
4. Una nuova installazione parte **IN PAUSA e senza schedulazioni**. Seleziona il programma, imposta orari e giorni e registra le coordinate dei soli pulsanti necessari.
5. Controlla START `APRI -> LOGIN -> STOP x3 -> SEND` e CLOSE `SEND -> NEXT -> CHIUDI`, poi premi **Riprendi automazione**.
6. Esegui un ciclo di test presidiato senza diretta attiva. Windows deve essere acceso e sbloccato.

Non eliminare o caricare su GitHub i tuoi INI, i log e i file di runtime. Se aggiorni dalla V5, fai prima un backup e chiudi tutti i vecchi processi AutoHotkey.

## Pacchetto EXE futuro

Lo script Windows `scripts/Build-Windows.ps1` prepara due eseguibili indipendenti da un'installazione AutoHotkey locale. Devono restare insieme nella stessa cartella: GUI e Worker. **Non è ancora stato verificato in questa sessione** e non costituisce una release stabile. Vedi [WINDOWS_BUILD.md](WINDOWS_BUILD.md).
