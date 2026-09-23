<div align="center">

# ⚡ JA IQ5 Reflash

**Professional Multi-Device Qualcomm Snapdragon Firmware Flashing & Recovery Tool**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-0078D6?logo=windows&logoColor=white)](https://microsoft.com)
[![Release](https://img.shields.io/badge/Release-v1.3.0-00C853?logo=github)](https://github.com/jatechvn/JA_IQ5_Flash/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<p align="center">
  <b>🇺🇸 English</b> • <a href="i18n/README.vi.md">🇻🇳 Tiếng Việt</a> • <a href="i18n/README.zh-CN.md">🇨🇳 中文</a>
</p>

*An industrial-grade Windows desktop application built with Flutter & Dart for automated multi-device Qualcomm IQ5 EDL (9008) firmware flashing, ADB/Fastboot routing, and intelligent glassmorphism.*

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Core Capabilities](#-core-capabilities)
- [Hardware Tier Architecture](#-hardware-tier-architecture)
- [Directory & Technical Architecture](#-directory--technical-architecture)
- [Quick Start Guide](#-quick-start-guide)
  - [Option A: Portable Run (Recommended)](#option-a-portable-run-recommended)
  - [Option B: Building from Source](#option-b-building-from-source)
- [Configuration & Settings](#-configuration--settings)
- [Changelog](#-changelog)
- [License & Author](#-license--author)

---

## 🌟 Overview

**JA IQ5 Reflash** is an enterprise-grade firmware flashing utility developed for Qualcomm Snapdragon platform devices (such as Qualcomm IQ5 units). It empowers hardware test engineers, manufacturing lines, and repair technicians to flash up to **8 devices simultaneously** via Qualcomm Emergency Download (EDL 9008) mode.

Featuring an automated 3-stage pipeline (Fastboot → ADB → EDL → Flash → Reboot), a modern Two-Column layout, rotating neon glow selection borders, and GPU-cached fluent glassmorphism, JA IQ5 Reflash delivers zero-friction production flashing with complete reliability.

---

## 🚀 Core Capabilities

### ⚡ Simultaneous Multi-Device EDL Flashing
- Flashes up to **8 Qualcomm Snapdragon devices** in parallel across independent COM ports (USB\VID_05C6&PID_9008).
- Integrated h_loader.exe and Sahara Protocol engine with real-time sector transfer and progress tracking per device.
- Full partition flashing support: awprogram_unsparse0.xml, patch0.xml, and prog_firehose_ddr.elf.

### 📱 Two-Column Dual Pipeline Layout
- **Left Column (EDL 9008)**: High-priority flashing zone showing real-time flash progress, transfer speed, partition status, and per-device abort/reboot actions.
- **Right Column (ADB & Fastboot)**: Real-time device detection, model identification, authorization status, and 1-click batch rebooting into EDL mode.

### 💾 3-Slot Smart Firmware Selector & Rotating Glow Border
- Instant switching between 3 dedicated firmware slots:
  - **Slot 1**: Factory Stock ROM (FACTORY ROM • Sky Cyan)
  - **Slot 2**: Customer / User Custom ROM (USER ROM • Emerald Green)
  - **Slot 3**: Diagnostic / QA Calibration ROM (DIAG / TEST • Amber Gold)
- **Rotating Glow Border**: Selected slot is wrapped with an animated rotating comet light beam for instant visual focus.
- **Adaptive Contrast Surface**: Pristine frosted-white milky glass in Light Mode with high-contrast text and WCAG AAA compliance; glowing cyberpunk slate glass in Dark Mode.

### 🔄 Asymmetric Bounce Marquee Path Input (GlassBouncePathField)
- Seamlessly handles very long directory paths without UI truncation or layout overflow.
- **Asymmetric Ping-Pong Marquee**: Pauses 1.4s at the start to identify the drive letter, smoothly scrolls forward to reveal deep folders, pauses 1.4s at the destination, and returns.
- **Instant Focus Switch**: Seamlessly switches to an interactive TextField on mouse click for manual typing, text selection, or 1-click clipboard paste.

### 🎛️ Hardware-Aware Performance Profiling
- Automatically benchmarks system hardware (CPU logical cores & Windows OS version) and selects the optimal rendering tier:
  - **Ultra Mode (120 FPS)**: Full backdrop blur convolution, dynamic Mesh Orbs, and animated comet borders for high-end PCs.
  - **Balanced Mode (60 FPS)**: Optimized for mainstream laptops with smooth glass surfaces.
  - **Lite Mode (Zero Lag)**: Bypasses backdrop filters, disables mesh orbs, and uses pure translucent acrylic for resource-constrained or virtual machines.
- Cycle through tiers instantly via TopBar button or the Settings modal.

### 🎨 Windows 11 Fluent Glassmorphism with Live Tuning
- Real-time 4-slider controls for Card Blur, Card Opacity, Dialog Blur, and Dialog Opacity.
- GPU texture rasterization caching via RepaintBoundary and Skia/Impeller hardware acceleration.

### 🛡️ Hardware-Locked Security & LAN Licensing
- Cryptographically secured with HMAC-SHA256 hardware machine ID (HWID) binding.
- Automatic background license synchronization via local network (LAN) server.

### 🌐 Trilingual Localization
- Live dynamic language switching without app restart:
  - 🇺🇸 English
  - 🇻🇳 Tiếng Việt
  - 🇨🇳 中文

---

## 📊 Hardware Tier Architecture

| Metric / Setting | 🚀 Ultra Tier | ⚖️ Balanced Tier | 🍃 Lite Tier |
| :--- | :--- | :--- | :--- |
| **Target Hardware** | $\ge 8$ CPU Cores / High-end GPU | 4 – 7 CPU Cores / Laptops | $< 4$ CPU Cores / VMs |
| **Card Backdrop Blur** | 20.0 px (Dual pass) | 14.0 px (Single pass) | 0.0 px (Bypassed) |
| **Card Opacity** | 25% Frosted Glass | 32% Semi-glass | 78% High-contrast Acrylic |
| **Floating Mesh Orbs** | Active (GPU Raster Cache) | Active (GPU Raster Cache) | Disabled (0% CPU cost) |
| **Comet Border Loop** | 120 FPS / 60 FPS | 60 FPS | 60 FPS Static fallback |

---

## 🗂️ Directory & Technical Architecture

`	ext
JA_IQ5_Flash/
├── bin/                             # Embedded Qualcomm & Android binaries
│   ├── adb.exe                      # Android Debug Bridge utility
│   ├── fastboot.exe                 # Android Fastboot protocol utility
│   ├── fh_loader.exe                # Qualcomm Firehose Loader binary
│   └── *.dll                        # Required Windows runtime dynamic libraries
├── dist/                            # Packaged release folder (built via build.bat)
│   ├── ja_iq5_flash.exe             # Standalone Windows x64 executable
│   └── JA_IQ5_Flash_v1.2.1_Windows_x64.zip # Standalone parent-folder zip release
├── lib/                             # Core Dart & Flutter application source code
│   ├── modules/                     # Modular business logic & services
│   │   ├── logic/                   # Device management, sessions & workers
│   │   │   ├── device_manager.dart  # Win32 SetupAPI COM port & ADB poller
│   │   │   ├── fastboot_to_edl_worker.dart # Fastboot -> ADB -> EDL pipeline
│   │   │   ├── firmware_slot.dart   # 3-slot profile model & file validator
│   │   │   ├── flash_session.dart   # fh_loader stdout parser & state machine
│   │   │   └── reboot_worker.dart   # Sahara reset & ADB reboot workers
│   │   ├── ui/                      # Bento Glassmorphism UI components
│   │   │   ├── adb_device_card.dart # ADB / Fastboot device status widget
│   │   │   ├── app_colors.dart      # Win10/Win11 Light & Dark theme tokens
│   │   │   ├── device_card.dart     # Qualcomm EDL device progress card
│   │   │   ├── dialogs.dart         # Slot rename & confirmation modals
│   │   │   ├── glass_widgets.dart   # BentoCard, RotatingGlowBorder, BounceMarquee
│   │   │   ├── main_window.dart     # Two-column primary interface & monitor
│   │   │   ├── settings_dialog.dart # Glass tuning, hardware tiers & User Guide
│   │   │   └── styles.dart          # AppTheme state & hardware profiling
│   │   ├── constants.dart           # USB VIDs/PIDs, paths, and version tokens
│   │   ├── i18n.dart                # Trilingual translation maps (EN, VI, CN)
│   │   ├── ja_license_checker.dart  # HMAC-SHA256 HWID license verification
│   │   └── utils.dart               # INI config parser, logging & file helpers
│   └── main.dart                    # Application entry point & single-instance guard
├── test/                            # Comprehensive unit & widget test suites
│   ├── flash_lifecycle_test.dart    # Engine state machine & abort cycle tests
│   └── widget_test.dart             # UI contrast, marquee, tier & dialog tests
├── windows/                         # Native C++ Windows desktop runner
│   └── runner/                      # Flutter window chrome & Mica/Acrylic hooks
├── ABOUT.txt                        # Standard JA Auto Git project information card
├── build.bat                        # Automated Windows release compiler & packager
├── CHANGELOG.md                     # Cumulative release version history
├── config.ini                       # User configuration & persistent preferences
├── FLASH_TROUBLESHOOTING.md         # Factory technician troubleshooting handbook
└── pubspec.yaml                     # Flutter package metadata & dependencies
`

---

## ⚡ Quick Start Guide

### Option A: Standard Windows Installation (Recommended)
1. Download `JA_IQ5_Flash_v1.3.0_Windows_x64.zip` from [Releases](https://github.com/jatechvn/JA_IQ5_Flash/releases).
2. Extract the package, right-click `install.bat` and run it (no Administrator rights required).
3. The app is installed into `%LOCALAPPDATA%\Programs\JA_IQ5_Flash` with Desktop & Start Menu shortcuts.
4. To uninstall, run `uninstall.bat` or remove via Windows Settings → Installed apps.

### Option B: Portable Run
1. Download the latest release package `JA_IQ5_Flash_v1.3.0_Windows_x64.zip` from [Releases](https://github.com/jatechvn/JA_IQ5_Flash/releases).
2. Extract the ZIP package to any directory (e.g. `D:\Tools\JA_IQ5_Flash\`).
3. Run `ja_iq5_flash.exe`.
4. Ensure your Qualcomm QDLoader 9008 drivers and Android USB drivers are installed on Windows.

### Option C: Building from Source
Prerequisites:
- Flutter SDK $\ge 3.22.0$ (Dart $\ge 3.4.0$)
- Visual Studio 2022 with "Desktop development with C++"
- Git

```bash
git clone https://github.com/jatechvn/JA_IQ5_Flash.git
cd JA_IQ5_Flash
flutter pub get
flutter run -d windows
```

To compile a self-contained release zip:
```cmd
build.bat
```

---

## ⚙️ Configuration & Settings

Preferences are stored in `config.ini`:

```ini
[APP]
language = VI
theme = dark
compact = false

[PATHS]
active_slot = 0
slot_0_name = Factory Stock ROM
slot_0_path = D:\Firmware\Qualcomm_SDM660_Factory_v10.3
slot_0_type = factory
slot_1_name = User / Custom ROM
slot_1_path = 
slot_1_type = user
slot_2_name = Diag / Test ROM
slot_2_path = 
slot_2_type = diag

[GLASS]
perf_mode = auto
card_blur = 20.0
card_opacity = 0.25
dialog_blur = 20.0
dialog_opacity = 0.85
enable_mesh_orbs = true
mesh_orb_opacity = 0.24
`

---

## 📜 Changelog

See full release history and notes in [CHANGELOG.md](CHANGELOG.md).

- **v1.3.0 (2026-09-21)**:
  - Complete LAN Over-The-Air (OTA) Update System (`OtaUpdateService` + `update_config.json`).
  - Interactive Bento Frosted Glass Update Modal (`GlassUpdateDialog`) with release notes and progress.
  - Dedicated 5th Settings Tab ("LAN OTA") with SMB server path, credentials, interval, test connection, and config folder launcher.
  - Top Bar update pill badge with hover expand and background startup auto-check.
  - Fixed duplicated action icons on EDL and ADB toolbar buttons.
  - 57 passing automated unit & widget tests (100% green).
- **v1.2.1 (2026-09-12)**:
  - Real-time live responsiveness for Bento Card Blur & Opacity sliders (MES Tool Standard).
  - Global `ChangeNotifierProvider` architecture with reactive `context.watch<AppTheme>()`.
  - Automatic GPU `BackdropFilter` bypass when blur is 0 px (Lite mode).
  - Proportional dynamic opacity scaling for slot cards and column containers.
  - Safe cancellation rollback and persistence on Settings Dialog.
  - Added 5th User Guide section for Bento Glassmorphism across EN, VI, CN.
  - 43 passing automated unit & widget tests (100% green).
- **v1.2.0 (2026-09-12)**:
  - Two-Column layout dividing EDL 9008 and ADB/Fastboot monitoring.
  - 3-slot ROM selector with rotating neon glow border (RotatingGlowBorder).
  - Asymmetric Bounce Marquee path input (GlassBouncePathField / BounceMarqueeText).
  - Hardware Tier Profiling system (Ultra, Balanced, Lite).
  - Theme-aware high-contrast Light Mode cards (WCAG AAA compliant).
  - GPU texture rasterization caching for 120 FPS glass animations.

---

## 📄 License & Author

- **Author**: JATech VN / John Alaa
- **Website**: [https://jatechvn.github.io/](https://jatechvn.github.io/)
- **Repository**: [https://github.com/jatechvn/JA_IQ5_Flash](https://github.com/jatechvn/JA_IQ5_Flash)
- **License**: Released under the [MIT License](LICENSE).
