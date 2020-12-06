; TileEd is the ultimate "text mode sprite" (aka "tile") editor
;
; It was originally developed as a tool to develop "qtris.asm".
;
; Uses VGA to display all 256 characters of the font (based on font.asm) on
; the left side of the screen. On the right side of the screen, there is a
; box of the size TILE_DX_INIT and TILE_DY_INIT (size can be changed during
; runtime using F3 on the PS2/USB keyboard).
;
; Using F1 on the USB keyboard, you can jump between the character palette
; and the tile and using SPACE on the USB keyboard, you can "paint" characters
; into the tile box.
;
; You can also work in multicolor and edit the font itself using F7 and
; edit the palette using F9.
;
; Use F12 to enter the load/save/quit menu: Your work is being saved as an
; ASCII stream of .DW and .EQU statements separated by comments to make the
; output more readable. Save the output to a textfile so that you can load
; it again to TileEd using your terminal program. Additionally, the output is
; meant to be directly copy/pasted or included into QNICE assembler code.
;
; TileEd ignores STDIN and STDOUT settings of the monitor: The load/save data
; always goes to the UART and the other input/ouput is done via keyboard/VGA.
; This is also why the standard IO monitor functions such as "getc", "putc",
; "puts", etc. cannot be used inside this program and are replaced by local
; versions.
;
; done by sy2002 in January 2016
; enhanced by sy2002 in September to December 2020 to support character
; editing for font graphics and palette editing and color

#include "../dist_kit/sysdef.asm"
#include "../dist_kit/monitor.def"

                ; "external" interface, i.e. change TILE_DX and TILE_DY to
                ; your needs, recompile and run: TileEd                
TILE_DX_INIT    .EQU 10
TILE_DY_INIT    .EQU 10

                ; "internal" .EQUs, i.e. these are not meant to be changed
START_X         .EQU 2
START_Y         .EQU 5
TILE_CENTER_X   .EQU 57
TILE_CENTER_Y   .EQU 20
TILE_DX_MAX     .EQU 43                         ; if this is changed, then ...
TILE_DY_MAX     .EQU 36                         ; change STR_CHG_SIZE_*, too
SELECTED_X      .EQU 10
SELECTED_Y      .EQU 37

CHR_DRAW_1      .EQU 0x0010                     ; font editing char
CHR_DRAW_0      .EQU 0x0020
CHAR_ED_X       .EQU 12                         ; start coords. char ed. win.
CHAR_ED_Y       .EQU 2

CHR_PAL_F       .EQU 0x0011                     ; foregr. col. pal. disp. char
CHR_PAL_B       .EQU 0x0020                     ; backgr. col. pal. disp. char
CHR_PAL_SEL_F   .EQU 'a'                        ; foreground col selector
CHR_PAL_SEL_B   .EQU 'A'                        ; background col selector
PAL_ED_X        .EQU 2
PAL_ED_Y        .EQU 17

RED_MASK        .EQU 0x7C00                     ; 15-bit RGB mask for R
RED_ONE         .EQU 0x0400                     ; RED + 1
RED_ONE_C       .EQU 0xFC00                     ; RED - 1 (2-complement of +1)
GREEN_MASK      .EQU 0x03E0                     ; 15-bit RGB mask for G
GREEN_ONE       .EQU 0x0020                     ; GREEN + 1
GREEN_ONE_C     .EQU 0xFFE0                     ; GREEN - 1
BLUE_MASK       .EQU 0x001F                     ; 15-bit RGB mask for B
BLUE_ONE        .EQU 0x0001                     ; BLUE + 1
BLUE_ONE_C      .EQU 0xFFFF                     ; BLUE - 1

                .ORG 0x8000

                ; check external interface "variables" TILE_DX_INIT and
                ; TILE_DY_INIT to fit into the boundaries
                MOVE    TILE_DX_MAX, R0
                CMP     TILE_DX_INIT, R0
                RBRA    TILE_ED_HALT, N
                MOVE    TILE_DY_MAX, R0
                CMP     TILE_DY_INIT, R0
                RBRA    TILE_ED_HALT, N
                RBRA    TILE_ED_START, 1
TILE_ED_HALT    MOVE    STR_NOSTART, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

                ; move initial tile size to the global variables storing them
TILE_ED_START   MOVE    TILE_DX, R0
                MOVE    TILE_DX_INIT, @R0
                MOVE    TILE_DY, R0
                MOVE    TILE_DY_INIT, @R0

                ; copy font and palette to RAM and activate the RAM
                MOVE    1, R8
                SYSCALL(vga_copyfont, 1)
                SYSCALL(vga_copypal, 1)

                ; clear the foreground/background color LRU buffer
                MOVE    LRU_FGBG, R0
                MOVE    256, R1
LRU_INIT_LOOP   MOVE    0, @R0++
                SUB     1, R1
                RBRA    LRU_INIT_LOOP, !Z

                MOVE    FONT_MODE, R0
                MOVE    0, @R0

                ; fill the clipboard with the bitpattern of character 0
                MOVE    SELECTED_CHR, R8
                MOVE    0, @R8
                MOVE    KBD$CTRL_C, R8
                OR      0xFF00, R8              ; flag that COPYPASTE shall..
                RSUB    COPYPASTE, 1            ; ..act like a sub routine

                ; font ed cursor positions
                MOVE    FONT_ED_CX, R0
                MOVE    CHAR_ED_X, @R0
                ADD     1, @R0
                MOVE    FONT_ED_CY, R0
                MOVE    CHAR_ED_Y, @R0
                ADD     1, @R0

                ; set up the screen and calculate the *_WS_* variables
TILE_ED_RESET   SYSCALL(vga_cls, 1)             ; clear screen
                RSUB    DRAW_PALETTE, 1         ; character palette
                MOVE    0, R8                   ; R8=0: default workspace
                RSUB    DRAW_WORKSPACE, 1       ; the rest of the workspace

                ; global registers
TILE_ED_KEEP    MOVE    VGA$CR_X, R0            ; R0: hw cursor X
                MOVE    VGA$CR_Y, R1            ; R1: hw cursor Y
                MOVE    VGA$CHAR, R2            ; R2: print at hw cursor pos
                XOR     R3, R3                  ; R3: mode: 0=palette 1=tile
                MOVE    PAL_WS_X, R8
                MOVE    @R8, R4                 ; R4: palette x pos
                MOVE    PAL_WS_Y, R8
                MOVE    @R8, R5                 ; R5: palette y pos
                MOVE    TILE_WS_X, R8
                MOVE    @R8, R6                 ; R6: tile x pos
                MOVE    TILE_WS_Y, R8
                MOVE    @R8, R7                 ; R7: tile y pos

                ; set cursor depending on mode
MAIN_LOOP       CMP     0, R3                   ; 0=palette mode       
                RBRA    CRS_MODE_0, Z
                MOVE    R6, @R0                 ; 1=tile mode
                MOVE    R7, @R1
                RBRA    WAIT_FOR_KEY, 1

                ; we are in palette mode, that means guaranteed to be not
                ; in fonted mode, so store the selected char in SELECTED_CHR
                ; and print it at the bottom of the screen
CRS_MODE_0      MOVE    R4, @R0                 ; cursor to recently selected
                MOVE    R5, @R1
                MOVE    SELECTED_CHR, R8
                MOVE    @R2, @R8                ; store recently selected
                MOVE    SELECTED_X, @R0
                MOVE    SELECTED_Y, @R1
                MOVE    @R8, @R2                ; print recently selected
                MOVE    R4, @R0                 ; cursor back to selection
                MOVE    R5, @R1

                ; keyboard handler
WAIT_FOR_KEY    RSUB    KBD_GETCHAR, 1

                ; support fg/bg color selection using `a` to `q` and
                ; `A` to `Q` in case of active font ed mode
                MOVE    FONT_MODE, R11          
                MOVE    @R11, R11               ; if FONT_MODE = 0, then ..
                RBRA    CHECK_KEYS, Z           ; .. no font ed mode active
                MOVE    TILE_DX, R11            ; save TILE_DX and TILE_DY
                MOVE    @R11, @--SP
                MOVE    TILE_DY, R11
                MOVE    @R11, @--SP
                RSUB    _FONTED_FGBG, 1         ; changes TILE_DX and TILE_DY
                MOVE    TILE_DY, R11
                MOVE    @SP++, @R11             ; restore TILE_DX and TILE_DY
                MOVE    TILE_DX, R11
                MOVE    @SP++, @R11
                RBRA    MAIN_LOOP, C            ; fg or bg was changed

                ; ignore keys that are not allowed in font ed mode
                CMP     KBD$F3, R8
                RBRA    WAIT_FOR_KEY, Z
                CMP     KBD$F9, R8
                RBRA    WAIT_FOR_KEY, Z
                CMP     KBD$F12, R8
                RBRA    WAIT_FOR_KEY, Z

CHECK_KEYS      CMP     KBD$F1, R8              ; F1 = toggle sprite mode
                RBRA    SWITCH_MODE, Z
                CMP     KBD$F3, R8              ; F3 = change size (and clear)
                RBRA    CHANGE_SIZE, Z
                CMP     KBD$F5, R8              ; F5 = clear
                RBRA    CLEAR, Z
                CMP     KBD$F9, R8              ; F9 = palette editor
                RBRA    PAL_ED, Z
                CMP     KBD$F7, R8              ; F7 = toggle font mode
                RBRA    _WFK_CHK_F12, !Z
                MOVE    FONT_MODE, R11          ; are we already in font mode?
                CMP     0, @R11
                RBRA    _WFK_FONTED, Z          ; no: so switch to font mode!

                MOVE    0, @R11                 ; reset back to normal mode
                MOVE    STR_HELP_MAIN, R8
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1
                RSUB    _FONTED_CLR, 1
                RSUB    DRAW_PALETTE, 1
                RBRA    MAIN_LOOP, 1

_WFK_FONTED     RSUB    FONT_ED, 1              ; switch to font editor
                MOVE    R8, R3                  ; remember mode
                CMP     1, R3                   ; sprite mode?
                RBRA    MAIN_LOOP, Z
                RSUB    DRAW_PALETTE, 1         ; character palette
                MOVE    0, R8                   ; R8=0: default workspace
                RSUB    DRAW_WORKSPACE, 1       ; the rest of the workspace                
                RBRA    MAIN_LOOP, 1
_WFK_CHK_F12    CMP     KBD$F12, R8             ; F12 = load/save/quit
                RBRA    FILE_MENU, Z
                CMP     KBD$SPACE, R8           ; SPACE = draw character
                RBRA    DRAW_CHAR, Z
                CMP     KBD$CTRL_C, R8          ; CTRL+C: COPY
                RBRA    COPYPASTE, Z
                CMP     KBD$CTRL_V, R8          ; CTRL+V: PASTE
                RBRA    COPYPASTE, Z                               
                CMP     0, R3                   ; mode = palette?
                RBRA    NAV_PAL, Z              ; yes: navigate palette
                CMP     KBD$CUR_UP, R8          ; no: tile: up
                RBRA    NAV_TILE_U, Z
                CMP     KBD$CUR_DOWN, R8        ; tile: cursor down
                RBRA    NAV_TILE_D, Z
                CMP     KBD$CUR_LEFT, R8        ; tile: cursor left
                RBRA    NAV_TILE_L, Z
                CMP     KBD$CUR_RIGHT, R8       ; tile: cursor right
                RBRA    NAV_TILE_R, Z
                CMP     KBD$HOME, R8            ; tile: home = top left
                RBRA    NAV_TILE_H, Z
                CMP     KBD$END, R8             ; tile: end = bottom right
                RBRA    NAV_TILE_E, Z
                RBRA    WAIT_FOR_KEY, 1

NAV_PAL         CMP     KBD$CUR_UP, R8          ; palette: cursor up
                RBRA    NAV_PAL_U, Z
                CMP     KBD$CUR_DOWN, R8        ; palette: cursor down
                RBRA    NAV_PAL_D, Z
                CMP     KBD$CUR_LEFT, R8        ; palette: cursor left
                RBRA    NAV_PAL_L, Z
                CMP     KBD$CUR_RIGHT, R8       ; palette: cursor right
                RBRA    NAV_PAL_R, Z
                CMP     KBD$HOME, R8            ; palette: home = top left
                RBRA    NAV_PAL_H, Z
                CMP     KBD$END, R8             ; palette: end = bottom right
                RBRA    NAV_PAL_E, Z
                RBRA    WAIT_FOR_KEY, 1

                ; palette navigation: up
NAV_PAL_U       MOVE    PAL_WS_Y, R8
                CMP     R5, @R8                 ; y-pos already at minimum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore keypress
                SUB     2, R5                   ; no: one step up
                RBRA    MAIN_LOOP, 1

                ; palette navigation: down
NAV_PAL_D       MOVE    PAL_WS_Y_MAX, R8
                CMP     R5, @R8                 ; y-pos already at maximum?        
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore keypress
                ADD     2, R5                   ; no: one step down
                RBRA    MAIN_LOOP, 1

                ; palette navigation: left
NAV_PAL_L       MOVE    PAL_WS_X, R8
                CMP     R4, @R8                 ; x-pos already at minimum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore keypress
                SUB     2, R4                   ; no: one step to the left    
                RBRA    MAIN_LOOP, 1

                ; palette navigation: right
NAV_PAL_R       MOVE    PAL_WS_X_MAX, R8        
                CMP     R4, @R8                 ; x-pos already at maximum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore keypress
                ADD     2, R4                   ; no: one step to the right
                RBRA    MAIN_LOOP, 1

                ; palette navigation: home
