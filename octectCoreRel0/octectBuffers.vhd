
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.dpuArray_package.all;

entity octectRelatedBuffers is
    generic (
        LANES           : integer := 8;
        REG_W           : integer := 32;
        ELEM_W          : integer := 32  --worst case element width
    );
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        
        --control
        load_en         : in std_logic;
        load_ph         : in std_logic_vector(1 downto 0); -- 00 = load A, 01 = load B, 10 = load C
        load_pair       : in std_logic_vector(1 downto 0); -- 00 -> slots 0..1, 01 -> slots 2..3
        hmma_step       : in std_logic; --'0' = step0, '1'= step1
        
        --control for execution readout
        exec_step       : in std_logic_vector(1 downto 0); --00, 01, 10, 11 --cycle inside 4by4 sweep
        
        --register file read return (per lane)
        rf_rd_data_port_a    : in arraySize8_32;
        rf_rd_data_port_b    : in arraySize8_32;
        
        --outputs to octect DPU array
        --current A row vector for threadgroup0 (or tg1 or tg2 or tg3)
        A_tg0_out       : out arraySize4_32;
        --current A row vector for threadgroup4 (or tg5 or tg6 or tg7)
        A_tg4_out       : out arraySize4_32;
        
        --stationary 4x4 B subblock reused across the 4 execution cycles
        B_blk_out       : out arraySize16_32;
        
        --current Accumulator row vector for tg0 (or tg1 or tg2 or tg3)
        C_tg0_out       : out arraySize4_32;
        --current Accumulator row vector for tg4, tg5, tg6, tg7
        C_tg4_out       : out arraySize4_32
    );
end octectRelatedBuffers;

architecture rtl of octectRelatedBuffers is

    subtype elem_t is std_logic_vector(ELEM_W-1 downto 0);
    type elem_vec4_t is array (0 to 3) of elem_t;
    type lane_buf_t is array (0 to LANES-1) of elem_vec4_t;
    
    --A is kept across hmma steps
    signal A_buf : lane_buf_t; 
    
    signal B_buf : lane_buf_t;
    
    --C is reloaded between hmma steps
    signal C_buf : lane_buf_t;
    
    function slot_base(pair_sel : std_logic_vector(1 downto 0)) return integer is
    begin
        if pair_sel = "00" then
            return 0; --slots 0,1
        elsif pair_sel = "01" then --needed for fp32 operands case
            return 2; --slots 2,3
        else
            return 0; -- default safe
        end if;
    end function;
    
begin

    --load process
    process(clk)
        variable regA_lane : std_logic_vector(REG_W-1 downto 0);
        variable regB_lane : std_logic_vector(REG_W-1 downto 0);
        variable s0        : integer;
        
    begin
        if rising_edge(clk) then
            if rst = '1' then
            --clear 
            for l in 0 to LANES-1 loop
                for k in 0 to 3 loop
                    A_buf(l)(k) <= (others => '0');
                    B_buf(l)(k) <= (others => '0');
                    C_buf(l)(k) <= (others => '0');
                end loop;
            end loop;
            
            elsif load_en = '1' then
                
                s0 := slot_base(load_pair); --0 or 2
                
                for lane in 0 to LANES-1 loop
                regA_lane := rf_rd_data_port_a(lane);
                regB_lane := rf_rd_data_port_b(lane);
                
                case load_ph is
                
                    when "00" => --LOAD A buffer related to a specific octect. 
                                --example for octet0: threadgroup0 content is stored in pointer A_buf[lane0], A_buf[lane1], A_buf[lane2], A_buf[lane3]. 
                                --                    while threadgroup4 content is stored in A_buf[lane4], A_buf[lane5], A_buf[lane6], A_buf[lane7]
                        A_buf(lane)(s0)     <= regA_lane;
                        A_buf(lane)(s0+1)   <= regB_lane;
                        
                    when "01" => --LOAD B buffer related to a specific octet
                        B_buf(lane)(s0)     <= regA_lane;
                        B_buf(lane)(s0+1)   <= regB_lane;
                        
                    when "10" => --LOAD C buffer related to a specific octet
                        C_buf(lane)(s0)     <= regA_lane; 
                        C_buf(lane)(s0+1)   <= regB_lane;

                    when others =>
                        null;
                end case;
                
                end loop;
            end if;
        end if;
    end process;
    
    --execution readout: 
    --the exec_step signal selects which row-pair is exposed to the octect DPU array
    --exec_step = 00 -> lane0 feeds TG0 output wires (relatedto A and C), lane 4 feeds TG4 output wire (relatedto A and C)
    --exec_step = 01 -> lane1 feeds TG0 output wires, lane5 feeds TG4 output wires
    --exec_step = 10 -> lane2 feeds TG0 output wires, lane6 feeds TG4 output wires
    --exec step = 11 -> lane3 feeds TG0 output wires, lane7 feeds TG4 output wires 
    
    process( A_buf, B_buf, C_buf, exec_step, hmma_step )
        variable row_idx    : integer;
        variable b_base     : integer;
    begin
        
        row_idx := to_integer(unsigned(exec_step)); --0..3

        if hmma_step = '0' then
            b_base := 0;
        else 
            b_base := 4;
        end if; 
        
        --TG0 current A row comes from lanes 0..3, selected by exec_step
        for k in 0 to 3 loop  
            A_tg0_out(k) <= A_buf(row_idx)(k);
        end loop;
        
        --TG4 current A row comes from lanes 4..7, selected by exec_step
        for k in 0 to 3 loop
            A_tg4_out(k) <= A_buf(row_idx+4)(k); --rowIdx selects which laneBuffer. k the singular elements of the row.
        end loop;
            
        --TG0 current C row
        for k in 0 to 3 loop
            C_tg0_out(k) <= C_buf(row_idx)(k);
        end loop;
        
        --TG4 current C row
        for k in 0 to 3 loop
            C_tg4_out(k) <= C_buf(row_idx+4)(k);
        end loop;
        
        --B_blk_out indices:
        --0..3 = row0
        --4..7 = row1
        --8..11 = row2
        --12..15 = row3
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                B_blk_out(r*4+c) <= B_buf(r+b_base)(c);
            end loop;
        end loop;
   
    end process;
    
end rtl;