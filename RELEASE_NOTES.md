TAG=v1.3.1
TITLE=JA IQ5 Reflash v1.3.1 - Standard Build Script & Robust Packaging Engine
BODY=
# ⚡ JA IQ5 Reflash v1.3.1

### 🚀 Major Enhancements & Bug Fixes
- **🛠️ Standard 6-Step Build Script (`build.bat` aligned with JA LAN Messenger):**
  - **Automated Process Termination**: Terminates lingering `ja_iq5_flash.exe` before compiling to eliminate file lock conflicts.
  - **Release Mode Compilation**: Compiles Flutter Windows Desktop in Release mode with immediate error status reporting.
  - **Robust Asset Synchronization via Robocopy**: Synchronizes `bin/` (`fh_loader.exe`, `xerces-c_3_1.dll`, `msvcr100.dll`), `i18n/`, `assets/`, debug tools, Windows installer trio (`install.bat`, `uninstall.bat`, `uninstall.ps1`), and all project documentation without `Access denied` errors.
  - **Integrated PowerShell Packager (`windows\packaging\package_dist.ps1`)**: Verifies binary `ProductVersion` against `pubspec.yaml`, checks runtime dependencies, bundles parent-folder ZIP, checks SHA256 archive hashes, and generates `version.json` for LAN OTA updates.
  - **Automated Root Shortcut**: Generates `.Release - Shortcut.lnk` directly at project root.
  - **Foreground Active Window**: Automatically opens and brings the Release directory to the top (`Foreground Window`) upon successful compilation.
  - **Headless Execution Support**: Supports `--no-pause` parameter for CI/CD and `/gitpush` automation pipelines.
- **🔒 OneDrive Folder Locking Resolution**:
  - Implemented intelligent fallback synchronization for `dist/`: When OneDrive sync or Windows Explorer holds a folder handle on `dist/`, the packager seamlessly syncs files directly without aborting, while preserving user configurations (`config.ini`, `license.key`, `logs/`) and storing a snapshot in `backup/`.
- **🧪 Comprehensive Testing Suite**:
  - All 81 automated tests passing with 100% green coverage.

### 📦 Artifacts Included
- `JA_IQ5_Flash_v1.3.1_Windows_x64.zip`: Standalone portable bundle with embedded Qualcomm EDL binaries (`fh_loader.exe`), 1-click Windows installer/uninstaller, multilingual assets, documentation, and debug tools.
