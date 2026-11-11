# Aggiornamento e nomi file — CasterLiveAutomation 0.5 pre-release

Il nome ufficiale del progetto, della finestra e del collegamento di avvio Windows è **CasterLiveAutomation**.
Il programma che viene controllato può continuare a chiamarsi **CasterLive DJ**: non rinominare il suo `.exe`.

## File correnti

- `CasterLiveAutomation_V5.ahk` — pannello principale
- `CasterLiveAutomation_Worker.ahk` — motore indipendente
- `CasterLiveAutomation_ScheduleLib.ahk` — libreria condivisa
- `CasterLiveAutomation_Settings.ini` — eseguibile, pulsanti, sequenze, lingua e pausa
- `CasterLiveAutomation_Schedules.ini` — calendari e date extra
- `CasterLiveAutomation_Runtime.ini` — stato di sessione / protezione SEND
- `CasterLiveAutomation_Log.txt` — attività e diagnosi

## Migrazione da versioni precedenti

1. **Sospendi l'automazione e verifica che CasterLive DJ non trasmetta.** Chiudi il pannello e il Worker precedenti. Non eseguire due versioni contemporaneamente.
2. Estrai i nuovi file `.ahk` nella cartella usata in precedenza (oppure trasferisci i vecchi INI nella nuova cartella, senza rinominarli).
3. Avvia `CasterLiveAutomation_V5.ahk`.
4. Il programma copia automaticamente, **solo se il nuovo file manca**, i file precedenti:
   - `CasterLiveDJ_Configurazione.ini` → `CasterLiveAutomation_Settings.ini`
   - `CasterAutomation_Schedules.ini` → `CasterLiveAutomation_Schedules.ini`
   - `CasterAutomation_Runtime.ini` → `CasterLiveAutomation_Runtime.ini`
   - `CasterLiveDJ_Log.txt` → `CasterLiveAutomation_Log.txt`
5. Controlla schedulazioni e stato in *Attività e diagnosi*. Il collegamento di avvio Windows viene aggiornato a `CasterLiveAutomation.lnk` se autorizzato nelle impostazioni.

La copia è **non distruttiva**: i vecchi INI non vengono eliminati o sovrascritti. Se un file con il nuovo nome esiste già, quello è considerato la fonte autorevole e non viene sostituito dal vecchio. Non cancellare lo stato runtime durante una sessione attiva.

## Prima installazione pulita

Se nessun file preesistente è presente, il programma crea `CasterLiveAutomation_Settings.ini` con **IN PAUSA** e `CasterLiveAutomation_Schedules.ini` senza alcuna schedulazione. È necessario configurare i pulsanti e premere **Riprendi automazione**.

## GitHub

I file `.ini`, i log e i backup sono **personali** e ignorati da `.gitignore`. Non aggiungerli alla repository o agli ZIP di distribuzione.
