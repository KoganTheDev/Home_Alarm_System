--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Sensors_logic_TB.vhd
-- Author: Yuval Kogan
-- Ver: 1
-- Created Date: 27/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity Sensors_logic_TB is
end Sensors_logic_TB;

architecture test_bench of Sensors_logic_TB is

    -- DUT Component Declaration
    component Sensors_logic
        port (
            Clk          : IN  std_logic;
            Rst          : IN  std_logic;
            door_sens    : IN  std_logic;
            window_sens  : IN  std_logic;    
            motion_sens  : IN  std_logic;
            
            door_clean   : OUT std_logic;
            window_clean : OUT std_logic;
            motion_clean : OUT std_logic;
            detected     : OUT std_logic
        );
    end component;

    -- Signal Declarations
    constant CLK_PERIOD : time := 10 ns; 
    constant T_DEBOUNCE_TIME : time := CLK_PERIOD * 3; 
    constant T_PRE_DEBOUNCE  : time := CLK_PERIOD * 2; 

    -- Testbench Control Signals
    signal TB_Clk         : std_logic := '0';
    signal TB_Rst         : std_logic := '0';
    signal TB_door_sens   : std_logic := '0';
    signal TB_window_sens : std_logic := '0';
    signal TB_motion_sens : std_logic := '0';
    
    -- Output Signals from the DUT
    signal TB_door_clean  : std_logic;
    signal TB_window_clean: std_logic;
    signal TB_motion_clean: std_logic;
    signal TB_detected    : std_logic;

