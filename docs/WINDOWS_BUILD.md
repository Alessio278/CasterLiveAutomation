# Building the Windows distribution (V1.0)

The program consists of **two cooperating Windows processes**: a GUI and a scheduling Worker. A compiled release therefore consists of **two EXEs**, not a single StagePad-style .NET single-file executable. Changing this requires a separate redesign and Windows testing.

## Requirements

- Windows 10/11 x64.
- AutoHotkey **v2**, with the official Ahk2Exe compiler installed.
- PowerShell for the build step only. Users can run the compiled EXEs without starting PowerShell.

From the repository root on Windows:

```powershell
.\scripts\Build-Windows.ps1
```

The script checks compiler paths, compiles GUI and Worker, fails if either EXE is missing, and prepares `dist/CasterLiveAutomation-1.0-Windows-x64.zip`. The package must be unpacked into a **writable** directory with both executables together.

## Why the GUI launcher must be compiled differently

When running from source the GUI starts a second `.ahk` script via the AutoHotkey interpreter. When compiled, it starts the separate `CasterLiveAutomation-Worker.exe` and does not attempt to execute an `.ahk` file using its own compiled launcher. The changed branch is only used when `A_IsCompiled` is true.

## Mandatory acceptance before public binaries

1. Both binaries are compiled on the intended Windows host and the PowerShell script exits successfully.
2. Source calendar tests pass in AutoHotkey v2.
3. New folder: launch GUI, zero schedules/paused, create schedule, resume, test START and CLOSE.
4. Minimize, move and hide CasterLive DJ and verify safe window recovery; check CLICK and CLOSE logs.
5. Verify startup shortcut points to the right compiled GUI executable.
6. Check both binaries close properly and no old Worker remains.
7. Verify build integrity and third-party license notices; compute checksums for release files.

Version 1.0 is designated stable. A successful automatic Windows compilation is a packaging check, **not** confirmation that real START/CLOSE or streaming succeeds with CasterLive DJ. Before unattended use, complete the operational checklist on an unlocked Windows desktop.

## Application icon

The build script uses `assets/branding/CasterLiveAutomation.ico` with Ahk2Exe's `/icon` parameter for **both** executables, and also includes the ICO in the release ZIP under `assets/branding/`. The GUI uses this file for its title bar and system tray. Do not remove this asset when assembling or moving a compiled installation. If using a custom package layout, preserve this relative path or update `gBrandIcon` accordingly.

## Automated GitHub build

Push the updated source and a new `VERSION` to the default branch. `.github/workflows/auto-release.yml` installs AutoHotkey v2 and the official Ahk2Exe compiler, runs calendar tests, builds the two EXEs and creates a **stable release** with a checksum attachment. A matching tag `vX.Y` can also trigger publication. The automatic tests do not replace supervised CasterLive DJ integration checks.
