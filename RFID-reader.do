vcom -2008 data-buffer.vhd testbench.vhd
vsim -voptargs=+acc testbench
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench/reset
add wave -noupdate -format Logic /testbench/data_clk
add wave -noupdate -format Literal /testbench/line__76/counter
add wave -noupdate -format Logic /testbench/not_data
add wave -noupdate -format Logic /testbench/PLL_clk
add wave -noupdate -format Logic /testbench/data
add wave -noupdate -format literal -radix unsigned /testbench/samples
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {56020710 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {105 ms}
run 300 ms 
