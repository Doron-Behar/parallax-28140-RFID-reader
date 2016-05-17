library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
library RFID;
use RFID.UART.all;
use RFID.reciever.all;
use RFID.components.all;

entity RFID_reader is
	port(
		----simulation:
		SIM_vars	:out SIM_vars_type;
		----design
		reset		:in std_logic;
		clk100mhz	:in std_logic;
		data		:in std_logic;
		ID			:out std_logic_vector(40-1 downto 0);
		successful	:out std_logic;
		broadcast	:out std_logic;
		byte		:out std_logic_vector(7 downto 0);
		uart_tx		:out std_logic;
		pmod		:out std_logic_vector(1 downto 0)
	);
end entity;

architecture arc of RFID_reader is
	function valid(chr:std_logic_vector(7 downto 0)) return boolean is
	begin
		if (chr(7 downto 0)>=x"30" and chr(7 downto 0)<=x"39") or (chr(7 downto 0)>=x"40" and chr(7 downto 0)<=x"46") then
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
	signal UART:UART_type;
	signal reciever:reciever_type;
begin
	--====================================================================
	--------------------------------UART----------------------------------
	--====================================================================
	-- UART's physical interface input:
	UART.rx.buff<=data;
	uart_tx<=UART.tx.buff;
	-- sample signal at 16x baud rate, 1 clk spikes:
	sample_process:process(clk100mhz,reset) is
	begin
		if reset='1' then
			UART.sample.counter<=(others=>'0');
			UART.sample.clk<='0';
		elsif rising_edge(clk100mhz) then
			if UART.sample.counter=DIVISOR-1 then
				UART.sample.clk<='1';
				UART.sample.counter<=(others=>'0');
			else
				UART.sample.clk<='0';
				UART.sample.counter<=UART.sample.counter + 1;
			end if;
		end if;
	end process;
	-- RX, TX state registers update at each clk, and reset
	reg_process:process(clk100mhz,reset) is
	begin
		if reset='1' then
			UART.rxs.last.state<=idle;
			UART.rxs.last.bits<=(others=>'0');
			UART.rxs.last.nbits<=(others=>'0');
			UART.rxs.last.enable<='0';
			UART.txs.last.state<=idle;
			UART.txs.last.bits<=(others=>'1');
			UART.txs.last.nbits<=(others=>'0');
			UART.txs.last.ready<='1';
		elsif rising_edge(clk100mhz) then
			UART.rxs.last<=UART.rxs.current;
			UART.txs.last<=UART.txs.current;
		end if;
	end process;
	-- RX FSM
	rx_process:process (UART.rxs,UART.sample.clk,UART.rx.buff) is
	begin
		case UART.rxs.last.state is
			when idle=>
				UART.rxs.current.counter<=(others=>'0');
				UART.rxs.current.bits<=(others=>'0');
				UART.rxs.current.nbits<=(others=>'0');
				UART.rxs.current.enable<='0';
				if UART.rx.buff='0' then
					-- start a new byte
					UART.rxs.current.state<=active;
				else
					-- keep idle
					UART.rxs.current.state<=idle;
				end if;
			when active=>
				UART.rxs.current<=UART.rxs.last;
				if UART.sample.clk='1' then
					if UART.rxs.last.counter=8 then
						-- UART.sample next RX bit (at the middle of the counter cycle)
						if UART.rxs.last.nbits=9 then
							-- back to idle state to wait for next start bit
							UART.rxs.current.state<=idle;
							-- OK if stop bit is '1':
							UART.rxs.current.enable<=UART.rx.buff;
						else
							UART.rxs.current.bits<=UART.rx.buff & UART.rxs.last.bits(7 downto 1);
							UART.rxs.current.nbits<=UART.rxs.last.nbits + 1;
						end if;
					end if;
					UART.rxs.current.counter<=UART.rxs.last.counter+1;
				end if;
		end case;
	end process;
	-- RX output
	rx_output:process(UART.rxs) is
	begin
		UART.rx.enable<=UART.rxs.last.enable;
		UART.rx.data<=UART.rxs.last.bits;
	end process;
	-- TX FSM
	tx_process:process(UART.txs,UART.sample.clk,UART.tx.enable,UART.tx.data) is
	begin
		case UART.txs.last.state is
			when idle=>
				if UART.tx.enable='1' then
					-- start a new bit
					-- data & start
					UART.txs.current.bits<=UART.tx.data & '0';
					-- send 10 bits (includes '1' stop bit)
					UART.txs.current.nbits<="1000";
					UART.txs.current.counter<=(others=>'0');
					UART.txs.current.state<=active;
					UART.txs.current.ready<='0';
				else
					-- keep idle
					UART.txs.current.bits<=(others=>'1');
					UART.txs.current.nbits<=(others=>'0');
					UART.txs.current.counter<=(others=>'0');
					UART.txs.current.state<=idle;
					UART.txs.current.ready<='1';
				end if;
			when active=>
				UART.txs.current<=UART.txs.last;
				if UART.sample.clk='1' then
					if UART.txs.last.counter=15 then
						-- send next bit
						if UART.txs.last.nbits=0 then
							-- turn idle
							UART.txs.current.bits<=(others=>'1');
							UART.txs.current.nbits<=(others=>'0');
							UART.txs.current.counter<=(others=>'0');
							UART.txs.current.state<=idle;
							UART.txs.current.ready<='1';
						else
							UART.txs.current.bits<='1' & UART.txs.last.bits(8 downto 1);
							UART.txs.current.nbits<=UART.txs.last.nbits - 1;
						end if;
					end if;
					UART.txs.current.counter<=UART.txs.last.counter + 1;
				end if;
		end case;
	end process;
	-- TX output
	tx_output:process(UART.txs) is
	begin
		UART.tx.ready<=UART.txs.last.ready;
		UART.tx.buff<=UART.txs.last.bits(0);
	end process;
	--====================================================================
	------------------------------receiver--------------------------------
	--====================================================================
	pmod(0)<=UART.tx.enable;
	pmod(1)<=UART.tx.ready;
	fsm_clk:process(clk100mhz,reset) is
	begin
		if reset='1' then
			reciever.last.state<=idle;
			reciever.last.tx.data<=(others=>'0');
			reciever.last.tx.enable<='0';
		elsif rising_edge(clk100mhz) then
			reciever.last<=reciever.current;
		end if;
	end process;
	fsm_next:process(reciever.last,UART.rx.enable,UART.rx.data,UART.tx.ready) is
	begin
		reciever.current<=reciever.last;
		case reciever.last.state is
			when idle=>
				if UART.rx.enable = '1' then
					reciever.current.tx.data<=UART.rx.data;
					reciever.current.tx.enable<='0';
					reciever.current.state<=received;
				end if;
			when received=>
				if UART.tx.ready = '1' then
					reciever.current.tx.enable<='1';
					reciever.current.state<=emitting;
				end if;
			when emitting=>
				if UART.tx.ready = '0' then
					reciever.current.tx.enable<='0';
					reciever.current.state<=idle;
				end if;
		end case;
	end process;
	fsm_output:process(reciever.last) is
	begin
		UART.tx.enable<=reciever.last.tx.enable;
		UART.tx.data<=reciever.last.tx.data;
		byte<=reciever.last.tx.data;
	end process;
	--====================================================================
	-------------------------------reader---------------------------------
	--====================================================================
	process(clk100mhz,reset)
		type byte_type is record
			current:std_logic_vector(7 downto 0);
			last:std_logic_vector(7 downto 0);
			index:integer range 0 to 9;
		end record;
		variable byte:byte_type;
		type state_type is (startbyte,databytes,endbyte);
		variable state:state_type;
	begin
		byte.current:=reciever.last.tx.data;
		if reset='1' then
			byte.index:=0;
			byte.last:=x"00";
			byte.current:=x"00";
		elsif rising_edge(clk100mhz) then
			if byte.current/=byte.last then
				case state is
					when startbyte=>
						if byte.last=x"0A" then
						--start byte:
							state:=databytes;
							byte.index:=1;
							--report that a broadcast has started:
							broadcast<='1';
							--make `successful` low to imply that we don't
							--know if the rest of the following broadcast
							--will be successful.
							successful<='0';
						end if;
					when databytes=>
						if byte.index<9 and valid(byte.last)=true then
							ID(byte.index*4+3 downto byte.index*4)<=ascii2hex(byte.last);
						else
							state:=endbyte;
						end if;
						byte.index:=byte.index+1;
					when endbyte=>
						if byte.last=x"0D" then
							--report a successful transmission finished:
							successful<='1';
							--report that a broadcast has finished:
							broadcast<='0';
							state:=startbyte;
						end if;
				end case;
			end if;
			byte.last:=byte.current;
		end if;
	end process;
end arc;
