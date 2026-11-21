"""Public version, packaging and attribution contracts. No private project notes."""
from pathlib import Path
import re

r = Path(__file__).resolve().parents[1]
version = (r / 'VERSION').read_text(encoding='utf-8-sig').strip()
assert re.fullmatch(r'\d+\.\d+', version), f'Invalid VERSION: {version!r}'
assert (r / 'CasterLiveAutomation.ahk').exists()
assert not (r / 'CasterLiveAutomation_V5.ahk').exists()

for f in ['README.md', 'docs/README.it.md', 'docs/README.es.md',
          'docs/README.fr.md', 'LICENSE', 'CHANGELOG.md']:
    x = (r / f).read_text(encoding='utf-8-sig')
    assert '@Alessio278' in x, f'Missing approved attribution in {f}'
    assert not re.search(r'Alessio\s+Natalucci', x, re.I), f'Full-name credit in {f}'

for f in ['CasterLiveAutomation.ahk', 'CasterLiveAutomation_Worker.ahk',
          'CasterLiveAutomation_ScheduleLib.ahk']:
    assert not re.search(r'Alessio\s+Natalucci', (r / f).read_text(encoding='utf-8-sig'), re.I)

main = (r / 'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
worker = (r / 'CasterLiveAutomation_Worker.ahk').read_text(encoding='utf-8-sig')
assert f'"CasterLiveAutomation  |  {version}"' in main, 'GUI version differs from VERSION'
assert f'"WorkerVersion", "") != "{version}"' in main, 'GUI WorkerVersion differs from VERSION'
assert f'WState("WorkerVersion", "{version}")' in worker, 'Worker protocol differs from VERSION'
assert 'CasterLiveAutomation-$version.exe' in (r / 'scripts/Build-Windows.ps1').read_text(encoding='utf-8-sig')
assert (r / 'third_party/GPL-2.0.txt').exists()
release_workflow = (r / '.github/workflows/auto-release.yml').read_text(encoding='utf-8-sig')
calendar_runner = (r / 'scripts/Run-WindowsCalendarTests.ps1').read_text(encoding='utf-8-sig')
windows_workflow = (r / '.github/workflows/windows-ahk-tests.yml').read_text(encoding='utf-8-sig')
assert 'stable release' in release_workflow.lower(), 'Release should be stable'
assert "'--prerelease'" not in release_workflow, 'Release workflow still publishes prereleases'
assert 'Run-WindowsCalendarTests.ps1' in release_workflow
assert 'Run-WindowsCalendarTests.ps1' in windows_workflow
native_runner = (r / 'scripts/Invoke-WindowsNativeProcess.ps1').read_text(encoding='utf-8-sig')
build_script = (r / 'scripts/Build-Windows.ps1').read_text(encoding='utf-8-sig')
probe_script = (r / 'scripts/Test-WindowsProcessRunner.ps1').read_text(encoding='utf-8-sig')
assert 'Invoke-CasterNativeProcess' in calendar_runner, 'Calendar tests must use a process-based launcher'
assert 'Invoke-CasterNativeProcess' in build_script, 'Compiler must use a process-based launcher'
assert 'System.Diagnostics.ProcessStartInfo' in native_runner, 'Missing process start configuration'
assert 'RedirectStandardOutput = $true' in native_runner and 'RedirectStandardError = $true' in native_runner
assert 'WaitForExit' in native_runner and 'process.ExitCode' in native_runner, 'Must await and inspect actual process status'
assert '$code -ne 0' in calendar_runner and '$compilerCode -ne 0' in build_script
assert '$LASTEXITCODE' not in probe_script, 'Smoke test must not depend on LASTEXITCODE'
assert 'exit 0' in probe_script and 'exit 23' in probe_script, 'Smoke test must cover success and nonzero status'
assert 'Test-WindowsProcessRunner.ps1' in release_workflow
assert 'Test-WindowsProcessRunner.ps1' in windows_workflow
for workflow in (release_workflow, windows_workflow, (r / '.github/workflows/static-checks.yml').read_text(encoding='utf-8-sig')):
    assert 'actions/checkout@v4' not in workflow and 'actions/setup-python@v5' not in workflow, 'Deprecated Node.js 20 action version'

print(f'PASS: v{version} public release contracts; no private context required')
