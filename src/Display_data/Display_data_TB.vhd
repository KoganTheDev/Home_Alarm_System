--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data_TB.vhd
-- Author: Roni Shifrin
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data_TB is
end Display_data_TB;

architecture test_bench of Display_data_TB is

    -- Clock Period
    constant CLK_PERIOD : time := 10 ns;

    -- TB Signals (Types match Display_data exactly)
    signal TB_clk      : std_logic := '0';
    signal TB_rst      : std_logic := '0';
    signal TB_state    : std_logic_vector(2 downto 0) := "000";
    signal TB_attempts : integer range 0 to 7 := 0;
    signal TB_data     : std_logic_vector(7 downto 0);

begin

    -- Instantiate DUT using direct entity instantiation
    -- This bypasses component declaration mismatches.
    DUT: entity work.Display_data
        port map (
            clk        => TB_clk,
            Rst        => TB_rst,
            state_code => TB_state,
            attempts   => TB_attempts,
            data       => TB_data
        );

    -- Clock generation
    CLK_PROC: process
    begin
        while now < 500 ns loop  -- Stop after 500ns
            TB_clk <= '0';
            wait for CLK_PERIOD / 2;
            TB_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    STIM: process
    begin
        report "--- Display_data Testbench Started ---" severity note;

        -- 1. Apply Reset
        TB_rst <= '1';
        wait for CLK_PERIOD * 2;
        TB_rst <= '0';
        wait for CLK_PERIOD;

        -- 2. Test System OFF -> "000" => ASCII '0' (x30)
        TB_state <= "000"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"30") report "ERROR: State 000 mismatch" severity error;

        -- 3. Test ARMED -> "001" => ASCII '8' (x38)
        TB_state <= "001"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"38") report "ERROR: State 001 mismatch" severity error;

        -- 4. Test ALERT -> "010" => ASCII 'A' (x41)
        TB_state <= "010"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"41") report "ERROR: State 010 mismatch" severity error;

        -- 5. Test CORRECT -> "011" => ASCII 'F' (x46)
        TB_state <= "011"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"46") report "ERROR: State 011 mismatch" severity error;

        -- 6. Test ATTEMPTS Mode -> "100" (Dynamic Offset)
        TB_state <= "100";
        for i in 0 to 7 loop
            TB_attempts <= i;
            wait until rising_edge(TB_clk); wait for 1 ns;
            -- Check if data = ASCII '0' + i (e.g., if i=1, data=x31)
            assert (TB_data = std_logic_vector(to_unsigned(i + 48, 8)))
                report "ERROR: Attempts count " & integer'image(i) & " mismatch" severity error;
        end loop;

        -- 7. Test LOCK State -> "101" => ASCII '7' (x37)
        TB_state <= "101"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"37") report "ERROR: State 101 mismatch" severity error;

        -- 8. Test Unknown State -> "110" => DASH (x2D)
        TB_state <= "110"; 
        wait until rising_edge(TB_clk); wait for 1 ns;
        assert (TB_data = x"2D") report "ERROR: State 110 mismatch" severity error;

        report "--- Display_data Testbench Completed Successfully ---" severity note;
        wait;
    end process;

end architecture test_bench;