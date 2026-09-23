# 📘 Hướng dẫn Sử dụng - JA IQ5 Reflash v1.3.1

Ứng dụng desktop chuyên nghiệp hỗ trợ nạp firmware tự động cho nhiều thiết bị Qualcomm Snapdragon (EDL 9008) đồng thời trên nền tảng Windows 10 & 11 (x64).

---

## 📑 Mục lục
1. [Khởi động & Cài đặt](#1-khởi-động--cài-đặt)
2. [Giao diện & Bố cục 2 Cột](#2-giao-diện--bố-cục-2-cột)
3. [Quản lý 3 Slot Firmware](#3-quản-lý-3-slot-firmware)
4. [Quy trình Nạp ROM Tự động](#4-quy-trình-nạp-rom-tự-động)
5. [Cập nhật Tự động qua Mạng LAN (OTA)](#5-cập-nhật-tự-động-qua-mạng-lan-ota)
6. [Tối ưu Cấu hình Máy & Kính mờ (Bento Glassmorphism)](#6-tối-ưu-cấu-hình-máy--kính-mờ-bento-glassmorphism)
7. [Xử lý Sự cố & Hỏi đáp](#7-xử-lý-sự-cố--hỏi-đáp)

---

## 1. Khởi động & Cài đặt

### Cách 1: Cài đặt chuẩn vào Windows (Khuyên dùng)
1. Tải gói phát hành `JA_IQ5_Flash_v1.3.1_Windows_x64.zip`.
2. Giải nén gói phát hành, nhấp đúp vào `install.bat` để chạy cài đặt tự động (không cần quyền Administrator).
3. Ứng dụng sẽ được cài đặt vào `%LOCALAPPDATA%\Programs\JA_IQ5_Flash` với đầy đủ shortcut trên Desktop và Start Menu.
4. Gỡ bỏ bất kỳ lúc nào qua `uninstall.bat` hoặc Control Panel / Windows Settings.

### Cách 2: Chạy trực tiếp bản Portable
1. Tải gói phát hành `JA_IQ5_Flash_v1.3.1_Windows_x64.zip`.
2. Giải nén toàn bộ nội dung gói vào thư mục làm việc (ví dụ: `D:\Tools\JA_IQ5_Flash\`).
3. Nhấp đúp chuột vào `ja_iq5_flash.exe` để mở ứng dụng.
4. *Lưu ý*: Ứng dụng tự động tạm dừng Qualcomm Service khi khởi động để bắt trọn gói Sahara 9008 và tự kích hoạt lại khi đóng ứng dụng.

---

## 2. Giao diện & Bố cục 2 Cột

Ứng dụng chia tách giao diện thành 2 cột độc lập tối ưu cho môi trường nhà máy:
- **Cột Trái — EDL (9008) Sẵn sàng Flash**:
  - Quản lý đồng thời tối đa **8 cổng COM** EDL (`USB\VID_05C6&PID_9008`).
  - Hiển thị tiến trình nạp %, tốc độ truyền tải byte/s, tên phân vùng đang nạp (`boot`, `system`, `vendor`, `userdata`...).
  - Mỗi thẻ thiết bị có nút **Flash Ngay**, **Dừng**, và **Reboot → ADB** độc lập.
- **Cột Phải — ADB / Fastboot**:
  - Tự động nhận diện thiết bị kết nối qua ADB hoặc Fastboot.
  - Hỗ trợ chuyển đổi nhanh toàn bộ thiết bị sang EDL bằng 1 click (`Reboot All → EDL`).
- **Thanh Công cụ Đỉnh (Top Menu Bar)**:
  - Tên ứng dụng, phiên bản, thông tin bản quyền (License).
  - Nút chuyển nhanh Hardware Tier (`Auto`, `Ultra`, `Balanced`, `Lite`).
  - Huy hiệu cập nhật mạng LAN OTA (`v{version}`) khi có bản phát hành mới.
  - Nút Cài đặt (`Settings`) và chuyển đổi ngôn ngữ (Tiếng Việt, English, 中文).

---

## 3. Quản lý 3 Slot Firmware

Hỗ trợ 3 cấu hình ROM độc lập giúp kỹ thuật viên chuyển đổi nhanh chóng:
- **Slot 1 (Factory Stock ROM)**: Dành cho bản ROM chuẩn xuất xưởng nhà máy (đầy đủ phân vùng).
- **Slot 2 (User / Custom ROM)**: Dành cho bản ROM tùy biến hoặc cài đặt ứng dụng khách hàng.
- **Slot 3 (Diag / Test ROM)**: Dành cho bản ROM kỹ thuật, kiểm định phần cứng và hiệu chuẩn sóng RF.

### Thao tác với Slot ROM:
- **Chọn Slot**: Nhấp chuột vào thẻ Slot tương ứng. Thẻ đang chọn sẽ có hiệu ứng **Viền sáng sao băng xoay quanh (Rotating Glow Border)**.
- **Đổi đường dẫn**: Sử dụng nút **Duyệt thư mục (Browse)**, **Dán (Paste)** từ clipboard, hoặc chỉnh sửa trực tiếp trên ô đường dẫn. Ô đường dẫn hỗ trợ hiệu ứng **Cuộn bật nảy mượt mà (Bounce Marquee)** cho đường dẫn dài.
- **Đổi tên & Loại Slot**: Nhấp đúp vào thẻ Slot để mở hộp thoại tùy chỉnh tên hiển thị và gán preset nhanh.

---

## 4. Quy trình Nạp ROM Tự động (Auto Flash Pipeline)

Khi bật công tắc **Tự động Flash (Auto Flash)** trên thanh công cụ:
1. Thiết bị cắm vào ở chế độ Fastboot/ADB sẽ được tự động chuyển sang chế độ EDL (9008).
2. Khi phát hiện cổng EDL hợp lệ, hệ thống tự động tải Firehose Programmer (`prog_firehose_ddr.elf`) và nạp các phân vùng theo file XML.
3. Sau khi flash thành công 100%, hệ thống tự động khởi động lại thiết bị về hệ điều hành chính (ADB).
4. Tiến trình được cách ly độc lập cho từng cổng COM, lỗi trên một thiết bị không ảnh hưởng đến các thiết bị còn lại.

---

## 5. Cập nhật Tự động qua Mạng LAN (OTA)

Tính năng mới trong phiên bản **v1.3.0** cho phép dây chuyền sản xuất tự động nhận bản cập nhật mới nhất từ máy chủ nội bộ mà không cần cài đặt lại thủ công:

### Cấu hình trong Cài đặt (Tab "LAN OTA"):
1. Nhấp vào nút **Cài đặt (Settings)** trên thanh công cụ, chuyển sang tab số 2: **Cập nhật OTA**.
2. **Tần suất tự động kiểm tra**:
   - *Mỗi ngày khi khởi động* (Mặc định)
   - *Hàng tuần (7 ngày)*
   - *Hàng tháng (30 ngày)*
   - *Tắt (Chỉ kiểm tra thủ công)*
3. **Đường dẫn thư mục cập nhật mạng LAN (SMB / UNC)**:
   - Mặc định: `\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_IQ5_Flash`
4. **Tài khoản & Mật khẩu**: Nhập thông tin đăng nhập máy chủ Windows Share (nếu cần).
5. Nhấp **Thử kết nối máy chủ** để xác minh đường truyền.
6. Nhấp **Lưu cài đặt**. File cấu hình `update_config.json` sẽ được lưu tự động cạnh file thực thi.

### Quy trình Nhận & Áp dụng Cập nhật:
1. Khi có bản cập nhật mới, thanh Top Bar sẽ hiển thị nút màu ngọc lục bảo: `v{newVersion}`.
2. Nhấp vào nút để mở **Hộp thoại Cập nhật Bento Frosted Glass**.
3. Xem chi tiết thông tin bản vá (Release Notes), dung lượng tải về và nhấn **Cập nhật ngay**.
4. Ứng dụng tự động tải gói zip, kiểm tra tính toàn vẹn và kích hoạt script `apply_update.bat` chạy nền để ghi đè phiên bản mới, tự động sao lưu và khởi chạy lại ứng dụng hoàn tất.

---

## 6. Tối ưu Cấu hình Máy & Kính mờ (Bento Glassmorphism)

Trong hộp thoại Cài đặt (Tab **Kính mờ**):
- **Phân cấp Phần cứng (Hardware Tier)**:
  - **Ultra (120 FPS)**: Đầy đủ hiệu ứng kính mờ 20px, hạt sáng nền chuyển động mượt mà cho PC cấu hình cao.
  - **Balanced (60 FPS)**: Hiệu ứng kính mờ 14px tối ưu pin và hiệu năng cho laptop văn phòng.
  - **Lite (Zero-Lag)**: Giao diện Acrylic trong suốt loại bỏ độ trễ, thích hợp cho máy cấu hình thấp hoặc máy ảo.
- **Xem trước thời gian thực (Live Preview)**:
  - Kéo thanh trượt **Độ mờ kính (Blur)** và **Độ trong suốt (Opacity)** để xem trực tiếp thay đổi trên nền ứng dụng.
  - Nếu đóng hộp thoại mà không nhấn "Lưu cài đặt", hệ thống sẽ tự động **Rollback** về thông số ban đầu.

---

## 7. Xử lý Sự cố & Hỏi đáp

- **Không nhận cổng COM 9008**: Kiểm tra lại driver Qualcomm HS-USB QDLoader 9008 trong Device Manager.
- **Báo thiếu file Programmer**: Đảm bảo thư mục firmware đã chọn có đầy đủ file `prog_firehose_ddr.elf`, `rawprogram_unsparse0.xml`, và `patch0.xml`.
- **Lỗi kết nối máy chủ OTA**: Kiểm tra kết nối mạng LAN/Wi-Fi công ty tới địa chỉ IP máy chủ và xác thực tài khoản chia sẻ.
- **Log chi tiết**: Nhấp vào nút **Sao chép log** tại góc dưới để gửi thông tin cho đội ngũ kỹ thuật hỗ trợ.

---

*Bản quyền © 2026 JATech VN. Mọi quyền được bảo lưu.*
