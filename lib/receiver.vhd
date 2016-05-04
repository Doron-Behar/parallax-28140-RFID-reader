-- synthesis library RFID
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

package reciever is
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
end package;
