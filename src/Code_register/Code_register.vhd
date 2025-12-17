--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Code_register.vhd
-- Author: Yuval Kogan
-- Ver: 2 
-- Created Date: 23/11/25
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Code_register is
    generic (
        N : INTEGER := 2;
        PASSWORD : STD_LOGIC_VECTOR := "01"
    );
    port (
        Clk          : IN  STD_LOGIC;
        Rst          : IN  STD_LOGIC;        
        bit_in       : IN  STD_LOGIC;                           -- bit input
        valid        : IN  STD_LOGIC;                           -- Insert bit if high
        
        Code_ready   : OUT STD_LOGIC;                           -- High for 1 cycle when N bits reached
        code_match   : OUT STD_LOGIC;                           -- High for 1 cycle if match
        code_vector  : OUT STD_LOGIC_VECTOR((N - 1) DOWNTO 0)     -- Current register state
    );
end Code_register;

architecture behavior of Code_register is
    
    -- Internal Signals
    signal code_reg_int  : STD_LOGIC_VECTOR((N - 1) DOWNTO 0) := (others => '0');
    signal bit_count_int : INTEGER range 0 to N := 0; 
    signal ready_int     : STD_LOGIC := '0';
    signal match_int     : STD_LOGIC := '0';

begin
        
    code_register_process : process(Clk, Rst)
        variable next_vector : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
    begin
        -- ASYNCHRONOUS RESET
        if (Rst = '1') then
            code_reg_int  <= (others => '0');
            bit_count_int <= 0;
            match_int     <= '0'; 
            ready_int     <= '0';

        -- SYNCHRONOUS LOGIC
        elsif RISING_EDGE(Clk) then
            -- Default: Flags are only high for one clock cycle
            ready_int <= '0';
            match_int <= '0';

            -- If we just finished a code entry last cycle, clear the register for the next attempt
            if (bit_count_int = N) then
                bit_count_int <= 0;
                code_reg_int  <= (others => '0');
            end if;
            
            -- Capture new bit
            if (valid = '1' and bit_count_int < N) then
                -- Calculate what the vector will look like
                next_vector := code_reg_int(code_reg_int'left - 1 DOWNTO 0) & bit_in;
                
                -- Update register and counter
                code_reg_int  <= next_vector;
                bit_count_int <= bit_count_int + 1;
                
                -- Check if this was the final bit
                if (bit_count_int + 1 = N) then
                    ready_int <= '1';
                    if (next_vector = PASSWORD) then
                        match_int <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process code_register_process;
    

    code_vector <= (others => 'Z') when Rst = '1' else code_reg_int;
    Code_ready  <= 'Z' when Rst = '1' else ready_int;
    code_match  <= 'Z' when Rst = '1' else match_int;

end behavior;