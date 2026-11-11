# Known limitations — 0.5 public pre-release

- **Windows-only**: depends on an interactive Windows desktop and AutoHotkey v2.
- **Unattended reliability unverified**: the latest minimized-window CLOSE fix needs a complete manual Windows cycle before production use.
- **No live-stream state API**: the application cannot know whether CasterLive DJ is actively streaming. `SEND` may be a toggle.
- **Shared actions**: multiple schedules share one configured executable and one START/CLOSE sequence set.
- **Cannot click on locked desktops**: Windows sign-in and an unlocked interactive session are required.
- **Layout-dependent calibration**: moving windows is supported by current window geometry calculations; resizing the window, changing display scale, or changing the Caster UI may invalidate recorded coordinates.
- **Not a Windows service**: automatic startup is after user login, not before it.
- **Time changes**: daylight-saving transitions, long sleep periods and system clock adjustments require additional testing.
- **Partial localization**: some diagnostic and advanced editor text remains Italian.
- **No standalone binary**: source scripts require AutoHotkey v2; executable packaging is a future release task.

Please use GitHub Issues for reproducible problems, without attaching any unredacted personal settings or runtime logs.
