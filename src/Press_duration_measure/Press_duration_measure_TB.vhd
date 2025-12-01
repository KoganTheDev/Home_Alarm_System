--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Press_duration_measure_TB.vhd
-- Author: Roni Shifrin
-- Ver: 1
-- Created Date: 23/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Press_duration_measure_tb is
end Press_duration_measure_tb;

architecture behavior of Press_duration_measure_tb is

    -- Component Declaration
    component Press_duration_measure
        generic (
            K : integer := 3
        );
        port (
            Clk       : in  std_logic;
            Rst       : in  std_logic;
            btn_in    : in  std_logic;
            enable    : in  std_logic;
            bit_out   : out std_logic;
            bit_valid : out std_logic
        );
    end component;

    -- Test Signals
    signal tb_Clk       : std_logic := '0';
    signal tb_Rst       : std_logic := '0';
    signal tb_btn_in    : std_logic := '0';
    signal tb_enable    : std_logic := '0';
    signal tb_bit_out   : std_logic;
    signal tb_bit_valid : std_logic;

    -- Simulation Constants
    constant clk_period : time := 10 ns;
    constant TEST_K     : integer := 5; -- Threshold for TB

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Press_duration_measure
        generic map (
            K => TEST_K -- Set threshold to 5 cycles for this test
        )
        port map (
            Clk       => tb_Clk,
            Rst       => tb_Rst,
            btn_in    => tb_btn_in,
            enable    => tb_enable,
            bit_out   => tb_bit_out,
            bit_valid => tb_bit_valid
        );

    -- Clock Process
    clk_process : process
    begin
        tb_Clk <= '0';
        wait for clk_period/2;
        tb_Clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        report "Starting Simulation..." severity note;

        
        -- 1. Reset System
        tb_Rst <= '1';
        wait for 20 ns;
        tb_Rst <= '0';
        tb_enable <= '1'; -- Enable the system
        wait for clk_period;

        -- 2. Test SHORT Press (2 cycles, K=5)
        report "Test 1: Generating SHORT Press (2 cycles)..." severity note;
        
        tb_btn_in <= '1';
        wait for 2 * clk_period; -- Hold for 2 clocks
        tb_btn_in <= '0';        -- Release
        
        -- Wait for processing (needs 1-2 clocks to detect edge and output)
        wait for 2 * clk_period; 

        -- Check results
        assert tb_bit_valid = '1' report "Error: Valid bit not High for Short Press" severity error;
        assert tb_bit_out = '0'   report "Error: Output should be '0' (Short)" severity error;
        
        report "Short Press Verified." severity note;
        
        -- Wait for valid pulse to finish (2 cycles total)
        wait for 2 * clk_period; 
        assert tb_bit_valid = '0' report "Error: Valid bit did not go Low" severity error;

        wait for 20 ns; -- Gap between tests

        
        -- 3. Test LONG Press (7 cycles, K=5)
        report "Test 2: Generating LONG Press (7 cycles)..." severity note;
        
        tb_btn_in <= '1';
        wait for 7 * clk_period; -- Hold for 7 clocks
        tb_btn_in <= '0';        -- Release
        
        wait for 2 * clk_period; -- Allow edge detection
        
        -- Check results
        assert tb_bit_valid = '1' report "Error: Valid bit not High for Long Press" severity error;
        assert tb_bit_out = '1'   report "Error: Output should be '1' (Long)" severity error;
        
        report "Long Press Verified." severity note;
        wait for 2 * clk_period;

        -- 4. Test ENABLE = '0' (Ignored Press)
        report "Test 3: Testing Disabled State..." severity note;
        
        tb_enable <= '0'; -- Disable
        wait for clk_period;
        
        tb_btn_in <= '1';
        wait for 10 * clk_period; -- Very long press
        tb_btn_in <= '0';
        
        wait for 2 * clk_period;
        
        assert tb_bit_valid = '0' report "Error: Generated output while Disabled!" severity error;
        report "Disabled State Verified." severity note;
 
        -- End Simulation
        report "Simulation Completed Successfully." severity note;
        wait;
    end process;

end behavior;