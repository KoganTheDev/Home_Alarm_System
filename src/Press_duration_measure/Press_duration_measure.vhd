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
        Clk      : in  std_logic;
        Rst      : in  std_logic;    -- asynchronous reset
        btn_in   : in  std_logic;    -- raw button input (assumed clean)
        enable   : in  std_logic;    -- measurement enable
        bit_out  : out std_logic;    -- 0 = short, 1 = long
        bit_vaild: out std_logic     -- 2-clock pulse indicating bit_out valid
    );
end Press_duration_measure;

architecture behavior of Press_duration_measure is
    signal btn_prev      : std_logic := '0';
    signal count         : integer := 0;
    signal pressing      : std_logic := '0';
    signal last_bit      : std_logic := '0';
    signal valid_count   : integer := 0; -- counts remaining cycles of bit_vaild
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
            bit_vaild   <= '0';

        elsif rising_edge(Clk) then
            -- default: capture previous button value
            btn_prev <= btn_in;

            -- Manage valid pulse timing
            if valid_count > 0 then
                bit_vaild <= '1';
                valid_count <= valid_count - 1;
                -- keep bit_out stable while valid
                bit_out <= last_bit;
            else
                bit_vaild <= '0';
                bit_out <= '0';
            end if;

            if enable = '1' then
                -- Start counting on rising edge of button
                if btn_prev = '0' and btn_in = '1' then
                    pressing <= '1';
                    count <= 1;

                -- Continue counting while pressed
                elsif pressing = '1' and btn_in = '1' then
                    count <= count + 1;

                -- On release, evaluate length and generate bit + valid
                elsif pressing = '1' and btn_prev = '1' and btn_in = '0' then
                    if count >= K then
                        last_bit <= '1';
                    else
                        last_bit <= '0';
                    end if;
                    valid_count <= 2; -- produce 2-clock pulse
                    pressing <= '0';
                    count <= 0;
                end if;
            else
                -- If not enabled, clear any ongoing measurement
                pressing <= '0';
                count <= 0;
            end if;
        end if;
    end process;

end architecture behavior;