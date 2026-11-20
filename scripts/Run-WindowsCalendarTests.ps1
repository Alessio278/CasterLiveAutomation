# Run the two logic-only AutoHotkey v2 tests reliably from Windows PowerShell / pwsh.
# AutoHotkey64.exe is a GUI-subsystem executable: an unpiped call may run asynchronously
# and leave $LASTEXITCODE stale. Piping to Out-Host makes the invocation synchronous.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ahk = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'
if (-not (Test-Path -LiteralPath $ahk)) { throw "AutoHotkey v2 x64 not installed: $ahk" }

foreach ($relative in @('tests/schedule_cases.ahk', 'tests/first_run_schedule_cases.ahk')) {
    $script = Join-Path $repo $relative
    Write-Host "Running $relative"
    # A fresh exit value must come from this process, not an earlier native command.
    $LASTEXITCODE = $null
    & $ahk /ErrorStdOut $script | Out-Host
    $code = $LASTEXITCODE
    if ($null -eq $code -or $code -ne 0) {
        throw "AutoHotkey test failed: $relative (process exit code: $code)"
    }
}
Write-Host 'PASS Windows AutoHotkey calendar tests. GUI/Caster integration NOT tested.'
