--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data.vhd
-- Author: Roni Shifrin
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------

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

entity Display_data is
    port (
        clk         : in  std_logic;
        Rst         : in  std_logic;
        state_code  : in  std_logic_vector(N_bit downto 0);
        attempts    : in  integer range 0 to 7;
        data        : out std_logic_vector(7 downto 0)
    );
end Display_data;

architecture behavior of Display_data is
begin

end architecture behavior;
