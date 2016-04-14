library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity data_buffer is
	port(
		clk384000hz	:in std_logic;
		reset		:in std_logic;
		not_data	:in std_logic;
		data		:out std_logic;
		samples		:out std_logic_vector(15 downto 0)
	);
end entity;

architecture arc of data_buffer is
	signal counter:std_logic_vector(15 downto 0);
	type d_type is record
		current:std_logic;
		last:std_logic;
	end record;
	signal d:d_type;
begin
	process(clk384000hz,reset)
	begin
		d.current<=not not_data;
		if reset='0' then
			counter<=(others=>'0');
		elsif rising_edge(clk384000hz) then
			if d.current/=d.last then
				counter<=(others=>'0');
			else
				counter<=counter+1;
			end if;
			d.current<=d.last;
		end if;
	end process;
	data<=d.current;
	samples<=counter;
end arc;
