; CPU performance testbed based instrumenting vaxmans mandelbrot demo
; mandelbrot demo done by vaxman in 2015
; performance testbed done and used for CPU improvement by sy2002 in May 2016
; added instruction counter by sy2002 in July 2020
;
; ****************************************************************************
; 
; !!! All test results from V1.7 on are in doc/MIPS.md !!!
;
; ****************************************************************************
;
; Results on August, 18th 2020 (Vivado on Nexys 4 DDR):

; speed and cycle count comparison using VGA (after three runs due to cater
; for the effects of scrolling)
;
; 008C 7A95 = 9.206.421 cycles => 0,1841 sec
; 0026 4514 = 2.508.052 instructions => 3,67 cycles / instruction
;                                    => 13,62 MIPS
;
; ============================================================================
; Results on July, 13th 2020 (Vivado on MEGA65):
;
; speed and cycle count comparison using UART:
;
; 00FE 547F = 16.667.775 cycles = 0,3334 sec
; 0042 C59C =  4.375.964 instructions => 3,8089 cycles / instruction
;                                     => 13,13 MIPS
;
; speed and cycle count comparison using VGA:
;
; 0091 66D5 = 9.529.045 cycles = 0,1906 sec
; 0026 51C0 = 2.511.296 instructions => 3,7945 cycles / instruction
;                                    => 13,18 MIPS
;
; everything below this line has been done in 2016
; ============================================================================
; speed comparison using UART:
;
;  CPU revision GIT #f6ccada needs 0106 BDF3 = 17.219.059 cycles = 0,3444 sec
;
; speed comparison using VGA:
;
;  CPU revision GIT #f6ccada needs 009F 12AD = 10.425.005 cycles = 0,2085 sec
;
;
; everything below this line has been done and measured using the software
; implementation of muls, so these results are not comparable any more with
; the new results that have been generated using the hardware muls of the EAE
; ============================================================================
;
; speed comparison using UART:
;
;  CPU revision GIT #0a9e0b0 needs 0426 8EF9 = 69.635.833 cycles = 1,3927 sec
;  CPU revision GIT #0aeb48e needs 02F9 31C8 = 49.885.640 cycles = 0,9977 sec
;  CPU revision GIT #60f1294 needs 02D4 FA6C = 47.512.172 cycles = 0,9502 sec
;  CPU revision GIT #83e2936 needs 02D2 3BCF = 47.332.303 cycles = 0,9466 sec
;
; speed comparison using VGA:
;
;  CPU revision GIT #0a9e0b0 needs 0425 7A16 = 69.564.950 cycles = 1,3913 sec
;  CPU revision GIT #0aeb48e needs 02F4 3938 = 49.559.864 cycles = 0,9913 sec
;  CPU revision GIT #60f1294 needs 02CF 1666 = 47.126.118 cycles = 0,9425 sec
;  CPU revision GIT #83e2936 needs 02CC 0531 = 46.925.105 cycles = 0,9385 sec
;
;  using the instruction counter feature of the emulator we learned, that this
;  test program consists of 12.143.388 instructions, i.e. the FGA QNICE system
;  performs at an average of 3,86 cycles/instruction which leads to 
;  a system performance 12,93 MIPS.

                .ORG    0xA000

                MOVE    IO$CYC_STATE, R0    ; reset hw cycle counter
                MOVE    1, @R0
                MOVE    IO$INS_STATE, R0    ; reset hw instruction counter
                MOVE    1, @R0

#define         POINTER R12

#include "../dist_kit/sysdef.asm"
#include "../dist_kit/monitor.def"                