NAV_PAL_H       MOVE    PAL_WS_X, R8            ; top left position
                MOVE    @R8, R4
                MOVE    PAL_WS_Y, R8
                MOVE    @R8, R5
                RBRA    MAIN_LOOP, 1

                ; palette navigation: end            
NAV_PAL_E       MOVE    PAL_WS_X_MAX, R8        ; bottom right position
                MOVE    @R8, R4
                MOVE    PAL_WS_Y_MAX, R8
                MOVE    @R8, R5
                RBRA    MAIN_LOOP, 1

                ; tile navigation: up
NAV_TILE_U      MOVE    TILE_WS_Y, R8
                CMP     @R8, R7                 ; y-pos already at minimum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore keypress
                SUB     1, R7                   ; no: one line up
                RBRA    MAIN_LOOP, 1

                ; tile navigation: down
NAV_TILE_D      MOVE    TILE_WS_Y_MAX, R8
                CMP     @R8, R7                 ; y-pos already at maximum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore the keypress
                ADD     1, R7                   ; no: one line down
                RBRA    MAIN_LOOP, 1

                ; tile navigation: left
NAV_TILE_L      MOVE    TILE_WS_X, R8
                CMP     @R8, R6                 ; x-pos already at minimum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore the keypress
                SUB     1, R6                   ; no: one column left                
                RBRA    MAIN_LOOP, 1

                ; tile navigation: right
NAV_TILE_R      MOVE    TILE_WS_X_MAX, R8
                CMP     @R8, R6                 ; x-pos already at maximum?
                RBRA    WAIT_FOR_KEY, Z         ; yes: ignore the keypress
                ADD     1, R6                   ; no: one column right
                RBRA    MAIN_LOOP, 1

                ; tile navigation: home
NAV_TILE_H      MOVE    TILE_WS_X, R8           ; top left position
                MOVE    @R8, R6
                MOVE    TILE_WS_Y, R8
                MOVE    @R8, R7
                RBRA    MAIN_LOOP, 1

                ; tile navigation: end
NAV_TILE_E      MOVE    TILE_WS_X_MAX, R8       ; bottom right position
                MOVE    @R8, R6
                MOVE    TILE_WS_Y_MAX, R8
                MOVE    @R8, R7
                RBRA    MAIN_LOOP, 1

                ; switch mode between palette and tile
SWITCH_MODE     XOR     1, R3
                MOVE    FONT_MODE, R8           ; running inside font ed?
                MOVE    @R8, R8                
                RBRA    MAIN_LOOP, Z            ; no: standard mode
                RBRA    _WFK_FONTED, 1          ; yes: back to fond ed

                ; draw the currently active character of the palette
                ; (aka "SELECTED") to the current cursor position within
                ; the tile window
DRAW_CHAR       MOVE    R6, @R0
                MOVE    R7, @R1
                MOVE    SELECTED_CHR, R8
                MOVE    @R8, R8
                CMP     R8, @R2                 ; same char already there?
                RBRA    _DRAW_CHAR_N, !Z        ; no: overwrite with new char
                MOVE    ' ', @R2                ; yes: delete existing char
                RBRA    MAIN_LOOP, 1
_DRAW_CHAR_N    MOVE    R8, @R2                 ; print the character
                RBRA    MAIN_LOOP, 1

                ; copy currently selected char font bit pattern to clipboard
COPYPASTE       INCRB
                MOVE    R8, R0                  ; R0 = copy or paste
                AND     0x00FF, R0              ; strip RET flag from R0
                MOVE    R8, R1 
                AND     0xFF00, R1              ; if R1 = 0xFF00 then use RET
                MOVE    SELECTED_CHR, R8
                MOVE    @R8, R8
                AND     0x00FF, R8              ; strip color information
                MOVE    12, R9                  ; height of a char: 12
                SYSCALL(mulu, 1)                ; R10 = R8 * 12
                ADD     VGA$FONT_OFFS_USER, R10 ; R10 = bitpattern address
                XOR     R8, R8
                MOVE    VGA$FONT_ADDR, R9
                MOVE    VGA$FONT_DATA, R11
                MOVE    CLIPBOARD, R12
COPYPASTE_LOOP  MOVE    R10, @R9                ; R10 = bitpattern address
                CMP     KBD$CTRL_C, R0          ; copy?
                RBRA    COPYPASTE_PASTE, !Z
                MOVE    @R11, @R12++            ; bitpattern data to clipboard
                RBRA    COPYPASTE_CONT, 1
COPYPASTE_PASTE MOVE    @R12++, @R11            ; clipboard to bitpattern data                
COPYPASTE_CONT  ADD     1, R10
                ADD     1, R8
                CMP     12, R8                  ; height of a char: 12
                RBRA    COPYPASTE_LOOP, !Z
                MOVE    R1, R8
                DECRB
                CMP     0xFF00, R8
                RBRA    COPYPASTE_RBRA, !Z
                RET
COPYPASTE_RBRA  RBRA    MAIN_LOOP, 1

                ; clear tile
CLEAR           MOVE    TILE_WS_X_MAX, R9
                MOVE    TILE_WS_Y_MAX, R10
                MOVE    TILE_WS_Y, R8
                MOVE    @R8, @R1
_CLEAR_NEXT_Y   MOVE    TILE_WS_X, R8
                MOVE    @R8, @R0
_CLEAR_NEXT_X   MOVE    KBD$SPACE, @R2
                ADD     1, @R0
                CMP     @R0, @R9
                RBRA    _CLEAR_NEXT_X, !N
                ADD     1, @R1
                CMP     @R1, @R10
                RBRA    _CLEAR_NEXT_Y, !N
                RBRA    MAIN_LOOP, 1

                ; change the size of the tile editor
                ; the user can enter two new values or press ESC to stick
                ; to the old values (in the latter case: no reset is
                ; performed and the work is preserved)
CHANGE_SIZE     MOVE    39, R10                 ; y-pos = last line of screen              
                MOVE    0, R9                   ; x-pos = first column
                MOVE    STR_CLR_LINE, R8        ; clear last line
                RSUB    PRINT_STR_AT, 1
                MOVE    STR_CHG_SIZE_X, R8      ; print change dx message
                RSUB    PRINT_STR_AT, 1
                MOVE    R11, R9                 ; x-pos = behind the message
                MOVE    TILE_DX, R12            ; default val. for ESC...
                MOVE    @R12, R8                ; ...is set to to TILE_DX
                RSUB    KBD_GET2DGN, 1          ; 2-digit number from keyboard

                MOVE    TILE_DX_MAX, R0
                CMP     R8, R0                  ; R8 <= TILE_DX_MAX?
                RBRA    _CS_CHECK_DX, !N        ; yes: continue checking
                RBRA    CHANGE_SIZE, 1          ; no: enter a new number
_CS_CHECK_DX    CMP     1, R8                   ; R8 >= 1
                RBRA    CHANGE_SIZE, N          ; no: enter a new number
                MOVE    R8, R1                  ; R1: remember new TILE_DX

_CS_ENTER_DY    MOVE    39, R10                 ; mult did destroy R10
                MOVE    0, R9
                MOVE    STR_CLR_LINE, R8        ; clear last screen line
                RSUB    PRINT_STR_AT, 1
                MOVE    STR_CHG_SIZE_Y, R8      ; print change dy message
                RSUB    PRINT_STR_AT, 1
                MOVE    R11, R9
                MOVE    TILE_DY, R12            ; default val. for ESC...
                MOVE    @R12, R8                ; ...is set to TILE_DY
                RSUB    KBD_GET2DGN, 1          ; 2-digit number from keyboard

                MOVE    TILE_DY_MAX, R0         
                CMP     R8, R0                  ; R8 <= TILE_DY_MAX?
                RBRA    _CS_CHECK_DY, !N        ; yes: continue checking
                RBRA    _CS_ENTER_DY, 1         ; no: enter a new number
_CS_CHECK_DY    CMP     1, R8                   ; R8 >= 1
                RBRA    _CS_ENTER_DY, N         ; no: enter a new number
                MOVE    R8, R2                  ; R2: remember new TILE_DY

                MOVE    TILE_DX, R12
                CMP     @R12, R1                ; old TILE_DX = new TILE_DX?
                RBRA    _CS_ODX_NDX, Z          ; yes: continue checking
                RBRA    _CS_STORE_NEW, 1        ; no: store new values&reset
_CS_ODX_NDX     MOVE    TILE_DY, R12
                CMP     @R12, R2                ; old TILE_DY = new TILE_DY?
                RBRA    _CS_STORE_NEW, !Z       ; no: store new values&reset

                MOVE    0, R9                   ; yes: show help line...
                MOVE    39, R10
                MOVE    STR_CLR_LINE, R8
                RSUB    PRINT_STR_AT, 1
                MOVE    STR_HELP_MAIN, R8
                RSUB    PRINT_STR_AT, 1
                RBRA    TILE_ED_KEEP, 1         ; ...and preserve the work

_CS_STORE_NEW   MOVE    TILE_DX, R12
                MOVE    R1, @R12
                MOVE    TILE_DY, R12
                MOVE    R2, @R12                
                RBRA    TILE_ED_RESET, 1        ; reset TileEd with new DX, DY

                ; return to the system by clearing the screen and resetting
END             SYSCALL(vga_init, 1)            ; also activates default font
                SYSCALL(vga_cls, 1)                
                SYSCALL(exit, 1)

; ****************************************************************************
; Various string constants
; ****************************************************************************

STR_HELLO       .ASCII_W "TileEd - Textmode Sprite Editor  V2.0  by sy2002 in December 2020"
STR_NOSTART     .ASCII_W "Either TILE_DX or TILE_DY is larger than the allowed maximum. TileEd halted.\n"

STR_HELP_MAIN   .ASCII_P "F1: Sprite F3: Size F5: Clr F7: Font F9: Pal F12: File SPACE: Paint CRSR: Nav   `"
                .ASCII_W "XX         XX       XX      XX       XX      XXX       XXXXX        XXXX"
STR_HELP_FONT   .ASCII_P "F1: Char/Sprite F5: Clear F7: Back SPACE: Paint CRSR: Nav a..p & A..P: Color    `"
                .ASCII_W "XX              XX        XX       XXXXX        XXXX      X  X   X  X"
STR_HELP_PAL    .ASCII_P "1|2 Red 3|4 Green 5|6 Blue F1: 24-bit F3: 15-bit F5|F7|F9 R|G|B Values F11: Back`"
                .ASCII_W "X X     X X       X X      XX         XX         XX XX XX              XXX"
STR_HELP_EDIT   .ASCII_P "0..9 and a..f: Hexadecimal input ENTER: Change value ESC: Cancel                `"
                .ASCII_W "X  X     X  X                    XXXXX               XXX"
STR_CLR_LEFT    .ASCII_W "                                   "
STR_CLR_LINE    .ASCII_W "                                                                                "
STR_CHG_SIZE_X  .ASCII_W "Enter new width (1..43): "
STR_CHG_SIZE_Y  .ASCII_W "Enter new height (1..36): "
STR_CURCHAR     .ASCII_W "SELECTED:"
STR_FOREGROUND  .ASCII_W "Foreground color:"
STR_BACKGROUND  .ASCII_W "Background color:"
STR_PAL_FG      .ASCII_W "Palette for foreground colors:"
STR_PAL_BG      .ASCII_W "Palette for background colors:"
STR_PED_ACTIVE  .ASCII_W "Active palette entry: "
STR_RGB24       .ASCII_W "24-bit RGB: "
STR_RGB15       .ASCII_W "15-bit RGB: "
STR_RED         .ASCII_W "       Red: "
STR_GREEN       .ASCII_W "     Green: "
STR_BLUE        .ASCII_W "      Blue: "
STR_METER       .ASCII_W " [                ]"
STR_PED_EDIT    .ASCII_W "New value for "
STR_PED_RED     .ASCII_W "red: "
STR_PED_GREEN   .ASCII_W "green: "
STR_PED_BLUE    .ASCII_W "blue: "
STR_FILE_PRJ    .ASCII_W "Project description: "
STR_FILE_ELM    .ASCII_W "Element identifier: "
STR_FILE_ELMCMT .ASCII_W "Element comment: "

STR_LS_START0   .ASCII_W "; =======================================================================\n"
STR_LS_START1   .ASCII_W "; -----------------------------------------------------------------------\n"
STR_LS_START2   .ASCII_W "; DO NOT MODIFY! Autogenerated with TileEd V2.0\n"
STR_LS_CMT      .ASCII_W ";"
STR_LS_COLON    .ASCII_W ":"
STR_LS_COMMASPC .ASCII_W ", "
STR_LS_SPACE    .ASCII_W " "
STR_LS_SPACE2   .ASCII_W "  "
STR_LS_SPACE3   .ASCII_W "   "
STR_LS_NEWLINE  .ASCII_W "\n"
STR_LS_PAL      .ASCII_W "PALETTE"
LEN_LS_PAL_COL  .EQU 9                  ; length of STR_LS_PAL_LFN + 2
STR_LS_PAL_LFN  .ASCII_W "_PAL_FN"
STR_LS_PAL_LF   .ASCII_W "_PAL_F"
STR_LS_PAL_LBN  .ASCII_W "_PAL_BN"
STR_LS_PAL_LB   .ASCII_W "_PAL_B"
STR_LS_FONT     .ASCII_W "FONT"
STR_LS_FONT_LN  .ASCII_W "_FONT_N"
STR_LS_FONT_L   .ASCII_W "_FONT_"
STR_LS_TILE     .ASCII_W "TILE"
STR_LS_HEX_PREF .ASCII_W "0x"
STR_LS_EQU      .ASCII_W ".EQU "
STR_LS_DW       .ASCII_W ".DW "
STR_LS_E_ILLID  .ASCII_W "Illegal element identifier: Use [A..Z], [0..9], _ <Enter to continue>"

