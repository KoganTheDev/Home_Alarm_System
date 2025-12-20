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
        Rst          : IN  STD_LOGIC;        -- Connected to s_clear_code from FSM
        bit_in       : IN  STD_LOGIC;        -- Bit value from Measure unit
        valid        : IN  STD_LOGIC;        -- Pulse indicating bit_in is valid
        
        Code_ready   : OUT STD_LOGIC;        -- High for 1 cycle when N bits reached
        code_match   : OUT STD_LOGIC;        -- High for 1 cycle if match
        code_vector  : OUT STD_LOGIC_VECTOR((N - 1) DOWNTO 0)
    );
end Code_register;

architecture behavior of Code_register is
    
    -- Internal Signals
    signal code_reg_int  : STD_LOGIC_VECTOR((N - 1) DOWNTO 0) := (others => '0');
    signal bit_count_int : INTEGER range 0 to N := 0; 
    signal ready_int     : STD_LOGIC := '0';
    signal match_int     : STD_LOGIC := '0';
    signal valid_prev    : STD_LOGIC := '0';  -- Track previous valid state for edge detection

begin
        
    code_register_process : process(Clk) -- Removed Rst from sensitivity list for Synchronous Reset
        variable next_vector : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
    begin
        if RISING_EDGE(Clk) then
            -- Track previous valid state for edge detection
            valid_prev <= valid;
            
            -- SYNCHRONOUS RESET (Teacher's s_clear_code)
            -- This allows Code_ready to stay high for exactly one full clock cycle
            if (Rst = '1') then
                code_reg_int  <= (others => '0');
                bit_count_int <= 0;
                match_int     <= '0'; 
                ready_int     <= '0';
            else
                -- Default: Flags are only high for one clock cycle
                ready_int <= '0';
                match_int <= '0';

                -- Internal clear if counter exceeded (safety)
                if (bit_count_int = N) then
                    bit_count_int <= 0;
                    code_reg_int  <= (others => '0');
                end if;
                
                -- Capture new bit on RISING EDGE of valid (not level detection)
                if (valid = '1' and valid_prev = '0' and bit_count_int < N) then
                    -- Calculate the resulting vector
                    next_vector := code_reg_int(code_reg_int'left - 1 DOWNTO 0) & bit_in;
                    
                    -- Update register and counter
                    code_reg_int  <= next_vector;
                    bit_count_int <= bit_count_int + 1;
                    
                    -- Check if the final bit of the password length was reached
                    if (bit_count_int + 1 = N) then
                        ready_int <= '1';
                        if (next_vector = PASSWORD) then
                            match_int <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process code_register_process;

    -- Change 'Z' to '0'
    code_vector <= (others => '0') when Rst = '1' else code_reg_int;
    Code_ready  <= '0' when Rst = '1' else ready_int;
    code_match  <= '0' when Rst = '1' else match_int;

end behavior;