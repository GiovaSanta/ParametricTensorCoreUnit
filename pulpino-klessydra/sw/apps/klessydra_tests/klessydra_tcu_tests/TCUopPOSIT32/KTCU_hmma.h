#ifndef KTCU_HMMA_H
#define KTCU_HMMA_H

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

/*
  KTCU custom R-type instruction encoding:

  opcode = 0x5B  -> KTCU
  funct3 = HMMA step:
           0x0 = HMMA step 0
           0x1 = HMMA step 1

  funct7 = numeric format:
           0x00 = FP8
           0x01 = FP16
           0x02 = FP32
           0x04 = POSIT8
           0x05 = POSIT16
           0x06 = POSIT32
           0x08 = INT8
           0x09 = INT16
           0x0C = FIXED8
           0x0D = FIXED16
*/

#define KTCU_HMMA_R_ASM(funct3, funct7, rd, rs1, rs2) \
  ".insn r 0x5b, " STR(funct3) ", " STR(funct7) ", " STR(rd) ", " STR(rs1) ", " STR(rs2) "\n"

/* HMMA step 0 */
#define HMMA_0_FP8_ASM(rd, rs1, rs2)      KTCU_HMMA_R_ASM(0x0, 0x00, rd, rs1, rs2)
#define HMMA_0_FP16_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x0, 0x01, rd, rs1, rs2)
#define HMMA_0_FP32_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x0, 0x02, rd, rs1, rs2)
#define HMMA_0_POSIT8_ASM(rd, rs1, rs2)   KTCU_HMMA_R_ASM(0x0, 0x04, rd, rs1, rs2)
#define HMMA_0_POSIT16_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x0, 0x05, rd, rs1, rs2)
#define HMMA_0_POSIT32_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x0, 0x06, rd, rs1, rs2)
#define HMMA_0_INT8_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x0, 0x08, rd, rs1, rs2)
#define HMMA_0_INT16_ASM(rd, rs1, rs2)    KTCU_HMMA_R_ASM(0x0, 0x09, rd, rs1, rs2)
#define HMMA_0_FIXED8_ASM(rd, rs1, rs2)   KTCU_HMMA_R_ASM(0x0, 0x0C, rd, rs1, rs2)
#define HMMA_0_FIXED16_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x0, 0x0D, rd, rs1, rs2)

/* HMMA step 1 */
#define HMMA_1_FP8_ASM(rd, rs1, rs2)      KTCU_HMMA_R_ASM(0x1, 0x00, rd, rs1, rs2)
#define HMMA_1_FP16_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x1, 0x01, rd, rs1, rs2)
#define HMMA_1_FP32_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x1, 0x02, rd, rs1, rs2)
#define HMMA_1_POSIT8_ASM(rd, rs1, rs2)   KTCU_HMMA_R_ASM(0x1, 0x04, rd, rs1, rs2)
#define HMMA_1_POSIT16_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x1, 0x05, rd, rs1, rs2)
#define HMMA_1_POSIT32_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x1, 0x06, rd, rs1, rs2)
#define HMMA_1_INT8_ASM(rd, rs1, rs2)     KTCU_HMMA_R_ASM(0x1, 0x08, rd, rs1, rs2)
#define HMMA_1_INT16_ASM(rd, rs1, rs2)    KTCU_HMMA_R_ASM(0x1, 0x09, rd, rs1, rs2)
#define HMMA_1_FIXED8_ASM(rd, rs1, rs2)   KTCU_HMMA_R_ASM(0x1, 0x0C, rd, rs1, rs2)
#define HMMA_1_FIXED16_ASM(rd, rs1, rs2)  KTCU_HMMA_R_ASM(0x1, 0x0D, rd, rs1, rs2)

#endif