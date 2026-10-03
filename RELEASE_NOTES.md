TAG=v1.3.2
TITLE=JA IQ5 Reflash v1.3.2 - Window Title & PE Metadata Normalization & Official App Icon
BODY=
# ⚡ JA IQ5 Reflash v1.3.2

### 🚀 Major Enhancements & Bug Fixes
- **🏷️ Window Title & Windows PE Metadata Normalization:**
  - Synchronized window title to consistently display full application name **"JA IQ5 Reflash"** across all Windows 10 & 11 versions instead of binary executable name (`ja_iq5_flash.exe`).
  - Updated PE resource metadata (`Runner.rc`): `FileDescription`, `ProductName`, `InternalName`, and `CompanyName` set to "JA IQ5 Reflash" and "JATech VN", ensuring Task Manager, Explorer Properties, and Alt+Tab display professional application branding.
  - Added native `SetWindowText` synchronization with fallback handle resolution in `lib/main.dart`.
- **🎨 Official High-Tech Application Logo & App Icon:**
  - Integrated official brand icon (cybernetic energy ring with neon lightning bolt and sharp IQ5 emblem).
  - Applied to Windows executable binary (`windows/runner/resources/app_icon.ico`) and installer shortcut definitions (`install.bat`).
  - Added brand logo rendering to Top Header Bar and Settings About Tab.
- **⚡ Firmware Preflight & QFIL Engine Stability:**
  - Refined firmware structure preflight validation and device reboot retry mechanics (`firmware_preflight.dart`, `qfil_engine.dart`, `reboot_worker.dart`).
- **🧪 100% Verification Suite Pass:**
  - All 81 automated tests passing with zero errors.

### 📦 Artifacts Included
- `JA_IQ5_Flash_v1.3.2_Windows_x64.zip`: Standalone portable bundle with embedded Qualcomm EDL binaries (`fh_loader.exe`), 1-click Windows installer/uninstaller, multilingual assets, documentation, and debug tools.
