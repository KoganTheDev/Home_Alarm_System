--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Display_data.vhd
-- Author: Roni Shifrin
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data is
    generic (
        N_bit : integer := 2  -- Resulting vector is (2 downto 0) = 3 bits
    ); 
    port (
        clk        : in  std_logic;
        Rst        : in  std_logic;
        state_code : in  std_logic_vector(N_bit downto 0);
        attempts   : in  integer range 0 to 7;
        data       : out std_logic_vector(7 downto 0)  -- ASCII output
    );
end Display_data;

architecture behavior of Display_data is

    -- ASCII Constants (Hex values)
    constant ASCII_0    : unsigned(7 downto 0)         := x"30"; -- '0'
    constant ASCII_7    : std_logic_vector(7 downto 0) := x"37"; -- '7'
    constant ASCII_8    : std_logic_vector(7 downto 0) := x"38"; -- '8'
    constant ASCII_A    : std_logic_vector(7 downto 0) := x"41"; -- 'A'
    constant ASCII_F    : std_logic_vector(7 downto 0) := x"46"; -- 'F'
    constant ASCII_DASH : std_logic_vector(7 downto 0) := x"2D"; -- '-'

begin

    process(clk, Rst)
        variable state_val : integer;
    begin
        if Rst = '1' then
            data <= (others => 'Z'); 

        elsif rising_edge(clk) then
            -- Perform the conversion
            state_val := to_integer(unsigned(state_code));

            case state_val is
                when 0 => -- ST_OFF
                    data <= std_logic_vector(ASCII_0);
                
                when 1 => -- ST_ARMED
                    data <= ASCII_8;

                when 2 => -- ST_ALERT
                    data <= ASCII_A;

                when 3 => -- ST_CORRECT
                    data <= ASCII_F;

                when 4 => -- ST_ATTEMPTS
                    -- Dynamically shows '0' + attempt count
                    data <= std_logic_vector(ASCII_0 + to_unsigned(attempts, 8));
                
                when 5 => -- ST_LOCK
                    data <= ASCII_7;

                when 6 => -- ST_UNKNOWN
                    data <= ASCII_DASH;

                when others =>
                    data <= ASCII_DASH;
            end case;
        end if;
    end process;

end architecture behavior;
