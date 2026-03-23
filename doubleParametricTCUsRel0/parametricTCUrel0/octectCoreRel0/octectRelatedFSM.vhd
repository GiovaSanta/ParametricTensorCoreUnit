library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity octectRelatedFSM is
    port(
        clk         : in std_logic;
        rst         : in std_logic; 
        start       : in std_logic;
        
        Fp32Op      : in std_logic; --if operands are of 32bits, 
                                    --2 load cycles required per buffer to load related submatrix
        hmma_step   : in std_logic;
        --control outputs toward octectCoreTop
        load_en     : out std_logic;
        load_ph     : out std_logic_vector(1 downto 0);
        load_pair   : out std_logic_vector(1 downto 0);
        exec_step   : out std_logic_vector(1 downto 0);
        
        --status
        busy        : out std_logic;
        done        : out std_logic
    );
end octectRelatedFSM;

architecture rtl of octectRelatedFSM is

    type state_t is (
        S_IDLE,
        S_LOAD_A,
        S_LOAD_A2, --needed in the case operands are 32 bit wide
        S_LOAD_B,
        S_LOAD_B2, --needed in the case operands are 32 bit wide
        S_LOAD_C,
        S_LOAD_C2, --needed in the case operands are 32 bit wide
        S_EXEC_0,
        S_EXEC_1,
        S_EXEC_2,
        S_EXEC_3,
        S_DONE
    );
    
    signal state_reg  : state_t := S_IDLE;
    signal state_next : state_t := S_IDLE;

begin

    --State Register
    
    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= S_IDLE;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;
    
    --Next state logic
    
    process(state_reg, start, Fp32Op, hmma_step)
    begin
        state_next <= state_reg;
        
        case state_reg is
        
        when S_IDLE => 
            if start = '1' then
                if hmma_step = '0' then
                    state_next <= S_LOAD_A;
                else
                    state_next <= S_LOAD_C;
                end if;
            else 
                state_next <= S_IDLE;
            end if;
            
        when S_LOAD_A => 
            if Fp32Op = '0' then
                state_next <= S_LOAD_B ;
            else
                state_next <= S_LOAD_A2 ;
            end if ;
                
        when S_LOAD_A2 => 
            state_next <= S_LOAD_B ;
            
        when S_LOAD_B => 
            if Fp32Op = '0' then
                state_next <= S_LOAD_C ;
            else 
                state_next <= S_LOAD_B2 ;
            end if;
        
        when S_LOAD_B2 =>
            state_next <= S_LOAD_C ;
        
        when S_LOAD_C =>
            if Fp32Op = '0' then
                state_next <= S_EXEC_0 ;
            else
                state_next <= S_LOAD_C2 ;
            end if;
        
        when S_LOAD_C2 =>
            state_next <= S_EXEC_0 ;
        
        when S_EXEC_0 =>
            state_next <= S_EXEC_1 ;
        
        when S_EXEC_1 => 
            state_next <= S_EXEC_2 ; 
        
        when S_EXEC_2 => 
            state_next <= S_EXEC_3 ;
        
        when S_EXEC_3 => 
            state_next <= S_DONE ;
        
        when S_DONE => 
            state_next <= S_IDLE ;
            
        when others =>
            state_next <= S_IDLE ;
        
        end case;
    end process;
    
    --output logic
    
    process(state_reg)
    begin
        --defaults
        load_en <= '0';
        load_ph <= "00";
        load_pair <= "00";
        exec_step <= "00";
        busy <= '0';
        done <= '0';
        
        case state_reg is
            when S_IDLE =>
                busy <= '0';
                
            when S_LOAD_A =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "00"; --A
                load_pair <= "00";
            
            when S_LOAD_A2 =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "00";
                load_pair <= "01";
                
            when S_LOAD_B =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "01"; --B
                load_pair <= "00";
            
            when S_LOAD_B2 =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "01";
                load_pair <= "01";
            
            when S_LOAD_C =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "10"; --C
                load_pair <= "00";
            
            when S_LOAD_C2 =>
                busy <= '1';
                load_en <= '1';
                load_ph <= "10";
                load_pair <= "01";
                
            when S_EXEC_0 =>
                busy <= '1';
                exec_step <= "00";
                
            when S_EXEC_1 =>
                busy <= '1';
                exec_step <= "01";
                
            when S_EXEC_2 =>
                busy <= '1';
                exec_step <= "10";
                
            when S_EXEC_3 => 
                busy <= '1';
                exec_step <= "11";
            
            when S_DONE =>
                busy <= '0';
                done <= '1';
                
            when others =>
                null;
                
        end case;
    end process;       

end rtl;