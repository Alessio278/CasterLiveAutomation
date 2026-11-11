#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
#Include CasterLiveAutomation_ScheduleLib.ahk
Persistent()
SetTitleMatchMode(2)
CoordMode("Mouse", "Client")
SendMode("Event")
SetMouseDelay(100)

; CasterLiveAutomation v0.5.0-rc.1 - pre-release. Runtime compatibility protocol remains 5.0.
; Non eseguire azioni senza sessione confermata. Il pannello puo' essere nascosto.
wCfg := A_ScriptDir "\CasterLiveAutomation_Settings.ini"
wLogFilePath := A_ScriptDir "\CasterLiveAutomation_Log.txt"
wScheduleFile := A_ScriptDir "\CasterLiveAutomation_Schedules.ini"
wRuntime := A_ScriptDir "\CasterLiveAutomation_Runtime.ini"
wBusy := false
wLastHeartbeat := ""
wLastDecision := Map()
wLastMinute := Map()

try {
    CLAMigrateLegacyFiles(wCfg, wScheduleFile, wRuntime, wLogFilePath)
    ; Worker avviato da solo: calendario vuoto e pausa sicura al primo uso.
    if SEnsureEmptySchedules(wScheduleFile) {
        IniWrite("1", wCfg, "V3", "Paused")
        WLog("PRIMO CALENDARIO: nessuna schedulazione; Worker IN PAUSA")
    }
    if !FileExist(wRuntime) {
        FileAppend("[Session]`r`n", wRuntime, "UTF-16")
        IniWrite("idle", wRuntime, "Session", "Status")
    }
    WLog("WORKER v0.5 PRE-RELEASE AVVIATO | pianificazioni multiple con controllo conflitti")
    WState("WorkerVersion", "5.0")
    WState("WorkerStartedAt", A_Now)
    SetTimer(MCheck, 5000)
    MCheck()
} catch Error as e {
    WLog("ERRORE FATALE WORKER: " e.Message " | Riga " e.Line)
    ExitApp(1)
}
WLog(s) {
    global wLogFilePath
    try FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " | " s "`r`n", wLogFilePath, "UTF-8")
}
WState(key, value) {
    global wCfg
    IniWrite(value, wCfg, "State", key)
}
MState(key, value) {
    global wRuntime
    IniWrite(value, wRuntime, "Session", key)
}
MGet(key, fallback := "") {
    global wRuntime
    return IniRead(wRuntime, "Session", key, fallback)
}
MDecision(category, reason) {
    global wLastDecision, wLastMinute
    minute := FormatTime(A_Now, "yyyyMMddHHmm")
    previousReason := wLastDecision.Has(category) ? wLastDecision[category] : ""
    previousMinute := wLastMinute.Has(category) ? wLastMinute[category] : ""
    if reason != previousReason || minute != previousMinute {
        wLastDecision[category] := reason
        wLastMinute[category] := minute
        WLog("VERIFICA " category " | " reason)
    }
    WState("WorkerLast" category "Decision", reason)
}
MCheck(*) {
    global wCfg, wBusy, wLastHeartbeat, wScheduleFile
    try {
        if IniRead(wCfg, "State", "WorkerStopRequested", "0") = "1" {
            WLog("WORKER FERMATO SU RICHIESTA")
            ExitApp()
        }
        now := A_Now
        minute := FormatTime(now, "yyyyMMddHHmm")
        if minute != wLastHeartbeat {
            wLastHeartbeat := minute
            WState("WorkerHeartbeat", now)
            WState("WorkerLastCheck", FormatTime(now, "dd/MM/yyyy HH:mm:ss"))
            WLog("WORKER ATTIVO | " minute)
        }
        if wBusy
            return
        if IniRead(wCfg, "V3", "Paused", "1") = "1" {
            MDecision("STATO", "Automazione sospesa")
            return
        }
        if !FileExist(wScheduleFile) {
            MDecision("STATO", "File schedulazioni non trovato")
            return
        }
        try {
            jobs := SReadAll(wScheduleFile)
            SValidateAll(jobs)
        } catch Error as e {
            WState("V3LastError", "Calendario non valido: " e.Message)
            MDecision("STATO", "Calendario non valido: " e.Message)
            return
        }
        sessionState := MGet("Status", "idle")
        if sessionState = "running" {
            endStamp := MGet("EndStamp")
            token := MGet("Token")
            if !RegExMatch(endStamp, "^\d{14}$") {
                MDecision("CLOSE", "Sessione attiva con chiusura mancante; intervento manuale")
                return
            }
            late := DateDiff(now, endStamp, "Seconds")
            if late < 0 {
                MDecision("CLOSE", "Sessione " token " | chiusura " FormatTime(endStamp, "dd/MM HH:mm"))
                return
            }
            if late > 900 {
                MDecision("CLOSE", "Chiusura superata di " late " secondi: verifica SEND manualmente")
                return
            }
            MExecuteClose(token)
            return
        }
        if sessionState != "idle" && sessionState != "complete" {
            MDecision("STATO", "Stato sessione '" sessionState "': controllare Caster e risolvere prima di riprendere")
            return
        }
        today := SubStr(now, 1, 8) "000000"
        for job in jobs {
            if job["Enabled"] != "1" || !SAllowed(job, today)
                continue
            event := SOccurrence(job, today)
            late := DateDiff(now, event["Start"], "Seconds")
            if late < 0 || late > 180
                continue
            if MGet("LastAttemptToken") = event["Token"] {
                MDecision("START", "Evento " event["Token"] " già tentato")
                return
            }
            MExecuteStart(event)
            return
        }
        MDecision("START", "Nessun avvio previsto in questa finestra di 3 minuti")
    } catch Error as e {
        WState("V3LastError", "Worker scheduler: " e.Message " riga " e.Line)
        WLog("ERRORE TIMER: " e.Message " | riga " e.Line " | " e.File)
    }
}
MExecuteStart(event) {
    global wCfg, wBusy
    process := IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
    if WFindCasterWindow(true) || ProcessExist(process) {
        MDecision("START", "BLOCCATO: programma già aperto. Stato SEND non verificabile")
        return
    }
    try {
        steps := WReadSteps("StepsStart")
        WCheckSteps(steps, "start")
        executable := IniRead(wCfg, "Config", "ExePath", "")
        if !FileExist(executable)
            throw Error("Eseguibile non trovato: " executable)
    } catch Error as e {
        MDecision("START", "Configurazione START errata: " e.Message)
        return
    }
    wBusy := true
    MState("LastAttemptToken", event["Token"])
    MState("Token", event["Token"])
    MState("EndStamp", event["End"])
    MState("ScheduleId", event["Id"])
    MState("Status", "starting")
    WLog("TRIGGER START | " event["Name"] " | " FormatTime(event["Start"], "yyyy-MM-dd HH:mm") " | " event["Token"])
    try {
        WExecuteFlow("start", steps)
        if !WFindCasterWindow(true)
            throw Error("Programma assente dopo START")
        MState("Status", "running")
        MState("LastStartToken", event["Token"])
        WState("WorkerLastEvent", "OK START " event["Name"] " " event["Token"])
        WState("V3LastError", "")
        WLog("OK START | " event["Token"] " | CLOSE " FormatTime(event["End"], "dd/MM HH:mm"))
    } catch Error as e {
        MState("Status", "start_error")
        WState("V3LastError", "START: " e.Message)
        WLog("ERRORE START | " e.Message " | riga " e.Line " | controllare SEND")
    } finally {
        wBusy := false
    }
}
MExecuteClose(token) {
    global wCfg, wBusy
    if MGet("LastCloseAttemptToken") = token {
        MDecision("CLOSE", "CLOSE già tentato per la sessione " token)
        return
    }
    caster := WFindCasterWindow(true)
    if !caster {
        MDecision("CLOSE", "Finestra assente: non eseguo clic e non forzo chiusura")
        return
    }
    try {
        steps := WReadSteps("StepsClose")
        WCheckSteps(steps, "close")
    } catch Error as e {
        MDecision("CLOSE", "Sequenza CLOSE non valida: " e.Message)
        return
    }
    wBusy := true
    MState("LastCloseAttemptToken", token)
    MState("Status", "closing")
    WLog("TRIGGER CLOSE | token=" token " | Caster HWND=" caster)
    try {
        WExecuteFlow("close", steps)
        MState("Status", "complete")
        MState("LastCloseToken", token)
        WState("WorkerLastEvent", "OK CLOSE " token)
        WState("V3LastError", "")
        WLog("OK CLOSE | token=" token)
    } catch Error as e {
        MState("Status", "close_error")
        WState("V3LastError", "CLOSE: " e.Message)
        WLog("ERRORE CLOSE | " e.Message " | riga " e.Line " | controllare SEND")
    } finally {
        wBusy := false
    }
}

