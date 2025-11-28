--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data_TB.vhd
-- Author: Roni Shifrin
-- Ver: 1
-- Created Date: 27/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data_TB is
end Display_data_TB;

architecture test_bench of Display_data_TB is

    -- Clock Period
    constant CLK_PERIOD : time := 10 ns;

    -- TB Signals
    signal TB_clk      : std_logic := '0';
    signal TB_rst      : std_logic := '0';
    signal TB_state    : std_logic_vector(2 downto 0) := "000";
    signal TB_attempts : integer range 0 to 7 := 0;
    signal TB_data     : std_logic_vector(7 downto 0);

begin

    -- Instantiate DUT
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
        loop
            TB_clk <= '0';
            wait for CLK_PERIOD / 2;
            TB_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus process
    STIM: process
    begin
        report "--- Display_data Testbench Started ---" severity note;

        -- Apply Reset
        TB_rst <= '1';
        wait for CLK_PERIOD;
        TB_rst <= '0';
        wait for CLK_PERIOD;

        -- Test System OFF -> "000" => ASCII '0'
        TB_state <= "000"; wait for CLK_PERIOD;
        assert TB_data = x"30"
            report "ERROR: State 000 expected ASCII '0'" severity error;

        -- Test ARMED -> "001" => ASCII '8'
        TB_state <= "001"; wait for CLK_PERIOD;
        assert TB_data = x"38"
            report "ERROR: State 001 expected ASCII '8'" severity error;

        -- Test ALERT -> "010" => ASCII 'A'
        TB_state <= "010"; wait for CLK_PERIOD;
        assert TB_data = x"41"
            report "ERROR: State 010 expected ASCII 'A'" severity error;

        -- Test CORRECT CODE -> "011" => ASCII 'F'
        TB_state <= "011"; wait for CLK_PERIOD;
        assert TB_data = x"46"
            report "ERROR: State 011 expected ASCII 'F'" severity error;

        -- Test ATTEMPTS Mode -> "100"
        TB_state <= "100";
        for i in 0 to 7 loop
            TB_attempts <= i;
            wait for CLK_PERIOD;
            assert TB_data = std_logic_vector(to_unsigned(i + 48, 8))
                report "ERROR: Attempts=" & integer'image(i) severity error;
        end loop;

        -- Test unknown states ? '-'
        TB_state <= "101"; wait for CLK_PERIOD; assert TB_data = x"2D" severity error;
        TB_state <= "110"; wait for CLK_PERIOD; assert TB_data = x"2D" severity error;
        TB_state <= "111"; wait for CLK_PERIOD; assert TB_data = x"2D" severity error;

        report "--- Display_data Testbench Completed Successfully ---" severity note;
        wait;
    end process;

end architecture test_bench;
