# CasterLiveAutomation - Windows build (requires AutoHotkey v2 and official Ahk2Exe).
# This script does not publish to GitHub and does not certify the live GUI.
[CmdletBinding()]
param(
    [string]$CompilerPath = "",
    [string]$AutoHotkeyBase = ""
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'Invoke-WindowsNativeProcess.ps1')
$version = (Get-Content (Join-Path $repo 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+$') { throw "Unsupported public version '$version'" }
# Fail the release build if mandatory source/privacy/version checks fail.
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { throw 'Python 3 is required for the source release checks.' }
foreach ($test in @('check_sources.py', 'test_naming_migration.py', 'test_release_contract.py', 'test_repository_safety.py', 'test_language_ui_regression.py', 'test_window_recovery_static.py', 'test_documentation_links.py', 'test_branding_assets.py')) {
    & $python.Source (Join-Path $repo "tests\$test")
    if ($LASTEXITCODE -ne 0) { throw "Release source check failed: $test" }
}
if (-not $CompilerPath) {
    $choices = @(
        "${env:ProgramFiles}\AutoHotkey\Compiler\Ahk2Exe.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\Compiler\Ahk2Exe.exe"
    )
    $CompilerPath = $choices | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $CompilerPath -or -not (Test-Path $CompilerPath)) {
    throw 'Ahk2Exe.exe not found. Install the official AutoHotkey v2 compiler or pass -CompilerPath.'
}
if (-not $AutoHotkeyBase) {
    $AutoHotkeyBase = "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe"
}
if (-not (Test-Path $AutoHotkeyBase)) {
    throw "64-bit AutoHotkey v2 base not found at $AutoHotkeyBase. Specify -AutoHotkeyBase."
}
$dist = Join-Path $repo 'dist'
$package = Join-Path $dist "CasterLiveAutomation-$version-Windows-x64"
# Do not allow files from an earlier build to leak into this versioned package.
if (Test-Path $package) { Remove-Item -Force -Recurse $package }
New-Item -ItemType Directory -Force -Path $package | Out-Null
$guiSrc = Join-Path $repo 'CasterLiveAutomation.ahk'
$workerSrc = Join-Path $repo 'CasterLiveAutomation_Worker.ahk'
$guiExe = Join-Path $package "CasterLiveAutomation-$version.exe"
$workerExe = Join-Path $package 'CasterLiveAutomation-Worker.exe'
$brandIcon = Join-Path $repo 'assets\branding\CasterLiveAutomation.ico'
if (-not (Test-Path $brandIcon)) { throw "Branding icon missing: $brandIcon" }
foreach ($pair in @(@($guiSrc, $guiExe), @($workerSrc, $workerExe))) {
    # Ahk2Exe is also a GUI-subsystem executable. Use its actual process exit
    # status rather than $LASTEXITCODE, and check that it produced the EXE.
    $compilerCode = Invoke-CasterNativeProcess -FilePath $CompilerPath -Arguments @(
        '/in', $pair[0], '/out', $pair[1], '/base', $AutoHotkeyBase,
        '/icon', $brandIcon, '/silent'
    ) -WorkingDirectory $repo -TimeoutSeconds 300
    if ($compilerCode -ne 0 -or -not (Test-Path -LiteralPath $pair[1])) {
        throw "Compilation failed for $($pair[0]) (exit code: $compilerCode)"
    }
}
$packageAssets = Join-Path $package 'assets\branding'
New-Item -ItemType Directory -Force -Path $packageAssets | Out-Null
Copy-Item $brandIcon (Join-Path $packageAssets 'CasterLiveAutomation.ico') -Force
Copy-Item (Join-Path $repo 'LICENSE') (Join-Path $package 'LICENSE') -Force
Copy-Item (Join-Path $repo 'third_party\GPL-2.0.txt') (Join-Path $package 'AUTOHOTKEY_GPL-2.0.txt') -Force
Copy-Item (Join-Path $repo 'third_party\README.md') (Join-Path $package 'THIRD_PARTY_NOTICES.md') -Force
Copy-Item (Join-Path $repo 'docs\INSTALLATION.md') (Join-Path $package 'INSTALLATION.md') -Force
Copy-Item (Join-Path $repo 'docs\KNOWN_LIMITATIONS.md') (Join-Path $package 'KNOWN_LIMITATIONS.md') -Force
$checksums = foreach ($file in Get-ChildItem -File -Recurse $package) {
    $sha = Get-FileHash $file.FullName -Algorithm SHA256
    "$($sha.Hash)  $($file.FullName.Substring($package.Length + 1))"
}
$checksums | Set-Content (Join-Path $package 'SHA256SUMS.txt') -Encoding utf8
$zip = Join-Path $dist "CasterLiveAutomation-$version-Windows-x64.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path (Join-Path $package '*') -DestinationPath $zip -Force
$zipChecksum = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$zipChecksum  $([IO.Path]::GetFileName($zip))" | Set-Content -Path "$zip.sha256" -Encoding ascii
Write-Host "Prepared Windows binary ZIP: $zip"
Write-Host "Prepared ZIP checksum: $zip.sha256"
Write-Host 'NOTE: Compiling a stable release does not verify GUI/Caster operation; supervised runtime checks are recommended.'