HEX_DIGITS      .ASCII_P "0123456789ABCDEF"

; ****************************************************************************
; FONT_ED
;    Main routine for color selection and font editing
;    Returns mode in R8: 0 = standard font palette, 1 = sprite editing
; ****************************************************************************

FONT_ED         INCRB
                MOVE    R9, R1
                MOVE    R10, R2
                MOVE    R11, R3
                MOVE    R12, R4
                MOVE    VGA$CR_X, R5
                MOVE    @R5, R5
                MOVE    VGA$CR_Y, R6
                MOVE    @R6, R6

                ; save the dimensions of the sprite, because we are reusing
                ; the workspace drawing routine here
                INCRB
                MOVE    TILE_DX, R0
                MOVE    @R0, R0
                MOVE    TILE_DY, R1
                MOVE    @R1, R1
                INCRB

                ; draw the font ed workspace
                RSUB    _FONTED_DRAW, 1

                ; set working registers
                MOVE    VGA$CR_X, R0            ; R0: hw cursor X
                MOVE    VGA$CR_Y, R1            ; R1: hw cursor Y
                MOVE    VGA$CHAR, R2            ; R2: print at hw cursor pos                
                MOVE    SELECTED_CHR, R3
                MOVE    @R3, R3                 ; R3: char being edited
                AND     0x00FF, R3              ; drop color information
                MOVE    LRU_FGBG, R12           ; R12: fg/bg color combination
                ADD     R3, R12
                MOVE    @R12, R12

                ; font ed main loop
_FONTED_MAIN    RSUB    KBD_GETCHAR, 1

                ; check for foreground color selected: >= `a` and < `q`
                ; OR
                ; check for background color selected: >= `A` and < `Q`
                ; AND
                ; act accordingly
                RSUB    _FONTED_FGBG, 1
                RBRA    _FONTED_MAIN, C         ; fg or bg was changed

                ; check for cursor keys
_FONTED_CHKCSR  CMP     KBD$CUR_RIGHT, R8       ; cursor right?
                RBRA    _FONTED_CC_L, !Z        ; no
                MOVE    @R0, R9                 ; check right boundary
                ADD     1, R9
                SUB     CHAR_ED_X, R9
                CMP     R9, 8                   ; char width = 8
                RBRA    _FONTED_MAIN, N         ; out of bounds: ignore key
                ADD     1, @R0                  ; move cursor to the right
                MOVE    FONT_ED_CX, R8          ; remember x position
                MOVE    @R0, @R8
                RBRA    _FONTED_MAIN, 1         ; get next key

_FONTED_CC_L    CMP     KBD$CUR_LEFT, R8        ; cursor left?
                RBRA    _FONTED_CC_D, !Z        ; no
                MOVE    @R0, R9                 ; check left boundary
                SUB     1, R9
                CMP     R9, CHAR_ED_X
                RBRA    _FONTED_MAIN, !N        ; out of bounds: ignore key
                MOVE    R9, @R0                 ; move cursor to the left
                MOVE    FONT_ED_CX, R8          ; remember x position
                MOVE    R9, @R8
                RBRA    _FONTED_MAIN, 1

_FONTED_CC_D    CMP     KBD$CUR_DOWN, R8        ; cursor down
                RBRA    _FONTED_CC_U, !Z        ; no
                MOVE    @R1, R9                 ; check lower boundary
                ADD     1, R9
                SUB     CHAR_ED_Y, R9
                CMP     R9, 12                  ; char height = 12
                RBRA    _FONTED_MAIN, N         ; out of bounds: ignore key
                ADD     1, @R1                  ; move cursor down
                MOVE    FONT_ED_CY, R8          ; remember y position
                MOVE    @R1, @R8
                RBRA    _FONTED_MAIN, 1

_FONTED_CC_U    CMP     KBD$CUR_UP, R8          ; cursor up
                RBRA    _FONTED_SPACE, !Z       ; no
                MOVE    @R1, R9                 ; check upper boundary
                SUB     1, R9
                CMP     R9, CHAR_ED_Y
                RBRA    _FONTED_MAIN, !N        ; out of bounds: ignore key
                MOVE    R9, @R1                 ; move cursor up
                MOVE    FONT_ED_CY, R8          ; remember y position
                MOVE    R9, @R8
                RBRA    _FONTED_MAIN, 1

_FONTED_SPACE   CMP     KBD$SPACE, R8           ; space
                RBRA    _FONTED_F1, !Z
                MOVE    @R2, R8                 ; ignore color information ..
                AND     0x00FF, R8              ; .. to check if ..
                CMP     R8, CHR_DRAW_1          ; .. pixel is set
                RBRA    _FONTED_SET0, Z         ; yes: so delete it
                MOVE    CHR_DRAW_1, @R2         ; no: so set it                
                RBRA    _FONTED_MODF, 1
_FONTED_SET0    MOVE    CHR_DRAW_0, @R2
_FONTED_MODF    MOVE    SELECTED_CHR, R12       ; apply color
                MOVE    @R12, R12
                AND     0xFF00, R12
                ADD     R12, @R2
                XOR     R12, R12                ; scanend bit pattern
                MOVE    8, R9                   ; char is 8 pixel wide
                MOVE    @R0, R7                 ; save original cursor pos
                MOVE    CHAR_ED_X, @R0          ; scan line from left to right
_FONTED_MODF3   ADD     1, @R0
                MOVE    @R2, R8                 ; discard color information
                AND     0x00FF, R8
                CMP     R8, CHR_DRAW_1          ; pixel is set?
                RBRA    _FONTED_MODF1, !Z       ; no
                OR      2, SR                   ; set X for SHL (shift in a 1)
                RBRA    _FONTED_MODF2, 1
_FONTED_MODF1   AND     0xFFFD, SR              ; clr X for SHL (shift in a 0)
_FONTED_MODF2   SHL     1, R12                  
                SUB     1, R9
                RBRA    _FONTED_MODF3, !Z
                MOVE    SELECTED_CHR, R8        ; change font ram:                
                MOVE    @R8, R8                 ; offs = (ascii * 12) + line
                AND     0x00FF, R8              ; discard color information
                MOVE    12, R9
                SYSCALL(mulu, 1)
                ADD     @R1, R10                ; @R1 = line + CHAR_ED_Y + 1
                SUB     CHAR_ED_Y, R10
                SUB     1, R10
                ADD     VGA$FONT_OFFS_USER, R10
                MOVE    VGA$FONT_ADDR, R8
                MOVE    R10, @R8++              ; set address
                MOVE    R12, @R8                ; write pixel pattern
                MOVE    R7, @R0                 ; restore original cursor pos
                RBRA    _FONTED_MAIN, 1

_FONTED_F1      CMP     KBD$F1, R8              ; F1
                RBRA    _FONTED_F5, !Z          ; no
                MOVE    FONT_MODE, R0           ; sprite editing while in ..
                MOVE    1, @R0                  ; .. font mode
                MOVE    1, R8
                RBRA    _FONTED_EXIT, 1

_FONTED_F5      CMP     KBD$F5, R8              ; F5
                RBRA    _FONTED_F7, !Z          ; no
                MOVE    SELECTED_CHR, R8        ; calculate and set address
                MOVE    @R8, R8                 ; char index
                MOVE    12, R9                  ; 12 words per char
                SYSCALL(mulu, 1)                ; address = chr idx * 12
                ADD     VGA$FONT_OFFS_USER, R10 ; R10 = address + user offset
                MOVE    VGA$FONT_ADDR, R8
                MOVE    R10, @R8++              ; set address
_FONTED_F5_L    MOVE    0, @R8                  ; clear font pattern
                SUB     1, R8                   ; back to address register
                ADD     1, @R8++                ; set next address
                SUB     1, R9                   ; one less word per char to go
                RBRA    _FONTED_F5_L, !Z
                RSUB    _FONTED_DRAW, 1         ; redraw
                RBRA    _FONTED_MAIN, 1

_FONTED_F7      CMP     KBD$F7, R8              ; F7
                RBRA    _FONTED_MAIN, !Z        ; no
                RSUB    _FONTED_CLR, 1          ; clear left part of workspace
                MOVE    FONT_MODE, R0           ; back to normal main mode
                MOVE    0, @R0
                MOVE    0, R8
                RBRA    _FONTED_EXIT, 1

                ; restore registers and sprite size
_FONTED_EXIT    MOVE    FONT_MODE, R9
                CMP     1, @R9
                RBRA    _FONTED_EXIT2, Z

                ; restore main help, but only, if we are not in sprite
                ; editing while in font mode
                MOVE    R8, R0
                MOVE    STR_HELP_MAIN, R8
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1
                MOVE    R0, R8

_FONTED_EXIT2   DECRB
                MOVE    TILE_DX, R2
                MOVE    R0, @R2
                MOVE    TILE_DY, R2
                MOVE    R1, @R2
                DECRB
                MOVE    R1, R9
                MOVE    R2, R10
                MOVE    R3, R11
                MOVE    R4, R12
                MOVE    VGA$CR_X, R7
                MOVE    R5, @R7++
                MOVE    R6, @R7
                DECRB
                RET
                
                ; draw the font ed workspace by clearing the character
                ; selection palette and showing the font editing window
                ; and the color selection palette instead
_FONTED_DRAW    SYSCALL(enter, 1)

                RSUB    _FONTED_CLR, 1
                MOVE    TILE_DX, R0             ; font size is 8x12
                MOVE    8, @R0
                MOVE    TILE_DY, R0
                MOVE    12, @R0
                MOVE    1, R8                   ; R8=1: font ed workspace
                RSUB    DRAW_WORKSPACE, 1

                ; draw the character that is being edited
                MOVE    VGA$CR_X, R0            ; R0: hw cursor X
                MOVE    VGA$CR_Y, R1            ; R1: hw cursor Y
                MOVE    VGA$CHAR, R2            ; R2: print at hw cursor pos                
                MOVE    SELECTED_CHR, R3
                MOVE    @R3, R3                 ; R3: char being edited
                AND     0x00FF, R3              ; drop color information
                MOVE    LRU_FGBG, R12           ; R12: fg/bg color combination
                ADD     R3, R12
                MOVE    @R12, R12

                MOVE    SELECTED_X, @R0         ; print the small char at ..
                MOVE    SELECTED_Y, @R1         ; .. the bottom of the screen
                MOVE    R3, R10                 ; ASCII selected char
                AND     0x00FF, R10             ; delete old color
                ADD     R12, R10                ; apply fg/bg color
                MOVE    R10, @R2                ; print

                MOVE    CHAR_ED_X, R4           ; R4=start col. for each line
                ADD     1, R4
                MOVE    R4, @R0
                MOVE    CHAR_ED_Y, @R1
                ADD     1, @R1

                MOVE    R3, R8                  ; calculate address of char .. 
                MOVE    12, R9                  ; .. pattern in font ram
                SYSCALL(mulu, 1)
                ADD     VGA$FONT_OFFS_USER, R10
                MOVE    VGA$FONT_ADDR, R6
                MOVE    R10, R5
                MOVE    R5, @R6
                MOVE    VGA$FONT_DATA, R9

                MOVE    12, R8                  ; 12 words per char
_FONTED_PLM     MOVE    @R9, R5
                MOVE    9, R7                   ; we are subtracting pre-loop
                AND     0xFFFD, SR              ; clear X before SHL
                SHL     8, R5
_FONTED_PL      SUB     1, R7                   ; one less bit to go
                RBRA    _FONTED_PNEXT, Z
                AND     0xFFFD, SR              ; clear X before SHL
                SHL     1, R5                   ; probe bitmask
                RBRA    _FONTED_PSPACE, !C      ; zero?
                MOVE    CHR_DRAW_1, R11         ; one!
                ADD     R12, R11                ; apply color
                MOVE    R11, @R2                ; print on screen
                ADD     1, @R0                  ; x-coord on screen + 1
                RBRA    _FONTED_PL, 1           ; next bit
_FONTED_PSPACE  MOVE    CHR_DRAW_0, R11         ; zero!
                ADD     R12, R11                ; apply color
                MOVE    R11, @R2                ; print on screen
                ADD     1, @R0                  ; x-coord on screen + 1
                RBRA    _FONTED_PL, !Z          ; next bit
_FONTED_PNEXT   MOVE    R4, @R0                 ; x-coord: back to 1st column
                ADD     1, @R1                  ; y-coord + 1
                ADD     1, @R6                  ; font ram address + 1
                SUB     1, R8                   ; one less pattern word to go
                RBRA    _FONTED_PLM, !Z

                ; draw the color palette choosers
                MOVE    STR_FOREGROUND, R8      ; print foreground col. string
                MOVE    PAL_ED_X, R9
                MOVE    PAL_ED_Y, R10
                RSUB    PRINT_STR_AT, 1

                MOVE    PAL_ED_X, @R0           ; put cursor to correct pos
                MOVE    PAL_ED_Y, @R1
                ADD     2, @R1

                XOR     R3, R3                  ; print foreground pal
                MOVE    16, R4
                MOVE    CHR_PAL_F, R11
                MOVE    CHR_PAL_SEL_F, R12
                RSUB    _FONTED_PALL, 1

                ADD     3, @R1                  ; print background col. string
                MOVE    STR_BACKGROUND, R8
                MOVE    PAL_ED_X, R9
                MOVE    @R1, R10
                RSUB    PRINT_STR_AT, 1

                MOVE    PAL_ED_X, @R0           ; print background pal
                ADD     2, @R1
                XOR     R3, R3
                MOVE    16, R4
                MOVE    CHR_PAL_B, R11
                MOVE    CHR_PAL_SEL_B, R12
                RSUB    _FONTED_PALL, 1

                ; font edit cursor
                MOVE    FONT_ED_CX, R8
                MOVE    @R8, @R0
                MOVE    FONT_ED_CY, R8                
                MOVE    @R8, @R1

                SYSCALL(leave, 1)
                RET

                ; clears left part of workspace
