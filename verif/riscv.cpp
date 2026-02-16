//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>  // int32_t, int64_t
#include "svdpi.h"   // SystemVerilog DPI

// Macro definitions
#define XLEN (32)    // Base RISC-V ISA (32, 64)
#define NPOS (1024)  // Number of memory positions for program and data memory models

// Datatype: data width
#if (XLEN == 64)
    typedef int64_t xlen_t;
#else
    typedef int32_t xlen_t;
#endif

// Datatype: instruction width (32 bits, standard)
typedef int32_t ilen_t;

// External memories
xlen_t pmem[NPOS] = {0};
xlen_t dmem[NPOS] = {0};

// Architectural state
xlen_t pc = 0;
xlen_t rf[32] = {0};

// DPI function to load program memory
extern "C" void rvm_load_bin(const char *filename) {
    // Local variables
    FILE *f;
    unsigned int idx;

    // Open file (read mode)
    f = fopen(filename, "r");

    // Read elements
    idx = 0;
    while ((fscanf(f, "%08x\n", &pmem[idx]) != EOF) && (++idx < NPOS)) ;

    // Close file
    fclose(f);

    // Show debug info
    printf("[TESTBENCH] (DPI-C) Successfully loaded RISC-V binary %s (%d instructions)\n", filename, idx);
}

// DPI function to reset processor
extern "C" void rvm_reset() {
    // Reset architectural state
    pc = 0;
    for (int i = 0; i < 32; i++) rf[i] = 0;
}

