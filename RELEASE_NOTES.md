TAG=v1.2.1
TITLE=JA IQ5 Reflash v1.2.1 - Real-time Bento Glassmorphism Tuning & Rollback
BODY=
# ⚡ JA IQ5 Reflash v1.2.1

### 🚀 Major Enhancements & Bug Fixes
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

### 📦 Artifacts Included
- `JA_IQ5_Flash_v1.2.1_Windows_x64.zip`: Standalone portable bundle with embedded Qualcomm EDL binaries (`fh_loader.exe`, `QMSL_MSVC10R.dll`), icons, documentation, and debug scripts.
