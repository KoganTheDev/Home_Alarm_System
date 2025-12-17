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
    constant ASCII_8    : std_logic_vector(7 downto 0) := x"38"; -- '8'
    constant ASCII_A    : std_logic_vector(7 downto 0) := x"41"; -- 'A'
    constant ASCII_F    : std_logic_vector(7 downto 0) := x"46"; -- 'F'
    constant ASCII_DASH : std_logic_vector(7 downto 0) := x"2D"; -- '-'

    -- State Constants (Binary encoding matches N_bit=2 => 3 bits)
    constant ST_OFF      : std_logic_vector(N_bit downto 0) := "000";
    constant ST_ARMED    : std_logic_vector(N_bit downto 0) := "001";
    constant ST_ALERT    : std_logic_vector(N_bit downto 0) := "010";
    constant ST_CORRECT  : std_logic_vector(N_bit downto 0) := "011";
    constant ST_ATTEMPTS : std_logic_vector(N_bit downto 0) := "100";

begin

    process(clk, Rst)
    begin
        -- Asynchronous Reset: Force High-Impedance ('Z')
        if Rst = '1' then
            data <= (others => 'Z');

        elsif rising_edge(clk) then
            
            case state_code is
                when ST_OFF =>
                    data <= std_logic_vector(ASCII_0);
                
                when ST_ARMED => 
                    data <= ASCII_8;

                when ST_ALERT =>
                    data <= ASCII_A;

                when ST_CORRECT =>
                    data <= ASCII_F;

                when ST_ATTEMPTS =>
                    -- Calc: Base ASCII '0' + attempts integer
                    data <= std_logic_vector(ASCII_0 + to_unsigned(attempts, 8));

                when others =>
                    data <= ASCII_DASH; -- Safe default state

            end case;
        end if;
    end process;

end architecture behavior;