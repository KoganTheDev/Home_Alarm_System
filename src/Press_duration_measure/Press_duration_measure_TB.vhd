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

    component Press_duration_measure
        generic ( K : integer := 3 );
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

    constant clk_period : time := 10 ns;
    constant TEST_K     : integer := 3;

begin

    uut: Press_duration_measure
        generic map ( K => TEST_K )
        port map (
            Clk => tb_Clk,
            Rst => tb_Rst,
            btn_in => tb_btn_in,
            enable => tb_enable,
            bit_out => tb_bit_out,
            bit_valid => tb_bit_valid
        );

    -- Clock Generation
    clk_process : process
    begin
        tb_Clk <= '0'; wait for clk_period/2;
        tb_Clk <= '1'; wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
        -- Helper procedure to simulate a button press for N cycles
        procedure press_button(cycles : integer) is
        begin
            wait until falling_edge(tb_Clk);
            tb_btn_in <= '1';
            for i in 1 to cycles loop
                wait until falling_edge(tb_Clk);
            end loop;
            tb_btn_in <= '0';
        end procedure;

    begin
        report "--- Starting Extensive Testbench ---" severity note;

        -----------------------------------------------------------
        -- TEST 1: ASYNCHRONOUS RESET
        -----------------------------------------------------------
        tb_Rst <= '1';
        wait for 15 ns;
        assert (tb_bit_out = 'Z' and tb_bit_valid = 'Z')
            report "FAIL TEST 1: Reset did not result in 'Z' outputs" severity failure;
        
        tb_Rst <= '0';
        tb_enable <= '1';
        wait until falling_edge(tb_Clk);
        assert (tb_bit_out = '0' and tb_bit_valid = '0')
            report "FAIL TEST 1: Post-reset state not '0'" severity failure;

        -----------------------------------------------------------
        -- TEST 2: SHORT PRESS (2 Cycles, K=3)
        -----------------------------------------------------------
        report "TEST 2: Short Press (2 cycles)...";
        press_button(2); 

        -- Logic detects falling edge at the next Rising Edge.
        -- We check on the Falling Edge to ensure signal stability.
        wait until falling_edge(tb_Clk); -- Pulse Cycle 1
        assert (tb_bit_valid = '1' and tb_bit_out = '0') report "FAIL TEST 2: Pulse 1" severity failure;
        wait until falling_edge(tb_Clk); -- Pulse Cycle 2
        assert (tb_bit_valid = '1' and tb_bit_out = '0') report "FAIL TEST 2: Pulse 2" severity failure;
        wait until falling_edge(tb_Clk); -- Pulse End
        assert (tb_bit_valid = '0') report "FAIL TEST 2: Pulse did not end" severity failure;

        -----------------------------------------------------------
        -- TEST 3: LONG PRESS (4 Cycles, K=3)
        -----------------------------------------------------------
        report "TEST 3: Long Press (4 cycles)...";
        wait for 2 * clk_period;
        press_button(4);

        wait until falling_edge(tb_Clk); -- Pulse Cycle 1
        assert (tb_bit_valid = '1' and tb_bit_out = '1') report "FAIL TEST 3: Pulse 1" severity failure;
        wait until falling_edge(tb_Clk); -- Pulse Cycle 2
        assert (tb_bit_valid = '1' and tb_bit_out = '1') report "FAIL TEST 3: Pulse 2" severity failure;

        -----------------------------------------------------------
        -- TEST 4: DISABLED STATE
        -----------------------------------------------------------
        report "TEST 4: Enable = '0' Suppression...";
        tb_enable <= '0';
        wait for 2 * clk_period;
        press_button(5); -- Long press, but disabled
        
        wait for 3 * clk_period;
        assert (tb_bit_valid = '0') report "FAIL TEST 4: Output produced while disabled" severity failure;

        -----------------------------------------------------------
        -- TEST 5: EXACT BOUNDARY (3 Cycles, K=3)
        -----------------------------------------------------------
        report "TEST 5: Boundary Press (3 cycles, K=3)...";
        tb_enable <= '1';
        wait for 2 * clk_period;
        press_button(3); 

        wait until falling_edge(tb_Clk);
        assert (tb_bit_valid = '1' and tb_bit_out = '1') report "FAIL TEST 5: Boundary 3 cycles should be LONG" severity failure;

        report "--- ALL TESTS PASSED SUCCESSFULLY ---" severity note;
        wait;
    end process;
end architecture;
