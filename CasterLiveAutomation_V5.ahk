#Requires AutoHotkey v2.0
#SingleInstance Force
#Include CasterLiveAutomation_ScheduleLib.ahk
Persistent()
SetTitleMatchMode(2)
CoordMode("Mouse", "Client")
SendMode("Event")
SetMouseDelay(100)

; CasterLiveAutomation v0.5.0-rc.1 - pre-release; internal protocol V5.
; Worker V5: le coordinate client sono ricalcolate e verificate prima di ogni clic.
; Richiede AutoHotkey v2 e una sessione Windows interattiva e sbloccata.

gCfg := A_ScriptDir "\CasterLiveAutomation_Settings.ini"
gLog := A_ScriptDir "\CasterLiveAutomation_Log.txt"
gShortcut := A_Startup "\CasterLiveAutomation.lnk"
gMain := ""
gShownOnce := false
gTabs := ""
gControls := Map()
gPoints := Map()
gPointSizes := Map()
gLanguage := "it"
gPointNames := []
gStartSteps := []
gCloseSteps := []
gActiveDialog := ""
gCaptureName := ""
gBusy := false
gDirty := false
gPaused := true
gLastError := ""
gLastDisplay := ""
gLastClockKey := ""
gLastScheduleCheck := "mai"
gLastScheduleNote := "In attesa del primo controllo"
gLastScheduledAction := "Nessun evento eseguito in questa sessione"
gWorkerScript := A_ScriptDir "\CasterLiveAutomation_Worker.ahk"
gWorkerLastLaunch := ""
gScheduleFile := A_ScriptDir "\CasterLiveAutomation_Schedules.ini"
gRuntimeFile := A_ScriptDir "\CasterLiveAutomation_Runtime.ini"
gScheduleRows := []
gScheduleEditor := ""
gEditorDateList := []

try {
    CLAMigrateLegacyFiles(gCfg, gScheduleFile, gRuntimeFile, gLog)
    PrepareConfig()
    gLanguage := IniRead(gCfg, "UI", "Language", "it")
    if !RegExMatch(gLanguage, "^(it|en|fr|es)$")
        gLanguage := "it"
    InitializeFirstRunPause()
    LoadData()
    InitializeEmptySchedules()
    SValidateAll(SReadAll(gScheduleFile))
    gPaused := IniRead(gCfg, "V3", "Paused", "1") = "1"
    BuildWindow()
    ApplyUITranslations()
    RefreshSchedules()
    SetupTray()
    gControls["pauseButton"].Text := Tr(gPaused ? "Riprendi automazione" : "Sospendi automazione")
    ; Installazione del collegamento diretto: nessun BAT/PowerShell all'avvio.
    try {
        if IniRead(gCfg, "V3", "AutoStartDisabled", "0") != "1"
            EnsureStartupLink()
    } catch Error as e {
        LogLine("AVVISO: avvio con Windows non configurato: " e.Message)
        gLastError := "Impossibile configurare avvio con Windows: " e.Message
    }
    ; L'orologio è gestito dal worker separato, indipendente dal pannello.
    EnsureWorker()
    SetTimer(RefreshStatus, 15000)
    RefreshViews()
    RefreshStatus()
    inTray := false
    for arg in A_Args
        if (arg = "--tray" || arg = "--minimized")
            inTray := true
    if !inTray {
        gMain.Show("w640 h640 Center")
        gShownOnce := true
    } else
        LogLine("Avviata con Windows in area di notifica")
    LogLine("GUI v0.5.0 PRE-RELEASE PRONTA | " ScheduleNextSummary())
    ; Il worker controlla subito il calendario all'avvio.
} catch Error as e {
    MsgBox("Impossibile avviare CasterLiveAutomation:`n" e.Message "`nRiga " e.Line, "CasterLiveAutomation", "Icon!")
    ExitApp(1)
}

; -------------------------- CONFIGURAZIONE --------------------------
DefaultButtonLabels() {
    return StrSplit("LOGIN|MUTE_MASTER|NEXT|PLAY|STOP|RESTART|SEND|RECEIVE|MONITOR|MONITOR_MIC|MONITOR_AUDIO|SETTINGS|ENTER", "|")
}
DefaultButtonList() {
    return JoinArray(DefaultButtonLabels(), "|")
}
PrepareConfig() {
    global gCfg
    if !FileExist(gCfg)
        FileAppend("[Config]`r`n", gCfg, "UTF-16")
    if IniRead(gCfg, "Config", "ExePath", "") = ""
        IniWrite("", gCfg, "Config", "ExePath")
    if IniRead(gCfg, "Config", "Process", "") = ""
        IniWrite("CasterLive DJ.exe", gCfg, "Config", "Process")
    ; Il calendario V5 esiste soltanto in CasterLiveAutomation_Schedules.ini.
    ; Non creare ne' importare schedulazioni all'avvio.
    if IniRead(gCfg, "Buttons", "Names", "") = ""
        IniWrite(DefaultButtonList(), gCfg, "Buttons", "Names")
    if IniRead(gCfg, "StepsStart", "Count", "") = "" {
        IniWrite("4", gCfg, "StepsStart", "Count")
        IniWrite("open||1|0", gCfg, "StepsStart", "Step1")
        IniWrite("click|LOGIN|1|3000", gCfg, "StepsStart", "Step2")
        IniWrite("click|STOP|3|1000", gCfg, "StepsStart", "Step3")
        IniWrite("click|SEND|1|0", gCfg, "StepsStart", "Step4")
    }
    if IniRead(gCfg, "StepsClose", "Count", "") = "" {
        IniWrite("3", gCfg, "StepsClose", "Count")
        IniWrite("click|SEND|1|1000", gCfg, "StepsClose", "Step1")
        IniWrite("click|NEXT|1|1000", gCfg, "StepsClose", "Step2")
        IniWrite("close||1|0", gCfg, "StepsClose", "Step3")
    }
}


; Prima installazione: non avviare mai la schedulazione senza consenso.
; Un valore Paused già presente viene rispettato anche ai riavvii:
; 1 = fermo, 0 = l'utente ha scelto Riprendi automazione.
InitializeFirstRunPause() {
    global gCfg
    if IniRead(gCfg, "V3", "Paused", "__MISSING__") = "__MISSING__" {
        IniWrite("1", gCfg, "V3", "Paused")
        LogLine("PRIMO AVVIO: automazione IN PAUSA. Premere Riprendi automazione solo dopo la configurazione.")
    }
}

; Se il calendario non esiste, crearlo VUOTO (zero schedulazioni).
; Una nuova installazione non può avviarsi automaticamente.
; Se manca il file in una cartella gia' usata, il fail-safe sospende il Worker.
InitializeEmptySchedules() {
    global gCfg, gScheduleFile
    if SEnsureEmptySchedules(gScheduleFile) {
        IniWrite("1", gCfg, "V3", "Paused")
        LogLine("PRIMO CALENDARIO: zero schedulazioni; automazione IN PAUSA. Aggiungi una schedulazione prima di riprendere.")
    }
}

LoadData() {
    global gCfg, gPoints, gPointSizes, gPointNames, gStartSteps, gCloseSteps
    gPoints := Map()
    gPointSizes := Map()
    gPointNames := []
    names := StrSplit(IniRead(gCfg, "Buttons", "Names", DefaultButtonList()), "|")
    for name in names {
        name := Trim(name)
        if name != "" && !gPoints.Has(name) {
            gPoints[name] := IniRead(gCfg, "Points", name, "")
            gPointSizes[name] := IniRead(gCfg, "PointClientSize", name, "")
            gPointNames.Push(name)
        }
    }
    gStartSteps := ReadSteps("StepsStart")
    gCloseSteps := ReadSteps("StepsClose")


}

ReadSteps(section) {
    global gCfg
    rows := []
    count := IniRead(gCfg, section, "Count", "0") + 0
    Loop Min(100, Max(0, count)) {
        p := StrSplit(IniRead(gCfg, section, "Step" A_Index, ""), "|")
        if p.Length >= 4
            rows.Push(Map("kind", p[1], "button", p[2], "repeat", p[3] + 0, "pause", p[4] + 0))
    }
    return rows
}

SaveData(*) {
    global gCfg, gControls, gPoints, gPointSizes, gPointNames, gStartSteps, gCloseSteps, gDirty, gRuntimeFile, gScheduleFile, gPaused
    if SSessionActive() {
        MsgBox("Impossibile cambiare pulsanti o programma mentre una sessione è attiva o incerta. Verifica CasterLive DJ e attendi la chiusura.", "CasterLiveAutomation", "Icon!")
        return false
    }
    try {
        exe := Trim(gControls["exe"].Value)
        ; La configurazione puo' essere salvata prima di aver installato Caster.
        ; Se manca l'eseguibile, la programmazione rimane in pausa.
        ; I nomi senza coordinate si possono salvare: la verifica operativa
        ; resta obbligatoria in CheckSteps(..., true) e nel Worker.
        CheckSteps(gStartSteps, "start", false)
        CheckSteps(gCloseSteps, "close", false)
        SValidateAll(SReadAll(gScheduleFile))
        missingPoints := UnconfiguredSequencePoints()
        if !FileExist(exe)
            missingPoints.Push("PROGRAMMA: eseguibile non trovato o non impostato")
        if missingPoints.Length {
            ; Disarmo PRIMA di pubblicare il nuovo INI: il Worker non deve
            ; eseguire una sequenza che non puo' completare.
            IniWrite("1", gCfg, "V3", "Paused")
            gPaused := true
            gControls["pauseButton"].Text := Tr("Riprendi automazione")
        }
        IniWrite(exe, gCfg, "Config", "ExePath")
        if exe != "" {
            SplitPath(exe, &processName)
            IniWrite(processName, gCfg, "Config", "Process")
        }
        names := []
        ; Il set di pulsanti e' la fonte unica: nessuna vecchia coordinata orfana.
        IniDelete(gCfg, "Points")
        IniDelete(gCfg, "PointClientSize")
        for name in gPointNames {
            coord := gPoints[name]
            names.Push(name)
            if coord != "" {
                IniWrite(coord, gCfg, "Points", name)
                if gPointSizes.Has(name) && gPointSizes[name] != ""
                    IniWrite(gPointSizes[name], gCfg, "PointClientSize", name)
            }
        }
        IniWrite(JoinArray(names, "|"), gCfg, "Buttons", "Names")
        WriteSteps("StepsStart", gStartSteps)
        WriteSteps("StepsClose", gCloseSteps)
        gDirty := false
        LogLine("Configurazione programma, coordinate e sequenze salvata")
        try EnsureWorker()
        catch Error as err
            LogLine("ERRORE avvio motore: " err.Message)
        RefreshStatus()
        if missingPoints.Length
            MsgBox("Salvataggio effettuato, ma l'automazione e' stata sospesa. Coordinate mancanti o pulsanti rimossi in queste azioni:`n" JoinArray(missingPoints, "`n") "`n`nRegistra i pulsanti necessari, salva e riprendi l'automazione.", "Pulsanti non operativi", "Icon!")
        else
            MsgBox("Programma e sequenze salvati. Le schedulazioni si salvano singolarmente nell'editor.", "CasterLiveAutomation", "Iconi")
        return true
    } catch Error as e {
        MsgBox("Impossibile salvare:`n" e.Message, "Controllo configurazione", "Icon!")
        return false
    }
}

UnconfiguredSequencePoints() {
    global gPoints, gPointSizes, gStartSteps, gCloseSteps
    missing := []
    for flow in ["start", "close"] {
        rows := flow = "start" ? gStartSteps : gCloseSteps
        for st in rows {
            if st["kind"] != "click"
                continue
            name := st["button"]
            coord := gPoints.Has(name) ? gPoints[name] : ""
            if !RegExMatch(coord, "^-?\d+,-?\d+$") || !gPointSizes.Has(name) || gPointSizes[name] = ""
                missing.Push(StrUpper(flow) ": " name " (registrazione da rifare per sicurezza)")
        }
    }
    return missing
}

WriteSteps(section, steps) {
    global gCfg
    previous := IniRead(gCfg, section, "Count", "0") + 0
    IniWrite(steps.Length, gCfg, section, "Count")
    for index, step in steps
        IniWrite(step["kind"] "|" step["button"] "|" step["repeat"] "|" step["pause"], gCfg, section, "Step" index)
    if previous > steps.Length
        Loop previous - steps.Length
            IniDelete(gCfg, section, "Step" (steps.Length + A_Index))
}


