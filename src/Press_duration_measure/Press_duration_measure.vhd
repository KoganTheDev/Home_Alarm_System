--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Press_duration_measure.vhd
-- Author: Roni Shifrin
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Duration_measure is
    port (
        clk : in std_logic;
        Rst : in std_logic;
        btn_in : in std_logic;
        enable : in std_logic;
        bit_out : out std_logic;
        Bit_valid : out std_logic

    );
end Duration_measure;

architecture behavior of Duration_measure is

begin




    
end architecture behavior;