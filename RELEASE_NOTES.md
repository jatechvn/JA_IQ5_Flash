TAG=v1.3.0
TITLE=JA IQ5 Reflash v1.3.0 - LAN Over-The-Air (OTA) Updates & UI Refinements
BODY=
# ⚡ JA IQ5 Reflash v1.3.0

### 🚀 Major Enhancements & Bug Fixes
- **🔄 Complete LAN Over-The-Air (OTA) Update System (LAN Messenger Standard):**
  - **Core Service (`OtaUpdateService`)**: Full Semantic Versioning (`SemanticVersion`) comparison, Windows UNC/SMB (`net use`) authenticated connection, Zip-Slip archive security validation, and detached robocopy script generation with automated rollback.
  - **Independent Portable Config (`update_config.json`)**: Stored next to executable (or `%APPDATA%\JA_IQ5_Flash`) for zero-touch portable deployment.
  - **Bento Frosted Glass Update Modal (`GlassUpdateDialog`)**: Interactive dialog featuring current vs latest version cards, package size, release notes viewer, dynamic progress % bar, and step-by-step status tracking.
  - **5th Settings Tab ("LAN OTA")**: Dedicated configuration tab in `SettingsDialog` allowing users to configure check interval (*Daily*, *Weekly*, *Monthly*, *Off*), SMB server path, credentials with password visibility toggle, 1-click server connection testing, and direct config directory access.
  - **Top Bar Update Pill Badge**: Dynamic emerald expanding pill button in the top menu bar showing `v{newVersion}` and expanding to `Update Now` on hover; triggers background check on startup.
- **📦 Standard Zero-Dependency Windows Installer & Uninstaller (`install.bat`, `uninstall.bat`, `uninstall.ps1`):**
  - Installs to `%LOCALAPPDATA%\Programs\JA_IQ5_Flash` without requiring Administrator privileges.
  - Preserves user configurations (`config.json`, `config.ini`, `update_config.json`, `license.key`) and logs during updates.
  - Creates Desktop shortcut, Start Menu folder with app and uninstaller (`shell32.dll,-240`), and registers into Windows Settings & Control Panel.
- **🌐 Trilingual Localization Expansion:**
  - Full translation coverage for all OTA features across English, Tiếng Việt, and 中文.
  - Upgraded `tr(key, [args])` to support safe parameter replacement (`{0}`, `{1}`) with 100% backward compatibility.
- **🐛 Fixed Duplicated Action Icons**: Cleaned up toolbar button definitions eliminating duplicate icon artifacts on EDL and ADB action buttons.
- **🧪 Comprehensive Automated Testing Suite**: Added `ota_update_service_test.dart` suite, achieving 100% green coverage (60/60 tests passing).

### 📦 Artifacts Included
- `JA_IQ5_Flash_v1.3.0_Windows_x64.zip`: Standalone portable bundle with embedded Qualcomm EDL binaries (`fh_loader.exe`, `QMSL_MSVC10R.dll`), 1-click Windows installer/uninstaller, icons, documentation, and debug scripts.