; -------------------------- INTERFACCIA ----------------------------
BuildWindow() {
    global gMain, gTabs, gControls, gCfg

    ; CasterLiveAutomation v0.5: apertura 640x640 (-20% per lato).
    ; Le ListView mantengono la stessa altezza di riga; si ridimensiona solo il riquadro.
    gMain := Gui("+Resize +MinSize640x640", "CasterLiveAutomation  |  v0.5 Pre-release")
    gMain.BackColor := "151515"
    gMain.SetFont("s9 cF1F1F1", "Segoe UI")

    gControls["title"] := gMain.Add("Text", "x18 y10 w460 h29", "CASTERLIVEAUTOMATION")
    gControls["title"].SetFont("s17 bold cF8F8F8", "Segoe UI")
    gControls["version"] := gMain.Add("Text", "x510 y15 w106 h20 Right", "v0.5 PRE")
    gControls["version"].SetFont("s9 bold cB5B5B5")
    gControls["brandSub"] := gMain.Add("Text", "x20 y40 w595 h19", "Creato da Alessio Natalucci")
    gControls["brandSub"].SetFont("s9 cABABAB")
    gControls["status"] := gMain.Add("Text", "x20 y64 w600 h24", "Controllo stato...")
    gControls["status"].SetFont("s10 bold cDCDCDC")
    gControls["details"] := gMain.Add("Text", "x20 y90 w600 h18", "")
    gControls["details"].SetFont("s8 cAAAAAA")
    gControls["headerRule"] := gMain.Add("Text", "x18 y113 w604 h2 Background505050", "")

    gTabs := gMain.Add("Tab3", "x12 y121 w616 h455 Background1D1D1D -Wrap", ["Panoramica", "Schedulazioni", "Sequenze", "Pulsanti"])
    gTabs.SetFont("s9 bold cF4F4F4", "Segoe UI")
    ; Dopo il cambio scheda forzare il ridisegno anche dei figli di Tab3.
    gTabs.OnEvent("Change", (*) => SetTimer(RedrawLocalizedGUI, -50))

    gTabs.UseTab(1)
    gControls["heroLabel"] := gMain.Add("Text", "x28 y158 w335 h18", "PROSSIMA ESECUZIONE")
    gControls["heroLabel"].SetFont("s9 bold cADADAD")
    gControls["languageLabel"] := gMain.Add("Text", "x393 y157 w65 h19", "Lingua:")
    gControls["languageLabel"].SetFont("s9 cC9C9C9")
    ; r4, non h28: per DropDownList h limita anche l'altezza del menu aperto.
    gControls["languageSelect"] := gMain.Add("DropDownList", "x465 y152 w147 r4 Choose" UILanguageIndex(), ["Italiano", "English", "Français", "Español"])
    gControls["languageSelect"].SetFont("s9 c202020", "Segoe UI")
    gControls["languageSelect"].OnEvent("Change", LanguageChanged)
    gControls["nextEvent"] := gMain.Add("Text", "x28 y178 w568 h32", "Calcolo prossimo evento...")
    gControls["nextEvent"].SetFont("s13 bold cF2F2F2")
    gControls["overviewHead"] := gMain.Add("Text", "x28 y211 w568 h18", "STATO DELLA PROGRAMMAZIONE")
    gControls["overviewHead"].SetFont("s9 bold cADADAD")
    ; Riquadro a scorrimento: i messaggi lunghi non coprono più i pulsanti.
    gControls["overview"] := gMain.Add("Edit", "x28 y231 w584 h140 ReadOnly +VScroll Background252525 cEDEDED", "")
    gControls["overview"].SetFont("s9", "Consolas")

    gControls["refreshButton"] := gMain.Add("Button", "x28 y385 w185 h32", "Diagnosi")
    gControls["refreshButton"].OnEvent("Click", ShowScheduleDiagnostics)
    gControls["checkButton"] := gMain.Add("Button", "x223 y385 w185 h32", "Aggiorna stato")
    gControls["checkButton"].OnEvent("Click", RefreshStatus)
    gControls["pauseButton"] := gMain.Add("Button", "x418 y385 w194 h32", "Riprendi automazione")
    gControls["pauseButton"].OnEvent("Click", TogglePause)

    gControls["maintenanceLabel"] := gMain.Add("Text", "x28 y429 w584 h18", "MANUTENZIONE (CON CONFERMA)")
    gControls["maintenanceLabel"].SetFont("s9 bold cADADAD")
    gControls["resetWindows"] := gMain.Add("Button", "x28 y450 w286 h32", "Reset impostazioni Windows")
    gControls["resetWindows"].OnEvent("Click", ResetWindowsSettings)
    gControls["resetButtons"] := gMain.Add("Button", "x326 y450 w286 h32", "Reset pulsanti e sequenze")
    gControls["resetButtons"].OnEvent("Click", ResetButtonConfig)
    gControls["overviewHelp"] := gMain.Add("Text", "x28 y494 w584 h52",
        "Il motore resta attivo anche con pannello nascosto. La spia ATTIVO non certifica lo streaming.`nPer i clic, Windows deve essere sbloccato. I test agiscono realmente su SEND.")
    gControls["overviewHelp"].SetFont("s9 cAAAAAA")

    gTabs.UseTab(2)
    gControls["exeLabel"] := gMain.Add("Text", "x28 y157 w550 h19", "PROGRAMMA CONTROLLATO (COMUNE A TUTTE LE SCHEDULAZIONI)")
    gControls["exeLabel"].SetFont("s9 bold cADADAD")
    gControls["exe"] := gMain.Add("Edit", "x28 y180 w450 h28 Background262626 cF1F1F1", IniRead(gCfg, "Config", "ExePath", ""))
    gControls["browse"] := gMain.Add("Button", "x492 y180 w120 h28", "Sfoglia...")
    gControls["browse"].OnEvent("Click", BrowseExe)
    gControls["exe"].OnEvent("Change", MarkDirty)
    gControls["scheduleTitle"] := gMain.Add("Text", "x28 y220 w584 h22", "SCHEDULAZIONI")
    gControls["scheduleTitle"].SetFont("s10 bold cEAEAEA")
    gControls["scheduleList"] := gMain.Add("ListView", "x28 y246 w584 h210 Background222222 cECECEC -Multi NoSortHdr", ["Stato", "Nome", "Giorni", "Inizio", "Fine", "Date extra"])
    gControls["scheduleList"].SetFont("s9", "Segoe UI")
    gControls["scheduleList"].OnEvent("DoubleClick", (*) => SEditSelected())
    gControls["scheduleButtons"] := []
    labels := ["Aggiungi", "Modifica", "Duplica", "Attiva / Disattiva", "Elimina"]
    callbacks := [SAddNew, SEditSelected, SDuplicate, SToggleSelected, SDeleteSelected]
    for i, label in labels {
        btn := gMain.Add("Button", "x" (28 + (i-1)*118) " y464 w110 h31", label)
        btn.OnEvent("Click", callbacks[i])
        gControls["scheduleButtons"].Push(btn)
    }
    gControls["scheduleHelp"] := gMain.Add("Text", "x28 y506 w584 h51",
        "I giorni selezionati sono quelli dell'AVVIO. 23:00–02:00 termina il giorno successivo.`nDate extra = altri giorni di avvio. Conflitti bloccati al salvataggio.")
    gControls["scheduleHelp"].SetFont("s9 cAAAAAA")

    gTabs.UseTab(3)
    gControls["startLabel"] := gMain.Add("Text", "x28 y157 w584 h21", "SEQUENZA DI AVVIO")
    gControls["startLabel"].SetFont("s10 bold cEEEEEE")
    gControls["startList"] := gMain.Add("ListView", "x28 y180 w584 h110 Background222222 cECECEC -Multi NoSortHdr", ["#", "Tipo", "Pulsante", "Rip.", "Pausa (ms)"])
    gControls["startList"].SetFont("s9", "Segoe UI")
    gControls["startList"].OnEvent("DoubleClick", (*) => EditStep("start"))
    gControls["startActions"] := []
    MakeStepButtons("start", 298)
    gControls["closeLabel"] := gMain.Add("Text", "x28 y341 w584 h21", "SEQUENZA DI CHIUSURA  /  DOPO AVVIO RIUSCITO")
    gControls["closeLabel"].SetFont("s10 bold cEEEEEE")
    gControls["closeList"] := gMain.Add("ListView", "x28 y364 w584 h110 Background222222 cECECEC -Multi NoSortHdr", ["#", "Tipo", "Pulsante", "Rip.", "Pausa (ms)"])
    gControls["closeList"].SetFont("s9", "Segoe UI")
    gControls["closeList"].OnEvent("DoubleClick", (*) => EditStep("close"))
    gControls["closeActions"] := []
    MakeStepButtons("close", 482)

    gTabs.UseTab(4)
    gControls["pointsHeading"] := gMain.Add("Text", "x28 y157 w584 h21", "PULSANTI  /  COORDINATE RELATIVE ALLA FINESTRA")
    gControls["pointsHeading"].SetFont("s10 bold cEEEEEE")
    gControls["pointList"] := gMain.Add("ListView", "x28 y182 w584 h300 Background222222 cECECEC -Multi NoSortHdr", ["Pulsante", "X", "Y"])
    gControls["pointList"].SetFont("s9", "Segoe UI")
    gControls["pointList"].OnEvent("DoubleClick", (*) => EditPoint())
    gControls["addPoint"] := gMain.Add("Button", "x28 y493 w102 h32", "Aggiungi")
    gControls["addPoint"].OnEvent("Click", AddPoint)
    gControls["deletePoint"] := gMain.Add("Button", "x139 y493 w102 h32", "Rimuovi")
    gControls["deletePoint"].OnEvent("Click", RemovePoint)
    gControls["editPoint"] := gMain.Add("Button", "x250 y493 w112 h32", "Modifica X / Y")
    gControls["editPoint"].OnEvent("Click", EditPoint)
    gControls["capturePoint"] := gMain.Add("Button", "x371 y493 w146 h32", "Registra col mouse")
    gControls["capturePoint"].OnEvent("Click", StartCapture)
    gControls["defaultPoints"] := gMain.Add("Button", "x526 y493 w86 h32", "Default")
    gControls["defaultPoints"].OnEvent("Click", RestoreDefaultLabels)
    gControls["pointHelp"] := gMain.Add("Text", "x28 y538 w584 h23", "Senza X/Y: etichetta salvabile, clic non eseguibile. Registra: Ctrl+Maiusc+C.")
    gControls["pointHelp"].SetFont("s9 cAAAAAA")

    gTabs.UseTab()

    gControls["save"] := gMain.Add("Button", "x12 y592 w80 h33 Default", "Salva")
    gControls["save"].OnEvent("Click", SaveData)
    gControls["startup"] := gMain.Add("Button", "x102 y592 w126 h33", "Avvio Windows")
    gControls["startup"].OnEvent("Click", ToggleStartup)
    gControls["testStart"] := gMain.Add("Button", "x238 y592 w96 h33", "Test avvio")
    gControls["testStart"].OnEvent("Click", (*) => RunTest("start"))
    gControls["testClose"] := gMain.Add("Button", "x344 y592 w104 h33", "Test chiusura")
    gControls["testClose"].OnEvent("Click", (*) => RunTest("close"))
    gControls["openLog"] := gMain.Add("Button", "x458 y592 w82 h33", "Attività e diagnosi")
    gControls["openLog"].OnEvent("Click", OpenLog)
    gControls["exit"] := gMain.Add("Button", "x550 y592 w78 h33", "Esci")
    gControls["exit"].OnEvent("Click", ReallyExit)

    gMain.OnEvent("Close", HideWindow)
    gMain.OnEvent("Escape", HideWindow)
    gMain.OnEvent("Size", ResizeWindow)
    ApplyDarkAppearance()
}

; Dark mode: colori nativi supportati + miglioramento opzionale di Windows.
; Se un tema di Windows non supporta i controlli scuri, l'app rimane utilizzabile.
ApplyDarkAppearance() {
    global gMain, gTabs, gControls
    try DllCall("uxtheme\#135", "Int", 2, "Int")
    try DllCall("uxtheme\#133", "Ptr", gMain.Hwnd, "Int", 1, "Int")
    try DllCall("uxtheme\SetWindowTheme", "Ptr", gTabs.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0, "Int")
    for key, ctrl in gControls {
        if ctrl is Array {
            for button in ctrl
                ApplyControlTheme(button)
        } else
            ApplyControlTheme(ctrl)
    }
    dark := Buffer(4, 0)
    NumPut("Int", 1, dark)
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", gMain.Hwnd, "UInt", 20, "Ptr", dark, "UInt", 4, "Int")
}
ApplyControlTheme(ctrl) {
    if !HasProp(ctrl, "Hwnd")
        return
    ; Combo e Button: tema Windows neutro (grigio), testo ad alto contrasto.
    ; La forzatura DarkMode_Explorer sui pulsanti nativi causava in alcune
    ; installazioni il testo invisibile fino al passaggio del mouse.
    if ctrl.Type = "DDL" || ctrl.Type = "Button" {
        try DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "Explorer", "Ptr", 0, "Int")
        try ctrl.SetFont("s9 c202020", "Segoe UI")
        return
    }
    try DllCall("uxtheme\#133", "Ptr", ctrl.Hwnd, "Int", 1, "Int")
    try DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0, "Int")
}

MakeStepButtons(flow, y) {
    global gControls, gMain
    captions := ["Aggiungi", "Modifica", "Elimina", "Sposta su", "Sposta giù"]
    funcs := [AddStep.Bind(flow), EditStep.Bind(flow), DeleteStep.Bind(flow), MoveStep.Bind(flow, -1), MoveStep.Bind(flow, 1)]
    for index, caption in captions {
        x := 28 + (index-1)*118
        b := gMain.Add("Button", "x" x " y" y " w110 h29", caption)
        b.OnEvent("Click", funcs[index])
        gControls[flow "Actions"].Push(b)
    }
}

