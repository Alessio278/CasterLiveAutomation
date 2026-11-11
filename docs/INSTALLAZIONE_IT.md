# Installazione e configurazione (Windows)

## Requisiti

- Windows 10 o 11, sessione utente connessa e desktop **sbloccato** quando avvengono i clic.
- [AutoHotkey v2](https://www.autohotkey.com/) (non la versione 1).
- CasterLive DJ installato separatamente.
- Una cartella scrivibile, per esempio `Documenti\CasterLiveAutomation`.

## Installazione

1. Scarica lo ZIP della release dalla sezione **Releases** di GitHub, oppure **Code → Download ZIP** per il repository intero.
2. Estrai lo ZIP in una cartella, senza avviare file dall'archivio compresso.
3. Assicurati che `CasterLiveAutomation_V5.ahk`, `CasterLiveAutomation_Worker.ahk` e `CasterLiveAutomation_ScheduleLib.ahk` si trovino **nella stessa cartella**.
4. Fai doppio clic su `CasterLiveAutomation_V5.ahk`.
5. Al primo avvio il programma è **IN PAUSA** e non contiene schedulazioni.
6. Imposta il percorso di `CasterLive DJ.exe`, crea e abilita la schedulazione desiderata e registra i pulsanti effettivamente usati.
7. Verifica le sequenze predefinite: **AVVIO** `APRI → LOGIN → STOP ×3 → SEND`, **CHIUSURA** `SEND → NEXT → CHIUDI`.
8. Premi **Riprendi automazione** soltanto quando il sistema è configurato. Non ripetere SEND mentre una trasmissione è attiva.

Per programmare venerdì 23:00 → sabato 02:00, seleziona **venerdì** come giorno dell'avvio. Per una data speciale, scegli la **data in cui parte** la sequenza.

## Avvio con Windows

L'app può creare un collegamento in Esecuzione automatica. L'avvio avviene dopo l'accesso al proprio account Windows, non prima. I clic necessitano della sessione sbloccata. Non lasciare in funzione una versione precedente contemporaneamente.

## Aggiornamento

Conserva una copia dell'installazione funzionante, chiudi pannello e Worker e controlla SEND; sostituisci soltanto gli script `.ahk`, mantenendo i file INI privati. Per aggiornare da nomi precedenti consulta [MIGRATION.md](MIGRATION.md).

## Diagnostica

Nella sezione **Attività e diagnosi** trovi gli eventi del Worker e gli errori. Per segnalare un bug non pubblicare file INI, log interi o percorsi personali: invia soltanto righe utili con informazioni private oscurate. Consulta [TROUBLESHOOTING.md](TROUBLESHOOTING.md) e [TEST.md](TEST.md).
