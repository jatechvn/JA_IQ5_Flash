# Tổng Hợp Lỗi Nạp Sahara (Qualcomm EDL 9008) & Giải Pháp Khắc Phục

Tài liệu này tổng hợp toàn bộ các vấn đề nghiêm trọng gặp phải trong quá trình tối ưu hóa module nạp Sahara bằng ngôn ngữ Dart (Win32 FFI) so với Python (`sahara.py` / QFIL) và cách chúng ta đã xử lý thành công để đưa ứng dụng đi vào trạng thái nạp ổn định.

---

## 1. Lỗi Chu kỳ Sống của Cổng COM (Đóng/Mở cổng liên tục)
* **Triệu chứng:** Phiên nạp Sahara bị treo hoặc thiết bị tự động thoát chế độ EDL khi bắt đầu chuyển giao trạng thái nạp.
* **Nguyên nhân:** 
  - Trong code Dart cũ, tại các điểm Strategy A, B, C, để đổi `timeout` chờ đọc của cổng COM, ta thường gọi `serial.close()` rồi `serial.open()` lại với timeout mới.
  - Trên Windows, việc đóng Handle của cổng COM ảo (`CloseHandle`) sẽ hạ chân tín hiệu DTR/RTS xuống Low. Đối với chip Qualcomm EDL, hành động này báo hiệu máy tính đã ngắt kết nối, khiến chip lập tức reboot hoặc thoát khỏi chế độ nạp Sahara.
* **Giải pháp:** 
  - Loại bỏ hoàn toàn việc đóng/mở cổng COM giữa chừng.
  - Viết thêm hàm `setTimeout(double seconds)` gọi trực tiếp API Win32 `SetCommTimeouts` trên Handle đang mở để thay đổi thời gian chờ đọc một cách động mà không ngắt kết nối vật lý.

---

## 2. Lỗi Gọi Hàm `FlushFileBuffers` Trên Driver Cổng COM Ảo
* **Triệu chứng:** Gửi tiêu đề ELF của file programmer đi nhưng thiết bị báo lỗi `status=0x08` (RX Timeout - Hết thời gian chờ nhận dữ liệu).
* **Nguyên nhân:** 
  - Để giả lập hàm `flush()` của Python, code Dart đã gọi API Win32 `FlushFileBuffers(_handle)`.
  - Theo tài liệu Microsoft MSDN, `FlushFileBuffers` chỉ dùng cho file hệ thống, không hỗ trợ thiết bị truyền thông (serial port). Gọi nó trên cổng COM đồng bộ (Non-Overlapped) sẽ khiến driver USB Virtual COM của Qualcomm gặp lỗi và tự động **xóa sạch (discard)** hàng đợi ghi, làm mất gói tin trước khi kịp gửi qua cáp USB.
* **Giải pháp:** 
  - Chuyển hàm `flush()` thành hàm rỗng (no-op). Đối với cổng COM ghi đồng bộ, dữ liệu từ hàm `WriteFile` sẽ tự động được đẩy đi ngay lập tức bởi hệ điều hành mà không cần flush cưỡng bức.

---

## 3. Lỗi Trỏ Lệch Vùng Nhớ Trong Dart VM (`Uint8List.view`)
* **Triệu chứng:** Thiết bị nhận đủ 64 bytes đầu tiên nhưng lập tức từ chối programmer với mã lỗi cấu trúc ELF không hợp lệ.
* **Nguyên nhân:** 
  - Code Dart trích xuất chunk dữ liệu bằng lệnh: `Uint8List.view(elfData.buffer, dataOffset, dataLength)`.
  - Trong máy ảo Dart, hàm `file.readAsBytesSync()` thường đọc dữ liệu vào một bộ đệm dùng chung lớn (buffer pool). Lúc này, `elfData.buffer` chứa toàn bộ bộ đệm đó và có một khoảng lệch (`elfData.offsetInBytes` > 0).
  - Lệnh `Uint8List.view` nếu chỉ truyền `dataOffset` sẽ đọc dữ liệu tính từ đầu bộ đệm dùng chung (chứa dữ liệu rác của máy ảo Dart) thay vì dữ liệu thực của file programmer. Chip nhận được 64 bytes rác nên báo lỗi ELF Header.
