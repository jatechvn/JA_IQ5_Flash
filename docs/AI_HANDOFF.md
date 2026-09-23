# Flash stability handoff — 2026-09-23

## Scope and implementation

Implemented the six requested stability improvements without changing the window layout.

1. Flash sessions remain visible after COM removal. Disconnection before reset aborts the engine and reports failure; a reset-stage disconnect waits for the real process result. Disconnected cards disable Flash/Reboot. Active/queued sessions cannot be removed. Reappearance of a reused COM port waits for the old operation and never automatically retries its flash.
2. Removed the global reboot-success counter. RebootTracker only confirms an explicitly known serial after absence/reappearance. The current registry EDL scanner has no trustworthy ADB serial mapping: it therefore records an unknown identity, reports waiting for verification and suppresses automatic EDL for subsequently observed ADB devices. Re-enabling Auto starts a new tracking cycle; do this only after manually checking devices. A successful flash/reset command is not proof of successful Android boot.
3. Firmware preflight parses rawprogram and patch XML, checks expected roots, requires at least one named program image, rejects missing/empty files, absolute/traversal/out-of-directory paths, and permits intentionally empty program filenames and DISK patch targets. XML 7.0.1 was already in the lockfile and is now a direct dependency. Deep checks run in an isolate and repeat when each queued engine starts. This does not authenticate firmware, validate device model compatibility, or lock images against external modification during flash. No trusted hash manifest was supplied.
4. ManagedProcess drains both output streams, uses byte activity rather than percentage movement, terminates on cancel/timeout, and waits for process exit. Firehose writing: 10-minute idle / 2-hour total; reset: 2-minute idle / 5-minute total; ADB/Fastboot commands: 30-second idle / 60-second total; Sahara upload: 5-minute ceiling. No automatic partition-write retry.
5. A shared FIFO queue serializes flash and EDL reboot operations (one active device). Cancelled queued engines never touch hardware. Qualcomm service state is queried inside the queue, stopped only when originally running, held through Firehose and restored in finally. Polling is now passive and no longer consumes Sahara HELLO or changes service state.
6. Registry discovery, reboot Sahara upload/reset and deep firmware checks run outside the UI isolate. Session/global log UI updates batch at 100 ms; session display retains 1,000 lines and global display is bounded. Per-flash full logs and separate writing/reset traces have unique run IDs. Reconnect cannot replace a still-active worker.

## Verification

- Dart format applied to changed files.
- `dart analyze lib test`: No issues found.
- `git diff --check`: passed (only a Git LF/CRLF notice on pubspec.lock).
- Full Flutter suite: 80 tests passed.
- After the final card/removal guard, focused lifecycle suite: 13 tests passed, including one new disconnected-card widget test (81 unique tests in the project).
- Windows Release build passed after the final removal guard: `build/windows/x64/runner/Release/ja_iq5_flash.exe`.
- Tests use temporary firmware fixtures, fake device engines/service responses and harmless PowerShell child processes. No actual IQ5 flash, service stop/start, ADB reboot or production firmware write was executed.

## Remaining hardware validation

Test a valid IQ5 firmware on a dedicated device, disconnect/reconnect during upload/write, normal reset, unavailable/busy Qualcomm service and multiple queued devices. Confirm the passive discovery change and timeout limits against real loader output and USB hubs. Test packaged runtime with its loader/DLL files; compilation alone does not validate tool deployment or actual flashing. Native app interaction and real multi-device USB behavior remain unverified.

No version bump, commit, tag, push, ZIP or GitHub release was requested/performed.

## Build script follow-up

- build.bat now captures Flutter's exit code, stops on failure, avoids forced process termination/cache deletion, and opens the actual Release folder on interactive success. `--no-pause` supports unattended verification.
- scripts/package_windows.ps1 checks AOT/Release/staged/ZIP app.so SHA256; creates clean payloads excluding runtime configuration/logs; preserves old dist only after successful staging; verifies the Release shortcut target. Uses .NET hash/ZIP APIs because Get-FileHash was unavailable in the Windows PowerShell environment invoked by the batch file.
- Current AOT, Release and dist app.so hashes were identical (0C202755DA3D550401CAC9E36BF8980C5171EFA3F4586C35E20787CDFAD7D612); 14:40:22 timestamp alone was not evidence of stale copying.
- Real Flutter build and ZIP validation passed. Promotion of staged output into dist was blocked by a Windows directory lock; existing dist was not replaced. Verified ZIP remains under dist_pack/20260923_153348_4214/JA_IQ5_Flash_v1.3.0_Windows_x64/. Close the process holding dist before rerunning build.bat.
- Isolated fixture packaging passed: ZIP/hash checks, runtime config exclusion, old-dist preservation, hash mismatch rejection and unchanged dist after failure. The real .Release.lnk target was read back and points to build/windows/x64/runner/Release.
