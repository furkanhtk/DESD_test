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
		switches	:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Besys3
		count_pulse	:	OUT	STD_LOGIC									-- signal which pulses when kit has to shift
		----------------------------

	);

end PulseGenerator;

architecture Behavioral of PulseGenerator is


	------------------ CONSTANT DECLARATION -------------------------

    ---------- TIMER -----------
	constant RANGE_COUNT_DTO		: positive		:= ((MIN_KITT_CAR_STEP_MS*1000000)/CLK_PERIOD_NS);

	-- RANGE_COUNT_FINE to RANGE_COUNT_DTO
	-- Implemantation
	-- number of counter's steps to reach teh Dt0
    
	
	constant RANGE_COUNT_SPEED		: positive		:= 2**NUM_OF_SWS -1;


	-- RANGE_COUNT_COARSE to RANGE_COUNT_SPEED
	-- max number that can be set throught the switches


	---------------------------- SIGNALS ----------------------------

	----- Counter Registers ----
	signal	count_dto		:	integer	range	0	to	RANGE_COUNT_DTO-1		:= 0;


	-- count_fine to count_dto
	-- counter that counts until Dt0
	
	signal	count_speed	:	integer	range	0	to	RANGE_COUNT_SPEED-1	:= 0;

	-- count_coarse to count_speed
	-- counter that counts the Dt0 until the number of Dt0 selected throught the switches

	signal	speed_input	   :	integer	range	0	to	RANGE_COUNT_SPEED-1	:= 1;

	-- select_speed	to speed_input
	-- sample signal of the value of the unsigned selected throught the switches
	
	signal	speed_input_reg1   :	integer	range	0	to	RANGE_COUNT_SPEED-1	:= 1;
	signal	speed_input_reg2   :	integer	range	0	to	RANGE_COUNT_SPEED-1	:= 1;



	--speed_input_reg to speed_input_reg1
    -- sample signal of the value of the unsigned selected throught the switches, registered for stability

	----------------------------------------------------------------



begin
	----------------------------- PROCESS ------------------------------

	------ Pulse Process --------
	process(rst, clk)

	begin

		-- rst
		if rst = '1' then
			count_dto			<= 0;
			count_speed		    <= 0;
			count_pulse			<= '0';

			speed_input     	<= 1;
			speed_input_reg1 	<= 1;
			speed_input_reg2 	<= 1;

		elsif rising_edge(clk) then

			-- Sample switches to guarantee stable on rising_edge(clk)
			--we are thinking about using 3 registered signals, just to show off 
			-- Because of the bouncing problem
			speed_input	    	<= to_integer(unsigned(switches));
			speed_input_reg1    <= speed_input;
			speed_input_reg2    <= speed_input_reg1;





			-- Count the clock pulses (fine)
			count_dto	<= count_dto +1;

			-- Count the overflow of count_dto (MIN_KITT_CAR_STEP_MS)
			count_pulse	<= '0';

			if count_dto = RANGE_COUNT_DTO-1 then 
				--if the minimum steps' counter reaches overflow, the Dt0 counter adds +1
				count_dto		<= 0;
				count_speed	<= count_speed	+1;

				-- Count the overflow of count_speed (MIN_KITT_CAR_STEP_MS*switches)
				if count_speed = speed_input then 
					--if the #N Dt0 counter reaches overflow, syn goes to 1
					count_speed	    	<= 0;
					count_pulse			<= '1';
				end if;

			end if;

			-- Restart, rst settings
			if speed_input_reg1 /= speed_input_reg2 then 
				--go back to lines 141,142: if the two values are different, we have a rst ( I (Laura) have a doubt)
				count_dto			  <= 0;
				count_speed   		  <= 0;
				count_pulse           <= '0';
			end if;

		end if;

	end process;

end Behavioral;