# Official Ahk2Exe release, pinned and verified for repeatable GitHub Windows builds.
# The interpreter is installed separately by Chocolatey.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$releaseUrl = 'https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip'
$expectedSha256 = 'c29b8c3a5124850d79fc9e66e2ca79677c377d7f31631ad3022ba159c5d9e3be'
$expectedCompilerSha256 = 'e54a599b19baa5c1688849bbae7a9cf049eefccd4f704c67941b40da13a625b2'
$target = Join-Path $env:ProgramFiles 'AutoHotkey\Compiler'
$compiler = Join-Path $target 'Ahk2Exe.exe'
if ((Test-Path $compiler) -and (Get-FileHash $compiler -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expectedCompilerSha256) {
    Write-Host 'Pinned official Ahk2Exe is already present.'
    return
}
$tempDir = Join-Path $env:TEMP ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
try {
    $archive = Join-Path $tempDir 'Ahk2Exe.zip'
    Invoke-WebRequest -Uri $releaseUrl -OutFile $archive
    $actualSha256 = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "Ahk2Exe archive SHA256 mismatch: $actualSha256"
    }
    $unpacked = Join-Path $tempDir 'extracted'
    Expand-Archive -Path $archive -DestinationPath $unpacked -Force
    $source = Get-ChildItem -Path $unpacked -Recurse -File -Filter 'Ahk2Exe.exe' | Select-Object -First 1
    if (-not $source) { throw 'Ahk2Exe.exe not found in official compiler archive' }
    if ((Get-FileHash $source.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedCompilerSha256) {
        throw 'Ahk2Exe.exe checksum does not match the published official release'
    }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Path (Join-Path $source.Directory.FullName '*') -Destination $target -Recurse -Force
    if (-not (Test-Path $compiler)) { throw 'Ahk2Exe installation failed' }
    Write-Host "Official Ahk2Exe installed at $compiler"
} finally {
    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Force -Recurse }
}
