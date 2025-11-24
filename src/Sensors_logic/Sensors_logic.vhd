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

    constant COUNTER_WIDTH      : integer := 2; -- 2 bits (0 to 3)
    constant DEBOUNCE_THRESHOLD : unsigned(COUNTER_WIDTH-1 downto 0) := "11"; -- X=3 used to represent that the sensor was on for 3 different cycles

    -- Internal Signals for debouncer counters (up to 3)
    signal count_door, count_window, count_motion : unsigned(COUNTER_WIDTH-1 downto 0);
    
    -- Internal Signals for the clean, registered state of the sensors
    signal door_int, window_int, motion_int       : std_logic; 

begin

-- ----------------------------------------------------
-- Door Sensor Debouncer
-- ----------------------------------------------------
debouncer_door_process : process(Clk, Rst)
begin
    -- Asynchronous Reset
    if Rst = '1' then
        door_int <= '0';
        count_door <= (others => '0');
        
    -- Synchronous Clock Edge
    elsif RISING_EDGE(Clk) then
        
        -- Check if the raw input matches the current clean state
        if door_sens = door_int then
            count_door <= (others => '0'); -- door sensor data is the same as the output => we can reset the door counter
        else
            -- Signal has changed: start/continue counting
            if count_door < DEBOUNCE_THRESHOLD then
                count_door <= count_door + 1;
            else
                -- Counter reached threshold: update the output`s state
                door_int <= door_sens;
                count_door <= (others => '0'); -- Reset after update
            end if;
        end if;
    end if;
end process debouncer_door_process;

-- ----------------------------------------------------
-- Window Sensor Debouncer 
-- ----------------------------------------------------
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

-- ----------------------------------------------------
-- Motion Sensor Debouncer
-- ----------------------------------------------------
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

-- ----------------------------------------------------
-- Output Connections
-- ----------------------------------------------------

-- Connect debounced state signals to the external output ports
door_clean   <= door_int;
window_clean <= window_int;
motion_clean <= motion_int;

-- ----------------------------------------------------
-- Detection Logic (Combinational Logic)
-- ----------------------------------------------------

-- 'detected' is active if at least two clean signals are '1'.
detected <= '1' when (
    (door_int = '1' and window_int = '1') or -- Door AND Window
    (door_int = '1' and motion_int = '1') or -- Door AND Motion
    (window_int = '1' and motion_int = '1')  -- Window AND Motion
) else '0';
    
end architecture behavior;