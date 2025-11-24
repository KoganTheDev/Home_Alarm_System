library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity Sensors_logic_TB is
end Sensors_logic_TB;

architecture test_bench_arch of Sensors_logic_TB is

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
    constant T_WAIT_STABLE : time := CLK_PERIOD * 4; -- Wait time for debounce 

    -- Testbench Control Signals (Inputs to the DUT)
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
        
        report "--- Starting Simulation: Debounce Threshold is 3 Cycles ---" severity note;


        -- == PHASE 0: INITIAL RESET ==
        report "PHASE 0: Testing Asynchronous Reset" severity note;

        -- 1. Apply the Asynchronous Reset pulse
        TB_Rst <= '1';
        wait for CLK_PERIOD * 2; -- Rst is active high for 2 clock cycles
        TB_Rst <= '0';          -- Rst is de-asserted

        -- 2. Wait for system stabilization (4 cycles) and verify outputs
        wait for T_WAIT_STABLE;

        -- Explicitly assert that ALL outputs are zero after reset
        assert TB_door_clean   = '0' report "Error: door_clean not reset to '0'" severity error;
        assert TB_window_clean = '0' report "Error: window_clean not reset to '0'" severity error;
        assert TB_motion_clean = '0' report "Error: motion_clean not reset to '0'" severity error;
        assert TB_detected     = '0' report "Error: detected not reset to '0'" severity error;

        report "Phase 0: Reset verification successful." severity note;

        --------------------------------------------------
        -- PHASE 1: TESTING DEBOUNCING AND 1-OUT-OF-3 COMBINATIONS (No Detection) ==
        --------------------------------------------------
        report "PHASE 1: Testing Single Sensor Debounce (Expected detected = '0')" severity note;

        -- A. Test Door ON (Check Debounce to '1' & No Detection)
        report "Test 1.1: Door ON (001)" severity note;
        TB_door_sens <= '1';
        wait for CLK_PERIOD * 2;
        assert TB_door_clean = '0' report "Error: Door debounced too quickly (2 cycles)" severity error;
        wait for CLK_PERIOD * 2;
        assert TB_door_clean = '1' report "Error: Door failed to debounce after 4 cycles" severity error;
        assert TB_detected = '0' report "Error: Detected high with only 1 sensor" severity error;

        -- B. Test Window ON (Door is already 1)
        report "Test 1.2: Door OFF, Window ON (010)" severity note;
        TB_door_sens <= '0'; -- Start debouncing door OFF (will drop in 4 cycles)
        TB_window_sens <= '1'; -- Start debouncing window ON
        wait for T_WAIT_STABLE;
        assert TB_door_clean = '0' report "Error: Door failed to debounce OFF" severity error;
        assert TB_window_clean = '1' report "Error: Window failed to debounce ON" severity error;
        assert TB_detected = '0' report "Error: Detected high with only 1 sensor (Window)" severity error;

        -- C. Test Motion ON
        report "Test 1.3: All OFF, then Motion ON (001)" severity note;
        TB_window_sens <= '0';
        TB_motion_sens <= '1';
        wait for T_WAIT_STABLE;
        assert TB_window_clean = '0' report "Error: Window failed to debounce OFF" severity error;
        assert TB_motion_clean = '1' report "Error: Motion failed to debounce ON" severity error;
        assert TB_detected = '0' report "Error: Detected high with only 1 sensor (Motion)" severity error;
        
        TB_motion_sens <= '0';
        wait for T_WAIT_STABLE;
        assert TB_motion_clean = '0' report "Error: Motion failed to debounce OFF" severity error;
        wait for CLK_PERIOD * 2;

        --------------------------------------------------
        -- == PHASE 2: TESTING BOUNCE REJECTION ==
        --------------------------------------------------
        report "PHASE 2: Testing Bounce Rejection (Short Pulse)" severity note;
        
        -- Short pulse (2 cycles ON)
        TB_door_sens <= '1';
        wait for CLK_PERIOD * 2; -- 2 cycles passed (not enough)
        TB_door_sens <= '0';
        
        wait for T_WAIT_STABLE; -- Wait to ensure door_clean remained '0'
        assert TB_door_clean = '0' report "Error: Door debounced ON on a short pulse" severity error;
        
        -- Short pulse (2 cycles OFF) - Start from high
        TB_door_sens <= '1';
        wait for T_WAIT_STABLE; -- Debounce to '1'
        assert TB_door_clean = '1' report "Error: Setup failed, Door not high" severity error;

        TB_door_sens <= '0'; -- Start short pulse OFF
        wait for CLK_PERIOD * 2; -- 2 cycles passed (not enough)
        TB_door_sens <= '1'; -- Go back high
        
        wait for T_WAIT_STABLE; -- Wait to ensure door_clean remained '1'
        assert TB_door_clean = '1' report "Error: Door debounced OFF on a short pulse" severity error;
        
        wait for CLK_PERIOD * 2;

        --------------------------------------------------
        -- == PHASE 3: TESTING 2-OUT-OF-3 COMBINATIONS (Detection) ==
        --------------------------------------------------
        report "PHASE 3: Testing 2-out-of-3 Combinations (Expected detected = '1')" severity note;

        -- A. Door + Window (110)
        report "Test 3.1: Door (1) + Window (1)" severity note;
        TB_door_sens <= '1';
        TB_window_sens <= '1';
        wait for T_WAIT_STABLE;
        assert TB_detected = '1' report "Error: Door & Window failed to trigger detection" severity error;
        
        -- B. Door + Motion (101) - Clear Window, Set Motion
        report "Test 3.2: Door (1) + Motion (1)" severity note;
        TB_window_sens <= '0';
        TB_motion_sens <= '1';
        wait for T_WAIT_STABLE;
        assert TB_detected = '1' report "Error: Door & Motion failed to trigger detection" severity error;

        -- C. Window + Motion (011) - Clear Door, Set Window
        report "Test 3.3: Window (1) + Motion (1)" severity note;
        TB_door_sens <= '0';
        TB_window_sens <= '1';
        wait for T_WAIT_STABLE;
        assert TB_detected = '1' report "Error: Window & Motion failed to trigger detection" severity error;

        --------------------------------------------------
        -- == PHASE 4: TEST 3-OUT-OF-3 & FINAL SHUTDOWN ==
        --------------------------------------------------
        report "PHASE 4: Testing All On and Final Shutdown" severity note;

        -- All three ON (111)
        report "Test 4.1: All ON (111)" severity note;
        TB_door_sens <= '1';
        wait for T_WAIT_STABLE;
        assert TB_detected = '1' report "Error: All 3 ON failed to maintain detection" severity error;

        -- All three OFF (000)
        report "Test 4.2: All OFF (000)" severity note;
        TB_door_sens <= '0';
        TB_window_sens <= '0';
        TB_motion_sens <= '0';
        wait for T_WAIT_STABLE;
        assert TB_detected = '0' report "Error: Detected remained high when all clean signals are low" severity error;
        
        -- End Simulation
        wait for CLK_PERIOD * 5;
        report "--- Simulation Complete: All Major States Tested Successfully ---" severity failure; -- Stop the simulation

    end process STIM_GEN;

end architecture test_bench_arch;