;
DIVERGENT       .EQU    0x0400              ; Constant for divergence test
X_START         .EQU    -0x0200             ; -512 = - 2 * scale with scale = 256
X_END           .EQU    0x0100              ; +128
X_STEP          .EQU    0x000B              ; was 0x0006 == 10
Y_START         .EQU    -0x0180             ; -256
Y_END           .EQU    0x0180              ; 256
Y_STEP          .EQU    0x0013              ; was 0x000F == 25
ITERATION       .EQU    0x001A              ; Number of iterations
;
; for (y = y_start; y <= y_end; y += y_step)
; {
                MOVE    Y_START, R0         ; R0 = y
OUTER_LOOP      CMP     Y_END, R0           ; End reached?
                RBRA    MANDEL_END, !V      ; Yes
;   for (x = x_start; x <= x_end; x += x_step)
;   {
                MOVE    X_START, R1         ; R1 = x
INNER_LOOP      CMP     X_END, R1           ; End reached?
                RBRA    INNER_LOOP_END, !V  ; Yes
;     z0 = z1 = 0;
                XOR     R2, R2
                XOR     R3, R3
;     for (i = i_max; i; i--)
;     {
                MOVE    ITERATION, R6       ; i = i_max
;;;
ITERATION_LOOP  MOVE R3, R8                 ; Compute z1 ** 2 for z2 = (z0 * z0 - z1 * z1) / 256
                MOVE R3, R9
                SYSCALL(muls, 1)
;
                MOVE    Z1SQUARE_LOW, POINTER
                MOVE    R10, @POINTER       ; Remember the result for later
                MOVE    Z1SQUARE_HIGH, POINTER
                MOVE    R11, @POINTER
;
                MOVE    R2, R8              ; Compute z0 * z0
                MOVE    R2, R9
                SYSCALL(muls, 1)
;
                MOVE    Z0SQUARE_LOW, POINTER
                MOVE    R10, @POINTER       ; Remember the result for later
                MOVE    Z0SQUARE_HIGH, POINTER
                MOVE    R11, @POINTER
;
                MOVE    Z1SQUARE_LOW, POINTER
                MOVE    @POINTER, R8
                MOVE    Z1SQUARE_HIGH, POINTER
                MOVE    @POINTER, R9
                SUB     R8, R10             ; First step of subtraction
                SUBC    R9, R11 ; Subtract high word
; R11/R10 now contains z0 ** 2 - z1 ** 2, next step is division by 256:
                SWAP    R10, R10
                AND     0x00FF, R10
                SWAP    R11, R11
                AND     0xFF00, R11
                OR      R11, R10
                MOVE    R10, R4             ; R4 now contains z2
;       z3 = 2 * z0 * z1 / 256
                MOVE    R2, R8
                ADD     R2, R8              ; R8 = 2 * z0
                MOVE    R3, R9
                SYSCALL(muls, 1)          ; R11|R10 = 2 * R2 * R3
                SWAP    R10, R10
                AND     0x00FF, R10
                SWAP    R11, R11
                AND     0xFF00, R11
                OR      R11, R10
                MOVE    R10, R5             ; R5 now contains z3
;       z1 = z3 + y
                MOVE    R5, R3
                ADD     R0, R3
;       z0 = z2 + x
                MOVE    R4, R2
                ADD     R1, R2
;       if (z0 * z0 / 256 + z1 * z1 / 256 > DIVERGENT)
; Implemented as (z0 ** 2 + z1 ** 2) / 256
                MOVE    Z0SQUARE_LOW, POINTER
                MOVE    @POINTER, R8
                MOVE    Z0SQUARE_HIGH, POINTER
                MOVE    @POINTER, R9
                MOVE    Z1SQUARE_LOW, POINTER
                MOVE    @POINTER, R10
                MOVE    Z1SQUARE_HIGH, POINTER
                MOVE    @POINTER, R11
                ADD     R10, R8
                ADDC    R11, R9
                SWAP    R8, R8
                AND     0x00FF, R8
                SWAP    R9, R9
                AND     0xFF00, R9
                OR      R9, R8              ; R8 now contains the left side of the comparison
                CMP     DIVERGENT, R8
;         break;
                RBRA    BREAK, !V           ; The sequence is diverging
;;;
                SUB     1, R6               ; i--
                RBRA    ITERATION_LOOP, !Z
;     }
;     printf("%c", display[iteration % 7]);
BREAK           MOVE    DISPLAY, R7
                AND     0x0007, R6
                ADD     R6, R7
                MOVE    @R7, R8
                SYSCALL(putc, 1)
                ADD     X_STEP, R1          ; x += x_step
                RBRA    INNER_LOOP, 1
;   }
;   printf("\n");
INNER_LOOP_END  SYSCALL(crlf, 1)
                ADD     Y_STEP, R0
                RBRA    OUTER_LOOP, 1
; }
MANDEL_END      SYSCALL(crlf, 1)

                ; output performance information

                MOVE    IO$CYC_STATE, R0
                MOVE    0, @R0              ; stop hw cycle counter
                MOVE    IO$INS_STATE, R0
                MOVE    0, @R0              ; stop hw instruction counter

                ; output cycle counter

                MOVE    PERF_STR, R8
                SYSCALL(puts, 1)            ; output info string
                MOVE    IO$CYC_HI, R1
                MOVE    @R1, R8 
                SYSCALL(puthex, 1)          ; output hi word of 48bit counter
                MOVE    SPACE_STR, R8
                SYSCALL(puts, 1)
                MOVE    IO$CYC_MID, R1
                MOVE    @R1, R8                 
                SYSCALL(puthex, 1)          ; output mid word of 48bit counter
                MOVE    SPACE_STR, R8
                SYSCALL(puts, 1)                
                MOVE    IO$CYC_LO, R1
                MOVE    @R1, R8 
                SYSCALL(puthex, 1)          ; output lo word of 48bit counter
                SYSCALL(crlf, 1)

                ; output instruction counter

                MOVE    INS_STR, R8
                SYSCALL(puts, 1)            ; output info string
                MOVE    IO$INS_HI, R1
                MOVE    @R1, R8 
                SYSCALL(puthex, 1)          ; output hi word of 48bit counter
                MOVE    SPACE_STR, R8
                SYSCALL(puts, 1)
                MOVE    IO$INS_MID, R1
                MOVE    @R1, R8                 
                SYSCALL(puthex, 1)          ; output mid word of 48bit counter
                MOVE    SPACE_STR, R8
                SYSCALL(puts, 1)                
                MOVE    IO$INS_LO, R1
                MOVE    @R1, R8 
                SYSCALL(puthex, 1)          ; output lo word of 48bit counter

                SYSCALL(exit, 1)

DISPLAY         .ASCII_P    " .-+*=#*"      ; Characters for the display
Z0SQUARE_LOW    .BLOCK      1
Z0SQUARE_HIGH   .BLOCK      1
Z1SQUARE_LOW    .BLOCK      1
Z1SQUARE_HIGH   .BLOCK      1

PERF_STR        .ASCII_W    "Overall clock cycles: "
INS_STR         .ASCII_W    "Overall instructions: "
SPACE_STR       .ASCII_W    " "
