library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package display is
	component hex7segment
		port(
			data 		:in std_logic_vector(4 downto 0);
			segments	:out std_logic_vector(6 downto 0)
		);
	end component;
	type hex_segments_type is array(7 downto 0)of std_logic_vector(6 downto 0);
	type hex_data_type is array(7 downto 0) of std_logic_vector(4 downto 0);
	type hex_type is record
		data:hex_data_type;
		segments:hex_segments_type;
	end record;
end package;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity hex7segment is
	port(
		data 		:in std_logic_vector(4 downto 0);
		segments	:out std_logic_vector(6 downto 0)
	);
end entity;

architecture proc of hex7segment is
begin
	process(data)
	begin
		case data is
			when "00000"	=>segments<="1000000";	--0
			when "00001"	=>segments<="1111001";	--1
			when "00010"	=>segments<="0100100";	--2
			when "00011"	=>segments<="0110000";	--3
			when "00100"	=>segments<="0011001";	--4
			when "00101"	=>segments<="0010010";	--5
			when "00110"	=>segments<="0000010";	--6
			when "00111"	=>segments<="1111000";	--7
			when "01000"	=>segments<="0000000";	--8
			when "01001"	=>segments<="0011000";	--9
			when "01010"	=>segments<="0001000";	--A
			when "01011"	=>segments<="0000011";	--B
			when "01100"	=>segments<="1000110";	--C
			when "01101"	=>segments<="0100001";	--D
			when "01110"	=>segments<="0000110";	--E
			when "01111"	=>segments<="0001110";	--F
			when "10000"	=>segments<="0100111";	--"c"
			when "10001"	=>segments<="0001001";	--"H"
			when "10010"	=>segments<="1100001";	--"J"
			when "10011"	=>segments<="1000111";	--"L"
			when "10100"	=>segments<="0010010";	--"S"
			when "10101"	=>segments<="0100011";	--"o"
			when "10110"	=>segments<="0001100";	--"P"
			when "10111"	=>segments<="1000001";	--"U"
			when "11000"	=>segments<="0010001";	--"y"
			when "11001"	=>segments<="0111111";	--"-"
			when "11010"	=>segments<="1110111";	--"_"
			when "11011"	=>segments<="0110111";	--"="
			when others		=>segments<="1111111";
		end case;
	end process;
end proc;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
library RFID;
use RFID.UART.all;
use RFID.reciever.all;
use RFID.components.all;
use work.display.all;

entity example is
	port(
		CLK50MHZ	:in std_logic;
		KEY			:in std_logic_vector(3 downto 0);
		GPIO		:inout std_logic_vector(35 downto 0);
		HEX0		:out std_logic_vector(6 downto 0);
		HEX1		:out std_logic_vector(6 downto 0);
		HEX2		:out std_logic_vector(6 downto 0);
		HEX3		:out std_logic_vector(6 downto 0);
		HEX4		:out std_logic_vector(6 downto 0);
		HEX5		:out std_logic_vector(6 downto 0);
		HEX6		:out std_logic_vector(6 downto 0);
		HEX7		:out std_logic_vector(6 downto 0);
		LEDR		:out std_logic_vector(17 downto 0);
		LEDG		:out std_logic_vector(8 downto 0)
	);
end entity;

architecture arc of example is
	signal reset:std_logic;
	-- clocks:
	signal clk100mhz:std_logic;
	signal clk9600hz:std_logic;
	-- hex 7 segment signals: data and segments:
	signal hex:hex_type;
	signal o:std_logic_vector(39 downto 0);

begin
	reset<=not KEY(0);
	PLL:PLL50mhz_100mhz
		port map(
			areset	=>reset,
			inclk0	=>clk50mhz,
			c0		=>clk100mhz,
			-- Useful for signaltap:
			c1		=>clk9600hz
		);
	RFID_reader_inst:RFID_reader
		port map(
			-- simulation:
			SIM_vars	=>open,
			-- design
			reset		=>reset,
			clk100mhz	=>clk100mhz,
			-- I use the old form of the electrical circuit
			-- The form that _does_ invert the signal from
			-- the reader - Therefor I insert here another
			-- not gate.
			data		=>not GPIO(10),
			ID			=>o,
			successful	=>LEDG(8),
			broadcast	=>LEDR(17),
			byte		=>open,
			uart_tx		=>open,
			pmod		=>open
		);

	-- The ID is observeable with the hex7segment display in combination with the 7 right green leds:
	hex.data(0)			<='0'&o(3 downto 0);
	hex.data(1)			<='0'&o(7 downto 4);
	hex.data(2)			<='0'&o(11 downto 8);
	hex.data(3)			<='0'&o(15 downto 12);
	hex.data(4)			<='0'&o(19 downto 16);
	hex.data(5)			<='0'&o(23 downto 20);
	hex.data(6)			<='0'&o(27 downto 24);
	hex.data(7)			<='0'&o(31 downto 28);
	LEDG(7 downto 0)	<=o(39 downto 32);
	digits2hex7segment:for i in 0 to 7 generate
		hex7segment_inst:hex7segment
			port map(
				data=>hex.data(i),
				segments=>hex.segments(i)
			);
	end generate digits2hex7segment;
	HEX0<=hex.segments(0);
	HEX1<=hex.segments(1);
	HEX2<=hex.segments(2);
	HEX3<=hex.segments(3);
	HEX4<=hex.segments(4);
	HEX5<=hex.segments(5);
	HEX6<=hex.segments(6);
	HEX7<=hex.segments(7);
end architecture;