begin
    -- DUT Instantiation
    DUT: Sensors_logic
        port map (
            Clk          => TB_Clk,
            Rst          => TB_Rst,
            door_sens    => TB_door_sens,
            window_sens  => TB_window_sens,
            motion_sens  => TB_motion_sens,
            door_clean   => TB_door_clean,
            window_clean => TB_window_clean,
            motion_clean => TB_motion_clean,
            detected     => TB_detected
        );

    -- Clock Generation Process
    CLK_GEN: process
    begin
        loop
            TB_Clk <= '0';
            wait for CLK_PERIOD / 2;
            TB_Clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process CLK_GEN;

    -- Stimulus Generation Process
    STIM_GEN: process
    begin
        
        report "--- Starting Sensor_logic Test Suite ---" severity note;
        report "--- Debounce requires 3 Clock Cycles (threshold=2) ---" severity note;

        -- Initial conditions
        TB_door_sens <= '0';
        TB_window_sens <= '0';
        TB_motion_sens <= '0';

        wait for CLK_PERIOD * 2;


        -- PHASE 0: INITIAL RESET
        report "PHASE 0: Testing Asynchronous Reset" severity note;

        TB_Rst <= '1';
        wait for CLK_PERIOD / 2; 

        -- CHECK 1: Assert that outputs are 'Z' WHILE Rst is active
        assert TB_door_clean   = 'Z' report "Error: door_clean not 'Z' during active Rst" severity error;
        assert TB_window_clean = 'Z' report "Error: window_clean not 'Z' during active Rst" severity error;
        assert TB_motion_clean = 'Z' report "Error: motion_clean not 'Z' during active Rst" severity error;
        assert TB_detected     = 'Z' report "Error: detected not 'Z' during active Rst" severity error; 
        
        TB_Rst <= '0';

        -- CHECK 2: Wait one clock cycle. Outputs should now be driven by the internal logic, which is '0'.
        wait for CLK_PERIOD;
        assert TB_door_clean   = '0' report "Error: door_clean not cleared to '0' after Rst removal" severity error;
        assert TB_window_clean = '0' report "Error: window_clean not cleared to '0' after Rst removal" severity error;
        assert TB_motion_clean = '0' report "Error: motion_clean not cleared to '0' after Rst removal" severity error;
        assert TB_detected     = '0' report "Error: detected not cleared to '0' after Rst removal" severity error;
        report "PHASE 0: Reset verified - Z-state confirmed and outputs cleared to 0" severity note;

        
        -- PHASE 1: FULL DEBOUNCE TIMING CHECK (Door ON)
        report "PHASE 1: Detailed Door Sensor Debounce ON Timing Check" severity note;

        TB_door_sens <= '1';
        
        -- Check 1: Must NOT have debounced after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_door_clean = '0' report "Error: Door debounced too quickly (after 2 cycles)" severity error;
        
        -- Check 2: Must debounce ON exactly after the 3rd cycle
        wait for CLK_PERIOD; 
        wait for 1 ns;
        
        assert TB_door_clean = '1' report "Error: Door failed to debounce ON after 3 cycles" severity error;
        assert TB_detected = '0' report "Error: Detected high with only 1 sensor" severity error;
        report "PHASE 1: Door debounced successfully after 3 cycles" severity note;

        
        -- PHASE 2: BOUNCE REJECTION AND COUNTER RESET
        report "PHASE 2: Testing Bounce Rejection (Short Pulse OFF)" severity note;
        
        TB_door_sens <= '0'; 
        
        -- Check 1: Must NOT have debounced OFF after 2 cycles
        wait for T_PRE_DEBOUNCE;
        assert TB_door_clean = '1' report "Error: Door debounced OFF too quickly (after 2 cycles)" severity error;
        
        TB_door_sens <= '1'; 
        
        -- Counter should have reset, and door_clean should remain '1'
        wait for CLK_PERIOD;
        wait for 1 ns;
        assert TB_door_clean = '1' report "Error: Door debounced OFF due to short pulse" severity error;
        report "PHASE 2: Bounce correctly rejected" severity note;


        -- PHASE 3: ASYMMETRIC DETECTION TIMING CHECK (Door (1) + Window (0->1))
        report "PHASE 3: Asymmetric Detection (Door is stable, Wait for Window)" severity note;
        
        TB_window_sens <= '1'; 
        
        -- Check 1: Must NOT detect after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_window_clean = '0' report "Error: Window debounced too quickly" severity error;
        assert TB_detected     = '0' report "Error: Detected asserted before second sensor stabilized (3 cycles)" severity error;

        -- Check 2: Must detect exactly after the 3rd cycle
        wait for CLK_PERIOD; 
        wait for 1 ns;
        
        assert TB_window_clean = '1' report "Error: Window failed to debounce ON after 3 cycles" severity error;
        assert TB_detected     = '1' report "Error: Detected failed to assert immediately after 2nd sensor stabilization" severity failure;
        report "PHASE 3: Detection asserted with 2 sensors (Door + Window)" severity note;

        
        -- PHASE 4: DETECTION DE-ASSERTION CHECK (Door (1) + Window (1->0))
        report "PHASE 4: De-assertion Timing Check (Window (1->0))" severity note;

        TB_window_sens <= '0';
        
        -- Check 1: Must still detect after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_window_clean = '1' report "Error: Window debounced OFF too quickly" severity error;
        assert TB_detected     = '1' report "Error: Detected de-asserted before sensor went low" severity error;
        
        -- Check 2: Must de-assert detection exactly after the 3rd cycle
        wait for CLK_PERIOD; 
        wait for 1 ns; 
        
        assert TB_window_clean = '0' report "Error: Window failed to debounce OFF after 3 cycles" severity error;
        assert TB_detected     = '0' report "Error: Detected failed to de-assert after sensor went low" severity failure;
        report "PHASE 4: Detection de-asserted correctly when only 1 sensor remains" severity note;


        -- PHASE 5: COMPLEX DETECTION COMBINATIONS
        report "PHASE 5: Testing Door + Motion Combination" severity note;

        TB_window_sens <= '0';
        TB_motion_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        -- Test 5.1: Door (1) + Motion (1) -> Should detect
        assert TB_door_clean   = '1' report "Error: Door expected '1'" severity error;
        assert TB_window_clean = '0' report "Error: Window expected '0'" severity error;
        assert TB_motion_clean = '1' report "Error: Motion expected '1'" severity error;
        assert TB_detected     = '1' report "Error: Door & Motion failed to detect" severity failure;
        report "PHASE 5.1: Door + Motion detection confirmed" severity note;


        -- PHASE 6: WINDOW + MOTION COMBINATION
        report "PHASE 6: Testing Window + Motion Combination" severity note;
        
        TB_door_sens   <= '0';
        TB_window_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        assert TB_door_clean   = '0' report "Error: Door failed to debounce OFF" severity error;
        assert TB_window_clean = '1' report "Error: Window failed to debounce ON" severity error;
        assert TB_motion_clean = '1' report "Error: Motion expected '1'" severity error;
        assert TB_detected     = '1' report "Error: Window & Motion failed to detect" severity failure;
        report "PHASE 6: Window + Motion detection confirmed" severity note;

        -- PHASE 7: ALL THREE SENSORS ACTIVE
        report "PHASE 7: Testing All Three Sensors Active (111)" severity note;
        
        TB_door_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        assert TB_door_clean   = '1' report "Error: Door expected '1'" severity error;
        assert TB_window_clean = '1' report "Error: Window expected '1'" severity error;
        assert TB_motion_clean = '1' report "Error: Motion expected '1'" severity error;
        assert TB_detected     = '1' report "Error: All three sensors should detect" severity failure;
        report "PHASE 7: All three sensors active - detection confirmed" severity note;


        -- PHASE 8: TRANSITION FROM ALL THREE TO SINGLE SENSOR
        report "PHASE 8: Transition from 3 sensors to 1 sensor (should de-assert)" severity note;
        
        TB_window_sens <= '0';
        TB_motion_sens <= '0';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        assert TB_door_clean   = '1' report "Error: Door expected '1'" severity error;
        assert TB_window_clean = '0' report "Error: Window expected '0'" severity error;
        assert TB_motion_clean = '0' report "Error: Motion expected '0'" severity error;
        assert TB_detected     = '0' report "Error: Detection should be OFF with only 1 sensor" severity failure;
        report "PHASE 8: Detection correctly de-asserted with only 1 sensor" severity note;


        -- PHASE 9: COMPLETE SYSTEM SHUTDOWN
        report "PHASE 9: Complete Shutdown Test" severity note;

        TB_door_sens   <= '0';
        TB_window_sens <= '0';
        TB_motion_sens <= '0';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        assert TB_door_clean   = '0' report "Error: Door failed to debounce OFF" severity error;
        assert TB_window_clean = '0' report "Error: Window failed to debounce OFF" severity error;
        assert TB_motion_clean = '0' report "Error: Motion failed to debounce OFF" severity error;
        assert TB_detected     = '0' report "Error: Detected remained high at shutdown" severity failure;
        report "PHASE 9: All sensors deactivated, detected correctly de-asserted" severity note;


        -- PHASE 10: RESET DURING DETECTION
        report "PHASE 10: Testing Reset While Detection Active" severity note;
        
        TB_door_sens   <= '1';
        TB_window_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        wait for 1 ns;
        
        assert TB_detected = '1' report "Error: Detection should be active" severity error;
        
        TB_Rst <= '1';
        wait for CLK_PERIOD / 2;
        
        assert TB_door_clean   = 'Z' report "Error: Output not 'Z' during active Rst" severity error;
        
        TB_Rst <= '0';
        wait for CLK_PERIOD * 2;
        
        assert TB_door_clean   = '0' report "Error: Reset failed to clear door_clean" severity error;
        assert TB_detected     = '0' report "Error: Reset failed to clear detected" severity error;
        report "PHASE 10: Reset during detection clears all signals correctly" severity note;

        
        -- End Simulation
        wait for CLK_PERIOD * 5;
        report "--- Simulation Complete: ALL test cases PASSED ---" severity note;
        wait; 
    end process STIM_GEN;

end architecture test_bench;