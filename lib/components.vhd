-- synthesis library RFID
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library RFID;
use RFID.UART.all;
use RFID.reciever.all;

package components is
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
			not_data	:in std_logic;
			ID			:out std_logic_vector(40-1 downto 0);
			successful	:out std_logic;
			broadcast	:out std_logic;
			byte		:out std_logic_vector(7 downto 0);
			uart_tx		:out std_logic;
			pmod		:out std_logic_vector(1 downto 0)
		);
	end component;
	component PLL50mhz_100mhz is
		port(
			areset	:in std_logic:='0';
			inclk0	:in std_logic:='0';
			c0		:out std_logic;
			c1		:out std_logic
		);
	end component;
end package;