; --- Funzioni di esecuzione preservate dal Worker stabile V3.11 ---
WReadSteps(section) {
    global wCfg
    rows := []
    count := IniRead(wCfg, section, "Count", "0") + 0
    Loop Min(100, Max(0, count)) {
        p := StrSplit(IniRead(wCfg, section, "Step" A_Index, ""), "|")
        if p.Length >= 4
            rows.Push(Map("kind", p[1], "button", p[2], "repeat", p[3]+0, "pause", p[4]+0))
    }
    return rows
}
WCheckSteps(steps, flow) {
    global wCfg
    if !steps.Length
        throw Error("Sequenza " flow " vuota")
    for i, s in steps {
        kind := s["kind"]
        if kind = "click" {
            p := StrSplit(IniRead(wCfg, "Points", s["button"], ""), ",")
            if p.Length != 2 || !RegExMatch(Trim(p[1]), "^-?\d+$") || !RegExMatch(Trim(p[2]), "^-?\d+$")
                throw Error("Coordinate mancanti o non valide per " s["button"])
            if IniRead(wCfg, "PointClientSize", s["button"], "") = ""
                throw Error("Pulsante " s["button"] " senza calibrazione dimensioni: registralo di nuovo col mouse per la sicurezza dei clic")
            if s["repeat"] < 1 || s["repeat"] > 30
                throw Error("Ripetizioni non valide, passo " i)
        } else if kind != "wait" && kind != "open" && kind != "close"
            throw Error("Azione sconosciuta, passo " i)
        if s["pause"] < 0 || s["pause"] > 600000
            throw Error("Pausa non valida, passo " i)
        if flow = "start" && kind = "close"
            throw Error("Avvio non può chiudere il programma")
        if flow = "close" && kind = "close" && i != steps.Length
            throw Error("Chiudi deve essere ultimo passo")
    }
    if flow = "close" && steps[steps.Length]["kind"] != "close"
        throw Error("Sequenza di chiusura deve terminare con Chiudi")
}

