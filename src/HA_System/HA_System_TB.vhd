--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: HA_System_TB.vhd
-- Author: Yuval Kogan
-- Ver: 1
-- Created Date: 4/12/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_HA_System is
    -- Testbench has no ports
end tb_HA_System;

architecture behavior of tb_HA_System is

    -- Component Declaration
    component HA_System
    port(
        Clk          : in  std_logic;
        Rst          : in  std_logic;
        pass_btn     : in  std_logic;
        door_raw     : in  std_logic;
        window_raw   : in  std_logic;
        motion_raw   : in  std_logic;
        alarm_siren  : out std_logic;
        system_armed : out std_logic;
        sens_dbg     : out std_logic_vector(2 downto 0);
        display_data : out std_logic_vector(8 downto 0)
    );
    end component;

    -- Inputs
    signal tb_Clk        : std_logic := '0';
    signal tb_Rst        : std_logic := '0';
    signal tb_pass_btn   : std_logic := '0';
    signal tb_door_raw   : std_logic := '0';
    signal tb_window_raw : std_logic := '0';
    signal tb_motion_raw : std_logic := '0';

    -- Outputs
    signal tb_alarm_siren  : std_logic;
    signal tb_system_armed : std_logic;
    signal tb_sens_dbg     : std_logic_vector(2 downto 0);
    signal tb_display_data : std_logic_vector(8 downto 0);

    -- Clock definition
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- User Configurable Constants (Adjust according to your logic)
    constant T_SHORT_PRESS : time := 20 ms;  -- Short press duration ('0')
    constant T_LONG_PRESS  : time := 500 ms; -- Long press duration ('1')
    constant T_GAP         : time := 50 ms;  -- Gap between presses

begin

    -- Instantiate the UUT
    uut: HA_System PORT MAP (
        Clk          => tb_Clk,
        Rst          => tb_Rst,
        pass_btn     => tb_pass_btn,
        door_raw     => tb_door_raw,
        window_raw   => tb_window_raw,
        motion_raw   => tb_motion_raw,
        alarm_siren  => tb_alarm_siren,
        system_armed => tb_system_armed,
        sens_dbg     => tb_sens_dbg,
        display_data => tb_display_data
    );

    -- Clock Process
    Clk_process :process
    begin
        tb_Clk <= '0';
        wait for CLK_PERIOD/2;
        tb_Clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Process
    stim_proc: process
        
        -- Helper Procedure: Short Press
        procedure press_short is
        begin
            tb_pass_btn <= '1';
            wait for T_SHORT_PRESS;
            tb_pass_btn <= '0';
            wait for T_GAP;
        end procedure press_short;

        -- Helper Procedure: Long Press
        procedure press_long is
        begin
            tb_pass_btn <= '1';
            wait for T_LONG_PRESS;
            tb_pass_btn <= '0';
            wait for T_GAP;
        end procedure press_long;

    begin		
        -- =========================================================
        -- 1. Initialization & Reset
        -- =========================================================
        report "Starting Simulation: System Reset";
        tb_Rst <= '1';
        wait for 100 ns;	
        tb_Rst <= '0';
        wait for 100 ns;

        -- =========================================================
        -- 2. Scenario: Wrong Code Entry (Check Failed Attempts)
        -- =========================================================
        report "Scenario 2: Entering Wrong Code";
        -- Assume correct code is 4 short presses, we insert a long one to fail it
        press_short;
        press_long;  -- Error!
        press_short;
        press_short;
        
        wait for 200 ms;
        -- Check: System should NOT be armed
        assert tb_system_armed = '0' report "Error: System Armed with wrong code!" severity error;

        -- =========================================================
        -- 3. Scenario: Successful Arming (Entering correct code)
        -- =========================================================
        report "Scenario 3: Entering Correct Code to ARM";
        -- Assuming 4 short presses. Change to long if your password differs
        press_short; 
        press_short;
        press_short;
        press_short;

        wait for 200 ms; -- Time for FSM processing
        
        -- Check: System should be ARMED
        if tb_system_armed = '1' then
            report "System Successfully ARMED";
        else
            report "Error: System failed to ARM" severity error;
        end if;

        -- =========================================================
        -- 4. Scenario: Intrusion Detected (Window)
        -- =========================================================
        report "Scenario 4: Intrusion on Window Sensor";
        wait for 100 ms;
        tb_window_raw <= '1';
        wait for 100 ms; -- Simulate window opening
        tb_window_raw <= '0';

        wait for 50 ms;
        -- Check: Alarm should trigger
        assert tb_alarm_siren = '1' report "Error: Siren did not trigger on window breach!" severity error;

        -- =========================================================
        -- 5. Scenario: Disarm System (Stop Siren)
        -- =========================================================
        report "Scenario 5: Entering Code to DISARM";
        wait for 1 sec; -- Let the alarm run for a bit
        
        -- Entering correct code again to disarm
        press_short;
        press_short;
        press_short;
        press_short;

        wait for 200 ms;
        assert tb_alarm_siren = '0' report "Error: Siren did not stop after code entry!" severity error;
        assert tb_system_armed = '0' report "Error: System did not disarm!" severity error;

        -- =========================================================
        -- 6. Scenario: Sensor Glitch / Debounce Test
        -- =========================================================
        report "Scenario 6: Sensor Glitch Test (Short noise)";
        -- Re-arming
        press_short; press_short; press_short; press_short;
        wait for 200 ms;

        -- Very short noise on door sensor (e.g., 10ns)
        tb_door_raw <= '1';
        wait for 10 ns; 
        tb_door_raw <= '0';
        
        wait for 50 ms;
        -- Alarm should *NOT* trigger (if you have debounce logic > 10ms)
        -- If alarm triggers here - your Sensor Logic is too sensitive to noise
        if tb_alarm_siren = '1' then
            report "Warning: System triggered on short glitch (check debounce logic)";
        else
            report "System ignored glitch correctly";
        end if;

        -- =========================================================
        -- 7. Scenario: Motion Detection Intrusion
        -- =========================================================
        report "Scenario 7: Intrusion on Motion Sensor";
        -- Triggering motion sensor for a long duration
        tb_motion_raw <= '1';
        wait for 200 ms;
        tb_motion_raw <= '0';
        
        wait for 50 ms;
        assert tb_alarm_siren = '1' report "Error: Motion sensor failed to trigger alarm" severity error;

        report "Testbench Completed Successfully";
        wait;
    end process;

end behavior;
