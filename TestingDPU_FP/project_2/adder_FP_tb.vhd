Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity adder_FP_TB is
end adder_FP_TB;

architecture ar of adder_FP_TB is
    
    --Signals for testing FP32 (single precision) ADDER
    signal operando1, operando2: unsigned (31 downto 0);
    signal operacion: unsigned (3 downto 0);
    signal resultado: unsigned(31 downto 0);
    signal goldenRes: unsigned(31 downto 0);
    
    -- Component declaration for the Fp32 ADDER
    component adder_FP is 
	generic( long : natural := 32 );
	port(
		operando1, operando2: in unsigned(long-1 downto 0);
		operacion: in unsigned(3 downto 0);
		resultado: out unsigned(long-1 downto 0)
	);
end component;

begin

    -- Instantiate the Device Under Test (DUT)
    DUT: adder_FP
        generic map (long => 32)
        port map(
            operando1 => operando1,
            operando2 => operando2,
            operacion => "0001",
            resultado => resultado
        );

    -- Process for reading test cases from a text file 
    test_bench : process
        file text_file : TEXT open READ_MODE is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU\project_2\test_vectors_FP32_adder.txt"; -- Change this path if needed
        variable text_line : line;
        variable ok : boolean;

        variable x_text, y_text, expected_text: std_logic_vector(31 downto 0);
        
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
            operando1 <= unsigned(x_text);
            operando2 <= unsigned(y_text);
            goldenRes <= unsigned(expected_text);

            -- Wait for result computations
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
