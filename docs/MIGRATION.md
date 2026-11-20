# Migration to CasterLiveAutomation 1.0

The public version moves from the previous `0.5` pre-release to `1.0` and follows a two-component versioning scheme.

## File names

- Previous source entry point: `CasterLiveAutomation_V5.ahk`.
- Current source entry point: **`CasterLiveAutomation.ahk`**.
- Shared Worker source: `CasterLiveAutomation_Worker.ahk`.
- Shared calendar library: `CasterLiveAutomation_ScheduleLib.ahk`.

The settings, schedule, runtime and log names remain `CasterLiveAutomation_*.ini` / `CasterLiveAutomation_Log.txt`, and continue to be excluded from Git. **Do not delete them** when updating.

## Safe sequence

1. Stop broadcasting and verify SEND manually. Exit all old GUI and Worker processes.
2. Back up the entire installation folder, especially `*.ini` and logs.
3. Extract the new source files together in a separate folder or update the existing folder without destroying user files.
4. Start `CasterLiveAutomation.ahk` once to recreate the Windows startup shortcut target, then confirm the shortcut points to the new entry point. Remove any duplicate old startup shortcuts.
5. Review schedules and sequences. The Worker compatibility protocol now reports `1.0`; old Worker instances cannot be reused.
6. Test a complete supervised cycle (including minimized CLOSE) before relying on a schedule.

**Rollback:** stop all V1.0 processes, restore the backed-up folder and settings, check the startup shortcut, and verify SEND before resuming broadcasts. Do not mix V5 and V1.0 Worker processes.

This migration preserves the existing on-disk V3-era INI keys for compatibility; renaming these sections is explicitly out of scope.
