--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data.vhd
-- Author: Roni Shifrin
-- Ver: 1 
-- Created Date: 23/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data is
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
end Display_data;

architecture behavior of Display_data is
begin

    process(clk, Rst)
    begin
        if Rst = '1' then
            data <= (others => 'Z');

        elsif RISING_EDGE(clk) then

            case state_code is

                -- System OFF => display '0' (ASCII 0x30)
                when "000" =>
                    data <= x"30";  -- ASCII '0'
                    report "Display: OFF -> '0'" severity note;

                -- System ARMED => display '8' (ASCII 0x38)
                when "001" => 
                    data <= x"38";  -- ASCII '8'
                    report "Display: ARMED -> '8'" severity note;

                -- ALERT / INTRUSION => display 'A' (ASCII 0x41)
                when "010" =>
                    data <= x"41";  -- ASCII 'A'
                    report "Display: ALERT -> 'A'" severity note;

                -- CORRECT CODE => display 'F' (ASCII 0x46)
                when "011" =>
                    data <= x"46";  -- ASCII 'F'
                    report "Display: CORRECT CODE -> 'F'" severity note;

                -- ATTEMPTS MODE => display '1'..'7' (ASCII 0x31..0x37)
                when "100" =>
                    data <= std_logic_vector(to_unsigned(attempts + 48, 8));  -- '0' + attempts
                    report "Display: ATTEMPTS -> " & integer'image(attempts) severity note;

                -- Default / unknown state => display '-' (ASCII 0x2D)
                when others =>
                    data <= x"2D";  -- ASCII '-'
                    report "Display: UNKNOWN STATE -> '-'" severity warning;

            end case;
        end if;
    end process;

end architecture behavior;
