--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Code_register_TB.vhd
-- Author: Yuval Kogan
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Code_register_TB is
end Code_register_TB;

architecture test_bench of Code_register_TB is

    -- Component Declaration
    component Code_register
        generic (
            N : INTEGER := 2;
            PASSWORD : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01"
        );
        port (
            Clk          : IN  STD_LOGIC;
            Rst          : IN  STD_LOGIC;        
            bit_in       : IN  STD_LOGIC;
            valid        : IN  STD_LOGIC;
            
            Code_ready   : OUT STD_LOGIC;
            code_match   : OUT STD_LOGIC;
            code_vector  : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
        );
    end component;

    -- Constants for Clock Generation
    constant CLK_PERIOD : time := 10 ns;

    -- Signals for DUT ports
    signal S_Clk        : STD_LOGIC := '0';
    signal S_Rst        : STD_LOGIC := '1'; -- Start in reset
    signal S_bit_in     : STD_LOGIC := '0';
    signal S_valid      : STD_LOGIC := '0';

    -- Signals for DUT ports (outputs)
    signal S_Code_ready : STD_LOGIC;
    signal S_code_match : STD_LOGIC;
    signal S_code_vector: STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- Helper function to convert std_logic_vector to string for reporting
    function slv_to_string (data : STD_LOGIC_VECTOR) return STRING is
        variable result : STRING(1 to data'length);
    begin
        for i in data'range loop
            if data(i) = '1' then
                result(i - data'low + 1) := '1';
            elsif data(i) = '0' then
                result(i - data'low + 1) := '0';
            else
                result(i - data'low + 1) := '-'; -- Undefined state
            end if;
        end loop;
        return result;
    end function slv_to_string;

begin

    -- Instantiate the Device Under Test (DUT)
    DUT : Code_register
        generic map (
            N => 2,
            PASSWORD => "01" -- Default password
        )
        port map (
            Clk         => S_Clk,
            Rst         => S_Rst,
            bit_in      => S_bit_in,
            valid       => S_valid,
            Code_ready  => S_Code_ready,
            code_match  => S_code_match,
            code_vector => S_code_vector
        );

    -- Clock Generation Process
    P_CLK : process
    begin
        loop
            S_Clk <= '0';
            wait for CLK_PERIOD / 2;
            S_Clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process P_CLK;

    -- Stimulus Generation Process
    P_STIM : process
        constant WAIT_CLK : time := CLK_PERIOD;
    begin
        report "--- Simulation Start ---" severity NOTE;
        report "Default Password: ""01""" severity NOTE;
        
        
        -- Initial Reset Check
        S_Rst <= '1';
        wait for CLK_PERIOD * 2;
        report "Checking Reset functionality..." severity NOTE;
        
        -- Release Reset
        S_Rst <= '0';
        wait for CLK_PERIOD * 2; -- Wait for signals to stabilize after reset release
        
        -- Correct Code Entry: Sequence '0', '1' (Match) => "01"
        report "--- Test 1: Correct Code Entry (Input: '0', '1') ---" severity NOTE;
        
        -- 1st bit: '0' (Clock Edge 1)
        S_bit_in <= '0'; 
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=1, Vector=X0
        
        report "T1: 1st bit '0' entered. Code vector: " & slv_to_string(S_code_vector) & 
               ", Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;
        assert S_Code_ready = '0' report "Test 1 Failed: Ready asserted too early (bit 1)" severity ERROR;

        -- 2nd bit: '1' (Clock Edge 2 - Final bit registered and output asserted)
        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=2, Vector=01. Outputs asserted ('1').
        
        -- Deassert Valid immediately after registration
        S_valid <= '0';
        
        report "T1: 2nd bit '1' entered. Code vector: " & slv_to_string(S_code_vector) & 
               ", Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;
        
        assert S_Code_ready = '1' report "Test 1 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '1' report "Test 1 Failed: Code_match should be '1'" severity FAILURE;
        assert S_code_vector = "01" report "Test 1 Failed: Code_vector incorrect" severity FAILURE;

        -- Wait one more clock cycle to observe the match signal synchronously resetting
        wait for WAIT_CLK; -- State: Counter=0, Vector=00. Outputs reset ('0').
        
        -- Check if reset occurs on the next cycle
        report "T1: Cycle after match reset. Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;
        assert S_Code_ready = '0' report "Test 1 Failed: Ready should be '0' after match" severity ERROR;
        assert S_code_match = '0' report "Test 1 Failed: Match should be '0' after 1 cycle" severity FAILURE;


        -- Incorrect Code Entry: Sequence '1', '1' (No Match)
        report "--- Test 2: Incorrect Code Entry (Input: '1', '1') ---" severity NOTE;

        -- 1st bit: '1'
        S_bit_in <= '1'; 
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=1, Vector=X1
        
        -- 2nd bit: '1' (Final bit registered and output asserted)
        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=2, Vector=11. Output ready='1', match='0'.
        S_valid <= '0';
        
        -- *** CHECK FINAL STATE ***
        report "T2: Code '11' entered. Code vector: " & slv_to_string(S_code_vector) & 
               ", Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;

        assert S_Code_ready = '1' report "Test 2 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '0' report "Test 2 Failed: Code_match should be '0'" severity FAILURE;
        assert S_code_vector = "11" report "Test 2 Failed: Code_vector incorrect" severity FAILURE;
        
        wait for WAIT_CLK; -- State: Counter=0, Vector=00. Outputs reset ('0').
        
        -- reset
        assert S_Code_ready = '0' report "Test 2 Failed: Ready should be '0' after attempt" severity ERROR;
        
        -- Test Valid Signal: Incomplete Code (One bit, then wait)
        report "--- Test 3: Incomplete Code (Input: '0', then wait) ---" severity NOTE;
        
        -- 1st bit: '0'
        S_bit_in <= '0'; 
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=1, Vector=X0
        
        S_valid <= '0';
        
        -- Wait for several clock cycles without a valid input
        wait for WAIT_CLK * 3;
        
        report "T3: Incomplete code, waiting. Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;
        
        -- Check state - should not be ready and not match
        assert S_Code_ready = '0' report "Test 3 Failed: Ready asserted incorrectly" severity FAILURE;
        assert S_code_match = '0' report "Test 3 Failed: Match asserted incorrectly" severity FAILURE;

        -- Test Valid Signal: Completing the Code (Input: '1')
        report "--- Test 4: Completing the Code (Input: '1') ---" severity NOTE;

        -- The counter is at 1 from Test 3. Only one more bit needed.
        S_bit_in <= '1'; -- This is the 2nd bit, completing the correct sequence "01"
        S_valid  <= '1';
        wait for WAIT_CLK; -- State: Counter=2, Vector=01. Outputs ready='1', match='1'.
        S_valid <= '0';

        report "T4: Final bit '1' entered. Code vector: " & slv_to_string(S_code_vector) & 
               ", Ready: " & STD_LOGIC'IMAGE(S_Code_ready) & ", Match: " & STD_LOGIC'IMAGE(S_code_match) severity NOTE;
        
        assert S_Code_ready = '1' report "Test 4 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '1' report "Test 4 Failed: Code_match should be '1'" severity FAILURE;
        assert S_code_vector = "01" report "Test 4 Failed: Code_vector incorrect" severity FAILURE;

        -- Wait one more clock cycle to observe the match signal resetting
        wait for WAIT_CLK; 
        
        assert S_Code_ready = '0' report "Test 4 Failed: Ready should be '0' after match" severity ERROR;
        assert S_code_match = '0' report "Test 4 Failed: Match should be '0' after 1 cycle" severity FAILURE;

                
        -- PHASE 5: Test All 4 Possible 2-Bit Codes (00, 01, 10, 11)
        report "--- Test 5: Complete 2-bit Code Coverage (00, 10, 11) ---" severity NOTE;

        -- Test 5.1: Code "00" (incorrect)
        report "T5.1: Testing Code '00'" severity NOTE;
        S_bit_in <= '0'; 
        S_valid  <= '1';
        wait for WAIT_CLK;

        S_bit_in <= '0';
        S_valid  <= '1';
        wait for WAIT_CLK;
        S_valid <= '0';

        assert S_Code_ready = '1' report "Test 5.1 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '0' report "Test 5.1 Failed: Code_match should be '0' for '00'" severity FAILURE;
        assert S_code_vector = "00" report "Test 5.1 Failed: Code_vector incorrect" severity FAILURE;

        wait for WAIT_CLK;

        -- Test 5.2: Code "10" (incorrect)
        report "T5.2: Testing Code '10'" severity NOTE;
        S_bit_in <= '1'; 
        S_valid  <= '1';
        wait for WAIT_CLK;

        S_bit_in <= '0';
        S_valid  <= '1';
        wait for WAIT_CLK;
        S_valid <= '0';

        assert S_Code_ready = '1' report "Test 5.2 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '0' report "Test 5.2 Failed: Code_match should be '0' for '10'" severity FAILURE;
        assert S_code_vector = "10" report "Test 5.2 Failed: Code_vector incorrect" severity FAILURE;

        wait for WAIT_CLK;

        -- Test 5.3: Code "11" (incorrect, already tested but included for completeness)
        report "T5.3: Testing Code '11'" severity NOTE;
        S_bit_in <= '1'; 
        S_valid  <= '1';
        wait for WAIT_CLK;

        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK;
        S_valid <= '0';

        assert S_Code_ready = '1' report "Test 5.3 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_match = '0' report "Test 5.3 Failed: Code_match should be '0' for '11'" severity FAILURE;
        assert S_code_vector = "11" report "Test 5.3 Failed: Code_vector incorrect" severity FAILURE;

        wait for WAIT_CLK;

        -- PHASE 6: Test Valid Signal Edge Cases
        report "--- Test 6: Valid Signal Toggling (Mid-Sequence) ---" severity NOTE;

        -- Start entering a code
        S_bit_in <= '0';
        S_valid  <= '1';
        wait for WAIT_CLK; -- Counter=1

        -- Toggle valid OFF and back ON with same bit
        S_valid <= '0';
        wait for WAIT_CLK; -- No change, counter still 1

        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK; -- Counter=2 (but bit_in changed to 1)
        S_valid <= '0';

        report "T6: Code after valid toggling: " & slv_to_string(S_code_vector) & 
            ", Ready: " & STD_LOGIC'IMAGE(S_Code_ready) severity NOTE;

        assert S_Code_ready = '1' report "Test 6 Failed: Code_ready should be '1'" severity FAILURE;
        assert S_code_vector = "01" report "Test 6 Failed: Code should be '01'" severity FAILURE;

        wait for WAIT_CLK;

        -- PHASE 7: Test Multiple Correct Entries Back-to-Back
        report "--- Test 7: Multiple Correct Entries ---" severity NOTE;

        report "T7.1: First correct entry" severity NOTE;
        S_bit_in <= '0'; 
        S_valid  <= '1';
        wait for WAIT_CLK;

        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK;
        S_valid <= '0';

        assert S_code_match = '1' report "Test 7.1 Failed: Match should be '1'" severity FAILURE;

        wait for WAIT_CLK;

        report "T7.2: Second correct entry" severity NOTE;
        S_bit_in <= '0'; 
        S_valid  <= '1';
        wait for WAIT_CLK;

        S_bit_in <= '1';
        S_valid  <= '1';
        wait for WAIT_CLK;
        S_valid <= '0';

        assert S_code_match = '1' report "Test 7.2 Failed: Match should be '1'" severity FAILURE;
        report "T7.2: Second correct entry accepted" severity NOTE;

        wait for WAIT_CLK * 2;

        report "--- Simulation End: All tests completed ---" severity NOTE;
        wait; -- Stop the simulation
    end process P_STIM;
    
end test_bench;