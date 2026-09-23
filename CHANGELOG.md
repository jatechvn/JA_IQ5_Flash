# 📜 CHANGELOG - JA IQ5 Reflash

All notable changes to **JA IQ5 Reflash** will be documented in this file.

---

## [v1.3.0] - 2026-09-23

### 🚀 Major Features & Enhancements
- **🔄 Complete LAN Over-The-Air (OTA) Update System (LAN Messenger Standard):**
  - **Core Service (`OtaUpdateService`)**: Full Semantic Versioning (`SemanticVersion`) comparison, Windows UNC/SMB (`net use`) authenticated connection, Zip-Slip archive security validation, and detached robocopy script generation with automated rollback.
  - **Independent Portable Config (`update_config.json`)**: Stored next to executable (or `%APPDATA%\JA_IQ5_Flash`) for zero-touch portable deployment.
  - **Bento Frosted Glass Update Modal (`GlassUpdateDialog`)**: Interactive dialog featuring current vs latest version cards, package size, release notes viewer, dynamic progress % bar, and step-by-step status tracking.
  - **5th Settings Tab ("LAN OTA")**: Dedicated configuration tab in `SettingsDialog` allowing users to configure check interval (*Daily*, *Weekly*, *Monthly*, *Off*), SMB server path, credentials with password visibility toggle, 1-click server connection testing, and direct config directory access.
  - **Top Bar Update Pill Badge**: Dynamic emerald expanding pill button in the top menu bar showing `v{newVersion}` and expanding to `Update Now` on hover; triggers background check on startup.
- **📦 Standard Zero-Dependency Windows Installer & Uninstaller (`install.bat`, `uninstall.bat`, `uninstall.ps1`):**
  - **User-space Zero-UAC Installation**: Installs to `%LOCALAPPDATA%\Programs\JA_IQ5_Flash` without requiring Administrator privileges.
  - **Data & Config Preservation**: Preserves `config.json`, `config.ini`, `update_config.json`, `license.key`, and logs during upgrades via Robocopy `/XF` / `/XD` filters.
  - **Full Windows Integration**: Automatically creates Desktop shortcut, Start Menu folder with app and uninstaller shortcuts (`shell32.dll,-240`), and registers into Windows Control Panel / Settings.
  - **Self-Deleting Staging Driver**: `uninstall.bat` stages execution to `%TEMP%` to avoid Windows batch file locking.
- **🌐 Trilingual Localization Expansion:**
  - Full translation coverage for all OTA features across English, Tiếng Việt, and 中文.
  - Upgraded `tr(key, [args])` to support safe parameter replacement (`{0}`, `{1}`) with 100% backward compatibility.

### 🐛 Bug Fixes & Polishing
- **Fixed Duplicated Action Icons**: Cleaned up toolbar button definitions eliminating duplicate icon artifacts on EDL and ADB action buttons.
- **Test Suite Expansion**: Added comprehensive `ota_update_service_test.dart` suite, achieving 100% green coverage (60/60 tests passing).

---

## [v1.2.1] - 2026-09-12

### 🚀 Major Features & Enhancements
- **🎛️ Real-Time Responsive Bento Glassmorphism Tuning (MES Tool Standard):**
  - Integrated root-level `ChangeNotifierProvider` (`provider: ^6.1.2`) wrapping the entire application tree and modal dialog routes.
  - Refactored `BentoCard` and `SubCard` to dynamically watch `AppTheme` via `context.watch<AppTheme>()` with reactive fallbacks.
  - Live real-time preview of **Bento Card Blur** (0 - 40 px) and **Bento Card Opacity** (5% - 100%) while dragging sliders in the Settings dialog without requiring save or app restart.
  - GPU optimization: automatically omits `BackdropFilter` when blur is 0 px (Lite mode), saving GPU cycles.
- **🔄 Dynamic Surface Opacity Scaling:**
  - Scaled slot card backgrounds, EDL and ADB column container surfaces, and sub-card headers proportionally according to the user's card opacity slider.
- **↩️ Graceful Cancellation Rollback & Save Persistence:**
  - Implemented initial glassmorphism state tracking and `_rollbackAndClose()` logic with `PopScope(canPop: false)` on `SettingsDialog` (matching `JA_MES_Tool`).
  - Closing the modal, clicking `X`, or pressing Escape safely rolls back uncommitted slider changes; clicking Save Settings persists values to `config.ini`.
