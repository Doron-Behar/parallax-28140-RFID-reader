library IEEE;
use IEEE.std_logic_1164.all  ; 
use IEEE.std_logic_arith.all  ; 
use IEEE.std_logic_unsigned.all  ; 

package SIM is
	type SIM_vars_type is record
	end record;
	component RFID_reader
		port(
			--simulation:
			SIM_PLL_clk	:in std_logic;
			SIM_vars	:out SIM_vars_type;
			--design
			reset		:in std_logic;
			clk50mhz	:in std_logic;
			not_data	:in std_logic;
			ID			:out std_logic_vector(40-1 downto 0);
			successful	:out std_logic;
			broadcast	:out std_logic
		);
	end component;
end package SIM;


