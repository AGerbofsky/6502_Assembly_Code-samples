	
    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Declare a segment of uninitialized memory at location $80 ;;;
;;; where our Zero-Page begins.                               ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg.u Variables
    org $80

P0XPos .byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Move to the begining of our program ROM Cartridge at      ;;;
;;; $F000.                                                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg Code
    org $F000

_Start:
    sei
    cld
    ldx #$FF
    lda #$00
    tay

_Zero:
    txs
    dex 
    pha 
    bne _Zero

    ldx #$80
    stx COLUBK

    ldx #$D0
    stx COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initialize our variables.                                 ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #10
    stx P0XPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Start a new frame by configuring the VBLANK and VSYNC     ;;;
;;; registers on the TIA.                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_Frame:
    ldx #2
    stx VBLANK
    stx VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Display 3 lines of VSYNC.                                 ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 3
        stx WSYNC
    REPEND

    ldx #0
    stx VSYNC       ; Turn off VSYNC. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Calculate Player 0's vertical position during the VBLANK. ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda P0XPos
    and #$7F
    sta WSYNC
    sta HMCLR

    sec

_XPosCalculate:
    sbc #15
    bcs _XPosCalculate
    
    eor #7
    asl 
    asl 
    asl 
    asl 

    sta HMP0
    sta RESP0
    sta WSYNC 
    sta HMOVE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Finish outputing the remaining 35 lines of VBLANK (37-2). ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 35
        sta WSYNC
    REPEND
    stx VBLANK
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Generate our 192 visible scanlines.                       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 160
        sta WSYNC
    REPEND

    ldx #17     ; This is the counter that will be used to draw
                ; the 17 rows of the P0_Bitmap. 
_DrawBitmap:
    lda P0Bitmap,X
    sta GRP0

    lda P0Color,X
    sta COLUP0

    sta WSYNC

    dex 
    bne _DrawBitmap

    ldy #0
    sty GRP0

    ldx #$FF
    stx PF0
    stx PF1
    stx PF2

    REPEAT 15
        stx WSYNC
    REPEND

    sty PF0
    sty PF1
    sty PF2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Output the remaining 30 VBLANK overscan lines, to         ;;;
;;; complete the generation of our frame                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_Overscan:
    ldx #2
    stx VBLANK

    REPEAT 30
        stx WSYNC
    REPEND
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Now test for changes in the value of our port1 joystick   ;;;
;;; input.                                                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_CheckP0Up:
    lda #%00010000
    bit SWCHA
    bne _CheckP0Down
    inc P0XPos

_CheckP0Down:
    lda #%00100000
    bit SWCHA
    bne _CheckP0Left
    dec P0XPos

_CheckP0Left:
    lda #%01000000
    bit SWCHA
    bne _CheckP0Right
    dec P0XPos

_CheckP0Right:
    lda #%10000000
    bit SWCHA
    bne _NoInput
    inc P0XPos

_NoInput:
    nop 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Once done with everything, jump back to the start of      ;;;
;;; The frame generation sub-routine.                         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    jmp _Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Look-up Table for Player 0's graphics bitmap.             ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Bitmap:
    byte #%00000000      ;       ........ 
    byte #%00010100      ;       ...#.#..
    byte #%00010100      ;       ...#.#.. 
    byte #%00010100      ;       ...#.#.. 
    byte #%00010100      ;       ...#.#.. 
    byte #%00010100      ;       ...#.#..
    byte #%00011100      ;       ...###..
    byte #%01011101      ;       .#.###.#
    byte #%01011101      ;       .#.###.#
    byte #%01011101      ;       .#.###.#
    byte #%01011101      ;       .#.###.#
    byte #%01111111      ;       .#######
    byte #%00111110      ;       ..#####. 
    byte #%00010000      ;       ...#....
    byte #%00011100      ;       ...###...
    byte #%00011100      ;       ...###...
    byte #%00011100      ;       ...###...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Look-up table for Player 0's pixel colors.                ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Color:
    byte #$00
    byte #$F6
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$3E
    byte #$3E
    byte #$3E
    byte #$24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Complete the ROM by adding reset vectors.                 ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC
    word _Start
    word _Start