--DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
--

entity KittCarPWM is
	Generic (
		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)
		NUM_OF_SWS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of output LEDs
		TAIL_LENGTH				:	INTEGER	RANGE	1 TO 16	:= 4	-- Tail length, only difference wrt the kitt car entity
	);
	Port (
		--standard signals
		reset   	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		-- LEDs/SWs 
		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
	);
end KittCarPWM;

architecture Behavioral of KittCarPWM is

	--SIGNALS
	signal	count_pulse	:	std_logic;						--takes the pulse form the pulse counter
    signal	head			:	std_logic_vector(LEDs'range);	--takes the head's position (full brightness LED) from the kittCarr component
	signal	tail	    	:	std_logic_vector(LEDs'range);	--takes the tail's information from the LEDcontroller component

	--COMPONENTS

	Component pulseGenerator is		--This component computes the time at which the head of the LEDs' array has to shift
		Generic(
			CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100;	
			MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000;
			NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16 := 16
		);
		Port(
			rst		:	IN	std_logic;
			clk		:	IN	std_logic;
			switches		: IN std_logic_vector(NUM_OF_SWS-1 downto 0);
			count_pulse		: OUT std_logic
		);

	end Component;

	Component LEDcontroller is		--This component handles PWM of each LED

		Generic(
			TailLength	:	INTEGER	RANGE	1 TO 16	:= 4			
		);
		Port(
			rst		:	IN	std_logic;
			clk		:	IN	std_logic;
			count_pulse		: IN	std_logic;
			head			: IN	std_logic;
			tail			: OUT	std_logic
		);

	end Component;

	Component KittCar is			--This component is the one which moves the head of the LEDs' array back and forth
		Generic(
			NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	
		);
		Port (
			rst		:	IN	std_logic;
			clk		:	IN	std_logic;
			count_pulse	:	IN	std_logic;
			kitt_car	:	OUT	std_logic_vector(NUM_OF_LEDS-1 downto 0)
		);
	end Component;

begin
		
	--INSTANTIATIONS
	pulsGen_inst: pulseGenerator
		Generic Map(
			CLK_PERIOD_NS           =>	CLK_PERIOD_NS,		
            MIN_KITT_CAR_STEP_MS    =>	MIN_KITT_CAR_STEP_MS,	
			NUM_OF_SWS				=>	NUM_OF_SWS		
		)
		Port Map(
			rst		=> reset,
			clk		=> clk,
			switches	=>	sw,
			count_pulse	=>	count_pulse
		);

	KittCar_inst	:	KittCar
		Generic Map(
			NUM_OF_LEDS	=> NUM_OF_LEDS
		)
		Port Map(
			rst	=>	reset,
			clk		=>	clk,
			count_pulse		=>	count_pulse,
			kitt_car	=>	head
		);

	LEDcontrollerGEN : for i in 0 to NUM_OF_LEDS-1 generate

		LEDcontroller_inst	: LEDcontroller
			Generic Map(
				TailLength	=>	TAIL_LENGTH	
			)
			Port Map(
				rst		=> reset,
				clk		=> clk,
				count_pulse		=>	count_pulse,
				head			=>	head(I),
				tail			=>	tail(I)
			);
	end generate;

	LEDs <= tail;

end Behavioral;
