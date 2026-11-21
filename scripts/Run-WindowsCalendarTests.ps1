# Logic-only tests for AutoHotkey v2 on Windows (not CasterLive DJ acceptance).
# A GUI-subsystem executable may print PASS while $LASTEXITCODE stays $null.
# Read its real exit code from System.Diagnostics.Process instead.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'Invoke-WindowsNativeProcess.ps1')
$ahk = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'
if (-not (Test-Path -LiteralPath $ahk)) { throw "AutoHotkey v2 x64 not installed: $ahk" }

foreach ($relative in @('tests/schedule_cases.ahk', 'tests/first_run_schedule_cases.ahk')) {
    $script = Join-Path $repo $relative
    Write-Host "Running $relative"
    $code = Invoke-CasterNativeProcess -FilePath $ahk -Arguments @('/ErrorStdOut', $script) -WorkingDirectory $repo -TimeoutSeconds 90
    if ($code -ne 0) {
        throw "AutoHotkey test failed: $relative (process exit code: $code)"
    }
}
Write-Host 'PASS Windows AutoHotkey calendar tests. GUI/Caster integration NOT tested.'
