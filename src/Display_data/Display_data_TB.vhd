--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data_TB.vhd
-- Author: Roni Shifrin
-- Ver: 0
-- Created Date: 27/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data_TB is
end Display_data_TB;

architecture test_bench of Display_data_TB is

    component Display_data is
    generic (
        N_bit : integer := 2           
    ); 

    port (
        clk         : in  std_logic;
        Rst         : in  std_logic;
        state_code  : in  std_logic_vector(N_bit downto 0);
        attempts    : in  integer range 0 to 7;
        data        : out std_logic_vector(7 downto 0)  -- ASCII output
    );
    end component Display_data;

    constant CLK_PERIOD : time := 10 ns;

    signal TB_Clk      : std_logic := '0';
    signal TB_Rst      : std_logic := '0';
    signal TB_state    : std_logic_vector(2 downto 0) := "000"; -- N_bit=2 => 3 bits
    signal TB_attempts : integer range 0 to 7 := 0;
    signal TB_data     : std_logic_vector(7 downto 0);
begin

    DUT: Display_data
        port map (
            clk => TB_Clk,
            Rst => TB_Rst,
            state_code => TB_state,
            attempts => TB_attempts,
            data => TB_data
        );

    -- Clock
    CLK_PROC: process
    begin
        loop
            TB_Clk <= '0';
            wait for CLK_PERIOD/2;
            TB_Clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    STIM: process
    begin
        report "--- Display_data TB start ---" severity note;

        -- Reset behavior: data should be Zs during reset
        TB_Rst <= '1';
        wait for CLK_PERIOD;
        assert TB_data = (others => 'Z') report "Reset: data not Zs" severity error;
        TB_Rst <= '0';
        wait for CLK_PERIOD;

        -- Test OFF state "000" -> '0' (0x30)
        TB_state <= "000"; wait for CLK_PERIOD;
        assert TB_data = x"30" report "State 000 expected '0'" severity error;

        -- Test ARMED state "001" -> '8'
        TB_state <= "001"; wait for CLK_PERIOD;
        assert TB_data = x"38" report "State 001 expected '8'" severity error;

        -- Test ALERT state "010" -> 'A'
        TB_state <= "010"; wait for CLK_PERIOD;
        assert TB_data = x"41" report "State 010 expected 'A'" severity error;

        -- Test CORRECT CODE "011" -> 'F'
        TB_state <= "011"; wait for CLK_PERIOD;
        assert TB_data = x"46" report "State 011 expected 'F'" severity error;

        -- Test ATTEMPTS mode "100" -> ASCII digit attempts
        for i in 0 to 7 loop
            TB_attempts <= i;
            TB_state <= "100";
            wait for CLK_PERIOD;
            assert TB_data = std_logic_vector(to_unsigned(i + 48, 8)) report
                "Attempts mode: expected ASCII '" & integer'image(i) & "'" severity error;
        end loop;

        -- Test unknown states -> '-'
        TB_state <= "101"; wait for CLK_PERIOD; assert TB_data = x"2D" report "State 101 expected '-'" severity error;
        TB_state <= "110"; wait for CLK_PERIOD; assert TB_data = x"2D" report "State 110 expected '-'" severity error;
        TB_state <= "111"; wait for CLK_PERIOD; assert TB_data = x"2D" report "State 111 expected '-'" severity error;

        -- Test Reset sets Zs again while active
        TB_Rst <= '1'; wait for CLK_PERIOD; assert TB_data = (others => 'Z') report "Reset: data not Zs after assert" severity error;
        TB_Rst <= '0'; wait for CLK_PERIOD;

        report "--- Display_data TB completed successfully ---" severity note;
        wait;
    end process STIM;

end architecture test_bench;
