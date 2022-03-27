
---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
--	use IEEE.MATH_REAL.all;
------------------------------------


---------- OTHERS LIBRARY ----------
-- NONE
------------------------------------

entity SyncGenerator is
	Generic(

		SIMULATION_VS_IMPLEMENTATION    :   STRING(1 to 3) := "SIM";	-- "SIM" or "IMP"

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100;	-- clk Period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000;	-- min step period in milliseconds

		NUM_OF_SWS		:	INTEGER	RANGE	1 TO 16 := 16				-- Switches used over the 16 in Basys3

	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		---------- Speed -----------
		SWs		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Besys3
		sync	:	OUT	STD_LOGIC		-- segnale che pulsa quando kit deve shiftare -- signal which pulses when kit has to shift
		----------------------------

	);

end SyncGenerator;

architecture Behavioral of SyncGenerator is


	---------------------- FUNCTION DECLARATION ----------------------

	--------- Set Fine ----------
	function   set_range_count_fine(SIMULATION_VS_IMPLEMENTATION   :   STRING(1 to 3)) return POSITIVE is

		variable  RANGE_COUNT_FINE_IMP    :    POSITIVE    := ((MIN_KITT_CAR_STEP_MS*1000000)/CLK_PERIOD_NS);	-- Implementation
		variable  RANGE_COUNT_FINE_SIM    :    POSITIVE    := ((MIN_KITT_CAR_STEP_MS*10)/CLK_PERIOD_NS);  		-- Simulation

	begin


		if SIMULATION_VS_IMPLEMENTATION = "IMP" then
			return RANGE_COUNT_FINE_IMP;

		elsif SIMULATION_VS_IMPLEMENTATION = "SIM" then
			return RANGE_COUNT_FINE_SIM;

		else
			return  1;

		end if;

	end function;
	----------------------------

	-----------------------------------------------------------------


	------------------ CONSTANT DECLARATION -------------------------

    ---------- TIMER -----------
    constant RANGE_COUNT_FINE		: POSITIVE		:= set_range_count_fine(SIMULATION_VS_IMPLEMENTATION); 
	-- numero di incrementi del contatore per arrivare ad Dt0 -- number of counter's steps to reach teh Dt0
    constant RANGE_COUNT_COARSE		: POSITIVE		:= 2**NUM_OF_SWS -1;
	-- numero massimo rappresentabile dagli switch come input -- max number that can be set throught the switches
	-- 
    ----------------------------

    -----------------------------------------------------------------



	---------------------------- SIGNALS ----------------------------

	----- Counter Registers ----
	signal	count_fine		:	INTEGER	RANGE	0	TO	RANGE_COUNT_FINE-1		:= 0;
	-- contatatore che conta fino al passare di un Dt0 -- counter that counts until Dt0
	signal	count_coarse	:	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 0;
	-- contatore che conta i Dt0 fino al passare del numero di Dt0 selezionato con gli switch -- counter that counts the Dt0 until the number of Dt0 selected throught the switches

	signal	select_speed	   :	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 1;
	-- segnale di sample del valora unsigned rappresentato dagli switches -- sample signal of the value of the unsigned selected throught the switches
	signal	select_speed_reg   :	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 1;
	-- segnale di sample del valora unsigned rappresentato dagli switches registrato per stabilità -- sample signal of the value of the unsigned selected throught the switches, registered for stability

	----------------------------

	----------------------------------------------------------------



begin


	--------------------- COMPONENTS INSTANTIATIONS -------------------
	-- NONE
	-------------------------------------------------------------------



	----------------------------- DATA FLOW ---------------------------
	-- NONE
	-------------------------------------------------------------------



	----------------------------- PROCESS ------------------------------

	------ Sync Process --------
	process(reset, clk)

	begin

		-- Reset
		if reset = '1' then
			count_fine		<= 0;
			count_coarse	<= 0;
			sync			<= '0';

			select_speed     <= 1;
			select_speed_reg <= 1;


		elsif rising_edge(clk) then

			-- Sample SWs to guarantee stable on rising_edge(clk)
			-- NOI NE METTIAMO 3 E LO IMPLEMENTIAMO COME SHIFT DI UN ARRAY DI TRE PER FARE GI SBOROOONI --we are thinking about using 3 registered signals, just to show off 
			select_speed	    <= to_integer(unsigned(SWs));
			select_speed_reg    <= select_speed;

			-- Count the clock pulses (fine)
			count_fine	<= count_fine +1;



			-- Count the overflow of count_fine (MIN_KITT_CAR_STEP_MS)
			sync	<= '0';

			if count_fine = RANGE_COUNT_FINE-1 then --se il contatore di step minimi è all'overflow incrementiamo il contatore di Dt0 --if the minimum steps' counter reaches overflow, the Dt0 counter adds +1
				count_fine		<= 0;
				count_coarse	<= count_coarse	+1;

				-- Count the overflow of count_coarse (MIN_KITT_CAR_STEP_MS*SWs)
				if count_coarse = select_speed then --se il contatore di #N Dt0 per lo shift è in overflow sync si alza --if the #N Dt0 counter reaches overflow, syn goes to 1
					count_coarse	<= 0;
					sync			<= '1';
				end if;

			end if;

			-- Restart, reset settings
			if select_speed /= select_speed_reg then -- vedi linea 141,142 : se il controllo di valore oscillante fallisce lo considera non valido e resetta  --go back to lines 141,142: if the two values are different, we have a reset ( I (Laura) have a doubt)
				count_fine		<= 0;
				count_coarse   <= 0;
				sync           <= '0';
			end if;



		end if;

	end process;

	----------------------------

	-------------------------------------------------------------------


end Behavioral;
