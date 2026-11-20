# Release process - shared StagePad methodology

CasterLiveAutomation uses **two-part public versions**: `1.0`, `1.1`, `1.2`, ..., `1.9`, `2.0`. For GitHub, use tag `v1.0`; match the **source VERSION**, on-screen title, release notes, commit and packaged filename.

## Definition of done

1. Identify the exact source commit and review the changed files.
2. Run static checks (`python tests/check_sources.py` and the other Python tests) and Windows AHK calendar tests.
3. Validate the actual Windows GUI and real CasterLive DJ START/CLOSE with a supervised operator, including minimizing the window.
4. Compile EXEs only on Windows with Ahk2Exe, and confirm both programs work **together**.
5. Audit README, translations, privacy, copyright and third-party license files.
6. Verify the commit, tag, artifacts and checksum list. Never reassign tags solely to conceal a failed build.
7. Manually publish GitHub release only after the required checks pass. If testing is incomplete, mark the distribution as a candidate/preview and explain the remaining limitations.

## Repository vs public downloads

- GitHub source repository: source code, tests, build script, documentation and continuity files.
- Windows release ZIP: two compiled EXEs, license notices, installation guide and checksums; no tests, logs or personal INI.
- Project handoff notes and test reports: maintain separately; do not embed fake Windows test results or upload private telemetry.

## Key commands

Suggested commit: `Prepare CasterLiveAutomation 1.0 release candidate`

Suggested future stable tag (after validation): `v1.0`

No automated publishing to GitHub is implied by generating repository files.
