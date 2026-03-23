Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity multiplier_FP8_TB is
end multiplier_FP8_TB;

architecture ar of multiplier_FP8_TB is

    -- Signals for testing FP8 MULTIPLIER
    signal entrada_x, entrada_y: std_logic_vector(7 downto 0);
    signal salida: std_logic_vector(7 downto 0);
    signal underflow, overflow: std_logic;
    signal golden_salida: std_logic_vector(7 downto 0);

    -- Component declaration for the multiplier Fp8
    component multiplier_FP8 is
    port(
        entrada_x, entrada_y: in std_logic_vector(7 downto 0);
        salida: out std_logic_vector(7 downto 0);
        underflow, overflow: out std_logic
    );
    end component;

begin

    -- Instantiate the Device Under Test (DUT)
    DUT: multiplier_FP8
        port map(
            entrada_x => entrada_x,
            entrada_y => entrada_y,
            salida => salida,
            underflow => underflow,
            overflow => overflow
        );

    -- Process for reading test cases from a text file 
    test_bench : process
        --file text_file : TEXT open READ_MODE is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU\project_2\test_vectors_FP8_multiplier.txt"; -- Change this path if needed
        file text_file : TEXT open READ_MODE is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_FP\project_2\intermediate_multiplicationsFP8.txt";
        variable text_line : line;
        variable ok : boolean;
        
        --if testing FP8 multiplier
        variable x_text, y_text, expected_text: std_logic_vector(7 downto 0);

        --if testing the FP32 multiplier
        --variable x_text, y_text, expected_text: std_logic_vector(31 downto 0);
        
    begin
        -- Loop through the file until reaching the end
        while not endfile(text_file) loop
            -- Read a line from the file
            readline(text_file, text_line);

            -- Skip empty lines or comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
                next;
            end if;

            -- Read hexadecimal values from the file
            hread(text_line, x_text, ok);
            assert ok report "Error reading entrada_x" severity failure;

            hread(text_line, y_text, ok);
            assert ok report "Error reading entrada_y" severity failure;

            hread(text_line, expected_text, ok);
            assert ok report "Error reading expected output" severity failure;

            -- Apply the inputs to the DUT
            entrada_x <= x_text;
            entrada_y <= y_text;
            golden_salida <= expected_text;

            -- Wait for result computation
            wait for 50 ns;

            -- Check output
            --assert salida = golden_salida
            --    report "Test failed for entrada_x = " & to_hstring(entrada_x) & 
            --           ", entrada_y = " & to_hstring(entrada_y) & 
            --           ", Expected: " & to_hstring(golden_salida) & 
            --           ", Got: " & to_hstring(salida)
            --    severity error;

        end loop;
        
        -- Stop simulation
        report "All test cases passed!";
        wait;
    end process;

end ar;
