
---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
--	use IEEE.MATH_REAL.all;
------------------------------------


---------- OTHERS LIBRARY ----------
-- NONE
------------------------------------


entity TailGenerator is

	Generic(

		TAIL_LENGTH	:	INTEGER	RANGE	1 TO 16	:= 4	-- Teil length in bit

	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;		-- Aync reset
		clk		:	IN	STD_LOGIC;		-- Clock
		----------------------------

		-------- Input/Output -------
		sync		:	IN	STD_LOGIC;	-- Sync Speed from KittCar
		kitt_car	:	IN	STD_LOGIC;	-- Input from standard KittCar module in clk domain

		tail		:	OUT	STD_LOGIC	-- Outut with PWM modulated for the tail effect
		-----------------------------

	);
end TailGenerator;

architecture Behavioral of TailGenerator is

	------------------------ TYPES DECLARATION ----------------------

	-------- TAIL TYPE ---------
	type	TAIL_ARRAY_TYPE	is	array(0 TO TAIL_LENGTH-1)	of	INTEGER	RANGE 1 TO TAIL_LENGTH;
	----------------------------

	-----------------------------------------------------------------



	-------------------- FUNCTION DEFINITION ------------------------

	------- COMPUTE TAIL -------
	function DefineTail return TAIL_ARRAY_TYPE is

		variable	tail_array_tmp	:	TAIL_ARRAY_TYPE; --un array di integers lungo quanto la coda --array of integer long as the tail

	begin

		for I in tail_array_tmp'RANGE loop    			-- i si muove da 0 a lunghezza coda -1  --i goes from 0 to the tail's length
			tail_array_tmp(I) := TAIL_LENGTH -1; 		-- inizializza tutti gli integer alla lunghezza della coda -1 
		end loop;										-- initialize all the integer to tail's length-1

		return tail_array_tmp;							-- returna il vettore inizializzato es un vettore di 4 3  (3,3,3,3) per una coda lunga 4
														-- it returns the value initialized -> ex. a vector of four 3 (3,3,3,3) for a tail of length 4
	end function;
	----------------------------


	-----------------------------------------------------------------



	------------------ CONSTANT DECLARATION -------------------------

	-------- SET TAIL ----------
	constant	Tail_Array	:	TAIL_ARRAY_TYPE	:= DefineTail; 	--INIZIALIZZEREMO LA COSTANTE SENZA STA CAZZO DE FUNZIONE CHE TANTO NUN DOVREMO SAPÈ FA 
	----------------------------								-- we cannot use functions, so we will use constants!


	------ SETTINGS PWM --------
	constant	BIT_LENGTH	:	INTEGER	RANGE	1 TO 16	:= 4;	-- Bit used  in PWM 
	--usa il minimo numero di bit che hanno senso per 16 led, la risoluzione è 1/16 di periodo...
	--it uses the minimum number of bit which makes sense for 16 leds, the resolution is 1/16 of the period
	constant	T_ON_INIT	:	POSITIVE	:= 1;				-- Init Ton off
	--il pwm è inizializzato a 1 che risulta in elettrocardiogramma piatto perchè il pwm è imperfetto, questo vogliono dire con "off", un po' criptico ma pazienza
	--the pwm is initialized at 1. They are using the imperfect pwm, the one which, when the duty cycle is nominally 100%, is actually leaving a zero for a clk cycle. So with T_ON_INIT '1', the rel duty cycle is 0%.
	-- This is why the wrote "init ton off".
	constant	PERIOD_INIT	:	POSITIVE	:= TAIL_LENGTH;		-- Init Period at TAIL_LENGTH
	--il periodo è letteralmente la lunghezza della coda, sono andati sul semplice: dice 3/4 alto => 3 clock su e uno giù, come l'antichi
	--the period is literally the tail's length, they went for a simple solution: when the duty cycle has to be 3/4, they will keep the signal high for 3 clk cycle, down for 1 clk.
	constant	PWM_INIT	:	STD_LOGIC	:= '1';				-- Init Ton at '1'
	--parte da uno --it starts from 1


	constant	PERIOD_SLV	:	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0)	:= std_logic_vector(to_unsigned(TAIL_LENGTH-1,BIT_LENGTH));
	-- smart way to handle the resolution. For example: if we have a tail of 7, they pass 6 since the counter in the pwm will count from 0 to 6.
	-- in this way we use only the needed resolution
	----------------------------




	-----------------------------------------------------------------



	--------------------- COMPONENTS DECLARETION --------------------

	---------- PWM -------------

	Component PulseWidthModulator is
		Generic(

			BIT_LENGTH	:	INTEGER	RANGE	1 TO 16;	-- Bit used  inside PWM

			T_ON_INIT	:	POSITIVE;					-- Init of Ton
			PERIOD_INIT	:	POSITIVE;					-- Init of Periof

			PWM_INIT	:	STD_LOGIC					-- Init of PWM

		);
		Port (

			------- Reset/Clock --------
			reset	:	IN	STD_LOGIC;
			clk		:	IN	STD_LOGIC;
			----------------------------

			-------- Duty Cycle ----------
			Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk at PWM = '1'
			Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk per period of PWM

			PWM		:	OUT	STD_LOGIC		-- PWM signal
			----------------------------

		);
	end Component;

	----------------------------

	-----------------------------------------------------------------





	--------------------- SIGNLAS DECLARETION ----------------------

	------------ PWM ------------
	signal	Ton		:	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);
	signal	Period	:	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);

	signal	PWM		:	STD_LOGIC; -- coming from pwm component output, see line 197
	----------------------------

	----------- Tail -----------
	signal	Tail_Array_Index	:	INTEGER	RANGE 0 TO PERIOD_INIT; --TODO change the name of tail_array_index in period

	signal	Kitt_Car_reg		:	STD_LOGIC;
	----------------------------


	-----------------------------------------------------------------