_FONTED_CLR     INCRB
                MOVE    R8, R0
                MOVE    R9, R1
                MOVE    R10, R2
                MOVE    R11, R3
                INCRB
                MOVE    STR_CLR_LEFT, R8        ; string contains spaces
                XOR     R9, R9                  ; R9:  column
                MOVE    2, R10                  ; R10: line
_FONTED_CLR1    RSUB    PRINT_STR_AT, 1
                ADD     1, R10
                CMP     37, R10                 ; clear until line 36
                RBRA    _FONTED_CLR1, !Z
                DECRB
                MOVE    R0, R8
                MOVE    R1, R9
                MOVE    R2, R10
                MOVE    R3, R11
                DECRB
                RET

                ; prints the color palette
                ; (deliberately does not save the lower register bank)
                ;
                ; the hardware cursor needs to be set
                ; R3 is a predefined color counter
                ; R4 is the amount
                ; R11 is the color palette display character
                ; R12 is a predefined ASCII code to count up from for
                ; displaying the color selector
_FONTED_PALL    MOVE    R12, R5                 ; print selector char
                MOVE    R5, @R2                
                MOVE    R11, R5                 ; char used to print the pal
                AND     0xFFFD, SR              ; clear X before SHL
                MOVE    R3, R7                  
                CMP     CHR_PAL_F, R11          ; foreground or background?
                RBRA    _FONTED_PALL_F, Z
                SHL     12, R7                  ; background color
                RBRA    _FONTED_PALL_B, 1
_FONTED_PALL_F  SHL     8, R7                   ; foreground color     
_FONTED_PALL_B  ADD     R7, R5
                ADD     1, @R1                  ; print color one line below
                MOVE    R5, @R2
                SUB     1, @R1
                ADD     1, R12                  ; next selector char
                ADD     2, @R0                  ; x-coord + 2
                ADD     1, R3                   ; next color
                SUB     1, R4                   ; one less color to go
                RBRA    _FONTED_PALL, !Z
                RET                

                ; check for foreground color selected: >= `a` and < `q`
                ; OR
                ; check for background color selected: >= `A` and < `Q`
                ; AND
                ; act accordingly
                ;
                ; expects the key in R8
                ; 
                ; returns C=1, if foreground or background color changes
                ; where performed, else C=0

_FONTED_FGBG    SYSCALL(enter, 1)
                AND     0xFFFB, SR              ; clear carry bit

                ; check for foreground color selected: >= `a` and < `q`
                MOVE    CHR_PAL_SEL_F, R9       ; R9 = `a`
                MOVE    R9, R10
                ADD     16, R10                 ; R10 = `q`
                SYSCALL(in_range_u, 1)          ; is R8 in the fg col. range?
                RBRA    _FONTED_FGBG1, !C       ; no: check for bg col. range

                ; add correct foreground color to fg/bg col. LRU buffer
                SUB     CHR_PAL_SEL_F, R8       ; foreground color selected
                AND     0xFFFD, SR              ; clear X before SHL   
                SHL     8, R8                   ; foreground color bit pos.
                MOVE    LRU_FGBG, R9            ; index the LRU buffer with ..
                MOVE    SELECTED_CHR, R10       ; .. the character ..
                AND     0x00FF, @R10            ; .. but without color info
                ADD     @R10, R9
                AND     0xF000, @R9             ; clear old foreground color 
                ADD     R8, @R9                 ; set new foreground color
                ADD     @R9, @R10               ; save modified selected char 
                RSUB    _FONTED_DRAW, 1         ; redraw everything
                OR      0x0004, SR              ; set carry bit
                RBRA    _FONTED_FGBG2, 1        ; return with C=1

                ; check for background color selected: >= `A` and < `Q`
_FONTED_FGBG1   MOVE    CHR_PAL_SEL_B, R9       ; R9 = `A`
                MOVE    R9, R10
                ADD     16, R10                 ; R10 = `Q`
                SYSCALL(in_range_u, 1)          ; is R8 is the bg col. range?
                RBRA    _FONTED_FGBG2, !C       ; no: return with C=0

                ; add correct background color to fg/bg col. LRU buffer
                SUB     CHR_PAL_SEL_B, R8       ; background color selected
                AND     0xFFFD, SR              ; clear X before SHL   
                SHL     12, R8                  ; background color bit pos.
                MOVE    LRU_FGBG, R9            ; index the LRU buffer with ..
                MOVE    SELECTED_CHR, R10       ; .. the character ..
                AND     0x00FF, @R10            ; .. but without color info                
                ADD     @R10, R9
                AND     0x0F00, @R9             ; clear old background color
                ADD     R8, @R9                 ; set new background color
                ADD     @R9, @R10               ; save modified selected char
                RSUB    _FONTED_DRAW, 1         ; redraw everything and
                OR      0x0004, SR              ; set carry bit

_FONTED_FGBG2   SYSCALL(leave, 1)
                RET

; ****************************************************************************
; PAL_ED
;    Main routine for palette editing: Not meant to be called via RSUB.
;    Instead, it jumps back to the main loop
; ****************************************************************************

PAL_ED          SYSCALL(enter, 1)

_PED_START      MOVE    STR_HELP_PAL, R8
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1

                RSUB    CURSOR_OFF, 1
                RSUB    _FONTED_CLR, 1          ; clear left side of workspace

                MOVE    VGA$CR_X, R0            ; R0: hw cursor X
                MOVE    VGA$CR_Y, R1            ; R1: hw cursor Y
                MOVE    VGA$CHAR, R2            ; R2: print at hw cursor pos                

                ; draw the color palette choosers
                MOVE    STR_PAL_FG, R8          ; print foreground col. string
                MOVE    PAL_ED_X, R9
                MOVE    PAL_ED_Y, R10
                ADD     9, R10
                RSUB    PRINT_STR_AT, 1

                MOVE    PAL_ED_X, @R0           ; put cursor to correct pos
                MOVE    PAL_ED_Y, @R1
                ADD     11, @R1

                XOR     R3, R3                  ; print foreground pal
                MOVE    16, R4
                MOVE    CHR_PAL_F, R11
                MOVE    CHR_PAL_SEL_F, R12
                RSUB    _FONTED_PALL, 1

                ADD     3, @R1                  ; print background col. string
                MOVE    STR_PAL_BG, R8
                MOVE    PAL_ED_X, R9
                MOVE    @R1, R10
                RSUB    PRINT_STR_AT, 1

                MOVE    PAL_ED_X, @R0           ; print background pal
                ADD     2, @R1
                XOR     R3, R3
                MOVE    16, R4
                MOVE    CHR_PAL_B, R11
                MOVE    CHR_PAL_SEL_B, R12
                RSUB    _FONTED_PALL, 1

                ; draw the color bars
                MOVE    CHR_PAL_F, R3
                RSUB    _PED_DCB, 1

                ; R4 contains the address of the color that is being edited
                MOVE    VGA$PALETTE_OFFS_USER, R4

                MOVE    SELECTED_PAL, R8
                MOVE    'a', @R8

                ; main loop of the palette editor

_PED_KL         MOVE    _PED_SCRATCH, R8        ; init input scratch buffer
                MOVE    0, @R8++
                MOVE    0, @R8
                MOVE    PAL_ED_X, R8            ; print selected pal entry
                MOVE    11, R9
                SYSCALL(vga_moveto, 1)
                MOVE    STR_PED_ACTIVE, R8
                RSUB    LOCAL_PUTS, 1
                MOVE    SELECTED_PAL, R8
                MOVE    @R8, R8
                RSUB    LOCAL_PUTC, 1

                MOVE    VGA$PALETTE_ADDR, R8
                MOVE    R4, @R8++
                MOVE    @R8, R5                 ; R5 = 15bit RBG color

                ; show compound 24-bit and 15-bit RGB info
                MOVE    PAL_ED_X, R8            ; 24-bit RGB numeric
                MOVE    13, R9
                SYSCALL(vga_moveto, 1)
                MOVE    STR_RGB24, R8
                RSUB    LOCAL_PUTS, 1
                MOVE    R5, R8
                RSUB    PRINT_24BIT_RGB, 1                
                MOVE    PAL_ED_X, R8            ; 15-bit RGB numeric
                MOVE    15, R9
                SYSCALL(vga_moveto, 1)
                MOVE    STR_RGB15, R8
                RSUB    LOCAL_PUTS, 1
                MOVE    R5, R8
                RSUB    LOCAL_PUTHEX, 1

                ; show 2 hex nibbles per color plus a visual representation
                MOVE    _PED_STRS, R12          ; LUT for strings for R, G, B
                MOVE    _PED_RGB, R11           ; LUT for masks and shifts
                MOVE    3, R10                  ; 3 iterations: R, G and B
                MOVE    17, R9                  ; y-pos for cursor                
_PED_SHOWRGB_L  MOVE    PAL_ED_X, R8            ; x-pos for cursor
                SYSCALL(vga_moveto, 1)
                MOVE    @R12++, R8              ; print string for R, G or B
                RSUB    LOCAL_PUTS, 1
                MOVE    R5, R8                  ; 15-bit compound value
                AND     @R11, R8                ; extract R, G or B
                ADD     3, R11                  ; amount of SHR in LUT
                                                ; (C is zero here due to ADD)
                SHR     @R11++, R8              ; now R8 = 2 nibbles
                RSUB    PRINT_2HEXNIBS, 1       ; print R8
                MOVE    R8, @--SP               ; remember R8
                MOVE    STR_METER, R8           ; clear old meter display by
                RSUB    LOCAL_PUTS, 1           ; printing [                ]
                MOVE    @SP++, R8               ; R8 = R, G or B in 2 nibbles
                AND     0xFFFB, SR              ; clear C (shift in '0')                
                SHR     1, R8                   ; calculate the x-coordinate..
                ADD     PAL_ED_X, R8            ; of the visualization ..
                ADD     16, R8
                SYSCALL(vga_moveto, 1)          ; .. and move the cursor ..
                MOVE    CHR_DRAW_1, R8          ; .. and draw the visual
                RSUB    LOCAL_PUTC, 1
                ADD     1, R9                   ; y-pos + 1
                ADD     4, R11                  ; LUT: skip one row
                SUB     1, R10                  ; iteration counter
                RBRA    _PED_SHOWRGB_L, !Z

                RSUB    KBD_GETCHAR, 1

                ; check for foreground color selected: >= `a` and < `q`
                MOVE    CHR_PAL_SEL_F, R9       ; R9 = `a`
                MOVE    R9, R10
                ADD     16, R10                 ; R10 = `q`
                SYSCALL(in_range_u, 1)          ; is R8 in the fg col. range?
                RBRA    _PED_BG, !C             ; no: check for bg col. range

                MOVE    SELECTED_PAL, R10       ; remember selection for ..
                MOVE    R8, @R10                ; .. displaying it

                ; determine address of current foreground col. being edited
                ; and store it in R4 and redraw the color bar
                SUB     R9, R8
                ADD     VGA$PALETTE_OFFS_USER, R8
                MOVE    R8, R4                  ; R4 = addr of current col
                AND     0xFFFD, SR              ; clear X (shift in '0')                
                SHL     8, R8
                MOVE    CHR_PAL_F, R3
                ADD     R8, R3
                RSUB    _PED_DCB, 1             ; redraw color bar
                RBRA    _PED_KL, 1              ; next key

                ; check for foreground color selected: >= `A` and < `Q`
_PED_BG         MOVE    CHR_PAL_SEL_B, R9       ; R9 = `A`
                MOVE    R9, R10
                ADD     16, R10                 ; R10 = `Q`
                SYSCALL(in_range_u, 1)          ; is R8 in the bg col. range?
                RBRA    _PED_CK, !C             ; no: check for other keys

                MOVE    SELECTED_PAL, R10       ; remember selection for ..
                MOVE    R8, @R10                ; .. displaying it

                ; determine address of current background col. being edited
                ; and store it in R4 and redraw the color bar
                SUB     R9, R8
                ADD     VGA$PALETTE_OFFS_USER, R8
                ADD     16, R8                  ; switch to background pal
                MOVE    R8, R4                  ; R4 = addr of current col
                AND     0xFFFD, SR              ; clear X (shift in '0')                
                SHL     12, R8
                MOVE    CHR_PAL_B, R3
                ADD     R8, R3
                RSUB    _PED_DCB, 1             ; redraw color bar
                RBRA    _PED_KL, 1              ; next key

                ; check if key is >= `1` and < `7`
                ; 1 & 2: modify R
                ; 3 & 4: modify G
                ; 5 & 6: modify B
_PED_CK         MOVE    '1', R9
                MOVE    '7', R10
                SYSCALL(in_range_u, 1)
                RBRA    _PED_CKK, !C

                MOVE    R5, R10                 ; R5 = 15bit RGB color
                MOVE    VGA$PALETTE_DATA, R9
                SUB     '1', R8                 ; 1 => 0; 2 => 1, ...
                AND     0xFFFD, SR              ; clear X (shift in '0')                
                SHL     2, R8                   ; 4 LUT entries per row
                MOVE    _PED_RGB, R6            ; index to look-up table
                ADD     R8, R6 

                MOVE    R10, R11                ; R10 = 15bit RGB color
                AND     @R6++, R11              ; check over-/underflow:
                CMP     @R6++, R11              ; in case of yes ..
                RBRA    _PED_KL, Z              ; .. back to pal ed main loop
                ADD     @R6, R10                ; add or sub 1 from R, G or B
                MOVE    R10, @R9                ; store in palette RAM

