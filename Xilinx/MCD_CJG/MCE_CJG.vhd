----------------------------------------------------------------------------------
-- Engineer:			 Chandler Griscom
-- 
-- Create Date:		17:24:05 02/01/2017 
-- Module Name:		MCE_CJG - Behavioral 
-- Project Name:	 Microcomputer Design
-- Target Devices: XC9572-7PC84
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity MCE_CJG is
		Port (	A2					: in		Std_Logic_Vector(2 downto 0); -- A22, A21, A20
					A23				: in		STD_LOGIC;
					CPU_AS			: in		STD_LOGIC;
					CPU_BERR			: out		STD_LOGIC;
					CPU_BG			: in		STD_LOGIC;
					CPU_BGACK		: out		STD_LOGIC;
					CPU_BR			: out		STD_LOGIC;
					CPU_CLK			: out		STD_LOGIC;
					CPU_DTACK		: out		STD_LOGIC;
					CPU_HALT			: inout	STD_LOGIC;
					CPU_IPL0			: out		STD_LOGIC;
					CPU_IPL1			: out		STD_LOGIC;
					CPU_IPL2			: out		STD_LOGIC;
					CPU_LDS			: in		STD_LOGIC;
					CPU_RESET		: inout	STD_LOGIC;
					CPU_RW			: in		STD_LOGIC;
					CPU_UDS			: in		STD_LOGIC;
					D					: inout	unsigned(7 downto 0);
					DUART_CLK		: in		STD_LOGIC;
					DUART_CS			: out		STD_LOGIC;
					DUART_DTACK		: in		STD_LOGIC;
					DUART_IACK		: out		STD_LOGIC;
					DUART_IRQ		: in		STD_LOGIC;
					DUART_OP4		: in		STD_LOGIC;
					DUART_OP5		: in		STD_LOGIC;
					DUART_OP6		: in		STD_LOGIC;
					DUART_OP7		: in		STD_LOGIC;
					DUART_RESET		: out		STD_LOGIC;
					DUART_RW			: out		STD_LOGIC;
					FC0				: in		STD_LOGIC; -- Was GPIO_A
					FC1				: in		STD_LOGIC; -- Was GPIO_B
					FC2				: in		STD_LOGIC; -- Was GPIO_C
					GPO				: out		unsigned(7 downto 0); -- Was GPIO 7-0, 7-5 may contain A22-20
					GPI				: in		unsigned(3 downto 0); -- Was GPIO 11-8
					GPIO_IPL0		: in		STD_LOGIC; -- Was GPIO_12 -- Active High
					GPIO_IACK		: inout	STD_LOGIC; -- Was GPIO_13 -- Active High
					GPIO_AS			: inout	STD_LOGIC; -- Was GPIO_14 -- Active High
					GPIO_DTACK		: in		STD_LOGIC; -- Was GPIO_15 -- Active High
					Q2_Clock			: in		STD_LOGIC;
					Q2_Enable		: out		STD_LOGIC;
					RAM_CE			: out		STD_LOGIC;
					RAM_LB			: out		STD_LOGIC;
					RAM_OE			: out		STD_LOGIC;
					RAM_UB			: out		STD_LOGIC;
					RAM_WE			: out		STD_LOGIC;
					Reset_In			: in		STD_LOGIC;
					ROM_CE			: out		STD_LOGIC;
					ROM_OE			: out		STD_LOGIC;
					ROM_WE			: out		STD_LOGIC;
					Speaker			: out		STD_LOGIC);
end MCE_CJG;

architecture Behavioral of MCE_CJG is
	signal power_on		: STD_LOGIC := '0'; -- 0 until reset is pressed
	signal data_out		: unsigned(7 downto 0);
	signal CPLD_mask		: unsigned(4 downto 0)  := "00000";
	signal GPIO_Buf1		: unsigned(7 downto 0)  := (others=>'0');
	signal prescaler_cpu : STD_LOGIC := '0';
	signal prescaler_irq : unsigned(14 downto 0) := (others=>'0');
	signal reset_db      : STD_LOGIC := '1';
	signal hotswap_db    : STD_LOGIC := '0';
	signal hotswap_xor   : STD_LOGIC := '0';
	signal RAM_STROBE		: STD_LOGIC;
	signal ROM_STROBE		: STD_LOGIC;
	signal DUART_STROBE	: STD_LOGIC;
	signal IPL6				: STD_LOGIC := '1'; -- Signal that indicates a high-level interrupt req
	signal CPU_CLK_pre	: STD_LOGIC;
	signal CPU_CLK_pre2	: STD_LOGIC;
	signal speaker_pre	: STD_LOGIC;
	signal CPU_IACK_ah	: STD_LOGIC;
	signal GPIO_IACK_ah	: STD_LOGIC;
	signal DUART_IACK_ah	: STD_LOGIC;
	signal IPL6_IACK_ah	: STD_LOGIC;
	signal was_IPL6      : STD_LOGIC := '1';
