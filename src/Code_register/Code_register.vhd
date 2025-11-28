--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Code_register.vhd
-- Author: Yuval Kogan
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implemented as a Shift code register
entity Code_register is
    generic (
        N : INTEGER := 2;
        PASSWORD : STD_LOGIC_VECTOR := "01"
    );

    port (
        Clk          : IN  STD_LOGIC;
        Rst          : IN  STD_LOGIC;        
        bit_in       : IN  STD_LOGIC;                           -- bit input
        valid        : IN  STD_LOGIC;                           -- If the valid flag is on, insert the current bit_in
        
        Code_ready   : OUT STD_LOGIC;                           -- Used to check if the current code size is the same as the PASSWORD's
        code_match   : OUT STD_LOGIC;                           -- If PASSWORD == code_vector, this flag turns on. otherwise, 0.
        code_vector  : OUT STD_LOGIC_VECTOR((N - 1) DOWNTO 0)     -- Outputs the current code's state
    );
end Code_register;


architecture behavior of Code_register is
    
    -- Internal Signal to hold the actual shift register state
    signal code_reg_int  : STD_LOGIC_VECTOR((N - 1) DOWNTO 0) := (others => '0');
    
    -- Internal signal for the counter state (0 to N)
    signal bit_count_int : INTEGER range 0 to N := 0; 
    
    -- Internal signals for synchronous output
    signal ready_int     : STD_LOGIC := '0';
    signal match_int     : STD_LOGIC := '0';

begin
    -- Assign the internal state to the external output ports
    code_vector <= code_reg_int;
    Code_ready  <= ready_int;
    code_match  <= match_int;
    
    code_register_process : process(Clk, Rst)
    begin
        -- ASYNCHRONOUS RESET
        if (Rst = '1') then
            -- Reset all internal state elements
            match_int     <= '0';
            code_reg_int  <= (others => '0');
            bit_count_int <= 0;
            ready_int     <= '0';

        -- SYNCHRONOUS LOGIC
        elsif RISING_EDGE(Clk) then
            -- Reset both match and ready flag on each clock rising edge
            match_int <= '0';
            ready_int <= '0'; 

            if (bit_count_int = N) then
                -- Reset the counter and the code vector to wait for a new code
                bit_count_int <= 0;
                code_reg_int  <= (others => '0');
            end if;
            
            -- If there`s a valid bit incoming => insert it to the code vector
            if (valid = '1') then
                
                -- If bit_count_int = N, we ignore the new valid bit until the counter is reset.
                if (bit_count_int < N) then
                    
                    -- Shift left and insert the new bit into the LSB 
                    code_reg_int <= code_reg_int(code_reg_int'left - 1 DOWNTO 0) & bit_in;
                    
                    -- Increment inserted bit counter
                    bit_count_int <= bit_count_int + 1;
                    
                end if;
            end if;
            
            
            if (bit_count_int + 1 = N AND valid = '1') then
                -- This condition asserts Code_ready on the clock cycle the Nth bit arrives.
                -- We use code_reg_int here because it has already been updated in the same delta cycle.
                ready_int <= '1';
                if (code_reg_int(code_reg_int'left - 1 DOWNTO 0) & bit_in = PASSWORD) then
                    match_int <= '1';
                end if;
            
            end if;

        end if;
    end process code_register_process;
    
end behavior;