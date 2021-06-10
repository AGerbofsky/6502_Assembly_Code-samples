	
        processor 6502
        
        include "vcs.h"
        include "macro.h"
        
        ; Define an uninitialized segment of memory in which
        ; to store variable aliases necessary to our program.
        ; Begin this segment at the begining of our ZP.
        
        seg.u Variables
	org $80
        
P0_XPos	byte
	
        
	; Define the entry point for our program ROM cartridge.
    	seg Code
        org $F000
        
Start:
	; Begin the memory zeroing routine.
        CLEAN_START
        
        ; Set up of Game element colors among other housekeeping
        ; items.
        
        ; Load the value of our Background color and store it in
        ; the COLUBK register in the TIA.
        ldx #$00
        stx COLUBK
        
        ; Initiialize our player related aliasees.
        ldx #50
        stx P0_XPos
        
Frame_Generation:
	; Generate 3 lines of verticle sync. WSYNC is at $02 and 
        ; VSYNC is located at $00
        ldx #2
       	stx VBLANK
        sty VSYNC

        ; Load the value of zero at VSYNC. turning it off.
        REPEAT 3
                stx WSYNC
        REPEND

        sty WSYNC
        
        ; Use the VBLANK time to configure the player's horizontal
        ; position
        
        ; Load the Accumulator with the value of Player 0's 
        ; desired x location. then. The and operation ensures that
        ; the value in A is always positive.
        lda P0_XPos
        and #$7F
        
        ; Wait for the next scaneline. and clear the old 
        ; horizontal positon to zero (good practice).
        sta WSYNC
        sta HMCLR
        
        ; Set the carry enable flag to true before begining our
        ; "division".
        sec
       
XPos_Calculation:
	sbc #15
        bcs XPos_Calculation
        
        eor #7
        
        asl	; Adjust the remainder to the high nibble
        asl	; As HMP0 only operates on the high nibble.
        asl
        asl
        
        ; Store our calculation in the neccessary TIA registers.
        sta HMP0
        sta RESP0
        sta WSYNC
        sta HMOVE
        
        ; Now move one to generate our 37-2 scanlines of VBLANK.
        REPEAT 35
        	sta WSYNC
        REPEND
        
        ldx #0
        stx VBLANK 
        
        ; Move no to draw our 192 visible scanlines.
        
        REPEAT 60
        	stx WSYNC
        REPEND
        
        ; Index size of our bit map
        ldy 8
        
Bitmap:
     	
        lda P0_Bitmap,Y
     	sta GRP0
        
        lda P0_Color,Y
        sta COLUP0   

        sta WSYNC
        
        dey
        bne Bitmap
        
        ldy #0
        sty GRP0
        
        REPEAT 124
        	sty WSYNC
        REPEND
        
        ; Finish the frame generation by outputing 30 additional
        ; scanlines of verticle blank to handle our overscan.
        
Overscan:
	ldx #2
        stx VBLANK
        
        REPEAT 30
        	stx WSYNC
        REPEND
        
        ; Increment the X coordinate before the next frame begins
        ; generation.
        
        inc P0_XPos
        
        ; Finish our program code with a return to
        ; the Frame Generation subroutine.
        
        jmp Frame_Generation
       
	; Player 0 Bitmap image.
        
        
P0_Bitmap:
	
	byte #%00000000         ;       ........
        byte #%00010000         ;       ..#.....
        byte #%00001000         ;       ...#...
        byte #%00011100
        byte #%00110110
        byte #%00110110
        byte #%00111110
        byte #%00011100
        ; Player 0 Bit map colors
	
P0_Color:       
	
	byte #$00
        byte #$02
        byte #$02
        byte #$52
        byte #$52
        byte #$52
        byte #$52
        byte #$52

    	
        ; Set our return vectors at the end of the ROM.
	org $FFFC
        word Start
        word Start
        