begin

-- CPLD MASK --
--      4          3       2              1             0
-- ROM_Hotswap    Spk  Reset_UART  En_GPI_FlowCtrl  Storage  

CPU_IACK_ah <= FC0 and FC1 and FC2;
IPL6_IACK_ah <= CPU_IACK_ah and not IPL6;
DUART_IACK_ah <= CPU_IACK_ah and IPL6 and not DUART_IRQ;
GPIO_IACK_ah <= CPU_IACK_ah and IPL6 and DUART_IRQ and (CPLD_mask(1) and GPIO_IPL0);

setlevelrecord: process (CPU_IACK_ah) begin
	if rising_edge(CPU_IACK_ah) then
		-- Preserve CPLD-driven interrupt levels to they can be vectored properly
		if IPL6_IACK_ah = '1' then
			was_IPL6 <= '1';
		elsif GPIO_IACK_ah = '1' then
			was_IPL6 <= '0';
		end if;
	end if;
end process setlevelrecord;

-- Tri-State Data Bus Control
D <= data_out when ( (((A23 = '1' or A2 = "011") and CPU_RW = '1' and CPU_AS='0' and CPU_IACK_ah = '0') or IPL6_IACK_ah = '1' or GPIO_IACK_ah ='1')
					 and power_on = '1')
					 else (others=>'Z');

cpld_write: process (CPU_AS) begin
	if rising_edge(CPU_AS) then -- AS has just activated (CPU WRITES ON RISING EDGE)
		if (A23 = '0' and A2 = "011" and CPU_RW = '0' and power_on = '1') then -- Read 1XX0 - Mask   or  1XX1 - GPI
			CPLD_mask(1) <= D(1);
			CPLD_mask(2) <= D(2);
			CPLD_mask(3) <= D(3);
			CPLD_mask(4) <= D(4) xor hotswap_xor;
		elsif (A23 = '1' and CPU_RW = '0' and power_on = '1') then
			GPIO_Buf1(0) <= D(0);
			GPIO_Buf1(1) <= D(1);
			GPIO_Buf1(2) <= D(2);
			GPIO_Buf1(3) <= D(3);
			GPIO_Buf1(4) <= D(4);
			GPIO_Buf1(5) <= D(5);
			GPIO_Buf1(6) <= D(6);
			GPIO_Buf1(7) <= D(7);
		end if;
	end if;
end process cpld_write;

cpld_read: process (CPU_AS) begin
	if falling_edge(CPU_AS) then
		if (A23 = '0' and A2 = "011" and CPU_IACK_ah = '0') then
			data_out(0) <= '0';
			data_out(1) <= CPLD_mask(1);
			data_out(2) <= CPLD_mask(2);
			data_out(3) <= CPLD_mask(3);
			data_out(4) <= CPLD_mask(4) xor hotswap_xor;
			data_out(5) <= '0';
			data_out(6) <= '0';
			data_out(7) <= '0';
		elsif (A23 = '1' and CPU_IACK_ah = '0') then
			data_out(0) <= GPI(0);
			data_out(1) <= GPI(1);
			data_out(2) <= GPI(2);
			data_out(3) <= GPI(3);
			data_out(4) <= GPIO_IPL0;
			data_out(5) <= GPIO_IACK;
			data_out(6) <= GPIO_AS;
			data_out(7) <= GPIO_DTACK;
		else 
			-- Put interrupt vectors here, starts at 64
			data_out(0) <= was_IPL6; -- 64: GPIO, 65: IPL6
			data_out(1) <= '0';
			data_out(2) <= '0';
			data_out(3) <= '0';
			data_out(4) <= '0';
			data_out(5) <= '0';
			data_out(6) <= '1'; -- 64 plus xx
			data_out(7) <= '0';
		end if;
	end if;
end process cpld_read;

Q2_Enable <= '1';
CPU_BERR <= '1';
CPU_BR <= '1'; -- No bus requests
CPU_BGACK <= '1'; -- No bus grants... 5 hours worth of debugging here -_-
CPU_RESET <= '0' when reset_db='1' or power_on='0' else 'Z'; -- (0 until reset is hit)
CPU_HALT	<= '0' when reset_db='1' or power_on='0' else 'Z';  -- (0 until reset is hit)

DUART_RESET <= '0' when reset_db='1' or power_on='0' else not CPLD_mask(2); -- If mask 6 goes hi, reset duart

