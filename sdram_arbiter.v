module sdram_arbiter #(
    parameter R_FIFO_DEPTH = 1024,
    parameter BURST_LENGTH = 256
)(
    input wire clk,
    input wire rst_n,
    
    // ?????ng b??? khung h??nh
    input wire vga_vsync,
    
    // Giao ti???p W-FIFO
    input wire w_fifo_empty,
    input wire [15:0] w_fifo_data,
    output reg w_fifo_rd_en,
    
    // Giao ti???p R-FIFO
    input wire [10:0] r_fifo_count,
    output reg [15:0] r_fifo_data,
    output reg r_fifo_wr_en,
    output reg r_fifo_clear,
    
    // Giao ti???p SDRAM Controller
    input wire sys_ready,
    input wire sys_valid, // C??? d??? li???u Burst
    output reg sys_write_req,
    output reg sys_read_req,
    output reg [21:0] sys_addr,
    output reg [15:0] sys_data_in,
    input wire [15:0] sys_data_out
);

    localparam IDLE           = 3'd0;
    localparam ASSERT_READ    = 3'd1;
    localparam WAIT_READ      = 3'd2;
    localparam FETCH_W_FIFO_1 = 3'd3;
    localparam FETCH_W_FIFO_2 = 3'd4;
    localparam ASSERT_WRITE   = 3'd5;
    localparam WAIT_WRITE     = 3'd6;

    reg [2:0] state;
    
    reg [21:0] write_addr;
    reg [21:0] read_addr;
    
    reg vsync_d1, vsync_d2;
    wire vsync_falling = (vsync_d2 && !vsync_d1);
    reg vsync_req; // C??? l??u tr???ng th??i y??u c???u V-Sync
    
    reg [23:0] write_timeout_cnt; // T??? ?????ng reset write_addr n???u r???nh r???i 100ms
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            write_addr <= 22'd0;
            read_addr <= 22'd0;
            w_fifo_rd_en <= 0;
            r_fifo_wr_en <= 0;
            r_fifo_clear <= 0;
            sys_write_req <= 0;
            sys_read_req <= 0;
            sys_addr <= 0;
            sys_data_in <= 0;
            r_fifo_data <= 0;
            vsync_d1 <= 0;
            vsync_d2 <= 0;
            vsync_req <= 0;
            write_timeout_cnt <= 24'd0;
        end else begin
            vsync_d1 <= vga_vsync;
            vsync_d2 <= vsync_d1;
            
            // Ch??? b???t t??n hi???u V-Sync v?? gi????ng c???
            if (vsync_falling) begin
                vsync_req <= 1'b1;
            end
            
            // T??? ?????ng ?????ng b??? write_addr n???u UART kh??ng c?? d??? li???u h??n 100ms
            if (w_fifo_empty) begin
                if (write_timeout_cnt < 24'd5_000_000) begin
                    write_timeout_cnt <= write_timeout_cnt + 1'b1;
                end else if (state == IDLE) begin
                    write_addr <= 22'd0;
                end
            end else begin
                write_timeout_cnt <= 24'd0;
            end
            
            w_fifo_rd_en <= 0;
            r_fifo_wr_en <= 0;
            r_fifo_clear <= 0;
            
            // Streaming tr???c ti???p t??? SDRAM v??o R-FIFO m???i khi c?? data
            if (sys_valid) begin
                r_fifo_wr_en <= 1;
                r_fifo_data <= sys_data_out;
                read_addr <= read_addr + 1'b1;
            end
            
            case (state)
                IDLE: begin
                    sys_write_req <= 0;
                    sys_read_req <= 0;
                    
                    // Reset read_addr v?? X??? S???CH R-FIFO an to??n khi VSync t???i
                    if (vsync_req) begin
                        read_addr <= 22'd0;
                        r_fifo_clear <= 1'b1; // X??? s???ch d??? li???u th???a ngo??i l??? khung h??nh
                        vsync_req <= 1'b0;
                    end
                    else if (sys_ready) begin
                        // T??nh to??n ????? tr???ng c???a R-FIFO (1024 - 256 = 768)
                        if (r_fifo_count <= (R_FIFO_DEPTH - BURST_LENGTH)) begin
                            sys_addr <= read_addr;
                            sys_read_req <= 1;
                            state <= ASSERT_READ;
                        end
                        else if (!w_fifo_empty) begin
                            w_fifo_rd_en <= 1; // R?t data kh?i W-FIFO
                            state <= FETCH_W_FIFO_1;
                        end
                    end
                end
                
                ASSERT_READ: begin
                    sys_read_req <= 1;
                    if (sys_ready == 1'b0) begin // Ch? SDRAM controller acknowledge
                        sys_read_req <= 0;
                        state <= WAIT_READ;
                    end
                end
                
                WAIT_READ: begin
                    sys_read_req <= 0;
                    if (sys_ready == 1'b1) begin // SDRAM controller t? ng?t sau khi Burst xong
                        state <= IDLE;
                    end
                end
                
                FETCH_W_FIFO_1: begin
                    state <= FETCH_W_FIFO_2; // Ch? latency 1 nh?p c?a Standard FIFO
                end
                
                FETCH_W_FIFO_2: begin
                    sys_addr <= write_addr;
                    sys_data_in <= w_fifo_data; // Data ?? s?n s?ng
                    sys_write_req <= 1;
                    state <= ASSERT_WRITE;
                end
                
                ASSERT_WRITE: begin
                    sys_write_req <= 1;
                    if (sys_ready == 1'b0) begin
                        sys_write_req <= 0;
                        state <= WAIT_WRITE;
                    end
                end
                
                WAIT_WRITE: begin
                    if (sys_ready == 1'b1) begin
                        if (write_addr == 22'd307199) begin
                            write_addr <= 22'd0;
                        end else begin
                            write_addr <= write_addr + 1'b1;
                        end
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
