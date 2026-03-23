library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.dpuArray_package.all;

entity octectCoreTop_tb is
end octectCoreTop_tb;

--for now this testbench will verify the execution of what happens with an octect execution (threadGroup0+threadGroup4 for instance)
--for a hmmaStep0 instruction type . 

architecture sim of octectCoreTop_tb is

    --DUT Generics
    constant LANES  : integer := 8;
    constant REG_W  : integer := 32;
    constant ELEM_W : integer := 32;
    
    --clock period
    constant CLK_PERIOD : time := 10 ns;
    
    constant WIDTH_FP16 : std_logic_vector(1 downto 0) := "01";
    constant TYPE_FP    : std_logic_vector(2 downto 0) := "000";
    
    --DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    
    signal widthSel : std_logic_vector(1 downto 0) := (others => '0');
    signal typeSel  : std_logic_vector(2 downto 0) := (others => '0');
    signal load_en  : std_logic := '0' ;
    signal load_ph  : std_logic_vector(1 downto 0) := (others => '0'); --selects if we Are loading buffer A, or bufferB or buffer C
    signal load_pair: std_logic_vector(1 downto 0) := (others => '0'); --signal which selcets which slots of the particular lane Buffer you write into.
                            --for instance load_pair equal to 00 means that we write into slot0 and slot1 of all the laneBuffers. while 01  means we write into slot2 and slot3 of all the lane buffers..
    signal hmma_step : std_logic := '0' ; --used for telling which submatrix of B to take in the threadgroups of the octect. step0 means we take the content of laneBuffers related to lanes0to3 (which were loaded by threadgroup0) 
                                          --while step1 means that the dpuArray executes with the content fetched from laneBuffers4 to 7, which contain matrixB submatrix which was loaded by threafgroup4.
    
    signal exec_step: std_logic_vector(1 downto 0) := (others => '0'); --a threadgroups takes 2 cycles to produce a 2x4 subtile of the output matrix (as said by research article). 
                                                                      --so 4 cycles/substeps are needed for a threadgroup to produce the full result subtile related to the particular hmmastep instruction at hand.  
    
    signal rf_rd_data_port_a : std_logic_vector(LANES*REG_W-1 downto 0) := (others => '0');
    signal rf_rd_data_port_b : std_logic_vector(LANES*REG_W-1 downto 0) := (others => '0');
    
    signal W0_8_X3 : arraySize4_8 ;
    signal W1_8_X3 : arraySize4_8 ;
    signal W0_16_X3 : arraySize4_16;
    signal W1_16_X3 : arraySize4_16;
    signal W0_32_X3 : arraySize4_32;
    signal W1_32_X3 : arraySize4_32;
    
    --helper procedure
    --lane0 is the least significant 32 bits of the bus
    
    procedure set_lane_word(
        signal bus_sig : out std_logic_vector;
        constant lane  : in integer;
        constant value : in std_logic_vector(31 downto 0)
    ) is 
        variable hi : integer ;
        variable lo : integer ;
    begin
        lo := lane * 32;
        hi := lo + 31;
        bus_sig(hi downto lo) <= value;
    end procedure;
    
