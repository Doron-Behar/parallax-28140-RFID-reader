library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity RFID_reader is
	port	(
		reset	:in std_logic;
		clk50mhz:in std_logic;
		not_data:in std_logic;
		ID		:out std_logic_vector(40-1 downto 0)
	);
end entity;

architecture arc of RFID_reader is
signal data:std_logic;
type main_state_type is (wait2startbits,startbits,reading,wait2endbits,endbits);
signal main_state:main_state_type;

component PLL50mhz_2400hz
	port	(	areset	:in std_logic:='0';
				inclk0	:in std_logic:='0';
				c0		:out std_logic		);
end component;
signal clk2400hz:std_logic;

constant IDRL	:integer range 0 to 100:=100;--ID-register length--10 bits per 10 bytes
signal BC		:integer range 0 to IDRL-1;--bits counter
signal RC		:std_logic;--'read-count' - counts how many times the ID was read
constant IDL	:integer range 0 to 40:=40;--ID string length
subtype ID_str is std_logic_vector(IDRL downto 0);
signal IDR		:ID_str;--read-ID register
constant EBL	:integer range 0 to 9:=9;--edges' bytes' length including stop bits
subtype RFID_byte is std_logic_vector(EBL-1 downto 0);
constant SB		:RFID_byte:="100001010";--start bits constant
constant EB		:RFID_byte:="100001101";--end bits constant
signal char		:RFID_byte;--unique ID char register
begin--both constants include the stop bits -- '1'
	data<=not not_data;
	PLL50mhz_2400hz_inst:PLL50mhz_2400hz
		port map(
			inclk0=>clk50mhz,
			areset=>not reset,
			c0=>clk2400hz
		);
	reader:process(clk2400hz,reset,data)
	variable IDV:ID_str;--read-ID variable
	begin
		if reset='0' then
			RC<='0';
			main_state<=wait2startbits;
			BC<=0;
		elsif rising_edge(clk2400hz) then
			case main_state is
			when wait2startbits=>
				if data='0' then--start bit
					main_state<=startbits;
				end if;
			when startbits=>
				if BC<EBL-1 then--if BC<8
					char(BC)<=data;
					BC<=BC+1;
				else--BC=8 then
					char(EBL-1)<=data;--char(8)<=data;
					BC<=0;
					if char=SB then
						main_state<=reading;
					else
						main_state<=wait2startbits;
					end if;
				end if; 
			when reading=>
				if BC<IDRL then--if BC<100
					IDV(BC):=data;
					BC<=BC+1;
				else--BC=99 then
					IDV(IDRL):=data;--IDV(100):=data when IDRL=100
					BC<=0;
					main_state<=wait2endbits;
				end if;
			when wait2endbits=>
				if data='0' then
					main_state<=endbits;
				end if;
			when endbits=>
				if BC<EBL-1 then
					char(BC)<=data;
					BC<=BC+1;
				else--BC=8-1=7
					char(EBL-1)<=data;
					BC<=0;
					if char=EB then
						IDR<=IDV;
					else
						IDR<=(others=>'0');
					end if;
					main_state<=wait2startbits;
				end if;
			end case;
		end if;
	end process reader;
	process(IDR)
	variable IDRNA:std_logic_vector(7 downto 0);--ID register not ascii (after decrementation by x"30")
	variable i,j:integer range 0 to IDRL;
	variable x:integer range 0 to IDL;
	begin
		i:=1;j:=8;
		x:=0;
		while j<IDRL-1 and x<IDL-1 loop
			IDRNA:=IDR(j downto i)-x"30";
			i:=i+9;j:=j+9;
			ID(x+3 downto x)<=IDRNA(3 downto 0);
			x:=x+4;
		end loop;
	end process;
--	memory:process(reset,clk50mhz)
--	begin
--		
--	end process;
end arc;
