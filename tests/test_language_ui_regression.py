"""Static language UI regression checks (no AHK interpreter required)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
gui = (root / "CasterLiveAutomation_V5.ahk").read_text(encoding="utf-8-sig")
assert 'x465 y152 w147 r4 Choose' in gui
assert 'x465 y152 w147 h28' not in gui
assert 'gControls["languageSelect"].Move(w-175, 152, 147)' in gui
assert 'gControls["languageSelect"].Move(w-175, 152, 147, 28)' not in gui
assert 'SetTimer(RedrawLocalizedGUI, -100)' in gui
assert 'RedrawLocalizedGUI(*) {' in gui
assert 'User32\\RedrawWindow' in gui
assert 'tabParent' in gui
assert 'if ctrl.Type = "DDL" || ctrl.Type = "Button" {' in gui
for name in ['Italiano', 'English', 'Français', 'Español']:
    assert name in gui
print("PASS: language menu and repaint source checks")
