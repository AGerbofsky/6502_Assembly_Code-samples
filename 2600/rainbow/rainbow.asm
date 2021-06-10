
	processor 6502
	
	include "vcs.h"
	include "macro.h"

	seg code
	org $F000

START:
	sei
	cld
	ldx #$FF
	txs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clean all addresses contained within the zero page
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #0
	ldx #$FF
	sta $FF

MEMORY_CLEAN:
	dex
	sta $0,X
	bne MEMORY_CLEAN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NEXT_FRAME:
	lda #2		; same as binary value %00000010
	sta VBLANK	; turn on VBLANK
	sta VSYNC	; turn on VSYNC
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	sta WSYNC	; first scanline
	sta WSYNC	; second scanline
	sta WSYNC	; third scanline

	lda #0		; load the literal value of 
				; zero into the accumulator.
	sta VSYNC	; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommeded 37 scanlines of 
;; VBLNAK.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #37		; load the value of 37 into our
				; X register.
VERTICLE_BLANK:
	sta WSYNC	; tell WSYNC to wait for the 
				; next scanline.
	dex
	bne VERTICLE_BLANK

	lda #0		; load the value of zero into
				; the accumulator.
	sta VBLANK	; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #192			; counter for 192 visible 
						; scanlines
VISIBLE_SCANLINES:
	stx COLUBK			; store the value of the X
						; register into the BKG_COLOR
						; register, in the TIA.
	sta WSYNC			; wait for the next scanline
	dex
	bne VISIBLE_SCANLINES

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output the 30 OVERSCAN lines. we do this using our 
;; VBLANK, once again.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #2 				; turn on the VBLANK
	sta VBLANK	
	ldx #30

OVERSCAN:
	sta WSYNC			; wait for the next scanline
	dex
	bne OVERSCAN

	jmp NEXT_FRAME 		; goto the NEXT_FRAME label

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pad our remaining 4k of ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	org $FFFC
	.word START
	.word START
                                                                              
