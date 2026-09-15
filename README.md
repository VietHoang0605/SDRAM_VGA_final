# 🖥️ Terasic DE1: SDRAM VGA Video Framebuffer

> **Dự án Kỹ thuật số Nâng cao trên FPGA (Altera Cyclone II)**
> 
> Truyền hình ảnh (Streaming) độ phân giải 640x480 qua giao tiếp UART, lưu trữ vào SDRAM và xuất tín hiệu hiển thị lên màn hình VGA @ 60Hz.

**🔗 [XEM TRỰC TIẾP BÁO CÁO KỸ THUẬT & TRÌNH GIẢ LẬP ONLINE TẠI ĐÂY](https://de1-sdram-vga-imagine.netlify.app/) 🔗**

---

## 🎯 Tóm tắt Dự án

Dự án này là một bài toán kinh điển nhưng cực kỳ thách thức trong thiết kế phần cứng: Giải quyết bài toán **bất đồng bộ về tốc độ (Clock Domain Crossing)** giữa ba khối giao tiếp phần cứng hoàn toàn độc lập:

1. **Khối nhận dữ liệu (UART RX):** Nhận luồng dữ liệu hình ảnh (pixels) từ máy tính thông qua cáp RS-232 với tốc độ chậm (Baudrate 115,200).
2. **Khối lưu trữ trung tâm (SDRAM):** Đóng vai trò làm *Video Framebuffer*. Đây là nút thắt khó nhất của dự án khi phải tự thiết kế một **SDRAM Controller** hoàn chỉnh để quản lý các trạng thái vật lý phức tạp (Auto-Refresh, Row/Col Active, CAS Latency) và đọc/ghi dữ liệu ở chế độ *Burst Mode*.
3. **Khối hiển thị (VGA Controller):** Quét tín hiệu liên tục ra màn hình với tốc độ Pixel Clock lên tới 25.175 MHz để đảm bảo chuẩn hiển thị 640x480 @ 60Hz.

Hệ thống vận hành trơn tru nhờ vào cơ chế điều phối của **SDRAM Arbiter** và các bộ đệm **Asynchronous FIFO (Dual-Clock)** để đồng bộ hóa luồng dữ liệu chảy giữa các miền xung nhịp (Clock Domains) khác biệt, đảm bảo không một pixel nào bị thất thoát.

## 🛠️ Luồng Dữ liệu (Dataflow Pipeline)

1. **Máy tính (Python)** $\rightarrow$ Gửi ảnh $\rightarrow$ **UART RX (FPGA)**
2. **UART RX** $\rightarrow$ Ghép Pixel (16-bit) $\rightarrow$ **Write FIFO**
3. **SDRAM Arbiter** $\rightarrow$ Lấy từ Write FIFO $\rightarrow$ Ghi vào **SDRAM (Burst Write)**
4. **SDRAM Arbiter** $\rightarrow$ Đọc từ **SDRAM (Burst Read)** $\rightarrow$ Đẩy vào **Read FIFO**
5. **VGA Controller** $\rightarrow$ Rút Pixel từ **Read FIFO** $\rightarrow$ Trình chiếu lên **Màn hình**

*(Sơ đồ khối cấu trúc chi tiết, phân tích độ trễ và Nhật ký gỡ lỗi được trình bày trực quan tại [Trang Báo Cáo Online](https://de1-sdram-vga-imagine.netlify.app/)).*

## 🚀 Hướng dẫn sử dụng nhanh

1. Tổng hợp và nạp file `project_2_SDRAM_VGA.sof` vào Kit Terasic DE1.
2. Kết nối cáp UART (RS-232) và cáp VGA từ Kit lên màn hình.
3. Chạy script truyền ảnh bằng Python trên máy tính:
   ```bash
   python send_image_uart.py COM3 tree_sunset_640x480.bin
   ```
   *(Thay `COM3` bằng cổng thực tế trên máy tính)*
4. Màn hình VGA sẽ hiển thị từng dải màu được nạp trực tiếp qua SDRAM cho tới khi bức ảnh hiển thị hoàn chỉnh rực rỡ!

---
**🧑‍💻 Tác giả:** VietHoang0605  
**🏫 Nền tảng phần cứng:** Board FPGA Terasic DE1 (Altera Cyclone II)
