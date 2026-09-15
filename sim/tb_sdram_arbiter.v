`timescale 1ns/1ps

module tb_sdram_arbiter();

    reg clk;
    reg rst_n;
    reg vga_vsync;
    
    reg w_fifo_empty;
    reg [15:0] w_fifo_data;
    wire w_fifo_rd_en;
    
    reg [9:0] r_fifo_count;
    wire [15:0] r_fifo_data;
    wire r_fifo_wr_en;
    
    reg sys_ready;
    reg sys_valid;
    wire sys_write_req;
    wire sys_read_req;
    wire [21:0] sys_addr;
    wire [15:0] sys_data_in;
    reg [15:0] sys_data_out;

    sdram_arbiter #(
        .R_FIFO_DEPTH(512),
        .BURST_LENGTH(256)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .vga_vsync(vga_vsync),
        .w_fifo_empty(w_fifo_empty),
        .w_fifo_data(w_fifo_data),
        .w_fifo_rd_en(w_fifo_rd_en),
        .r_fifo_count(r_fifo_count),
        .r_fifo_data(r_fifo_data),
        .r_fifo_wr_en(r_fifo_wr_en),
        .sys_ready(sys_ready),
        .sys_valid(sys_valid),
        .sys_write_req(sys_write_req),
        .sys_read_req(sys_read_req),
        .sys_addr(sys_addr),
        .sys_data_in(sys_data_in),
        .sys_data_out(sys_data_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        vga_vsync = 0;
        w_fifo_empty = 1;
        w_fifo_data = 0;
        r_fifo_count = 512; // full initially to prevent immediate read
        sys_ready = 1;
        sys_valid = 0;
        sys_data_out = 0;
        
        #20;
        rst_n = 1;
        
        // Test Write request
        #20;
        w_fifo_empty = 0;
        w_fifo_data = 16'hABCD;
        
        // Wait for w_fifo_rd_en
        @(posedge w_fifo_rd_en);
        #10;
        w_fifo_data = 16'h1234; // next data
        w_fifo_empty = 1;
        
        // Handle SDRAM write
        @(posedge sys_write_req);
        #10;
        sys_ready = 0;
        #30;
        sys_ready = 1; // write done
        
        // Test Read Request
        #50;
        r_fifo_count = 100; // less than 256
        
        @(posedge sys_read_req);
        #10;
        sys_ready = 0;
        
        // Burst data
        #20;
        sys_valid = 1;
        sys_data_out = 16'hDEAD;
        #10;
        sys_valid = 1;
        sys_data_out = 16'hBEEF;
        #10;
        sys_valid = 0;
        
        #20;
        sys_ready = 1; // read done
        
        // Test VSYNC
        #50;
        vga_vsync = 1;
        #30;
        vga_vsync = 0; // falling edge
        
        #100;
        $finish;
    end
endmodule