_PED_CKK        CMP     KBD$F11, R8             ; end pal ed
                RBRA    _PED_END, Z

                ; numeric palette editing

                MOVE    _PED_EDIT_ITEMS, R10
                MOVE    _PED_EDIT, R12          ; LUT: find F-key and print ..
_PED_CKF        CMP     R8, @R12                ; .. dynamic string
                RBRA    _PED_FKF, Z
                ADD     _PED_EDIT_LINE, R12     ; next row of LUT
                SUB     1, R10
                RBRA    _PED_CKF, !Z
                RBRA    _PED_KL, 1              ; illegal key => main loop
        
_PED_FKF        MOVE    STR_HELP_EDIT, R8       ; numeric edit help text
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1

                MOVE    PAL_ED_X, R8            ; print static edit string
                MOVE    22, R9
                SYSCALL(vga_moveto, 1)
                MOVE    STR_PED_EDIT, R8
                RSUB    LOCAL_PUTS, 1

                ADD     1, R12                  ; LUT: string to be printed
                MOVE    @R12++, R8              ; print dynamic edit string
                RSUB    LOCAL_PUTS, 1

                RSUB    CURSOR_ON, 1
                MOVE    R4, R8                  ; R4=address of edited pal col
                INCRB
                MOVE    @R12++, R1              ; R1=# of nibbles to type
                MOVE    @R12++, R2              ; R2=bitmask
                NOT     R2, R3                  ; R3=bitmask to clear value
                MOVE    @R12, R4                ; R4=SHL pos in color word
                XOR     R5, R5                  ; R5=typed # of nibbles
                MOVE    R1, R6                  ; R6=SHL pos of nib. in buffer
                SUB     1, R6
                AND     0xFFFD, SR              ; clear X (shift in '0')                
                SHL     2, R6
                MOVE    R8, R7                  ; R7=address of edited pal col

_PED_NEXTCHR    RSUB    KBD_GETCHAR, 1
                SYSCALL(chr2upper, 1)
                MOVE    R8, R11                 ; remember char for printing

                CMP     KBD$ENTER, R8           ; ENTER = store & finish
                RBRA    _PED_STORE, Z 

                CMP     KBD$ESC, R8             ; ESC = cancel
                RBRA    _PED_NUM_END, Z

                MOVE    '0', R9                 ; R8 in range [0..9]
                MOVE    ':', R10                ; ASCII of 9 + 1
                SYSCALL(in_range_u, 1)
                RBRA    _PED_VALIDCHR1, C       ; in range: proceed
                MOVE    'A', R9                 ; R8 in range [A..F]
                MOVE    'G', R10
                SYSCALL(in_range_u, 1)
                RBRA    _PED_VALIDCHR2, C       ; in range: proceed
                RBRA    _PED_NEXTCHR, 1         ; illegal char: ignore

_PED_VALIDCHR1  SUB     '0', R8                 ; R8=convert to number
                RBRA    _PED_NIBBLE, 1
_PED_VALIDCHR2  SUB     55, R8                  ; R8=convert to number
_PED_NIBBLE     CMP     R5, R1                  ; max amount of chars?
                RBRA    _PED_NEXTCHR, Z         ; yes: ignore typed char
                ADD     1, R5                   ; R5=typed # of nibbles

                XOR     R9, R9                  ; R9 = hi word  R8 = lo word
                MOVE    R6, R10                 ; R10 = amount
                AND     0xFFFD, SR              ; clr X for SHL (shift in a 0)                
                SYSCALL(shl32, 1)               ; move nib. to correct pos

                MOVE    _PED_SCRATCH, R0        ; store nibble at the correct
                OR      R9, @R0++               ; position in the buffer:
                OR      R8, @R0                 ; from left to right

                SUB     4, R6                   ; next nib: 4 bit pos to right

                MOVE    R11, R8                 ; print nib
                RSUB    LOCAL_PUTC, 1

                RBRA    _PED_NEXTCHR, 1

_PED_STORE      SUB     R5, R1                  ; R1=# remaining not typed nib
                AND     0xFFFD, SR              ; clr X for SHL (shift in a 0)
                SHL     2, R1                   ; amount of necessary SHR 

                MOVE    _PED_SCRATCH, R0        ; compensate for # of typed ch
                MOVE    @R0++, R9               ; hi word
                MOVE    @R0, R8                 ; lo word
                MOVE    R1, R10                 ; amount of shr
                AND     0xFFFB, SR              ; clr C for SHR (shift in a 0)                
                SYSCALL(shr32, 1)               ; result: R9=hi R8=lo
                SUB     1, R0
                MOVE    R9, @R0++               ; store in scratch buffer
                MOVE    R8, @R0                                                                 

                CMP     0xFFFF, R4              ; 24-bit flag?
                RBRA    _PED_STORE2, !Z         ; no: just use low word in R8
                AND     0x00F8, R9              ; convert 24-bit to 15-bit..
                XOR     R8, R8                  ; ..according to tools/rgb2q.c
                MOVE    9, R10
                AND     0xFFFB, SR              ; clr C for SHR (shift in a 0)                
                SYSCALL(shr32, 1)               ; result is in R8, ignore R9
                MOVE    R8, R9                  ; R9 will contain 15-bit val.
                MOVE    @R0, R8
                AND     0xF800, R8
                AND     0xFFFB, SR              ; clr C for SHR (shift in a 0)                
                SHR     6, R8
                ADD     R8, R9
                MOVE    @R0, R8
                AND     0x00F8, R8
                AND     0xFFFB, SR              ; clr C for SHR (shift in a 0)                
                SHR     3, R8
                ADD     R8, R9
                MOVE    R9, R8                  ; _PED_STORE2 expcts val in R8
                XOR     R4, R4                  ; no shl necessary             

_PED_STORE2     AND     0xFFFD, SR              ; clr X for SHL (shift in a 0)
                SHL     R4, R8                  ; shift to pos in color word
                AND     R2, R8                  ; bitmask to cut to right size 

                MOVE    VGA$PALETTE_ADDR, R12   ; R7 = address of currently ..
                MOVE    R7, @R12++              ; edited palette color
                AND     R3, @R12                ; clear old value
                OR      R8, @R12                ; store new value

                ; continue editing: back to pal ed main loop
_PED_NUM_END    RSUB    CURSOR_OFF, 1                
                MOVE    PAL_ED_X, R8            ; clear edit string
                MOVE    22, R9
                SYSCALL(vga_moveto, 1)
                MOVE    STR_CLR_LEFT, R8
                RSUB    LOCAL_PUTS, 1
                MOVE    STR_HELP_PAL, R8        ; print pal ed help
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1
                DECRB 
                RBRA    _PED_KL, 1              ; pal ed main loop

                ; end pal ed
_PED_END        RSUB    CURSOR_ON, 1

                ; restore visual apprearance of the main workspace 
                RSUB    _FONTED_CLR, 1          ; clear left side of workspace
                RSUB    DRAW_PALETTE, 1         ; character chooser
                MOVE    STR_HELP_MAIN, R8       ; print main help
                MOVE    0, R9
                MOVE    39, R10
                RSUB    PRINT_STR_AT, 1
                MOVE    STR_HELP_MAIN, R8

                SYSCALL(leave, 1)
                RBRA    MAIN_LOOP, 1            ; we came here by RBRA

                ; draw the color bar
                ; expects:
                ; R0 .. R2 to contain the screen-write registers
                ; R3 to contain the char incl. color that is used to draw
_PED_DCB        MOVE    3, @R1                  ; start y coordinate on screen
_PED_L1         MOVE    PAL_ED_X, @R0
_PED_L2         MOVE    R3, @R2
                ADD     1, @R0                  ; x coordinate on screen
                CMP     35, @R0                 ; width = @R0 - PAL_ED_X
                RBRA    _PED_L2, !Z
                ADD     1, @R1
                CMP     9, @R1                  ; height = @R1 - start y coord
                RBRA    _PED_L1, !Z
                RET

                ; this look up table stores, how R, G or B are modified
                ; depending on pressing 1 .. 6
_PED_RGB        .DW     RED_MASK,   0,          RED_ONE_C,    10 ; RED - 1
                .DW     RED_MASK,   RED_MASK,   RED_ONE,      0  ; RED + 1
                .DW     GREEN_MASK, 0,          GREEN_ONE_C,  5  ; GREEN - 1
                .DW     GREEN_MASK, GREEN_MASK, GREEN_ONE,    0  ; GREEN + 1
                .DW     BLUE_MASK,  0,          BLUE_ONE_C,   0  ; BLUE - 1
                .DW     BLUE_MASK,  BLUE_MASK,  BLUE_ONE,     0  ; BLUE + 1

_PED_STRS       .DW STR_RED, STR_GREEN, STR_BLUE

                ; this look up table stores the combination of function keys
                ; and strings, amount of hex digits (nibbles) to be entered,
                ; the bit mask and the amount of SHL to position the nibbles
                ; inside the color word (0xFFFF = special 24-bit flag)
_PED_EDIT_ITEMS .EQU    5
_PED_EDIT_LINE  .EQU    5
_PED_EDIT       .DW     KBD$F1, STR_RGB24,      6, 0xFFFF,      0xFFFF
                .DW     KBD$F3, STR_RGB15,      4, 0x7FFF,      0
                .DW     KBD$F5, STR_PED_RED,    2, RED_MASK,    10
                .DW     KBD$F7, STR_PED_GREEN,  2, GREEN_MASK,  5
                .DW     KBD$F9, STR_PED_BLUE,   2, BLUE_MASK,   0

                ; 32-bit scratch buffer for editing:
                ; highest nibble first (editing "from left to right")
_PED_SCRATCH    .BLOCK  2

; ****************************************************************************
; FILE_MENU
;    Load or save data or quit.
;    Meant to be called via RBRA and not via RSUB. Jumps back to main loop.
; ****************************************************************************

FILE_MENU       SYSCALL(enter, 1)

                ; do a before/after stack check!
                RSUB    _FM_SAVE, 1           
                SYSCALL(leave, 1)
                ; not called via RSUB, so do an RBRA to return to main!
                HALT

_FM_ELMID       .BLOCK 21                       ; element id
_FM_ELMID_N     .EQU 21                         ; maximum length of element id

; ----------------------------------------------------------------------------
; Save data for FILE_MENU
; ----------------------------------------------------------------------------

_FM_SAVE        SYSCALL(enter, 1)

                ; ------------------------------------------------------------
                ; Let the user enter project details and output the header
                ; ------------------------------------------------------------

                MOVE    STR_LS_START0, R8       ; output header intro
                RSUB    UART_PUTS, 1
                RSUB    _FM_CMTSPACE, 1

                MOVE    STR_FILE_PRJ, R8        ; get project name and ...
                MOVE    INPUTSCRATCH, R9        ; ... add it to the output
                MOVE    INPUTSCRATCH_N, R10
                RSUB    _FM_INPUT, 1
                MOVE    R9, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                RSUB    _FM_CMTSPACE, 1
                
_FM_INP_ID      MOVE    STR_FILE_ELM, R8        ; get element id
                MOVE    _FM_ELMID, R9
                MOVE    _FM_ELMID_N, R10
                RSUB    _FM_INPUT, 1          
                MOVE    R9, R8
                SYSCALL(str2upper, 1)           ; id is in capital letters
                RSUB    _FM_CHKID, 1            ; legal element id?
                RBRA    _FM_INP_IDLEGAL, C      ; yes   
                MOVE    STR_LS_E_ILLID, R8
                RSUB    _FM_PLL, 1
_FM_INP_ID_EL   RSUB    KBD_GETCHAR, 1
                CMP     KBD$ENTER, R8
                RBRA    _FM_INP_ID_EL, !Z
                RBRA    _FM_INP_ID, 1

_FM_INP_IDLEGAL RSUB    UART_PUTS, 1            ; output element id

                MOVE    STR_LS_COLON, R8        ; output :<space>
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE, R8
                RSUB    UART_PUTS, 1

                MOVE    STR_FILE_ELMCMT, R8     ; get element comment and ...
                MOVE    INPUTSCRATCH, R9        ; ... add it to output
                MOVE    INPUTSCRATCH_N, R10
                RSUB    _FM_INPUT, 1
                MOVE    R9, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1

                MOVE    STR_LS_START1, R8       ; output header outro
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_START2, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_START0, R8
                RSUB    UART_PUTS, 1

                ; ------------------------------------------------------------
                ; Output palette data
                ; ------------------------------------------------------------

                ; put changes of foreground palette (fg pal) on the stack
                XOR     R10, R10                ; R10 = 0 means fg pal
                RSUB    _FM_GETCHGPAL, 1        ; (changes R12)
                MOVE    R9, R0                  ; R0: used to restore the SP
                MOVE    R8, R1                  ; R1: start address of info
                                                ; record about fg pal changes

                ; put changes of background palette (bg pal) on the stack
                MOVE    1, R10                  ; R10 = 1 means bg pal
                RSUB    _FM_GETCHGPAL, 1        ; (changes R12)
                MOVE    R9, R2                  ; R2: used to restore the SP
                MOVE    R8, R3                  ; R3: start address of info
                                                ; record about bg pal changes

                ; if nothing is changed in fg and bg then return
                CMP     0, @R1                  
                RBRA    _FMS_SAVEPAL, !Z        ; # of fg changes is not 0
                CMP     0, @R3
                RBRA    _FMS_SAVEPAL, !Z        ; # of bg changes is not 0

                ; if both 0: restore SP & continue with the font save routine
                RBRA    _FMS_ENDSAVEPAL, 1      

