; CasterLiveAutomation v5 - calendario condiviso tra GUI e Worker.
; Le date speciali sono DATE DI AVVIO. La chiusura puo' essere il giorno dopo.


; Migrazione non distruttiva dalla V5.0 precedente.
; Non sovrascrive MAI un file nuovo: la configurazione gia' presente ha priorita'.
; Necessaria sia alla GUI sia al Worker, che possono essere avviati separatamente.
CLAMigrateLegacyFiles(settingsPath, schedulesPath, runtimePath, logPath) {
    legacy := [
        [settingsPath, A_ScriptDir "\CasterLiveDJ_Configurazione.ini"],
        [schedulesPath, A_ScriptDir "\CasterAutomation_Schedules.ini"],
        [runtimePath, A_ScriptDir "\CasterAutomation_Runtime.ini"],
        [logPath, A_ScriptDir "\CasterLiveDJ_Log.txt"]
    ]
    for item in legacy {
        destination := item[1], source := item[2]
        if FileExist(destination) || !FileExist(source)
            continue
        try FileCopy(source, destination, false)
        catch Error as err
            throw Error("Migrazione dei file di CasterLiveAutomation non riuscita: " source " -> " destination " | " err.Message)
    }
}

SClockMinutes(hhmm) {
    return (SubStr(hhmm, 1, 2) + 0) * 60 + (SubStr(hhmm, 4, 2) + 0)
}
SValidTime(value) {
    return !!RegExMatch(value, "^([01]\d|2[0-3]):[0-5]\d$")
}
SWeekdays() {
    return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
}
SJoin(items, separator) {
    result := ""
    for item in items
        result .= (result = "" ? "" : separator) item
    return result
}
SDefaultSchedule() {
    return Map("Id", "1", "Name", "Programmazione principale", "Enabled", "1",
        "StartTime", "00:01", "EndTime", "02:00", "Days", "Saturday,Sunday", "Dates", "")
}
SEnsureEmptySchedules(scheduleFile) {
    ; Ritorna true solo alla creazione. Se esiste, non sovrascrive MAI.
    if FileExist(scheduleFile)
        return false
    SWriteAll(scheduleFile, [])
    return true
}
SReadAll(file) {
    jobs := []
    if !FileExist(file)
        return jobs
    rawIds := IniRead(file, "Schedules", "Ids", "")
    if rawIds = ""
        return jobs
    seen := Map()
    for rawId in StrSplit(rawIds, ",") {
        id := Trim(rawId)
        if !RegExMatch(id, "^\d{1,8}$") || seen.Has(id)
            throw Error("Identificatore schedulazione errato: " id)
        seen[id] := true
        section := "Job_" id
        jobs.Push(Map("Id", id,
            "Name", IniRead(file, section, "Name", "Schedulazione " id),
            "Enabled", IniRead(file, section, "Enabled", "1"),
            "StartTime", IniRead(file, section, "StartTime", ""),
            "EndTime", IniRead(file, section, "EndTime", ""),
            "Days", IniRead(file, section, "Days", ""),
            "Dates", IniRead(file, section, "Dates", "")))
    }
    return jobs
}
SWriteAll(file, jobs) {
    SValidateAll(jobs)
    tmp := file ".writing"
    if FileExist(tmp)
        FileDelete(tmp)
    try {
        FileAppend("[Schedules]`r`n", tmp, "UTF-16")
        ids := []
        for job in jobs
            ids.Push(job["Id"])
        IniWrite("1", tmp, "Schedules", "Schema")
        IniWrite(SJoin(ids, ","), tmp, "Schedules", "Ids")
        for job in jobs {
            section := "Job_" job["Id"]
            for key in ["Name", "Enabled", "StartTime", "EndTime", "Days", "Dates"]
                IniWrite(job[key], tmp, section, key)
        }
        if FileExist(file)
            FileCopy(file, file ".bak", true)
        FileMove(tmp, file, true)
    } catch Error as e {
        try FileDelete(tmp)
        throw e
    }
}
SValidDate(date) {
    if !RegExMatch(date, "^\d{4}-\d{2}-\d{2}$")
        return false
    try {
        stamp := StrReplace(date, "-", "") "000000"
        return FormatTime(stamp, "yyyy-MM-dd") = date
    } catch Error {
        return false
    }
}
SValidJob(job) {
    if !RegExMatch(job["Id"], "^\d{1,8}$")
        throw Error("ID schedulazione non valido")
    if Trim(job["Name"]) = "" || StrLen(job["Name"]) > 60 || InStr(job["Name"], "|")
        throw Error("Nome schedulazione non valido (massimo 60 caratteri)")
    if job["Enabled"] != "0" && job["Enabled"] != "1"
        throw Error("Stato attivazione non valido: " job["Name"])
    if !SValidTime(job["StartTime"]) || !SValidTime(job["EndTime"])
        throw Error("Usa orari HH:MM: " job["Name"])
    if job["StartTime"] = job["EndTime"]
        throw Error("Avvio e fine non possono coincidere: " job["Name"])
    allowed := SWeekdays()
    haveDay := false
    for d in StrSplit(job["Days"], ",") {
        if d = ""
            continue
        found := false
        for a in allowed
            if a = d
                found := true
        if !found
            throw Error("Giorno non valido: " d)
        haveDay := true
    }
    unique := Map()
    for d in StrSplit(job["Dates"], "|") {
        if d = ""
            continue
        if !SValidDate(d)
            throw Error("Data eccezionale non valida: " d)
        if unique.Has(d)
            throw Error("Data ripetuta: " d)
        unique[d] := true
        if unique.Count > 50
            throw Error("Massimo 50 date aggiuntive per schedulazione")
        haveDay := true
    }
    if !haveDay
        throw Error("Seleziona almeno un giorno o una data: " job["Name"])
}
SAllowed(job, dayStamp) {
    date := FormatTime(dayStamp, "yyyy-MM-dd")
    dayIndex := FormatTime(dayStamp, "WDay") + 0
    english := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    return InStr("," job["Days"] ",", "," english[dayIndex] ",") > 0
        || InStr("|" job["Dates"] "|", "|" date "|") > 0
}
SOccurrence(job, dayStamp) {
    st := SubStr(dayStamp, 1, 8) StrReplace(job["StartTime"], ":", "") "00"
    finishDay := dayStamp
    if SClockMinutes(job["EndTime"]) < SClockMinutes(job["StartTime"])
        finishDay := DateAdd(dayStamp, 1, "Days")
    en := SubStr(finishDay, 1, 8) StrReplace(job["EndTime"], ":", "") "00"
    return Map("Id", job["Id"], "Name", job["Name"], "Start", st,
        "End", en, "Token", job["Id"] "_" FormatTime(st, "yyyyMMddHHmm"))
}
SValidateAll(jobs) {
    if jobs.Length > 40
        throw Error("Massimo 40 schedulazioni")
    ids := Map()
    for job in jobs {
        SValidJob(job)
        if ids.Has(job["Id"])
            throw Error("ID duplicato: " job["Id"])
        ids[job["Id"]] := true
    }
    ; Dimostrazione di conflitti settimanali in una finestra di 16 giorni.
    ; Per ogni data eccezionale controlla anche i due giorni adiacenti.
    dates := Map()
    monday := "20260105000000"
    Loop 16 {
        day := DateAdd(monday, A_Index - 1, "Days")
        dates[FormatTime(day, "yyyyMMdd")] := true
    }
    for job in jobs {
        if job["Enabled"] != "1"
            continue
        for date in StrSplit(job["Dates"], "|") {
            if date = ""
                continue
            stamp := StrReplace(date, "-", "") "000000"
            Loop 5 {
                probe := DateAdd(stamp, A_Index - 3, "Days")
                dates[FormatTime(probe, "yyyyMMdd")] := true
            }
        }
    }
    ; Tutti gli intervalli durano meno di 24 ore: basta confrontare
    ; quelli iniziati nello stesso giorno e nel giorno precedente.
    ; Il controllo resta valido per ricorrenze settimanali e date future.
    for dateKey in dates {
        day := dateKey "000000"
        yesterday := DateAdd(day, -1, "Days")
        current := [], previous := []
        for job in jobs {
            if job["Enabled"] != "1"
                continue
            if SAllowed(job, day)
                current.Push(SOccurrence(job, day))
            if SAllowed(job, yesterday)
                previous.Push(SOccurrence(job, yesterday))
        }
        for i, first in current {
            for second in previous
                SAssertNoOverlap(first, second)
            Loop current.Length - i
                SAssertNoOverlap(first, current[i + A_Index])
        }
    }
}
SAssertNoOverlap(first, second) {
    if first["Start"] < second["End"] && second["Start"] < first["End"] {
        msg := "Intervalli sovrapposti: '" first["Name"] "' (" FormatTime(first["Start"], "dd/MM HH:mm")
        msg .= "–" FormatTime(first["End"], "dd/MM HH:mm") ") e '" second["Name"] "' ("
        msg .= FormatTime(second["Start"], "dd/MM HH:mm") "–" FormatTime(second["End"], "dd/MM HH:mm") ")"
        throw Error(msg)
    }
}
SNextEvent(jobs, now := "", horizonDays := 400) {
    if now = ""
        now := A_Now
    base := SubStr(now, 1, 8) "000000"
    nearest := ""
    description := "Nessun evento nei prossimi " horizonDays " giorni"
    Loop horizonDays + 2 {
        day := DateAdd(base, A_Index - 2, "Days")
        for job in jobs {
            if job["Enabled"] != "1" || !SAllowed(job, day)
                continue
            event := SOccurrence(job, day)
            for flow in ["Start", "End"] {
                stamp := event[flow]
                if stamp < now
                    continue
                if nearest = "" || stamp < nearest {
                    nearest := stamp
                    description := (flow = "Start" ? "AVVIO" : "CHIUSURA") " · " job["Name"] " · " FormatTime(stamp, "dd/MM/yyyy HH:mm")
                }
            }
        }
    }
    return description
}
