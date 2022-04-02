library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_PulseGenerator is
end tb_PulseGenerator;

architecture Behavioral of tb_PulseGenerator is
 	-- CONSTANT DECLARATION 
	-- Timing 
	constant	CLK_PERIOD 	:	TIME	:= 10 ns;
	constant	RESET_WND	:	TIME	:= 10*CLK_PERIOD;
	-- TB Initialiazzations 
	constant	TB_CLK_INIT		:	STD_LOGIC	:= '0';
	constant	TB_RESET_INIT 	:	STD_LOGIC	:= '1';
	-- DUT Generics 
	constant	DUT_CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100		:=	10;
	constant	DUT_MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	20	TO	2000	:=	100;
	constant	DUT_NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16 := 4;	-- Switches used over the 16 in Basys3
-- DUT 
	component PulseGenerator
		Generic(
			CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100;	-- clk Period in nanoseconds
			MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	20	TO	2000;	-- min step period in milliseconds
			NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16		-- Switches used over the 16 in Basys3
		);
		Port (
			--standard signals
			rst		:	IN	STD_LOGIC;
			clk		:	IN	STD_LOGIC;
			--Speed signals
			switches		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);
			count_pulse		:	OUT	STD_LOGIC
		);
	end component;
	-- SIGNALS DECLARATION 
	-- Clock/Reset  
	signal	rst		:	STD_LOGIC	:= TB_RESET_INIT;
	signal	clk		:	STD_LOGIC	:= TB_CLK_INIT;
	-- LEDs/SWs 
	signal	dut_switches		:	STD_LOGIC_VECTOR(DUT_NUM_OF_SWS-1 downto 0);
	signal	dut_count_pulse		:	STD_LOGIC;
begin
	-- COMPONENTS DUT WRAPPING 
	-- DUT 
	dut_PulseGenerator	:	PulseGenerator
		Generic Map(
			CLK_PERIOD_NS			=> DUT_CLK_PERIOD_NS,
			MIN_KITT_CAR_STEP_MS	=> DUT_MIN_KITT_CAR_STEP_MS,
			NUM_OF_SWS				=> DUT_NUM_OF_SWS
		)
		Port Map(
			-- Reset/Clock 
			rst		=> rst,
			clk		=> clk,
			-- Speed 
			switches		=> dut_switches,
			count_pulse		=> dut_count_pulse
		);
	-- TEST BENCH DATA FLOW  
	-- clock 
	clk <= not clk after CLK_PERIOD/2;
	-- TEST BENCH PROCESS 
	---- Clock Process 
	-- clk_wave :process
	-- begin
		-- clk <= CLK_PERIOD;
		-- wait for CLK_PERIOD/2;
		-- clk <= not clk;
		-- wait for CLK_PERIOD/2;
    -- end process;
	--------------------------
	-- Reset Process --------
	reset_wave :process
	begin
		rst <= TB_RESET_INIT;
		wait for RESET_WND;

		rst <= not rst;
		wait;
    end process;

   -- Stimulus process 
    stim_proc: process
    begin
		-- waiting the reset wave
		dut_switches	<= std_logic_vector(to_unsigned(0,DUT_NUM_OF_SWS));
		wait for RESET_WND;
		-- Start
		dut_switches	<= std_logic_vector(to_unsigned(1,DUT_NUM_OF_SWS));
        -- Stop
		wait;
      wait;
    end process;
	

	
end Behavioral;