_FMS_SAVEPAL    MOVE    STR_LS_PAL, R8          ; output palette header
                RSUB    _FMS_HEADER_OUT, 1

                MOVE    STR_LS_PAL_LFN, R8      ; save foreground pal data
                MOVE    STR_LS_PAL_LF, R9
                MOVE    R1, R10
                RSUB    _FMS_SP_F_OR_B, 1

                MOVE    STR_LS_PAL_LBN, R8      ; save background pal data
                MOVE    STR_LS_PAL_LB, R9
                MOVE    R3, R10
                RSUB    _FMS_SP_F_OR_B, 1

                ; restore SP
_FMS_ENDSAVEPAL ADD     R0, SP
                ADD     R2, SP

                ; ------------------------------------------------------------
                ; Output font data
                ; ------------------------------------------------------------

                ; put font changes on the stack
                RSUB    _FM_GETCHGFONT, 1       ; (changes R12)
                MOVE    R9, R0                  ; R0: used to restore the SP
                MOVE    R8, R1                  ; R1: start address of info
                                                ; record about font changes
                CMP     0, @R1
                RBRA    _FMS_SAVEFONT, !Z       ; # of font changes is not 0
                ADD     R0, SP                  ; else restore SP and leave
                RET

_FMS_SAVEFONT   MOVE    @R1++, R7               ; R7 = # of changed chars
                MOVE    STR_LS_FONT, R8         ; output font header
                RSUB    _FMS_HEADER_OUT, 1
                MOVE    STR_LS_FONT_LN, R8      ; output font metadata
                MOVE    R7, R9
                RSUB    _FMS_META_OUT, 1

                MOVE    VGA$FONT_ADDR, R2
                MOVE    VGA$FONT_DATA, R3

_FMS_S_F_LOOP   MOVE    @R1++, R4               ; R4: index of changed char
                MOVE    R4, R8
                MOVE    12, R9                  ; 12 words per char
                SYSCALL(mulu, 1)                
                ADD     VGA$FONT_OFFS_USER, R10 ; R10: address of changed char

                ; output the label and ".DW"
                MOVE    _FM_ELMID, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_FONT_L, R8
                RSUB    UART_PUTS, 1
                MOVE    R4, R8                  ; R4: index of changed char
                MOVE    INPUTSCRATCH, R9
                RSUB    WORD2HEXSTR, 1
                ADD     2, R9                   ; only last 2 nibbles
                MOVE    R9, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_DW, R8
                RSUB    UART_PUTS, 1

                ; output the 12 words of the changed char
                XOR     R5, R5                  ; R5: loop counter
_FMS_S_F_LOOP2  MOVE    R10, @R2                ; read changed word ...
                MOVE    @R3, R8                 ; ... into R8 so that it ...
                RSUB    _FMS_HEX_OUT, 1         ; ... be output as hex
                ADD     1, R10                  ; next address inside this chr
                ADD     1, R5
                CMP     12, R5                  ; done?
                RBRA    _FMS_S_F_CONT, Z        ; yes
                MOVE    STR_LS_COMMASPC, R8     ; add a ", "
                RSUB    UART_PUTS, 1
                RBRA    _FMS_S_F_LOOP2, 1       ; next word within this char

                ; next changed char, if any
_FMS_S_F_CONT   MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                SUB     1, R7
                RBRA    _FMS_S_F_LOOP, !Z

                ; restore SP
                ADD     R0, SP
                HALT

                SYSCALL(leave, 1)
                RET

; ----------------------------------------------------------------------------
; Output helper functions for the SAVE function in FILE_MENU
; ----------------------------------------------------------------------------

; Output a comment and a space
_FM_CMTSPACE    INCRB
                MOVE    R8, R0
                MOVE    STR_LS_CMT, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE, R8
                RSUB    UART_PUTS, 1
                MOVE    R0, R8
                DECRB
                RET

; Output amount of spaces given in R8 to UART
_FM_SPACES      INCRB
                MOVE    R8, R0
                MOVE    R8, R1
                MOVE    ' ', R8
_FM_SPACES_LOOP CMP     0, R0
                RBRA    _FM_SPACES_RET, Z
                RSUB    UART_PUTCHAR, 1
                SUB     1, R0
                RBRA    _FM_SPACES_LOOP, 1
_FM_SPACES_RET  MOVE    R1, R8
                DECRB
                RET

; Output "0x" and then the value given in R8 in hexadecimal
_FMS_HEX_OUT    INCRB
                MOVE    R8, R0
                MOVE    STR_LS_HEX_PREF, R8
                RSUB    UART_PUTS, 1
                MOVE    R0, R8
                MOVE    INPUTSCRATCH, R9
                RSUB    WORD2HEXSTR, 1
                MOVE    R9, R8
                RSUB    UART_PUTS, 1
                DECRB
                RET

; Output the header for the entity given by the string pointer in R8
_FMS_HEADER_OUT INCRB
                MOVE    R8, R0
                MOVE    STR_LS_CMT, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1                
                MOVE    STR_LS_START1, R8
                RSUB    UART_PUTS, 1
                RSUB    _FM_CMTSPACE, 1
                MOVE    _FM_ELMID, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE, R8
                RSUB    UART_PUTS, 1
                MOVE    R0, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_START1, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_CMT, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                DECRB
                RET

; Output the label, the .EQU and the 0x prefix for the # of something;
; then convert R9 to hex and output it, too
; R8: String pointer to "something" 
; R9: The actual amount to be converted to hex and to be output
_FMS_META_OUT   INCRB
                MOVE    R8, R0
                MOVE    _FM_ELMID, R8           
                RSUB    UART_PUTS, 1
                MOVE    R0, R8                  
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE2, R8
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_EQU, R8
                RSUB    UART_PUTS, 1
                MOVE    R9, R8
                RSUB    _FMS_HEX_OUT, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                DECRB
                RET

; ----------------------------------------------------------------------------
; Data output helper function for the SAVE function in FILE_MENU
; ----------------------------------------------------------------------------

; Check, which characters of the font changed in comparison to the default
; font. Return a pointer to a record set on the stack that is having the
; following structure:
; <amount of changed characters>
; <changed character index 0>
; <... ditto 1 .. n ...>
;   R8: pointer to record set on the stack
;   R9: amount to be added to the stack for restoring it
_FM_GETCHGFONT  INCRB

                MOVE    257, R9                 ; up to 256 index
                                                ; +1: size of change amount
                SUB     R9, SP                  ; reserve space on stack
                ADD     1, R9                   ; +1: size of return address
                                                ; because we are not returning
                                                ; from here using RET but by
                                                ; using our own "manual" way
                MOVE    SP, R8
                MOVE    R8, R0                  ; R0 = data record pointer
                ADD     1, R0                   ; leave space for # of changes

                MOVE    VGA$FONT_ADDR, R1
                MOVE    VGA$FONT_DATA, R2
                XOR     R3, R3                  ; R3 = start idx system font
                MOVE    VGA$FONT_OFFS_USER, R4  ; R4 = start idx custom font
                XOR     R7, R7                  ; R7 = font changes amount
                MOVE    3072, R12               ; R12 = amount of words to chk

_FM_GCF_LOOP    MOVE    R3, @R1                 ; addr of std value of font
                MOVE    @R2, R5                 ; R5 = std. val at index R3
                MOVE    R4, @R1                 ; addr of custom val. of font
                MOVE    @R2, R6                 ; R6 = custom val. at idx R4

                CMP     R5, R6                  ; changed font value?
                RBRA    _FM_GCF_NEXT, Z         ; no: next value

                ADD     1, R7                   ; increase amount of changes

                ; we need to find out, which character index the current
                ; data chunk refers to by dividing the current address of the
                ; standard value off the font by 12. And then we need to skip
                ; the rest of the current data of the char by calculating:
                ; new_address = current_address + (12 - (address % 12))
                ; We skip, because a single changed word within a character
                ; is enough so that the whole character needs to be stored.
                MOVE    R8, @--SP
                MOVE    R9, @--SP
                MOVE    R10, @--SP
                MOVE    R11, @--SP

                MOVE    R3, R8                  ; R10 = R3 / 12
                MOVE    12, R9                  ; R11 = R3 % 12
                SYSCALL(divu, 1)
                MOVE    R10, @R0++              ; store index of changed char
                MOVE    12, R10                 ; R10 = 12 - (R3 % 12)
                SUB     R11, R10
                ADD     R10, R3                 ; next index: standard font
                ADD     R10, R4                 ; next index: custom font

                MOVE    @SP++, R11
                MOVE    @SP++, R10
                MOVE    @SP++, R9
                MOVE    @SP++, R8
                RBRA    _FM_GCF_NEXT2, 1

_FM_GCF_NEXT    ADD     1, R3                   ; next index: standard font
                ADD     1, R4                   ; next index: custom font
_FM_GCF_NEXT2   CMP     R12, R3                 ; font done?
                RBRA    _FM_GCF_LOOP, !Z        ; no: loop

                MOVE    R7, @R8                 ; store # of pal changes
                DECRB

                MOVE    R8, R12                 ; find return address on stack                 
                ADD     R9, R12
                SUB     1, R12
                ABRA    @R12, 1                 ; perform manual RET

; Output palette data
; R8 = string ptr to number of elements (fg or bg)
; R9 = string ptr to data block (fg or bg)
; R10 = ptr to data structure that contains the to-be-output palette data
_FMS_SP_F_OR_B  INCRB   
                MOVE    R8, R0                  ; R0 = string ptr # of elmnts
                MOVE    R9, R1                  ; R1 = string ptr to dta block
                MOVE    R10, R2                 ; R2 = ptr to data records

                MOVE    R0, R8                  ; R0 = string ptr # of elmnts
                MOVE    @R2, R9                 ; @R2 = # changed pal entries
                RSUB    _FMS_META_OUT, 1        ; output palette metadata

                MOVE    @R2++, R3               ; R3: loop var: amount of chgs
                CMP     0, R3                   ; are there any pal. changes?
                RBRA    _FMS_SPFOB_RET, Z       ; no: return

                MOVE    _FM_ELMID, R8           ; output palette data
                RSUB    UART_PUTS, 1
                MOVE    R1, R8                  ; R1 = string ptr to dta block
                RSUB    UART_PUTS, 1
                MOVE    STR_LS_SPACE3, R8
                RSUB    UART_PUTS, 1
_FM_S_PAL_LOOP  MOVE    STR_LS_DW, R8
                RSUB    UART_PUTS, 1
                MOVE    @R2++, R8               ; output palette index
                RSUB    _FMS_HEX_OUT, 1        
                MOVE    STR_LS_COMMASPC, R8     ; add ", "
                RSUB    UART_PUTS, 1
                MOVE    @R2++, R8               ; output 15-bit pal col data
                RSUB    _FMS_HEX_OUT, 1
                MOVE    STR_LS_NEWLINE, R8
                RSUB    UART_PUTS, 1
                SUB     1, R3                   ; R3: loop var: amount of chgs
                RBRA    _FMS_SPFOB_RET, Z       ; no more palette data
                MOVE    _FM_ELMID, R8           ; use spaces to align:
                SYSCALL(strlen, 1)              ; len of element id plus
                ADD     LEN_LS_PAL_COL, R9      ; fixed len
                MOVE    R9, R8
                RSUB    _FM_SPACES, 1
                RBRA    _FM_S_PAL_LOOP, 1

_FMS_SPFOB_RET  DECRB
                RET

; Check, which foreground or background palette entries changed in comparison
; to the default palette. Return a pointer to a record set on the stack
; that is having the following structure:
; <amount of changed palette colors>
; <palette index 0><color data for index 0>
; <... ditto 1 .. n ...>
;   R8: pointer to record set on the stack
;   R9: amount to be added to the stack for restoring it
;  R10: toggle switch: 0 = foreground palette; 1 = background palette
_FM_GETCHGPAL   INCRB

                CMP     0, R10                 
                RBRA    _FM_GCP_BG, !Z
                                                ; R10 = 0: strt idx std fg pal
                MOVE    32, R11                 ; R11 = strt idx custom fg pal
                MOVE    16, R12                 ; R12 = end index std fg pal
                RBRA    _FM_GCP_START, 1
_FM_GCP_BG      MOVE    16, R10                 ; R10 = start idx std bg pal
                MOVE    48, R11                 ; R11 = strt idx custom bg pal
                MOVE    32, R12                 ; R12 = end index std

_FM_GCP_START   MOVE    33, R9                  ; (palsize 16 * 2 values)
                                                ; +1: size of change amount
                SUB     R9, SP
                ADD     1, R9                   ; +1: size of return address
                                                ; because we are not returning
                                                ; from here using RET but by
                                                ; using our own "manual" way
                MOVE    SP, R8
                MOVE    R8, R0                  ; R0 = data record pointer
                ADD     1, R0                   ; leave space for # of changes

                MOVE    VGA$PALETTE_ADDR, R1
                MOVE    VGA$PALETTE_DATA, R2
                MOVE    R10, R3                 ; R10 = start idx std pal
                MOVE    R11, R4                 ; R11 = start idx custom pal
                XOR     R7, R7                  ; R7 = pal changes amount

_FM_GCP_LOOP    MOVE    R3, @R1                 ; addr of std value of pal
                MOVE    @R2, R5                 ; R5 = std. val at index R3
                MOVE    R4, @R1                 ; addr of custom val. of pal
                MOVE    @R2, R6                 ; R6 = custom val. at idx R4

                CMP     R5, R6                  ; changed pal value?
                RBRA    _FM_GCP_NEXT, Z         ; no: next value                
                ADD     1, R7                   ; increase amount of changes
                MOVE    R4, @R0++               ; store changed entry: index..
                MOVE    R6, @R0++               ; .. and value
