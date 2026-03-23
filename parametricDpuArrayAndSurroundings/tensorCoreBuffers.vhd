

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity octetRelatedBuffers is
    generic (
        LANES           : integer := 8;
        REG_W           : integer := 32;
        FP16_W          : integer := 16
    );
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        
        --control
        load_en         : in std_logic;
        load_ph         : in std_logic_vector(1 downto 0);
        -- 00 = load A
        -- 01 = load B
        -- 10 = load C
        
        --register file read return (per lane, packed)
        rf_rd_data_port_a    : in std_logic_vector(LANES*REG_W-1 downto 0);
        rf_rd_data_port_b    : in std_logic_vector(LANES*REG_W-1 downto 0);
        
        --outputs to DPU array
        A_out           : out std_logic_vector(LANES*4*FP16_W-1 downto 0);
        B_out           : out std_logic_vector(LANES*4*FP16_W-1 downto 0);
        C_out           : out std_logic_vector(LANES*4*FP16_W-1 downto 0)
    );
end octetRelatedBuffers;

architecture rtl of octetRelatedBuffers is

    subtype fp16_t is std_logic_vector(FP16_W-1 downto 0);
    type fp16_vec4_t is array (0 to 3) of fp16_t;
    type lane8_buf_t is array (0 to LANES-1) of fp16_vec4_t;
    
    signal A_buf : lane8_buf_t; 
    signal B_buf : lane8_buf_t;
    signal C_buf : lane8_buf_t;
    
begin

    --load process
    process(clk)
        variable regA_lane : std_logic_vector(REG_W-1 downto 0);
        variable regB_lane : std_logic_vector(REG_W-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
            --clear ?
            for l in 0 to LANES-1 loop
                for k in 0 to 3 loop
                    A_buf(l)(k) <= (others => '0');
                    B_buf(l)(k) <= (others => '0');
                    C_buf(l)(k) <= (others => '0');
                end loop;
            end loop;
            
            elsif load_en = '1' then
                for lane in 0 to LANES-1 loop
                
                regA_lane := rf_rd_data_port_a((lane+1)*REG_W-1 downto lane*REG_W);
                regB_lane := rf_rd_data_port_b((lane+1)*REG_W-1 downto lane*REG_W);
                
                case load_ph is
                
                    when "00" => --LOAD A buffer related to a specific octect. 
                                --example for octet0: threadgroup0 content is stored in pointer A_buf[lane0], A_buf[lane1], A_buf[lane2], A_buf[lane3]. 
                                --                    while threadgroup4 content is stored in A_buf[lane4], A_buf[lane5], A_buf[lane6], A_buf[lane7]
                        A_buf(lane)(0) <= regA_lane(15 downto 0);
                        A_buf(lane)(1) <= regA_lane(31 downto 16);
                        A_buf(lane)(2) <= regB_lane(15 downto 0);
                        A_buf(lane)(3) <= regB_lane(31 downto 16);
                        
                    when "01" => --LOAD B buffer related to a specific octet
                        B_buf(lane)(0) <= regA_lane(15 downto 0);
                        B_buf(lane)(1) <= regA_lane(31 downto 16);
                        B_buf(lane)(2) <= regB_lane(15 downto 0);
                        B_buf(lane)(3) <= regB_lane(31 downto 16);
                        
                    when "10" => --LOAD C buffer related to a specific octet
                        C_buf(lane)(0) <= regA_lane(15 downto 0);
                        C_buf(lane)(1) <= regA_lane(31 downto 16);
                        C_buf(lane)(2) <= regB_lane(15 downto 0);
                        C_buf(lane)(3) <= regB_lane(31 downto 16);
                    when others =>
                        null;
                        
                end case;
                
                end loop;
            end if;
        end if;
    end process;
    
    --flatten outputs for DPU Array
    
    process( A_buf, B_buf, C_buf )
        variable idx : integer := 0;
    
    begin
        idx := 0;
        for l in 0 to LANES-1 loop
            for k in 0 to 3 loop
                A_out(idx + FP16_W-1 downto idx) <= A_buf(l)(k);
                idx := idx + FP16_W;
            end loop;
        end loop;
        
        idx := 0;
        for l in 0 to LANES-1 loop 
            for k in 0 to 3 loop
                B_out(idx + FP16_W-1 downto idx) <= B_buf(l)(k);
                idx := idx + FP16_W;
            end loop;
        end loop;
        
        idx := 0;
        for l in 0 to LANES-1 loop
            for k in 0 to 3 loop
                C_out(idx + FP16_W-1 downto idx) <= C_buf(l)(k);
                idx := idx + FP16_W;
            end loop;
        end loop;
        
    end process;

end rtl;
