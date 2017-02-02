----------------------------------------------------------------------------------
-- Engineer:       Chandler Griscom
-- 
-- Create Date:    17:24:05 02/01/2017 
-- Module Name:    MCE_CJG - Behavioral 
-- Project Name:   Microcomputer Design
-- Target Devices: XC9572-7PC84
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity MCE_CJG is
    Port ( A2          : in    Std_Logic_Vector(3 downto 0);
           CPU_AS      : in    STD_LOGIC;
           CPU_BERR    : out   STD_LOGIC;
           CPU_BG      : in    STD_LOGIC;
           CPU_BGACK   : in    STD_LOGIC;
           CPU_BR      : out   STD_LOGIC;
           CPU_CLK     : out   STD_LOGIC;
           CPU_DTACK   : out   STD_LOGIC;
           CPU_HALT    : out   STD_LOGIC;
           CPU_IPL0    : out   STD_LOGIC;
           CPU_IPL1    : out   STD_LOGIC;
           CPU_IPL2    : out   STD_LOGIC;
           CPU_LDS     : in    STD_LOGIC;
           CPU_RESET   : out   STD_LOGIC;
           CPU_RW      : in    STD_LOGIC;
           CPU_UDS     : in    STD_LOGIC;
           D           : inout Std_Logic_Vector(7 downto 0);
           DUART_CLK   : in    STD_LOGIC;
           DUART_CS    : out   STD_LOGIC;
           DUART_DTACK : in    STD_LOGIC;
           DUART_IACK  : out   STD_LOGIC;
           DUART_IRQ   : in    STD_LOGIC;
           DUART_OP4   : in    STD_LOGIC;
           DUART_OP5   : in    STD_LOGIC;
           DUART_OP6   : in    STD_LOGIC;
           DUART_OP7   : in    STD_LOGIC;
           DUART_RESET : out   STD_LOGIC;
           DUART_RW    : out   STD_LOGIC;
           FC0         : in    STD_LOGIC; -- Was GPIO_A
           FC1         : in    STD_LOGIC; -- Was GPIO_B
           FC2         : in    STD_LOGIC; -- Was GPIO_C
           GPIO        : inout Std_Logic_Vector(15 downto 0);
           Q2_Clock    : in    STD_LOGIC;
           Q2_Enable   : out   STD_LOGIC;
           RAM_CE      : out   STD_LOGIC;
           RAM_LB      : out   STD_LOGIC;
           RAM_OE      : out   STD_LOGIC;
           RAM_UB      : out   STD_LOGIC;
           RAM_WE      : out   STD_LOGIC;
           Reset_In    : in    STD_LOGIC;
           ROM_CE      : out   STD_LOGIC;
           ROM_OE      : out   STD_LOGIC;
           ROM_WE      : out   STD_LOGIC;
           Speaker     : out   STD_LOGIC);
end MCE_CJG;

architecture Behavioral of MCE_CJG is
  signal cpld_mask     : unsigned(7 downto 0);
  signal prescaler_cpu : unsigned(3 downto 0);
  signal prescaler_spk : unsigned(23 downto 0);
  signal div_speaker   : unsigned(23 downto 0);
  signal CPU_CLK_pre   : STD_LOGIC;
  signal speaker_pre   : STD_LOGIC;
  signal CPU_IACK      : STD_LOGIC;
begin

Q2_Enable <= '1';
CPU_CLK <= CPU_CLK_pre;
CPU_IACK <= not (FC0 and FC1 and FC2); -- IACK' from function code "111"
DUART_IACK <= CPU_IACK; -- TODO verify that this is OK

cpld_ops : Process (Q2_Clock) 
begin
	-- CPU_AS can possibly be used to make sure the address is actually being called
	-- by an application and not a CPU cycle artifact... put a top-level if statement?

	case A2 is
	  when "0000" =>
		 -- ROM
	  when "0001" =>
		 -- RAM
	  when "0010" =>
		 -- DUART
	  when "0011" =>
		 -- CPLD Masks
	  when others => 
		 -- Hrm
	end case;
end process cpld_ops;

gen_cpu : process (Q2_Clock) -- Generates CPU Freq
begin
  -- 8000000  9  "1001"
  -- 8888889  8  "1000"
  -- 10000000 7  "0111"
  -- 11428571 6  "0110"
  -- 13333333 5  "0101"
  -- 16000000 4  "0100"
  -- 20000000 3  "0011"
  if prescaler_cpu = "1001" then     -- Set this value to (80000000/freq_desired - 1)
    prescaler_cpu <= (others => '0');
    CPU_CLK_pre <= not CPU_CLK_pre;
  else
    prescaler_cpu <= prescaler_cpu + "1";
  end if;
end process gen_cpu;

gen_sound : process (Q2_Clock) -- Generates Speaker Freq
begin
  if prescaler_spk = div_speaker then
    prescaler_spk <= (others => '0');
    speaker_pre <= not speaker_pre;
  else
    prescaler_spk <= prescaler_spk + "1";
  end if;
end process gen_sound;


end Behavioral;

