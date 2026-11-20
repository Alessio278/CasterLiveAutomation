# Release process - CasterLiveAutomation

CasterLiveAutomation uses two-part public versions (`1.0`, `1.1`, `2.0`). The `VERSION` file is the source of the release tag `vX.Y`. The GUI, Worker protocol and Windows ZIP must agree with `VERSION`.

## Automatic GitHub prereleases

The workflow `.github/workflows/auto-release.yml` runs on pushes to `main` or `master` (only the repository's **default branch** is allowed to publish), on matching version tags and by manual dispatch. On the first push of an unpublished version, the workflow:

1. Reads `VERSION`, checks that it matches `X.Y` and checks existing tags/releases. If already released, it skips rather than republishing an old version.
2. Runs Python source/privacy checks, then AutoHotkey v2 calendar tests on a GitHub-hosted Windows runner.
3. Compiles **two** Windows executables with Ahk2Exe using `scripts/Build-Windows.ps1` and packages license notices and SHA256 sums.
4. Creates tag `vX.Y` at the triggering commit (or uses an existing pushed tag), and publishes a GitHub **prerelease** with the Windows ZIP and ZIP checksum. GitHub generates the release notes.

This workflow cannot test CasterLive DJ in a real logged-in, unlocked Windows desktop. The output is therefore intentionally marked **prerelease**. The automation only publishes if its steps succeed, but CI success does *not* mean the software is production-ready.

After a supervised successful manual acceptance of the exact commit and review of third-party runtime licensing, the maintainer may promote that GitHub release to stable. Do not force-move a published tag or silently replace an old version. Increase `VERSION` and the corresponding GUI/Worker version strings when producing a new version.

GitHub Actions needs permission to create releases and tags (`contents: write`, defined on the release job). The repository can additionally restrict Actions permissions via settings or rulesets; configure them to permit the workflow's intended publication. No personal access token is required for a standard repository using `GITHUB_TOKEN`.

## Acceptance before stable publication

- Real Windows GUI, Worker startup and shutdown, calendar behavior, first-run pause and migration.
- Supervised START/CLOSE with CasterLive DJ, including minimizing, moving and invalid-window recovery; no live broadcast during tests.
- GUI translations and DPI, license and corresponding-source obligations for the AutoHotkey runtime, clean ZIP and archive-history privacy audit.
- Verify release ZIP checksum, tag, commit, source `VERSION` and compiled GUI/Worker behavior.

## Files in the public repository

Public source, build scripts, tests, documentation and third-party notices belong in Git. Private project notes (`AI_PROJECT_INSTRUCTIONS.md`, `PROJECT_STATE.md`, `PROJECT_KNOWLEDGE.md`), private local INI/log files, saved coordinates and Windows paths must **never** be committed. `.gitignore` cannot remove material from old commits, tags, forks or releases.

See [test checklist](TEST.md), [Windows build](WINDOWS_BUILD.md) and [privacy guidance](PRIVACY.md).
