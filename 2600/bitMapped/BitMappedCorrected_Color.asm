

	processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  List of used Include files. These contain time-saving macros and functions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include "vcs.h"
	include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Begin the code segment stored in our 4k ROM cartridge.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg code
	org $F000

Begining:
	CLEAN_START	; Call the Zero-page scrubbing function.

	ldx #$80	; Load the value of blue into the X-register.
	stx COLUBK	; Store that hex-color value into the COLUBK TIA reg.

	ldx #%1111	; Load the value of yellow into the X-register.
	stx COLUPF	; Now store that into the COLUPF Register on the TIA.
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  We set the TIA registers to the colors of P0 and P1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #$48	; Load the color value of P0 into the X-register.
        stx COLUP0	; Store it...
        
        ldx #$C6	; Load the color value or P! into the X-register.
        stx COLUP1	; Store it again...
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Set the CTRLPF register to allow reflection of the playfield.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ldy #%00000010	; CTRLPF register (D0 means reflect the PF
        sty CTRLPF	; Store that binary sequence into the CTRLPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Start a new frame by configuring the VBLANK and VSYCN T.V., signals.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Start_Frame:
	ldx #02		; ???
	stx VBLANK	; Turn on VBLANK.
	stx VSYNC	; Turn on VSYNC.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Generate the three lines of VSYNC.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	REPEAT 3	; This acts almost like a while loop
			; Dont forget to look at the documentation on this...

		stx WSYNC
	REPEND

	ldx #0
	stx VSYNC	; Now turn off VSYNC.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Let the TIA output the 37 recommended blanking lines for NTSC displays.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	REPEAT 37
		stx WSYNC
	REPEND
	
	stx VBLANK	; Turn off VBLANK
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Now draw the 192 visible scanlines. This part is known as the KERNEL.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Visible_Scanlines: ; Draw 10 blank scanlines at the top of the 192.
	REPEAT 10
        	stx WSYNC
        REPEND
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  After the 10 scanlines are drawn. Move on to display the bitmap of the
;;;  Player and Scoreboard sprites/missles.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
        ldy #0
        
Score_Board:
	lda Number_BitMap,Y
        sta PF1
        sta WSYNC
        
        iny
        cpy #10
        
        bne Score_Board
        
        stx PF1		; Turn off the playfield when finished...
        
        ; Now, we're gonna need another 50 scanlines...
        
        REPEAT 50
        	stx WSYNC
        REPEND
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  After the 10 scanlines are drawn. for the Player 0 Sprite.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ldy #0
        
Player0_Sprite:
	lda Player_BitMap,Y
        sta GRP0
        sta WSYNC
        
        iny
        cpy #10
        
        bne Player0_Sprite
       	
        stx GRP0		; Turn off Player 0...
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  After the 10 scanlines are drawn. for the Player 0 Sprite.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
        ldy #0
        
Player1_Sprite:
	lda Player_BitMap,Y
        sta GRP1
        sta WSYNC
        
        iny
        cpy #10
        
        bne Player1_Sprite
       
        stx GRP1		; Turn off Player 0...
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;;;  Wrap up the rest of the 102 Visible Scanlines (192-90).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
        REPEAT 102
        	stx WSYNC
        REPEND
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Output 30 more VBLANK lines to handle the T.V., overscan. Thiw will 
;;;  complete our video signal generation.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       
	REPEAT 30
        	stx WSYNC
        REPEND
       		              
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Jump to the begining of the frame generation code.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       

	jmp Start_Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  This code section defines the Player Bit-map look-up table.The data 
;;;  for this will be stored at $FFE8 in ROM.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFE8
        
Player_BitMap:
	.byte #%01111110	;  ###### 
        .byte #%11111111	; ########
        .byte #%10011001	; #  ##  #
        .byte #%11111111	; ########
        .byte #%11111111	; ########
        .byte #%11111111	; ########
        .byte #%10111101	; # #### #
        .byte #%10000001	; ##    ##
        .byte #%11111111	; ########
        .byte #%01111110	;  ######
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  This code section defines the Score Board Bit-map look-up table.The data 
;;;  for this will be stored at $FFF2 in ROM.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFF2
        
Number_BitMap:
	.byte #%00001110	; ########
        .byte #%00001110	; ########
        .byte #%00000010	;      ###
        .byte #%00000010	;      ###
        .byte #%00001110	; ########
        .byte #%00001110	; ########
        .byte #%00001000	; ###
        .byte #%00001000	; ###
        .byte #%00001110	; ########
        .byte #%00001110	; ########

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Add the Reset/Recycle vectors for the CPU.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
        .word Begining
        .word Begining
