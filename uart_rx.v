/*
================================================================================
-- Module Name: uart_rx
-- Description:
-- Bo thu UART tieu chuan 8N1 (1 Start bit, 8 Data bits, 1 Stop bit, No Parity).
-- Tich hop bo loc nhieu Majority Voting (3 mau 7, 8, 9 tren he so chia 16x).
-- Tuong thich hoan hao 100% voi moi cong COM PC va cable RS-232.
================================================================================
*/
module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUDRATE = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire rx_pin,        // Tin hieu RX tu chan vat ly
    output reg [7:0] rx_data, // Du lieu 8-bit nhan duoc
    output reg rx_done,       // Xung bao hoan thanh nhan 1 byte (1 clock)
    output wire parity_err    // Luon bang 0 (8N1 khong dung Parity)
);

    assign parity_err = 1'b0;

    // He so chia mau 16x
    localparam OVERSAMPLE_RATE = BAUDRATE * 16;
    localparam BAUD_LIMIT = (CLK_FREQ / OVERSAMPLE_RATE) - 1;

    // 4 trang thai chuan 8N1
    localparam IDLE      = 2'd0;
    localparam START_BIT = 2'd1;
    localparam DATA_BITS = 2'd2;
    localparam STOP_BIT  = 2'd3;

    reg [1:0]  state;
    reg [31:0] baud_counter;
    reg [3:0]  sample_tick;
    reg [2:0]  bit_index;
    reg [7:0]  data_reg;

    // Dong bo hoa tin hieu rx_pin de tranh Metastability
    reg rx_sync_1, rx_sync_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_1 <= 1'b1;
            rx_sync_2 <= 1'b1;
        end else begin
            rx_sync_1 <= rx_pin;
            rx_sync_2 <= rx_sync_1;
        end
    end

    // Bo tao xung Tick 16x
    wire tick_16x = (baud_counter == BAUD_LIMIT);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 32'd0;
        end else begin
            if (state == IDLE && rx_sync_2 == 1'b1) begin
                baud_counter <= 32'd0;
            end else if (tick_16x) begin
                baud_counter <= 32'd0;
            end else begin
                baud_counter <= baud_counter + 1'b1;
            end
        end
    end

    // Majority Voting loc nhieu o mau 7, 8, 9
    reg sample_7, sample_8, sample_9;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_7 <= 1'b1; sample_8 <= 1'b1; sample_9 <= 1'b1;
        end else if (tick_16x) begin
            if (sample_tick == 4'd7) sample_7 <= rx_sync_2;
            if (sample_tick == 4'd8) sample_8 <= rx_sync_2;
            if (sample_tick == 4'd9) sample_9 <= rx_sync_2;
        end
    end

    wire rx_filtered = (sample_7 & sample_8) | (sample_7 & sample_9) | (sample_8 & sample_9);

    // FSM Nhan du lieu
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 1'b0;
            sample_tick <= 4'd0;
            bit_index <= 3'd0;
            rx_data <= 8'd0;
            data_reg <= 8'd0;
        end else begin
            rx_done <= 1'b0; // Mac dinh tat co bao

            case (state)
                IDLE: begin
                    sample_tick <= 4'd0;
                    bit_index <= 3'd0;
                    if (rx_sync_2 == 1'b0) begin
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (tick_16x) begin
                        if (sample_tick == 4'd15) begin
                            state <= DATA_BITS;
                            sample_tick <= 4'd0;
                        end else if (sample_tick == 4'd10) begin
                            // Neu tai giua Start bit ma tin hieu = 1 -> Nhieu, quay ve IDLE
                            if (rx_filtered == 1'b1) begin
                                state <= IDLE;
                            end else begin
                                sample_tick <= sample_tick + 1'b1;
                            end
                        end else begin
                            sample_tick <= sample_tick + 1'b1;
                        end
                    end
                end

                DATA_BITS: begin
                    if (tick_16x) begin
                        if (sample_tick == 4'd10) begin
                            data_reg[bit_index] <= rx_filtered;
                            sample_tick <= sample_tick + 1'b1;
                        end else if (sample_tick == 4'd15) begin
                            sample_tick <= 4'd0;
                            if (bit_index == 3'd7) begin
                                state <= STOP_BIT;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end else begin
                            sample_tick <= sample_tick + 1'b1;
                        end
                    end
                end

                STOP_BIT: begin
                    if (tick_16x) begin
                        if (sample_tick == 4'd10) begin
                            rx_data <= data_reg; // Chot du lieu
                            sample_tick <= sample_tick + 1'b1;
                        end else if (sample_tick == 4'd15) begin
                            rx_done <= 1'b1; // Phat xung da nhan xong 1 byte
                            state <= IDLE;
                            sample_tick <= 4'd0;
                        end else begin
                            sample_tick <= sample_tick + 1'b1;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
