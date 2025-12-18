library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HA_System_TB is
end HA_System_TB;

architecture behavior of HA_System_TB is
    signal tb_Clk, tb_Rst, tb_pass_btn : std_logic := '0';
    signal tb_door_raw, tb_window_raw, tb_motion_raw : std_logic := '0';
    signal tb_alarm_siren, tb_system_armed : std_logic;
    signal tb_display_data : std_logic_vector(7 downto 0);
    signal tb_status_code : std_logic_vector(2 downto 0);
    constant CLK_PERIOD : time := 10 ns;

    -- Helper function to convert std_logic_vector to string for reporting
    function vec_to_str(vec : std_logic_vector) return string is
        variable result : string(1 to vec'length);
    begin
        for i in 0 to vec'length - 1 loop
            if vec(vec'left - i) = '1' then result(i + 1) := '1';
            elsif vec(vec'left - i) = '0' then result(i + 1) := '0';
            else result(i + 1) := 'X';
            end if;
        end loop;
        return result;
    end function;

    procedure do_press(constant cycles : in integer; signal btn : out std_logic; signal clk : in std_logic) is
    begin
        wait until falling_edge(clk); btn <= '1';
        for i in 1 to cycles loop wait until falling_edge(clk); end loop;
        btn <= '0'; wait for CLK_PERIOD * 5;
    end procedure;

begin
    uut: entity work.HA_System port map (
        Clk => tb_Clk, Rst => tb_Rst, pass_btn => tb_pass_btn,
        door_raw => tb_door_raw, window_raw => tb_window_raw, motion_raw => tb_motion_raw,
        alarm_siren => tb_alarm_siren, system_armed => tb_system_armed,
        output_display_data => tb_display_data, status_code_dbg => tb_status_code,
        s_dbg_code_vector => open, sens_dbg => open
    );

    tb_Clk <= not tb_Clk after CLK_PERIOD/2;

    process
    begin
        -- 1. Reset
        tb_Rst <= '1'; wait for 45 ns; tb_Rst <= '0';
        wait until rising_edge(tb_Clk);
        assert tb_system_armed = '1' 
            report "error: System not armed after reset, excepted: 1, Actual Value: " & std_logic'image(tb_system_armed) severity error;

        -- 2. Trigger Alarm
        tb_window_raw <= '1'; tb_motion_raw <= '1';
        wait for CLK_PERIOD * 10;
        assert tb_alarm_siren = '1' 
            report "error: Siren not active, excepted: 1, Actual Value: " & std_logic'image(tb_alarm_siren) severity error;
        tb_window_raw <= '0'; tb_motion_raw <= '0';

        -- 3. Lockout sequence (Attempts 0 to 6 displayed)
        for i in 0 to 6 loop
            assert tb_display_data = std_logic_vector(x"30" + to_unsigned(i, 8)) 
                report "error: Incorrect display count, excepted: " & integer'image(i) & 
                       ", Actual Value: " & integer'image(to_integer(unsigned(tb_display_data)) - 48) severity error;
            
            do_press(5, tb_pass_btn, tb_Clk); 
            do_press(5, tb_pass_btn, tb_Clk); 
            wait for CLK_PERIOD * 2;
        end loop;

        -- 4. Verify ST_LOCK (State "101", Display '7' = x37)
        wait for CLK_PERIOD * 5;
        assert tb_status_code = "101" 
            report "error: FSM not in ST_LOCK, excepted: 101, Actual Value: " & vec_to_str(tb_status_code) severity error;
        
        assert tb_display_data = x"37" 
            report "error: Display not showing 7 in lock, excepted: 7, Actual Value: " & integer'image(to_integer(unsigned(tb_display_data)) - 48) severity error;

        report "ALL TESTS COMPLETED SUCCESSFULLY";
        wait;
    end process;
end architecture;