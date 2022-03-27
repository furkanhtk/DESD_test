---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------


entity PulseGenerator is
	Generic(

		CLK_PERIOD_NS			:	positive    range	1	to	100;	-- clk Period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	positive	range	1	to	2000;	-- min step period in milliseconds
		
		NUM_OF_SWS		:	integer	range	1 to 16 := 16				-- Switches used over the 16 in Basys3

	);
	Port (

		------- rst/Clock --------
		rst     :	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		---------- Speed -----------
		SWs		    :	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Besys3
		count_pulse	:	OUT	STD_LOGIC									-- signal which pulses when kit has to shift
		----------------------------

	);

end PulseGenerator;

architecture Behavioral of PulseGenerator is


	------------------ CONSTANT DECLARATION -------------------------

    ---------- TIMER -----------
	constant RANGE_COUNT_FINE		: positive		:= ((MIN_KITT_CAR_STEP_MS*10)/CLK_PERIOD_NS);  		
	-- Simulation
	-- number of counter's steps to reach teh Dt0
    constant RANGE_COUNT_COARSE		: positive		:= 2**NUM_OF_SWS -1;
	-- max number that can be set throught the switches


	---------------------------- SIGNALS ----------------------------

	----- Counter Registers ----
	signal	count_fine		:	integer	range	0	to	RANGE_COUNT_FINE-1		:= 0;
	
	-- counter that counts until Dt0
	
	signal	count_coarse	:	integer	range	0	to	RANGE_COUNT_COARSE-1	:= 0;

	-- counter that counts the Dt0 until the number of Dt0 selected throught the switches

	signal	select_speed	   :	integer	range	0	to	RANGE_COUNT_COARSE-1	:= 1;
	
	-- sample signal of the value of the unsigned selected throught the switches
	
	signal	select_speed_reg   :	integer	range	0	to	RANGE_COUNT_COARSE-1	:= 1;
	
    -- sample signal of the value of the unsigned selected throught the switches, registered for stability

	----------------------------------------------------------------



begin
	----------------------------- PROCESS ------------------------------

	------ Pulse Process --------
	process(rst, clk)

	begin

		-- rst
		if rst = '1' then
			count_fine			<= 0;
			count_coarse		<= 0;
			count_pulse			<= '0';

			select_speed     	<= 1;
			select_speed_reg 	<= 1;


		elsif rising_edge(clk) then

			-- Sample SWs to guarantee stable on rising_edge(clk)
			--we are thinking about using 3 registered signals, just to show off 
			-- Because of the bouncing problem
			select_speed	    <= to_integer(unsigned(SWs));
			select_speed_reg    <= select_speed;




			-- Count the clock pulses (fine)
			count_fine	<= count_fine +1;

			-- Count the overflow of count_fine (MIN_KITT_CAR_STEP_MS)
			count_pulse	<= '0';

			if count_fine = RANGE_COUNT_FINE-1 then 
				--if the minimum steps' counter reaches overflow, the Dt0 counter adds +1
				count_fine		<= 0;
				count_coarse	<= count_coarse	+1;

				-- Count the overflow of count_coarse (MIN_KITT_CAR_STEP_MS*SWs)
				if count_coarse = select_speed then 
					--if the #N Dt0 counter reaches overflow, syn goes to 1
					count_coarse	    <= 0;
					count_pulse			<= '1';
				end if;

			end if;

			-- Restart, rst settings
			if select_speed /= select_speed_reg then 
				--go back to lines 141,142: if the two values are different, we have a rst ( I (Laura) have a doubt)
				count_fine			  <= 0;
				count_coarse   		  <= 0;
				count_pulse           <= '0';
			end if;

		end if;

	end process;

end Behavioral;
