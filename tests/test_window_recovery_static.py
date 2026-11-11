"""Static checks for minimized-window recovery; not a Windows integration test."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
worker = (root / "CasterLiveAutomation_Worker.ahk").read_text(encoding="utf-8-sig")
checks = {
    "track successful click HWND": 'MState("CasterMainHwnd", hwnd)' in worker,
    "track successful click PID": 'MState("CasterMainPid", WinGetPID(hwnd))' in worker,
    "reuse saved process-bound HWND": "WRememberedCasterWindow()" in worker,
    "reject child windows": '0x40000000 ; WS_CHILD' in worker,
    "exclude invalid client rects": "requireClient && !hasClient" in worker,
    "wait for geometry after restore": "WWaitUsableClient(hwnd, buttonName" in worker,
    "fallback to calibrated window": 'WFindCasterWindow(true, buttonName, hwnd, true)' in worker,
    "fail closed on unresolved window": 'nessuna finestra principale con client' in worker,
    "verify active and hovered target": 'WCursorOverCaster(hwnd, screenX, screenY)' in worker,
    "no blind ControlClick": "ControlClick(" not in worker,
}
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)
assert all(checks.values()), "Window recovery static regression checks failed"
