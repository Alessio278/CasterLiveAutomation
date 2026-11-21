# Execute AutoHotkey / Ahk2Exe as an actual child process, not as a PowerShell
# GUI-app pipeline. Wait for termination and read the process's own exit code.
# This file only declares a function; dot-source it from build/test scripts.
function Invoke-CasterNativeProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 120
    )

    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.CreateNoWindow = $true
    foreach ($argument in $Arguments) {
        # ArgumentList preserves quoting even when the repository path has spaces.
        [void]$start.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) {
            throw "Could not start $FilePath"
        }

        # Read both pipes concurrently to avoid blocking when a child writes a
        # lot to stderr while stdout is being consumed (or vice versa).
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill($true) } catch { }
            $process.WaitForExit()
            throw "Process timed out after $TimeoutSeconds seconds: $FilePath"
        }
        $process.WaitForExit()
        $stdout = $outTask.GetAwaiter().GetResult()
        $stderr = $errTask.GetAwaiter().GetResult()
        if ($stdout) { Write-Host $stdout.TrimEnd() }
        if ($stderr) { Write-Host $stderr.TrimEnd() }

        return [int]$process.ExitCode
    } finally {
        $process.Dispose()
    }
}
