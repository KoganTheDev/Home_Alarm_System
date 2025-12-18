--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Code_register_TB.vhd
-- Author: Yuval Kogan
-- Ver: 1
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Code_register_TB is
end Code_register_TB;

architecture behavior of Code_register_TB is

    -- Component Declaration for the Unit Under Test (UUT)
    component Code_register
        generic (
            N : INTEGER := 2;
            PASSWORD : STD_LOGIC_VECTOR := "01"
        );
        port (
            Clk          : IN  STD_LOGIC;
            Rst          : IN  STD_LOGIC;        
            bit_in       : IN  STD_LOGIC;
            valid        : IN  STD_LOGIC;
            Code_ready   : OUT STD_LOGIC;
            code_match   : OUT STD_LOGIC;
            code_vector  : OUT STD_LOGIC_VECTOR((N - 1) DOWNTO 0)
        );
    end component;

    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant TEST_N     : integer := 2;
    constant TEST_PASS  : std_logic_vector(1 downto 0) := "01";

    -- Test Signals
    signal Clk          : std_logic := '0';
    signal Rst          : std_logic := '0';
    signal bit_in       : std_logic := '0';
    signal valid        : std_logic := '0';
    signal Code_ready   : std_logic;
    signal code_match   : std_logic;
    signal code_vector  : std_logic_vector(TEST_N-1 downto 0);

begin

    -- Instantiate the UUT
    uut: Code_register
        generic map (
            N => TEST_N,
            PASSWORD => TEST_PASS
        )
        port map (
            Clk         => Clk,
            Rst         => Rst,
            bit_in      => bit_in,
            valid       => valid,
            Code_ready  => Code_ready,
            code_match  => code_match,
            code_vector => code_vector
        );

    -- Clock Generation
    clk_process : process
    begin
        Clk <= '0'; wait for CLK_PERIOD/2;
        Clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Process
    stim_proc: process
        -- Helper procedure to simulate a single valid bit entry
        procedure enter_bit(b : std_logic) is
        begin
            wait until falling_edge(Clk);
            bit_in <= b;
            valid  <= '1';
            wait until falling_edge(Clk);
            valid  <= '0';
        end procedure;

    begin
        report "Starting Extensive Code_register Test..." severity note;

        -----------------------------------------------------------
        -- TEST 1: ASYNCHRONOUS RESET & HIGH IMPEDANCE
        -----------------------------------------------------------
        Rst <= '1';
        wait for 15 ns;
        assert (Code_ready = 'Z' and code_match = 'Z')
            report "FAIL T1: Outputs must be 'Z' during Reset" severity failure;
        
        Rst <= '0';
        wait until falling_edge(Clk);
        assert (Code_ready = '0' and code_match = '0')
            report "FAIL T1: Outputs must be '0' after Reset release" severity failure;

        -----------------------------------------------------------
        -- TEST 2: CORRECT PASSWORD ENTRY ("0" -> "1")
        -----------------------------------------------------------
        report "Test 2: Correct Password '01'";
        enter_bit('0'); -- Bit 1
        assert Code_ready = '0' report "FAIL T2: Ready high too early" severity failure;
        
        enter_bit('1'); -- Bit 2 (Completes N)
        assert (Code_ready = '1' and code_match = '1') 
            report "FAIL T2: Match not detected on Nth bit" severity failure;
        
        -- Check auto-clear on next cycle
        wait until falling_edge(Clk);
        assert (Code_ready = '0' and code_match = '0') 
            report "FAIL T2: Flags must pulse for 1 cycle only" severity failure;

        -----------------------------------------------------------
        -- TEST 3: INCORRECT PASSWORD ENTRY ("1" -> "1")
        -----------------------------------------------------------
        report "Test 3: Incorrect Password '11'";
        enter_bit('1');
        enter_bit('1');
        assert (Code_ready = '1' and code_match = '0') 
            report "FAIL T3: Match asserted for wrong code" severity failure;
        
        wait until falling_edge(Clk); -- Auto-reset

        -----------------------------------------------------------
        -- TEST 4: VALID SIGNAL WITH GAPS
        -----------------------------------------------------------
        report "Test 4: Gapped valid signals";
        enter_bit('0');
        wait for 2 * CLK_PERIOD; -- Idle
        enter_bit('1');
        assert (Code_ready = '1' and code_match = '1') 
            report "FAIL T4: Gapped entry failed" severity failure;

        wait until falling_edge(Clk);

        -----------------------------------------------------------
        -- TEST 5: BACK-TO-BACK ENTRIES
        -----------------------------------------------------------
        report "Test 5: Back-to-back passwords";
        -- First Entry
        enter_bit('0'); enter_bit('1');
        assert code_match = '1' report "FAIL T5: First entry failed" severity failure;
        wait until falling_edge(Clk); -- Wait for clear
        
        -- Second Entry immediately
        enter_bit('0'); enter_bit('1');
        assert code_match = '1' report "FAIL T5: Second entry failed" severity failure;

        report "--- ALL TESTS PASSED SUCCESSFULLY ---" severity note;
        wait;
    end process;

end architecture;