- **📖 Expanded In-App User Guide:**
  - Added dedicated Guide section for Bento Glassmorphism, hardware tier auto-profiling, and preview rollback across all 3 languages (English, Tiếng Việt, 中文).
- **🧪 Comprehensive Automated Testing Suite:**
  - Added `Live Glassmorphism Reactivity & Rollback Tests` group, bringing total coverage to 43 passing unit & widget tests (100% green).

---

## [v1.2.0] - 2026-09-12

### 🚀 Major Features & Enhancements
- **📊 Dedicated Two-Column Dual Pipeline Layout:**
  - Separated the device interface into two dedicated monitoring columns: Left column exclusively dedicated to active Qualcomm EDL (9008) flashing; Right column dedicated to ADB & Fastboot device monitoring and 1-click EDL reboot routing.
  - Ensures technicians can monitor up to 8 EDL ports without horizontal layout clipping or obstructed logs.
- **💾 3-Slot Smart Firmware Selector:**
  - Quick 1-click switching between Factory Stock (FACTORY ROM), User Custom (USER ROM), and Diagnostics/Test (DIAG / TEST) profiles.
  - Double-click modal for live profile renaming and slot type reassignment.
  - Multi-partition Qualcomm XML & Firehose integrity validation (awprogram_unsparse0.xml, patch0.xml, prog_firehose_ddr.elf).
- **💫 Rotating Glow Border Animation (Cyber Comet):**
  - High-performance animated neon comet light beam rotating around the perimeter of the active selected slot card.
  - Automatically paused when app is minimized via AppLifecycleListener to conserve GPU cycles.
- **🔄 Asymmetric Bounce Marquee Path Input (GlassBouncePathField):**
  - Integrated BounceMarqueeText with asymmetric ping-pong scrolling: pauses 1.4s at root drive, scrolls smoothly forward at 40 px/s, pauses 1.4s at destination folder, and returns.
  - Seamlessly switches from marquee view to an editable TextField on tap/focus for manual editing or Ctrl+V clipboard pasting.
- **🎛️ Hardware Tier Profiling & Optimization (Showcase Standard):**
  - Automated system benchmarking (CPU cores + OS version) classifying hardware into Ultra (120 FPS), Balanced (60 FPS), and Lite (Zero-Lag).
  - 1-click cycling button on TopBar and comprehensive selection tab in Settings modal.
  - GPU texture rasterization caching (RepaintBoundary) on blurred mesh orbs, reducing frame render cost to ~0.1ms.
- **🎨 Theme-Aware Contrast & Light Mode Overhaul:**
  - Engineered pristine frosted-white milky glass card backgrounds (94% white + 8% slot tint) in Light Mode, eliminating dark mesh orb bleed-through.
  - WCAG AAA compliant text and badge tokens across all 3 slot types in both Light and Dark themes.

### 🐛 Bug Fixes & Polishing
- Fixed overlapping language flag text inside the language selector dropdown.
- Fixed duplicated paste buttons on the firmware path bar.
- Replaced basic console output with an isolated, high-contrast Bento Terminal Log Monitor.
- Fixed dark theme slate background and mesh orb parameters to match Showcase design standard.
- Enforced single-instance application guard with Win32 window bring-to-front.

---

## [v1.1.0] - 2026-06-28

### 🚀 Major Features & Enhancements
- **⚡ Multi-Device Parallel Flashing:**
  - Concurrent flashing engine supporting up to 8 simultaneous Qualcomm Snapdragon QDLoader 9008 devices.
  - Integrated h_loader.exe runner and Sahara Protocol state machine with real-time stdout parsing.
- **🔄 Fastboot -> ADB -> EDL Auto-Pipeline:**
  - Automated worker detecting Fastboot devices, executing reboot, waiting for ADB authorization, and sending reboot-edl.

### 🛡️ Security & Licensing
- Implemented HMAC-SHA256 hardware machine ID (HWID) license verification with LAN server synchronization.

---

## [v1.0.0] - 2026-06-26

### 🚀 Initial Release
- Initial release of JA IQ5 Reflash tool with Qualcomm EDL flashing capabilities, Windows 10/11 desktop support, and trilingual interface (EN, VI, CN).
