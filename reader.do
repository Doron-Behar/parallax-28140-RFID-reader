vcom -2008 SIM.package.vhd reader.vhd reader.TB.vhd
vsim -voptargs=+acc testbench
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench/reset
add wave -noupdate -format Logic /testbench/data
add wave -noupdate -format Logic /testbench/SIM_vars.UART.sample.clk
add wave -noupdate -format Logic /testbench/SIM_vars.UART.sample.counter
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.last.state
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.last.counter
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.last.bits
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.last.nbits
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.last.enable
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.current.state
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.current.counter
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.current.bits
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.current.nbits
add wave -noupdate -format Logic /testbench/SIM_vars.UART.rxs.current.enable
add wave -noupdate -format Logic /testbench/ID
TreeUpdate [SetDefaultTree]
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
run 300 ms 
