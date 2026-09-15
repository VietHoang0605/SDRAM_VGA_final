vlib work
vlog -work work sdram_arbiter.v tb_sdram_arbiter.v
vsim -voptargs=+acc work.tb_sdram_arbiter

add wave -divider "System Signals"
add wave -color white -radix binary /tb_sdram_arbiter/clk
add wave -color white -radix binary /tb_sdram_arbiter/rst_n

add wave -divider "VGA Sync"
add wave -color yellow -radix binary /tb_sdram_arbiter/vga_vsync
add wave -color yellow -radix binary /tb_sdram_arbiter/dut/vsync_req

add wave -divider "W-FIFO Interface"
add wave -color cyan -radix binary /tb_sdram_arbiter/w_fifo_empty
add wave -color cyan -radix binary /tb_sdram_arbiter/w_fifo_rd_en
add wave -color cyan -radix hex /tb_sdram_arbiter/w_fifo_data

add wave -divider "R-FIFO Interface"
add wave -color magenta -radix unsigned /tb_sdram_arbiter/r_fifo_count
add wave -color magenta -radix binary /tb_sdram_arbiter/r_fifo_wr_en
add wave -color magenta -radix hex /tb_sdram_arbiter/r_fifo_data

add wave -divider "SDRAM Controller"
add wave -color green -radix binary /tb_sdram_arbiter/sys_ready
add wave -color green -radix binary /tb_sdram_arbiter/sys_write_req
add wave -color green -radix binary /tb_sdram_arbiter/sys_read_req
add wave -color green -radix hex /tb_sdram_arbiter/sys_addr
add wave -color green -radix hex /tb_sdram_arbiter/sys_data_in
add wave -color green -radix binary /tb_sdram_arbiter/sys_valid
add wave -color green -radix hex /tb_sdram_arbiter/sys_data_out

add wave -divider "Internal FSM"
add wave -color orange -radix unsigned /tb_sdram_arbiter/dut/state
add wave -color orange -radix hex /tb_sdram_arbiter/dut/read_addr
add wave -color orange -radix hex /tb_sdram_arbiter/dut/write_addr

view structure
view signals
run -all

config wave -signalnamewidth 1
wave zoom full