ResizeWindow(guiObj, minMax, w, h) {
    global gTabs, gControls
    if minMax = -1 {
        guiObj.Hide()
        return
    }
    try {
        contentW := w - 56
        gControls["title"].Move(18, 10, w-170, 29)
        gControls["version"].Move(w-124, 15, 106, 20)
        for key in ["brandSub", "status", "details"]
            gControls[key].Move(20, , w-40)
        gControls["headerRule"].Move(18, 113, w-36, 2)
        gTabs.Move(12, 121, w-24, h-185)

        ; Panoramica: la nota scorre verticalmente, le azioni rimangono sempre visibili.
        for key in ["nextEvent", "overviewHead", "maintenanceLabel", "overviewHelp"]
            gControls[key].Move(28, , contentW)
        gControls["heroLabel"].Move(28, 158, Max(280, contentW-232), 18)
        gControls["languageLabel"].Move(w-248, 157, 72, 20)
        ; Non ridurre mai l'altezza totale della DropDownList: include il popup.
        gControls["languageSelect"].Move(w-175, 152, 147)
        actionY := h-255
        overviewHeight := Max(140, actionY-231-14)
        gControls["overview"].Move(28, 231, contentW, overviewHeight)
        gap := 9
        third := Floor((contentW-2*gap)/3)
        gControls["refreshButton"].Move(28, actionY, third, 32)
        gControls["checkButton"].Move(28+third+gap, actionY, third, 32)
        gControls["pauseButton"].Move(28+2*(third+gap), actionY, contentW-2*(third+gap), 32)
        gControls["maintenanceLabel"].Move(28, actionY+44, contentW, 18)
        half := Floor((contentW-12)/2)
        gControls["resetWindows"].Move(28, actionY+65, half, 32)
        gControls["resetButtons"].Move(40+half, actionY+65, contentW-half-12, 32)
        gControls["overviewHelp"].Move(28, actionY+109, contentW, 52)

        ; Schedulazioni: la tabella si allunga, senza modificare l'altezza delle righe.
        gControls["exeLabel"].Move(28, 157, contentW, 19)
        gControls["exe"].Move(28, 180, contentW-134, 28)
        gControls["browse"].Move(w-148, 180, 120, 28)
        gControls["scheduleTitle"].Move(28, 220, contentW, 22)
        tableH := Max(210, h-430)
        gControls["scheduleList"].Move(28, 246, contentW, tableH)
        buttonsY := 246+tableH+8
        btnGap := 7
        btnW := Floor((contentW-4*btnGap)/5)
        for i, btn in gControls["scheduleButtons"]
            btn.Move(28+(i-1)*(btnW+btnGap), buttonsY, i=5 ? contentW-4*(btnW+btnGap) : btnW, 31)
        gControls["scheduleHelp"].Move(28, buttonsY+42, contentW, 51)

        ; Sequenze: cambia l'altezza del contenitore, mai l'altezza delle righe.
        listH := Max(110, 110+Floor((h-640)/2))
        gControls["startLabel"].Move(28, 157, contentW, 21)
        gControls["startList"].Move(28, 180, contentW, listH)
        startButtonsY := 180+listH+8
        PositionStepActionRow("start", startButtonsY, contentW)
        closeLabelY := startButtonsY+43
        gControls["closeLabel"].Move(28, closeLabelY, contentW, 21)
        closeListY := closeLabelY+23
        gControls["closeList"].Move(28, closeListY, contentW, listH)
        PositionStepActionRow("close", closeListY+listH+8, contentW)

        ; Pulsanti: ListView a righe fisse anche dopo ingrandimento e ripristino.
        gControls["pointsHeading"].Move(28, 157, contentW, 21)
        pointH := Max(300, h-340)
        gControls["pointList"].Move(28, 182, contentW, pointH)
        pointButtonsY := 182+pointH+11
        btnGap := 8
        btnWeights := [102, 102, 112, 146, 86]
        btnWeightSum := 548
        btnAvailable := contentW - 4*btnGap
        nextBtnX := 28
        for i, key in ["addPoint", "deletePoint", "editPoint", "capturePoint", "defaultPoints"] {
            thisBtnW := i=5 ? 28+contentW-nextBtnX : Floor(btnAvailable*btnWeights[i]/btnWeightSum)
            gControls[key].Move(nextBtnX, pointButtonsY, thisBtnW, 32)
            nextBtnX += thisBtnW + btnGap
        }
        gControls["pointHelp"].Move(28, pointButtonsY+45, contentW, 23)

        ; Footer: mantiene sei azioni senza sovrapposizioni, anche a 640px.
        keys := ["save", "startup", "testStart", "testClose", "openLog", "exit"]
        weights := [67, 105, 94, 98, 164, 60]
        available := w-24-5*7
        totalWeight := 588
        currentX := 12
        for i, key in keys {
            buttonW := i = keys.Length ? w-12-currentX : Floor(available*weights[i]/totalWeight)
            gControls[key].Move(currentX, h-48, buttonW, 33)
            currentX += buttonW+7
        }
    }
}

PositionStepActionRow(flow, y, width) {
    global gControls
    gap := 8
    buttonW := Floor((width-4*gap)/5)
    for i, button in gControls[flow "Actions"]
        button.Move(28+(i-1)*(buttonW+gap), y, i=5 ? width-4*(buttonW+gap) : buttonW, 29)
}

SetupTray() {
    A_IconTip := "CasterLiveAutomation"
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Apri pannello", ShowWindow)
    A_TrayMenu.Add("Sospendi/Riprendi", TogglePause)
    A_TrayMenu.Add("Attività e diagnosi", OpenLog)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Esci da CasterLiveAutomation", ReallyExit)
    A_TrayMenu.Default := "Apri pannello"
    A_TrayMenu.ClickCount := 2
}

ShowWindow(*) {
    global gMain, gShownOnce
    if !gShownOnce {
        gMain.Show("w640 h640 Center")
        gShownOnce := true
    } else
        gMain.Show("Restore")
    WinActivate("ahk_id " gMain.Hwnd)
    RefreshStatus()
    WinRedraw("ahk_id " gMain.Hwnd)
}
HideWindow(*) {
    global gMain
    gMain.Hide()
    return true
}
ReallyExit(*) {
    global gCfg
    ; Esci arresta il motore ORA, senza introdurre una pausa permanente al riavvio.
    ; Una pausa richiesta dall'utente tramite Sospendi rimane invece salvata.
    try {
        IniWrite("1", gCfg, "State", "WorkerStopRequested")
        LogLine("USCITA ESPLICITA: arresto motore richiesto; lo stato di pausa non cambia")
    }
    ExitApp()
}

MarkDirty(*) {
    global gDirty
    gDirty := true
    RefreshStatus()
}
BrowseExe(*) {
    global gControls
    chosen := FileSelect(1, , "Individua CasterLive DJ.exe", "Programmi (*.exe)")
    if chosen != "" {
        gControls["exe"].Value := chosen
        MarkDirty()
    }
}
RefreshViews() {
    RefreshSchedules()
    RefreshStepList("start")
    RefreshStepList("close")
    RefreshPointList()
}
RefreshStepList(flow) {
    global gControls, gStartSteps, gCloseSteps
    rows := flow = "start" ? gStartSteps : gCloseSteps
    lv := gControls[flow "List"]
    lv.Delete()
    for i, st in rows {
        kind := Tr(st["kind"] = "click" ? "Clic" : st["kind"] = "wait" ? "Attesa" : st["kind"] = "open" ? "Apri" : "Chiudi")
        lv.Add("", i, kind, st["button"], st["repeat"], st["pause"])
    }
    lv.ModifyCol(1, 43)
    lv.ModifyCol(2, 115)
    lv.ModifyCol(3, 190)
    lv.ModifyCol(4, 92)
    lv.ModifyCol(5, 125)
}
RefreshPointList() {
    global gControls, gPoints, gPointNames
    lv := gControls["pointList"]
    lv.Delete()
    for name in gPointNames {
        coord := gPoints[name]
        arr := StrSplit(coord, ",")
        lv.Add("", name, arr.Length = 2 ? arr[1] : "", arr.Length = 2 ? arr[2] : "")
    }
    lv.ModifyCol(1, 225)
    lv.ModifyCol(2, 145)
    lv.ModifyCol(3, 145)
}

StepSelection(flow) {
    global gControls
    return gControls[flow "List"].GetNext(0)
}
AddStep(flow, *) {
    OpenStepEditor(flow, 0)
}
EditStep(flow, *) {
    idx := StepSelection(flow)
    if idx
        OpenStepEditor(flow, idx)
}
DeleteStep(flow, *) {
    global gStartSteps, gCloseSteps
    idx := StepSelection(flow)
    if !idx
        return
    rows := flow = "start" ? gStartSteps : gCloseSteps
    rows.RemoveAt(idx)
    RefreshStepList(flow)
    MarkDirty()
}
MoveStep(flow, dir, *) {
    global gStartSteps, gCloseSteps, gControls
    idx := StepSelection(flow)
    rows := flow = "start" ? gStartSteps : gCloseSteps
    other := idx + dir
    if idx < 1 || other < 1 || other > rows.Length
        return
    row := rows.RemoveAt(idx)
    rows.InsertAt(other, row)
    RefreshStepList(flow)
    gControls[flow "List"].Modify(other, "Select Focus Vis")
    MarkDirty()
}

OpenStepEditor(flow, idx) {
    global gActiveDialog, gMain, gStartSteps, gCloseSteps, gPoints, gPointNames
    rows := flow = "start" ? gStartSteps : gCloseSteps
    st := idx ? rows[idx] : Map("kind", "click", "button", "LOGIN", "repeat", 1, "pause", 1000)
    modal := Gui("+Owner" gMain.Hwnd " -MinimizeBox", idx ? "Modifica azione" : "Aggiungi azione")
    modal.BackColor := "202020"
    modal.SetFont("s10 cF1F1F1", "Segoe UI")
    modal.Add("Text", "x20 y20", "Tipo di azione")
    kinds := ["Clic", "Attesa", "Apri", "Chiudi"]
    typeBox := modal.Add("DropDownList", "x20 y45 w260 Choose1", kinds)
    kindNo := st["kind"] = "wait" ? 2 : st["kind"] = "open" ? 3 : st["kind"] = "close" ? 4 : 1
    typeBox.Choose(kindNo)
    modal.Add("Text", "x20 y87", "Pulsante")
    names := gPointNames.Clone()
    if names.Length = 0
        names.Push("LOGIN")
    pointBox := modal.Add("DropDownList", "x20 y111 w260", names)
    for n, name in names
        if name = st["button"]
            pointBox.Choose(n)
    if pointBox.Value = 0
        pointBox.Choose(1)
    modal.Add("Text", "x20 y155", "Ripetizioni (1–30)")
    repeatBox := modal.Add("Edit", "x20 y180 w115", st["repeat"])
    modal.Add("Text", "x160 y155", "Pausa in millisecondi")
    pauseBox := modal.Add("Edit", "x160 y180 w120", st["pause"])
    modal.Add("Text", "x20 y217 w302 h47", "Pausa: dopo ogni Clic o dopo Apri. Per pausa autonoma scegli Attesa.")
    save := modal.Add("Button", "x20 y271 w125 h33 Default", "Conferma")
    cancel := modal.Add("Button", "x155 y271 w125 h33", "Annulla")
    gActiveDialog := {gui: modal, flow: flow, idx: idx, type: typeBox, point: pointBox, repeat: repeatBox, pause: pauseBox}
    typeBox.OnEvent("Change", AdjustStepEditor)
    save.OnEvent("Click", SaveStepEditor)
    cancel.OnEvent("Click", (*) => modal.Destroy())
    AdjustStepEditor()
    modal.Show("w300 h325 Center")
}
AdjustStepEditor(*) {
    global gActiveDialog
    if !IsObject(gActiveDialog)
        return
    clickable := gActiveDialog.type.Value = 1
    gActiveDialog.point.Enabled := clickable
    gActiveDialog.repeat.Enabled := clickable
    gActiveDialog.pause.Enabled := gActiveDialog.type.Value != 4
}
SaveStepEditor(*) {
    global gActiveDialog, gStartSteps, gCloseSteps
    d := gActiveDialog
    try {
        kind := ["click", "wait", "open", "close"][d.type.Value]
        name := kind = "click" ? d.point.Text : ""
        rep := kind = "click" ? Integer(Trim(d.repeat.Value)) : 1
        pause := kind = "close" ? 0 : Integer(Trim(d.pause.Value))
        if rep < 1 || rep > 30 || pause < 0 || pause > 600000
            throw Error("Ripetizioni 1–30 e pausa 0–600000 millisecondi.")
        st := Map("kind", kind, "button", name, "repeat", rep, "pause", pause)
        rows := d.flow = "start" ? gStartSteps : gCloseSteps
        if d.idx
            rows[d.idx] := st
        else
            rows.Push(st)
        d.gui.Destroy()
        gActiveDialog := ""
        RefreshStepList(d.flow)
        MarkDirty()
    } catch Error as e {
        MsgBox("Dati non validi:`n" e.Message, "Azione", "Icon!")
    }
}

PointSelectedName() {
    global gControls
    row := gControls["pointList"].GetNext(0)
    return row ? gControls["pointList"].GetText(row, 1) : ""
}
AddPoint(*) {
    global gPoints, gPointNames
    result := InputBox("Nome del pulsante (es. NEXT). Usa lettere, numeri e _.", "Nuovo pulsante", "w350 h150")
    if result.Result != "OK"
        return
    name := StrUpper(Trim(result.Value))
    if !RegExMatch(name, "^[A-Z][A-Z0-9_]*$") || gPoints.Has(name) {
        MsgBox("Nome non valido oppure già presente.", "Pulsanti", "Icon!")
        return
    }
    gPoints[name] := ""
    gPointSizes[name] := ""
    gPointNames.Push(name)
    RefreshPointList()
    MarkDirty()
}
RestoreDefaultLabels(*) {
    global gPoints, gPointSizes, gPointNames, gDirty
    if SSessionActive() {
        MsgBox("Non modificare i pulsanti mentre una sessione e' attiva o incerta.", "Protezione sessione", "Icon!")
        return
    }
    message := "Ripristinare le 13 etichette standard con X e Y vuote?`n`n"
    message .= "Le etichette personalizzate spariranno dall'elenco, ma le sequenze rimarranno invariate."
    message .= "`nLe azioni senza coordinate non saranno eseguibili."
    message .= "`n`nLe modifiche saranno applicate soltanto dopo aver premuto Salva."
    if MsgBox(message, "Ripristina etichette predefinite", "YesNo Icon!") != "Yes"
        return
    gPoints := Map()
    gPointSizes := Map()
    gPointNames := DefaultButtonLabels()
    for name in gPointNames {
        gPoints[name] := ""
        gPointSizes[name] := ""
    }
    RefreshPointList()
    MarkDirty()
}

