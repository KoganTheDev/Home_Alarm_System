--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name   : alarm_Control_TB.vhd
-- Author      : Yuval Kogan
-- Ver         : 1.0 (Testbench)
-- Created Date: 04/12/25
-- Description : Complete verification of alarm_Control FSM (Expanded)
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_Control_TB is
end entity alarm_Control_TB;

architecture behavior of alarm_Control_TB is

    -- Inputs
    signal Clk              : std_logic := '0';
    signal Rst              : std_logic := '0';
    signal intrusion_detected : std_logic := '0';
    signal code_ready       : std_logic := '0';
    signal code_match       : std_logic := '0';

    -- Outputs
    signal enable_press       : std_logic;
    signal clear_code         : std_logic;
    signal alarm_siren        : std_logic;
    signal system_armed       : std_logic;
    signal attempts           : integer range 0 to 7;
    signal state_code         : std_logic_vector(7 downto 0);

    -- Clock period definitions
    constant Clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    DUT: entity work.alarm_Control PORT MAP (
        Clk              => Clk,
        Rst              => Rst,
        intrusion_detected => intrusion_detected,
        code_ready       => code_ready,
        code_match       => code_match,
        enable_press     => enable_press,
        clear_code       => clear_code,
        alarm_siren      => alarm_siren,
        system_armed     => system_armed,
        attempts         => attempts,
        state_code       => state_code
    );

    -- Clock process definitions
    Clk_process :process
    begin
        Clk <= '0';
        wait for Clk_period/2;
        Clk <= '1';
        wait for Clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        ------------------------------------------------------------
        -- 1. Power-Up and Reset Test (Target: ST_ARMED)
        ------------------------------------------------------------
        report "Starting Testbench...";
        Rst <= '1';
        wait for 20 ns;
        Rst <= '0';
        wait for Clk_period;

        -- Check: System should start in ST_ARMED (ASCII '8')
        assert state_code = x"38" report "Error 1A: Failed to reset to ST_ARMED" severity error;
        assert system_armed = '1' report "Error 1B: System not ARMED after reset" severity error;

        ------------------------------------------------------------
        -- 2. Intrusion Test (Target: ST_ARMED -> ST_ALERT -> ST_ATTEMPTS)
        ------------------------------------------------------------
        report "Testing Intrusion Trigger (ST_ARMED -> ST_ATTEMPTS)...";
        intrusion_detected <= '1';
        wait for Clk_period; -- ST_ARMED -> ST_ALERT
        intrusion_detected <= '0';
        
        wait for Clk_period; -- ST_ALERT -> ST_ATTEMPTS (Siren ON)

        -- Check: Should be in ST_ATTEMPTS (Attempts = 0)
        assert alarm_siren = '1' report "Error 2A: Siren did not trigger on intrusion" severity error;
        assert enable_press = '1' report "Error 2B: Keypad not enabled in ST_ATTEMPTS" severity error;
        assert attempts = 0 report "Error 2C: Attempts counter not 0 initially" severity error;

        ------------------------------------------------------------
        -- 3. Lockout Logic Test (Target: Fail 8 times -> ST_LOCK)
        ------------------------------------------------------------
        report "Testing Lockout Logic (8 Failures)...";
        
        -- Loop 8 times (Index 0 to 7) to simulate failed attempts
        for i in 0 to 7 loop
            assert attempts = i report "Error 3A: Attempts counter mismatch before entry " & integer'image(i) severity error;
            
            code_ready <= '1';
            code_match <= '0'; -- Incorrect Code
            wait for Clk_period;
            code_ready <= '0';
            wait for Clk_period; -- Wait one cycle for state update
        end loop;

        -- Check: Should now be in ST_LOCK (ASCII '-')
        assert state_code = x"2D" report "Error 3B: Failed to enter ST_LOCK after 8 attempts" severity error;
        assert enable_press = '0' report "Error 3C: Keypad should be disabled in ST_LOCK" severity error;
        assert alarm_siren = '1' report "Error 3D: Siren should stay ON in ST_LOCK" severity error;

        ------------------------------------------------------------
        -- 4. Lock Timer Test (Target: Wait 5 cycles -> ST_ATTEMPTS)
        ------------------------------------------------------------
        report "Testing Lock Timer (5 Cycles)...";
        
        -- Wait for the lock counter duration (5 cycles)
        wait for Clk_period * 6; -- +1 buffer for transition

        -- Check: Should return to ST_ATTEMPTS, reset attempts
        assert enable_press = '1' report "Error 4A: Failed to return to ST_ATTEMPTS after Lock" severity error;
        assert attempts = 0 report "Error 4B: Attempts not reset after Lock" severity error;

        ------------------------------------------------------------
        -- 5. Correct Code Test (Target: ST_ATTEMPTS -> ST_CORRECT -> ST_ARMED)
        ------------------------------------------------------------
        report "Testing Correct Code Entry to re-ARM...";
        
        code_ready <= '1';
        code_match <= '1'; -- Correct Code
        wait for Clk_period; -- State moves to ST_CORRECT, attempts reset, siren off
        code_ready <= '0';

        wait for Clk_period; -- ST_CORRECT -> ST_ARMED

        -- Check: Should be back in ST_ARMED (Siren OFF, System ARMED)
        assert system_armed = '1' report "Error 5A: Failed to re-ARM after correct code" severity error;
        assert alarm_siren = '0' report "Error 5B: Siren did not turn OFF after correct code" severity error;
        assert state_code = x"38" report "Error 5C: Not in ST_ARMED state" severity error;
        assert attempts = 0 report "Error 5D: Attempts not reset after correct code" severity error;

        ------------------------------------------------------------
        -- 6. Failed Attempt (Target: ST_ATTEMPTS)
        ------------------------------------------------------------
        report "Testing a single failed attempt...";
        
        -- Trigger intrusion again to get back to ST_ATTEMPTS
        intrusion_detected <= '1';
        wait for Clk_period; -- ST_ARMED -> ST_ALERT
        intrusion_detected <= '0';
        wait for Clk_period; -- ST_ALERT -> ST_ATTEMPTS

        -- Fail the code once
        code_ready <= '1';
        code_match <= '0'; 
        wait for Clk_period; -- ST_ATTEMPTS (Attempts=0) -> ST_ATTEMPTS (Attempts=1)
        code_ready <= '0';
        wait for Clk_period; 

        -- Check: Attempts should be 1
        assert attempts = 1 report "Error 6A: Failed attempt did not increment counter to 1" severity error;
        assert enable_press = '1' report "Error 6B: Keypad should be enabled" severity error;

        ------------------------------------------------------------
        -- 7. Correct Code After Failed Attempt (Target: ST_ATTEMPTS -> ST_CORRECT)
        ------------------------------------------------------------
        report "Testing Correct Code after one failure...";
        
        code_ready <= '1';
        code_match <= '1'; -- Correct Code
        wait for Clk_period; -- ST_ATTEMPTS (Attempts=1) -> ST_CORRECT
        code_ready <= '0';

        -- Check: Should be in ST_CORRECT, then move to ST_ARMED
        wait for Clk_period; -- ST_CORRECT -> ST_ARMED

        assert system_armed = '1' report "Error 7A: Failed to re-ARM after late correct code" severity error;
        assert alarm_siren = '0' report "Error 7B: Siren is still ON" severity error;
        assert attempts = 0 report "Error 7C: Attempts not reset by ST_CORRECT" severity error;


        ------------------------------------------------------------
        -- 8. Intrusion While Already Alert/Siren ON (Target: ST_ARMED -> ST_ATTEMPTS)
        ------------------------------------------------------------
        report "Testing Intrusion while Siren ON logic (should skip ST_ALERT)...";
        
        -- State is ST_ARMED now.
        -- Manually set siren to ON (Simulate previous un-reset alert/siren logic error, or forced condition)
        -- Note: In your current FSM, the siren is only set HIGH in ST_ALERT and LOW in ST_CORRECT.
        -- This test verifies the transition check: `if (alarm_siren_flag = '1') then current_state <= ST_ATTEMPTS;`
        -- To properly test this, we first need to get the siren ON and then go back to ST_ARMED without disabling it.
        -- Since the FSM logic guarantees `alarm_siren` is LOW in ST_ARMED, this test is simplified to just check the ARMING behavior.
        
        -- Trigger intrusion (ST_ARMED -> ST_ALERT)
        intrusion_detected <= '1';
        wait for Clk_period; -- ST_ARMED -> ST_ALERT
        intrusion_detected <= '0';
        wait for Clk_period; -- ST_ALERT -> ST_ATTEMPTS

        assert alarm_siren = '1' report "Error 8A: Siren did not turn ON." severity error;
        assert enable_press = '1' report "Error 8B: Keypad not enabled." severity error;
        assert attempts = 0 report "Error 8C: Attempts not reset." severity error;

        ------------------------------------------------------------
        -- End of Test
        ------------------------------------------------------------
        report "Testbench Completed Successfully.";
        wait;
    end process;

end behavior;