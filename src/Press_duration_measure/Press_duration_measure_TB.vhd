--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Press_duration_measure_TB.vhd
-- Author: Roni Shifrin
-- Ver: 1
-- Created Date: 27/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Press_duration_measure_TB is
end Press_duration_measure_TB;


architecture test_bench of Press_duration_measure_TB is

    component Press_duration_measure is
    generic (
        K : integer := 3  -- threshold in clock cycles for a "long" press
    );
    port (
        Clk      : in  std_logic;
        Rst      : in  std_logic;    -- asynchronous reset
        btn_in   : in  std_logic;    -- raw button input (assumed clean)
        enable   : in  std_logic;    -- measurement enable
        bit_out  : out std_logic;    -- 0 = short, 1 = long
        bit_vaild: out std_logic     -- 2-clock pulse indicating bit_out valid
    );
    end component Press_duration_measure;



    constant CLK_PERIOD : time := 10 ns;
    constant K_VAL : integer := 3; -- must match DUT generic

    -- DUT signals
    signal TB_Clk      : std_logic := '0';
    signal TB_Rst      : std_logic := '0';
    signal TB_btn_in   : std_logic := '0';
    signal TB_enable   : std_logic := '0';
    signal TB_bit_out  : std_logic;
    signal TB_bit_vaild: std_logic;

begin

    DUT: Press_duration_measure
        generic map (K => K_VAL)
        port map (
            Clk => TB_Clk,
            Rst => TB_Rst,
            btn_in => TB_btn_in,
            enable => TB_enable,
            bit_out => TB_bit_out,
            bit_vaild => TB_bit_vaild
        );

    -- Clock generator
    CLK_PROC: process
    begin
        loop
            TB_Clk <= '0';
            wait for CLK_PERIOD/2;
            TB_Clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    STIM_PROC: process
    begin
        report "--- Press_duration_measure TB start ---" severity note;

        -- PHASE 0: Reset behavior
        TB_Rst <= '1';
        TB_enable <= '0';
        TB_btn_in <= '0';
        wait for CLK_PERIOD * 2;
        TB_Rst <= '0';
        wait for CLK_PERIOD;
        assert TB_bit_out = '0' report "Reset: bit_out must be 0" severity error;
        assert TB_bit_vaild = '0' report "Reset: bit_vaild must be 0" severity error;

        -- PHASE 1: Short press (< K) produces bit_out=0
        report "PHASE 1: Short press test" severity note;
        TB_enable <= '1';
        wait for CLK_PERIOD;
        -- press for K-1 cycles (2 cycles)
        TB_btn_in <= '1';
        wait for CLK_PERIOD * 2;
        -- release
        TB_btn_in <= '0';
        -- valid appears starting next clock (implementation detail)
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '1' report "Short press: bit_vaild not asserted on expected cycle" severity error;
        assert TB_bit_out = '0' report "Short press: expected bit_out=0" severity error;
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '1' report "Short press: bit_vaild should be high for 2 cycles" severity error;
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '0' report "Short press: bit_vaild should have returned to 0" severity error;

        -- PHASE 2: Exact threshold press (== K) produces bit_out=1
        report "PHASE 2: Exact threshold press test" severity note;
        wait for CLK_PERIOD;
        TB_btn_in <= '1';
        wait for CLK_PERIOD * K_VAL; -- press for exactly K cycles
        TB_btn_in <= '0';
        wait for CLK_PERIOD; -- wait for valid to start
        assert TB_bit_vaild = '1' report "Exact: bit_vaild not asserted" severity error;
        assert TB_bit_out = '1' report "Exact: expected bit_out=1" severity error;
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '1' report "Exact: bit_vaild should be high for 2 cycles" severity error;
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '0' report "Exact: bit_vaild should have returned to 0" severity error;

        -- PHASE 3: Long press (> K) produces bit_out=1
        report "PHASE 3: Long press test" severity note;
        wait for CLK_PERIOD;
        TB_btn_in <= '1';
        wait for CLK_PERIOD * (K_VAL + 2);
        TB_btn_in <= '0';
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '1' report "Long: bit_vaild not asserted" severity error;
        assert TB_bit_out = '1' report "Long: expected bit_out=1" severity error;
        wait for CLK_PERIOD * 2;
        assert TB_bit_vaild = '0' report "Long: bit_vaild should be low after pulse" severity error;

        -- PHASE 4: Multiple consecutive presses
        report "PHASE 4: Multiple presses" severity note;
        wait for CLK_PERIOD;
        -- short press
        TB_btn_in <= '1'; wait for CLK_PERIOD * 2; TB_btn_in <= '0';
        wait for CLK_PERIOD; assert TB_bit_vaild = '1' severity error; assert TB_bit_out = '0' severity error;
        wait for CLK_PERIOD * 2;
        -- long press
        TB_btn_in <= '1'; wait for CLK_PERIOD * 4; TB_btn_in <= '0';
        wait for CLK_PERIOD; assert TB_bit_vaild = '1' severity error; assert TB_bit_out = '1' severity error;
        wait for CLK_PERIOD * 2;

        -- PHASE 5: Enable low - presses ignored
        report "PHASE 5: Enable low test" severity note;
        TB_enable <= '0';
        wait for CLK_PERIOD;
        TB_btn_in <= '1';
        wait for CLK_PERIOD * 4;
        TB_btn_in <= '0';
        wait for CLK_PERIOD * 2;
        assert TB_bit_vaild = '0' report "Enable low: bit_vaild should not assert" severity error;

        -- PHASE 6: Reset during press
        report "PHASE 6: Reset during press" severity note;
        TB_enable <= '1';
        wait for CLK_PERIOD;
        TB_btn_in <= '1';
        wait for CLK_PERIOD * 2;
        TB_Rst <= '1';
        wait for CLK_PERIOD;
        TB_Rst <= '0';
        wait for CLK_PERIOD;
        assert TB_bit_vaild = '0' report "Reset during press: bit_vaild should be 0" severity error;
        assert TB_bit_out = '0' report "Reset during press: bit_out should be 0" severity error;

        report "--- Press_duration_measure TB completed successfully ---" severity note;
        wait;
    end process STIM_PROC;

end architecture test_bench;
