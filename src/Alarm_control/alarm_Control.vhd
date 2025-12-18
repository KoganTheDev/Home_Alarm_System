--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name   : alarm_Control.vhd
-- Author      : Yuval Kogan
-- Ver         : 1
-- Created Date: 04/12/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_Control is
        port (
            Clk                : in  std_logic;
            Rst                : in  std_logic;
            intrusion_detected : in  std_logic;
            code_ready         : in  std_logic;
            code_match         : in  std_logic;
            enable_press       : out std_logic;
            clear_code         : out std_logic;
            alarm_siren        : out std_logic;
            system_armed       : out std_logic;
            attempts           : out integer range 0 to 7;
            state_code         : out std_logic_vector(2 downto 0) -- 8 bits for ASCII
        );
end entity alarm_Control;

architecture behavior of alarm_Control is

    -- FSM State Definitions
    type state_type is (ST_OFF, ST_ARMED, ST_ALERT, ST_ATTEMPTS, ST_CORRECT, ST_LOCK);
    signal current_state : state_type := ST_OFF;

    -- Internal signals
    signal s_enable_press : STD_LOGIC := '0';
    signal s_clear_code : STD_LOGIC := '0';
    signal alarm_siren_flag : STD_LOGIC := '0';
    signal system_armed_flag : STD_LOGIC := '0';
    signal s_attempts : integer range 0 to 7 := 0;
    signal s_state_code : std_logic_vector(2 downto 0);
    signal s_lock_cntr : integer range 0 to 5 := 0; -- Used to lock system for 5 Clk cycles

 
    constant VAL_ST_OFF      : std_logic_vector(2 downto 0) := "000";
    constant VAL_ST_ARMED    : std_logic_vector(2 downto 0) := "001";
    constant VAL_ST_ALERT    : std_logic_vector(2 downto 0) := "010";
    constant VAL_ST_CORRECT  : std_logic_vector(2 downto 0) := "011";
    constant VAL_ST_ATTEMPTS : std_logic_vector(2 downto 0) := "100";
    constant VAL_ST_LOCK : std_logic_vector(2 downto 0) := "101";
    constant VAL_ST_UKNOWN : std_logic_vector(2 downto 0) := "110";


begin
    alarm_Control_process : process(Clk, Rst)
    begin
        -- Asynchronous Reset 
        if Rst = '1' then -- Note: Rst does'nt change alarm state
            s_enable_press <= '0';
            s_clear_code <= '1';
            system_armed_flag <= '0';
            current_state <= ST_ARMED; -- Next state is to ARMED - arm the system
            s_attempts <= 0;
            s_lock_cntr <= 0;

        --  Synchronous Logic
        elsif rising_edge(Clk) then
            case current_state is

                when ST_OFF =>
                    -- Update all variables other than the system alarm
                    s_enable_press <= '0';
                    s_clear_code <= '0';
                    system_armed_flag <= '0';
                    s_attempts <= 0;
                    s_lock_cntr <= 0;

                when ST_ARMED =>
                    system_armed_flag <= '1'; -- Arm system
                    s_lock_cntr <= 0;

                    if (alarm_siren_flag = '1') then -- Siren is on from beforehand, move directly to the code part
                        current_state <= ST_ATTEMPTS;
                    elsif (intrusion_detected = '1') then
                        current_state <= ST_ALERT; -- Change to ST_ALERT
                    end if;

                when ST_ALERT =>
                    system_armed_flag <= '0'; -- Siren fires -> system is not armed anymore
                    alarm_siren_flag <= '1'; -- Siren on
                    
                    current_state <= ST_ATTEMPTS; -- Move automatically to the Code check logic block

                when ST_ATTEMPTS =>
                    if (code_ready = '0') then
                        s_enable_press <= '1';
                        s_clear_code <= '0';
                    else 
                        s_enable_press <= '0';
                        s_clear_code <= '1'; 

                        -- Priority 1: Check if the code is correct
                        if (code_match = '1') then 
                            current_state <= ST_CORRECT;
                        
                        -- Priority 2: If wrong, check if we hit the limit
                        elsif (s_attempts >= 7) then 
                            s_lock_cntr <= 0; -- Initialize lockout timer
                            current_state <= ST_LOCK;
                        
                        -- Priority 3: Increment attempt counter
                        else
                            s_attempts <= s_attempts + 1;
                        end if;
                    end if;               

                when ST_CORRECT =>
                    -- Code Correct logic
                    s_enable_press <= '0'; -- Don't allow pressing
                    s_clear_code <= '0';
                    system_armed_flag <= '0';
                    alarm_siren_flag <= '0'; -- Turn off siren
                    s_attempts <= 0; -- Reset attempts

                    current_state <= ST_ARMED; -- On next clock rise, move to ST_ARMED to re-ARM the machine
                
                when ST_LOCK =>
                    s_enable_press <= '0'; -- Don't allow pressing
                    system_armed_flag <= '0'; 
                    alarm_siren_flag <= '1'; -- Make sure siren is ON
                    s_attempts <= 7; -- Set attempts to 7 to be displayed

                    -- Lock for 4 clock cycles, on the 5th cycle, release lock
                    if (s_lock_cntr = 4) then 
                        s_lock_cntr <= 0;
                        s_attempts <= 0;
                        current_state <= ST_ATTEMPTS;
                    else 
                        s_lock_cntr <= s_lock_cntr + 1;
                    end if;
                    
            end case;
        end if;
    end process;

    
    PRODUCE_STATE_VALUE : process(current_state)
    begin
        case current_state is
            when ST_OFF      => s_state_code <= VAL_ST_OFF;
            when ST_ARMED    => s_state_code <= VAL_ST_ARMED;
            when ST_ALERT    => s_state_code <= VAL_ST_ALERT;
            when ST_CORRECT  => s_state_code <= VAL_ST_CORRECT;
            when ST_LOCK     => s_state_code <= VAL_ST_LOCK;
            when ST_ATTEMPTS => s_state_code <= VAL_ST_ATTEMPTS;
            when others      => s_state_code <= VAL_ST_UKNOWN;
        end case;
    end process PRODUCE_STATE_VALUE;

    -- Set output signals        
    enable_press <= 'Z' when Rst = '1' else s_enable_press;
    alarm_siren  <= 'Z' when Rst = '1' else alarm_siren_flag;
    system_armed <= 'Z' when Rst = '1' else system_armed_flag;
    clear_code   <= 'Z' when Rst = '1' else s_clear_code;
    attempts     <= 0 when Rst = '1' else s_attempts;
    state_code   <= (others => 'Z') when Rst = '1' else s_state_code;

end architecture behavior;
