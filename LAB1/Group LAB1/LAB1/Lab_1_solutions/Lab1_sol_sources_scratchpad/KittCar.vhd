
---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
--	use IEEE.MATH_REAL.all;
------------------------------------


---------- OTHERS LIBRARY ----------
-- NONE
------------------------------------


entity KittCar is
	Generic(

		NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	-- Leds used  over the 16 in Basys3

	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		---------- Speed -----------
		sync	:	IN	STD_LOGIC;		-- Set the speed
		----------------------------

		----- One Only Kitt --------
		kitt_car	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Besys3
		----------------------------

	);
end KittCar;

architecture Behavioral of KittCar is


	------------------ CONSTANT DECLARATION -------------------------

	---------- INIT ------------
	constant	KITT_CAR_RIGHT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := std_logic_vector(to_unsigned(2**(kitt_car'RIGHT), kitt_car'LENGTH));	-- 10...0
	constant	KITT_CAR_LEFT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := std_logic_vector(to_unsigned(2**(kitt_car'LEFT), kitt_car'LENGTH));		-- 0...01

	constant	KITT_CAR_INIT	:	STD_LOGIC_VECTOR(kitt_car'RANGE) := KITT_CAR_RIGHT;
	----------------------------

	-----------------------------------------------------------------



	------------------------ TYPES DECLARATION ----------------------

	--------- SECTION ----------
	-- NONE
	----------------------------

	-----------------------------------------------------------------


	---------------------------- SIGNALS ----------------------------

	---- Kitt Car Registers ----
	signal	kitt_car_reg		:	STD_LOGIC_VECTOR(kitt_car'RANGE)	:= KITT_CAR_INIT; --valore registrato della poi uscita sui led --registerd value of what will be the output on the led
	signal	direction			:	STD_LOGIC	:=	'1';  		--boolean che definisce la direzione del led 0 destra, 1 sinistra
	----------------------------								--boolean that defines the direction of the movement of the led: if 0 the "light" goes to the right, if 1 it goes to the left

	----------------------------------------------------------------



begin


	--------------------- COMPONENTS INSTANTIATIONS -------------------
	-- NONE
	-------------------------------------------------------------------



	----------------------------- DATA FLOW ---------------------------
	
	-- we use a registered output for two reasons:

	-- 1.when my module is used as a driver, i don't know what they are going to put at the output, so I have to put a buffer
	-- 2.bouncing broblem

	------ Output KittCar ------
	kitt_car    <= kitt_car_reg;
	----------------------------

	-------------------------------------------------------------------



	----------------------------- PROCESS ------------------------------

	------ Sync Process --------
	process(reset, clk)

	begin

		-- Reset
		if reset = '1' then
			kitt_car_reg		<= KITT_CAR_INIT; --noi resetteremo anche la direzione giusto per farlo diverso
													--could be smart to reset the position, just to add a little difference. Should we aske if there is a project spesification about the reset?


		elsif rising_edge(clk) then


			-- Execute the Shift
			if sync = '1' then   --IMPLEMENTARE LO SHIFT CON UN MODULO GIÀ SCRITTO DAI COJONI...GIUSTO PER  --we can copy the shift register from the istructor's

				-- Rigth shift *left, coglioni --it's actually left, not right --VOLENDO POTREMMO ANCHE METTERE IL CONTROLLO PRIMA DELLO SHIFT PER DISTINGURECI DAI CCOJONI--to make something differente we could put the control before the shift section
				if direction = '1' then
					kitt_car_reg	<= kitt_car_reg(NUM_OF_LEDS-2 downto 0)&"0"; --padding dello shif a sinistra, padding to the left

				-- Left shift *vedi su, so here it is right
				elsif direction = '0' then
					kitt_car_reg	<= "0"&kitt_car_reg(NUM_OF_LEDS-1 downto 1);

				end if;

				-- Set direction and overwrite for out of bounding
				-- la parte sopra scrive lo shift anche se out of bounds e questa sotto se out of bounds lo sovrascrive giusto, vedi signal commit
				-- the upper section executes the shfit also if it is out of bounds, while the bottom section if the shift is out of bound overwrites it correctly, go back to signal commit, too
				if(kitt_car_reg = KITT_CAR_LEFT) then --to handle bouncing, otherwise it would stay on 0 an 15 for a cycle more than needed
					direction	<= '0';
					kitt_car_reg	<= "0"&kitt_car_reg(NUM_OF_LEDS-1 downto 1);

				elsif(kitt_car_reg = KITT_CAR_RIGHT) then
					direction	<= '1';
					kitt_car_reg	<= kitt_car_reg(NUM_OF_LEDS-2 downto 0)&"0";


				end if;



			end if;


		end if;

	end process;

	----------------------------

	-------------------------------------------------------------------


end Behavioral;
