library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
--use work.SIM.all;

entity RFID_reader is
	port	(
		----simulation:
		--SIM_PLL	:in std_logic;
		--SIM_vars	:out SIM_vars_type;
		----design
		reset		:in std_logic;
		clk50mhz	:in std_logic;
		data		:in std_logic;
		ID			:out std_logic_vector(40-1 downto 0);
		successful	:out std_logic;
		broadcast	:out std_logic
	);
end entity;

architecture arc of RFID_reader is
	signal sampling_clk:std_logic;
	function valid(chr:std_logic_vector(9 downto 0)) return boolean is
	begin
		if chr(9)='1' and ((chr(8 downto 1)>=x"30" and chr(8 downto 1)<=x"39") or (chr(8 downto 1)>=x"41" and chr(8 downto 1)<=x"46")) and chr(0)='0' then
			return true;
		else
			return false;
		end if;
	end function;
	function ascii2hex(chr:std_logic_vector(7 downto 0)) return std_logic_vector is
		variable x:std_logic_vector(7 downto 0);
	begin
		if chr>=x"30" and chr<=x"39" then
			x:=chr-x"30";
		elsif chr>=x"41" and chr<=x"46" then
			x:=chr-x"41"+10;
		else
			x:=(others=>'Z');
		end if;
		return x(3 downto 0);
	end function;
begin
end arc;
