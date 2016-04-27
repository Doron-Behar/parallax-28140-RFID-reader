library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

package SIM is
	--====================================================================
	--------------------------------UART----------------------------------
	--====================================================================
	constant divisor:natural:=2604; -- DIVISOR=100,000,000 / (16 x BAUD_RATE)
			-- for a frequency of 2400hz you need to put 2604 as a divisor
			-- for a frequency of 9600hz you need to put 651 as a divisor
			-- for a frequency of 115200hz you need to put 54 as a divisor
			-- for a frequency of 1562500hz you need to put 4 as a divisor
			-- for a frequency of 2083333hz you need to put 3 as a divisor
	type UART_fsm_state_type is (idle,active); -- common to both RX and TX FSM
	type UART_rxs_state_type is record
		-- FSM state:
		state:UART_fsm_state_type;
		-- tick count:
		counter:std_logic_vector(3 downto 0);
		-- received bits:
		bits:std_logic_vector(7 downto 0);
		-- number of received bits (includes start bit):
		nbits:std_logic_vector(3 downto 0);
		-- signal we received a new byte:
		enable:std_logic;
	end record;
	type UART_txs_state_type is record
		-- FSM state:
		state:UART_fsm_state_type;
		-- tick count:
		counter:std_logic_vector(3 downto 0);
		-- bits to emit, includes start bit:
		bits:std_logic_vector(8 downto 0);
		-- number of bits left to send:
		nbits:std_logic_vector(3 downto 0);
		-- signal we are accepting a new byte:
		ready:std_logic;
	end record;
	type UART_rxs_type is record
		current:UART_rxs_state_type;
		last:UART_rxs_state_type;
	end record;
	type UART_txs_type is record
		current:UART_txs_state_type;
		last:UART_txs_state_type;
	end record;
	type UART_sample_type is record
		clk:std_logic;
		-- should fit values in 0..DIVISOR-1:
		counter:std_logic_vector(integer(ceil(log2(real(divisor))))-1 downto 0);
	end record;
	type UART_rx_type is record
		-- received byte:
		data	:std_logic_vector(7 downto 0);
		-- validates received byte (1 system clock spike):
		enable	:std_logic;
		--physical
		buff	:std_logic;
	end record;
	type UART_tx_type is record
		-- byte to send:
		data	:std_logic_vector(7 downto 0);
		-- validates byte to send if tx_ready is '1':
		enable	:std_logic;
		-- if '1', we can send a new byte, otherwise we won't take it:
		ready	:std_logic;
		--physical
		buff	:std_logic;
	end record;
	type UART_type is record
		rxs:UART_rxs_type;
		txs:UART_txs_type;
		rx:UART_rx_type;
		tx:UART_tx_type;
		sample:UART_sample_type;
	end record;
	--====================================================================
	------------------------------reciever--------------------------------
	--====================================================================
	type reciever_fsm_state_type is (idle,received,emitting);
	type reciever_tx_type is record
		data:std_logic_vector(7 downto 0);
		enable:std_logic;
	end record;
	type reciever_state_type is record
		state:reciever_fsm_state_type;
		tx:reciever_tx_type;
	end record;
	type reciever_type is record
		current:reciever_state_type;
		last:reciever_state_type;
	end record;
	type SIM_vars_type is record
		UART:UART_type;
		reciever:reciever_type;
	end record;
	component RFID_reader is
		port(
			----simulation:
			SIM_vars	:out SIM_vars_type;
			----design
			reset		:in std_logic;
			clk100mhz	:in std_logic;
			data		:in std_logic;
			ID			:out std_logic_vector(40-1 downto 0);
			successful	:out std_logic;
			broadcast	:out std_logic;
			byte		:out std_logic_vector(7 downto 0);
			uart_tx		:out std_logic;
			pmod		:out std_logic_vector(1 downto 0)
		);
	end component;
end package SIM;


