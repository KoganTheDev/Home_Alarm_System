library ieee;
use ieee.std_logic_1164.all;

entity HA_System is
    port (
        Clk          : in  std_logic;
        Rst          : in  std_logic;
        pass_btn     : in  std_logic;
        door_raw     : in  std_logic;
        window_raw   : in  std_logic;
        motion_raw   : in  std_logic;
        alarm_siren  : out std_logic;
        system_armed : out std_logic;
        sens_dbg     : out std_logic_vector(2 downto 0);
        output_display_data : out std_logic_vector(7 downto 0);
        s_dbg_code_vector   : out std_logic_vector(1 downto 0);
        status_code_dbg     : out std_logic_vector(2 downto 0)
    );
end HA_System;

architecture behavior of HA_System is
    signal s_bit_out, s_bit_valid, s_code_ready, s_code_match : std_logic;
    signal s_intrusion_detected, s_enable_press, s_clear_code : std_logic;
    signal s_attempts : integer range 0 to 7;
    signal s_state_code : std_logic_vector(2 downto 0);
    signal s_data : std_logic_vector(7 downto 0);
    signal d_c, w_c, m_c : std_logic;

begin
    U0: entity work.Press_duration_measure 
    port map (Clk=>Clk,
            Rst=>Rst,
            btn_in=>pass_btn,
            enable=>s_enable_press,
            bit_out=>s_bit_out,
            bit_valid=>s_bit_valid);


    U1: entity work.Code_register
    port map (Clk=>Clk,
            Rst=>s_clear_code,
            bit_in=>s_bit_out,
            valid=>s_bit_valid,
            Code_ready=>s_code_ready,
            code_match=>s_code_match,
            code_vector=>s_dbg_code_vector);

    
    U2: entity work.Sensors_logic
    port map (Clk=>Clk,
            Rst=>Rst,
            door_sens=>door_raw,
            window_sens=>window_raw,
            motion_sens=>motion_raw,
            door_clean=>d_c,
            window_clean=>w_c,
            motion_clean=>m_c,
            detected=>s_intrusion_detected);


    U3: entity work.Alarm_Control 
    port map (Clk=>Clk,
            Rst=>Rst,
            code_ready=>s_code_ready,
            code_match=>s_code_match,
            enable_press=>s_enable_press,
            clear_code=>s_clear_code,
            alarm_siren=>alarm_siren,
            system_armed=>system_armed,
            state_code=>s_state_code,
            attempts=>s_attempts,
            intrusion_detected=>s_intrusion_detected);


    U4: entity work.Display_data 
    port map (clk=>Clk,
            Rst=>Rst,
            state_code=>s_state_code,
            attempts=>s_attempts,
            data=>s_data);

    sens_dbg <= m_c & w_c & d_c;
    output_display_data <= s_data;
    status_code_dbg <= s_state_code;
end architecture;