RemovePoint(*) {
    global gPoints, gPointSizes, gPointNames, gStartSteps, gCloseSteps, gCfg
    name := PointSelectedName()
    if name = ""
        return
    for st in gStartSteps
        if st["kind"] = "click" && st["button"] = name {
            MsgBox("Questo pulsante è utilizzato nella sequenza di avvio: rimuovi prima l'azione.")
            return
        }
    for st in gCloseSteps
        if st["kind"] = "click" && st["button"] = name {
            MsgBox("Questo pulsante è utilizzato nella sequenza di chiusura: rimuovi prima l'azione.")
            return
        }
    if MsgBox("Rimuovere il pulsante '" name "'?", "Conferma", "YesNo Icon?") != "Yes"
        return
    gPoints.Delete(name)
    if gPointSizes.Has(name)
        gPointSizes.Delete(name)
    for i, savedName in gPointNames {
        if savedName = name {
            gPointNames.RemoveAt(i)
            break
        }
    }
    RefreshPointList()
    MarkDirty()
}
EditPoint(*) {
    global gPoints, gPointSizes
    name := PointSelectedName()
    if name = ""
        return
    result := InputBox("Coordinate X,Y relative alla finestra di CasterLive DJ:", "Pulsante " name, "w410 h155", gPoints[name])
    if result.Result != "OK"
        return
    coord := Trim(result.Value)
    if coord != "" && !RegExMatch(coord, "^-?\d+,-?\d+$") {
        MsgBox("Inserisci X,Y (per esempio 300,450), oppure lascia vuoto per disattivare il pulsante.", "Coordinate", "Icon!")
        return
    }
    gPoints[name] := coord
    gPointSizes[name] := ""  ; Dimensioni sconosciute per coordinate inserite manualmente.
    RefreshPointList()
    MarkDirty()
}
StartCapture(*) {
    global gCaptureName
    name := PointSelectedName()
    if name = "" {
        MsgBox("Seleziona prima una riga nella tabella pulsanti.")
        return
    }
    gCaptureName := name
    Hotkey("^+c", FinishCapture, "On")
    Hotkey("Esc", CancelCapture, "On")
    MsgBox("1. Passa alla finestra CasterLive DJ.`n2. Posiziona il puntatore sul pulsante '" name "'.`n3. Premi Ctrl+Maiusc+C per salvare.`n`nEsc annulla.", "Registra pulsante")
}
CancelCapture(*) {
    global gCaptureName
    Hotkey("^+c", "Off")
    Hotkey("Esc", "Off")
    gCaptureName := ""
    ToolTip("Registrazione annullata")
    SetTimer(() => ToolTip(), -1500)
}
FinishCapture(*) {
    global gCaptureName, gPoints, gPointSizes, gCfg
    name := gCaptureName
    if name = ""
        return
    CoordMode("Mouse", "Screen")
    MouseGetPos(&sx, &sy, &hwnd)
    CoordMode("Mouse", "Client")
    try {
        if !hwnd
            throw Error("Non è stata trovata una finestra sotto il puntatore.")
        expected := IniRead(gCfg, "Config", "Process", "CasterLive DJ.exe")
        actual := WinGetProcessName("ahk_id " hwnd)
        if StrLower(actual) != StrLower(expected)
            throw Error("Mouse su '" actual "', non su '" expected "'.")
        pt := Buffer(8, 0)
        NumPut("Int", sx, pt, 0)
        NumPut("Int", sy, pt, 4)
        if !DllCall("User32\ScreenToClient", "Ptr", hwnd, "Ptr", pt, "Int")
            throw Error("Impossibile convertire coordinate della finestra.")
        x := NumGet(pt, 0, "Int"), y := NumGet(pt, 4, "Int")
        rect := Buffer(16, 0)
        if !DllCall("User32\GetClientRect", "Ptr", hwnd, "Ptr", rect, "Int")
            throw Error("Impossibile leggere dimensioni area client di CasterLive DJ")
        width := NumGet(rect, 8, "Int")
        height := NumGet(rect, 12, "Int")
        if x < 0 || y < 0 || x >= width || y >= height
            throw Error("Il puntatore non e' dentro l'area dei pulsanti di CasterLive DJ")
        gPoints[name] := x "," y
        gPointSizes[name] := width "x" height
        LogLine("COORDINATA " name " = " x "," y)
        RefreshPointList()
        MarkDirty()
        CancelCapture()
        MsgBox("Pulsante " name " registrato: " x "," y ".`nRicordati di premere Salva.", "Coordinate", "Iconi")
    } catch Error as e {
        MsgBox(e.Message "`nRiprovare oppure premere Esc.", "Errore registrazione", "Icon!")
    }
}

; ------------------------ AVVIO AUTOMATICO --------------------------
EnsureStartupLink() {
    global gShortcut
    for legacy in [A_Startup "\CasterLive DJ V3.lnk", A_Startup "\CasterLiveDJ V3.lnk", A_Startup "\Caster Automation.lnk"] {
        if !FileExist(legacy)
            continue
        try {
            FileGetShortcut(legacy, &oldTarget, , &oldArgs)
            if InStr(StrLower(oldArgs " " oldTarget), "casterlivedj_v3.ahk") || InStr(StrLower(oldArgs " " oldTarget), "casterliveautomation_v5.ahk") {
                FileDelete(legacy)
                LogLine("MIGRAZIONE AUTOSTART: rimosso vecchio collegamento Caster")
            }
        } catch Error as err
            LogLine("AVVISO: collegamento precedente non migrato: " err.Message)
    }
    ; Ricrea il collegamento se punta a una versione/cartella diversa.
    args := A_IsCompiled ? "--tray" : '"' A_ScriptFullPath '" --tray'
    expectedTarget := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
    rebuild := !FileExist(gShortcut)
    if !rebuild {
        try {
            FileGetShortcut(gShortcut, &existingTarget, , &existingArgs)
            rebuild := StrLower(existingTarget) != StrLower(expectedTarget) || existingArgs != args
        } catch Error {
            rebuild := true
        }
    }
    if !rebuild
        return
    if FileExist(gShortcut)
        FileDelete(gShortcut)
    FileCreateShortcut(expectedTarget, gShortcut, A_ScriptDir, args, "CasterLiveAutomation - avvio in tray")
    LogLine("Collegamento avvio Windows creato/aggiornato: " A_ScriptFullPath)
}
ToggleStartup(*) {
    global gShortcut, gCfg
    try {
        if FileExist(gShortcut) {
            if MsgBox("Disattivare l'avvio automatico con Windows?", "CasterLiveAutomation", "YesNo Icon?") != "Yes"
                return
            FileDelete(gShortcut)
            IniWrite("1", gCfg, "V3", "AutoStartDisabled")
        } else {
            IniWrite("0", gCfg, "V3", "AutoStartDisabled")
            EnsureStartupLink()
        }
        RefreshStatus()
    } catch Error as e {
        MsgBox("Impossibile modificare l'avvio automatico:`n" e.Message, "Windows", "Icon!")
    }
}

