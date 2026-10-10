TAG=v1.4.0
TITLE=JA IQ5 Reflash v1.4.0 — Power & GPU Optimizer, Idle Sleep Mode & Concurrency Lease
BODY=
# ⚡ JA IQ5 Reflash v1.4.0

### 🚀 Major Enhancements & Performance
- **⚡ Comprehensive GPU/CPU Power Management (`AppPowerManager`):**
  - Introduced `AppPowerManager` as the single source of truth managing window state (`windowActiveNotifier`), user activity (`userActiveNotifier`), and active animation control (`animationsRunningNotifier`).
  - Automatically ceases all continuous background animations (`MeshOrb`, `RotatingGlowBorder`, `AsymmetricMarqueeText`) when the application window loses focus or is minimized, dropping GPU/CPU usage to zero on industrial test benches.
  - **Direction Preservation:** `MeshOrb` records floating direction vector prior to pausing and smoothly resumes along its original trajectory when the window reactivates.
  - **Session Epoch Guard:** Tokenized lifecycle sessions (`_sessionEpoch`) eliminate animation timer and marquee callback leaks during slot or theme changes.
  - **Marquee Offset Freezing:** Retains precise text scroll positions while paused and resumes without jumping back to origin.
- **🌙 Idle Sleep Mode (Ngủ Rảnh Tay):**
  - Automatically pauses resource-heavy glassmorphism animations after a period of user inactivity (12s default, 30s, 60s, or disabled).
  - Wakes up immediately upon any user interaction via a 250ms throttled pointer/key listener.
  - Interactive settings tab with rollback on cancel and automatic persistence to `config.ini`.
  - Full trilingual localization: English, Tiếng Việt, 中文.
- **🔒 Concurrency Lease & Device Reboot Stabilization:**
  - Enforced per-port mutex leases across `operation_support.dart`, `qfil_engine.dart`, and `reboot_worker.dart` to eliminate race conditions during rapid device reconnects.
- **🪟 Win32 Native Focus Handling Fix:**
  - Resolved `WM_ACTIVATE` message processing for `WA_INACTIVE` in `windows/runner/win32_window.cpp` ensuring proper focus dispatch to the Flutter engine.
- **🧪 100% Verification Suite Pass:**
  - 97 automated tests passing with zero failures.

### 📦 Artifacts Included
- `JA_IQ5_Flash_v1.4.0_Windows_x64.zip`: Standalone portable bundle with embedded Qualcomm EDL binaries (`fh_loader.exe`), 1-click Windows installer/uninstaller, multilingual assets, documentation, and debug tools.
