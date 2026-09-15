import serial
import serial.tools.list_ports
import time
import sys
import os

# ==============================================================================
# CAU HINH CHUAN XAC CHO BO MACH DE1 CLASSIC (RS-232 DB9)
# ==============================================================================
BAUD_RATE = 115200       # Chuan 115200 baud - on dinh 100% qua chip RS-232 tren DE1
script_dir = os.path.dirname(os.path.abspath(__file__))
RAW_FILE  = os.path.join(script_dir, 'tree_sunset_640x480.bin')

def find_com_port():
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        return None
    if len(ports) == 1:
        return ports[0].device
    for p in ports:
        desc = p.description.upper()
        if any(k in desc for k in ['USB', 'UART', 'SERIAL', 'CP210', 'CH340', 'FTDI', 'PROLIFIC']):
            return p.device
    return ports[0].device

def main():
    if not os.path.exists(RAW_FILE):
        print(f"[!] Error: File raw khong ton tai: {RAW_FILE}")
        return

    with open(RAW_FILE, 'rb') as f:
        data_bytes = f.read()

    total_bytes = len(data_bytes)
    print("=" * 60)
    print("   FPGA DE1 IMAGE STREAMER - TRUYEN DU LIEU THO (RAW RGB565)")
    print("=" * 60)
    print(f"[+] Kich thuoc du lieu tho: {total_bytes} bytes (dung 320x240 @ 16-bit RGB565)")
    print(f"[+] Baudrate: {BAUD_RATE} (8 Data bits, No Parity, 1 Stop bit - 8N1)")

    port = find_com_port()
    if not port:
        print("[!] Khong tim thay cong COM nao duoc ket noi!")
        port = input("[?] Nhap ten cong COM bang tay (vi du: COM3): ").strip()
        if not port:
            return
    else:
        print(f"[+] Tu dong nhan dien cong COM: {port}")

    try:
        print(f"[+] Dang ket noi toi {port} voi toc do {BAUD_RATE}...")
        ser = serial.Serial(
            port=port,
            baudrate=BAUD_RATE,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=2
        )
        time.sleep(1) # Cho on dinh ket noi vat ly

        print("[+] Bat dau ban du lieu tho xuong SRAM cua FPGA...")
        start_time = time.time()

        # Truyen theo block 1024 bytes
        chunk_size = 1024
        for i in range(0, total_bytes, chunk_size):
            chunk = data_bytes[i:i+chunk_size]
            ser.write(chunk)
            sent = min(i + chunk_size, total_bytes)
            progress = (sent / total_bytes) * 100
            print(f"\r    Tien trinh: {progress:5.1f}% [{sent}/{total_bytes} bytes]", end="")
            sys.stdout.flush()

        print()
        elapsed = time.time() - start_time
        speed_kb = (total_bytes / 1024) / elapsed if elapsed > 0 else 0
        print(f"[V] HOAN TAT! Thoi gian truyen: {elapsed:.2f}s (Toc do: {speed_kb:.1f} KB/s)")
        print("[V] Kiem tra man hinh VGA cua ngai ngay lap tuc!")
        ser.close()

    except Exception as e:
        print(f"\n[X] Loi Serial: {e}")
        print("    Goi y: Kiem tra xem co phan mem nao khac (nhu PuTTY, Arduino IDE) dang chiem cong COM khong.")

if __name__ == '__main__':
    try:
        main()
    finally:
        input("\n[!] Nhan Enter de thoat...")
