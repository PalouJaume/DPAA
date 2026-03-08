# addi tests
main:   addi x2, x0, 5          # x2 = 5                        0         00500113
        addi x3, x0, 12         # x3 = 12                       4         00C00193
        addi x7, x3, -9         # x7 = (12 - 9) = 3             8         FF718393
# or / ori tests 
        or   x4, x7, x2         # x4 = (3 OR 5) = 7             C         0023E233
        ori  x8, x7, 0x10       # x8 = (3 OR 16) = 19           10        0103E413
# and / andi tests 
        and  x5, x3, x4         # x5 = (12 AND 7) = 4           14        0041F2B3
        andi x9, x3, 0x07       # x9 = (12 AND 7) = 4           18        0071F493
# xor / xori tests 
        xor  x10, x3, x4        # x10 = (12 XOR 7) = 11         1C        0041C533
        xori x11, x3, 0x07      # x11 = (12 XOR 7) = 11         20        0071C593
# add / sub tests 
        add  x5, x5, x4         # x5 = (4 + 7) = 11             24        004282B3
        sub  x6, x3, x2         # x6 = (12 - 5) = 7             28        40218333
# slt / slti tests
        slt  x12, x2, x3        # x12 = (5 < 12) = 1            2C        0031A633
        slt  x13, x3, x2        # x13 = (12 < 5) = 0            30        0021B6B3
        slti x14, x2, 10        # x14 = (5 < 10) = 1            34        00A12713
        slti x15, x2, 3         # x15 = (5 < 3) = 0             38        00312793
# beq test (not taken)
        beq  x5, x7, end        # shouldn't be taken            3C        02728C63
# beq test (taken)
        beq  x13, x0, around    # should be taken (0 == 0)      40        00068463
        addi x5, x0, 0          # shouldn't happen              44        00000293
# lui test 
around: lui  x16, 0x12345       # x16 = 0x12345000              48        12345837
        lui  x17, 1             # x17 = 0x00001000              4C        000018B7
# sw / lw tests 
        sw   x7, 84(x3)         # mem[96] = 3                   50        0471AA23
        lw   x18, 96(x0)        # x18 = mem[96] = 3             54        06002903
        add  x19, x18, x5       # x19 = (3 + 11) = 14           58        005909B3
# jal test
        jal  x20, end           # jump to end, x20 = 0x60       5C        008001EF
        addi x2, x0, 99         # shouldn't happen              60        06300113
# final operations 
end:    add  x2, x2, x19        # x2 = (5 + 14) = 19            64        01310133
        sw   x2, 0x20(x3)       # mem[44] = 19                  68        0221A023
# infinite loop 
done:   beq  x0, x0, done       # infinite loop                 6C        00000063
