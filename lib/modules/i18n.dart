// lib/modules/i18n.dart

String _lang = 'VI';

void setLang(String lang) {
  if (['EN', 'VI', 'CN'].contains(lang)) {
    _lang = lang;
  }
}

String getLang() => _lang;

String tr(String key) {
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[_lang] ?? entry['EN'] ?? key;
}

const Map<String, Map<String, String>> _strings = {
  // Firmware bar
  'firmware_label': {
    'EN': '💾  FIRMWARE:',
    'VI': '💾  FIRMWARE:',
    'CN': '💾  固件:',
  },
  'change_btn': {'EN': '📂 Browse', 'VI': '📂 Duyệt thư mục', 'CN': '📂 浏览'},
  'paste_btn': {'EN': '📋 Paste', 'VI': '📋 Dán', 'CN': '📋 粘贴'},
  'paste_tooltip': {
    'EN': 'Paste directory path from clipboard',
    'VI': 'Dán đường dẫn thư mục từ clipboard',
    'CN': '从剪贴板粘贴目录路径',
  },
  'hint_paste_or_browse': {
    'EN': 'Paste or enter firmware folder path...',
    'VI': 'Nhập hoặc dán đường dẫn thư mục ROM...',
    'CN': '在此输入或粘贴固件文件夹路径...',
  },
  'log_slot_update_prefix': {
    'EN': 'Updated path for Slot',
    'VI': 'Đã cập nhật đường dẫn cho Slot',
    'CN': '已更新插槽路径',
  },
  'open_folder_btn': {'EN': '🖥️ Reveal', 'VI': '🖥️ Mở thư mục', 'CN': '🖥️ 打开目录'},
  'rename_slot': {'EN': '✏️ Rename', 'VI': '✏️ Đổi tên', 'CN': '✏️ 重命名'},
  'slot_factory_rom': {'EN': 'Factory Stock ROM', 'VI': 'Bản ROM Chuẩn Nhà Máy', 'CN': '原厂官方固件'},
  'slot_user_rom': {'EN': 'User / Custom ROM', 'VI': 'Bản ROM Khách Hàng / Tuỳ Biến', 'CN': '客户定制固件'},
  'slot_diag_rom': {'EN': 'Diag / Test ROM', 'VI': 'Bản ROM Kỹ Thuật / Chẩn Đoán', 'CN': '工程测试固件'},
  'slot_desc_factory': {'EN': 'Full partitions: boot, system, vendor, userdata...', 'VI': 'Phân vùng đầy đủ: boot, system, vendor, userdata...', 'CN': '完整分区: boot, system, vendor, userdata...'},
  'slot_desc_user': {'EN': 'Customer apps & customized build', 'VI': 'Bản ROM cấu hình ứng dụng khách hàng & tùy biến', 'CN': '客户应用与定制版本'},
  'slot_desc_diag': {'EN': 'Hardware QA, RF calibration & test', 'VI': 'Kiểm thử QA phần cứng & hiệu chuẩn RF', 'CN': '硬件测试与校准固件'},
  'fw_empty': {'EN': '⚪ No folder configured', 'VI': '⚪ Chưa cấu hình thư mục', 'CN': '⚪ 未配置文件夹'},
  'slot_active_badge': {'EN': 'ACTIVE', 'VI': 'ĐANG CHỌN', 'CN': '已选定'},
  'copy_logs': {'EN': '📋 Copy Logs', 'VI': '📋 Sao chép log', 'CN': '📋 复制日志'},
  'clear_logs': {'EN': '🗑️ Clear', 'VI': '🗑️ Xóa log', 'CN': '🗑️ 清空'},
  'logs_copied': {'EN': 'Logs copied to clipboard', 'VI': 'Đã sao chép log vào clipboard', 'CN': '日志已复制到剪贴板'},
  'connected_edl_badge': {'EN': 'EDL READY', 'VI': 'EDL SẴN SÀNG', 'CN': 'EDL就绪'},
  'connected_adb_badge': {'EN': 'ADB / FASTBOOT', 'VI': 'ADB / FASTBOOT', 'CN': 'ADB/FASTBOOT'},

  // Toolbar
  'scan_now': {'EN': '🔍  Scan Now', 'VI': '🔍  Quét ngay', 'CN': '🔍  立即扫描'},
  'no_devices': {
    'EN': 'No devices detected',
    'VI': 'Không phát hiện thiết bị',
    'CN': '未检测到设备',
  },
  'auto_flash_label': {
    'EN': '⚡ Auto Flash',
    'VI': '⚡ Tự động Flash',
    'CN': '⚡ 自动刷机',
  },
  'auto_flash_tip': {
    'EN':
        'When ON:\n• ADB/Fastboot detected → auto reboot to EDL\n• EDL detected → auto flash\n• Flash done → auto reboot to ADB',
    'VI':
        'Khi BẬT:\n• Phát hiện ADB/Fastboot → tự động reboot sang EDL\n• Phát hiện EDL → tự động flash\n• Flash xong → tự động reboot sang ADB',
    'CN':
        '开启时:\n• 检测到ADB/Fastboot → 自动重启到EDL\n• 检测到EDL → 自动刷机\n• 刷机完成 → 自动重启到ADB',
  },
  'flash_all': {'EN': '⚡  FLASH ALL', 'VI': '⚡  FLASH TẤT CẢ', 'CN': '⚡  全部刷机'},
  'abort_all': {'EN': '■  Abort All', 'VI': '■  Dừng tất cả', 'CN': '■  全部中止'},

  // Section headers
  'edl_header': {
    'EN': '📟  EDL (9008) — Flash Ready',
    'VI': '📟  EDL (9008) — Sẵn sàng Flash',
    'CN': '📟  EDL (9008) — 准备刷机',
  },
  'reboot_all_adb': {
    'EN': '🔄  Reboot All → ADB',
    'VI': '🔄  Khởi động lại → ADB',
    'CN': '🔄  全部重启 → ADB',
  },
  'reboot_all_tip': {
    'EN': 'Send Sahara RESET to all EDL devices → reboot to ADB',
    'VI':
        'Gửi lệnh reset Sahara tới tất cả thiết bị EDL → khởi động lại về ADB',
    'CN': '向所有EDL设备发送Sahara复位 → 重启到ADB',
  },
  'adb_header': {
    'EN': '📱  ADB / FASTBOOT — Boot to EDL',
    'VI': '📱  ADB / FASTBOOT — Boot sang EDL',
    'CN': '📱  ADB / FASTBOOT — 启动到EDL',
  },
  'boot_all_edl': {
    'EN': '🔄  Boot All → EDL',
    'VI': '🔄  Boot tất cả → EDL',
    'CN': '🔄  全部启动 → EDL',
  },
  'boot_all_tip': {
    'EN': 'Send reboot-edl to all ADB + fastboot devices',
    'VI': 'Gửi lệnh reboot-edl tới tất cả thiết bị ADB + fastboot',
    'CN': '向所有ADB + fastboot设备发送reboot-edl命令',
  },

  // Placeholders
  'placeholder_edl': {
    'EN':
        '🔌  Connect Qualcomm IQ5 devices in EDL mode (USB 9008)\n     Devices will appear automatically.',
    'VI':
        '🔌  Kết nối thiết bị Qualcomm IQ5 ở chế độ EDL (USB 9008)\n     Thiết bị sẽ xuất hiện tự động.',
    'CN': '🔌  以EDL模式连接高通IQ5设备 (USB 9008)\n     设备将自动显示。',
  },
  'placeholder_adb': {
    'EN':
        '📱  No ADB / Fastboot devices detected.\n     Connect a device via USB.',
    'VI':
        '📱  Không phát hiện thiết bị ADB / Fastboot.\n     Kết nối thiết bị qua USB.',
    'CN': '📱  未检测到ADB/Fastboot设备。\n     请通过USB连接设备。',
  },

  // Status messages
  'auto_on_status': {
    'EN': '⚡ Auto Flash ON — devices will be flashed automatically',
    'VI': '⚡ Tự động Flash BẬT — thiết bị sẽ được flash tự động',
    'CN': '⚡ 自动刷机已开启 — 设备将自动刷机',
  },
  'auto_off_status': {
    'EN': 'Auto Flash OFF',
    'VI': 'Tự động Flash TẮT',
    'CN': '自动刷机已关闭',
  },
  'fw_ok': {'EN': '✅ Firmware OK', 'VI': '✅ Firmware hợp lệ', 'CN': '✅ 固件正常'},
  'fw_missing': {
    'EN': '⚠️ Files missing',
    'VI': '⚠️ Thiếu file',
    'CN': '⚠️ 缺少文件',
  },
  'fw_invalid': {
    'EN': '❌ Invalid folder',
    'VI': '❌ Thư mục không hợp lệ',
    'CN': '❌ 无效文件夹',
  },

  // License dialog
  'lic_title': {
    'EN': '🔑  License Manager',
    'VI': '🔑  Quản lý Bản Quyền',
    'CN': '🔑  许可证管理',
  },
  'lic_valid': {
    'EN': '✅  License is valid',
    'VI': '✅  Bản quyền hợp lệ',
    'CN': '✅  许可证有效',
  },
  'lic_expired': {
    'EN': '⏰  License expired',
    'VI': '⏰  Bản quyền hết hạn',
    'CN': '⏰  许可证已过期',
  },
  'lic_no_key': {
    'EN': '⚠️  Not activated — no license file found.',
    'VI': '⚠️  Chưa kích hoạt — chưa tìm thấy file bản quyền.',
    'CN': '⚠️  未激活 — 未找到许可证文件。',
  },
  'lic_invalid': {
    'EN': '❌  Invalid license key.',
    'VI': '❌  Key bản quyền không hợp lệ.',
    'CN': '❌  许可证密钥无效。',
  },
  'lic_days': {
    'EN': 'Expires: {date}  |  {days} day(s) remaining',
    'VI': 'Hết hạn: {date}  |  Còn {days} ngày',
    'CN': '到期: {date}  |  剩余 {days} 天',
  },
  'lic_contact': {
    'EN': 'Contact Admin to renew or enter a new key below.',
    'VI': 'Liên hệ Admin để gia hạn hoặc nhập key mới bên dưới.',
    'CN': '请联系管理员续期或在下方输入新密钥。',
  },
  'lic_hwid_label': {
    'EN': '🖥  Hardware Machine ID (HWID):',
    'VI': '🖥  Mã phần cứng máy tính (HWID):',
    'CN': '🖥  硬件机器码 (HWID):',
  },
  'lic_copy': {'EN': '📋 Copy', 'VI': '📋 Sao chép', 'CN': '📋 复制'},
  'lic_key_label': {
    'EN': '🔑  PASTE LICENSE KEY:',
    'VI': '🔑  DÁN KEY BẢN QUYỀN:',
    'CN': '🔑  粘贴许可证密钥:',
  },
  'lic_placeholder': {
    'EN': 'Paste license key here…',
    'VI': 'Dán chuỗi key bản quyền vào đây…',
    'CN': '在此粘贴许可证密钥…',
  },
  'lic_paste_clip': {
    'EN': '📋 Paste from Clipboard',
    'VI': '📋 Dán từ Clipboard',
    'CN': '📋 从剪贴板粘贴',
  },
  'lic_activate': {
    'EN': '✅  Activate Key',
    'VI': '✅  Kích Hoạt Key',
    'CN': '✅  激活密钥',
  },
  'lic_sync': {
    'EN': '🔄 Sync from Server',
    'VI': '🔄 Đồng bộ Server',
    'CN': '🔄 从服务器同步',
  },
  'lic_close': {'EN': 'Close', 'VI': 'Đóng', 'CN': '关闭'},
  'lic_exit': {'EN': 'Exit App', 'VI': 'Thoát chương trình', 'CN': '退出程序'},
  'lic_copied': {
    'EN': '📋 HWID copied to clipboard.',
    'VI': '📋 Đã sao chép mã máy.',
    'CN': '📋 已复制到剪贴板。',
  },
  'lic_clip_empty': {
    'EN': 'Clipboard is empty.',
    'VI': 'Clipboard đang trống.',
    'CN': '剪贴板为空。',
  },
  'lic_syncing': {
    'EN': '🔄 Connecting to server…',
    'VI': '🔄 Đang kết nối server…',
    'CN': '🔄 正在连接服务器…',
  },
  'lic_sync_ok': {
    'EN': '✅  Synced successfully from LAN server.',
    'VI': '✅  Đồng bộ thành công từ server LAN.',
    'CN': '✅  从局域网服务器同步成功。',
  },
  'lic_sync_fail': {
    'EN': '❌  Server key not found: {path}',
    'VI': '❌  Không tìm thấy key trên server: {path}',
    'CN': '❌  服务器上找不到密钥: {path}',
  },
  'lic_sync_err': {
    'EN': '❌  Server connection error: {err}',
    'VI': '❌  Lỗi kết nối server: {err}',
    'CN': '❌  服务器连接错误: {err}',
  },
  'lic_enter_first': {
    'EN': '⚠️  Please paste a license key first.',
    'VI': '⚠️  Vui lòng dán key bản quyền trước.',
    'CN': '⚠️  请先粘贴许可证密钥。',
  },

  // Fastboot → ADB → EDL pipeline
  'fb_detected_auto_off': {
    'EN': '🔌 FASTBOOT device detected: {serial} — Auto Flash OFF, no action.',
    'VI': '🔌 Phát hiện FASTBOOT: {serial} — Tự động Flash TẮT, bỏ qua.',
    'CN': '🔌 检测到FASTBOOT设备: {serial} — 自动刷机已关闭，不操作。',
  },
  'fb_detected_auto_on': {
    'EN':
        '🔌 FASTBOOT {serial} detected — Auto Flash ON → starting Fastboot→ADB→EDL pipeline…',
    'VI':
        '🔌 Phát hiện FASTBOOT {serial} — Tự động Flash BẬT → bắt đầu pipeline Fastboot→ADB→EDL…',
    'CN': '🔌 检测到FASTBOOT {serial} — 自动刷机已开启 → 启动Fastboot→ADB→EDL流程…',
  },
  'fb_pipe_start': {
    'EN': '[Fastboot→ADB→EDL] Starting pipeline for {serial}',
    'VI': '[Fastboot→ADB→EDL] Bắt đầu pipeline cho {serial}',
    'CN': '[Fastboot→ADB→EDL] 启动{serial}的流程',
  },
  'fb_step1': {
    'EN': '  Step 1: fastboot reboot → {serial}…',
    'VI': '  Bước 1: fastboot reboot → {serial}…',
    'CN': '  第1步: fastboot reboot → {serial}…',
  },
  'fb_step1_ok': {
    'EN': '  Step 1 OK — waiting for ADB ({wait}s)…',
    'VI': '  Bước 1 OK — đợi ADB ({wait}s)…',
    'CN': '  第1步完成 — 等待ADB ({wait}s)…',
  },
  'fb_step1_fail': {
    'EN':
        'Fastboot reboot failed: {msg}\n⚠️ Use testpoint to enter EDL manually.',
    'VI':
        'Fastboot reboot thất bại: {msg}\n⚠️ Dùng testpoint để vào EDL thủ công.',
    'CN': 'Fastboot重启失败: {msg}\n⚠️ 请使用testpoint手动进入EDL。',
  },
  'fb_wait_adb': {
    'EN': '  Waiting for ADB… {remaining}s remaining',
    'VI': '  Đang đợi ADB… còn {remaining}s',
    'CN': '  等待ADB… 剩余 {remaining}s',
  },
  'fb_adb_timeout': {
    'EN':
        '⚠️ ADB not detected after {wait}s reboot from Fastboot.\nUse testpoint to enter EDL manually.',
    'VI':
        '⚠️ Không thấy ADB sau {wait}s reboot từ Fastboot.\nDùng testpoint để vào EDL thủ công.',
    'CN': '⚠️ Fastboot重启{wait}s后未检测到ADB。\n请使用testpoint手动进入EDL。',
  },
  'fb_step2_ok': {
    'EN': '  Step 2 OK — ADB online: {serial}',
    'VI': '  Bước 2 OK — ADB trực tuyến: {serial}',
    'CN': '  第2步完成 — ADB在线: {serial}',
  },
  'fb_step3': {
    'EN': '  Step 3: adb reboot edl → {serial}…',
    'VI': '  Bước 3: adb reboot edl → {serial}…',
    'CN': '  第3步: adb reboot edl → {serial}…',
  },
  'fb_step3_ok': {
    'EN': '  Step 3 OK — {serial} → EDL',
    'VI': '  Bước 3 OK — {serial} → EDL',
    'CN': '  第3步完成 — {serial} → EDL',
  },
  'fb_step3_fail': {
    'EN': 'adb reboot edl failed: {msg}',
    'VI': 'adb reboot edl thất bại: {msg}',
    'CN': 'adb reboot edl失败: {msg}',
  },
  'fb_done_ok': {
    'EN': '✅ {serial} → EDL (via Fastboot→ADB→EDL)',
    'VI': '✅ {serial} → EDL (qua Fastboot→ADB→EDL)',
    'CN': '✅ {serial} → EDL（通过Fastboot→ADB→EDL）',
  },
  'fb_adb_appeared': {
    'EN':
        '📱 [{serial}] ADB online (from Fastboot reboot) → sending reboot edl…',
    'VI':
        '📱 [{serial}] ADB trực tuyến (sau Fastboot reboot) → đang gửi reboot edl…',
    'CN': '📱 [{serial}] ADB已在线（来自Fastboot重启）→ 正在发送reboot edl…',
  },
  'fb_testpoint_badge': {
    'EN': '⚠️ {serial}: Fastboot reboot failed — use testpoint manually',
    'VI': '⚠️ {serial}: Fastboot reboot thất bại — dùng testpoint thủ công',
    'CN': '⚠️ {serial}: Fastboot重启失败 — 请手动使用testpoint',
  },
  'fb_testpoint_log': {
    'EN':
        '⚠️ [{serial}] Cannot reboot from Fastboot to ADB.\n   → Use testpoint to put device into EDL (9008) manually.',
    'VI':
        '⚠️ [{serial}] Không thể reboot từ Fastboot về ADB.\n   → Dùng testpoint để đưa thiết bị vào EDL (9008) thủ công.',
    'CN':
        '⚠️ [{serial}] 无法从 Fastboot 重启到 ADB。\n   → 请使用 testpoint 手动将设备进入 EDL (9008)。',
  },
  'fb_pipe_badge_ok': {
    'EN': '✅ {serial} → EDL (Fastboot pipeline)',
    'VI': '✅ {serial} → EDL (Pipeline Fastboot)',
    'CN': '✅ {serial} → EDL（Fastboot流程）',
  },
  'fb_pipe_badge_fail': {
    'EN': '❌ {serial} — Fastboot pipeline failed',
    'VI': '❌ {serial} — Pipeline Fastboot thất bại',
    'CN': '❌ {serial} — Fastboot流程失败',
  },

  // Flashing logs and status translation keys
  'log_app_started': {
    'EN': 'JA IQ5 Reflash application started.',
    'VI': 'Ứng dụng JA IQ5 Reflash đã khởi động.',
    'CN': 'JA IQ5 Reflash 应用程序已启动。',
  },
  'log_config_load_error': {
    'EN': 'Config load error: {err}',
    'VI': 'Lỗi tải cấu hình: {err}',
    'CN': '加载配置错误: {err}',
  },
  'log_config_save_error': {
    'EN': 'Config save error: {err}',
    'VI': 'Lỗi lưu cấu hình: {err}',
    'CN': '保存配置错误: {err}',
  },
  'log_edl_detected': {
    'EN': 'New EDL device detected: {port}',
    'VI': 'Phát hiện thiết bị EDL mới: {port}',
    'CN': '检测到新的 EDL 设备: {port}',
  },
  'log_edl_disconnected': {
    'EN': 'EDL device disconnected: {port}',
    'VI': 'Thiết bị EDL đã ngắt kết nối: {port}',
    'CN': 'EDL 设备已断开连接: {port}',
  },
  'log_flash_start': {
    'EN': 'Starting firmware flash for device {port}…',
    'VI': 'Bắt đầu nạp firmware cho thiết bị {port}…',
    'CN': '开始为设备 {port} 刷入固件…',
  },
  'log_flash_abort': {
    'EN': 'Requesting abort for flash session {port}…',
    'VI': 'Đang yêu cầu dừng phiên nạp {port}…',
    'CN': '正在请求中止 {port} 的刷机进程…',
  },
  'log_flash_no_devices': {
    'EN': 'No EDL devices ready for flashing.',
    'VI': 'Không có thiết bị EDL nào sẵn sàng nạp.',
    'CN': '没有准备好刷机的 EDL 设备。',
  },
  'log_reboot_start': {
    'EN': 'Launching reboot process for device {port}…',
    'VI': 'Đang khởi chạy tiến trình reboot cho thiết bị {port}…',
    'CN': '正在启动设备 {port} 的重启进程…',
  },
  'log_auto_pipe_start': {
    'EN': 'Launching Auto Fastboot -> ADB -> EDL process for: {serial}',
    'VI': 'Khởi chạy tiến trình Auto Fastboot -> ADB -> EDL cho: {serial}',
    'CN': '启动 Auto Fastboot -> ADB -> EDL 流程: {serial}',
  },
  'log_flash_success_reboot': {
    'EN': 'Device {serial} flash completed and rebooted back to ADB.',
    'VI': 'Thiết bị {serial} đã hoàn tất nạp và boot trở lại ADB.',
    'CN': '设备 {serial} 刷机完成并重启回到 ADB。',
  },
  'log_auto_reboot_edl': {
    'EN': 'Auto-sending reboot to EDL command to ADB: {serial}',
    'VI': 'Tự động gửi lệnh reboot sang EDL tới ADB: {serial}',
    'CN': '自动向 ADB 发送重启到 EDL 命令: {serial}',
  },
  'log_slot_switch': {
    'EN': 'Switched to firmware config Slot {slot}.',
    'VI': 'Đã chuyển sang Slot cấu hình firmware {slot}.',
    'CN': '已切换至固件配置 Slot {slot}。',
  },
  'log_lang_change': {
    'EN': 'Display language changed to: {lang}',
    'VI': 'Thay đổi ngôn ngữ hiển thị thành: {lang}',
    'CN': '显示语言已更改为: {lang}',
  },
  'log_theme_change': {
    'EN': 'Changed color theme.',
    'VI': 'Thay đổi giao diện màu sắc.',
    'CN': '已更改主题颜色。',
  },
  'log_device_flash_done': {
    'EN': 'Device {port} flash: {result}',
    'VI': 'Thiết bị {port} nạp: {result}',
    'CN': '设备 {port} 刷机: {result}',
  },
  'success': {'EN': 'Success', 'VI': 'Thành công', 'CN': '成功'},
  'failed': {'EN': 'Failed', 'VI': 'Thất bại', 'CN': '失败'},

  // QfilEngine validation and flash logs
  'err_fh_loader_missing': {
    'EN': 'fh_loader.exe not found:\n  {path}',
    'VI': 'fh_loader.exe không tìm thấy:\n  {path}',
    'CN': '未找到 fh_loader.exe:\n  {path}',
  },
  'err_fw_file_missing': {
    'EN': 'Missing required firmware file: {file}',
    'VI': 'Thiếu file firmware bắt buộc: {file}',
    'CN': '缺少必要的固件文件: {file}',
  },
  'log_stopping_mtu_service': {
    'EN': '[Sahara] Stopping Qualcomm MTU Service (qcmtusvc)…',
    'VI': '[Sahara] Đang dừng Qualcomm MTU Service (qcmtusvc)…',
    'CN': '[Sahara] 正在停止 Qualcomm MTU 服务 (qcmtusvc)…',
  },
  'log_mtu_service_stopped': {
    'EN': '[Sahara] qcmtusvc stopped — HELLO packet locked successfully',
    'VI': '[Sahara] qcmtusvc đã dừng — Khóa gói tin HELLO thành công',
    'CN': '[Sahara] qcmtusvc 已停止 — 成功锁定 HELLO 数据包',
  },
  'log_mtu_service_stop_fail': {
    'EN': '[Sahara] Could not stop qcmtusvc (Admin rights required)',
    'VI': '[Sahara] Không thể dừng qcmtusvc (Yêu cầu quyền Admin)',
    'CN': '[Sahara] 无法停止 qcmtusvc (需要管理员权限)',
  },
  'err_sahara_upload_fail': {
    'EN': 'Sahara driver upload failed:\n  {msg}',
    'VI': 'Lỗi nạp driver Sahara:\n  {msg}',
    'CN': '上传 Sahara 驱动失败:\n  {msg}',
  },
  'log_sahara_upload_success': {
    'EN': '[Sahara] Driver uploaded successfully: {msg}',
    'VI': '[Sahara] Driver nạp thành công: {msg}',
    'CN': '[Sahara] 驱动上传成功: {msg}',
  },
  'log_wait_firehose': {
    'EN': ' Waiting 2.0s for Firehose port to start…',
    'VI': ' Đợi 2.0s để cổng Firehose khởi động…',
    'CN': ' 等待 2.0 秒以启动 Firehose 端口…',
  },
  'log_phase2_start': {
    'EN': '[PHASE 2] Starting firmware flash → {port}',
    'VI': '[PHASE 2] Bắt đầu nạp firmware → {port}',
    'CN': '[PHASE 2] 开始刷入固件 → {port}',
  },
  'log_phase2_command': {
    'EN':
        '  Running command: fh_loader.exe --port=\\\\.\\{port} --search_path={path}',
    'VI':
        '  Chạy lệnh: fh_loader.exe --port=\\\\.\\{port} --search_path={path}',
    'CN': '  运行命令: fh_loader.exe --port=\\\\.\\{port} --search_path={path}',
  },
  'err_flash_failed': {
    'EN': 'Error during partition flash (fh_loader failed)',
    'VI': 'Lỗi trong quá trình nạp phân vùng (fh_loader failed)',
    'CN': '分区刷入过程中出错 (fh_loader 失败)',
  },
  'log_phase2b_start': {
    'EN': '[PHASE 2b] Activating boot partition (--setactivepartition=0)…',
    'VI': '[PHASE 2b] Kích hoạt phân vùng khởi động (--setactivepartition=0)…',
    'CN': '[PHASE 2b] 激活启动分区 (--setactivepartition=0)…',
  },
  'log_flash_complete': {
    'EN': 'Firmware flash completed successfully!',
    'VI': 'Nạp firmware hoàn tất!',
    'CN': '固件刷入完成！',
  },
  'err_active_slot_fail': {
    'EN': 'Activating boot slot failed.',
    'VI': 'Kích hoạt boot slot thất bại.',
    'CN': '激活启动槽失败。',
  },
  'log_flash_aborted': {
    'EN': 'Firmware flash process was aborted by the user.',
    'VI': 'Quá trình nạp firmware đã bị dừng bởi người dùng.',
    'CN': '固件刷入进程已被用户中止。',
  },

  // RebootWorker paths and status translation keys
  'log_reboot_path_a': {
    'EN': '[Path A] Firehose Reboot: uploading driver…',
    'VI': '[Path A] Khởi động lại Firehose: đang nạp driver…',
    'CN': '[Path A] Firehose 重启: 正在上传驱动…',
  },
  'log_reboot_elf_missing': {
    'EN':
        '[Path A] Programmer driver not found: {path} — switching to Sahara RESET',
    'VI':
        '[Path A] Driver programmer không tìm thấy: {path} — chuyển sang Sahara RESET',
    'CN': '[Path A] 未找到引导程序驱动: {path} — 切换到 Sahara RESET',
  },
  'log_reboot_fh_missing': {
    'EN': '[Path A] fh_loader not found — switching to Sahara RESET',
    'VI': '[Path A] fh_loader không tìm thấy — chuyển sang Sahara RESET',
    'CN': '[Path A] 未找到 fh_loader — 切换到 Sahara RESET',
  },
  'log_reboot_driver_ok': {
    'EN': '[Path A] Driver uploaded successfully — sending reset command…',
    'VI': '[Path A] Nạp driver thành công  — đang gửi lệnh reset…',
    'CN': '[Path A] 驱动上传成功 — 正在发送重置命令…',
  },
  'log_reboot_firehose_success': {
    'EN': ' {port}: Rebooting to Android OS (Firehose Reset).',
    'VI':
        ' {port}: Đang khởi động lại về hệ điều hành Android (Firehose Reset).',
    'CN': ' {port}: 正在重启到 Android 系统 (Firehose 重置)。',
  },
  'log_reboot_fh_error': {
    'EN': '[Path A] Failed to run fh_loader: {err}',
    'VI': '[Path A] Thất bại khi chạy fh_loader: {err}',
    'CN': '[Path A] 运行 fh_loader 失败: {err}',
  },
  'log_reboot_fh_fail_fallback': {
    'EN': '[Path A] fh_loader error — attempting direct Sahara RESET…',
    'VI': '[Path A] fh_loader gặp lỗi — đang thử Sahara RESET trực tiếp…',
    'CN': '[Path A] fh_loader 出错 — 尝试直接进行 Sahara RESET…',
  },
  'log_reboot_path_b': {
    'EN': '[Path B] Sending Sahara RESET…',
    'VI': '[Path B] Gửi lệnh Sahara RESET…',
    'CN': '[Path B] 正在发送 Sahara RESET…',
  },
  'log_reboot_reset_ok': {
    'EN': '[Path B]  RESET command sent successfully',
    'VI': '[Path B]  Gửi lệnh RESET thành công',
    'CN': '[Path B]  成功发送 RESET 命令',
  },
  'log_reboot_reset_fail': {
    'EN': '[Path B] ❌ Failed: {msg}',
    'VI': '[Path B] ❌ Thất bại: {msg}',
    'CN': '[Path B] ❌ 失败: {msg}',
  },
  'log_reboot_both_failed': {
    'EN': '❌ Both reboot methods failed on {port}.\n  Sahara details: {msg}',
    'VI':
        '❌ Cả hai phương pháp khởi động lại đều thất bại trên {port}.\n  Chi tiết Sahara: {msg}',
    'CN': '❌ {port} 上的两种重启方法均失败。\n  Sahara 详情: {msg}',
  },
  'log_reboot_sahara_success': {
    'EN': ' {port}: Rebooting (Sahara RESET).',
    'VI': ' {port}: Đang khởi động lại (Sahara RESET).',
    'CN': ' {port}: 正在重启 (Sahara RESET)。',
  },

  // Sahara reset and errors
  'log_sahara_all_failed': {
    'EN':
        'All strategies failed on {port}.\n  Device is stuck. Run as Admin to stop qcmtusvc.',
    'VI':
        'Mọi biện pháp nạp driver đều thất bại trên {port}.\n  Thiết bị đã bị treo. Chạy quyền Admin để dừng qcmtusvc.',
    'CN': '在 {port} 上所有策略均失败。\n  设备已卡住。请以管理员身份运行以停止 qcmtusvc。',
  },
  'log_sahara_reset_sent': {
    'EN':
        'RESET sent to {port} — device will re-enumerate. Auto-flash will retry.',
    'VI':
        'Đã gửi RESET tới {port} — thiết bị sẽ kết nối lại. Tự động Flash sẽ thử lại.',
    'CN': '已向 {port} 发送 RESET — 设备将重新枚举。自动刷机将重试。',
  },
  'err_select_valid_fw': {
    'EN': 'Please check and select a folder containing valid firmware files.',
    'VI': 'Vui lòng kiểm tra và cung cấp thư mục chứa file firmware hợp lệ.',
    'CN': '请检查并选择包含有效固件文件的文件夹。',
  },
  'err_fh_loader_start': {
    'EN': 'Could not start fh_loader: {err}',
    'VI': 'Không thể khởi động fh_loader: {err}',
    'CN': '无法启动 fh_loader: {err}',
  },

  // Slot path bar & indicators
  'slot_indicator_prefix': {'EN': 'SLOT', 'VI': 'SLOT', 'CN': '插槽'},
  'slot_path_label': {
    'EN': 'Slot {slot} Path:',
    'VI': 'Đường dẫn Slot {slot}:',
    'CN': '插槽 {slot} 路径:',
  },
  'fw_ready': {
    'EN': 'Ready ({fh})',
    'VI': 'Sẵn sàng ({fh})',
    'CN': '就绪 ({fh})',
  },
  'fw_missing_files': {
    'EN': 'Missing',
    'VI': 'Thiếu',
    'CN': '缺少',
  },
  'fw_files_count': {
    'EN': '{xml} XML files',
    'VI': '{xml} file XML',
    'CN': '{xml} 个XML文件',
  },
  'fw_dir_not_exist': {
    'EN': 'Directory does not exist',
    'VI': 'Thư mục không tồn tại',
    'CN': '目录不存在',
  },
  'fw_no_folder_selected': {
    'EN': 'No folder selected',
    'VI': 'Chưa chọn thư mục',
    'CN': '未选择目录',
  },

  // Badges
  'badge_factory': {'EN': 'FACTORY ROM', 'VI': 'FACTORY ROM', 'CN': '原厂固件'},
  'badge_user': {'EN': 'USER ROM', 'VI': 'USER ROM', 'CN': '客户固件'},
  'badge_diag': {'EN': 'DIAG / TEST', 'VI': 'DIAG / TEST', 'CN': '测试固件'},

  // Terminal log monitor
  'terminal_title': {
    'EN': 'TERMINAL LOG MONITOR',
    'VI': 'BẢNG THEO DÕI LOG TERMINAL',
    'CN': '终端日志监控',
  },
  'log_lines_count': {
    'EN': 'LINES',
    'VI': 'DÒNG',
    'CN': '行',
  },

  // Tooltips
  'tooltip_change_lang': {
    'EN': 'Change Language ({lang})',
    'VI': 'Đổi ngôn ngữ ({lang})',
    'CN': '更改语言 ({lang})',
  },
  'tooltip_theme_light': {
    'EN': 'Switch to Light Theme',
    'VI': 'Chuyển sang Giao diện Sáng',
    'CN': '切换至浅色模式',
  },
  'tooltip_theme_dark': {
    'EN': 'Switch to Dark Theme',
    'VI': 'Chuyển sang Giao diện Tối',
    'CN': '切换至深色模式',
  },
  'theme_light': {
    'EN': 'Light Theme',
    'VI': 'Giao diện Sáng',
    'CN': '浅色模式',
  },
  'theme_dark': {
    'EN': 'Dark Theme',
    'VI': 'Giao diện Tối',
    'CN': '深色模式',
  },
  'settings_btn_label': {
    'EN': 'Settings',
    'VI': 'Cài đặt',
    'CN': '设置',
  },
  'tooltip_rename_slot': {
    'EN': 'Rename Slot {slot}',
    'VI': 'Đặt tên cho Slot {slot}',
    'CN': '重命名插槽 {slot}',
  },

  // Slot rename dialog
  'rename_slot_title': {
    'EN': 'Rename Slot {slot}',
    'VI': 'Đặt tên cho Slot {slot}',
    'CN': '重命名插槽 {slot}',
  },
  'rename_slot_subtitle': {
    'EN': 'Customize label or firmware profile for this slot',
    'VI': 'Tùy chỉnh tên gợi nhớ hoặc loại firmware cho slot này',
    'CN': '为此插槽自定义备注或固件配置',
  },
  'rename_slot_name_label': {
    'EN': 'Display Name:',
    'VI': 'Tên hiển thị:',
    'CN': '显示名称:',
  },
  'rename_slot_hint': {
    'EN': 'Enter slot name…',
    'VI': 'Nhập tên cho slot…',
    'CN': '输入插槽名称…',
  },
  'rename_slot_presets_header': {
    'EN': 'Quick Presets (1-Click):',
    'VI': 'Tên mẫu nhanh (1-Click):',
    'CN': '快速预设 (1键):',
  },
  'rename_slot_type_header': {
    'EN': 'Slot Type & Accent Color:',
    'VI': 'Loại Slot & Màu nhận diện:',
    'CN': '插槽类型与识别颜色:',
  },
  'confirm': {
    'EN': 'Confirm',
    'VI': 'Xác nhận',
    'CN': '确认',
  },
  'cancel': {
    'EN': 'Cancel',
    'VI': 'Hủy',
    'CN': '取消',
  },
  'save_slot_name': {
    'EN': 'Save Slot Name',
    'VI': 'Lưu tên Slot',
    'CN': '保存名称',
  },
  'preset_unbrick': {
    'EN': 'Unbrick / Rescue ROM',
    'VI': 'ROM Cứu Hộ / Unbrick',
    'CN': '救砖 / 修复固件',
  },
  'preset_global': {
    'EN': 'Global Official ROM',
    'VI': 'ROM Global Quốc Tế',
    'CN': '全球官方固件',
  },
  'preset_qa_test': {
    'EN': 'Test QA Build',
    'VI': 'Test QA Build',
    'CN': 'QA 测试构建',
  },

  // Device card status and buttons
  'card_flashing': {
    'EN': 'Flashing',
    'VI': 'Đang nạp',
    'CN': '正在刷机',
  },
  'card_completed': {
    'EN': 'Completed',
    'VI': 'Hoàn tất',
    'CN': '完成',
  },
  'card_failed': {
    'EN': 'Failed',
    'VI': 'Thất bại',
    'CN': '失败',
  },
  'card_aborted': {
    'EN': 'Aborted',
    'VI': 'Đã dừng',
    'CN': '已中止',
  },
  'card_rebooting': {
    'EN': 'Rebooting…',
    'VI': 'Đang khởi động…',
    'CN': '正在重启…',
  },
  'card_edl_ready': {
    'EN': 'EDL Ready',
    'VI': 'EDL Sẵn sàng',
    'CN': 'EDL就绪',
  },
  'card_waiting_cmd': {
    'EN': 'Waiting for flash command…',
    'VI': 'Chờ lệnh nạp firmware…',
    'CN': '等待刷机指令…',
  },
  'card_flash_btn': {
    'EN': 'Flash',
    'VI': 'Flash',
    'CN': '刷机',
  },
  'card_abort_btn': {
    'EN': 'Abort',
    'VI': 'Dừng',
    'CN': '中止',
  },
  'card_reboot_adb_btn': {
    'EN': 'Reboot ADB',
    'VI': 'Reboot ADB',
    'CN': '重启到ADB',
  },

  // ADB device card
  'adb_fastboot_ready': {
    'EN': 'Fastboot Ready',
    'VI': 'Fastboot Sẵn sàng',
    'CN': 'Fastboot就绪',
  },
  'adb_connected': {
    'EN': 'Connected',
    'VI': 'Đã kết nối',
    'CN': '已连接',
  },
  'adb_switched_edl': {
    'EN': 'Switched to EDL',
    'VI': 'Đã chuyển EDL',
    'CN': '已转入EDL',
  },
  'adb_boot_to_edl': {
    'EN': 'Boot to EDL (9008)',
    'VI': 'Boot sang EDL (9008)',
    'CN': '启动到EDL (9008)',
  },

  // Logs
  'log_manual_scan': {
    'EN': 'Scanning for connected devices…',
    'VI': 'Đang thực hiện quét thiết bị thủ công…',
    'CN': '正在扫描已连接设备…',
  },
  'log_folder_not_exist': {
    'EN': 'Directory does not exist: {dir}',
    'VI': 'Thư mục không tồn tại để mở: {dir}',
    'CN': '目录不存在无法打开: {dir}',
  },
  'log_slot_renamed': {
    'EN': 'Renamed Slot {slot} to "{name}" [{type}]',
    'VI': 'Đã đổi tên Slot {slot} thành "{name}" [{type}]',
    'CN': '已将插槽 {slot} 重命名为 "{name}" [{type}]',
  },

  // Settings modal
  'settings_title': {
    'EN': 'System Settings',
    'VI': 'Cài đặt hệ thống',
    'CN': '系统设置',
  },
  'settings_tooltip': {
    'EN': 'Settings',
    'VI': 'Cài đặt',
    'CN': '设置',
  },
  'tab_glass': {
    'EN': 'Glass & UI',
    'VI': 'Kính mờ & UI',
    'CN': '毛玻璃与UI',
  },
  'tab_guide': {
    'EN': 'User Guide',
    'VI': 'Hướng dẫn',
    'CN': '使用指南',
  },
  'tab_about': {
    'EN': 'About',
    'VI': 'Thông tin',
    'CN': '关于软件',
  },
  'tab_license': {
    'EN': 'License',
    'VI': 'Bản quyền',
    'CN': '软件授权',
  },
  'settings_glass_header': {
    'EN': 'Glassmorphism & Visual Tuning',
    'VI': 'Tùy chỉnh Kính mờ & Hiệu ứng',
    'CN': '毛玻璃特效微调',
  },
  'settings_default': {
    'EN': 'Default',
    'VI': 'Mặc định',
    'CN': '恢复默认',
  },
  'settings_card_blur': {
    'EN': 'Bento Card Blur',
    'VI': 'Độ mờ thẻ Bento (Card Blur)',
    'CN': '卡片模糊度',
  },
  'settings_card_opacity': {
    'EN': 'Bento Card Opacity',
    'VI': 'Độ đục thẻ Bento (Card Opacity)',
    'CN': '卡片不透明度',
  },
  'settings_dialog_blur': {
    'EN': 'Dialog Blur',
    'VI': 'Độ mờ hộp thoại (Dialog Blur)',
    'CN': '弹窗模糊度',
  },
  'settings_dialog_opacity': {
    'EN': 'Dialog Opacity',
    'VI': 'Độ đục hộp thoại (Dialog Opacity)',
    'CN': '弹窗不透明度',
  },
  'settings_mesh_orbs': {
    'EN': 'Ambient Mesh Orbs',
    'VI': 'Quả cầu phát sáng Mesh Orbs',
    'CN': '环境发光光球',
  },
  'settings_mesh_orbs_sub': {
    'EN': '3 floating luminous ambient light orbs',
    'VI': '3 quả cầu ánh sáng dạ quang trôi nổi trên nền desktop',
    'CN': '背景悬浮3D动态发光球',
  },
  'settings_mesh_opacity': {
    'EN': 'Mesh Orb Luminous Opacity',
    'VI': 'Độ sáng dạ quang Orbs',
    'CN': '光球发光亮度',
  },
  'guide_flash_title': {
    'EN': '1. Qualcomm EDL 9008 Flash Process',
    'VI': '1. Quy trình Nạp Firmware (EDL 9008)',
    'CN': '1. 高通EDL 9008刷机流程',
  },
  'guide_flash_desc': {
    'EN':
        'Dedicated Two-Column Layout: Left column monitors active EDL 9008 flashing with real-time transfer progress and speeds; right column tracks ADB/Fastboot devices. Select one of the 3 firmware slots and click Flash to execute multi-partition reflashing.',
    'VI':
        'Bố cục 2 cột độc lập: Cột trái quản lý các thiết bị EDL 9008 đang nạp kèm tiến độ % và tốc độ chi tiết; cột phải theo dõi thiết bị ADB/Fastboot. Chọn 1 trong 3 Slot ROM tương ứng rồi nhấn nút Flash để nạp phân vùng firmware tự động.',
    'CN':
        '独立双列布局：左列专属监控EDL 9008实时刷机进度与分区速度；右列监控ADB/Fastboot设备。选择3个固件插槽之一并点击刷机以执行完整分区烧录。',
  },
  'guide_autoflash_title': {
    'EN': '2. Intelligent Auto Flash',
    'VI': '2. Tự động Nạp (Auto Flash)',
    'CN': '2. 智能自动刷机',
  },
  'guide_autoflash_desc': {
    'EN':
        'When ON: System detects ADB/Fastboot -> auto reboots to EDL 9008 -> triggers firmware flash -> reboots device to ADB upon completion.',
    'VI':
        'Khi Bật: App tự động phát hiện thiết bị ADB/Fastboot -> tự reboot sang EDL 9008 -> tự động nạp slot đang chọn -> tự khởi động lại sau khi hoàn tất.',
    'CN':
        '开启时：自动检测ADB/Fastboot设备并重启到EDL 9008 -> 自动刷入当前插槽固件 -> 完成后自动重启。',
  },
  'guide_slots_title': {
    'EN': '3. Managing 3 Firmware Slots & Path Marquee',
    'VI': '3. Quản lý 3 Firmware Slots & Cuộn Đường Dẫn',
    'CN': '3. 管理3个固件插槽与路径跑马灯',
  },
  'guide_slots_desc': {
    'EN':
        'Features 3 smart slots (Factory Stock, User Custom, Diag Test) with an animated rotating comet glow border on selection. The path input uses an asymmetric bounce marquee to smoothly view long directory paths, instantly switching to an editable textfield on click. Double-click any card to rename.',
    'VI':
        'Bộ 3 slot ROM thông minh (Factory, User, Diag) với viền sáng sao băng xoay quanh lựa chọn. Ô đường dẫn tự động cuộn bật nảy mượt mà xem trọn đường dẫn dài và chuyển sang ô nhập khi nhấp chuột. Nhấp đúp chuột vào thẻ để đổi tên.',
    'CN':
        '提供3个智能固件插槽（原厂、定制、测试），选中卡片带有动态彗星流光外框。路径框配备非对称回弹跑马灯可平滑查看超长目录，点击即可编辑。双击卡片可重命名。',
  },
  'guide_trouble_title': {
    'EN': '4. Shortcuts & Diagnostics',
    'VI': '4. Phím tắt & Mẹo Xử lý',
    'CN': '4. 快捷键与排障技巧',
  },
  'guide_trouble_desc': {
    'EN':
        'Click Scan Now to refresh COM ports. If device gets stuck in Fastboot, use "Boot to EDL". The Terminal log monitor allows 1-click clipboard copying.',
    'VI':
        'Nhấn Quét ngay (Scan) để quét lại cổng COM. Nếu thiết bị kẹt ở Fastboot, dùng nút "Boot sang EDL". Bảng Terminal cho phép sao chép log nhanh chỉ bằng 1 cú nhấp chuột.',
    'CN':
        '点击立即扫描刷新COM端口。若设备卡在Fastboot，使用“启动到EDL”。终端监控支持一键复制日志。',
  },
  'about_app_name': {
    'EN': 'JA IQ5 REFLASH TOOL',
    'VI': 'JA IQ5 REFLASH TOOL',
    'CN': 'JA IQ5 快速刷机工具',
  },
  'about_app_desc': {
    'EN':
        'Professional multi-device Qualcomm IQ5 firmware flashing and recovery tool with two-column EDL & ADB layout, 3-slot ROM selector, rotating glow effects, bounce marquee path, and hardware tier profiling.\n\nOfficial Website: https://jatechvn.github.io/',
    'VI':
        'Công cụ nạp firmware cứu hộ đa thiết bị Qualcomm Snapdragon QDLoader 9008 với bố cục 2 cột độc lập, 3 slot ROM viền sáng xoay quanh, thanh path cuộn bật nảy và nhận diện cấu hình phần cứng.\n\nTrang chủ chính thức: https://jatechvn.github.io/',
    'CN':
        '专为高通骁龙QDLoader 9008设备打造的多端口固件刷机与救砖工具，配备独立双列监控布局、3插槽彗星流光卡片、回弹跑马灯路径框及硬件分级性能自适应体系。\n\n官方网站: https://jatechvn.github.io/',
  },
  'about_sys_title': {
    'EN': 'System & Runtime Specifications',
    'VI': 'Thông số Hệ Thống & Runtime',
    'CN': '系统与运行时规格',
  },
  'about_dev_title': {
    'EN': 'Developer & Architecture',
    'VI': 'Đơn vị Phát triển & Bản quyền',
    'CN': '开发团队与架构规范',
  },
  'about_os_label': {
    'EN': 'Operating System',
    'VI': 'Hệ điều hành / OS',
    'CN': '操作系统',
  },
  'about_cpu_label': {
    'EN': 'CPU Processors',
    'VI': 'Số nhân CPU',
    'CN': 'CPU核心数',
  },
  'about_score_label': {
    'EN': 'Hardware Score',
    'VI': 'Điểm phần cứng',
    'CN': '硬件综合评分',
  },
  'about_author': {
    'EN': 'John Alaa / JA Tech',
    'VI': 'John Alaa / JA Tech',
    'CN': 'John Alaa / JA Tech',
  },
  'about_blueprint': {
    'EN': 'flutter-app-blueprint v1.2',
    'VI': 'flutter-app-blueprint v1.2',
    'CN': 'flutter-app-blueprint v1.2',
  },
  'lic_tab_title': {
    'EN': 'Software License & Activation',
    'VI': 'Quản lý Bản quyền Phần mềm',
    'CN': '软件授权与激活',
  },
  'lic_status_label': {
    'EN': 'License Status:',
    'VI': 'Trạng thái bản quyền:',
    'CN': '授权状态:',
  },
  'lic_days_left': {
    'EN': '{days} days remaining',
    'VI': '{days} ngày còn lại',
    'CN': '剩余 {days} 天',
  },
  'lic_copy_hwid_btn': {
    'EN': 'Copy HWID',
    'VI': 'Sao chép HWID',
    'CN': '复制机器码',
  },
  'lic_sync_lan_btn': {
    'EN': 'Sync from LAN Server',
    'VI': 'Đồng bộ từ máy chủ LAN',
    'CN': '从局域网服务器同步',
  },
  'lic_manual_activate_header': {
    'EN': 'Activate with License Key:',
    'VI': 'Kích hoạt bằng Mã Bản Quyền:',
    'CN': '通过授权密钥激活:',
  },
  'lic_paste_btn': {
    'EN': 'Paste',
    'VI': 'Dán',
    'CN': '粘贴',
  },
  'lic_activate_now_btn': {
    'EN': 'Activate Now',
    'VI': 'Kích hoạt ngay',
    'CN': '立即激活',
  },
  'lic_key_input_hint': {
    'EN': 'Enter or paste license key here…',
    'VI': 'Nhập hoặc dán mã license key vào đây…',
    'CN': '在此输入或粘贴授权密钥…',
  },
  'action_close': {
    'EN': 'Close',
    'VI': 'Đóng',
    'CN': '关闭',
  },
  'action_save_settings': {
    'EN': 'Save Settings',
    'VI': 'Lưu cài đặt',
    'CN': '保存设置',
  },
  'log_settings_saved': {
    'EN': 'Glassmorphism settings saved to config.ini',
    'VI': 'Đã lưu cấu hình cài đặt giao diện kính mờ',
    'CN': '毛玻璃界面设置已保存至config.ini',
  },
  'terminal_toggle_tooltip': {
    'EN': 'Toggle Terminal Size (Compact / Expanded / Minimized)',
    'VI': 'Chuyển kích thước Terminal (Thu nhỏ / Tiêu chuẩn / Mở rộng)',
    'CN': '切换终端尺寸 (最小化 / 标准 / 展开)',
  },
  'terminal_height_collapsed': {
    'EN': 'Minimized',
    'VI': 'Thu nhỏ',
    'CN': '已折叠',
  },
  'terminal_height_compact': {
    'EN': 'Compact',
    'VI': 'Tiêu chuẩn',
    'CN': '标准',
  },
  'terminal_height_expanded': {
    'EN': 'Expanded',
    'VI': 'Mở rộng',
    'CN': '已展开',
  },

  // Hardware & Performance Tier Profiling
  'perf_tooltip': {
    'EN': 'Hardware Graphic Profile (Auto / Ultra / Balanced / Lite)',
    'VI': 'Chế độ Đồ họa & Cấu hình Máy (Auto / Ultra / Balanced / Lite)',
    'CN': '硬件与图形配置档位 (自动 / 极速 / 均衡 / 低功耗)',
  },
  'perf_tier_header': {
    'EN': 'Hardware Auto-Detection & Graphic Performance',
    'VI': 'Tự động Nhận diện Cấu hình & Hiệu năng Đồ họa',
    'CN': '硬件自动识别与图形性能档位',
  },
  'perf_tier_sub': {
    'EN': 'System dynamically detects hardware specs and optimizes glass rendering',
    'VI': 'Hệ thống tự động phát hiện phần cứng và tối ưu hóa bộ render kính mờ',
    'CN': '系统动态检测硬件规格并针对性优化毛玻璃渲染',
  },
  'perf_mode_label': {
    'EN': 'Profile Mode:',
    'VI': 'Chế độ cấu hình:',
    'CN': '配置模式:',
  },
  'perf_auto': {
    'EN': 'Auto',
    'VI': 'Tự động',
    'CN': '自动',
  },
  'perf_ultra': {
    'EN': 'Ultra',
    'VI': 'Ultra',
    'CN': '极速',
  },
  'perf_balanced': {
    'EN': 'Balanced',
    'VI': 'Cân bằng',
    'CN': '均衡',
  },
  'perf_lite': {
    'EN': 'Lite',
    'VI': 'Tiết kiệm',
    'CN': '轻量',
  },
  'perf_detected_label': {
    'EN': 'Detected Hardware:',
    'VI': 'Cấu hình phát hiện:',
    'CN': '检测到硬件:',
  },
  'perf_score_label': {
    'EN': 'Hardware Score:',
    'VI': 'Điểm phần cứng:',
    'CN': '硬件评分:',
  },
  'perf_cores_label': {
    'EN': 'CPU Cores:',
    'VI': 'Số nhân CPU:',
    'CN': 'CPU核心:',
  },
  'perf_desc_auto': {
    'EN': 'Auto: Continuously optimizes graphics pipeline to match your computer specs for maximum responsiveness.',
    'VI': 'Tự động: Tự động phân tích cấu hình máy và điều chỉnh bộ xử lý đồ họa để app luôn mượt mà nhất.',
    'CN': '自动: 持续分析系统性能并动态调整渲染管线，确保界面始终丝滑顺畅。',
  },
  'perf_desc_ultra': {
    'EN': 'Ultra: 120 FPS high-end profile with full 20px blur and floating glowing particles.',
    'VI': 'Ultra: Cấu hình cao cấp 120 FPS với độ mờ kính 20px đầy đủ và hiệu ứng hạt phát sáng.',
    'CN': '极速: 120 FPS顶级配置，提供完整20px毛玻璃虚化与漂浮发光粒子效果。',
  },
  'perf_desc_balanced': {
    'EN': 'Balanced: 60 FPS smooth glassmorphism with optimized 14px blur for laptops and office PCs.',
    'VI': 'Cân bằng: Hiệu ứng kính mờ 60 FPS mượt mà với độ mờ 14px tối ưu cho laptop và máy văn phòng.',
    'CN': '均衡: 60 FPS流畅毛玻璃，优化14px虚化深度，专为现代笔记本与办公电脑设计。',
  },
  'perf_desc_lite': {
    'EN': 'Lite: High-speed acrylic interface with zero blur overhead for older laptops, low-spec CPUs, or VMs.',
    'VI': 'Tiết kiệm: Giao diện Acrylic siêu nhẹ loại bỏ hoàn toàn độ trễ cho laptop cũ, CPU yếu hoặc máy ảo.',
    'CN': '轻量: 极速亚克力界面，无虚化开销，适用于老旧电脑、低配CPU或虚拟机。',
  },
};
