#Requires AutoHotkey v2.0
#Include ..\CasterLiveAutomation_ScheduleLib.ahk

; Test senza accesso a CasterLive DJ: eseguibile con AutoHotkey v2 su Windows.
try {
    friday := Map("Id", "1", "Name", "Venerdi notte", "Enabled", "1", "StartTime", "23:00",
        "EndTime", "02:00", "Days", "Friday", "Dates", "")
    saturday := Map("Id", "2", "Name", "Sabato notte", "Enabled", "1", "StartTime", "23:00",
        "EndTime", "02:00", "Days", "Saturday", "Dates", "")
    SValidateAll([friday, saturday])
    Assert(SOccurrence(friday, "20261106000000")["End"] = "20261107020000", "Friday overnight")
    Assert(SAllowed(friday, "20261106000000"), "Friday allowed")
    Assert(!SAllowed(friday, "20261107000000"), "Saturday not allowed")

    ; Conflitto vero: sabato 01:00 durante una sessione iniziata venerdi 23:00.
    overlap := Map("Id", "3", "Name", "Sabato mattina", "Enabled", "1", "StartTime", "01:00",
        "EndTime", "03:00", "Days", "Saturday", "Dates", "")
    AssertConflicts([friday, overlap], "overnight vs next-day morning")

    ; Intervalli che si toccano a 02:00 non si sovrappongono.
    overlap["StartTime"] := "02:00"
    overlap["EndTime"] := "04:00"
    SValidateAll([friday, overlap])

    ; Una schedulazione disabilitata non genera conflitti.
    overlap["StartTime"] := "01:00"
    overlap["Enabled"] := "0"
    SValidateAll([friday, overlap])

    ; Eccezione 31 dicembre che attraversa il capodanno.
    special := Map("Id", "4", "Name", "Capodanno", "Enabled", "1", "StartTime", "23:00",
        "EndTime", "02:00", "Days", "", "Dates", "2026-12-31")
    Assert(SOccurrence(special, "20261231000000")["End"] = "20270101020000", "New Year end")
    conflictSpecial := Map("Id", "5", "Name", "01 gennaio", "Enabled", "1", "StartTime", "01:00",
        "EndTime", "03:00", "Days", "", "Dates", "2027-01-01")
    AssertConflicts([special, conflictSpecial], "extra date cross-year")

    ; La stessa data presente anche tra i ricorrenti deve valere una sola volta.
    friday["Dates"] := "2026-11-06"
    SValidateAll([friday])

    MsgBox("Tutti i test logici del calendario sono riusciti.", "CasterLiveAutomation")
    ExitApp(0)
} catch Error as e {
    MsgBox("TEST FALLITO: " e.Message "`nRiga: " e.Line, "CasterLiveAutomation", "Icon!")
    ExitApp(1)
}
Assert(value, message) {
    if !value
        throw Error(message)
}
AssertConflicts(jobs, label) {
    conflict := false
    try SValidateAll(jobs)
    catch Error
        conflict := true
    Assert(conflict, "Conflitto non rilevato: " label)
}
