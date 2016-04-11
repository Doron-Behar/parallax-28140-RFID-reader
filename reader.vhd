library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity RFID_reader is
	port	(
		reset		:in std_logic;
		clk50mhz	:in std_logic;
		not_data	:in std_logic;
		ID			:out std_logic_vector(40-1 downto 0);
		successful	:out std_logic;
		broadcast	:out std_logic
	);
end entity;

architecture arc of RFID_reader is
	component PLL50mhz_2400hz
		port(
			areset	:in std_logic:='0';
			inclk0	:in std_logic:='0';
			c0		:out std_logic
		);
	end component;
	signal data		:std_logic;
	signal clk2400hz:std_logic;
begin
	data<=not not_data;
	PLL50mhz_2400hz_inst:PLL50mhz_2400hz
		port map(
			inclk0=>clk50mhz,
			areset=>not reset,
			c0=>clk2400hz
		);
	process(clk2400hz,reset)
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
		variable tmp:std_logic_vector(7 downto 0);
		variable counter:integer range 0 to 100;
		type main_state_type is (wait4startbits,startbits,wait4byte,reading,wait4endbits,endbits,fixing);
		variable main_state:main_state_type;
		variable sample:integer range 0 to 3;
		variable index:integer range 0 to 9;
		variable err:main_state_type;
		procedure assign(
			byte:in std_logic_vector(7 downto 0)
		) is
		begin
			ID(index*4+3 downto index*4)<=ascii2hex(byte);
			if index<9 then
				index:=index+1;
				main_state:=wait4byte;
			else
				index:=0;
				main_state:=wait4endbits;
			end if;
		end procedure assign;
	begin
		if reset='0' then
			main_state:=wait4startbits;
			counter:=0;
			tmp:=(others=>'0');
			ID<=(others=>'0');
			successful<='0';
			index:=0;
			broadcast<='0';
		elsif rising_edge(clk2400hz) then
			case main_state is
				when wait4startbits=>
					if data='0' then--start-bit
						main_state:=startbits;
						successful<='0';
						tmp:=(others=>'0');
						index:=0;
						broadcast<='1';
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
							broadcast<='0';
							err:=startbits;
						end if;
					end if;
				when wait4byte=>
					successful<='0';
					if data='0' then
						main_state:=reading;
					else
						err:=wait4byte;
						main_state:=fixing;
					end if;
				when reading=>
					if counter<8 then
						tmp(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if valid(data&tmp&'0')=true then
							assign(tmp);
						else
							err:=reading;
							main_state:=fixing;
						end if;
					end if;
				when wait4endbits=>
					if data='0' then
						main_state:=endbits;
					else
						err:=wait4endbits;
						main_state:=wait4startbits;
						broadcast<='0';
					end if;
				when endbits=>
					if counter<8 then
						tmp(counter):=data;
						counter:=counter+1;
					else
						counter:=0;
						if tmp=x"0D" and data='1' then
							successful<='1';
						else
							err:=endbits;
						end if;
						main_state:=wait4startbits;
						broadcast<='0';
					end if;
				when others=>
					if err=reading then
						--check if the byte that was recieved is in a proper range:
						if valid(data&tmp&'0')=true then
							--mistake is in the stop-bit
							--A.O.K --an extra '0' bit was added right before the end-bit
							assign(tmp);
						else
							main_state:=wait4startbits;
							broadcast<='0';
						end if;
					elsif err=wait4byte then
						--mirror to `wait4byte` state
						if data='0' then
							main_state:=reading;
						else
							err:=wait4byte;
							main_state:=wait4startbits;
							broadcast<='0';
						end if;
					end if;
			end case;
		end if;
	end process;
end arc;