// DPI function to emulate one instruction step
extern "C" void rvm_step(svLogicVecVal *pc_o, svLogicVecVal *rf_o) {
    // Local variables
    ilen_t instr;
    xlen_t pc_next;

    // Instruction fields
    xlen_t opcode;
    xlen_t funct3;
    xlen_t funct7;
    xlen_t rs1;
    xlen_t rs2;
    xlen_t rd;

    // Sign-extended immediates
    xlen_t imm_ext_i;
    xlen_t imm_ext_s;
    xlen_t imm_ext_b;
    xlen_t imm_ext_j;
    xlen_t imm_ext_u;

    //
    // Stage #1: Instruction Fetch
    //

    // Read next instruction from program memory
    instr = pmem[pc >> 2];

    //
    // Stage #2: Instruction Decode / Register Read
    //

    // Extract instruction fields
    opcode = (instr >>  0) & (0x7f);  // opcode = instr[6:0]
    funct3 = (instr >> 12) & ( 0x7);  // funct3 = instr[14:12]
    funct7 = (instr >> 25) & (0x7f);  // funct7 = instr[31:25]
    rs1    = (instr >> 15) & (0x1f);  // rs1    = instr[19:15]
    rs2    = (instr >> 20) & (0x1f);  // rs2    = instr[24:20]
    rd     = (instr >>  7) & (0x1f);  // rd     = instr[11:7]

    // I-type sign-extended immediate
    imm_ext_i = (instr >> 20) & (0xfff);
    imm_ext_i |= (imm_ext_i & 0x800) ? 0xfffff000 : 0x00000000;

    // S-type sign-extended immediate
    imm_ext_s = ((instr >> 7) & 0x1f) | (((instr >> 25) & 0x7f) << 5);
    imm_ext_s |= (imm_ext_s & 0x800) ? 0xfffff000 : 0x00000000;

    // B-type sign-extended immediate
    imm_ext_b = (((instr >> 8) & 0xf) << 1) | (((instr >> 25) & 0x3f) << 5) | (((instr >> 7) & 0x1) << 11) | (((instr >> 31) & 0x1) << 12);
    imm_ext_b |= (imm_ext_b & 0x1000) ? 0xffffe000 : 0x00000000;

    // J-type sign-extended immediate
    imm_ext_j = (((instr >> 21) & 0x3ff) << 1) | (((instr >> 20) & 0x1) << 11) | (((instr >> 12) & 0xff) << 12) | (((instr >> 31) & 0x1) << 20);
    imm_ext_j |= (imm_ext_j & 0x80000) ? 0xfff00000 : 0x00000000;

    // U-type immediate
    imm_ext_u = instr & 0xfffff000;

    //
    // Stage #3: Execute / Address Calculation
    // Stage #4: Data Memory Access
    //

    // Set default PC value for next cycle
    pc_next = pc + 4;

    // Decode opcode
    switch (opcode) {
        // lw
        case 3:
            printf("[TESTBENCH] (DPI-C) lw   : x%d <- dmem[x%d%+d]\n", rd, rs1, imm_ext_i);
            rf[rd] = dmem[(rf[rs1] + imm_ext_i) >> 2];
            break;
        // I-type ALU
        case 19:
            switch (funct3) {
                // addi
                case 0:
                    printf("[TESTBENCH] (DPI-C) addi : x%d <- x%d + %d\n", rd, rs1, imm_ext_i);
                    rf[rd] = rf[rs1] + imm_ext_i;
                    break;
                // slti
                case 2:
                    printf("[TESTBENCH] (DPI-C) slti : x%d <- (x%d < %d) ? 1 : 0\n", rd, rs1, imm_ext_i);
                    rf[rd] = (rf[rs1] < imm_ext_i) ? 1 : 0;
                    break;
                // xori
                case 4:
                    printf("[TESTBENCH] (DPI-C) xori : x%d <- x%d ^ %d\n", rd, rs1, imm_ext_i);
                    rf[rd] = rf[rs1] ^ imm_ext_i;
                    break;
                // ori
                case 6:
                    printf("[TESTBENCH] (DPI-C) ori  : x%d <- x%d | %d\n", rd, rs1, imm_ext_i);
                    rf[rd] = rf[rs1] | imm_ext_i;
                    break;
                // andi
                case 7:
                    printf("[TESTBENCH] (DPI-C) andi : x%d <- x%d & %d\n", rd, rs1, imm_ext_i);
                    rf[rd] = rf[rs1] & imm_ext_i;
                    break;
                // Illegal operation
                default:
                    printf("[TESTBENCH] (DPI-C) illegal funct3 (%02x)\n", funct3);
            }
            break;
        // sw
        case 35:
            printf("[TESTBENCH] (DPI-C) sw   : dmem[x%d%+d] <- x%d\n", rs1, imm_ext_s, rs2);
            dmem[(rf[rs1] + imm_ext_s) >> 2] = rf[rs2];
            break;
        // R-type ALU
        case 51:
            switch (funct3) {
                // add/sub
                case 0:
                    // sub
                    if (funct7) {
                        printf("[TESTBENCH] (DPI-C) sub  : x%d <- x%d - x%d\n", rd, rs1, rs2);
                        rf[rd] = rf[rs1] - rf[rs2];
                    // add
                    } else {
                        printf("[TESTBENCH] (DPI-C) add  : x%d <- x%d + x%d\n", rd, rs1, rs2);
                        rf[rd] = rf[rs1] + rf[rs2];
                    }
                    break;
                // slt
                case 2:
                printf("[TESTBENCH] (DPI-C) slt  : x%d <- (x%d < x%d) ? 1 : 0\n", rd, rs1, rs2);
                    rf[rd] = (rf[rs1] < rf[rs2]) ? 1 : 0;
                    break;
                // xor
                case 4:
                    printf("[TESTBENCH] (DPI-C) xor  : x%d <- x%d ^ x%d\n", rd, rs1, rs2);
                    rf[rd] = rf[rs1] ^ rf[rs2];
                    break;
                // or
                case 6:
                    printf("[TESTBENCH] (DPI-C) or   : x%d <- x%d | x%d\n", rd, rs1, rs2);
                    rf[rd] = rf[rs1] | rf[rs2];
                    break;
                // and:
                case 7:
                    printf("[TESTBENCH] (DPI-C) and  : x%d <- x%d & x%d\n", rd, rs1, rs2);
                    rf[rd] = rf[rs1] & rf[rs2];
                    break;
                // Illegal operation
                default:
                    printf("[TESTBENCH] (DPI-C) illegal funct3 (%02x)\n", funct3);
            }
            break;
        // lui
        case 55:
            printf("[TESTBENCH] (DPI-C) lui  : x%d <- %05x\n", rd, imm_ext_u);
            rf[rd] = imm_ext_u;
            break;
        // beq
        case 99:
            printf("[TESTBENCH] (DPI-C) beq  : PC = (x%d == x%d) ? PC%+d : PC+4\n", rs1, rs2, imm_ext_b);
            if (rf[rs1] == rf[rs2]) {
                pc_next = pc + imm_ext_b;
            }
            break;
        // jal
        case 111:
            printf("[TESTBENCH] (DPI-C) jal  : PC = PC%+d, x%d = PC+4 \n", imm_ext_j, rd);
            rf[rd] = pc + 4;
            pc_next = pc + imm_ext_j;
            break;
        // Illegal instruction
        default:
            printf("[TESTBENCH] (DPI-C) illegal opcode (%02x)\n", opcode);
    }

    // Ensure x0 is always 0
    rf[0] = 0;

    //
    // Stage #5: Update PC
    //

    // Update program counter
    pc = pc_next;

    // Return architectural state
    pc_o->aval = pc;
    for (int i = 0; i < 32; i++) rf_o[i].aval = rf[i];
}
