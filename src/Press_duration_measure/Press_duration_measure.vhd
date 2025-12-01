--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Press_duration_measure.vhd
-- Author: Roni Shifrin
-- Ver: 1
-- Created Date: 23/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Press_duration_measure is
    generic (
        K : integer := 3  -- threshold in clock cycles for a "long" press
    );
    port (
        Clk       : in  std_logic;
        Rst       : in  std_logic;    -- asynchronous reset
        btn_in    : in  std_logic;    -- raw button input (assumed clean)
        enable    : in  std_logic;    -- measurement enable
        bit_out   : out std_logic;    -- 0 = short, 1 = long
        bit_valid : out std_logic     -- 2-clock pulse indicating bit_out valid
    );
end Press_duration_measure;

architecture behavior of Press_duration_measure is
    signal btn_prev    : std_logic := '0';
    signal count       : natural := 0;      -- Used 'natural' prevents negative numbers
    signal pressing    : std_logic := '0';
    signal last_bit    : std_logic := '0';
    signal valid_count : natural range 0 to 2 := 0; 
begin

    process(Clk, Rst)
    begin
        if Rst = '1' then
            btn_prev    <= '0';
            count       <= 0;
            pressing    <= '0';
            last_bit    <= '0';
            valid_count <= 0;
            bit_out     <= '0';
            bit_valid   <= '0';

        elsif rising_edge(Clk) then
            -- 1. Default: capture previous button value for edge detection
            btn_prev <= btn_in;

            -- 2. Handle Output Pulse (Default behavior)
            if valid_count > 0 then
                bit_valid   <= '1';
                bit_out     <= last_bit;   -- output the calculated length
                valid_count <= valid_count - 1;
            else
                bit_valid <= '0';
                bit_out   <= '0';
            end if;

            -- 3. Handle Input Logic (Overrides Valid Count if a new release occurs)
            if enable = '1' then
                
                -- Detect Rising Edge (Start Press)
                if btn_prev = '0' and btn_in = '1' then
                    pressing <= '1';
                    count    <= 1;

                -- Continue Counting (Holding)
                elsif pressing = '1' and btn_in = '1' then
                    count <= count + 1;

                -- Detect Falling Edge (Release)
                elsif pressing = '1' and btn_prev = '1' and btn_in = '0' then
                    -- Determine Short vs Long
                    if count >= K then
                        last_bit <= '1'; -- Long Press
                    else
                        last_bit <= '0'; -- Short Press
                    end if;
                    
                    valid_count <= 2; -- Trigger the 2-clock pulse (overrides the decrement above)
                    pressing    <= '0';
                    count       <= 0;
                end if;
            
            else
                -- If disabled, clear internal state
                pressing <= '0';
                count    <= 0;
            end if;
        end if;
    end process;

end architecture behavior;