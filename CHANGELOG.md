# 📜 CHANGELOG - JA IQ5 Reflash

All notable changes to **JA IQ5 Reflash** will be documented in this file.

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
