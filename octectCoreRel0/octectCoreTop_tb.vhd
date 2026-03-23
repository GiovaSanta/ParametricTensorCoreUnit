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
    
    signal rf_rd_data_port_a : arraySize8_32;
    signal rf_rd_data_port_b : arraySize8_32;
    
    signal W0_8_X3 : arraySize4_8 ;
    signal W1_8_X3 : arraySize4_8 ;
    signal W0_16_X3 : arraySize4_16;
    signal W1_16_X3 : arraySize4_16;
    signal W0_32_X3 : arraySize4_32;
    signal W1_32_X3 : arraySize4_32;
    
    signal step_done: std_logic;
    
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
            W0_32_X3 => W0_32_X3,
            W1_32_X3 => W1_32_X3,
            
            step_done => step_done
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
        
        rf_rd_data_port_a <= (others => (others => '0'));
        rf_rd_data_port_b <= (others => (others => '0'));
        
        wait for 3*CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        --load A, pair 00
        --for FP16 convention, slots 0 and 1 of the A and C buffers are enough
        --(each slot of the buffer in fp16 format contains two values)
        
        load_en <= '1';
        load_ph <= "00"; --means we are loading information of A into buffer A
        load_pair <= "00";
        
        rf_rd_data_port_a <= (others => (others => '0'));
        rf_rd_data_port_b <= (others => (others => '0'));
        
        --TG0 lanes 0..3 first row A00: 4c62 c3d3 4dbd 4a51
        rf_rd_data_port_a(0) <= x"c3d34c62" ;
        rf_rd_data_port_b(0) <= x"4a514dbd" ;
                      --2nd row A00: ce7e 4f9c 4c2e 4c94
        rf_rd_data_port_a(1) <= x"4f9cce7e" ;
        rf_rd_data_port_b(1) <= x"4c944c2e" ;
                      --3rd row A00: cdf3 c25a c822 4ed4
        rf_rd_data_port_a(2) <= x"c25acdf3" ;
        rf_rd_data_port_b(2) <= x"4ed4c822" ;
                      --4th row A00: 489b 4d2a c33e cc5d
        rf_rd_data_port_a(3) <= x"4d2a489b" ;
        rf_rd_data_port_b(3) <= x"cc5dc33e" ;
        
        --TG4 lanes 4--7 --A20 related matrix load
        rf_rd_data_port_a(4) <= x"00420041" ;
        rf_rd_data_port_b(4) <= x"00440043" ;
        
        rf_rd_data_port_a(5) <= x"00520051" ;
        rf_rd_data_port_b(5) <= x"00540053" ;
        
        rf_rd_data_port_a(6) <= x"00620061" ;
        rf_rd_data_port_b(6) <= x"00640063" ;
        
        rf_rd_data_port_a(7) <= x"00720071" ;
        rf_rd_data_port_b(7) <= x"00740073" ;
        
        wait for CLK_PERIOD;
        load_en <= '0';
        wait for CLK_PERIOD;
        
        --Load B, pair 00 ,(load pair doesnt need to set to 01 in fp16 because each value of the registers correspond to 2 values, 
        --meaning that for each laneBufferB, 2 slots of 32 bits (slot0 and slot1) are enough for containing the 4 elements related to a particular lane which a corresponding thread of a threadgroup had to load
        
        load_en <= '1' ;
        load_ph <= "01" ;  -- means we are loading B laneBuffers.
        load_pair <= "00" ; -- means we are loading into slots0 and 1 of the laneBUffersB.
        
        rf_rd_data_port_a <= (others => (others => '0'));
        rf_rd_data_port_b <= (others => (others => '0'));
        
        --for step0 hmma instruction, lanes 0 to 3 matter for the stationary 4by4 B block at execution time, 
        --but the loading of the laneBuffers is done at the same time.
        
        --TG0 lanes 0 to 3 matrix B00 first col load: 42fd, cefb, 4d3e, 4837
        rf_rd_data_port_a(0) <= x"cefb42fd" ;
        rf_rd_data_port_b(0) <= x"48374d3e" ;
                          --matrix B00 second col load: 4c21, c8a8, 4f88, 4e4a
        rf_rd_data_port_a(1) <= x"c8a84c21" ;
        rf_rd_data_port_b(1) <= x"4e4a4f88" ;
                          --matrix B00 third col load: 4c74, cce3,cd42, cf4d
        rf_rd_data_port_a(2) <= x"cce34c74" ;
        rf_rd_data_port_b(2) <= x"cf4dc042" ;
                          --matrix B00 forth col load: cd88, 49dc, 4bd5, 4f7b
        rf_rd_data_port_a(3) <= x"49dccd88" ;
        rf_rd_data_port_b(3) <= x"4f7b4bd5" ;
        
        --TG4 lanes 4--7 --B01 relative elements. first col of B01
        rf_rd_data_port_a(4) <= x"02020201" ;
        rf_rd_data_port_b(4) <= x"02040203" ;
                             --second col of B01
        rf_rd_data_port_a(5) <= x"02120211" ;
        rf_rd_data_port_b(5) <= x"02140213" ;
                             --third col of B01
        rf_rd_data_port_a(6) <= x"02220221" ;
        rf_rd_data_port_b(6) <= x"02240223" ;
                             --forth col of B01
        rf_rd_data_port_a(7) <= x"02320231" ;
        rf_rd_data_port_b(7) <= x"02340233" ;
        
        wait for CLK_PERIOD;
        load_en <= '0';
        wait for CLK_PERIOD;
        
        --Load C, pair 00
        
        load_en <= '1';
        load_ph <= "10"; --selecting the loading of laneBuffersC 
        load_pair <= "00"; --again, since testing fp16 in this particular testbench, the slots 0 and slot 1 of a particular laneBufferC
        --are enough to store the 4 elements related to a specific thread.
        
        rf_rd_data_port_a <= (others =>(others => '0'));
        rf_rd_data_port_b <= (others =>(others => '0'));
        --first row of C00: c993, c825, bfcb, ccf8
        rf_rd_data_port_a(0) <= x"c825c993" ;
        rf_rd_data_port_b(0) <= x"ccf8bfcb" ;
        --second row of C00: cdec, be38, cc5f, 496f
        rf_rd_data_port_a(1) <= x"be38cdec" ;
        rf_rd_data_port_b(1) <= x"496fcc5f" ;
        --third row C00: c406, 4d53, 4a69, ca01
        rf_rd_data_port_a(2) <= x"4d53c406" ;
        rf_rd_data_port_b(2) <= x"ca014a69" ;
        --forth row C00: 4d51, 4ce0, c734, cac6
        rf_rd_data_port_a(3) <= x"4ce04d51" ;
        rf_rd_data_port_b(3) <= x"cac6c734" ;
        
        --TG4 lanes 4--7 -- related to C20
        rf_rd_data_port_a(4) <= x"10421041" ;
        rf_rd_data_port_b(4) <= x"10441043" ;
        
        rf_rd_data_port_a(5) <= x"10521051" ;
        rf_rd_data_port_b(5) <= x"10541053" ;
        
        rf_rd_data_port_a(6) <= x"10621061" ;
        rf_rd_data_port_b(6) <= x"10641063" ;
        
        rf_rd_data_port_a(7) <= x"10721071" ;
        rf_rd_data_port_b(7) <= x"10741073" ;
        
        wait for CLK_PERIOD;
        load_en <= '0';
        exec_step <= "01";
        wait for CLK_PERIOD;
        
        --execution sweep
        --step through the 4 execution rows
        exec_step <= "10";
        wait for CLK_PERIOD;
        
        exec_step <= "11";
        wait for CLK_PERIOD;
        
        --end 
        
        wait for 5*CLK_PERIOD;
        assert false report "End of testbench" severity failure;
    end process;
        
end sim;
