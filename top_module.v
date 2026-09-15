module top_module (
    input wire CLOCK_50,
    input wire [0:0] KEY, // KEY[0] d??ng l??m n??t reset
    
    // UART
    input wire UART_RXD,
    
    // VGA (Giao ti???p DE1 c??: 12-bit RGB 4-4-4)
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    
    // SDRAM
    output wire [11:0] DRAM_ADDR,
    output wire DRAM_BA_0,
    output wire DRAM_BA_1,
    output wire DRAM_CAS_N,
    output wire DRAM_CKE,
    output wire DRAM_CLK,
    output wire DRAM_CS_N,
    inout  wire [15:0] DRAM_DQ,
    output wire DRAM_LDQM,
    output wire DRAM_UDQM,
    output wire DRAM_RAS_N,
    output wire DRAM_WE_N
);

    wire rst_n = KEY[0];
    
    // Clock cho DRAM l???ch pha so v???i h??? th???ng ????? ?????m b???o setup/hold time
    assign DRAM_CLK = ~CLOCK_50; 
    assign DRAM_CKE = 1'b1;
    assign DRAM_LDQM = 1'b0;
    assign DRAM_UDQM = 1'b0;
    
    // ==========================================
    // KHAI B??O C??C WIRE LI??N K???T
    // ==========================================
    wire [7:0] uart_data;
    wire uart_ready;
    
    // Logic gh??p 2 byte UART th??nh 1 Pixel 16-bit
    reg [7:0] temp_byte;
    reg byte_flag;
    reg [15:0] packed_pixel;
    reg pixel_valid;
    reg [21:0] byte_timeout;

    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            byte_flag <= 1'b0;
            pixel_valid <= 1'b0;
            temp_byte <= 8'h00;
            packed_pixel <= 16'h0000;
            byte_timeout <= 22'd0;
        end else begin
            pixel_valid <= 1'b0; 
            if (uart_ready) begin
                byte_timeout <= 22'd0;
                if (byte_flag == 1'b0) begin
                    temp_byte <= uart_data; // Byte th???p
                    byte_flag <= 1'b1;
                end else begin
                    packed_pixel <= {uart_data, temp_byte}; // Gh??p {Byte cao, Byte th???p}
                    byte_flag <= 1'b0;
                    pixel_valid <= 1'b1; // B???n c??? ghi v??o FIFO
                end
            end else if (byte_flag) begin
                // N???u ch??? byte 2 qu?? 50ms (m???t sync), t??? ?????ng reset byte_flag
                if (byte_timeout < 22'd2_500_000) begin
                    byte_timeout <= byte_timeout + 1'b1;
                end else begin
                    byte_flag <= 1'b0;
                end
            end
        end
    end
    
    // W-FIFO (Write FIFO)
    wire [15:0] w_fifo_in_data = packed_pixel;
    wire w_fifo_empty;
    wire w_fifo_full;
    wire [15:0] w_fifo_out_data;
    wire w_fifo_rd_en;
    
    // R-FIFO (Read FIFO)
    wire r_fifo_empty;
    wire r_fifo_full;
    wire [15:0] r_fifo_in_data;
    wire r_fifo_wr_en;
    wire [15:0] r_fifo_out_data;
    wire r_fifo_rd_en;
    
    // ARBITER <-> SDRAM CONTROLLER
    wire sys_ready;
    wire sys_valid;
    wire sys_write_req;
    wire sys_read_req;
    wire [21:0] sys_addr;
    wire [15:0] sys_data_in;
    wire [15:0] sys_data_out;

    // VGA
    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    
    // ==========================================
    // INSTANTIATE C??C MODULE
    // ==========================================
    
    uart_rx uart_rx_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .rx_pin(UART_RXD),
        .rx_data(uart_data),
        .rx_done(uart_ready)
    );
    
    // B???n th??? 1: W-FIFO (S??u 32)
    fifo_sync #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(5)
    ) w_fifo_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .clear(1'b0),
        .wr_en(pixel_valid), // Ghi khi gh??p ????? 1 pixel
        .wr_data(w_fifo_in_data),
        .rd_en(w_fifo_rd_en),
        .rd_data(w_fifo_out_data),
        .empty(w_fifo_empty),
        .full(w_fifo_full),
        .count()
    );
    
    wire [10:0] r_fifo_count;
    wire r_fifo_clear;
    // B???n th??? 2: R-FIFO (S??u 1024 - Ch???a tr???n v???n h??n 1 d??ng qu??t 640 pixel v?? 2 ?????t Burst)
    fifo_sync #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(10)
    ) r_fifo_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .clear(r_fifo_clear), // X??? s???ch d??? li???u th???a t???i V-Sync
        .wr_en(r_fifo_wr_en),
        .wr_data(r_fifo_in_data),
        .rd_en(r_fifo_rd_en),
        .rd_data(r_fifo_out_data),
        .empty(r_fifo_empty),
        .full(r_fifo_full),
        .count(r_fifo_count)
    );
    
    sdram_arbiter arbiter_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .vga_vsync(VGA_VS),
        .w_fifo_empty(w_fifo_empty),
        .w_fifo_data(w_fifo_out_data),
        .w_fifo_rd_en(w_fifo_rd_en),
        .r_fifo_count(r_fifo_count),
        .r_fifo_data(r_fifo_in_data),
        .r_fifo_wr_en(r_fifo_wr_en),
        .r_fifo_clear(r_fifo_clear),
        
        .sys_ready(sys_ready),
        .sys_valid(sys_valid),
        .sys_write_req(sys_write_req),
        .sys_read_req(sys_read_req),
        .sys_addr(sys_addr),
        .sys_data_in(sys_data_in),
        .sys_data_out(sys_data_out)
    );
    
    sdram_controller sdram_ctrl_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .sys_valid(sys_valid),
        
        .write_req(sys_write_req),
        .read_req(sys_read_req),
        .sys_addr(sys_addr),
        .sys_data_in(sys_data_in),
        .sys_data_out(sys_data_out),
        .sys_ready(sys_ready),
        
        .sdram_addr(DRAM_ADDR),
        .sdram_ba({DRAM_BA_1, DRAM_BA_0}),
        .sdram_cs_n(DRAM_CS_N),
        .sdram_ras_n(DRAM_RAS_N),
        .sdram_cas_n(DRAM_CAS_N),
        .sdram_we_n(DRAM_WE_N),
        .sdram_dq(DRAM_DQ)
    );
    
    reg ce;
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) ce <= 1'b0;
        else ce <= ~ce;
    end
    
    vga_sync vga_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .ce(ce),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );
    
    // Logic ?????y d??? li???u t??? R-FIFO ra m??n h??nh 
    // Ch??? ?????c R-FIFO khi m??n h??nh c???n pixel (video_on) V?? ????ng nh???p 25MHz (ce)
    assign r_fifo_rd_en = video_on && !r_fifo_empty && ce;
    
    // Hi???n th??? ???nh. N???u h???t d??? li???u do ????i b??ng th??ng (starvation), ??i???m ???nh t??? ?????ng th??nh ??en.
    wire [15:0] pixel_data = (video_on && !r_fifo_empty) ? r_fifo_out_data : 16'h0000;
    
    // ?????m thanh ghi ?????u ra cho VGA DAC (Register Output) ????? tri???t ti??u to??n b??? s???c nhi???u
    reg [3:0] vga_r_reg, vga_g_reg, vga_b_reg;
    always @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            vga_r_reg <= 4'h0;
            vga_g_reg <= 4'h0;
            vga_b_reg <= 4'h0;
        end else begin
            vga_r_reg <= pixel_data[15:12];
            vga_g_reg <= pixel_data[10:7];
            vga_b_reg <= pixel_data[4:1];
        end
    end

    assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;

endmodule
