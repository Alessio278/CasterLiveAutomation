# Smoke test the exit-code handling independently of AutoHotkey. Windows CI only.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'Invoke-WindowsNativeProcess.ps1')
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source

$ok = Invoke-CasterNativeProcess -FilePath $pwsh -Arguments @('-NoProfile', '-NonInteractive', '-Command', '[Console]::WriteLine("PASS native process stdout"); exit 0') -WorkingDirectory $repo -TimeoutSeconds 30
if ($ok -ne 0) { throw "Native-process probe should return 0, got $ok" }

$failed = Invoke-CasterNativeProcess -FilePath $pwsh -Arguments @('-NoProfile', '-NonInteractive', '-Command', '[Console]::Error.WriteLine("EXPECTED probe stderr"); exit 23') -WorkingDirectory $repo -TimeoutSeconds 30
if ($failed -ne 23) { throw "Native-process probe should return 23, got $failed" }
Write-Host 'PASS native process exit-code checks (0 and 23).'