Speaker <= speaker_pre and CPLD_mask(3) and power_on; -- Pipe speaker clock to output pin if enabled (7)

-- DTACK, assuming no delays needed!
-- Altera says each case is guarenteed mutually exclusive
CPU_DTACK <= CPU_AS when (IPL6_IACK_ah or GPIO_IACK_ah) = '1' else -- Interrupts
		DUART_DTACK   when (DUART_IACK_ah = '1') else   -- DUART interrupt
		'1'  			  when CPU_AS = '1' else -- No address selected
		GPIO_DTACK    when A23 = '1' and CPLD_mask(0) = '1' else    -- Peripherals with flow control
		DUART_DTACK   when (A2 = "010") else   -- DUART
		'0';                                 -- ROM, RAM, CPLD-mask

ROM_STROBE	 <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "000" and power_on = '1' and CPU_IACK_ah = '0') else '0';
RAM_STROBE	 <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "001" and power_on = '1' and CPU_IACK_ah = '0') else '0';
DUART_STROBE <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "010" and power_on = '1' and CPU_IACK_ah = '0') else '0';

-- 50 ns delay between clock pulses
-- 70 ns delay for read cycle
ROM_CE <= '0' when ROM_STROBE = '1' else '1';
ROM_OE <= (not CPU_RW) when ROM_STROBE = '1' else '1';
ROM_WE <= CPU_RW when ROM_STROBE = '1' else '1';

-- 50 ns delay between clock pulses
-- 12 ns delay for read and write cycles
------- low on RW means write
RAM_CE <= '0' when RAM_STROBE = '1' else '1';
RAM_OE <= (not CPU_RW) when RAM_STROBE = '1' else '1';
RAM_WE <= CPU_RW when RAM_STROBE = '1' else '1';
RAM_LB <= CPU_LDS when RAM_STROBE = '1' else '1';
RAM_UB <= CPU_UDS when RAM_STROBE = '1' else '1';

DUART_CS <= not DUART_STROBE;
DUART_RW <= CPU_RW when DUART_STROBE = '1' else '1';

DUART_IACK <= not DUART_IACK_ah;

 -- Active high when enabled, else set to high impedance
GPIO_IACK  <= GPIO_IACK_ah when CPLD_mask(1) = '1' else 'Z';
GPIO_AS    <= (A23 and not CPU_AS and power_on) when CPLD_mask(1) = '1' else 'Z';

 -- Trigger interrupt; GPIO Level 2, DUART level 4, IPL6
CPU_IPL0 <= '1';
CPU_IPL1 <= IPL6 and not (CPLD_mask(1) and GPIO_IPL0 and DUART_IRQ);
CPU_IPL2 <= IPL6 and DUART_IRQ;

GPO <= GPIO_Buf1;

--------------20 MHZ CLOCK----------------
CPU_CLK <= CPU_CLK_pre2;

-- 20 MHz divider
gen_count : process (Q2_Clock)
begin
	if (rising_edge(Q2_Clock)) then
		if prescaler_cpu = '1' then -- Divides by a total of 4 with inversions
			CPU_CLK_pre <= not CPU_CLK_pre;
			if (hotswap_db = '0') then
				CPU_CLK_pre2 <= not CPU_CLK_pre2;
			else
				CPU_CLK_pre2 <= '0';
			end if;
		end if;
		prescaler_cpu <= not prescaler_cpu;
	end if;
end process gen_count;	

--------------end 20 MHZ CLOCK----------------

-- 20MHz sourcing
gen_irq : process (CPU_CLK_pre)
begin
	-- Generate periodic interrupt at 1000 Hz
	if rising_edge(CPU_CLK_pre) then
		if prescaler_irq = 19999 then
			prescaler_irq <= (others => '0');
			speaker_pre <= not speaker_pre; -- Invert speaker clock
			if Reset_In = '1' then
				if (CPLD_mask(4) xor hotswap_xor) = '1' then
					hotswap_db <= '1';
				else
					if reset_db = '0' then
						power_on <= not power_on;
					end if;
					reset_db <= '1';
				end if;
			else
				if hotswap_db = '1' then
					hotswap_xor <= not hotswap_xor; -- Notifies CPU that hotswap is complete
				end if;
				reset_db <= '0';
				hotswap_db <= '0';
				IPL6 <= '0'; -- Trigger interrupt if not resetting
			end if;
		else
			if (CPU_IACK_ah='1' and CPU_AS = '1') then
				-- IACK recieved AND finished cycle; clear interrupt requests
				IPL6 <= '1';
			end if;
			prescaler_irq <= prescaler_irq + "1";
		end if;
	end if;
end process gen_irq;

end Behavioral;
