--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name   : Alarm_controller_FSM.vhd
-- Author      : Yuval Kogan
-- Ver         : 1
-- Created Date: 04/12/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Alarm_controller_FSM is
        port (
            Clk                : in  std_logic;
            Rst                : in  std_logic;
            code_ready         : in  std_logic;
            code_match         : in  std_logic;
            enable_press       : out std_logic;
            clear_code         : out std_logic;
            alarm_siren        : out std_logic;
            system_armed       : out std_logic;
            state_code         : out std_logic_vector(7 downto 0); -- 8 bits for ASCII
            attempts           : out integer range 0 to 7; 
            intrusion_detected : in  std_logic
        );
end entity Alarm_controller_FSM;

architecture behavior of Alarm_controller_FSM is

    -- FSM State Definitions
    type state_type is (DISARMED, ARMED, ALARM);
    signal current_state : state_type;

    -- Internal signal for failed attempt counting
    signal s_attempts : integer range 0 to 7 := 0;

    -- ASCII Constants for Display Output
    constant ASCII_0 : std_logic_vector(7 downto 0) := x"30"; -- '0' - Disarmed
    constant ASCII_8 : std_logic_vector(7 downto 0) := x"38"; -- '8' - Armed
    constant ASCII_A : std_logic_vector(7 downto 0) := x"41"; -- 'A' - Alarm

begin

    Alarm_controller_FSM_process : process(Clk, Rst)
    begin
        if Rst = '1' then
            -- System Reset
            current_state <= DISARMED;
            s_attempts    <= 0;
            clear_code    <= '0';
            
        elsif rising_edge(Clk) then
            case current_state is
                when DISARMED =>
                    if code_ready = '1' then
                        if code_match = '1' then
                            current_state <= ARMED;
                            s_attempts <= 0;
                        else
                            s_attempts <= s_attempts + 1;
                        end if;
                    end if;
                    
                when ARMED =>
                    if intrusion_detected = '1' then
                        current_state <= ALARM;
                    elsif code_ready = '1' and code_match = '1' then
                        current_state <= DISARMED;
                        s_attempts <= 0;
                    end if;
                    
                when ALARM =>
                    if code_ready = '1' and code_match = '1' then
                        current_state <= DISARMED;
                        s_attempts <= 0;
                    end if;
                    
            end case;
        end if;
    end process;

    -- Output assignments based on current state
    enable_press <= '1' when current_state = DISARMED else '0';
    alarm_siren <= '1' when current_state = ALARM else '0';
    system_armed <= '1' when current_state = ARMED else '0';
    clear_code <= '1' when code_ready = '1' else '0';
    attempts <= s_attempts;
    
    state_code <= ASCII_0 when current_state = DISARMED else
                  ASCII_8 when current_state = ARMED else
                  ASCII_A;

end architecture behavior;