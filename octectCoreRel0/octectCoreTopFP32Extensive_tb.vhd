library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity octectCoreTopv2Extensive_fp32_tb is
end octectCoreTopv2Extensive_fp32_tb;

architecture sim of octectCoreTopv2Extensive_fp32_tb is

    -- DUT Generics
    constant LANES  : integer := 8;
    constant REG_W  : integer := 32;
    constant ELEM_W : integer := 32;

    -- Clock/config
    constant CLK_PERIOD : time := 10 ns;

    -- IMPORTANT: adjust if your widthSel encoding for FP32 is different
    constant WIDTH_FP32 : std_logic_vector(1 downto 0) := "10";
    constant TYPE_FP    : std_logic_vector(2 downto 0) := "000";

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal widthSel  : std_logic_vector(1 downto 0) := (others => '0');
    signal typeSel   : std_logic_vector(2 downto 0) := (others => '0');
    signal load_en   : std_logic := '0';
    signal load_ph   : std_logic_vector(1 downto 0) := (others => '0');
    signal load_pair : std_logic_vector(1 downto 0) := (others => '0');
    signal hmma_step : std_logic := '0';
    signal exec_step : std_logic_vector(1 downto 0) := (others => '0');

    signal rf_rd_data_port_a : arraySize8_32;
    signal rf_rd_data_port_b : arraySize8_32;

    signal W0_8_X3  : arraySize4_8;
    signal W1_8_X3  : arraySize4_8;
    signal W0_16_X3 : arraySize4_16;
    signal W1_16_X3 : arraySize4_16;
    signal W0_32_X3 : arraySize4_32;
    signal W1_32_X3 : arraySize4_32;

    signal step_done : std_logic;

    -- TB-only type to reconstruct full 4x4 FP32 matrices
    type matrix4x4_fp32_t is array (0 to 3, 0 to 3) of std_logic_vector(31 downto 0);

    -- Input/output files
    file tb_file : text open read_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/fp32related/hmma_step0_tb_input_fp32.txt";

    file tb_out_file : text open write_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/fp32related/hmma_step0_tb_output_fp32.txt";

    ------------------------------------------------------------------------
    -- Helpers
    ------------------------------------------------------------------------

    procedure clear_rf_ports(
        signal port_a : out arraySize8_32;
        signal port_b : out arraySize8_32
    ) is
    begin
        port_a <= (others => (others => '0'));
        port_b <= (others => (others => '0'));
    end procedure;


    procedure read_next_port_pair(
        file f : text;
        variable val_a : out std_logic_vector(31 downto 0);
        variable val_b : out std_logic_vector(31 downto 0);
        variable ok    : out boolean
    ) is
        variable L : line;
        variable tmp_a : std_logic_vector(31 downto 0);
        variable tmp_b : std_logic_vector(31 downto 0);
    begin
        ok := false;

        while not endfile(f) loop
            readline(f, L);

            if L = null then
                null;
            elsif L.all'length = 0 then
                null;
            elsif L.all(1) = '#' then
                null;
            else
                hread(L, tmp_a);
                hread(L, tmp_b);
                val_a := tmp_a;
                val_b := tmp_b;
                ok := true;
                return;
            end if;
        end loop;
    end procedure;


    procedure load_8_lanes_from_file(
        file f : text;
        signal port_a : out arraySize8_32;
        signal port_b : out arraySize8_32;
        variable success : out boolean
    ) is
        variable v_a : std_logic_vector(31 downto 0);
        variable v_b : std_logic_vector(31 downto 0);
        variable ok  : boolean;
    begin
        success := false;

        for i in 0 to 7 loop
            read_next_port_pair(f, v_a, v_b, ok);

            if not ok then
                if i = 0 then
                    return;
                else
                    assert false
                        report "Unexpected EOF while reading an 8-lane FP32 load block from stimulus file"
                        severity failure;
                end if;
            end if;

            port_a(i) <= v_a;
            port_b(i) <= v_b;
        end loop;

        success := true;
    end procedure;


    procedure write_matrix4x4_hex(
        file f : text;
        constant M : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        for r in 0 to 3 loop
            L := null;
            for c in 0 to 3 loop
                hwrite(L, M(r, c));
                if c < 3 then
                    write(L, string'(" "));
                end if;
            end loop;
            writeline(f, L);
        end loop;
    end procedure;


    procedure write_test_result(
        file f : text;
        constant idx : in integer;
        constant D00 : in matrix4x4_fp32_t;
        constant D20 : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#Test "));
        write(L, idx);
        write(L, string'(" HMMAstep0 related D00 and D20 result submatrices (FP32)"));
        writeline(f, L);

        L := null;
        write(L, string'("#D00"));
        writeline(f, L);
        write_matrix4x4_hex(f, D00);

        L := null;
        write(L, string'("#D20"));
        writeline(f, L);
        write_matrix4x4_hex(f, D20);

        L := null;
        writeline(f, L);
    end procedure;

begin

    ------------------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    ------------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------------
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
            W0_8_X3 => W0_8_X3,
            W1_8_X3 => W1_8_X3,
            W0_16_X3 => W0_16_X3,
            W1_16_X3 => W1_16_X3,
            W0_32_X3 => W0_32_X3,
            W1_32_X3 => W1_32_X3,
            step_done => step_done
        );

    ------------------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------------------
    stim_proc : process
        variable have_data   : boolean;
        variable test_idx    : integer := 0;
        variable D00_capture : matrix4x4_fp32_t;
        variable D20_capture : matrix4x4_fp32_t;
    begin
        -- Initial configuration
        widthSel  <= WIDTH_FP32;
        typeSel   <= TYPE_FP;
        load_en   <= '0';
        load_ph   <= "00";
        load_pair <= "00";
        hmma_step <= '0';
        exec_step <= "00";

        clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);

        -- Reset
        wait for 3*CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Loop over all tests contained in the file
        while true loop
            test_idx := test_idx + 1;

            ----------------------------------------------------------------
            -- LOAD A, pair00  (cols 0,1 -> slots 0,1)
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_en   <= '1';
            load_ph   <= "00";
            load_pair <= "00";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);
            exit when not have_data;
            
            wait for CLK_PERIOD;

            ----------------------------------------------------------------
            -- LOAD A, pair01  (cols 2,3 -> slots 2,3)
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_ph   <= "00";
            load_pair <= "01";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);

            assert have_data
                report "Stimulus file ended unexpectedly while reading A pair01 block for test " &
                       integer'image(test_idx)
                severity failure;

            wait for CLK_PERIOD;
            load_en <= '0';
            wait for CLK_PERIOD;

            ----------------------------------------------------------------
            -- LOAD B, pair00
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_en   <= '1';
            load_ph   <= "01";
            load_pair <= "00";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);
            

            assert have_data
                report "Stimulus file ended unexpectedly while reading B pair00 block for test " &
                       integer'image(test_idx)
                severity failure;
            
            wait for CLK_PERIOD;
            ----------------------------------------------------------------
            -- LOAD B, pair01
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_ph   <= "01";
            load_pair <= "01";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);

            assert have_data
                report "Stimulus file ended unexpectedly while reading B pair01 block for test " &
                       integer'image(test_idx)
                severity failure;

            wait for CLK_PERIOD;
            load_en <= '0';
            wait for CLK_PERIOD;

            ----------------------------------------------------------------
            -- LOAD C, pair00
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_en   <= '1';
            load_ph   <= "10";
            load_pair <= "00";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);
            
            
            assert have_data
                report "Stimulus file ended unexpectedly while reading C pair00 block for test " &
                       integer'image(test_idx)
                severity failure;
            
            wait for CLK_PERIOD;
            ----------------------------------------------------------------
            -- LOAD C, pair01
            ----------------------------------------------------------------
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            load_ph   <= "10";
            load_pair <= "01";

            load_8_lanes_from_file(tb_file, rf_rd_data_port_a, rf_rd_data_port_b, have_data);

            assert have_data
                report "Stimulus file ended unexpectedly while reading C pair01 block for test " &
                       integer'image(test_idx)
                severity failure;

            wait for CLK_PERIOD;
            load_en <= '0';
            wait for CLK_PERIOD;

            ----------------------------------------------------------------
            -- Execution sweep for HMMAstep0
            -- Assumption: W0_32_X3 and W1_32_X3 each expose one 1x4 FP32 row
            -- per exec_step, exactly like the FP16 case.
            ----------------------------------------------------------------
            exec_step <= "00";
            wait for CLK_PERIOD;
            for c in 0 to 3 loop
                D00_capture(0, c) := W0_32_X3(c);
                D20_capture(0, c) := W1_32_X3(c);
            end loop;

            exec_step <= "01";
            wait for CLK_PERIOD;
            for c in 0 to 3 loop
                D00_capture(1, c) := W0_32_X3(c);
                D20_capture(1, c) := W1_32_X3(c);
            end loop;

            exec_step <= "10";
            wait for CLK_PERIOD;
            for c in 0 to 3 loop
                D00_capture(2, c) := W0_32_X3(c);
                D20_capture(2, c) := W1_32_X3(c);
            end loop;

            exec_step <= "11";
            wait for CLK_PERIOD;
            for c in 0 to 3 loop
                D00_capture(3, c) := W0_32_X3(c);
                D20_capture(3, c) := W1_32_X3(c);
            end loop;

            -- Write results for this test
            write_test_result(tb_out_file, test_idx, D00_capture, D20_capture);

            -- Optional idle cycle between tests
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            exec_step <= "00";
            wait for CLK_PERIOD;

            report "Completed HMMAstep0 FP32 test #" & integer'image(test_idx);
        end loop;

        wait for 5*CLK_PERIOD;
        assert false report "End of file reached. End of FP32 testbench." severity failure;
    end process;

end sim;
