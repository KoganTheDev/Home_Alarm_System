--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Sensors_logic.vhd
-- Author: Yuval Kogan
-- Ver: 1
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;

entity Sensors_logic is
    port (
        Clk          : IN  std_logic;
        Rst          : IN  std_logic;

        -- Raw Sensor Inputs
        door_sens    : IN  std_logic;
        window_sens  : IN  std_logic;  
        motion_sens  : IN  std_logic;
        
        -- Debounced Sensor Outputs
        door_clean   : OUT std_logic;
        window_clean : OUT std_logic;
        motion_clean : OUT std_logic;
        
        -- Combined Detection Output
        detected     : OUT std_logic
    );
end Sensors_logic;

architecture behavior of Sensors_logic is

    constant COUNTER_WIDTH      : integer := 2;     -- 2 bits (0 to 3)
    constant DEBOUNCE_THRESHOLD : unsigned(COUNTER_WIDTH-1 downto 0) := "10"; 

    -- Internal Signals for debouncer counters
    signal count_door, count_window, count_motion : unsigned(COUNTER_WIDTH-1 downto 0);
    
    -- Internal Signals for the clean, registered state of the sensors
    signal door_int, window_int, motion_int       : std_logic := '0'; -- Initialize to '0'
    
begin


-- Door Sensor Debouncer
debouncer_door_process : process(Clk, Rst)
begin
    -- Asynchronous Reset
    if Rst = '1' then
        door_int <= '0';
        count_door <= (others => '0');
        
    -- Synchronous Clock Edge
    elsif RISING_EDGE(Clk) then
        
        -- If the raw input matches the current debounced state, reset the counter.
        if door_sens = door_int then
            count_door <= (others => '0'); 
        else
            -- Signal has changed: start/continue counting
            if count_door < DEBOUNCE_THRESHOLD then
                count_door <= count_door + 1;
            else
                -- Counter reached threshold: update the output's state
                door_int <= door_sens;
                count_door <= (others => '0'); -- Reset after update
            end if;
        end if;
    end if;
end process debouncer_door_process;


-- Window Sensor Debouncer 
debouncer_window_process : process(Clk, Rst)
begin
    if Rst = '1' then
        window_int <= '0';
        count_window <= (others => '0');
    elsif RISING_EDGE(Clk) then
        if window_sens = window_int then
            count_window <= (others => '0');
        else
            if count_window < DEBOUNCE_THRESHOLD then
                count_window <= count_window + 1;
            else
                window_int <= window_sens;
                count_window <= (others => '0');
            end if;
        end if;
    end if;
end process debouncer_window_process;


-- Motion Sensor Debouncer
debouncer_motion_process : process(Clk, Rst)
begin
    if Rst = '1' then
        motion_int <= '0';
        count_motion <= (others => '0');
    elsif RISING_EDGE(Clk) then
        if motion_sens = motion_int then
            count_motion <= (others => '0');
        else
            if count_motion < DEBOUNCE_THRESHOLD then
                count_motion <= count_motion + 1;
            else
                motion_int <= motion_sens;
                count_motion <= (others => '0');
            end if;
        end if;
    end if;
end process debouncer_motion_process;

-- Output Connections
-- Connect debounced state signals to the external output ports
door_clean   <= 'Z' when Rst = '1' else door_int;
window_clean <= 'Z' when Rst = '1' else window_int;
motion_clean <= 'Z' when Rst = '1' else motion_int;

-- Detection Logic 
-- 'detected' is active if at least two clean signals are '1'.
detected <= 'Z' when Rst = '1' else 
            '1' when (
                (door_int = '1' and window_int = '1') or
                (door_int = '1' and motion_int = '1') or
                (window_int = '1' and motion_int = '1')
            ) else 
            '0';
    
end architecture behavior;