WExecuteFlow(flow, steps) {
    global wCfg
    target := "ahk_exe " IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
    ; Sequenze precedenti: continuano ad aprire il programma implicitamente.
    if flow = "start" && !WFlowHasOpenStep(steps)
        WOpenProgram()
    for i, s in steps {
        WLog("PASSO " i "/" steps.Length " - " s["kind"] " " s["button"])
        if s["kind"] = "click" {
            Loop s["repeat"] {
                WClick(s["button"])
                if s["pause"] > 0
                    Sleep(s["pause"])
            }
        } else if s["kind"] = "wait"
            Sleep(s["pause"])
        else if s["kind"] = "open" {
            WOpenProgram()
            if s["pause"] > 0
                Sleep(s["pause"])
        } else if s["kind"] = "close"
            WClose()
    }
}

WFlowHasOpenStep(steps) {
    for step in steps
        if step["kind"] = "open"
            return true
    return false
}
WOpenProgram() {
    global wCfg
    target := "ahk_exe " IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
    hwnd := WFindCasterWindow(true)
    processName := IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
    if !hwnd && !ProcessExist(processName) {
        exe := IniRead(wCfg, "Config", "ExePath", "")
        if !FileExist(exe)
            throw Error("Eseguibile non trovato: " exe)
        WLog("APRI programma | " exe)
        Run('"' exe '"')
    } else
        WLog("APRI: programma gia' aperto; attesa finestra")
    ; Prima prova a rilevare anche le finestre nascoste nel tray.
    deadline := DateAdd(A_Now, 45, "Seconds")
    while !WFindCasterWindow(true) {
        if DateDiff(A_Now, deadline, "Seconds") >= 0
            throw Error("Finestra non disponibile entro 45 secondi dopo APRI")
        Sleep(250)
    }
    Sleep(1500)
}

