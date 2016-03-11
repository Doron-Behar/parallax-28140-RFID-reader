library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity RFID_reader is
	port	(
		reset			:in std_logic;
		clk50mhz		:in std_logic;
		RFID_not_data	:in std_logic;
		ID				:out std_logic_vector(40-1 downto 0);
		successful		:out std_logic
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
begin
	data<=not RFID_not_data;
	PLL50mhz_2400hz_inst:PLL50mhz_2400hz
		port map(
			inclk0=>clk50mhz,
			areset=>not reset,
			c0=>clk2400hz
		);
	process(clk2400hz,reset,data)
	variable tmp:std_logic_vector(7 downto 0);
	variable counter:integer range 0 to 100;
	type main_state_type is (wait4startbits,startbits,wait4byte,reading,wait4endbits,endbits,fixing);
	variable main_state:main_state_type;
	type byte_type is array(3 downto 0,7 downto 0) of std_logic_vector(7 downto 0);
	variable byte:byte_type;
	variable sample:integer range 0 to 3;
	variable index:integer range 0 to 7;
	subtype var_type is std_logic_vector(110-1 downto 0);
	variable var:var_type;
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
		if reset='0' then
			main_state:=wait4startbits;
			counter:=0;
			tmp:=(others=>'0');
			ID<=(others=>'0');
			successful<='0';
--			sample:=0;
			index:=0;
			byte:=(others=>(others=>(others=>'0')));
			var:=(others=>'0');
		elsif rising_edge(clk2400hz) then
			case main_state is
				when wait4startbits=>
					if data='0' then--start-bit
						main_state:=startbits;
						successful<='0';
						var:=(others=>'0');
						tmp:=(others=>'0');
						index:=0;
					end if;
				when startbits=>
					if counter<8 then
						tmp(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if tmp=x"0a" and data='1' then--data='1' is stop-bit
							main_state:=wait4byte;
						else
							main_state:=wait4startbits;
						end if;
					end if;
				when wait4byte=>
					if data='0' then
						main_state:=reading;
					else
						main_state:=fixing;
						counter:=index*10+9;
						index:=0;
					end if;
				when reading=>
					if counter<8 then
						tmp(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if valid(data&tmp&'0')=true then
							byte(0,index):=tmp;
							if index<8 then
								index:=index+1;
								main_state:=wait4byte;
							else
								index:=0;
								main_state:=wait4endbits;
							end if;
						else
							var(index*10+0):='0';
							var(index*10+8 downto index*10+1):=tmp;
							counter:=index*10+9;
							index:=0;
							main_state:=fixing;--state ment to deal with overlapping data
						end if;
					end if;
				when wait4endbits=>
					if data='0' then
						main_state:=endbits;
					else
						main_state:=wait4startbits;
					end if;
				when endbits=>
					if counter<8 then
						tmp(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if tmp=x"0D" and data='1' then
							for i in 0 to 7 loop--check all bytes;
								for j in 0 to 3 loop--check if the current sample's byte is equal to the corresponding one in another sample;
									if byte(0,i)=byte((0+j) mod 4,i) then
										ID(i*4+3 downto i*4)<=ascii2hex(byte(0,i));
										exit;
									end if;
								end loop;
							end loop;
--							sample:=sample+1;
						end if;
						index:=0;
						main_state:=wait4startbits;
					end if;
				when fixing=>
					if counter<110 then
						var(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if var(110-1 downto 110-10)='0'&x"0D"&'1' then
							for i in 9 downto 0 loop
								if valid(var(i*10+9 downto i*10))=true then
									ID(i*4+3 downto i*4)<=ascii2hex(var(i*10+8 downto i*10+1));
								else
									exit;
								end if;
							end loop;
						end if;
						main_state:=wait4startbits;
					end if;
			end case;
		end if;
	end process;
end arc;
