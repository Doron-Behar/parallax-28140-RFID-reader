library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.SIM.all;

entity testbench is
end entity;

architecture arc of testbench is
	----simulation:
	signal SIM_vars		:SIM_vars_type;
	----design
	signal reset		:std_logic:='1';
	signal clk50mhz		:std_logic:='0';
	signal data			:std_logic:='0';
	signal ID			:std_logic_vector(40-1 downto 0);
	signal successful	:std_logic;
	signal broadcast	:std_logic;
	constant data_at_data_clk:std_logic_vector:="000000000000000000000011010111101111100110110110011011111001101111110011011110001101101100110111100011011011110101111100110101111110101010011110000000000000000000000000000000000000000011010111110111110011011011001101111100110111110011011110001101101100011011110001101101111010111110011010111110101010011110000000000000000000000000000000000000000000000000000000001101011110111110011011011001100111110011011111001101111000110110110011011110001101101111011011111001101011111010101001111000000000000000000000000000000000000000001101011110111110011011011001101111100110111110011011110000110110110011011110001101101111010111110011010111110101010001111000000000000000000000000000000000011010111101111100110110110011011111001101111100110111100001101101100110111100011011011110101111100110101111101010100011110000000000000000000000000000000000000110101111011111001101100110011011111001101111100110111100011011011001101111000110111011110101111100110101111101010100111100000000000000000000000000000110101111011111100110110110011011111001101111100110111100011011011001100111100011011011110101111100110101111101010100111100000000000000000000000000000000000000000000001101011110111110011011011001101111100111011111001101111000110110110011011110001101101111010111110001101011111010101001111000000000000000000000000000000000000000000000000000000000001101011110111110011011011001101111100110111111001101111000110110110011011110001101101111010111110011101011111010101001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110101111011111100110110110011011111001101111100110111100011011011001100111100011011011110101111100110101111101010100111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110101111011111001101101100110111110001101111100110111100011011011001101111000110110111101011111100110101111101010100111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100101111011111001101101100110111110011011111001101111000110111011001101111000110110111101011111001101011111010101001111000000000000000000000000000000000000000000011010111101111100110110110011101111100110111110011011110001101101100110111100011011011111010111110011010111110101010011110000000000000000";
	signal data_clk:std_logic:='0';
begin
	clk50mhz<=not clk50mhz after 10 ns;
	data_clk<=not data_clk after 208333 ns;
	RFID_reader_inst:RFID_reader
		port map(
			----simulation:
			SIM_vars	=>SIM_vars,
			----design
			reset		=>reset,
			clk50mhz	=>clk50mhz,
			data		=>data,
			ID			=>ID,
			successful	=>successful,
			broadcast	=>broadcast
		);
	reset<='0','1' after 1 us;
	process(data_clk,reset)
		variable counter:integer;
	begin
		if reset='0' then
			counter:=0;
			data<='0';
		elsif rising_edge(data_clk) then
			counter:=counter+1;
			if counter<data_at_data_clk'length then
				data<=data_at_data_clk(counter);
			else
				counter:=0;
			end if;
		end if;
	end process;
end arc;