; Return the most plausible *main* Caster window, not the first WinExist() hit.
; Caster can expose a different 0x0 helper HWND while the main window is minimized.
WIsCasterWindow(hwnd) {
    global wCfg
    if !hwnd || !DllCall("User32\IsWindow", "Ptr", hwnd, "Int")
        return false
    try {
        expectedProcess := StrLower(IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe"))
        if StrLower(WinGetProcessName(hwnd)) != expectedProcess
            return false
        if DllCall("User32\GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr") != hwnd
            return false
        if WinGetStyle(hwnd) & 0x40000000 ; WS_CHILD
            return false
        return true
    } catch Error {
        return false
    }
}

WRememberedCasterWindow() {
    hwndText := MGet("CasterMainHwnd", "")
    if !RegExMatch(hwndText, "^\d+$")
        return 0
    hwnd := Integer(hwndText)
    if !WIsCasterWindow(hwnd)
        return 0
    recordedPid := MGet("CasterMainPid", "")
    try {
        if recordedPid != "" && WinGetPID(hwnd) != Integer(recordedPid)
            return 0
    } catch Error {
        return 0
    }
    return hwnd
}

WFindCasterWindow(allowHidden := false, buttonName := "", excludeHwnd := 0, requireClient := false) {
    global wCfg
    processName := IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
    expectedSize := buttonName = "" ? "" : IniRead(wCfg, "PointClientSize", buttonName, "")
    remembered := WRememberedCasterWindow()
    best := 0, bestScore := -100000
    previous := DetectHiddenWindows(allowHidden)
    try {
        for candidate in WinGetList("ahk_exe " processName) {
            if candidate = excludeHwnd || !WIsCasterWindow(candidate)
                continue
            try {
                dims := WClientDimensions(candidate)
                hasClient := dims[1] > 0 && dims[2] > 0
                if requireClient && !hasClient
                    continue
                match := expectedSize != "" && hasClient && expectedSize = dims[1] "x" dims[2]
                isVisible := DllCall("User32\IsWindowVisible", "Ptr", candidate, "Int")
                title := StrLower(Trim(WinGetTitle(candidate)))
                owner := DllCall("User32\GetWindow", "Ptr", candidate, "UInt", 4, "Ptr")
                mm := WinGetMinMax(candidate)
                score := (match ? 12000 : 0) + (hasClient ? 2000 : 0)
                score += candidate = remembered ? 900 : 0
                score += isVisible ? 200 : 0
                score += mm = -1 ? 0 : 100
                score += (InStr(title, "caster") || InStr(title, "live dj")) ? 200 : 0
                score -= owner ? 300 : 0
                score -= title = "" ? 250 : 0
                if score > bestScore {
                    best := candidate
                    bestScore := score
                }
            } catch Error {
                continue
            }
        }
    } finally {
        DetectHiddenWindows(previous)
    }
    return best
}

; Include detailed candidate dimensions when recovery fails; never guess a click.
WDescribeCasterWindows() {
    global wCfg
    previous := DetectHiddenWindows(true)
    details := ""
    try {
        processName := IniRead(wCfg, "Config", "Process", "CasterLive DJ.exe")
        for candidate in WinGetList("ahk_exe " processName) {
            if !WIsCasterWindow(candidate)
                continue
            try {
                size := WClientDimensions(candidate)
                title := WinGetTitle(candidate)
                details .= (details = "" ? "" : "; ") candidate "=" size[1] "x" size[2] " (" WWindowState(candidate) ", " title ")"
            } catch Error {
                continue
            }
        }
    } finally {
        DetectHiddenWindows(previous)
    }
    return details = "" ? "nessuna finestra principale trovata" : details
}

WWindowState(hwnd) {
    visible := DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
    mm := WinGetMinMax(hwnd)
    return (visible ? "visibile" : "nascosta") "/" (mm = -1 ? "minimizzata" : mm = 1 ? "massimizzata" : "normale")
}

; Restore the specific window, checking focus before any mouse operation.
WBringCasterToFront(hwnd, action) {
    if !WIsCasterWindow(hwnd)
        throw Error("Finestra CasterLive DJ non piu' valida prima di " action)
    WLog("RIPRISTINO prima di " action " | HWND=" hwnd " | prima=" WWindowState(hwnd))
    if !DllCall("User32\IsWindowVisible", "Ptr", hwnd, "Int") {
        WinShow(hwnd)
        Sleep(500)
    }
    if WinGetMinMax(hwnd) = -1 {
        WinRestore(hwnd)
        Sleep(500)
    }
    WinActivate(hwnd)
    if !WinWaitActive(hwnd, , 10)
        throw Error("Impossibile attivare CasterLive DJ prima di " action ". Controlla desktop sbloccato e privilegi Windows")
    if !DllCall("User32\IsWindowVisible", "Ptr", hwnd, "Int") || WinGetMinMax(hwnd) = -1
        throw Error("CasterLive DJ e' ancora nascosto/minimizzato; non eseguo " action)
    WLog("RIPRISTINO OK prima di " action " | dopo=" WWindowState(hwnd))
}

; After restoring from the tray, some Caster HWNDs report 0x0 transiently.
; Wait for real geometry, otherwise the click MUST be refused.
WWaitUsableClient(hwnd, buttonName, timeoutMs := 4000) {
    deadline := A_TickCount + timeoutMs
    loop {
        if !WIsCasterWindow(hwnd)
            throw Error("Finestra non piu' valida dopo ripristino: " hwnd)
        size := WClientDimensions(hwnd)
        if size[1] > 0 && size[2] > 0
            return size
        if A_TickCount >= deadline
            break
        Sleep(200)
    }
    throw Error("HWND " hwnd " mantiene area client 0x0 dopo il ripristino prima di " buttonName)
}

; Prefer the HWND successfully used at START; fail over only to a calibrated
; same-process top-level window when Caster recreated its main window.
WResolveCasterForClick(buttonName, recordedSize) {
    hwnd := WRememberedCasterWindow()
    if !hwnd
        hwnd := WFindCasterWindow(true, buttonName)
    if !hwnd
        throw Error("Finestra CasterLive DJ non trovata prima di " buttonName)
    firstError := ""
    try {
        WBringCasterToFront(hwnd, buttonName)
        size := WWaitUsableClient(hwnd, buttonName)
        if size[1] "x" size[2] = recordedSize
            return hwnd
        firstError := "dimensioni HWND " hwnd " " size[1] "x" size[2] " diverse dalla calibrazione " recordedSize
    } catch Error as e {
        firstError := e.Message
    }
    WLog("RECUPERO FINESTRA prima di " buttonName " | " firstError)
    replacement := WFindCasterWindow(true, buttonName, hwnd, true)
    if replacement {
        try {
            WBringCasterToFront(replacement, buttonName)
            size := WWaitUsableClient(replacement, buttonName)
            if size[1] "x" size[2] = recordedSize {
                WLog("FINESTRA RECUPERATA | prima=" hwnd " | attuale=" replacement " | client=" recordedSize)
                return replacement
            }
            firstError .= "; candidato " replacement " con dimensioni " size[1] "x" size[2]
        } catch Error as e {
            firstError .= "; alternativa fallita: " e.Message
        }
    }
    WLog("FINESTRE CASTER DISPONIBILI | " WDescribeCasterWindows())
    throw Error("CLIC BLOCCATO " buttonName ": nessuna finestra principale con client " recordedSize ". " firstError)
}

; Return the current client dimensions. A moved window has the same client size;
; a resized/maximized window may move its buttons inside the client area.
WClientDimensions(hwnd) {
    rect := Buffer(16, 0)
    if !DllCall("User32\GetClientRect", "Ptr", hwnd, "Ptr", rect, "Int")
        throw Error("Impossibile leggere l'area client di CasterLive DJ")
    return [NumGet(rect, 8, "Int"), NumGet(rect, 12, "Int")]
}

; Confirm the cursor is physically over the SAME top-level Caster window.
; This refuses a click if another app, the desktop, or an overlay is on top.
WCursorOverCaster(targetHwnd, expectedX, expectedY) {
    MouseGetPos(&actualX, &actualY, &hoverHwnd)
    if Abs(actualX - expectedX) > 2 || Abs(actualY - expectedY) > 2
        return false
    if !hoverHwnd
        return false
    targetRoot := DllCall("User32\GetAncestor", "Ptr", targetHwnd, "UInt", 2, "Ptr")
    hoveredRoot := DllCall("User32\GetAncestor", "Ptr", hoverHwnd, "UInt", 2, "Ptr")
    if !targetRoot || hoveredRoot != targetRoot
        return false
    return WinGetPID("ahk_id " hoverHwnd) = WinGetPID("ahk_id " targetHwnd)
}

; All coordinates in [Points] are CLIENT coordinates from the recording window.
; Resolve them against the current HWND for EVERY click, after restoring it.
; Do not rely on the globally active window for coordinate conversion.
WClick(name) {
    global wCfg
    p := StrSplit(IniRead(wCfg, "Points", name, ""), ",")
    if p.Length != 2 || !RegExMatch(Trim(p[1]), "^-?\d+$") || !RegExMatch(Trim(p[2]), "^-?\d+$")
        throw Error("Coordinate non valide per " name)
    clientX := Integer(Trim(p[1]))
    clientY := Integer(Trim(p[2]))

    ; Fail closed: no click without a known client geometry, even after tray restore.
    recordedSize := IniRead(wCfg, "PointClientSize", name, "")
    if recordedSize = ""
        throw Error("CLIC BLOCCATO " name ": calibrazione assente; registra nuovamente il pulsante col mouse")
    hwnd := WResolveCasterForClick(name, recordedSize)
    Sleep(180)
    if !WinActive(hwnd)
        throw Error("Caster non e' piu' attivo prima di " name "; clic annullato")
    size := WClientDimensions(hwnd)
    if clientX < 0 || clientY < 0 || clientX >= size[1] || clientY >= size[2]
        throw Error("CLIC BLOCCATO " name ": punto " clientX "," clientY " fuori area client " size[1] "x" size[2])
    if recordedSize != size[1] "x" size[2]
        throw Error("CLIC BLOCCATO " name ": finestra modificata durante il recupero (registrata " recordedSize ", attuale " size[1] "x" size[2] ")")

    pt := Buffer(8, 0)
    NumPut("Int", clientX, pt, 0)
    NumPut("Int", clientY, pt, 4)
    if !DllCall("User32\ClientToScreen", "Ptr", hwnd, "Ptr", pt, "Int")
        throw Error("Impossibile convertire in coordinate schermo il pulsante " name)
    screenX := NumGet(pt, 0, "Int")
    screenY := NumGet(pt, 4, "Int")

    ; Explicit screen coordinates, then independently verify the hovered HWND.
    ; Only AFTER both checks do we emit an actual mouse-down/up event.
    previousMode := CoordMode("Mouse", "Screen")
    try {
        MouseMove(screenX, screenY, 0)
        Sleep(100)
        if !WinActive(hwnd)
            throw Error("CLIC BLOCCATO " name ": Caster ha perso il focus")
        if !WCursorOverCaster(hwnd, screenX, screenY)
            throw Error("CLIC BLOCCATO " name ": sotto il puntatore non c'e' CasterLive DJ")
        ; Detect window movement between conversion and actual click.
        freshPt := Buffer(8, 0)
        NumPut("Int", clientX, freshPt, 0)
        NumPut("Int", clientY, freshPt, 4)
        if !DllCall("User32\ClientToScreen", "Ptr", hwnd, "Ptr", freshPt, "Int")
            throw Error("CLIC BLOCCATO " name ": impossibile ricontrollare la posizione")
        if NumGet(freshPt, 0, "Int") != screenX || NumGet(freshPt, 4, "Int") != screenY
            throw Error("CLIC BLOCCATO " name ": finestra spostata durante il clic")
        MouseClick("Left")
        MState("CasterMainHwnd", hwnd)
        MState("CasterMainPid", WinGetPID(hwnd))
        WLog("CLIC " name " | client=" clientX "," clientY " | schermo=" screenX "," screenY " | HWND=" hwnd)
    } finally {
        CoordMode("Mouse", previousMode)
    }
}
WClose() {
    hwnd := WRememberedCasterWindow()
    if !hwnd
        hwnd := WFindCasterWindow(true)
    if !hwnd
        throw Error("Finestra CasterLive DJ non trovata durante la chiusura")
    WLog("RICHIESTA CHIUSURA | HWND=" hwnd " | " WWindowState(hwnd))
    WinClose(hwnd)
    if !WinWaitClose(hwnd, , 12)
        throw Error("Chiusura normale non riuscita: non forzo il processo")
    WLog("FINESTRA CHIUSA")
}
