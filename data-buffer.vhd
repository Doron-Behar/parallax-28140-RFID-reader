library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity data_buffer is
	generic(
		extra_samples_width:integer:=4
	);
	port(
		clk		:in std_logic;
		reset	:in std_logic;
		not_data:in std_logic;
		data	:out std_logic;
		samples	:out integer range 0 to 2**extra_samples_width-1
	);
end entity;

architecture arc of data_buffer is
	type d_type is record
		current:std_logic;
		last:std_logic;
	end record;
	signal d:d_type;
	type counter_type is record
		current:integer range 0 to 2**extra_samples_width-1;
		last:integer range 0 to 2**extra_samples_width-1;
	end record;
	signal counter:integer range 0 to 2**extra_samples_width-1;
begin
	process(clk,reset)
	begin
		d.current<=not not_data;
		if reset='0' then
			counter<=0;
		elsif rising_edge(clk) then
			if d.current/=d.last then
				if counter mod 16 > 13 then	-- only recieved data
					counter<=0;				-- continued for more
				end if;						-- then 13 clocks.
			elsif counter<79 then
				counter<=counter+1;
			end if;
			d.last<=d.current;
		end if;
	end process;
	data<=d.current;
	samples<=counter;
end arc;
