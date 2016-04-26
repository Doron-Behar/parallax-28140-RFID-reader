library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

package SIM is
	constant DIVISOR:natural:=2605; -- DIVISOR = 100,000,000 / (16 x BAUD_RATE)
		-- for a frequency of 2400hz you need to put 2604 as a divisor
		-- for a frequency of 9600hz you need to put 651 as a divisor
		-- for a frequency of 115200hz you need to put 54 as a divisor
		-- for a frequency of 1562500hz you need to put 4 as a divisor
		-- for a frequency of 2083333hz you need to put 3 as a divisor
	-- common to both RX and TX FSM:
	type sample_type is record
		-- should fit values in 0..DIVISOR-1:
		counter:std_logic_vector(integer(ceil(log2(real(DIVISOR))))-1 downto 0);
		-- 1 clk spike at 16x baud rate:
		clk:std_logic;
	end record;
	type UART_fsm_states_type is (idle,active);
	type UART_rxs_state_type is record
		-- FSM state:
		state:UART_fsm_states_type;
		-- tick count:
		counter:std_logic_vector(3 downto 0);
		-- received data:
		bits:std_logic_vector(7 downto 0);
		-- number of received data (includes start bit):
		nbits:std_logic_vector(3 downto 0);
		-- signal we received a new byte:
		enable:std_logic;
	end record;
	type UART_rxs_type is record
		current:UART_rxs_state_type;
		last:UART_rxs_state_type;
	end record;
	type UART_txs_state_type is record
		-- FSM state:
		state:UART_fsm_states_type;
		-- tick count:
		counter:std_logic_vector(3 downto 0);
		-- received data:
		bits:std_logic_vector(7 downto 0);
		-- number of received data (includes start bit):
		nbits:std_logic_vector(3 downto 0);
		-- signal we received a new byte:
		ready:std_logic;
	end record;
	type UART_txs_type is record
		current:UART_txs_state_type;
		last:UART_txs_state_type;
	end record;
	type UART_rx_type is record
		-- received byte:
		data:std_logic_vector(7 downto 0);
		-- validates received byte (1 system clock spike):
		enable:std_logic;
		buff:std_logic;
	end record;
	type UART_tx_type is record
		-- byte to send:
		data:std_logic_vector(7 downto 0);
		-- validates byte to send if tx_ready is '1':
		enable:std_logic;
		-- if '1', we can send a new byte, otherwise we won't take it:
		ready:std_logic;
		buff:std_logic;
	end record;
	type UART_type is record
		rxs:UART_rxs_type;
		txs:UART_txs_type;
		rx:UART_rx_type;
		tx:UART_tx_type;
		sample:sample_type;
	end record;
	type SIM_vars_type is record
		UART:UART_type;
		--reciever:reciever_type;
	end record;
	component RFID_reader is
		port	(
			----simulation:
			SIM_vars	:out SIM_vars_type;
			----design
			reset		:in std_logic;
			clk50mhz	:in std_logic;
			data		:in std_logic;
			ID			:out std_logic_vector(40-1 downto 0);
			successful	:out std_logic;
			broadcast	:out std_logic
		);
	end component;
end package SIM;


