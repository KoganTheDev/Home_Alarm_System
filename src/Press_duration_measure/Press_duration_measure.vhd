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
        K : integer := 3
    );
    port (
        Clk       : in  std_logic;
        Rst       : in  std_logic;
        btn_in    : in  std_logic;
        enable    : in  std_logic;
        bit_out   : out std_logic;
        bit_valid : out std_logic
    );
end Press_duration_measure;

architecture behavior of Press_duration_measure is
    signal btn_prev     : std_logic := '0';
    signal count        : integer := 0; 
    signal pressing     : std_logic := '0';
    signal last_bit_reg : std_logic := '0';
    signal valid_reg    : std_logic := '0';
    signal valid_count  : integer range 0 to 2 := 0; 
begin                  

    process(Clk, Rst)
    begin
        if Rst = '1' then
            btn_prev     <= '0';
            count        <= 0;
            pressing     <= '0';
            valid_count  <= 0;
            last_bit_reg <= '0';
            valid_reg    <= '0';

        elsif rising_edge(Clk) then
            btn_prev <= btn_in;

            -- 1. Pulse management
            if valid_count > 0 then
                valid_count <= valid_count - 1;
                valid_reg   <= '1';
            else
                valid_reg    <= '0';
                last_bit_reg <= '0';
            end if;

            -- 2. Measurement Logic
            if enable = '1' then
                -- Falling Edge (Button Release)
                if btn_prev = '1' and btn_in = '0' and pressing = '1' then
                    if count >= K then
                        last_bit_reg <= '1'; -- Long press
                    else
                        last_bit_reg <= '0'; -- Short press
                    end if;
                    
                    valid_reg   <= '1';
                    valid_count <= 1; -- Ensures total 2 clock cycles of '1'
                    pressing    <= '0';
                    count       <= 0;
                    
                -- Rising Edge (Button Press Start)
                elsif btn_prev = '0' and btn_in = '1' then
                    pressing <= '1';
                    count    <= 1;

                -- Continue Holding
                elsif pressing = '1' and btn_in = '1' then
                    count <= count + 1;
                end if;
            else
                -- Clear state if disabled
                pressing    <= '0';
                count       <= 0;
                valid_count <= 0;
                valid_reg   <= '0';
            end if;
        end if;
    end process;

    bit_out   <= 'Z' when Rst = '1' else last_bit_reg;
    bit_valid <= 'Z' when Rst = '1' else valid_reg;

end architecture behavior;