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
					CPU_BGACK		: in		STD_LOGIC;
					CPU_BR			: out		STD_LOGIC;
					CPU_CLK			: out		STD_LOGIC;
					CPU_DTACK		: out		STD_LOGIC;
					CPU_HALT			: out		STD_LOGIC;
					CPU_IPL0			: out		STD_LOGIC;
					CPU_IPL1			: out		STD_LOGIC;
					CPU_IPL2			: out		STD_LOGIC;
					CPU_LDS			: in		STD_LOGIC;
					CPU_RESET		: out		STD_LOGIC;
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
	signal CPLD_mask		: unsigned(7 downto 0)  := "00000101"; -- Pattern for testing
	signal GPIO_Buf1		: unsigned(7 downto 0)  := (others=>'0');
	signal prescaler_cpu : unsigned(1 downto 0)  := (others=>'0');
	signal prescaler_irq : unsigned(16 downto 0) := (others=>'0');
	signal RAM_STROBE		: STD_LOGIC;
	signal ROM_STROBE		: STD_LOGIC;
	signal DUART_STROBE	: STD_LOGIC;
	signal IRQ7				: STD_LOGIC := '1'; -- Signal that indicates a high-level interrupt req
	signal CPU_CLK_pre	: STD_LOGIC;
	signal speaker_pre	: STD_LOGIC;
begin

-- CPLD MASK --
--     7       6             5               4           3          2          1          0
--    Spk  Reset_UART  En_GPI_FlowCtrl  En_GPO_Addr  En_GPO0_CLK

-- Tri-State Data Bus Control.... double check the RW condditions
D <= data_out when ((A23 = '1' or A2 = "011") and CPU_RW = '1') else (others=>'Z');

cpld_write: process (CPU_AS) begin
	if falling_edge(CPU_AS) then -- AS has just activated
		if (A23 = '0' and A2 = "011" and CPU_RW = '0') then -- Read 1XX0 - Mask   or  1XX1 - GPI
			CPLD_mask <= D;
		elsif (A23 = '1' and CPU_RW = '0') then
		   if CPLD_mask(3) = '1' then -- Expose clock
			   GPIO_Buf1(0) <= CPU_CLK_pre;
			else
				GPIO_Buf1(0) <= D(0);
			end if;
			GPIO_Buf1(1) <= D(1);
			GPIO_Buf1(2) <= D(2);
			GPIO_Buf1(3) <= D(3);
			GPIO_Buf1(4) <= D(4);
			if CPLD_mask(4) = '1' then -- Expose address
				GPIO_Buf1(5) <= A2(0);
				GPIO_Buf1(6) <= A2(1);
				GPIO_Buf1(7) <= A2(2);
			else
				GPIO_Buf1(5) <= D(5);
				GPIO_Buf1(6) <= D(6);
				GPIO_Buf1(7) <= D(7);
			end if;
		end if;
	end if;
end process cpld_write;

cpld_read: process (CPU_AS) begin
	if falling_edge(CPU_AS) then
		if (A23 = '0' and A2 = "011" and CPU_RW = '1') then
			data_out <= CPLD_mask; -- TODO expendable
		elsif (A23 = '1' and CPU_RW = '1') then
			data_out(0) <= GPI(0);
			data_out(1) <= GPI(1);
			data_out(2) <= GPI(2);
			data_out(3) <= GPI(3);
			data_out(4) <= GPIO_IPL0;
			data_out(5) <= GPIO_IACK;
			data_out(6) <= GPIO_AS;
			data_out(7) <= GPIO_DTACK;
		else 
			data_out <= (others=>'0');
		end if;
	end if;
end process cpld_read;

Q2_Enable <= '1';
CPU_BERR <= '1'; -- No bus errors here!
CPU_BR <= '1'; -- No bus requests
CPU_CLK <= CPU_CLK_pre;
CPU_RESET <= power_on; -- (0 until reset is hit)
CPU_HALT	<= power_on;  -- (0 until reset is hit)

DUART_RESET <= power_on and not CPLD_mask(6); -- If mask 6 goes hi, reset duart

Speaker <= speaker_pre and CPLD_mask(7); -- Pipe speaker clock to output pin if enabled (7)

ROM_STROBE	 <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "000") else '0';
RAM_STROBE	 <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "001") else '0';
DUART_STROBE <= '1' when (CPU_AS = '0' and A23 = '0' and A2 = "010") else '0';

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

DUART_IACK <= not (FC0 and FC1 and FC2);

 -- Active high when enabled, else set to high impedance
GPIO_IACK  <= (FC0 and FC1 and FC2) when CPLD_mask(5) = '1' else 'Z';
GPIO_AS    <= (A23 and not CPU_AS) when CPLD_mask(5) = '1' else 'Z';

 -- Trigger interrupt; DUART gets level 6, plus optional add CPIO IPLs
CPU_IPL0 <= IRQ7 and not (CPLD_mask(5) and GPIO_IPL0);
CPU_IPL1 <= IRQ7 and DUART_IRQ;
CPU_IPL2 <= IRQ7 and DUART_IRQ;

GPO <= GPIO_Buf1;

-- Use reset button to toggle power on
resetbutton : process (Reset_In)
begin
	if rising_edge(Reset_In) then
		power_on <= not power_on;
	end if;
end process resetbutton;

gen_clk : process (Q2_Clock)
begin
	if (rising_edge(Q2_Clock)) then -- This CPLD doesn't support dual edge triggering
		if prescaler_cpu = "11" then -- Generate 10Mhz CPU clock
			prescaler_cpu <= "00";
			CPU_CLK_pre <= not CPU_CLK_pre;
		else
			prescaler_cpu <= prescaler_cpu + "1";
		end if;
	end if;
end process gen_clk;

gen_dtack : process (CPU_CLK_pre)
begin
	-- Generate DTACK delays
	-- TODO check if rising or falling edge is better
	if falling_edge(CPU_CLK_pre) then
		if CPU_AS = '0' then
			---if A23 = '0' and A2 = "000" then -- ROM  elsif
				
			if A23 = '0' and A2 = "010" then -- DUART
				CPU_DTACK <= DUART_DTACK;
			elsif A23 = '1' then -- Peripherals
				CPU_DTACK <= not GPIO_DTACK;
			else
				-- ROM: it looks like it takes 2 clock cycles after AS that the CPU latches.
				-- Instant will probably be fine for both rom and ram, but try later.
				CPU_DTACK <= '0'; -- RAM and CPLD ops
			end if;
		else 
			CPU_DTACK <= '1';
		end if;
	end if;
end process gen_dtack;
	
gen_irq : process (Q2_Clock)
begin
	-- Generate periodic interrupt at 1000 Hz
	if rising_edge(Q2_Clock) then
		if prescaler_irq = 79999 then
			prescaler_irq <= (others => '0');
			IRQ7 <= '0'; -- Request interrupt
			speaker_pre <= not speaker_pre; -- Invert speaker clock
		else
			if (FC0='1' and FC1='1' and FC2='1') then
				-- IACK recieved; clear interrupt requests
				IRQ7 <= '1';
			end if;
			prescaler_irq <= prescaler_irq + "1";
		end if;
	end if;
end process gen_irq;

end Behavioral;