* **Giải pháp:** 
  - Chuyển sang sử dụng hàm sao chép phân vùng an toàn: `elfData.sublist(dataOffset, dataOffset + dataLength)`. Lệnh này đảm bảo lấy đúng các byte của file bất kể cấu trúc vùng nhớ bên dưới của Dart VM.

---

## 4. Lỗi Thiếu Tín Hiệu Điều Khiển Dòng (DTR/RTS Low)
* **Triệu chứng:** Thiết bị không phản hồi, bị timeout 30 giây trong Strategy C mặc dù cổng COM vẫn mở thành công.
* **Nguyên nhân:** 
  - Cấu hình cũ thiết lập `dcb.ref.bitfield = 1` (chỉ bật binary mode, tắt toàn bộ các cờ khác).
  - Chip Qualcomm EDL yêu cầu hai đường tín hiệu điều khiển **DTR (Data Terminal Ready)** và **RTS (Request To Send)** phải ở mức High (Enable) thì mới chấp nhận nhận dữ liệu từ PC. Nếu hai đường này bị tắt (Low), driver USB của chip sẽ tự động nuốt/bỏ qua toàn bộ dữ liệu gửi đến.
* **Giải pháp:** 
  - Cập nhật cờ `bitfield = 4113` (kích hoạt `fBinary = 1`, `fDtrControl = DTR_CONTROL_ENABLE`, `fRtsControl = RTS_CONTROL_ENABLE`).
  - Gọi thêm hàm Win32 API `EscapeCommFunction` với tham số `SETDTR` (5) và `SETRTS` (3) ngay sau khi mở cổng để cưỡng bức kéo hai đường tín hiệu này lên mức High.

---

## 5. Lỗi Gửi Trùng Lặp Gói Tin Bắt Tay (Strategy C)
* **Triệu chứng:** Bắt tay thành công nhưng ngay khi gửi 64 bytes đầu tiên của file programmer, chip báo lỗi `status=0x08` (Protocol Abort/Timeout).
* **Nguyên nhân:** 
  - Để dọn dẹp các trạng thái rác trước đó, Strategy C của Dart đã gửi gói tin phản hồi mù `HELLO_RESP` lặp lại **3 lần liên tiếp** cách nhau 30ms.
  - Khi nhận gói `HELLO_RESP` đầu tiên, chip điện thoại lập tức chuyển trạng thái sang nạp dữ liệu (`IMAGE_TX`) và gửi yêu cầu `READ_64`.
  - Việc PC tiếp tục gửi thêm 2 gói `HELLO_RESP` sau đó bị chip coi là **lỗi vi phạm nghiêm trọng về trình tự gói tin (Out-of-order packet)**. Do đó chip lập tức đóng băng tiến trình và trả về lỗi.
* **Giải pháp:** 
  - Chỉ gửi gói tin bắt tay `HELLO_RESP` **đúng 1 lần duy nhất**, tương tự như cách PySerial của Python vận hành.

---

## 6. Xung Đột Dịch Vụ Hệ Thống `qcmtusvc` (Qualcomm MTU Service)
* **Triệu chứng:** Không thể lấy được gói tin bắt tay `HELLO` đầu tiên từ thiết bị khi cắm cáp.
* **Nguyên nhân:** 
  - Dịch vụ `qcmtusvc.exe` chạy ngầm của Windows luôn tự động chiếm quyền điều khiển cổng COM và tiêu thụ mất gói tin `HELLO` của thiết bị ngay khi cắm cáp. Điều này làm cho các ứng dụng bên thứ ba (không thông qua QPST coordinate) bị mất kết nối hoặc xung đột dữ liệu.
* **Giải pháp:** 
  - Thiết kế tiến trình tự động dừng dịch vụ `qcmtusvc` khi khởi động nạp (nếu có quyền Admin) và khởi động lại sau khi nạp xong.
  - Loại bỏ bắt buộc tự nâng quyền Admin lúc khởi chạy app (giúp app chạy được ở quyền User thường), đồng thời bổ sung thông tin log hướng dẫn người dùng tắt thủ công dịch vụ trong `services.msc` khi chạy quyền User thường để tránh xung đột.
