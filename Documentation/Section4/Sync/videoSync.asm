
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NEXT_FRAME:
	lda #2		; same as binary #%00000010
	sta VBLANK	; turn on VBLANK
	sta VSYNC	; turn on VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	sta WSYNC	; first scanline
	sta WSYNC	; second scanlines
	sta WSYNC	; third scanlines

	lda #0
	sta VSYNC	; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output the 37 recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #37		; Load into the X register, the
			; sum of our VBLANK scanlines.
VERTICLE_BLANK:
	sta WSYNC	; Tell WSYNC to wait for the 
			; next scanline.
	dex		; Decrement the value stored in
			; the X register.
	bne		; Loop until the value stored
			; in X is equal too zero.

	lda #0		; Load the value of zero into
			; the Accumulator.
	sta VBLANK	; turn off VBLANK flag.

