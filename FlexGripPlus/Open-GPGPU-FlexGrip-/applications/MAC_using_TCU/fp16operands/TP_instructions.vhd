
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TP_instructions is
	port(
		instruction_pointer_in : in  integer;
		num_instructions_out   : out integer;
		instruction_out        : out std_logic_vector(31 downto 0)
	);
end TP_instructions;

architecture arch of TP_instructions is

    constant TP_INSTRUCTIONS : integer := 150; --the total number of instructions of this program

begin

    num_instructions_out <= TP_INSTRUCTIONS;

    process(instruction_pointer_in)

    begin

        case(instruction_pointer_in) is

            --try out program which loads matrixA elements to various register files

            --assumes that in c[0x0][0x0] is 0x00000003
            --        that in c[0x0][0x1] is 0x00000001
            --        that in c[0x0][0x2] is 0x00000004 - general offset between two 32 bit loads
            --        that in c[0x0][0x3] is 0x00000200 - the address of matrix B in global mem 
            --        that in c[0x0][0x4] is 0x00000400 - the address of matric C in global mem
            --        that                   0x00000000 is the address of ammatrix A in global mem

            
            when 0  => instruction_out <= x"D0000005" ; --LOP.AND.U32 R1, R0, c[0x0][0x0] 
            when 1  => instruction_out <= x"04400F70" ; 
            
            when 2  => instruction_out <= x"30050205" ; --SHL R1, R1, 0x5
            when 3  => instruction_out <= x"C4100780" ;

            when 4  => instruction_out <= x"30040009" ; --SHR.U32 R2, R0, 0x4 --related to matA and matB load offset calc
            when 5  => instruction_out <= x"E4100780" ;

            when 6 => instruction_out <= x"30030015" ; --SHR.U32 R5, R0, 0x3 --related to matB offset calc
            when 7 => instruction_out <= x"E4100780" ;

            when 8 => instruction_out <= x"D0010A15" ; --LOP.AND R5, R5, c[0x0][0x1] --related to matB offset cal
            when 9 => instruction_out <= x"04400780" ;

            when 10 => instruction_out <= x"30080A15" ; --SHL R5, R5, 0x8
            when 11 => instruction_out <= x"C4100780" ;

            
            when 12  => instruction_out <= x"30070409" ; --SHL R2, R2, 0x7 
            when 13  => instruction_out <= x"C4100780" ;
            
            when 14 => instruction_out <= x"20000211" ; --IADD R4, R1, R5
            when 15 => instruction_out <= x"04014780" ;

            when 16 => instruction_out <= x"20000811" ; --IADD R4, R4, R2
            when 17 => instruction_out <= x"04008780" ;

            when 18 => instruction_out <= x"21000811" ; --IADD R4, R4, c[0x0][0x3] adress of B in global
            when 19 => instruction_out <= x"0400C780" ;

            
            when 20 => instruction_out <= x"3002000D" ; --SHR.U32 R3, R0, 0x2  --related to matA load offset calc
            when 21 => instruction_out <= x"E4100780" ;

            when 22 => instruction_out <= x"D001060D" ; --LOP.AND R3, R3, c[0x0][0x1]
            when 23 => instruction_out <= x"04400780" ;

            when 24 => instruction_out <= x"3008060D" ; --SHL R3, R3, 0x8
            when 25 => instruction_out <= x"C4100780" ;

            when 26 => instruction_out <= x"20000205" ; --IADD R1, R1, R2 
            when 27 => instruction_out <= x"04008780" ;

            when 28 => instruction_out <= x"20000205" ; --IADD R1, R1, R3 
            when 29 => instruction_out <= x"0400C780" ;

            --load of matrixA (stored in row major order in global)
            
            --load of columns 0-3 of matrixA in registers R22-R23
            when 30 => instruction_out <= x"D0000259" ; --GLD.U32 R22, global0[R1]
            when 31 => instruction_out <= x"80C00780" ;

            when 32 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 33 => instruction_out <= x"04008780" ;

            when 34 => instruction_out <= x"D000025D" ; --GLD.U32 R23, global0[R1]
            when 35 => instruction_out <= x"80C00780" ;

            when 36 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 37 => instruction_out <= x"04008780" ; 

            --load of columns 4-7 of matrixA in registers R16-R17
            when 38 => instruction_out <= x"D0000241" ; --GLD.U32 R16, global0[R1]
            when 39 => instruction_out <= x"80C00780" ;

            when 40 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 41 => instruction_out <= x"04008780" ;

            when 42 => instruction_out <= x"D0000245" ; --GLD.U32 R17, global0[R1]
            when 43 => instruction_out <= x"80C00780" ;

            when 44 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 45 => instruction_out <= x"04008780" ;

            --load of columns 8-11 of matrixA in registers R18-R19
            when 46 => instruction_out <= x"D0000249" ; --GLD.U32 R18, global0[R1]
            when 47 => instruction_out <= x"80C00780" ;

            when 48 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 49 => instruction_out <= x"04008780" ;

            when 50 => instruction_out <= x"D000024D" ; --GLD.U32 R19, global0[R1]
            when 51 => instruction_out <= x"80C00780" ;

            when 52 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 53 => instruction_out <= x"04008780" ;

            --load of columns 12-15 of matrixA in registers R2-R3
            when 54 => instruction_out <= x"D0000209" ; --GLD.U32 R2, global0[R1]
            when 55 => instruction_out <= x"80C00780" ;

            when 56 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 57 => instruction_out <= x"04008780" ;

            when 58 => instruction_out <= x"D000020D" ; --GLD.U32 R3, global0[R1]
            when 59 => instruction_out <= x"80C00780" ;

            when 60 => instruction_out <= x"21000205" ; --IADD R1, R1, c[0x0][0x2]
            when 61 => instruction_out <= x"04008780" ;

            --load of matrixB (stored in colomn major layout in global)
            
            --load of rows 0-3 of matrixB in registers R12-R13
            when 62 => instruction_out <= x"D0000831" ; -- GLD.U32 R12, global0[R4]
            when 63 => instruction_out <= x"80C00780" ;

            when 64 => instruction_out <= x"21000811" ; --IADD R4, R4, c[0x0][0x2]
            when 65 => instruction_out <= x"04008780" ;

            when 66 => instruction_out <= x"D0000835" ; -- GLD.U32 R13, global0[R4]
            when 67 => instruction_out <= x"80C00780" ;

            when 68 => instruction_out <= x"21000811" ; --IADD R4, R4, c[0x0][0x2]
            when 69 => instruction_out <= x"04008780" ;

            --load of rows 4-7 of matrixB in registers R14-R15
            when 70 => instruction_out <= x"D0000839" ; -- GLD.U32 R14, global0[R4]
            when 71 => instruction_out <= x"80C00780" ;

            when 72 => instruction_out <= x"21000811" ; -- IADD R4, R4, c[0x0][0x2]
            when 73 => instruction_out <= x"04008780" ;

            when 74 => instruction_out <= x"D000083D" ; -- GLD.U32 R15, global0[R4]
            when 75 => instruction_out <= x"80C00780" ;

            when 76 => instruction_out <= x"21000811" ; -- IADD R4, R4, c[0x0][0x2]
            when 77 => instruction_out <= x"04008780" ;

            --load of rows 8-11 of matrixB in registers R8-R9
            when 78 => instruction_out <= x"D0000821" ; -- GLD.U32 R8, global0[R4]
            when 79 => instruction_out <= x"80C00780" ;

            when 80 => instruction_out <= x"21000811" ; -- IADD R4, R4, c[0x0][0x2]
            when 81 => instruction_out <= x"04008780" ;

            when 82 => instruction_out <= x"D0000825" ; -- GLD.U32 R9, global[R4]
            when 83 => instruction_out <= x"80C00780" ;

            when 84 => instruction_out <= x"21000811" ; -- IADD R4, R4, c[0x0][0x2]
            when 85 => instruction_out <= x"04008780" ;

            --load of rows 12-15 of matrixB in registers R10-R11
            when 86 => instruction_out <= x"D0000829" ; -- GLD.U32 R10, global0[R4]
            when 87 => instruction_out <= x"80C00780" ;

            when 88 => instruction_out <= x"21000811" ; -- IADD R4, R4, c[0x0][0x2]
            when 89 => instruction_out <= x"04008780" ;

            when 90 => instruction_out <= x"D000082D" ; -- GLD.U32 R11, global0[R4]
            when 91 => instruction_out <= x"80C00780" ;

            --loading the C matrix

            when 92 => instruction_out <= x"D0000005" ; --LOP.AND.U32 R1, R0, c[0x0][0x0] 
            when 93 => instruction_out <= x"04400F70" ; 
            
            when 94 => instruction_out <= x"30050205" ; --SHL R1, R1, 0x5
            when 95 => instruction_out <= x"C4100780" ;

            when 96  => instruction_out <= x"30040055" ; --SHR.U32 R21, R0, 0x4 --related to matA and matB load offset calc
            when 97  => instruction_out <= x"E4100780" ;

            when 98  => instruction_out <= x"30072A55" ; --SHL R21, R21, 0x7 
            when 99  => instruction_out <= x"C4100780" ;

            when 100 => instruction_out <= x"30020061" ; --SHR.U32 R24, R0, 0x2  
            when 101 => instruction_out <= x"E4100780" ;

            when 102 => instruction_out <= x"D0013061" ; --LOP.AND R24, R24, c[0x0][0x1] 
            when 103 => instruction_out <= x"04400780" ;

            when 104 => instruction_out <= x"30083061" ; --SHL R24, R24, 0x8
            when 105 => instruction_out <= x"C4100780" ;

            when 106 => instruction_out <= x"30030065" ; --SHR.U32 R25, R0, 0x3
            when 107 => instruction_out <= x"E4100780" ;

            when 108 => instruction_out <= x"D0013265" ; -- LOP.AND R25, R25, c[0x0][0x1]
            when 109 => instruction_out <= x"04400780" ;

            when 110 => instruction_out <= x"30043265" ; -- SHL R25, R25, 0x4
            when 111 => instruction_out <= x"C4100780" ;

            when 112 => instruction_out <= x"20000269" ; --IADD R26, R1, R21
            when 113 => instruction_out <= x"04054780" ;

            when 114 => instruction_out <= x"20003469" ; --IADD R26, R26, R24
            when 115 => instruction_out <= x"04060780" ;

            when 116 => instruction_out <= x"20003469" ; --IADD R26, R26, R25
            when 117 => instruction_out <= x"04064780" ;

            when 118 => instruction_out <= x"21003469" ; --IADD R26, R26, c[0x0][0x4] adress of C in global
            when 119 => instruction_out <= x"04010780" ;

            --loading of cols __ of matrix C into R4 and R5 registers
            when 120 => instruction_out <= x"D0003411" ; --GLD R4, global0[R26]
            when 121 => instruction_out <= x"80C00780" ;

            when 122 => instruction_out <= x"21003469" ; --IADD R26, R26, c[0x0][0x2]
            when 123 => instruction_out <= x"04008780" ;

            when 124 => instruction_out <= x"D0003415" ; --GLD R5, global0[R26]
            when 125 => instruction_out <= x"80C00780" ;

            when 126 => instruction_out <= x"21003469" ; --IADD R26, R26, c[0x0][0x2]
            when 127 => instruction_out <= x"04008780" ;

            --loading of cols __ of matrix C into R6 and R7 registers

            when 128 => instruction_out <= x"D0003419" ; --GLD R6, global0[R26]
            when 129 => instruction_out <= x"80C00780" ;

            when 130 => instruction_out <= x"21003469" ; --IADD R26, R26, c[0x0][0x2]
            when 131 => instruction_out <= x"04008780" ;

            when 132 => instruction_out <= x"D000341D" ; --GLD R7, global0[R26]
            when 133 => instruction_out <= x"80C00780" ;

            --HMMA sequence utiling tensor cores
            --SET 0 step 0
            when 134 => instruction_out <= x"500C2C11" ; -- hmma.fp16.step0 R4, R22, R12, R4
            when 135 => instruction_out <= x"00410780" ;
            --SET 0 step 1
            when 136 => instruction_out <= x"500C2C19" ; -- hmma.fp16.step1 R6, R22, R12, R6
            when 137 => instruction_out <= x"10418780" ;  --checked till here.
            --SET 1 step 0
            when 138 => instruction_out <= x"500E2011" ; -- hmma.fp16.step0 R4, R16, R14, R4
            when 139 => instruction_out <= x"00410780" ;
            --SET 1 step 1
            when 140 => instruction_out <= x"500E2019" ; -- hmma.fp16.step1 R6, R16, R14, R6
            when 141 => instruction_out <= x"10418780" ;
            --SET 2 step 0
            when 142 => instruction_out <= x"50082411" ; -- hmma.fp16.step0 R4, R18, R8, R4
            when 143 => instruction_out <= x"00410780" ;
            --SET 2 step 1
            when 144 => instruction_out <= x"50082419" ; -- hmma.fp16.step1 R6, R18, R8, R6
            when 145 => instruction_out <= x"10418780" ;
            --SET 3 step 0
            when 146 => instruction_out <= x"500A0411" ; -- hmma.fp16.step0 R4, R2, R10, R4
            when 147 => instruction_out <= x"00410780" ;
            --SET 3 step 1
            when 148 => instruction_out <= x"500A0419" ; -- hmma.fp16.step1 R6, R2, R10, R6
            when 149 => instruction_out <= x"10418780" ;

            --when 10 => instruction_out <= x"" ; --RET
            --when 11 => instruction_out <= x"" ;
            
            when others => null;
        
        end case;

    end process;


end arch;