_FM_GCP_NEXT    ADD     1, R3                   ; next index: standard pal
                ADD     1, R4                   ; next index: custom pal
                CMP     R12, R3                 ; pal done?
                RBRA    _FM_GCP_LOOP, !Z        ; no: loop

                MOVE    R7, @R8                 ; store # of pal changes
                DECRB

                MOVE    R8, R12                 ; find return address on stack                 
                ADD     R9, R12
                SUB     1, R12
                ABRA    @R12, 1                 ; perform manual RET

; ----------------------------------------------------------------------------
; User-interface helper functions for FILE_MENU
; ----------------------------------------------------------------------------

; Print a string to the last line of the screen
;   R8: pointer to string
;   R11: returns x-pos behind message
_FM_PLL         INCRB
                MOVE    R8, R0
                MOVE    R9, R1
                MOVE    R10, R2
                MOVE    0, R9                   ; x-pos = first column
                MOVE    39, R10                 ; y-pos = last line of screen              
                MOVE    STR_CLR_LINE, R8        ; clear last line
                RSUB    PRINT_STR_AT, 1
                MOVE    R0, R8                  ; print prompt
                RSUB    PRINT_STR_AT, 1
                MOVE    R0, R8
                MOVE    R1, R9
                MOVE    R2, R10
                DECRB
                RET

; Show prompt and input data via keyboard incl. backspace support
;   R8: prompt
;   R9: input scratch buffer (zero terminator will be added)
;  R10: size of input scratch buffer (including zero terminator)
_FM_INPUT       SYSCALL(enter, 1)
                MOVE    R8, R0                  ; R0 = prompt
                MOVE    R9, R1                  ; R1 = input scratch buffer
                MOVE    R10, R2                 ; R2 = size of input scr. buf.
                SUB     1, R2                   ; leave space for 0-terminator
                RSUB    _FM_PLL, 1              ; print prompt from @R8
                MOVE    R11, R8                 ; x-pos = behind the message
                MOVE    39, R9
                SYSCALL(vga_moveto, 1)
                XOR     R4, R4                  ; char counter
_FM_INPUT_LOOP  RSUB    KBD_GETCHAR, 1
                CMP     KBD$ENTER, R8           ; ENTER = input done
                RBRA    _FM_INPUT_RET, Z
                CMP     KBD$BACKSPACE, R8       ; if no backspace ..
                RBRA    _FM_IL_NBS, !Z          ; .. continue
                CMP     0, R4                   ; handle backspace: anything..
                RBRA    _FM_INPUT_LOOP, Z       ; ..there already? no!
                SUB     1, R1                   ; yes: handle backspace:
                SUB     1, R4                   ; decrement scr. buf. ptr, ..
                SYSCALL(vga_getxy, 1)           ; ..char counter & cursor pos
                SUB     1, R8
                MOVE    R8, R5
                SYSCALL(vga_moveto, 1)
                MOVE    STR_LS_SPACE, R8
                RSUB    LOCAL_PUTS, 1
                MOVE    R5, R8
                SYSCALL(vga_moveto, 1)
                RBRA    _FM_INPUT_LOOP, 1
_FM_IL_NBS      CMP     R4, R2                  ; buffer full?
                RBRA    _FM_INPUT_LOOP, Z       ; ignore char
                RSUB    LOCAL_PUTC, 1
                MOVE    R8, @R1++               ; store in scratch buffer
                ADD     1, R4                   ; character counter
                RBRA    _FM_INPUT_LOOP, 1
_FM_INPUT_RET   MOVE    0, @R1                  ; add zero terminator
                SYSCALL(leave, 1)
                RET

; Check if the identifier is legal, i.e. at least one legal character long
; Legal characters are: characters, numbers, underscore
;   R8: pointer to identifier
;   Carry flag: 0 = illegal, 1 = legal
_FM_CHKID       INCRB
                MOVE    R8, R0                  ; save R8
                MOVE    R0, R1
                MOVE    R9, R2
                SYSCALL(strlen, 1)              ; 0 characters are illegal
                CMP     0, R9
                RBRA    _FM_CHKID_ILL, Z
_FM_CHKID_LOOP  MOVE    @R1++, R8
                RBRA    _FM_CHKID_LEGAL, Z      ; end of string reached                
                MOVE    'A', R9                 ; check [A..Z]
                MOVE    'Z', R10
                ADD     1, R10
                SYSCALL(in_range_u, 1)
                RBRA    _FM_CHKID_LOOP, C
                MOVE    '0', R9                 ; check [0..9]
                MOVE    '9', R10
                ADD     1, R10
                SYSCALL(in_range_u, 1)
                RBRA    _FM_CHKID_LOOP, C
                CMP     '_', R8                 ; check underscore _
                RBRA    _FM_CHKID_LOOP, Z
_FM_CHKID_ILL   AND     0xFFFB, SR              ; illegal char: clear carry ..
                RBRA    _FM_CHKID_RET, 1        ; .. and return
_FM_CHKID_LEGAL OR      4, SR                   ; everything legal: set carry
_FM_CHKID_RET   MOVE    R0, R8                  ; restore R8
                MOVE    R2, R9                  ; restore R9
                DECRB
                RET

; ****************************************************************************
; PRINT_24BIT_RGB
;    Print 24-bit RGB version of the 15-bit version stored in R8
; ****************************************************************************

PRINT_24BIT_RGB SYSCALL(enter, 1)

                MOVE    _PED_RGB, R0            ; R0 = index to LUT
                MOVE    3, R3
                MOVE    R8, R4

_P24B_LOOP      AND     @R0, R8
                ADD     3, R0                   ; how much do we need to SHR?
                SHR     @R0++, R8               ; C is zero here due to ADD
                MOVE    0x083A, R9              ; conversion: 15 to 24 bit:
                SYSCALL(mulu, 1)                ; multiply by 0x083A and ..
                AND     0xFFFB, SR              ; clear C (shift in '0')                
                SHR     8, R10                  ; .. then SHR 8
                MOVE    R10, R8
                SYSCALL(PRINT_2HEXNIBS, 1)
                ADD     4, R0
                MOVE    R4, R8
                SUB     1, R3
                RBRA    _P24B_LOOP, !Z

                SYSCALL(leave, 1)
                RET

; ****************************************************************************
; PRINT_2HEXNIBS
;    Print the lower byte of R8 as two hex nibbles at the current cursor pos
; ****************************************************************************

PRINT_2HEXNIBS  SYSCALL(enter, 1)

                MOVE    R8, R0
                AND     0x00FF, R0              ; mask upper bits
                MOVE    R0, R1
                AND     0xFFFB, SR              ; clear C (shift in '0')s                
                SHR     4, R1                   ; hi-nibble
                AND     0x000F, R0              ; lo-nibble

                MOVE    HEX_DIGITS, R2          ; look-up chars for nibbles
                MOVE    R2, R3
                ADD     R1, R2                  ; char for hi-nibble
                ADD     R0, R3                  ; char for lo-nibble

                MOVE    @R2, R8
                RSUB    LOCAL_PUTC, 1
                MOVE    @R3, R8
                RSUB    LOCAL_PUTC, 1

                SYSCALL(leave, 1)
                RET

; ****************************************************************************
; WORD2HEXSTR
;    Convert a word into its hexadecimal zero-terminated string representation
;    R8: word
;    R9: pointer to 5 words of memory
; ****************************************************************************

WORD2HEXSTR     INCRB

                MOVE    4, R0                   ; constant for nibble shifting
                MOVE    R0, R4                  ; set loop counter to four
                MOVE    R8, R5                  ; for restoring R8 later
                MOVE    HEX_DIGITS, R1          ; pointer to list of nibbles

_W2HEX_LOOP1    MOVE    R1, R2                  ; scratch copy nibble ptr
                MOVE    R8, R3                  ; local copy of input R8
                AND     0x000F, R3              ; only the four LSBs
                ADD     R3, R2                  ; adjust ptr to desired nibble
                MOVE    @R2, @--SP              ; save the ASCII char on stack
                SHR     4, R8                   ; shift R8 four places right
                                                ; (C is 0 due to ADD)
                SUB     1, R4                   ; decrement loop counter
                RBRA _W2HEX_LOOP1, !Z           ; continue with the next nib.


                MOVE    R0, R4                  ; init loop counter
                MOVE    R9, R7                  ; target pointer
_W2HEX_LOOP2    MOVE    @SP++, @R7++            ; fetch char from stack
                SUB     1, R4                   ; decrement loop counter
                RBRA    _W2HEX_LOOP2, !Z        ; continue with the next char
                MOVE    0, @R7                  ; zero terminator

                MOVE    R5, R8                  ; restore R8
                DECRB
                RET

; ****************************************************************************
; KBD_GETCHAR
;    Read a key from the PS2/USB keyboard, no matter where STDIN points to.
;    R8: character read (lower 8 bits) or special key (higher 8 bits)
; ****************************************************************************

KBD_GETCHAR     INCRB
                MOVE    IO$KBD_STATE, R0        ; R0: addr of status register
                MOVE    IO$KBD_DATA, R1         ; R1: addr of receiver reg.
_KBD_GETC_LOOP  MOVE    @R0, R2                 ; Read status register
                AND     KBD$NEW_ANY, R2         ; Bit 1: special, Bit 0: ASCII
                RBRA    _KBD_GETC_LOOP, Z       ; Loop until character recvd
                MOVE    @R1, R8                 ; Get the character
                DECRB
                RET

; ****************************************************************************
; KBD_GET2DGN
;    Read a two digit number from the PS2/USB keyboard
;    R8: (write) default in case ESC is pressed; (read): number entered
;    R9: start x for cursor and outputs
;    R10: start y for cursor and output
;    (currently hardcoded to 2 digits, but can be easily extended to up to
;    4 digits by adjusting the "CMP 2, R3" command and the BASE10 constants)
; ****************************************************************************

BASE10          .DW     10, 1

KBD_GET2DGN     INCRB

                MOVE    R8, R6                  ; R6: remember default

                MOVE    VGA$CR_X, R0            ; R0: hw cursor X
                MOVE    VGA$CR_Y, R1            ; R1: hw cursor Y
                MOVE    VGA$CHAR, R2            ; R2: print at hw cursor pos
                MOVE    R9, @R0                 
                MOVE    R10, @R1

                XOR     R3, R3                  ; R3: loop and base10 counter
                XOR     R4, R4                  ; R4: number that is entered

_KG2DGN_NEXT    RSUB    KBD_GETCHAR, 1

                CMP     KBD$ENTER, R8           ; enter pressed?
                RBRA    _KG2DGN_CHECK1, !Z      ; no: continue processing
                MOVE    R7, R4                  ; yes: use preserved digit
                RBRA    _KG2DGN_END, 1
  
_KG2DGN_CHECK1  CMP     KBD$ESC, R8             ; ESC pressed?
                RBRA    _KG2DGN_CHECK2, !Z      ; no: continue processing
                MOVE    R6, R4                  ; return default value
                RBRA    _KG2DGN_END, 1
                
_KG2DGN_CHECK2  CMP     47, R8                  ; ASCII value > 47?
                RBRA    _KG2DGN_NEXT, N         ; no: ignore key
                CMP     47, R8                  ; ASCII value = 47?
                RBRA    _KG2DGN_NEXT, Z         ; yes: ignore key
                CMP     58, R8                  ; ASCII value < 58?
                RBRA    _KG2DGN_NEXT, !N        ; no: ignore key

                ; print digit and move cursor to the right
                MOVE    R8, @R2
                ADD     1, @R0

                ; calculate decimal number
                MOVE    BASE10, R5              ; base10 multipliers
                ADD     R3, R5                  ; address right base
                SUB     48, R8                  ; convert ASCII to number
                MOVE    R8, R7                  ; preserve R8 in case of ENTER
                MOVE    @R5, R9                 ; retrieve base
                SYSCALL(mulu, 1)                ; R11|R10 = R8 x R9
                ADD     R10, R4                 ; R10 enough, 2 digits < 100

                ADD     1, R3                   ; next digit
                CMP     2, R3                   ; two digits entered
                RBRA    _KG2DGN_NEXT, !Z

_KG2DGN_END     MOVE    R4, R8

                DECRB
                RET

; ****************************************************************************
; UART_PUTS
;   Write a string to the UART, no matter where STDOUT points to.
;   R8: pointer to string
; ****************************************************************************

UART_PUTS       INCRB
                MOVE    R8, R0
                MOVE    R8, R1
_UARTPUTS_LOOP  MOVE    @R0++, R8
                RBRA    _UARTPUTS_RET, Z
                RSUB    UART_PUTCHAR, 1
                RBRA    _UARTPUTS_LOOP, 1
_UARTPUTS_RET   MOVE    R1, R8
                DECRB
                RET

; ****************************************************************************
; UART_PUTCHAR
;   Write a character to the UART, no matter where STDOUT points to.
;   R8: character to be sent
; ****************************************************************************

UART_PUTCHAR    INCRB                           ; Get a new register page
                MOVE    IO$UART_SRA, R0         ; R0: address of status register                
                MOVE    IO$UART_THRA, R1        ; R1: address of transmit register
_UART_PUTC_WAIT MOVE    @R0, R2                 ; read status register
                AND     0x0002, R2              ; ready to transmit?
                RBRA    _UART_PUTC_WAIT, Z      ; loop until ready
                MOVE    R8, @R1                 ; Print character
                DECRB                           ; Restore the old page
                RET                

; ****************************************************************************
; DRAW_WORKSPACE
;    * Prints the whole workspace (palette, strings, editing window)
;    * Sets up the following variables:
;      TILE_WS_X, TILE_WS_Y, TILE_WS_X_MAX, TILE_WS_Y_MAX
;    R8: 0 = default mode; 1 = font ed mode
; ****************************************************************************