begin



	-------------------- COMPONENTS INSTANTIATIONS --------------------


	---------- PWM -------------

	Inst_PulseWidthModulator	:	PulseWidthModulator
	Generic Map( 

		BIT_LENGTH	=>	BIT_LENGTH,

		T_ON_INIT	=>	T_ON_INIT,
		PERIOD_INIT	=>	PERIOD_INIT,

		PWM_INIT	=>	PWM_INIT

	)
	Port Map(

		------- Reset/Clock --------
		reset	=>	reset,
		clk		=>	clk,
		----------------------------

		-------- Duty Cycle ----------
		Ton		=>	Ton,
		Period	=>	Period,

		PWM		=>	PWM
		----------------------------

	);

	----------------------------

	-----------------------------------------------------------------




	----------------------------- DATA FLOW ---------------------------

	--------- PWM-TAIL ---------

	Ton		<= std_logic_vector(to_unsigned(Tail_Array_Index,BIT_LENGTH));	-- Write Ton in PWM, TODO change the name of tail_array_index in period. Ton is tail array index.
																			-- Tail array index is at 100% whne the head of kitt carr arrives and the decrements every led shift by 1. On the pwm it is reduces by 1/period
	Period	<= PERIOD_SLV;													-- Set the period Constant to PERIOD_INIT = TAIL_LENGTH-1

	Tail	<= PWM;															-- Put the PWM output as output of the module
	----------------------------

	-------------------------------------------------------------------





	----------------------------- PROCESS ------------------------------

	------ Sync Process --------
	process(reset,clk)
	begin

		if reset = '1' then
			Tail_Array_Index	<= 0;
			kitt_car_reg		<= '0';


		elsif rising_edge(clk) then

			-- remember we have a tail generator for each led!
			-- Move the Tail each synch pulse
			if sync = '1' then --the tail has to shift by one

				if Tail_Array_Index > 0  and Tail_Array_Index <= TAIL_LENGTH then
					Tail_Array_Index	<= Tail_Array_Index -1; --it gives us

				else
					Tail_Array_Index	<= 0;

				end if;

			end if;
			-- Set at 1 Tail_Array_Index each rising edge of kitt_car (0 -> 1)
			kitt_car_reg	<= kitt_car;

			if (kitt_car_reg = '0' and kitt_car = '1') then
				Tail_Array_Index	<= TAIL_LENGTH;
			end if;

		end if;

	end process;
	----------------------------


	----- Async Process --------
	-- NONE
	----------------------------


	--------- SECTION ----------
	-- NONE
	----------------------------

	-------------------------------------------------------------------






end Behavioral;
