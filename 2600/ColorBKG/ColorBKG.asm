
	processor 6502
	seg code
	org $F000

START:
	sei
	cld
	ldx #$FF
	txs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clean all addresses contained within the zero page
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #0
	ldx #$FF
	sta $FF

MEMORY_CLEAN:
	dex
	sta $0,X
	bne MEMORY_CLEAN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the Background luminosity color to yellow (NTSC)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	lda #$AA	; Load the color value into the
			; A register.
	sta $09		; Store A into the bkgColor 
			; address.
	jmp START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill every location in our 4KB ROM.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
	.word START	
	.word START
	