DRAW_WORKSPACE  INCRB

                MOVE    R8, R7                  ; R7: mode selector

                ; print workspace strings
                MOVE    STR_HELLO, R8           ; welcome string: Top line
                XOR     R9, R9
                XOR     R10, R10
                RSUB    PRINT_STR_AT, 1
                MOVE    STR_CURCHAR, R8         ; selected character string
                MOVE    SELECTED_Y, R10
                RSUB    PRINT_STR_AT, 1
                CMP     1, R7                   ; font help or std. help?
                RBRA    _DRAW_WS_HM, !Z
                MOVE    STR_HELP_FONT, R8
                RBRA    _DRAW_WS_PH, 1
_DRAW_WS_HM     MOVE    STR_HELP_MAIN, R8       
_DRAW_WS_PH     MOVE    39, R10
                RSUB    PRINT_STR_AT, 1         ; help string: Bottom line

                ; VGA registers
                MOVE    VGA$CR_X, R0          
                MOVE    VGA$CR_Y, R1
                MOVE    VGA$CHAR, R2

                CMP     0, R7                   
                RBRA    _DRAW_WS_STD, Z
                MOVE    CHAR_ED_X, @R0
                MOVE    CHAR_ED_Y, @R1
                RBRA    _DRAW_WS_START, 1

                ; center tile editing box on the right side of workspace
                ; by setting the hardware cursor to the correct coordinate
_DRAW_WS_STD    MOVE    TILE_DX, R12
                MOVE    @R12, R3
                AND     0xFFFB, SR              ; clear C (shift in '0')                
                SHR     1, R3                   ; divide TILE_DX by 2 ...
                MOVE    TILE_CENTER_X, R4
                SUB     R3, R4                  ; ... and subtract from center
                MOVE    R4, @R0                 ; store to hw cursor
                MOVE    TILE_WS_X, R5           ; remember this as TILE_WS_X
                MOVE    R4, @R5
                MOVE    TILE_DX, R12
                ADD     @R12, R4                ; calculate TILE_WS_X_MAX
                SUB     1, R4
                MOVE    TILE_WS_X_MAX, R5       
                MOVE    R4, @R5
                SUB     1, @R0                  ; -1 because of border line
                MOVE    TILE_DY, R12
                MOVE    @R12, R3                ; TILE_DY ditto
                AND     0xFFFB, SR              ; clear C (shift in '0')                
                SHR     1, R3
                MOVE    TILE_CENTER_Y, R4
                SUB     R3, R4
                MOVE    R4, @R1
                MOVE    TILE_WS_Y, R5
                MOVE    R4, @R5
                MOVE    TILE_DY, R12
                ADD     @R12, R4
                SUB     1, R4
                MOVE    TILE_WS_Y_MAX, R5
                MOVE    R4, @R5
                SUB     1, @R1

_DRAW_WS_START  MOVE    TILE_DY, R12
                MOVE    @R12, R3                ; distance top to bottom
                ADD     1, R3

                ; draw upper and lower left corners
                MOVE    0x0086, @R2             ; draw upper-left corner
                ADD     R3, @R1
                MOVE    0x0083, @R2             ; draw lower-left corner

                ; draw upper and lower lines
                MOVE    TILE_DX, R12
                MOVE    @R12, R5                ; x-width of box
_DRAW_WS_NX_TB  ADD     1, @R0
                SUB     R3, @R1
                MOVE    0x008A, @R2             ; draw upper "-"
                ADD     R3, @R1
                MOVE    0x008A, @R2

                SUB     1, R5
                RBRA    _DRAW_WS_NX_TB, !Z

                ; draw upper and lower right corners
                ADD     1, @R0
                MOVE    0x0089, @R2             ; lower-right corner
                SUB     R3, @R1
                MOVE    0x008C, @R2             ; upper-right corner

                ; draw left and right lines
                MOVE    TILE_DX, R12
                SUB     @R12, @R0
                SUB     1, @R0
                ADD     1, @R1

                MOVE    TILE_DY, R12
                MOVE    @R12, R5
_DRAW_WS_NX_LR  MOVE    0x0085, @R2             ; draw left "|"
                MOVE    TILE_DX, R12
                ADD     @R12, @R0
                ADD     1, @R0
                MOVE    0x0085, @R2             ; draw right "|"
                MOVE    TILE_DX, R12
                SUB     @R12, @R0
                SUB     1, @R0
                ADD     1, @R1
                SUB     1, R5
                RBRA    _DRAW_WS_NX_LR, !Z

                DECRB
                RET

; ****************************************************************************
; LOCAL_PUTHEX
;   local version of puthex that always uses VGA, independent if the
;   stdin/stdout settings; the vga_moveto syscall sets the relevant position
;   R8: word
; ****************************************************************************

LOCAL_PUTHEX    SYSCALL(enter, 1)
                SWAP    R8, R8
                RSUB    PRINT_2HEXNIBS, 1
                SWAP    R8, R8
                RSUB    PRINT_2HEXNIBS, 1
                SYSCALL(leave, 1)
                RET

; ****************************************************************************
; LOCAL_PUTC
;   local version of putc that always uses VGA, independent if the
;   stdin/stdout settings; the vga_moveto syscall sets the relevant position
;   R8: char
; ****************************************************************************

LOCAL_PUTC      SYSCALL(enter, 1)
                SUB     1, SP
                MOVE    0, @SP
                SUB     1, SP
                MOVE    R8, @SP
                MOVE    SP, R8
                RSUB    LOCAL_PUTS, 1
                ADD     2, SP
                SYSCALL(leave, 1)
                RET

; ****************************************************************************
; LOCAL_PUTS
;   local version of puts that always uses VGA, independent if the
;   stdin/stdout settings; the vga_moveto syscall sets the relevant position
;   R8: pointer to zero terminated string
; ****************************************************************************

LOCAL_PUTS      SYSCALL(enter, 1)
                MOVE    R8, R0
                SYSCALL(vga_getxy, 1)           ; get monitor-cursor-coords
                MOVE    R9, R10                 ; y-coordinate
                MOVE    R8, R9                  ; x-coordinate
                MOVE    R0, R8                  ; pointer to string
                RSUB    PRINT_STR_AT, 1
                MOVE    R11, R8                 ; new x-coordinate w/o support
                                                ; for wrap-arounds
                MOVE    R10, R9                 ; current y-corrdinate
                SYSCALL(vga_moveto, 1)
                SYSCALL(leave, 1)
                RET

; ****************************************************************************
; PRINT_STR_AT
;   print a zero terminated string at x/y pos
;   only one-liners are allowed
;   a tab char \t designates that now a mask for inverting is following
;   R8: pointer to string
;   R9/R10: x/y pos
;   R11 (output): x-pos of last printed character plus one
; ****************************************************************************

PRINT_STR_AT    INCRB
                MOVE    VGA$CR_Y, R0            ; set hw cursor to y-pos
                MOVE    R10, @R0

                MOVE    VGA$CR_X, R0
                MOVE    VGA$CHAR, R1
                MOVE    R8, R3
                MOVE    R9, R4
                MOVE    R4, R5

_PRINT_STR_LOOP MOVE    R4, @R0                 ; set x-pos
                CMP     '`', @R3               ; inverting mask mode?
                RBRA    _PRINT_STR_INV, Z       ; yes
                MOVE    @R3, @R1                ; print character
                ADD     1, R4                   ; increase x-pos
                ADD     1, R3                   ; increase character pointer
                CMP     0, @R3                  ; string end?
                RBRA    _PRINT_STR_LOOP, !Z     ; no: continue printing
                RBRA    _PRINT_STR_END, 1

_PRINT_STR_INV  ADD     1, R3                   ; skip the backtick
_PRINT_STR_INV1 MOVE    R5, @R0
                CMP     'X', @R3                ; invert current position?
                RBRA    _PRINT_STR_INV2, !Z     ; no
                ADD     0x8800, @R1
_PRINT_STR_INV2 ADD     1, R3
                ADD     1, R5
                CMP     0, @R3
                RBRA    _PRINT_STR_INV1, !Z

_PRINT_STR_END  MOVE R4, R11
                DECRB
                RET

; ****************************************************************************
; DRAW_PALETTE
;   draw the whole character palette
; ****************************************************************************

DRAW_PALETTE    INCRB

                MOVE    LRU_FGBG, R7

                ; draw y axis legend
                MOVE    VGA$CR_Y, R0            
                MOVE    VGA$CR_X, R1
                MOVE    VGA$CHAR, R2
                MOVE    START_Y, R3
                MOVE    START_X, R4             ; one x col. distance between
                SUB     2, R4                   ; legend and content
                RSUB    DRAW_LEGEND, 1

                ; draw x axis legend
                MOVE    VGA$CR_X, R0
                MOVE    VGA$CR_Y, R1
                MOVE    VGA$CHAR, R2
                MOVE    START_X, R3
                MOVE    START_Y, R4             ; one y line distance between
                SUB     2, R4                   ; legend and content
                RSUB    DRAW_LEGEND, 1

                ; draw the 256 characters
                XOR     R8, R8                  ; current character: 0..255
                MOVE    START_Y, R4             ; initial y-position on screen

_DRAW_P_LY      MOVE    START_X, R3             ; x-starting pos. of each row
                XOR     R9, R9                  ; current x-counter: 0..15

_DRAW_P_LX      MOVE    R3, @R0                 ; cursor x-pos to hardware
                MOVE    R4, @R1                 ; dito cursor y-pos
                MOVE    R8, @R2                 ; print character on VGA
                MOVE    R7, R6
                ADD     R8, R6
                AND     0x00FF, @R2             ; delete old color
                ADD     @R6, @R2                ; apply LRU color

                ADD     2, R3                   ; skip one column
                ADD     1, R8                   ; next character
                ADD     1, R9                   ; x-counter: 0..15
                CMP     16, R9                  ; already more than 15?
                RBRA    _DRAW_P_LX, !Z          ; no: next column

                ADD     2, R4                   ; yes: next line
                CMP     256, R8                 ; already more than 255 chars?
                RBRA    _DRAW_P_LY, !Z          ; no: go on printing

                ; calculate PAL_WS_* variables
                MOVE    PAL_WS_X, R0
                MOVE    START_X, @R0
                MOVE    PAL_WS_X_MAX, R0
                MOVE    30, R1
                ADD     START_X, R1
                MOVE    R1, @R0
                MOVE    PAL_WS_Y, R0
                MOVE    START_Y, @R0
                MOVE    PAL_WS_Y_MAX, R0
                MOVE    30, R1
                ADD     START_Y, R1
                MOVE    R1, @R0

                DECRB
                RET

                ; draw one legend axis
                ; input registers:
                ; R0: variable dimension hardware register
                ; R1: constant dimension hardware register
                ; R2: VGA character print register
                ; R3: variable axis start position
                ; R4: constant axis start position
DRAW_LEGEND     XOR     R8, R8
_DRAW_LEG_LOOP  RSUB    MAKE_ASCII, 1
                MOVE    R3, @R0                 ; hardware cursor variable
                MOVE    R4, @R1                 ; hardware cursor constant
                MOVE    R9, @R2                 ; draw char
                ADD     1, R8                   ; increase character
                ADD     2, R3                   ; increase variable dimension
                CMP     16, R8                  ; 0 .. F printed?
                RBRA    _DRAW_LEG_LOOP, !Z      ; no: loop
                RET                             ; yes: return

                ; convert a number between 0 and 15 into the ascii value
                ; of the corresponding hex nibble
                ; IN: R8    number 0..15
                ; OUT: R9   ascii of corresponding hex nibble
MAKE_ASCII      CMP     10, R8                  ; R8 < 10?
                RBRA    _MASCII_LESS10, N       ; yes
                MOVE    55, R9
                ADD     R8, R9                  ; no: >= 10: A = ASCII 65
                RET

_MASCII_LESS10  MOVE    48, R9                  ; 0 = ASCII 48
                ADD     R8, R9
                RET


; ****************************************************************************
; CURSOR_ON and CURSOR_OFF
;   Convenience functions for cursor handling. Do not change any register.
; ****************************************************************************

CURSOR_ON       INCRB
                MOVE    VGA$STATE, R0
                OR      VGA$EN_HW_CURSOR, @R0 
                DECRB
                RET

CURSOR_OFF      INCRB
                MOVE    VGA$STATE, R0
                MOVE    VGA$EN_HW_CURSOR, R1
                NOT     R1, R1
                AND     R1, @R0
                DECRB
                RET

; ****************************************************************************
; VARIABLES
; ****************************************************************************

TILE_DX         .BLOCK 1
TILE_DY         .BLOCK 1

SELECTED_CHR    .BLOCK 1
SELECTED_PAL    .BLOCK 1
FONT_MODE       .BLOCK 1
FONT_ED_CX      .BLOCK 1                        
FONT_ED_CY      .BLOCK 1

CLIPBOARD       .BLOCK 12                       ; copy/paste CTRL+C/CTRL+V
INPUTSCRATCH    .BLOCK 50                       ; string input scratch buffer
INPUTSCRATCH_N  .EQU 50

; workspace boundaries in absolute screen coordinates: palette and tile
PAL_WS_X        .BLOCK 1
PAL_WS_Y        .BLOCK 1
PAL_WS_X_MAX    .BLOCK 1
PAL_WS_Y_MAX    .BLOCK 1
TILE_WS_X       .BLOCK 1
TILE_WS_Y       .BLOCK 1
TILE_WS_X_MAX   .BLOCK 1
TILE_WS_Y_MAX   .BLOCK 1

; table to store the last recently used fg/bg color combination per character
LRU_FGBG        .BLOCK 256
