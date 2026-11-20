# Privacy and public repository audit

**Do not commit:** `CasterLiveAutomation_Settings.ini`, `CasterLiveAutomation_Schedules.ini`, `CasterLiveAutomation_Runtime.ini`, `CasterLiveAutomation_Log.txt`, old named INIs, old log files, Windows shortcuts, captured coordinates, local paths, broadcast access details or personal exports.

The `.gitignore` reduces accidents, but **is not a security boundary**. Scan all staged files (`git diff --cached`) before push, including archive contents and screenshots. Do not publish diagnostics without sanitizing them.

Public credit is exactly **Created by @Alessio278**, per the shared StagePad project decision. No personal full-name credit belongs in V1.0 repository documents, images or binaries. Third-party licenses/copyrights remain intact.

**Separate audit surfaces:** current source tree, generated ZIPs, release attachments, existing branches/commits/tags, forks and previous downloads. Cleaning current source does not erase historical commits or old release attachments. Never rewrite Git history without a backup and explicit plan.
