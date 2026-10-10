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

## 2026-10-03: isolate closure regression

- Reproduced reported QfilEngine preflight failure with a real IOSink captured by onLog/onDone. Before fix, regression returned Illegal argument in isolate message / unsendable _AsyncCompleter.
- Moved preflight Isolate.run into a top-level helper taking only a directory string; engine callback/session context no longer crosses the isolate boundary. Applied the same scope isolation to reboot Sahara reset. Added missing adb_rebooting_log translations.
- Formatting and analyzer passed; focused flash stability/lifecycle/fastboot suites passed 35/35. Test uses missing firmware in a temporary directory and stops before service/hardware operations.
- Existing dirty build.bat, main_window.dart, settings_dialog.dart, pubspec.yaml, icon and assets changes preserved. Real IQ5 flash remains untested; dist is not replaced by this fix.
- Windows Release rebuild succeeded after the fix (38.5s): build/windows/x64/runner/Release/ja_iq5_flash.exe. Run this Release bundle, not the unchanged dist copy.

## 2026-10-10: concurrent flashing

- Supersedes the earlier one-device FIFO decision: Flash/Reboot now use a shared queue keyed by normalized COM port. Different ports run concurrently; same-port operations remain serialized. No UI redesign or external dependencies added.
- QualcommServiceCoordinator serializes only service transitions and reference-counts active users. First user queries/stops the service; last user restores it only if originally running. Failure/abort in one operation releases its own lease without restarting service while another user remains active. Failed restoration is retried before the next service acquisition.
- Changed operation_support.dart, qfil_engine.dart, reboot_worker.dart and flash_stability_test.dart. Preserved all pre-existing power/UI/native-window edits.
- Focused stability/lifecycle/fastboot tests passed 37/37; added concurrent different-port/same-port exclusion test and overlapping service-lease test with one operation failing. Updated queued-cancel test to block only its own TEST port. Analyzer clean; git diff --check passed (existing CRLF notices only).
- These tests mock service commands and device operations. Real concurrent IQ5 USB/Sahara/Firehose sessions and USB-hub capacity remain unverified. No dist replacement or GitHub release performed.
- Windows Release build succeeded after the concurrency patch (33.1s): build/windows/x64/runner/Release/ja_iq5_flash.exe. Existing dist remains unchanged.

## 2026-10-10: bounded concurrency and observed throughput

- Added concurrent device setting (1–8, default 2) at the top of Settings' first tab, with EN/VI/CN strings. Save applies the limit before the config callback; Cancel leaves it unchanged. Persisted as [FLASH] max_concurrent_devices in config.ini. Flash and EDL reboot share the limit. Decreasing it lets active operations finish; increasing it admits queued operations. Same-port operations remain FIFO and do not occupy a second slot while waiting.
- Read-only review of actual successful runs: Release logs flash_COM58_1791619872885551.log and flash_COM63_1791619874886362.log show 165.828s at 18.94 MBps and 165.938s at 18.93 MBps for loader writing. Full sessions 176.497s / 176.552s; batch 178.552s. No ERROR lines, both Result: success.
- Previous dist logs flash_COM63_1791619608643013.log and flash_COM58_1791619608643013.log show sequential writing at 36.06 MBps (87.110s) and 35.13 MBps (89.407s). Batch wall time 197.782s includes queue wait. Concurrent batch improvement about 9.7%; aggregate writing rate about 37.87 MBps. Shared USB bandwidth is a hypothesis, not a verified controller/hub diagnosis. Optimal count above 2 is unmeasured.
- Keep default 2. Test two ports on separate USB host controllers before increasing to 3–4; compare batch duration, loader rate and error/retry behavior with the same ROM. Both new sessions spend about 8s waiting for Sahara Strategy B then succeed with Strategy C; no protocol timeout/payload changes made without hardware regression evidence.
- Dart format and analyzer passed. 68 focused stability/lifecycle/widget tests passed, plus 4 Fastboot pipeline tests. New tests exercise raising/lowering limits, failure releasing capacity, normalized same-port exclusion, and Settings Save/Cancel callback behavior. Initial test invocation included a nonexistent fastboot_test.dart; rerun used actual fastboot_pipeline_test.dart successfully.
- Existing user changes and runtime logs preserved. No dist replacement, commit, push or release. Native interaction/restart persistence and real devices using the new configurable limiter still require validation.
- Windows Release build passed (24.9s) with the configurable limiter; git diff --check passed. Run build/windows/x64/runner/Release/ja_iq5_flash.exe; dist remains unchanged.

## 2026-10-10: concurrency quick selection buttons

- Replaced the concurrency dropdown with eight ChoiceChip buttons in a wrapping layout. Selected count has a checkmark/accent color; count 2 retains its translated recommendation. Save/Cancel and config persistence unchanged.
- Updated widget test to select the button and verify selection plus all eight choices. Existing hardware-tier/idle tests now scroll target controls into view instead of assuming their position after the layout change.
- Formatter, focused analyzer and git diff --check passed; all 33 widget tests passed. Windows Release rebuilt successfully (22.3s). Native visual interaction not exercised; dist and runtime data preserved.
