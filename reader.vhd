library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity RFID_reader is
	port	(
		reset	:in std_logic;
		clk50mhz:in std_logic;
		RFID_not_data:in std_logic;
		ID		:out std_logic_vector(40-1 downto 0)
	);
end entity;

architecture arc of RFID_reader is
component PLL50mhz_2400hz
	port	(	areset	:in std_logic:='0';
				inclk0	:in std_logic:='0';
				c0		:out std_logic		);
end component;
signal data		:std_logic;
signal clk2400hz:std_logic;
type main_state_type is (wait4startbits,startbits,reading,wait4endbits,endbits);
signal main_state:main_state_type;
begin
	data<=not RFID_not_data;
	PLL50mhz_2400hz_inst:PLL50mhz_2400hz
		port map(
			inclk0=>clk50mhz,
			areset=>not reset,
			c0=>clk2400hz
		);
	process(clk2400hz,reset,data)
	begin
		if reset='0' then
			main_state<=wait4startbits;
		elsif rising_edge(clk2400hz) then
			case main_state is
			when wait4startbits=>
				if data='0' then--start bit
					main_state<=startbits;
				end if;
			when startbits=>
			when reading=>
			when wait4endbits=>
			when endbits=>
			end case;
		end if;
	end process;
end arc;
