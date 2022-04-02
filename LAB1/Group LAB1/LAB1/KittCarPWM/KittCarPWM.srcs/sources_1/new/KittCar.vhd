---------- DEFAULT LIBRARY ---------
--Instructors' solution adapted to our project.
--The main difference is that we created a differnt module (Pulse_counter) to read the switches and to count time.
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCar is

	Generic (

		NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	-- Number of output LEDs

	);
	Port (

		------- Reset/Clock --------
		rst		:	IN	STD_LOGIC;										--we called every reset -> rst
		clk		:	IN	STD_LOGIC;
		----------------------------

		count_pulse	:	IN 	STD_LOGIC;									--we handled the counter in a separate module
		kitt_car	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	--LEDs avaiable on Basys3
																		--we changed the name from leds to kitt_car
		----------------------------

	);
end KittCar;

architecture Behavioral of KittCar is


	------------------ CONSTANT DECLARATION -------------------------

	---------- INIT ------------
	constant	KITT_CAR_RIGHT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := '1' & (kitt_car'high-1 downto 0 => '0');	-- 10...0
	constant	KITT_CAR_LEFT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := (kitt_car'high downto 1 => '0') & '1';		-- 0...01
	constant	KITT_CAR_INIT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := KITT_CAR_RIGHT;
	----------------------------

	
	------------------------ TYPES DECLARATION ----------------------

	type direction_type is (MOVE_LEFT, MOVE_RIGHT);


	---------------------------- SIGNALS ----------------------------

	---- Kitt Car Registers ----
	
	signal	direction		:	direction_type					    :=	MOVE_LEFT;
	signal	kitt_car_reg	:	STD_LOGIC_VECTOR(kitt_car'RANGE)	:= 	KITT_CAR_INIT;
	----------------------------

	
begin


	--------------------- COMPONENTS INSTANTIATIONS -------------------
	-- NONE
	-------------------------------------------------------------------

	----------------------------- DATA FLOW ---------------------------

	------ Output KittCar ------
	kitt_car    <= kitt_car_reg;
	----------------------------

	----------------------------- PROCESS ------------------------------

	------ Sync Process -------- 
	process(rst, clk)

	begin

		if rising_edge(clk) then

			if rst = '1' then						--we have chosen to execute only synchronous reset in our project
				kitt_car_reg	<= KITT_CAR_INIT;
				direction		<= MOVE_LEFT;
				
			end if;

			-- Execute the Shift each go_kitt_car (MIN_KITT_CAR_STEP_MS*switches)
			if count_pulse = '1' then

				-- Shift to the left
				if direction = MOVE_LEFT then
					kitt_car_reg	<= kitt_car_reg(NUM_OF_LEDS-2 downto 0) & '0';

				-- Shift to the right
				elsif direction = MOVE_RIGHT then
					kitt_car_reg	<= '0' & kitt_car_reg(NUM_OF_LEDS-1 downto 1);

				end if;

				-- If reached the end, toggle the direction of the shift
				if kitt_car_reg(kitt_car_reg'high) = '1' then
					direction	<= MOVE_RIGHT;
					kitt_car_reg	<= '0' & kitt_car_reg(NUM_OF_LEDS-1 downto 1);

				elsif kitt_car_reg(0) = '1' then
					direction	<= MOVE_LEFT;
					kitt_car_reg	<= kitt_car_reg(NUM_OF_LEDS-2 downto 0) & '0';

				end if;

			end if;

		end if;

	end process;

end Behavioral;
