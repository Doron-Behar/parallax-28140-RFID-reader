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
	type main_state_type is (wait4startbits,startbits,wait4reading,reading,wait4endbits,endbits);
	variable main_state:main_state_type;
	variable var:std_logic_vector(100-1 downto 0);
	type IDR_type is array(3 downto 0) of std_logic_vector(100-1 downto 0);
	variable IDR:IDR_type;
	type byte_type is array(3 downto 0) of std_logic_vector(7 downto 0);
	variable byte:byte_type;
	variable ascii:std_logic_vector(7 downto 0);
	variable sample:integer range 0 to 3;
	begin
		if reset='0' then
			main_state:=wait4startbits;
			counter:=0;
			tmp:=(others=>'0');
			ID<=(others=>'0');
			successful<='0';
			var:=(others=>'0');
			IDR:=(others=>(others=>'0'));
			sample:=0;
			byte:=(others=>"00000000");
			ascii:=(others=>'0');
		elsif rising_edge(clk2400hz) then
		case main_state is
			when wait4startbits=>
				if data='0' then--start-bit
					main_state:=startbits;
					successful<='0';
				end if;
			when startbits=>
				if counter<8 then
					tmp(counter):=data;
					counter:=counter+1;
				else
					counter:=0;
					if tmp=x"0a" and data='1' then--data='1' is stop-bit
						main_state:=wait4reading;
					else
						main_state:=wait4startbits;
					end if;
				end if;
			when wait4reading=>
				if data='0' then
					main_state:=reading;
				else
					main_state:=wait4startbits;
				end if;
			when reading=>
				if counter<100-1 then
					counter:=counter+1;
					var(counter):=data;
				else
					counter:=0;
					if data='1' then
						main_state:=wait4endbits;
					else
						main_state:=wait4startbits;
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
				if tmp=x"0d" and data='1' then--data='1' is stop-bit
					successful<='1';
					IDR(sample):=var;
					for i in 0 to 9 loop
						byte(sample):=IDR(sample)(i*10+8 downto i*10+1);
						if IDR(sample)(i*10)='0' and IDR(sample)(i*10+9)='1' then
							if byte(0)=byte(1) or byte(0)=byte(2) or byte(0)=byte(3) then
								if byte(0)>=x"30" and byte(0)<=x"39" then
									ascii:=byte(0)-x"30";
									ID(i*4+3 downto i*4)<=ascii(3 downto 0);
								else
									ID(i*4+3 downto i*4)<="ZZZZ";
								end if;
							elsif byte(1)=byte(2) or byte(1)=byte(3) then
								if byte(1)>=x"30" and byte(1)<=x"39" then
									ascii:=byte(1)-x"30";
									ID(i*4+3 downto i*4)<=ascii(3 downto 0);
								else
									ID(i*4+3 downto i*4)<="ZZZZ";
								end if;
							elsif byte(2)=byte(3) then
								if byte(2)>=x"30" and byte(2)<=x"39" then
									ascii:=byte(2)-x"30";
									ID(i*4+3 downto i*4)<=ascii(3 downto 0);
								else
									ID(i*4+3 downto i*4)<="ZZZZ";
								end if;
							end if;
						end if;
					end loop;
					sample:=sample+1;
				else
					successful<='0';
				end if;
				main_state:=wait4startbits;
			end if;
		end case;
		end if;
	end process;
end arc;
