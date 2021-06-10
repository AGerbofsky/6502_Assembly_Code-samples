

	processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Necessary libraries, containig useful functions and	;;;
;;;	and macros that save Aidan time...			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include "vcs.h"
	include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Allocate an unitializatd data segment at location	;;;
;;;	$80 in which to store our "aliases". In this segment,   ;;;
;;;	we will have the location range of ( $80 : $FF ) to	;;;
;;;	work with. Some of the end will be reserved for the	;;;
;;;	STACK.							;;;
;;;								;;;
;;;		*NOTE: $80 to $FF is in the RIOT chip*.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg.u Variables	; Start the uninitialized segment
	org $80		; Begining of the RIOT chip.

P0_Height   byte	; Player 0's sprite height.
P0_YPos     byte	; Player 0's sprite YPosition.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Start reading from our ROM at location $F000		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg code	; Start the "main" code segment.
	org $F000	; Begining of cartridge ROM.

start:
	CLEAN_START	; Zero all the addresses in the STACK.

	ldx #$00	; Load the hex value of black
	stx COLUBK	; Store that value in the COLUBK register.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Initialize our variables from earlier.			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #180
	stx P0_YPos	; Store 180 into the address of P0_YPos.

	ldx #9
	stx P0_Height	; Store 9 into the address of P0_Height.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Define how the TIA will start a new frame, by		;;;
;;;	configuring our VBLANK and VSYNC registers.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_frame:
	ldy #2
	sty VBLANK
	sty VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Generate 3 lines of vertical syncronization.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	REPEAT 3
		stx WSYNC
	REPEND

	ldx #0
	stx VBLANK
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Generate 37 lines of verticle blank.			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	REPEAT 37
        	stx WSYNC
        REPEND
        
        stx VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Begin generation of our 192 visible scanlines.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #192

scanline:
	txa		; Transfer #192 to the Accumulator.
	sec		; Set the Sure Carry flag.
	sbc P0_YPos	; Subtract the P0 Y coordinate from the A.
	cmp P0_Height	; Test if we are within bounds of P0_Coor.
	bcc Load_Bitmap	; Branch "Load_Bitmap" sub-routine if Yes.
	lda #0		; Else... set Acc. to 0, exitiing loop.

Load_Bitmap:
	tay		; Transfer A to Y.

	lda P0_Bitmap,Y	; Load the Y'th index of P0_Bitmap.
	sta WSYNC	; Wait for the next scanline.
	sta GRP0	; Store the Bitmap slice into GRP0 reg.

	lda P0_Color,Y	; Load the X'th index of P0_Color.
	sta COLUP0	; Store the value of that slice into the
			; COLUP0 register.
	dex
	bne scanline	; Branch to the scanline sub-routine,
			; until done drawing.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Generate 30 lines of overscan. This is the end of	;;;
;;;	frame generation.					;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

overscan:
	ldy #2
	sty VBLANK

	REPEAT 30
		sty WSYNC
	REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Decrement the Y Position of Player 0, before moving	;;;
;;;	on to the next frame generation cycle.			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	dec P0_YPos	; dec decrements the value stored at a
			; specified memory address.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Jump back to the start of the frame generation		;;;
;;;	routine.						;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	jmp start_frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Player 0's sprite graphics look-up table.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0_Bitmap:
	.byte #%00000000
	.byte #%00101000
	.byte #%01110100
	.byte #%11111010
	.byte #%11111010
	.byte #%11111010
	.byte #%01101100
	.byte #%00110000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Player 0's sprite color look-up table.			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0_Color:
	.byte #$00
	.byte #$40
	.byte #$40
	.byte #$40
	.byte #$40
	.byte #$42
	.byte #$44
	.byte #$D2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Finish the cartridge ROM by adding the CPU reset	;;;
;;;	vectors to the start of the "main" code segment,	;;;
;;;	at the last 3-bytes ($FFFC - $FFFF).			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
	.word start
	.word start
