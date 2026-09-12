<div align="center">

# ⚡ JA IQ5 Reflash

**Công cụ Nạp Firmware & Cứu hộ Phần cứng Qualcomm Snapdragon Đa Cổng Chuyên nghiệp**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-0078D6?logo=windows&logoColor=white)](https://microsoft.com)
[![Release](https://img.shields.io/badge/Release-v1.2.1-00C853?logo=github)](https://github.com/jatechvn/JA_IQ5_Flash/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • <b>🇻🇳 Tiếng Việt</b> • <a href="README.zh-CN.md">🇨🇳 中文</a>
</p>

*Ứng dụng desktop chuẩn công nghiệp chạy trên nền Windows được phát triển bằng Flutter & Dart, hỗ trợ nạp firmware tự động cho nhiều thiết bị Qualcomm IQ5 đồng thời qua chế độ EDL (9008), điều phối Fastboot/ADB và giao diện kính mờ Bento Glassmorphism cao cấp.*

</div>

---

## 📑 Mục lục

- [Tổng quan](#-tổng-quan)
- [Tính năng cốt lõi](#-tính-năng-cốt-lõi)
- [Kiến trúc Phân cấp Cấu hình Phần cứng (Hardware Tier)](#-kiến-trúc-phân-cấp-cấu-hình-phần-cứng-hardware-tier)
- [Cấu trúc Thư mục & Kỹ thuật](#-cấu-trúc-thư-mục--kỹ-thuật)
- [Hướng dẫn Khởi động Nhanh](#-hướng-dẫn-khởi-động-nhanh)
  - [Cách A: Chạy bản Portable độc lập (Khuyên dùng)](#cách-a-chạy-bản-portable-độc-lập-khuyên-dùng)
  - [Cách B: Biên dịch từ Mã nguồn](#cách-b-biên-dịch-từ-mã-nguồn)
- [Cấu hình & Tùy chọn Hệ thống](#-cấu-hình--tùy-chọn-hệ-thống)
- [Lịch sử Thay đổi (Changelog)](#-lịch-sử-thay-đổi-changelog)
- [Bản quyền & Tác giả](#-bản-quyền--tác-giả)

---

## 🌟 Tổng quan

**JA IQ5 Reflash** là giải pháp phần mềm chuyên dụng dành cho các kỹ sư kiểm thử phần cứng, dây chuyền lắp ráp và kỹ thuật viên sửa chữa thiết bị chạy vi xử lý Qualcomm Snapdragon (đặc biệt là dòng thiết bị Qualcomm IQ5). Phần mềm cho phép nạp firmware đồng thời cho tối đa **8 thiết bị** qua giao thức cứu hộ khẩn cấp Qualcomm Emergency Download (EDL 9008).

Với quy trình 3 giai đoạn tự động (Fastboot → ADB → EDL → Flash → Reboot), bố cục 2 cột độc lập, viền sáng sao băng xoay quanh thẻ chọn ROM, ô đường dẫn cuộn bật nảy mượt mà cùng hệ thống tối ưu hóa GPU theo cấu hình máy, JA IQ5 Reflash mang lại năng suất tối đa và độ tin cậy tuyệt đối trong nhà máy.

---

## 🚀 Tính năng cốt lõi

### ⚡ Nạp Firmware Đồng thời Đa Thiết bị (Tối đa 8 cổng COM)
- Quản lý và nạp firmware song song cho tối đa **8 thiết bị Qualcomm Snapdragon** trên các cổng COM độc lập (USB\VID_05C6&PID_9008).
- Tích hợp engine h_loader.exe và Sahara Protocol với cơ chế phân tích luồng stdout thời gian thực để hiển thị tiến độ % và tốc độ nạp từng phân vùng.
- Hỗ trợ đầy đủ bộ file tiêu chuẩn: awprogram_unsparse0.xml, patch0.xml và prog_firehose_ddr.elf.

### 📱 Bố cục 2 Cột Độc lập (Dedicated Two-Column Layout)
- **Cột Trái (EDL 9008)**: Khu vực ưu tiên nạp ROM, hiển thị chi tiết tiến độ nạp, tốc độ truyền tải, dung lượng từng phân vùng và nút Dừng/Reboot cho từng thiết bị.
- **Cột Phải (ADB & Fastboot)**: Giám sát các thiết bị đang kết nối ở chế độ ADB hoặc Fastboot, tự động nhận diện model, trạng thái ủy quyền và nút 1-click chuyển toàn bộ sang EDL.

### 💾 3 Slot ROM Thông minh & Viền Sáng Xoay quanh (RotatingGlowBorder)
- Chuyển đổi tức thì giữa 3 cấu hình firmware độc lập:
  - **Slot 1**: Bản ROM Chuẩn Nhà Máy (FACTORY ROM • Màu Xanh Cyan)
  - **Slot 2**: Bản ROM Khách Hàng / Tùy biến (USER ROM • Màu Xanh Ngọc)
  - **Slot 3**: Bản ROM Kỹ Thuật / Chẩn đoán QA (DIAG / TEST • Màu Vàng Hổ Phách)
- **Viền sáng xoay quanh**: Thẻ ROM đang chọn được bao quanh bởi dải ánh sáng sao băng chuyển động vòng tròn cuốn hút và nổi bật.
- **Nền kính thích ứng theo Theme**: Nền trắng sữa mờ thanh thoát ở giao diện Sáng (Light Mode) với độ tương phản WCAG AAA vượt trội; nền kính Cyberpunk neon rực rỡ ở giao diện Tối (Dark Mode).

### 🔄 Ô Đường dẫn Cuộn Bật Nảy (GlassBouncePathField)
- Giải quyết triệt để tình trạng đường dẫn thư mục quá dài bị tràn hoặc cắt cụt.
- **Hiệu ứng Ping-Pong bất đối xứng**: Dừng 1.4 giây ở đầu để nhận diện ổ đĩa, cuộn mượt mà sang phải với vận tốc 40 px/s để quét qua toàn bộ đường dẫn, dừng 1.4 giây ở cuối để đọc tên thư mục firmware đích, rồi cuộn ngược lại.
- **Chuyển đổi tức thì**: Tự động chuyển thành TextField khi click chuột để gõ phím, chỉnh sửa hoặc dán đường dẫn nhanh bằng Ctrl+V.

### 🎛️ Tự động Nhận diện Cấu hình Phần cứng (Hardware Tier)
- Tự động đo đạc số nhân CPU và phiên bản Windows để phân loại mức đồ họa tối ưu:
  - **Ultra Mode (120 FPS)**: Hiệu ứng kính mờ kép cao cấp, 3 quả cầu phát sáng Mesh Orbs và viền sáng sao băng tốc độ cao dành cho máy PC mạnh.
  - **Balanced Mode (60 FPS)**: Cân bằng hoàn hảo hiệu ứng kính cho laptop văn phòng.
  - **Lite Mode (Zero Lag)**: Bỏ qua backdrop blur, tắt mesh orbs và sử dụng acrylic trong suốt cho máy cấu hình yếu hoặc máy ảo.
- Cho phép chuyển đổi nhanh vòng lặp bằng 1 click trên TopBar hoặc qua Cài đặt.

### 🎨 Giao diện Kính mờ Fluent Windows 11 với 4 Thanh Trượt Tinh chỉnh
- Điều chỉnh thời gian thực Độ mờ thẻ (Card Blur), Độ đục thẻ (Card Opacity), Độ mờ hộp thoại (Dialog Blur) và Độ đục hộp thoại (Dialog Opacity).
- Cơ chế GPU Raster Caching bằng RepaintBoundary giúp ứng dụng render cực nhẹ (~0.1ms cho mỗi khung hình chuyển động).

### 🛡️ Khóa Bản Quyền Phần cứng (HMAC-SHA256) & Đồng bộ Máy chủ Mạng Nội bộ (LAN)
- Bảo mật bằng mã băm phần cứng (HWID) duy nhất cho từng máy tính.
- Tự động quét và đồng bộ file bản quyền qua máy chủ mạng nội bộ LAN.

### 🌐 Hỗ trợ 3 Ngôn ngữ Linh hoạt
- Chuyển đổi trực tiếp không cần khởi động lại ứng dụng:
  - 🇺🇸 Tiếng Anh (English)
  - 🇻🇳 Tiếng Việt
  - 🇨🇳 Tiếng Trung (中文)

---

## 📊 Bảng So sánh Cấu hình Phần cứng (Hardware Tier)

| Chỉ số / Thiết lập | 🚀 Ultra Tier | ⚖️ Balanced Tier | 🍃 Lite Tier |
| :--- | :--- | :--- | :--- |
| **Yêu cầu Phần cứng** | $\ge 8$ Nhân CPU / GPU rời | 4 – 7 Nhân CPU / Laptop | $< 4$ Nhân CPU / Máy ảo |
| **Độ mờ kính (Backdrop Blur)** | 20.0 px (2 lượt quét) | 14.0 px (1 lượt quét) | 0.0 px (Bỏ qua Blur) |
| **Độ đục thẻ Bento (Card Opacity)** | 25% Kính mờ | 32% Bán mờ | 78% Acrylic tương phản |
| **Quả cầu phát sáng Mesh Orbs** | Hoạt động (VRAM Cache) | Hoạt động (VRAM Cache) | Tắt hoàn toàn (0% CPU) |
| **Vòng quét viền sáng** | 120 FPS / 60 FPS | 60 FPS | Tĩnh / Tiết kiệm điện |

---

## ⚡ Hướng dẫn Khởi động Nhanh

### Cách A: Chạy bản Portable độc lập (Khuyên dùng)
1. Tải gói phát hành `JA_IQ5_Flash_v1.2.1_Windows_x64.zip` từ mục [Releases](https://github.com/jatechvn/JA_IQ5_Flash/releases).
2. Giải nén vào một thư mục bất kỳ (ví dụ: `D:\Tools\JA_IQ5_Flash\`).
3. Chạy file `ja_iq5_flash.exe`.
4. Đảm bảo máy tính Windows đã cài đặt đầy đủ driver Qualcomm QDLoader 9008 và driver USB Android.

### Cách B: Biên dịch từ Mã nguồn
Yêu cầu môi trường:
- Flutter SDK $\ge 3.22.0$ (Dart $\ge 3.4.0$)
- Visual Studio 2022 với gói "Desktop development with C++"
- Hệ điều hành Windows 10/11 x64

```bash
# 1. Clone mã nguồn
git clone https://github.com/jatechvn/JA_IQ5_Flash.git
cd JA_IQ5_Flash

# 2. Cài đặt các thư viện phụ thuộc
flutter pub get

# 3. Chạy bộ kiểm thử tự động
flutter test

# 4. Đóng gói bản phát hành Release x64
build.bat
```

File thực thi và file nén zip đóng gói sẽ được tạo tự động trong thư mục `dist/`.

---

## 📜 Lịch sử Thay đổi (Changelog)

Chi tiết lịch sử các phiên bản có tại [CHANGELOG.md](../CHANGELOG.md).

- **v1.2.1 (12/09/2026)**:
  - Cập nhật thời gian thực (real-time live preview) cho thanh trượt Bento Card Blur & Opacity chuẩn MES Tool.
  - Tích hợp kiến trúc `ChangeNotifierProvider` toàn cục với `context.watch<AppTheme>()`.
  - Tự động bỏ qua GPU `BackdropFilter` khi độ mờ là 0 px (Chế độ Lite tiết kiệm tài nguyên).
  - Tỷ lệ trong suốt (opacity scaling) động và hài hòa cho các thẻ slot ROM và container.
  - Cơ chế Rollback hoàn tác thông minh khi hủy bỏ cài đặt (Cancel) và lưu chuẩn xác vào `config.ini`.
  - Bổ sung mục Hướng dẫn số 5 về Tinh chỉnh Kính Bento hỗ trợ 3 ngôn ngữ EN, VI, CN.
  - Đạt 43/43 bài kiểm thử tự động (100% xanh).
- **v1.2.0 (12/09/2026)**:
  - Bổ sung bố cục 2 cột độc lập chia riêng khu vực EDL 9008 và ADB/Fastboot.
  - Bộ 3 slot ROM thông minh với viền sáng xoay quanh (RotatingGlowBorder).
  - Ô nhập đường dẫn cuộn bật nảy mượt mà (GlassBouncePathField).
  - Hệ thống tự động nhận diện cấu hình máy Hardware Tier (Ultra, Balanced, Lite).
  - Khắc phục triệt để độ tương phản thẻ ROM ở giao diện Sáng đạt chuẩn WCAG AAA.
  - Tối ưu GPU Texture Raster Caching cho hiệu ứng kính mờ 120 FPS.

---

## 📄 Bản quyền & Tác giả

- **Tác giả**: JATech VN / John Alaa
- **Trang chủ**: [https://jatechvn.github.io/](https://jatechvn.github.io/)
- **Kho lưu trữ GitHub**: [https://github.com/jatechvn/JA_IQ5_Flash](https://github.com/jatechvn/JA_IQ5_Flash)
- **Giấy phép**: Phát hành theo giấy phép mã nguồn mở [MIT License](../LICENSE).