begin
    --clock
    clk <= not clk after CLK_PERIOD/2;
    
    --DUT
    dut : entity work.octectCoreTop
        generic map(
            LANES => LANES,
            REG_W => REG_W,
            ELEM_W => ELEM_W
        )
        port map(
            clk => clk,
            rst => rst,
            
            widthSel => widthSel,
            typeSel => typeSel,
            load_en => load_en,
            load_ph => load_ph,
            load_pair => load_pair,
            hmma_step => hmma_step,
            exec_step => exec_step,
            
            rf_rd_data_port_a => rf_rd_data_port_a,
            rf_rd_data_port_b => rf_rd_data_port_b,
            
            W0_8_X3 =>  W0_8_X3,
            W1_8_X3 =>  W1_8_X3,
            W0_16_X3 => W0_16_X3,
            W1_16_X3 => W1_16_X3,
            W0_32_X3 => W0_32_x3,
            W1_32_X3 => W1_32_X3
        );

    --Stimulus
    
    stim_proc : process
    begin
        --reset
        widthSel    <= WIDTH_FP16;
        typeSel     <= TYPE_FP;
        
        load_en     <= '0';
        load_ph     <= "00";
        load_pair   <= "00";
        exec_step   <= "00";
        
        rf_rd_data_port_a <= (others => '0');
        rf_rd_data_port_b <= (others => '0');
        
        wait for 3*CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        --load A, pair 00
        --for FP16 convention, slots 0 and 1 of the A and C buffers are enough
        --(each slot of the buffer in fp16 format contains two values)
        
        load_en <= '1';
        load_ph <= "00"; --means we are loading information of A into buffer A
        load_pair <= "00";
        
        rf_rd_data_port_a <= (others => '0');
        rf_rd_data_port_b <= (others => '0');
        
        --TG0 lanes 0..3
        set_lane_word(rf_rd_data_port_a, 0, x"00020001");
        set_lane_word(rf_rd_data_port_b, 0, x"00040003");
        
        set_lane_word(rf_rd_data_port_a, 1, x"00120011");
        set_lane_word(rf_rd_data_port_b, 1, x"00140013");
        
        set_lane_word(rf_rd_data_port_a, 2, x"00220021");
        set_lane_word(rf_rd_data_port_b, 2, x"00240023");
        
        set_lane_word(rf_rd_data_port_a, 3, x"00320031");
        set_lane_word(rf_rd_data_port_b, 3, x"00340033");
        
        --TG4 lanes 4--7
        set_lane_word(rf_rd_data_port_a, 4, x"00420041");
        set_lane_word(rf_rd_data_port_b, 4, x"00440043");
        
        set_lane_word(rf_rd_data_port_a, 5, x"00520051");
        set_lane_word(rf_rd_data_port_b, 5, x"00540053");
        
        set_lane_word(rf_rd_data_port_a, 6, x"00620061");
        set_lane_word(rf_rd_data_port_b, 6, x"00640063");
        
        set_lane_word(rf_rd_data_port_a, 7, x"00720071");
        set_lane_word(rf_rd_data_port_b, 7, x"00740073");
        
        wait for CLK_PERIOD;
        load_en <= '0';
        wait for CLK_PERIOD;
        
        --Load B, pair 00 ,(load pair doesnt need to set to 01 in fp16 because each value of the registers correspond to 2 values, 
        --meaning that for each laneBufferB, 2 slots of 32 bits (slot0 and slot1) are enough for containing the 4 elements related to a particular lane which a corresponding thread of a threadgroup had to load
        
        load_en <= '1';
        load_ph <= "01";  -- means we are loading B laneBuffers.
        load_pair <= "00"; -- means we are loading into slots0 and 1 of the laneBUffersB.
        
        rf_rd_data_port_a <= (others => '0');
        rf_rd_data_port_b <= (others => '0');
        
        --for step0 hmma instruction, lanes 0 to 3 matter for the stationary 4by4 B block at execution time, 
        --but the loading of the laneBuffers is done at the same time.
        
        --TG0 lanes 0 to 3
        set_lane_word(rf_rd_data_port_a, 0, x"01030102");
        set_lane_word(rf_rd_data_port_b, 0, x"01050104");
        
        set_lane_word(rf_rd_data_port_a, 1, x"01120111");
        set_lane_word(rf_rd_data_port_b, 1, x"01140113");
        
        set_lane_word(rf_rd_data_port_a, 2, x"01220121");
        set_lane_word(rf_rd_data_port_b, 2, x"01240123");
        
        set_lane_word(rf_rd_data_port_a, 3, x"01320131");
        set_lane_word(rf_rd_data_port_b, 3, x"01340133");
        
        --TG4 lanes 4 to 7
        set_lane_word(rf_rd_data_port_a, 4, x"02020201");
        set_lane_word(rf_rd_data_port_b, 4, x"02040203");
        
        set_lane_word(rf_rd_data_port_a, 5, x"02120211");
        set_lane_word(rf_rd_data_port_b, 5, x"02140213");
        
        set_lane_word(rf_rd_data_port_a, 6, x"02220221");
        set_lane_word(rf_rd_data_port_b, 6, x"02240223");
        
        set_lane_word(rf_rd_data_port_a, 7, x"02320231");
        set_lane_word(rf_rd_data_port_b, 7, x"02340233");
        
        wait for CLK_PERIOD;
        load_en <= '0';
        wait for CLK_PERIOD;
        
        --Load C, pair 00
        
        load_en <= '1';
        load_ph <= "10"; --selecting the loading of laneBuffersC 
        load_pair <= "00"; --again, since testing fp16 in this particular testbench, the slots 0 and slot 1 of a particular laneBufferC
        --are enough to store the 4 elements related to a specific thread.
        
        rf_rd_data_port_a <= (others => '0');
        rf_rd_data_port_b <= (others => '0');
        
        --TG0 lanes 0to3
        set_lane_word(rf_rd_data_port_a, 0, x"10021001");
        set_lane_word(rf_rd_data_port_b, 0, x"10041003");
        
        set_lane_word(rf_rd_data_port_a, 1, x"10121011");
        set_lane_word(rf_rd_data_port_b, 1, x"10141013");
        
        set_lane_word(rf_rd_data_port_a, 2, x"10221021");
        set_lane_word(rf_rd_data_port_b, 2, x"10241023");
        
        set_lane_word(rf_rd_data_port_a, 3, x"10323031");
        set_lane_word(rf_rd_data_port_b, 3, x"10341033");
        
        --TG4 lanes 4 to 7
        set_lane_word(rf_rd_data_port_a, 4, x"10421041");
        set_lane_word(rf_rd_data_port_b, 4, x"10441043");
        
        set_lane_word(rf_rd_data_port_a, 5, x"10521051");
        set_lane_word(rf_rd_data_port_b, 5, x"10541053");
        
        set_lane_word(rf_rd_data_port_a, 6, x"10621061");
        set_lane_word(rf_rd_data_port_b, 6, x"10641063");
        
        set_lane_word(rf_rd_data_port_a, 7, x"10721071");
        set_lane_word(rf_rd_data_port_b, 7, x"10741073");
        
        wait for CLK_PERIOD;
        load_en <= '0';
        wait for CLK_PERIOD;
        
        --execution sweep
        --step through the 4 execution rows
        exec_step <= "00";
        wait for CLK_PERIOD;
        
        exec_step <= "01";
        wait for CLK_PERIOD;
        
        exec_step <= "10";
        wait for CLK_PERIOD;
        
        exec_step <= "11";
        wait for CLK_PERIOD;
        
        --end 
        
        wait for 5*CLK_PERIOD;
        assert false report "End of testbench" severity failure;
    end process;
        
end sim;
