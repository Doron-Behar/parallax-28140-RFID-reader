library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.SIM.all;

entity RFID_reader is
	port	(
		----simulation:
		SIM_vars	:out SIM_vars_type;
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
	signal UART:UART_type;
	--signal reciever:reciever_type;
begin
	-- UART's physical interface input:
	UART.rx.buff<=data;
	-- UART.sample signal at 16x baud rate, 1 clk spikes:
	sample_process:process(clk50mhz,reset) is
	begin
		if reset='1' then
			UART.sample.counter<=(others=>'0');
			UART.sample.clk<='0';
		elsif rising_edge(clk50mhz) then
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
	reg_process:process(clk50mhz,reset) is
	begin
		if reset='1' then
			UART.rxs.last.state<=idle;
			UART.rxs.last.bits<=(others=>'0');
			UART.rxs.last.nbits<=(others=>'0');
			UART.rxs.last.enable<='0';
			UART.txs.last.state<=idle;
			UART.txs.last.bits<=(others=> '1');
			UART.txs.last.nbits<=(others=> '0');
			UART.txs.last.ready<='1';
		elsif rising_edge(clk50mhz) then
			UART.rxs.last<=UART.rxs.current;
			UART.txs.last<=UART.txs.current;
		end if;
	end process;
	-- RX FSM
	rx_process:process(UART.rxs.last.state,UART.sample.clk,UART.rx.buff) is
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
							UART.rxs.current.state<=idle; -- back to idle state to wait for next start bit
							UART.rxs.current.enable<='1'; -- OK if stop bit is '1'
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
	rx_output:process(UART.rxs.last) is
	begin
		UART.rx.enable<=UART.rxs.last.enable;
		UART.rx.data<=UART.rxs.last.bits;
	end process;
	-- TX FSM
	tx_process:process(UART.txs.last,UART.sample.clk,UART.tx.enable,UART.tx.data) is
	begin
		case UART.txs.last.state is
			when idle=>
				if UART.tx.enable='1' then
					-- start a new bit
					UART.txs.current.bits<=UART.tx.data & '0';  -- data & start
					UART.txs.current.nbits<="1010"; -- send 10 bits (includes '1' stop bit)
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
	tx_output:process(UART.txs.last) is
	begin
		UART.tx.ready<=UART.txs.last.ready;
		UART.tx.buff<=UART.txs.last.bits(0);
	end process;
	-- SIM output
	SIM_vars.UART<=UART;
end arc;
