--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: HA_System.vhd
-- Author: Roni Shifrin
-- Ver: 1
-- Created Date: 4/12/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        output_display_data : out std_logic_vector(7 downto 0)  -- Changed the name from display_data to output_display_data to solve a naming bug
    );
end HA_System;

architecture behavior of HA_System is

    component Press_duration_measure
        port (
            Clk       : in  std_logic;
            Rst       : in  std_logic;
            btn_in    : in  std_logic;
            enable    : in  std_logic;
            bit_out   : out std_logic;
            bit_valid : out std_logic
        );
    end component;

    component Code_register
        port (
            Clk        : in  std_logic;
            Rst        : in  std_logic;
            bit_in     : in  std_logic;
            valid      : in  std_logic;
            Code_ready : out std_logic;
            code_match : out std_logic;
            code_vector : out std_logic_vector(1 downto 0)
        );
    end component;

    component Sensors_logic
        port (
            Clk          : in  std_logic;
            Rst          : in  std_logic;
            door_sens    : in  std_logic;
            window_sens  : in  std_logic;
            motion_sens  : in  std_logic;
            door_clean   : out std_logic;
            window_clean : out std_logic;
            motion_clean : out std_logic;
            detected     : out std_logic
        );
    end component;

    component Alarm_Control
        port (
            Clk                : in  std_logic;
            Rst                : in  std_logic;
            code_ready         : in  std_logic;
            code_match         : in  std_logic;
            enable_press       : out std_logic;
            clear_code         : out std_logic;
            alarm_siren        : out std_logic;
            system_armed       : out std_logic;
            state_code         : out std_logic_vector(2 downto 0);
            attempts           : out integer range 0 to 7; 
            intrusion_detected : in  std_logic
        );
    end component;

    component Display_data 
            port (
        clk        : in  std_logic;
        Rst        : in  std_logic;
        state_code : in  std_logic_vector(2 downto 0);
        attempts   : in  integer range 0 to 7; 
        data       : out std_logic_vector(7 downto 0)  
    );
    end component;

-- Internal Signals
signal s_bit_out            : std_logic;
signal s_bit_valid          : std_logic;

signal s_code_ready         : std_logic;
signal s_code_match         : std_logic;

signal s_intrusion_detected : std_logic;
signal s_enable_press       : std_logic;
signal s_clear_code         : std_logic;
signal s_attempts           : integer range 0 to 7; 
signal s_state_code         : std_logic_vector(2 downto 0);
signal s_data               : std_logic_vector(7 downto 0); 

signal door_clean           : std_logic;
signal window_clean         : std_logic;
signal motion_clean         : std_logic;

begin

    -- Press duration measurement
    U0 : Press_duration_measure
        port map (
            Clk       => Clk,
            Rst       => Rst,
            btn_in    => pass_btn,
            enable    => s_enable_press,
            bit_out   => s_bit_out,
            bit_valid => s_bit_valid
        );

    -- Code register
    U1 : Code_register
        port map (
            Clk        => Clk,
            Rst        => s_clear_code, 
            bit_in     => s_bit_out,
            valid      => s_bit_valid,
            Code_ready => s_code_ready,
            code_match => s_code_match,
            code_vector => open
        );
        
    -- Sensors logic
    U2 : Sensors_logic
        port map (
            Clk          => Clk,
            Rst          => Rst,
            door_sens    => door_raw,
            window_sens  => window_raw,
            motion_sens  => motion_raw,
            door_clean   => door_clean,
            window_clean => window_clean,
            motion_clean => motion_clean,
            detected     => s_intrusion_detected
        );

    -- Alarm controller FSM
    U3 : Alarm_Control
        port map (
            Clk                => Clk,
            Rst                => Rst,
            code_ready         => s_code_ready,
            code_match         => s_code_match,
            enable_press       => s_enable_press,
            clear_code         => s_clear_code,
            alarm_siren        => alarm_siren,
            system_armed       => system_armed,
            state_code         => s_state_code,
            attempts           => s_attempts,
            intrusion_detected => s_intrusion_detected
        );

    -- Display module
    U4 : Display_data
        port map (
            clk        => Clk,
            Rst        => Rst,
            state_code => s_state_code,
            attempts   => s_attempts,
            data       => s_data
        );

    -- Outputs to top-level ports
    sens_dbg     <= motion_clean & window_clean & door_clean;
    output_display_data <= s_data;
    

end architecture behavior;