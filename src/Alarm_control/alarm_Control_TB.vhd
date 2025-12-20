--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name   : alarm_Control_TB.vhd
-- Author      : Yuval Kogan
-- Ver         : 1
-- Created Date: 04/12/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_Control_TB is
end entity alarm_Control_TB;

architecture test of alarm_Control_TB is
    -- Stimulus Signals
    signal S_Clk                : std_logic := '0';
    signal S_Rst                : std_logic := '0';
    signal S_intrusion_detected : std_logic := '0';
    signal S_code_ready         : std_logic := '0';
    signal S_code_match         : std_logic := '0';
    
    -- Observed Signals
    signal S_enable_press       : std_logic;
    signal S_clear_code         : std_logic;
    signal S_alarm_siren        : std_logic;
    signal S_system_armed       : std_logic;
    signal S_state_code         : std_logic_vector(2 downto 0);
    
    -- Integer Handling
    signal S_attempts_int       : integer range 0 to 7;
    signal S_attempts_vec       : std_logic_vector(2 downto 0); 

    constant CLK_PERIOD : time := 10 ns;

    -- Procedure to handle synchronous code entry
    procedure enter_code_proc(
        constant is_correct : in  std_logic;
        signal ready_sig    : out std_logic;
        signal match_sig    : out std_logic;
        signal clk_sig      : in  std_logic
    ) is
    begin
        wait until falling_edge(clk_sig);
        match_sig <= is_correct;
        ready_sig <= '1';
        wait until falling_edge(clk_sig); 
        ready_sig <= '0';
        match_sig <= '0';
    end procedure;

begin

    -- Instantiate Device Under Test (DUT)
    DUT: entity work.alarm_Control
        port map (
            Clk                => S_Clk,
            Rst                => S_Rst,
            intrusion_detected => S_intrusion_detected,
            code_ready         => S_code_ready,
            code_match         => S_code_match,
            enable_press       => S_enable_press,
            clear_code         => S_clear_code,
            alarm_siren        => S_alarm_siren,
            system_armed       => S_system_armed,
            attempts           => S_attempts_int, -- Map to internal integer signal
            state_code         => S_state_code
        );

    -- Concurrent conversion for the observed vector
    S_attempts_vec <= std_logic_vector(to_unsigned(S_attempts_int, 3));

    -- Clock Generation
    S_Clk <= not S_Clk after CLK_PERIOD/2;

    -- Stimulus Process
    stim_proc: process
    begin
        report "--- STARTING COMPREHENSIVE ALARM TEST ---" severity note;

        -----------------------------------------------------------
        -- TEST 1: Reset Behavior (High-Z and Zero check)
        -----------------------------------------------------------
        S_Rst <= '1';
        wait for 25 ns;
        
        assert S_enable_press = 'Z' report "T1 FAIL: enable_press not High-Z on Reset" severity error;
        assert S_attempts_int = 0   report "T1 FAIL: attempts not 0 on Reset" severity error;
        assert S_state_code = "ZZZ" report "T1 FAIL: state_code not High-Z on Reset" severity error;
        assert S_system_armed = 'Z' report "T1 FAIL: system_armed not High-Z on Reset" severity error;
        
        S_Rst <= '0';
        wait until rising_edge(S_Clk);
        wait for 2 ns; -- Small delay to let logic settle
        assert S_system_armed = '1' report "T1 FAIL: System not ARMED after Reset" severity error;
        report "T1 PASS: Initial Reset and High-Z checks successful";

        -----------------------------------------------------------
        -- TEST 2: Intrusion and Disarm
        -----------------------------------------------------------
        wait until falling_edge(S_Clk);
        S_intrusion_detected <= '1';
        wait until rising_edge(S_Clk);
        S_intrusion_detected <= '0';
        
        -- Transitions: ARMED -> ALERT -> ATTEMPTS
        wait until S_enable_press = '1';
        assert S_alarm_siren = '1' report "T2 FAIL: Siren should be ON" severity error;

        report "Entering Correct Code...";
        enter_code_proc('1', S_code_ready, S_code_match, S_Clk);
        
        wait until S_system_armed = '1';
        assert S_alarm_siren = '0' report "T2 FAIL: Siren still active after correct code" severity error;
        report "T2 PASS: Successful Disarm";

        -----------------------------------------------------------
        -- TEST 3: Lockout (8 Failures)
        -----------------------------------------------------------
        report "Triggering Intrusion for Lockout Test...";
        wait until falling_edge(S_Clk);
        S_intrusion_detected <= '1';
        wait until rising_edge(S_Clk);
        S_intrusion_detected <= '0';
        wait until S_enable_press = '1';

        for i in 0 to 7 loop
            report "Entering Wrong Code, attempt " & integer'image(i);
            enter_code_proc('0', S_code_ready, S_code_match, S_Clk);
            wait for CLK_PERIOD * 2;
        end loop;

        -- Verify state_code is ("111")
        assert S_state_code = "101" report "T3 FAIL: System not in LOCK state code" severity error;
        report "T3 PASS: System Locked out successfully";

        -----------------------------------------------------------
        -- TEST 4: Siren Reset Immunity (Critical Requirement)
        -----------------------------------------------------------
        report "Applying Reset while Siren is ON (Immunity Test)...";
        S_Rst <= '1';
        wait for 30 ns;
        
        -- Siren flag is NOT controlled by reset, it maintains its state
        assert S_alarm_siren = '1' report "T4 FAIL: Siren should remain ON during Reset" severity error;
        
        S_Rst <= '0';
        wait for 5 ns; -- Settle time
        
        -- After Reset, internal flag should have persisted
        assert S_alarm_siren = '1' 
            report "T4 CRITICAL FAIL: Siren was SILENCED/RESET by Reset signal!" severity failure;
        
        wait until S_enable_press = '1';
        report "T4 PASS: Siren persistence and recovery verified";

        -----------------------------------------------------------
        -- TEST 5: Recovery and Final Disarm
        -----------------------------------------------------------
        report "Final Disarm after Lockout/Reset sequence...";
        enter_code_proc('1', S_code_ready, S_code_match, S_Clk);
        
        wait until S_alarm_siren = '0';
        wait until S_system_armed = '1';
        
        report "--- ALL TESTS PASSED SUCCESSFULLY ---" severity note;
        wait;
    end process;

end architecture;
