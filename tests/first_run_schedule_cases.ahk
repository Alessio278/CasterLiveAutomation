#Requires AutoHotkey v2.0
#Include ..\CasterLiveAutomation_ScheduleLib.ahk

; Test senza aprire CasterLive DJ e senza toccare configurazioni reali.
folder := A_Temp "\CasterLiveAutomation_Test_" A_TickCount
path := folder "\CasterLiveAutomation_Schedules.ini"
try {
    DirCreate(folder)
    if !SEnsureEmptySchedules(path)
        throw Error("Un calendario nuovo deve essere creato")
    if !FileExist(path) || SReadAll(path).Length != 0
        throw Error("Calendario iniziale non vuoto")
    if SEnsureEmptySchedules(path)
        throw Error("Non deve ricreare un calendario esistente")
    sample := SDefaultSchedule()
    SWriteAll(path, [sample])
    if SEnsureEmptySchedules(path)
        throw Error("Un calendario salvato non va sovrascritto")
    jobs := SReadAll(path)
    if jobs.Length != 1 || jobs[1]["Name"] != sample["Name"]
        throw Error("La schedulazione esistente e' stata alterata")
    MsgBox("Test calendario iniziale vuoto e conservazione riusciti.", "CasterLiveAutomation")
} catch Error as e {
    MsgBox("TEST FALLITO: " e.Message " (riga " e.Line ")", "CasterLiveAutomation", "Icon!")
    ExitApp(1)
} finally {
    try FileDelete(path)
    try FileDelete(path ".bak")
    try DirDelete(folder)
}
ExitApp(0)
