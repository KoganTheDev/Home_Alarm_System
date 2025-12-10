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
            state_code         : out std_logic_vector(7 downto 0) -- 8 bits for ASCII
        );
end entity alarm_Control;

architecture behavior of alarm_Control is

    -- FSM State Definitions
    type state_type is (ST_OFF, ST_ARMED, ST_ALERT, ST_ATTEMPTS, ST_CORRECT);
    signal current_state : state_type := ST_OFF;

    -- Internal signals
    signal s_enable_press : STD_LOGIC := '0';
    signal s_clear_code : STD_LOGIC := '0';
    signal alarm_siren_flag : STD_LOGIC := '0';
    signal system_armed_flag : STD_LOGIC := '0';
    signal s_attempts : integer range 0 to 7 := 0;


    -- ASCII Constants (Hex values)
    constant ASCII_0    : std_logic_vector(7 downto 0) := x"30"; -- '0'
    constant ASCII_8    : std_logic_vector(7 downto 0) := x"38"; -- '8'
    constant ASCII_A    : std_logic_vector(7 downto 0) := x"41"; -- 'A'
    constant ASCII_F    : std_logic_vector(7 downto 0) := x"46"; -- 'F'
    constant ASCII_DASH : std_logic_vector(7 downto 0) := x"2D"; -- '-'

begin
    alarm_Control_process : process(Clk, Rst)
    begin
        -- Asynchronous Reset 
        if Rst = '1' then -- Note: siren_flag is unchanged
            s_enable_press <= '0';
            s_clear_code   <= '1';
            system_armed_flag <= '0';
            current_state <= ST_OFF;
            s_attempts    <= 0;

        --  Synchronous Logic
        elsif rising_edge(Clk) then
            case current_state is

                when ST_OFF =>
                    -- Update all variables other than the system alarm
                    s_enable_press <= '0';
                    s_clear_code <= '0';
                    system_armed_flag <= '0';
                    s_attempts <= 0;
                    
                    if (alarm_siren_flag = '1') then -- Coming from async reset when the alarm is on, continue to ST_ALERT
                        current_state <= ST_ALERT;
                    else -- Continue to ARMED state
                        current_state <= ST_ARMED;
                        alarm_siren_flag <= '0';  -- Make sure siren is off so the system can be armed
                    end if;
                    
                when ST_ARMED =>
                    system_armed_flag <= '1'; -- Arm system

                    if (intrusion_detected = '1') then
                        -- Change to ST_ALERT
                        current_state <= ST_ALERT;
                    else -- Move automatically to the Code Logic block
                        current_state <= ST_ATTEMPTS;
                    end if;

                when ST_ALERT =>
                    system_armed_flag <= '0'; -- Siren released -> system is not armed anymore
                    alarm_siren_flag <= '1'; -- Siren on
                    
                    current_state <= ST_ATTEMPTS; -- Move automatically to the Code check logic block

                when ST_ATTEMPTS =>
                    if (code_ready = '0') then
                        -- Code Entry logic
                        s_enable_press <= '1';
                        s_clear_code <= '0';
                    else -- Code Check logic
                        s_enable_press <= '0';
                        s_clear_code <= '1'; -- Clear code for next iteration

                        if (code_match = '1') then -- Correct code, move to state ST_CORRECT
                            current_state <= ST_CORRECT;
                        elsif (s_attempts < 7) then -- There are more possible attempts, try again
                            s_attempts <= s_attempts + 1; -- Increase attempts counter
                            current_state <= ST_ATTEMPTS; -- State stays the same
                        else -- Used all attempts, next state is intrusion detected
                            current_state <= ST_ALERT;
                        end if;
                    end if;

                when ST_CORRECT =>
                    -- Code Correct logic
                    s_enable_press <= '0'; -- Don't allow pressing
                    s_clear_code <= '0';
                    alarm_siren_flag <= '0'; -- Turn off siren
                    system_armed_flag <= '0';
                    s_attempts <= 0; -- Reset attempts

                    current_state <= ST_ARMED; -- On next clock rise, move to ST_ARMED to re-ARM the machine

            end case;
        end if;
    end process;

    -- Output assignments based on internal signals
    enable_press <= s_enable_press;
    alarm_siren <= alarm_siren_flag;
    system_armed <= system_armed_flag;
    clear_code <= s_clear_code;
    attempts <= s_attempts;
    
    -- Map current_state to an ASCII code for `state_code` using a selected signal assignment
    with current_state select
        state_code <= ASCII_0 when ST_OFF,
                      ASCII_8 when ST_ARMED,
                      ASCII_A when ST_ALERT,
                      ASCII_F when ST_CORRECT,
                      std_logic_vector(to_unsigned(48 + s_attempts, 8)) when ST_ATTEMPTS,
                      ASCII_DASH when others;


end architecture behavior;
