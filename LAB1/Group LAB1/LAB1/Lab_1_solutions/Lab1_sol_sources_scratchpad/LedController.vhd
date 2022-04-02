--LIBRARIES NEEDED
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.NUMERIC_STD.ALL;
--
entity LegController is
	Generic(
		TailLength	:	integer	range 1 to 16   := 4	-- Tail length, can be tuned 
	);
	Port (
		--STANDARD SIGNALS
		rst	            :	in	std_logic;  --standard reset signal...
		clk		        :	in	std_logic;	--clock
		--
		count_pulse		:	in	std_logic;	--pulses when it's time to shift leds
		head        	:	in	std_logic;	--input, it comes from the kitt mdule, '1' when the head is @ this led, '0' otherwise
        tail		    :	out	std_logic	--output that goes to the led, will be '1' if this lead is head, pwmmed if on the tail, '0' otherwise
	);
end LegController;

architecture Behavioral of LegController is

	--TYPES DECLARATIONS
    type    TailOperationType is (ishead, intail, idle); --state machine type
    --CONSTANTS DECLARATIONS
	constant	PwmBits	        :	integer range 1 to 4 					:= 4;	--bits allocated to the pwm...just the minimum needed will be fine 
	constant	tonInit	        :	positive	                            := 1;   --pwm starts with a '1', not the default on given PWM module
	constant	PeriodInit	    :	positive	                            := TailLength;	
	constant	PwmInit			:	std_logic								:= '1';		-- init ton at '1'
	constant	CounterInit	    :	std_logic_vector(PwmBits-1 downto 0)	:= std_logic_vector(to_unsigned(TailLength-1,PwmBits)); --the counter inside the PWM will have to count up to TailLength-1

    --SIGNALS
	signal	ton					:	std_logic_vector(PwmBits-1 downto 0);	--signal to connect to the PWM module rapresenting the portion of the period to be on
	signal	Period				:	std_logic_vector(PwmBits-1 downto 0); 	--signal to connect to the PWM module rapresenting the period 
	signal	PWM					:	std_logic; 								--coming from pwm component output, pwm output signal
	signal	LedTailTon       	:	integer	range 0 to PeriodInit; 			--clycles the led has to be on with respect to pwm period
	signal	HeadReg				:	std_logic;								--registered value of the kitt car head, needed to verify if the led BECAME a head 
    signal  TailOperation 		: 	TailOperationType := idle;				--tail STATE variable

    --COMPONENTS
	Component PulseWidthModulator is
		Generic(
			BIT_LENGTH	:	INTEGER	RANGE	1 to 16;	-- Bit used  inside PWM
			T_ON_INIT	:	POSITIVE;					-- Init of ton
			PERIOD_INIT	:	POSITIVE;					-- Init of Periof
			PWM_INIT	:	STD_LOGIC					-- Init of PWM
		);
		Port (
			reset	:	IN	STD_LOGIC;									
			clk		:	IN	STD_LOGIC;
			ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	--clk cycles of the period PWM stays on
			Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	--period of PWM
			PWM		:	OUT	STD_LOGIC									-- PWM signal
		);
	end Component;

begin

    --COMPONENT INST
	inst_PulseWidthModulator	:	PulseWidthModulator 			--every Led Controller has instantiated a single PWM module to control in order to obtein the tail effect
	Generic Map( 
		BIT_LENGTH	=>	PwmBits,			--mapping of generics to their respective in this code
		T_ON_INIT	=>	tonInit,
		PERIOD_INIT	=>	PeriodInit,
		PWM_INIT	=>	PwmInit
	)
	Port Map(
		reset	=>	rst,					
		clk		=>	clk,
		ton		=>	ton,
		Period	=>	Period,
		PWM		=>	PWM
	);
    
    --SYNC PART
	process(rst,clk)			
	begin
		if rising_edge(clk) then
            if rst = '1' then			--sync reset sets the ton @ 0 and resets the head register used to see if the lead is a new head
                LedTailTon	<= 0;
                headReg    <= '0';
            else
                if count_pulse = '1' then			--portion of the code that only activates if a count pulse comes, then a Dt has past and a shift is required

                    case TailOperation is			--FSM for the led
                        when ishead => 							--if the state is head then we need 100% duty cycle
                            LedTailTon	<= TailLength-1;
                        when intail =>							--if the state is tail then we decrease by one clock the ton of the pwm, corresponding to a shift either lef or right
                            LedTailTon	<= LedTailTon -1;
                        when others => 							--otherwise we're on idle, idealy, where the duty cycle is to be 0% also used as exeption state
                            LedTailTon	<= 0;
                    end case;
                    headReg	<= head;				--head reg is refreshes every count pulse
                end if;
            end if;
		end if;
	end process;

    --DATA FLOW
    TailOperation <= 			--this is the STATE ENGINE done in data flow
		ishead when head = '1' and headReg = '0' else						--if the led is a condition of new head (previously not head, now head) then the state is head
        intail when LedTailTon >0 and LedTailTon<TailLength else			--if we are not in new head but we are in LedTailTon != 0 (and not out of bounds) then we're in tail state
        idle;																--otherwise we're in idle


	ton		<= std_logic_vector(to_unsigned(LedTailTon,PwmBits));			--here we set the ton of the led from the LedTailTon so s to set the duty cycle based on the module's logic
    Period	<= CounterInit;													--the PWM should count to TailLength-1 maximum, here the max counter value of the pwm is set
	Tail	<= PWM;															--connects the PWM output @ the module output
end Behavioral;
