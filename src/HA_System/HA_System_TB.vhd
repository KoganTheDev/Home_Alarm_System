--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: HA_System_TB.vhd
-- Author: Logic Adjusted for 2-out-of-3
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HA_System_TB is
end HA_System_TB;

architecture behavior of HA_System_TB is

    component HA_System
    port(
        Clk                 : in  std_logic;
        Rst                 : in  std_logic;
        pass_btn            : in  std_logic;
        door_raw            : in  std_logic;
        window_raw          : in  std_logic;
        motion_raw          : in  std_logic;
        alarm_siren         : out std_logic;
        system_armed        : out std_logic;
        sens_dbg            : out std_logic_vector(2 downto 0);
        output_display_data : out std_logic_vector(7 downto 0)
    );
    end component;

    -- Inputs
    signal tb_Clk        : std_logic := '0';
    signal tb_Rst        : std_logic := '0';
    signal tb_pass_btn   : std_logic := '0';
    signal tb_door_raw   : std_logic := '0';
    signal tb_window_raw : std_logic := '0';
    signal tb_motion_raw : std_logic := '0';

    -- Outputs
    signal tb_alarm_siren  : std_logic;
    signal tb_system_armed : std_logic;
    signal tb_sens_dbg     : std_logic_vector(2 downto 0);
    signal tb_display_data : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns; 

    -- ??????? (K=3)
    constant T_SHORT_PRESS : time := 15 ns;  
    constant T_LONG_PRESS  : time := 50 ns;  
    constant T_GAP         : time := 40 ns;  

begin

    uut: HA_System PORT MAP (
        Clk                 => tb_Clk,
        Rst                 => tb_Rst,
        pass_btn            => tb_pass_btn,
        door_raw            => tb_door_raw,
        window_raw          => tb_window_raw,
        motion_raw          => tb_motion_raw,
        alarm_siren         => tb_alarm_siren,
        system_armed        => tb_system_armed,
        sens_dbg            => tb_sens_dbg,
        output_display_data => tb_display_data
    );

    Clk_process :process
    begin
        tb_Clk <= '0';
        wait for CLK_PERIOD/2;
        tb_Clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
        procedure press_short is
        begin
            tb_pass_btn <= '1';
            wait for T_SHORT_PRESS;
            tb_pass_btn <= '0';
            wait for T_GAP;
        end procedure press_short;

        procedure press_long is
        begin
            tb_pass_btn <= '1';
            wait for T_LONG_PRESS;
            tb_pass_btn <= '0';
            wait for T_GAP;
        end procedure press_long;

    begin       
        -- =========================================================
        -- 1. ?????
        -- =========================================================
        report "Starting Simulation";
        tb_Rst <= '1';
        wait for 100 ns;    
        tb_Rst <= '0';
        wait for 100 ns;

        -- ?????: ?????? ????? ????? ???? ????!
        assert tb_system_armed = '1' report "Error: System should start ARMED" severity error;

        -- =========================================================
        -- 2. ????? ????? (??? ?????? ?????)
        -- ??????: ??????? 2 ??????? ??? ????? ????? ?? 2 ???? 3
        -- =========================================================
        report "Scenario: Intrusion Detected (Window + Motion)";
        tb_window_raw <= '1';
        tb_motion_raw <= '1'; -- ?????? ????? ???
        
        wait for 100 ns; -- ??? ?-Debounce
        
        -- ????? ?? ???????? (?????? ????? ?????? ?????)
        tb_window_raw <= '0';
        tb_motion_raw <= '0';
        
        wait for 50 ns;
        -- ?????: ????? ????? ?????
        assert tb_alarm_siren = '1' report "Error: Siren did not trigger on double intrusion!" severity error;

        -- =========================================================
        -- 3. ?????? ??? ???? ???? ?????
        -- =========================================================
        report "Scenario: Wrong Code Entry during Alarm";
        press_short; -- '0'
        press_short; -- '0' (Wrong)
        
        wait for 100 ns;
        -- ?????: ????? ????? ??????
        assert tb_alarm_siren = '1' report "Error: Siren stopped incorrectly!" severity error;

        -- =========================================================
        -- 4. ?????? ?????? (??? ????)
        -- =========================================================
        report "Scenario: Correct Code Entry (0, 1)";
        press_short; -- '0'
        press_long;  -- '1' (Correct)

        wait for 100 ns; 
        
        -- ?????: ?????? ????? ??????
        if tb_alarm_siren = '0' then
            report "Success: Siren stopped!";
        else
            report "Error: Siren keeps ringing after correct code!" severity error;
        end if;
        
        report "Testbench Completed";
        wait;
    end process;

end behavior;