LegacyTaskNames() {
    return ["CasterLiveDJ V2 - AVVIO", "CasterLiveDJ V2 - CHIUSURA", "CasterLiveDJ - Avvio weekend", "CasterLiveDJ - Chiusura weekend"]
}
LegacyTaskCount() {
    count := 0
    try {
        service := ComObject("Schedule.Service")
        service.Connect()
        folder := service.GetFolder("\")
        for name in LegacyTaskNames() {
            try {
                task := folder.GetTask(name)
                if task.Enabled
                    count++
            }
        }
    }
    return count
}
; Reset limitato ESCLUSIVAMENTE agli elementi CasterLive DJ creati dalle versioni precedenti.
ResetWindowsSettings(*) {
    global gCfg, gShortcut, gPaused, gControls, gBusy
    if gBusy || SSessionActive() {
        MsgBox("Attendi la fine della sequenza in esecuzione.", "Reset Windows", "Icon!")
        return
    }
    question := "Rimuovere tutte le integrazioni CasterLive DJ create su Windows?`n`n"
    question .= "- Collegamento di avvio con Windows (V3 e vecchia V2)`n"
    question .= "- Eventuali attività pianificate CasterLive DJ V2 e weekend`n"
    question .= "- Sospendere l'automazione in questa sessione`n`n"
    question .= "Non modifica servizi, registro o altre attività di Windows. Non cancella calendario, orari o pulsanti.`n`nContinuare?"
    if MsgBox(question, "Reset impostazioni Windows", "YesNo Icon!") != "Yes"
        return
    removedLinks := 0, removedTasks := 0, errors := []
    ; Disabilita subito l'autoricreazione del collegamento al prossimo avvio.
    try IniWrite("1", gCfg, "V3", "AutoStartDisabled")
    catch Error as e
        errors.Push("INI: " e.Message)
    for path in [gShortcut, A_Startup "\Caster Automation.lnk", A_Startup "\CasterLiveDJ V3.lnk", A_Startup "\CasterLive DJ V3.lnk", A_Startup "\CasterLive DJ - Automazione.lnk"] {
        if !FileExist(path)
            continue
        try {
            ; Non cancellare collegamenti estranei anche se hanno un nome simile.
            FileGetShortcut(path, &targetExe, , &args)
            content := StrLower(targetExe " " args)
            if !InStr(content, "casterlive") && !InStr(content, "autohotkey")
                continue
            FileDelete(path)
            removedLinks++
            LogLine("RESET WINDOWS: eliminato collegamento " path)
        } catch Error as e {
            errors.Push("Collegamento " path ": " e.Message)
        }
    }
    try {
        service := ComObject("Schedule.Service")
        service.Connect()
        folder := service.GetFolder("\")
        for name in LegacyTaskNames() {
            try {
                existing := folder.GetTask(name)
            } catch Error {
                continue
            }
            try {
                folder.DeleteTask(name, 0)
                removedTasks++
                LogLine("RESET WINDOWS: eliminata attività " name)
            } catch Error as e {
                errors.Push("Attività " name ": " e.Message)
            }
        }
    } catch Error as e {
        errors.Push("Utilità di pianificazione: " e.Message)
    }
    gPaused := true
    IniWrite("1", gCfg, "V3", "Paused")
    IniWrite("1", gCfg, "State", "WorkerStopRequested")
    gControls["pauseButton"].Text := Tr("Riprendi automazione")
    LogLine("RESET WINDOWS: collegamenti=" removedLinks " attività=" removedTasks " errori=" errors.Length)
    RefreshStatus()
    message := "Collegamenti rimossi: " removedLinks "`nAttività rimosse: " removedTasks
    message .= "`nAutomazione: in pausa fino a quando scegli Riprendi."
    if errors.Length
        message .= "`n`nElementi non rimossi (può servire autorizzazione Windows):`n" JoinArray(errors, "`n")
    MsgBox(message, "Reset Windows completato", errors.Length ? "Icon!" : "Iconi")
}

ResetButtonConfig(*) {
    global gCfg, gPoints, gStartSteps, gCloseSteps, gDirty, gBusy, gPaused, gControls
    if gBusy || SSessionActive() {
        MsgBox("Una sessione e' in corso o incerta; non posso azzerare le coordinate.", "Reset pulsanti", "Icon!")
        return
    }
    question := "Azzerare TUTTE le coordinate registrate, i pulsanti aggiunti e le sequenze personalizzate?`n`n"
    question .= "Verranno ripristinate le 13 etichette predefinite con X/Y vuote, oltre alle sequenze standard.`n"
    question .= "Schedulazioni, programma e impostazioni Windows resteranno invariati.`n`n"
    question .= "Verrà creata una copia di sicurezza del file INI. Continuare?"
    if MsgBox(question, "Reset configurazione tasti", "YesNo Icon!") != "Yes"
        return
    backup := A_ScriptDir "\Backup_CasterLiveAutomation_" FormatTime(A_Now, "yyyyMMdd_HHmmss") ".ini"
    try {
        FileCopy(gCfg, backup, false)
        IniDelete(gCfg, "Points")
        IniDelete(gCfg, "PointClientSize")
        IniDelete(gCfg, "Buttons")
        IniDelete(gCfg, "StepsStart")
        IniDelete(gCfg, "StepsClose")
        PrepareConfig()
        LoadData()
        gPaused := true ; Evita azioni automatiche prima che i nuovi tasti siano registrati.
        IniWrite("1", gCfg, "V3", "Paused")
        gControls["pauseButton"].Text := Tr("Riprendi automazione")
        gDirty := false
        RefreshViews()
        RefreshStatus()
        LogLine("RESET PULSANTI: nuova configurazione vuota; backup=" backup)
        resetMessage := "Pulsanti e sequenze ripristinati ai valori iniziali, SENZA coordinate.`n`n"
        resetMessage .= "Backup: " backup "`n`n"
        resetMessage .= "Registra i pulsanti, premi Salva e soltanto dopo riattiva l'automazione."
        MsgBox(resetMessage, "Reset pulsanti", "Iconi")
    } catch Error as e {
        LogLine("ERRORE RESET PULSANTI: " e.Message)
        MsgBox("Reset non completato: " e.Message "`n`nBackup disponibile: " backup, "Errore", "Icon!")
    }
}

TogglePause(*) {
    global gPaused, gControls, gCfg, gRuntimeFile, gScheduleFile
    if gPaused {
        if gDirty {
            MsgBox("Salva prima le modifiche ai pulsanti o alle sequenze.", "Configurazione non salvata", "Icon!")
            return
        }
        if !FileExist(IniRead(gCfg, "Config", "ExePath", "")) {
            MsgBox("Configura un eseguibile valido prima di riprendere l'automazione.", "Programma non configurato", "Icon!")
            return
        }
        try {
            jobs := SReadAll(gScheduleFile)
            SValidateAll(jobs)
            enabled := 0
            for job in jobs
                if job["Enabled"] = "1"
                    enabled += 1
            if enabled = 0 {
                MsgBox("Non ci sono schedulazioni attive. Aggiungine e abilita almeno una nella scheda Schedulazioni prima di premere Riprendi automazione.", "Nessuna schedulazione", "Icon!")
                return
            }
            CheckSteps(ReadSteps("StepsStart"), "start")
            CheckSteps(ReadSteps("StepsClose"), "close")
        } catch Error as e {
            MsgBox("Impossibile riprendere: " e.Message "`n`nRegistra le coordinate necessarie e salva.", "Pulsanti non operativi", "Icon!")
            return
        }
        status := IniRead(gRuntimeFile, "Session", "Status", "idle")
        if status != "idle" && status != "complete" && status != "running" {
            MsgBox("Stato sessione incerto: " status ". Verifica SEND e chiudi Caster prima di riprendere.", "Protezione automatica", "Icon!")
            return
        }
    }
    gPaused := !gPaused
    IniWrite(gPaused ? "1" : "0", gCfg, "V3", "Paused")
    gControls["pauseButton"].Text := Tr(gPaused ? "Riprendi automazione" : "Sospendi automazione")
    LogLine(gPaused ? "AUTOMAZIONE IN PAUSA" : "AUTOMAZIONE RIPRESA")
    if !gPaused {
        try EnsureWorker()
        catch Error as err
            LogLine("ERRORE riavvio motore: " err.Message)
    }
    RefreshStatus()
}

; --------------------------- ESECUZIONE ----------------------------
; --------------------- CALENDARIO / DIAGNOSTICA ---------------------
; Giorni e date sono sempre riferiti al giorno REALE di esecuzione.
; Sabato selezionato + 00:01 = sabato alle 00:01. Nessun offset nascosto.
ScheduleNextSummary() {
    global gScheduleFile
    try return SNextEvent(SReadAll(gScheduleFile))
    catch Error as e
        return "Calendario non valido: " e.Message
}
ShowScheduleDiagnostics(*) {
    global gCfg, gScheduleFile, gRuntimeFile
    message := "Ora Windows: " FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss") "`n"
    message .= "Motore: " (WorkerHealthy() ? "ATTIVO" : "INATTIVO") "`n"
    message .= "Ultimo heartbeat: " IniRead(gCfg, "State", "WorkerHeartbeat", "mai") "`n"
    message .= "Pausa: " IniRead(gCfg, "V3", "Paused", "1") "`n"
    message .= "Stato sessione: " IniRead(gRuntimeFile, "Session", "Status", "mai") "`n"
    message .= "Sessione: " IniRead(gRuntimeFile, "Session", "Token", "nessuna") "`n"
    message .= "Ultima esecuzione: " IniRead(gCfg, "State", "WorkerLastEvent", "nessuna") "`n"
    message .= "Errore recente: " IniRead(gCfg, "State", "V3LastError", "nessuno") "`n"
    try {
        jobs := SReadAll(gScheduleFile)
        SValidateAll(jobs)
        active := 0
        for job in jobs
            if job["Enabled"] = "1"
                active += 1
        message .= "Schedulazioni: " jobs.Length " (attive: " active ")`n"
        message .= "Conflitti: NESSUNO`n"
    } catch Error as e
        message .= "CALENDARIO NON VALIDO: " e.Message "`n"
    message .= "Prossimo evento: " ScheduleNextSummary()
    LogLine("DIAGNOSI: " StrReplace(message, "`n", " | "))
    MsgBox(message, "Attività e diagnosi", "Iconi")
    current := IniRead(gRuntimeFile, "Session", "Status", "idle")
    if current = "start_error" || current = "close_error" || current = "starting" || current = "closing" || current = "running" {
        proc := IniRead(gCfg, "Config", "Process", "CasterLive DJ.exe")
        if ProcessExist(proc) {
            MsgBox("La sessione " current " richiede attenzione. CasterLive DJ e' ancora aperto: verifica SEND e chiudi manualmente il programma prima di usare il ripristino.", "Sessione da verificare", "Icon!")
        } else {
            question := "Stato salvato: " current ". CasterLive DJ risulta chiuso.`n`n"
            question .= "Solo se hai verificato che SEND e' spento, puoi reimpostare lo stato su IDLE.`n"
            question .= "L'evento gia' tentato non verra' ripetuto. Reimpostare?"
            if MsgBox(question, "Ripristino sessione", "YesNo Icon!") = "Yes" {
                IniWrite("idle", gRuntimeFile, "Session", "Status")
                LogLine("RESET STATO SESSIONE richiesto dall'utente dopo verifica manuale di SEND")
                RefreshStatus()
            }
        }
    }
}

RunTest(flow) {
    global gDirty, gPaused
    if !gPaused {
        MsgBox("Per i test manuali sospendi prima l’automazione: evita interferenze con eventi programmati.", "Test", "Icon!")
        return
    }
    if SSessionActive() {
        MsgBox("C'e' una sessione in corso o incerta. Verifica e chiudi Caster prima di fare test.", "Test", "Icon!")
        return
    }
    if gDirty {
        MsgBox("Salva prima le modifiche non ancora applicate.", "Test", "Icon!")
        return
    }
    msg := flow = "start" ? "eseguirà la sequenza START configurata" : "eseguirà la sequenza CLOSE configurata"
    if MsgBox("TEST REALE: " msg ".`n`nI clic sono veri e possono cambiare lo stato della trasmissione. Continuare?", "Conferma test", "YesNo Icon!") != "Yes"
        return
    RunFlow(flow, true, "test")
}
RunFlow(flow, manual, nightKey) {
    global gBusy, gCfg, gLastError, gLastScheduledAction
    if gBusy
        return
    gBusy := true
    try {
        steps := ReadSteps(flow = "start" ? "StepsStart" : "StepsClose")
        CheckSteps(steps, flow)
        LogLine((manual ? "TEST " : "INIZIO ") StrUpper(flow) " data " nightKey)
        ExecuteFlow(flow, steps)
        if !manual
            IniWrite(StrReplace(nightKey, "-", ""), gCfg, "State", "V3" flow "OK")
        gLastError := ""
        IniWrite("", gCfg, "State", "V3LastError")
        LogLine("OK " StrUpper(flow) " data " nightKey)
        if !manual
            gLastScheduledAction := "OK " StrUpper(flow) " data " nightKey
        if manual
            MsgBox("Test " flow " completato (non verifica lo stato del flusso audio).", "CasterLiveAutomation", "Iconi")
    } catch Error as e {
        RecordFailure(StrUpper(flow), e)
        if !manual
            gLastScheduledAction := "ERRORE " StrUpper(flow) " data " nightKey ": " e.Message
        if manual
            MsgBox("Test non riuscito:`n" e.Message "`n`nControlla lo stato di SEND manualmente.", "Errore", "Icon!")
    } finally {
        gBusy := false
        RefreshStatus()
    }
}
ExecuteFlow(flow, steps) {
    global gCfg
    target := CasterSelector()
    ; Compatibilita' con le vecchie sequenze che non hanno APRI.
    if flow = "start" && !FlowHasOpenStep(steps)
        OpenCasterProgram()
    for i, st in steps {
        LogLine("PASSO " i "/" steps.Length " - " st["kind"] " " st["button"])
        if st["kind"] = "click" {
            Loop st["repeat"] {
                PressButton(st["button"])
                if st["pause"] > 0
                    Sleep(st["pause"])
            }
        } else if st["kind"] = "wait"
            Sleep(st["pause"])
        else if st["kind"] = "open" {
            OpenCasterProgram()
            if st["pause"] > 0
                Sleep(st["pause"])
        } else if st["kind"] = "close"
            CloseCaster()
    }
}
FlowHasOpenStep(steps) {
    for step in steps
        if step["kind"] = "open"
            return true
    return false
}
OpenCasterProgram() {
    global gCfg
    target := CasterSelector()
    proc := IniRead(gCfg, "Config", "Process", "CasterLive DJ.exe")
    previous := DetectHiddenWindows(true)
    try {
        alreadyOpen := WinExist(target) || ProcessExist(proc)
        if !alreadyOpen {
            exe := IniRead(gCfg, "Config", "ExePath", "")
            if !FileExist(exe)
                throw Error("Programma inesistente: " exe)
            LogLine("APRI programma | " exe)
            Run('"' exe '"')
        } else
            LogLine("APRI: programma gia' aperto")
        if !WinWait(target, , 45)
            throw Error("Finestra non disponibile entro 45 secondi dopo APRI")
    } finally {
        DetectHiddenWindows(previous)
    }
    Sleep(1500)
}

CasterSelector() {
    global gCfg
    return "ahk_exe " IniRead(gCfg, "Config", "Process", "CasterLive DJ.exe")
}
PressButton(name) {
    global gCfg
    target := CasterSelector()
    hwnd := WinExist(target)
    if !hwnd
        throw Error("Finestra CasterLive DJ assente prima di " name)
    if WinGetMinMax(hwnd) = -1 {
        WinRestore(hwnd)
        Sleep(450)
    }
    WinActivate(hwnd)
    if !WinWaitActive(hwnd, , 10)
        throw Error("Impossibile attivare CasterLive DJ prima di " name)
    p := StrSplit(IniRead(gCfg, "Points", name, ""), ",")
    if p.Length != 2 || !RegExMatch(Trim(p[1]), "^-?\d+$") || !RegExMatch(Trim(p[2]), "^-?\d+$")
        throw Error("Coordinate non valide per " name)
    x := Integer(Trim(p[1]))
    y := Integer(Trim(p[2]))
    rect := Buffer(16, 0)
    if !DllCall("User32\GetClientRect", "Ptr", hwnd, "Ptr", rect, "Int")
        throw Error("Impossibile leggere area client Caster")
    width := NumGet(rect, 8, "Int")
    height := NumGet(rect, 12, "Int")
    if x < 0 || y < 0 || x >= width || y >= height
        throw Error("CLIC BLOCCATO: " name " fuori area client")
    calibrated := IniRead(gCfg, "PointClientSize", name, "")
    if calibrated = ""
        throw Error("CLIC BLOCCATO " name ": calibrazione assente. Registra nuovamente il pulsante.")
    if calibrated != width "x" height
        throw Error("CLIC BLOCCATO " name ": finestra ridimensionata, registra nuovamente il pulsante")
    pt := Buffer(8, 0)
    NumPut("Int", x, pt, 0), NumPut("Int", y, pt, 4)
    if !DllCall("User32\ClientToScreen", "Ptr", hwnd, "Ptr", pt, "Int")
        throw Error("Impossibile convertire posizione pulsante")
    screenX := NumGet(pt, 0, "Int"), screenY := NumGet(pt, 4, "Int")
    prevMode := CoordMode("Mouse", "Screen")
    try {
        MouseMove(screenX, screenY, 0)
        Sleep(100)
        MouseGetPos(&realX, &realY, &hover)
        root := DllCall("User32\GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
        rootHover := hover ? DllCall("User32\GetAncestor", "Ptr", hover, "UInt", 2, "Ptr") : 0
        if !WinActive(hwnd) || !hover || rootHover != root || Abs(realX-screenX) > 2 || Abs(realY-screenY) > 2
            throw Error("CLIC BLOCCATO " name ": il puntatore non e' su CasterLive DJ")
        if WinGetPID("ahk_id " hover) != WinGetPID("ahk_id " hwnd)
            throw Error("CLIC BLOCCATO " name ": finestra appartenente ad altro processo")
        freshPt := Buffer(8, 0)
        NumPut("Int", x, freshPt, 0)
        NumPut("Int", y, freshPt, 4)
        if !DllCall("User32\ClientToScreen", "Ptr", hwnd, "Ptr", freshPt, "Int")
            throw Error("CLIC BLOCCATO " name ": posizione non verificabile")
        if NumGet(freshPt, 0, "Int") != screenX || NumGet(freshPt, 4, "Int") != screenY
            throw Error("CLIC BLOCCATO " name ": finestra spostata durante il clic")
        MouseClick("Left")
        LogLine("CLIC " name " | schermo=" screenX "," screenY)
    } finally {
        CoordMode("Mouse", prevMode)
    }
}
CloseCaster() {
    target := CasterSelector()
    if !WinExist(target)
        throw Error("CasterLive DJ non trovato durante la chiusura")
    WinClose(target)
    if !WinWaitClose(target, , 12)
        throw Error("Chiusura normale non riuscita; non forzo il processo")
    LogLine("FINESTRA CHIUSA")
}
CheckSteps(steps, flow, requireCoordinates := true) {
    global gPoints, gPointSizes
    if steps.Length = 0
        throw Error("Sequenza " flow " vuota")
    for i, st in steps {
        kind := st["kind"]
        if kind = "click" {
            if st["button"] = ""
                throw Error("Pulsante non selezionato, passo " i)
            if requireCoordinates && (!gPoints.Has(st["button"]) || !RegExMatch(gPoints[st["button"]], "^-?\d+,-?\d+$"))
                throw Error("Coordinate non configurate per " st["button"])
            if requireCoordinates && (!gPointSizes.Has(st["button"]) || gPointSizes[st["button"]] = "")
                throw Error("Per sicurezza registra nuovamente " st["button"] " con Ctrl+Maiusc+C")
            if st["repeat"] < 1 || st["repeat"] > 30
                throw Error("Ripetizioni non valide, passo " i)
        } else if kind != "wait" && kind != "open" && kind != "close"
            throw Error("Tipo di azione non valido, passo " i)
        if st["pause"] < 0 || st["pause"] > 600000
            throw Error("Pausa non valida, passo " i)
        if flow = "start" && kind = "close"
            throw Error("La sequenza di avvio non può chiudere il programma")
        if flow = "close" && kind = "close" && i != steps.Length
            throw Error("La chiusura del software deve essere l'ultimo passo")
    }
    if flow = "close" && steps[steps.Length]["kind"] != "close"
        throw Error("La sequenza di chiusura deve terminare con Chiudi")
}

; ---------------------- MOTORE INDIPENDENTE ----------------------
; Il worker rimane attivo anche se il pannello viene nascosto o minimizzato.
WorkerHealthy() {
    global gCfg
    stamp := IniRead(gCfg, "State", "WorkerHeartbeat", "")
    if !RegExMatch(stamp, "^\d{14}$")
        return false
    try {
        age := DateDiff(A_Now, stamp, "Seconds")
        return age >= 0 && age <= 60
    } catch Error {
        return false
    }
}
EnsureWorker() {
    global gCfg, gWorkerScript, gWorkerLastLaunch
    if IniRead(gCfg, "V3", "Paused", "1") = "1"
        return
    ; Evita che un vecchio ordine di arresto sopravviva al riavvio.
    IniWrite("0", gCfg, "State", "WorkerStopRequested")
    if WorkerHealthy() {
        if IniRead(gCfg, "State", "WorkerVersion", "") != "5.0"
            throw Error("Un Worker incompatibile risulta attivo. Chiudi i vecchi processi AutoHotkey prima di usare CasterLiveAutomation.")
        return
    }
    if gWorkerLastLaunch != "" && DateDiff(A_Now, gWorkerLastLaunch, "Seconds") < 20
        return
    if !FileExist(gWorkerScript)
        throw Error("Manca CasterLiveAutomation_Worker.ahk nella cartella dell'applicazione")
    gWorkerLastLaunch := A_Now
    workerPid := 0
    Run('"' A_AhkPath '" "' gWorkerScript '"', A_ScriptDir, , &workerPid)
    LogLine("WORKER lanciato PID=" workerPid " | " gWorkerScript)
}

; ----------------------------- STATO -------------------------------
RefreshStatus(*) {
    global gControls, gCfg, gDirty, gPaused, gBusy, gLastError, gShortcut, gLastScheduleCheck, gLastScheduleNote, gLastScheduledAction, gScheduleFile, gRuntimeFile
    try {
        try EnsureWorker()
        catch Error as err {
            gLastError := "Worker: " err.Message
            LogLine("ERRORE WORKER: " err.Message)
        }
        gLastScheduleCheck := IniRead(gCfg, "State", "WorkerLastCheck", "mai")
        gLastScheduleNote := IniRead(gCfg, "State", "WorkerLastSTARTDecision", "In attesa del worker")
        gLastScheduledAction := IniRead(gCfg, "State", "WorkerLastEvent", "Nessun evento eseguito")
        problems := []
        if !WorkerHealthy() && !gPaused
            problems.Push("motore orari non ancora attivo")
        exe := IniRead(gCfg, "Config", "ExePath", "")
        if !FileExist(exe)
            problems.Push("eseguibile mancante")
        if !FileExist(gShortcut)
            problems.Push("avvio con Windows disattivato")
        try {
            allJobs := SReadAll(gScheduleFile)
            SValidateAll(allJobs)
            enabledJobs := 0
            for job in allJobs
                if job["Enabled"] = "1"
                    enabledJobs += 1
            if enabledJobs = 0
                problems.Push("nessuna schedulazione attiva")
        } catch Error as e
            problems.Push("conflitto o calendario non valido: " e.Message)
        sessionStatus := IniRead(gRuntimeFile, "Session", "Status", "idle")
        if sessionStatus != "idle" && sessionStatus != "running" && sessionStatus != "complete"
            problems.Push("sessione: " sessionStatus " (verificare SEND)")
        if LegacyTaskCount() > 0
            problems.Push("vecchie attività Windows ancora abilitate")
        for flow in ["start", "close"] {
            try CheckSteps(ReadSteps(flow = "start" ? "StepsStart" : "StepsClose"), flow)
            catch Error as e
                problems.Push(e.Message)
        }
        if gPaused
            status := Tr("IN PAUSA"), color := "cFFBD69"
        else if gDirty
            status := Tr("MODIFICHE NON SALVATE"), color := "cFFBD69"
        else if problems.Length
            status := "ATTENZIONE: " JoinArray(problems, "; "), color := "cFFB86B"
        else if gLastError != "" || IniRead(gCfg, "State", "V3LastError", "") != ""
            status := "ERRORE RECENTE: Attività e diagnosi", color := "cFFB86B"
        else if gBusy
            status := Tr("ESECUZIONE IN CORSO"), color := "cE0E0E0"
        else
            status := Tr("OPERATIVA • controllo orari attivo"), color := "cDCDCDC"
        gControls["status"].Text := status
        gControls["status"].SetFont(color " bold")
        gControls["details"].Text := Tr("Motore: ") (WorkerHealthy() ? Tr("ATTIVO") : Tr("INATTIVO")) " | " Tr("Avvio Windows: ") (FileExist(gShortcut) ? Tr("attivo") : Tr("disattivato")) " | " Tr("Ultimo controllo: ") gLastScheduleCheck
        gControls["overview"].Value := OverviewText()
        gControls["nextEvent"].Text := ScheduleNextSummary()
        gControls["startup"].Text := FileExist(gShortcut) ? "Autostart: ON" : "Autostart: OFF"
    }
}
OverviewText() {
    global gCfg, gScheduleFile, gRuntimeFile, gLastScheduleCheck, gLastScheduleNote, gLastScheduledAction
    jobs := SReadAll(gScheduleFile)
    count := 0
    for job in jobs
        if job["Enabled"] = "1"
            count += 1
    out := Tr("SCHEDULAZIONI ") count Tr(" attive / ") jobs.Length Tr(" totali") "`n"
    out .= Tr("SESSIONE       ") IniRead(gRuntimeFile, "Session", "Status", "idle") "`n"
    out .= Tr("ULTIMO CHECK   ") gLastScheduleCheck "`n"
    out .= Tr("MOTORE         ") gLastScheduleNote "`n"
    out .= Tr("ULTIMO EVENTO  ") gLastScheduledAction
    lastError := IniRead(gCfg, "State", "V3LastError", "")
    if lastError != ""
        out .= "`nATTENZIONE     " lastError
    return out
}
DisplayDays(raw) {
    if raw = ""
        return Tr("Nessuno")
    days := [["Monday", "Lun"], ["Tuesday", "Mar"], ["Wednesday", "Mer"], ["Thursday", "Gio"], ["Friday", "Ven"], ["Saturday", "Sab"], ["Sunday", "Dom"]]
    found := []
    for entry in days
        if InStr("," raw ",", "," entry[1] ",")
            found.Push(Tr(entry[2]))
    return JoinArray(found, "  ·  ")
}

OpenLog(*) {
    global gLog
    if !FileExist(gLog)
        FileAppend("", gLog, "UTF-8")
    Run('notepad.exe "' gLog '"')
}
RecordFailure(tag, e) {
    global gLastError, gCfg
    gLastError := tag ": " e.Message " (riga " e.Line ")"
    IniWrite(gLastError, gCfg, "State", "V3LastError")
    LogLine("ERRORE " gLastError " | File=" e.File " | What=" e.What)
}
LogLine(message) {
    global gLog
    try FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " | " message "`r`n", gLog, "UTF-8")
}
ClockMinutes(hhmm) {
    return (SubStr(hhmm, 1, 2) + 0)*60 + (SubStr(hhmm, 4, 2) + 0)
}
ArrayHas(arr, value) {
    for v in arr
        if v = value
            return true
    return false
}
JoinArray(arr, sep) {
    out := ""
    for v in arr
        out .= (out = "" ? "" : sep) v
    return out
}


; ------------------- SCHEDULAZIONI MULTIPLE -------------------
; Un solo programma e una coppia di sequenze condivise, ma piu' intervalli attivi.
SSessionActive() {
    global gRuntimeFile
    state := IniRead(gRuntimeFile, "Session", "Status", "idle")
    return state != "idle" && state != "complete"
}
SSelectedIndex() {
    global gControls
    return gControls["scheduleList"].GetNext(0)
}
SNextId(jobs) {
    maxId := 0
    for job in jobs
        maxId := Max(maxId, job["Id"] + 0)
    return (maxId + 1) ""
}
SRefreshAfterChange() {
    RefreshSchedules()
    RefreshStatus()
}
RefreshSchedules() {
    global gScheduleFile, gControls, gScheduleRows
    jobs := SReadAll(gScheduleFile)
    gScheduleRows := jobs
    lv := gControls["scheduleList"]
    lv.Delete()
    for job in jobs {
        countDates := 0
        for date in StrSplit(job["Dates"], "|")
            if date != ""
                countDates++
        lv.Add("", job["Enabled"] = "1" ? "ON" : "OFF", job["Name"],
            DisplayDays(job["Days"]), job["StartTime"], job["EndTime"]
                (SClockMinutes(job["EndTime"]) < SClockMinutes(job["StartTime"]) ? " (+1g)" : ""), countDates)
    }
    lv.ModifyCol(1, 53)
    lv.ModifyCol(2, 165)
    lv.ModifyCol(3, 150)
    lv.ModifyCol(4, 68)
    lv.ModifyCol(5, 105)
    lv.ModifyCol(6, 85)
}
SGetSelectedJob() {
    global gScheduleRows
    row := SSelectedIndex()
    if row < 1 || row > gScheduleRows.Length {
        MsgBox("Seleziona prima una schedulazione.", "CasterLiveAutomation", "Iconi")
        return ""
    }
    return gScheduleRows[row]
}
SCommitSchedules(jobs) {
    global gScheduleFile, gDirty
    if gDirty {
        MsgBox("Prima salva le modifiche al programma o alle sequenze con il pulsante Salva.", "Modifiche non salvate", "Icon!")
        return false
    }
    if SSessionActive() {
        MsgBox("Una sessione e' in corso o in stato incerto. Attendi la sua chiusura e verifica SEND prima di cambiare schedulazione.", "Protezione sessione", "Icon!")
        return false
    }
    try {
        SWriteAll(gScheduleFile, jobs)
        LogLine("SCHEDULAZIONI SALVATE | " jobs.Length " righe")
        SRefreshAfterChange()
        return true
    } catch Error as e {
        MsgBox("Modifica rifiutata:`n" e.Message "`n`nNon e' stato modificato il calendario attivo.", "Conflitto di orari", "Icon!")
        return false
    }
}
SAddNew(*) {
    global gScheduleFile
    jobs := SReadAll(gScheduleFile)
    job := SDefaultSchedule()
    job["Id"] := SNextId(jobs)
    job["Name"] := "Nuova schedulazione"
    job["Days"] := ""
    job["Dates"] := FormatTime(A_Now, "yyyy-MM-dd")
    job["StartTime"] := "20:00"
    job["EndTime"] := "22:00"
    SOpenEditor(job, true)
}
SEditSelected(*) {
    job := SGetSelectedJob()
    if IsObject(job)
        SOpenEditor(job, false)
}
SDuplicate(*) {
    global gScheduleFile
    selected := SGetSelectedJob()
    if !IsObject(selected)
        return
    jobs := SReadAll(gScheduleFile)
    copy := Map()
    for k, v in selected
        copy[k] := v
    copy["Id"] := SNextId(jobs)
    copy["Name"] := selected["Name"] " (copia)"
    copy["Enabled"] := "0" ; Disabilitata, altrimenti si sovrapporrebbe all'originale.
    jobs.Push(copy)
    if SCommitSchedules(jobs)
        MsgBox("Copia creata DISATTIVATA per evitare sovrapposizioni. Puoi modificarla e poi attivarla.", "CasterLiveAutomation", "Iconi")
}
SToggleSelected(*) {
    global gScheduleFile
    selected := SGetSelectedJob()
    if !IsObject(selected)
        return
    jobs := SReadAll(gScheduleFile)
    for job in jobs {
        if job["Id"] = selected["Id"] {
            job["Enabled"] := job["Enabled"] = "1" ? "0" : "1"
            break
        }
    }
    SCommitSchedules(jobs)
}
SDeleteSelected(*) {
    global gScheduleFile
    selected := SGetSelectedJob()
    if !IsObject(selected)
        return
    if MsgBox("Eliminare definitivamente la schedulazione '" selected["Name"] "'?", "Conferma eliminazione", "YesNo Icon!") != "Yes"
        return
    jobs := SReadAll(gScheduleFile)
    for i, job in jobs {
        if job["Id"] = selected["Id"] {
            jobs.RemoveAt(i)
            break
        }
    }
    SCommitSchedules(jobs)
}
SOpenEditor(job, creating) {
    global gMain, gScheduleEditor
    if gScheduleEditor != "" {
        try WinActivate("ahk_id " gScheduleEditor.Hwnd)
        return
    }
    ed := Map()
    ed["job"] := job
    ed["creating"] := creating
    ed["dates"] := []
    for date in StrSplit(job["Dates"], "|")
        if date != ""
            ed["dates"].Push(date)
    modal := Gui("+Owner" gMain.Hwnd " +MinSize590x555", creating ? Tr("Nuova schedulazione") : Tr("Modifica schedulazione"))
    modal.BackColor := "171717"
    modal.SetFont("s9 cEDEDED", "Segoe UI")
    gScheduleEditor := modal
    ed["gui"] := modal
    modal.Add("Text", "x22 y14 w535 h20", Tr("NOME SCHEDULAZIONE"))
    ed["name"] := modal.Add("Edit", "x22 y36 w535 h29 Background262626 cEFEFEF", job["Name"])
    ed["enabled"] := modal.Add("CheckBox", "x22 y82 w220 h25", Tr("Schedulazione attiva"))
    ed["enabled"].Value := job["Enabled"] = "1"
    modal.Add("Text", "x22 y120 w175 h20", Tr("INIZIO (HH:MM)"))
    modal.Add("Text", "x225 y120 w180 h20", Tr("FINE (HH:MM)"))
    ed["start"] := modal.Add("Edit", "x22 y143 w160 h29 Background262626 cEFEFEF", job["StartTime"])
    ed["end"] := modal.Add("Edit", "x225 y143 w160 h29 Background262626 cEFEFEF", job["EndTime"])
    modal.Add("Text", "x22 y183 w535 h35 cAAAAAA", Tr("Se la fine precede l'inizio, termina il giorno successivo.`nEsempio: venerdi 23:00 → sabato 02:00."))
    modal.Add("Text", "x22 y229 w535 h20", Tr("GIORNI RICORRENTI (GIORNO DI AVVIO)"))
    dayNames := ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]
    ed["dayChecks"] := Map()
    for i, day in SWeekdays() {
        cb := modal.Add("CheckBox", "x" (22 + (i-1)*78) " y251 w75 h26", Tr(dayNames[i]))
        cb.Value := InStr("," job["Days"] ",", "," day ",") > 0
        ed["dayChecks"][day] := cb
    }
    modal.Add("Text", "x22 y297 w535 h20", Tr("DATE ECCEZIONALI AGGIUNTIVE (GIORNI DI AVVIO)"))
    ed["dateList"] := modal.Add("ListBox", "x22 y324 w265 h132 Background262626 cEFEFEF", ed["dates"])
    ed["date"] := modal.Add("DateTime", "x303 y326 w149 h27", "dd/MM/yyyy")
    addDate := modal.Add("Button", "x466 y326 w101 h29", Tr("Aggiungi"))
    removeDate := modal.Add("Button", "x303 y368 w264 h29", Tr("Rimuovi data selezionata"))
    addDate.OnEvent("Click", (*) => SEditorAddDate(ed))
    removeDate.OnEvent("Click", (*) => SEditorRemoveDate(ed))
    modal.Add("Text", "x22 y466 w535 h34 cAAAAAA", Tr("Le date si AGGIUNGONO ai giorni settimanali. Due schedulazioni attive non possono sovrapporsi."))
    save := modal.Add("Button", "x290 y510 w130 h33 Default", Tr("Salva"))
    cancel := modal.Add("Button", "x434 y510 w130 h33", Tr("Annulla"))
    save.OnEvent("Click", (*) => SEditorSave(ed))
    cancel.OnEvent("Click", SEditorClose)
    modal.OnEvent("Close", SEditorClose)
    modal.OnEvent("Escape", SEditorClose)
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", modal.Hwnd, "UInt", 20, "Int*", 1, "UInt", 4, "Int")
    for hwnd, control in modal
        ApplyControlTheme(control)
    modal.Show("w590 h555 Center")
}
SEditorClose(*) {
    global gScheduleEditor
    if gScheduleEditor != "" {
        try gScheduleEditor.Destroy()
        gScheduleEditor := ""
    }
}
SEditorAddDate(ed) {
    raw := ed["date"].Value
    date := SubStr(raw, 1, 4) "-" SubStr(raw, 5, 2) "-" SubStr(raw, 7, 2)
    for oldDate in ed["dates"]
        if oldDate = date
            return
    ed["dates"].Push(date)
    SEditorRefreshDates(ed)
}
SEditorRemoveDate(ed) {
    row := ed["dateList"].Value
    if row >= 1 && row <= ed["dates"].Length {
        ed["dates"].RemoveAt(row)
        SEditorRefreshDates(ed)
    }
}
SEditorRefreshDates(ed) {
    ed["dateList"].Delete()
    ed["dateList"].Add(ed["dates"])
}
SEditorSave(ed) {
    global gScheduleFile
    try {
        job := Map()
        for key, value in ed["job"]
            job[key] := value
        job["Name"] := Trim(ed["name"].Value)
        job["Enabled"] := ed["enabled"].Value = 1 ? "1" : "0"
        job["StartTime"] := Trim(ed["start"].Value)
        job["EndTime"] := Trim(ed["end"].Value)
        selectedDays := []
        for day in SWeekdays()
            if ed["dayChecks"][day].Value = 1
                selectedDays.Push(day)
        job["Days"] := SJoin(selectedDays, ",")
        job["Dates"] := SJoin(ed["dates"], "|")
        jobs := SReadAll(gScheduleFile)
        if ed["creating"]
            jobs.Push(job)
        else {
            found := false
            for i, existing in jobs {
                if existing["Id"] = job["Id"] {
                    jobs[i] := job
                    found := true
                    break
                }
            }
            if !found
                throw Error("La schedulazione originale non esiste piu'")
        }
        if SCommitSchedules(jobs)
            SEditorClose()
    } catch Error as e
        MsgBox(e.Message, "Errore schedulazione", "Icon!")
}

; Interface strings are UI-only. Scheduler tokens and log messages are NOT translated.
UILanguageIndex() {
    global gLanguage
    return gLanguage = "en" ? 2 : gLanguage = "fr" ? 3 : gLanguage = "es" ? 4 : 1
}
Tr(key) {
    global gLanguage
    static translations := InitTranslations()
    if !translations.Has(key)
        return key
    idx := gLanguage = "en" ? 2 : gLanguage = "fr" ? 3 : gLanguage = "es" ? 4 : 1
    return translations[key][idx]
}
InitTranslations() {
    translations := Map()
    translations["PROSSIMA ESECUZIONE"] := ["PROSSIMA ESECUZIONE", "NEXT RUN", "PROCHAINE EXÉCUTION", "PRÓXIMA EJECUCIÓN"]
    translations["STATO DELLA PROGRAMMAZIONE"] := ["STATO DELLA PROGRAMMAZIONE", "SCHEDULE STATUS", "ÉTAT DES PLANIFICATIONS", "ESTADO DE LA PROGRAMACIÓN"]
    translations["Diagnosi"] := ["Diagnosi", "Diagnostics", "Diagnostic", "Diagnóstico"]
    translations["Aggiorna stato"] := ["Aggiorna stato", "Refresh status", "Actualiser", "Actualizar estado"]
    translations["Riprendi automazione"] := ["Riprendi automazione", "Resume", "Reprendre", "Reanudar"]
    translations["Sospendi automazione"] := ["Sospendi automazione", "Pause", "Suspendre", "Pausar"]
    translations["MANUTENZIONE (CON CONFERMA)"] := ["MANUTENZIONE (CON CONFERMA)", "MAINTENANCE (CONFIRMATION)", "MAINTENANCE (CONFIRMATION)", "MANTENIMIENTO (CONFIRMACIÓN)"]
    translations["Reset impostazioni Windows"] := ["Reset impostazioni Windows", "Reset Windows settings", "Réinitialiser Windows", "Restablecer Windows"]
    translations["Reset pulsanti e sequenze"] := ["Reset pulsanti e sequenze", "Reset buttons & sequences", "Réinit. touches et séquences", "Restablecer botones y secuencias"]
    translations["Il motore resta attivo anche con pannello nascosto. La spia ATTIVO non certifica lo streaming.`nPer i clic, Windows deve essere sbloccato. I test agiscono realmente su SEND."] := ["Il motore resta attivo anche con pannello nascosto. La spia ATTIVO non certifica lo streaming.`nPer i clic, Windows deve essere sbloccato. I test agiscono realmente su SEND.", "The scheduler keeps running when the panel is hidden. ACTIVE does not confirm a live stream.`nWindows must be unlocked for clicks. Tests really press SEND.", "Le moteur reste actif lorsque le panneau est masqué. ACTIF ne confirme pas la diffusion.`nWindows doit être déverrouillé. Les tests appuient vraiment sur SEND.", "El motor sigue activo con el panel oculto. ACTIVO no confirma la emisión.`nWindows debe estar desbloqueado. Las pruebas pulsan SEND."]
    translations["PROGRAMMA CONTROLLATO (COMUNE A TUTTE LE SCHEDULAZIONI)"] := ["PROGRAMMA CONTROLLATO (COMUNE A TUTTE LE SCHEDULAZIONI)", "CONTROLLED APPLICATION (SHARED BY ALL SCHEDULES)", "APPLICATION CONTRÔLÉE (COMMUNE AUX PLANIFICATIONS)", "PROGRAMA CONTROLADO (COMÚN A TODAS LAS PROGRAMACIONES)"]
    translations["Sfoglia..."] := ["Sfoglia...", "Browse...", "Parcourir...", "Examinar..."]
    translations["SCHEDULAZIONI"] := ["SCHEDULAZIONI", "SCHEDULES", "PLANIFICATIONS", "PROGRAMACIONES"]
    translations["Aggiungi"] := ["Aggiungi", "Add", "Ajouter", "Añadir"]
    translations["Modifica"] := ["Modifica", "Edit", "Modifier", "Editar"]
    translations["Duplica"] := ["Duplica", "Duplicate", "Dupliquer", "Duplicar"]
    translations["Attiva / Disattiva"] := ["Attiva / Disattiva", "Enable / Disable", "Activer / Désactiver", "Activar / Desactivar"]
    translations["Elimina"] := ["Elimina", "Delete", "Supprimer", "Eliminar"]
    translations["I giorni selezionati sono quelli dell'AVVIO. 23:00–02:00 termina il giorno successivo.`nDate extra = altri giorni di avvio. Conflitti bloccati al salvataggio."] := ["I giorni selezionati sono quelli dell'AVVIO. 23:00–02:00 termina il giorno successivo.`nDate extra = altri giorni di avvio. Conflitti bloccati al salvataggio.", "Selected days are START days. 23:00–02:00 ends the next day.`nExtra dates add more starts. Overlapping schedules cannot be saved.", "Les jours choisis sont ceux du DÉBUT. 23:00–02:00 se termine le lendemain.`nLes dates supplémentaires ajoutent des départs. Chevauchements bloqués.", "Los días elegidos son de INICIO. 23:00–02:00 termina al día siguiente.`nLas fechas extra añaden inicios. Se bloquean los solapamientos."]
    translations["SEQUENZA DI AVVIO"] := ["SEQUENZA DI AVVIO", "START SEQUENCE", "SÉQUENCE DE DÉMARRAGE", "SECUENCIA DE INICIO"]
    translations["SEQUENZA DI CHIUSURA  /  DOPO AVVIO RIUSCITO"] := ["SEQUENZA DI CHIUSURA  /  DOPO AVVIO RIUSCITO", "CLOSE SEQUENCE / AFTER SUCCESSFUL START", "SÉQUENCE DE FERMETURE / APRÈS DÉMARRAGE", "SECUENCIA DE CIERRE / TRAS INICIO CORRECTO"]
    translations["PULSANTI  /  COORDINATE RELATIVE ALLA FINESTRA"] := ["PULSANTI  /  COORDINATE RELATIVE ALLA FINESTRA", "BUTTONS / WINDOW-RELATIVE COORDINATES", "BOUTONS / COORDONNÉES RELATIVES À LA FENÊTRE", "BOTONES / COORDENADAS RELATIVAS A LA VENTANA"]
    translations["Rimuovi"] := ["Rimuovi", "Remove", "Retirer", "Eliminar"]
    translations["Modifica X / Y"] := ["Modifica X / Y", "Edit X / Y", "Modifier X / Y", "Editar X / Y"]
    translations["Registra col mouse"] := ["Registra col mouse", "Capture with mouse", "Capturer avec souris", "Capturar con ratón"]
    translations["Senza X/Y: etichetta salvabile, clic non eseguibile. Registra: Ctrl+Maiusc+C."] := ["Senza X/Y: etichetta salvabile, clic non eseguibile. Registra: Ctrl+Maiusc+C.", "Blank X/Y can be saved, but cannot be clicked. Capture: Ctrl+Shift+C.", "X/Y vides acceptés, mais clic impossible. Capture : Ctrl+Maj+C.", "X/Y vacíos se guardan, pero no permiten clic. Captura: Ctrl+Mayús+C."]
    translations["Salva"] := ["Salva", "Save", "Enregistrer", "Guardar"]
    translations["Avvio Windows"] := ["Avvio Windows", "Windows startup", "Démarrage Windows", "Inicio con Windows"]
    translations["Test avvio"] := ["Test avvio", "Test start", "Test début", "Probar inicio"]
    translations["Test chiusura"] := ["Test chiusura", "Test close", "Test fin", "Probar cierre"]
    translations["Attività e diagnosi"] := ["Attività e diagnosi", "Activity & diagnostics", "Activité et diagnostic", "Actividad y diagnóstico"]
    translations["Esci"] := ["Esci", "Exit", "Quitter", "Salir"]
    translations["Sposta su"] := ["Sposta su", "Move up", "Monter", "Subir"]
    translations["Sposta giù"] := ["Sposta giù", "Move down", "Descendre", "Bajar"]
    translations["Panoramica"] := ["Panoramica", "Overview", "Vue d’ensemble", "Resumen"]
    translations["Schedulazioni"] := ["Schedulazioni", "Schedules", "Planifications", "Programaciones"]
    translations["Sequenze"] := ["Sequenze", "Sequences", "Séquences", "Secuencias"]
    translations["Pulsanti"] := ["Pulsanti", "Buttons", "Boutons", "Botones"]
    translations["Lingua:"] := ["Lingua:", "Language:", "Langue :", "Idioma:"]
    translations["Stato"] := ["Stato", "Status", "État", "Estado"]
    translations["Nome"] := ["Nome", "Name", "Nom", "Nombre"]
    translations["Giorni"] := ["Giorni", "Days", "Jours", "Días"]
    translations["Inizio"] := ["Inizio", "Start", "Début", "Inicio"]
    translations["Fine"] := ["Fine", "End", "Fin", "Fin"]
    translations["Date extra"] := ["Date extra", "Extra dates", "Dates supplémentaires", "Fechas extra"]
    translations["Tipo"] := ["Tipo", "Action", "Action", "Acción"]
    translations["Pulsante"] := ["Pulsante", "Button", "Bouton", "Botón"]
    translations["Rip."] := ["Rip.", "Reps", "Rép.", "Rep."]
    translations["Pausa (ms)"] := ["Pausa (ms)", "Delay (ms)", "Pause (ms)", "Pausa (ms)"]
    translations["Clic"] := ["Clic", "Click", "Clic", "Clic"]
    translations["Attesa"] := ["Attesa", "Wait", "Attente", "Espera"]
    translations["Apri"] := ["Apri", "Open", "Ouvrir", "Abrir"]
    translations["Chiudi"] := ["Chiudi", "Close", "Fermer", "Cerrar"]
    translations["IN PAUSA"] := ["IN PAUSA", "PAUSED", "EN PAUSE", "EN PAUSA"]
    translations["MODIFICHE NON SALVATE"] := ["MODIFICHE NON SALVATE", "UNSAVED CHANGES", "MODIFICATIONS NON ENREGISTRÉES", "CAMBIOS SIN GUARDAR"]
    translations["ESECUZIONE IN CORSO"] := ["ESECUZIONE IN CORSO", "RUNNING ACTION", "EXÉCUTION EN COURS", "EJECUTANDO ACCIÓN"]
    translations["OPERATIVA • controllo orari attivo"] := ["OPERATIVA • controllo orari attivo", "READY • scheduling active", "OPÉRATIONNELLE • planification active", "OPERATIVA • programación activa"]
    translations["ATTIVO"] := ["ATTIVO", "ACTIVE", "ACTIF", "ACTIVO"]
    translations["INATTIVO"] := ["INATTIVO", "INACTIVE", "INACTIF", "INACTIVO"]
    translations["attivo"] := ["attivo", "active", "actif", "activo"]
    translations["disattivato"] := ["disattivato", "disabled", "désactivé", "desactivado"]
    translations["Motore: "] := ["Motore: ", "Scheduler: ", "Moteur : ", "Motor: "]
    translations["Avvio Windows: "] := ["Avvio Windows: ", "Windows startup: ", "Démarrage Windows : ", "Inicio Windows: "]
    translations["Ultimo controllo: "] := ["Ultimo controllo: ", "Last check: ", "Dernier contrôle : ", "Última comprobación: "]
    translations["SCHEDULAZIONI "] := ["SCHEDULAZIONI ", "SCHEDULES ", "PLANIFICATIONS ", "PROGRAMACIONES "]
    translations[" attive / "] := [" attive / ", " active / ", " actives / ", " activas / "]
    translations[" totali"] := [" totali", " total", " au total", " en total"]
    translations["SESSIONE       "] := ["SESSIONE       ", "SESSION       ", "SESSION       ", "SESIÓN        "]
    translations["ULTIMO CHECK   "] := ["ULTIMO CHECK   ", "LAST CHECK    ", "DERNIER TEST   ", "ÚLTIMO CONTROL"]
    translations["MOTORE         "] := ["MOTORE         ", "SCHEDULER     ", "MOTEUR         ", "MOTOR          "]
    translations["ULTIMO EVENTO  "] := ["ULTIMO EVENTO  ", "LAST EVENT    ", "DERNIER ÉVÉN.  ", "ÚLTIMO EVENTO  "]
    translations["ATTENZIONE     "] := ["ATTENZIONE     ", "WARNING       ", "ATTENTION      ", "ATENCIÓN       "]
    translations["Nessuno"] := ["Nessuno", "None", "Aucun", "Ninguno"]
    translations["Nuova schedulazione"] := ["Nuova schedulazione", "New schedule", "Nouvelle planification", "Nueva programación"]
    translations["NOME SCHEDULAZIONE"] := ["NOME SCHEDULAZIONE", "SCHEDULE NAME", "NOM DE LA PLANIFICATION", "NOMBRE DE LA PROGRAMACIÓN"]
    translations["Schedulazione attiva"] := ["Schedulazione attiva", "Schedule enabled", "Planification active", "Programación activa"]
    translations["INIZIO (HH:MM)"] := ["INIZIO (HH:MM)", "START (HH:MM)", "DÉBUT (HH:MM)", "INICIO (HH:MM)"]
    translations["FINE (HH:MM)"] := ["FINE (HH:MM)", "END (HH:MM)", "FIN (HH:MM)", "FIN (HH:MM)"]
    translations["GIORNI RICORRENTI (GIORNO DI AVVIO)"] := ["GIORNI RICORRENTI (GIORNO DI AVVIO)", "RECURRING DAYS (START DAY)", "JOURS RÉCURRENTS (JOUR DE DÉBUT)", "DÍAS RECURRENTES (DÍA DE INICIO)"]
    translations["DATE ECCEZIONALI AGGIUNTIVE (GIORNI DI AVVIO)"] := ["DATE ECCEZIONALI AGGIUNTIVE (GIORNI DI AVVIO)", "EXTRA DATES (START DAYS)", "DATES EXCEPTIONNELLES (DÉBUT)", "FECHAS EXCEPCIONALES (INICIO)"]
    translations["Annulla"] := ["Annulla", "Cancel", "Annuler", "Cancelar"]
    translations["Modifica schedulazione"] := ["Modifica schedulazione", "Edit schedule", "Modifier la planification", "Editar programación"]
    translations["Rimuovi data selezionata"] := ["Rimuovi data selezionata", "Remove selected date", "Retirer la date sélectionnée", "Eliminar fecha seleccionada"]
    translations["Le date si AGGIUNGONO ai giorni settimanali. Due schedulazioni attive non possono sovrapporsi."] := ["Le date si AGGIUNGONO ai giorni settimanali. Due schedulazioni attive non possono sovrapporsi.", "Extra dates ADD to recurring days. Enabled schedules cannot overlap.", "Les dates supplémentaires s’AJOUTENT aux jours récurrents. Aucun chevauchement.", "Las fechas extra se AÑADEN a los días recurrentes. No se permiten solapamientos."]
    translations["Se la fine precede l'inizio, termina il giorno successivo.`nEsempio: venerdi 23:00 → sabato 02:00."] := ["Se la fine precede l'inizio, termina il giorno successivo.`nEsempio: venerdi 23:00 → sabato 02:00.", "If end is earlier than start, it ends the next day.`nExample: Friday 23:00 → Saturday 02:00.", "Si la fin précède le début, elle a lieu le lendemain.`nExemple : vendredi 23:00 → samedi 02:00.", "Si fin es anterior al inicio, termina al día siguiente.`nEjemplo: viernes 23:00 → sábado 02:00."]
    translations["Lun"] := ["Lun", "Mon", "Lun", "Lun"]
    translations["Mar"] := ["Mar", "Tue", "Mar", "Mar"]
    translations["Mer"] := ["Mer", "Wed", "Mer", "Mié"]
    translations["Gio"] := ["Gio", "Thu", "Jeu", "Jue"]
    translations["Ven"] := ["Ven", "Fri", "Ven", "Vie"]
    translations["Sab"] := ["Sab", "Sat", "Sam", "Sáb"]
    translations["Dom"] := ["Dom", "Sun", "Dim", "Dom"]
    translations["Creato da Alessio Natalucci"] := ["Creato da Alessio Natalucci", "Created by Alessio Natalucci", "Créé par Alessio Natalucci", "Creado por Alessio Natalucci"]
    return translations
}
LanguageChanged(*) {
    global gLanguage, gControls, gCfg
    selected := gControls["languageSelect"].Value
    newLanguage := selected = 2 ? "en" : selected = 3 ? "fr" : selected = 4 ? "es" : "it"
    if newLanguage = gLanguage
        return
    gLanguage := newLanguage
    IniWrite(gLanguage, gCfg, "UI", "Language")
    ; Cambiare i testi senza ricreare le schede: i dati non salvati restano
    ; intatti. La tendina puo' ancora essere in fase di chiusura qui.
    ApplyUITranslations()
    RefreshViews()
    RefreshStatus()
    SetTimer(RedrawLocalizedGUI, -100)
}

; Un normale WinRedraw della finestra principale puo' lasciare gli HWND
; all'interno del dialogo di Tab3 non aggiornati. RDW_ALLCHILDREN
; ridisegna anche pulsanti, label, colonne e schede nascoste/riaperte.
RedrawLocalizedGUI(*) {
    global gMain, gTabs, gControls
    if !IsObject(gMain)
        return
    try {
        flags := 0x1 | 0x4 | 0x80 | 0x100 | 0x400 ; INVALIDATE|ERASE|ALLCHILDREN|UPDATENOW|FRAME
        DllCall("User32\RedrawWindow", "Ptr", gMain.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", flags, "Int")
        tabParent := DllCall("User32\GetParent", "Ptr", gControls["languageSelect"].Hwnd, "Ptr")
        if tabParent && tabParent != gMain.Hwnd
            DllCall("User32\RedrawWindow", "Ptr", tabParent, "Ptr", 0, "Ptr", 0, "UInt", flags, "Int")
        gTabs.Redraw()
        for key, ctrl in gControls {
            if ctrl is Array {
                for item in ctrl
                    try item.Redraw()
            } else
                try ctrl.Redraw()
        }
        Sleep(-1)
    }
}
; Rename Tab3 labels in-place: do NOT delete/re-create tabs, because
; that would change which page contains the pre-existing controls.
SetTabCaption(tabCtrl, index, label) {
    textBuffer := Buffer(StrPut(label, "UTF-16") * 2, 0)
    StrPut(label, textBuffer, "UTF-16")
    item := Buffer(A_PtrSize = 8 ? 40 : 28, 0)
    NumPut("UInt", 1, item, 0)   ; TCIF_TEXT
    NumPut("Ptr", textBuffer.Ptr, item, A_PtrSize = 8 ? 16 : 12)
    if !DllCall("User32\SendMessageW", "Ptr", tabCtrl.Hwnd, "UInt", 0x133D, "UPtr", index-1, "Ptr", item.Ptr, "Ptr")
        return false
    DllCall("User32\InvalidateRect", "Ptr", tabCtrl.Hwnd, "Ptr", 0, "Int", 1)
    return true
}
ApplyUITranslations() {
    global gControls, gTabs, gPaused
    captions := Map(
        "brandSub", "Creato da Alessio Natalucci",
        "heroLabel", "PROSSIMA ESECUZIONE",
        "overviewHead", "STATO DELLA PROGRAMMAZIONE",
        "refreshButton", "Diagnosi",
        "checkButton", "Aggiorna stato",
        "maintenanceLabel", "MANUTENZIONE (CON CONFERMA)",
        "resetWindows", "Reset impostazioni Windows",
        "resetButtons", "Reset pulsanti e sequenze",
        "overviewHelp", "Il motore resta attivo anche con pannello nascosto. La spia ATTIVO non certifica lo streaming.`nPer i clic, Windows deve essere sbloccato. I test agiscono realmente su SEND.",
        "exeLabel", "PROGRAMMA CONTROLLATO (COMUNE A TUTTE LE SCHEDULAZIONI)",
        "browse", "Sfoglia...", "scheduleTitle", "SCHEDULAZIONI",
        "scheduleHelp", "I giorni selezionati sono quelli dell'AVVIO. 23:00–02:00 termina il giorno successivo.`nDate extra = altri giorni di avvio. Conflitti bloccati al salvataggio.",
        "startLabel", "SEQUENZA DI AVVIO", "closeLabel", "SEQUENZA DI CHIUSURA  /  DOPO AVVIO RIUSCITO",
        "pointsHeading", "PULSANTI  /  COORDINATE RELATIVE ALLA FINESTRA",
        "addPoint", "Aggiungi", "deletePoint", "Rimuovi", "editPoint", "Modifica X / Y",
        "capturePoint", "Registra col mouse", "pointHelp", "Senza X/Y: etichetta salvabile, clic non eseguibile. Registra: Ctrl+Maiusc+C.",
        "save", "Salva", "startup", "Avvio Windows", "testStart", "Test avvio", "testClose", "Test chiusura", "openLog", "Attività e diagnosi", "exit", "Esci", "languageLabel", "Lingua:"
    )
    for key, original in captions {
        if gControls.Has(key) {
            translated := Tr(original)
            if gControls[key].Text != translated
                gControls[key].Text := translated
        }
    }
    gControls["pauseButton"].Text := Tr(gPaused ? "Riprendi automazione" : "Sospendi automazione")
    for i, title in ["Panoramica", "Schedulazioni", "Sequenze", "Pulsanti"]
        SetTabCaption(gTabs, i, Tr(title))
    schedCols := ["Stato", "Nome", "Giorni", "Inizio", "Fine", "Date extra"]
    for i, title in schedCols
        gControls["scheduleList"].ModifyCol(i, "", Tr(title))
    stepCols := ["#", "Tipo", "Pulsante", "Rip.", "Pausa (ms)"]
    for key in ["startList", "closeList"] {
        for i, title in stepCols
            gControls[key].ModifyCol(i, "", Tr(title))
    }
    for i, title in ["Pulsante", "X", "Y"]
        gControls["pointList"].ModifyCol(i, "", Tr(title))
    for i, title in ["Aggiungi", "Modifica", "Duplica", "Attiva / Disattiva", "Elimina"]
        gControls["scheduleButtons"][i].Text := Tr(title)
    for key in ["startActions", "closeActions"] {
        for i, title in ["Aggiungi", "Modifica", "Elimina", "Sposta su", "Sposta giù"]
            gControls[key][i].Text := Tr(title)
    }
    ; Evitare SetFont ripetuti ad ogni cambio lingua: su controlli nativi
    ; scuri causano ricalcoli e ripitture parziali finche' il mouse non passa.
}

