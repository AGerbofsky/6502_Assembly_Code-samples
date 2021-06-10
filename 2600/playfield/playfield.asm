

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

	ldx #$1C	; Load the value of yellow into the X-register.
	stx COLUPF	; Now store that into the COLUPF Register on the TIA.

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
;;;  Set the CTRLPF register to allow reflection of the playfield.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	lda #%00000001	; CTRLPF register (D0 means reflect the PF
        sta CTRLPF	; Store that binary sequence into the CTRLPF
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Now draw the 192 visible scanlines. This part is known as the KERNEL.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	stx PF0		; Set all of our player fields to #0
        stx PF1		;
        stx PF2		;
        
	REPEAT 7		; Now skip 7 scanlines, with no PF set
        	stx WSYNC
        REPEND
        
        lda #%11100000	; load the 8-bit pattern for PF0 in A
        sta PF0		; Store...
        lda #%11111111  ; load the 8-bit pattern for PF1-PF2 in A
        sta PF1		; Store...
        sta PF2
        REPEAT 7
        	stx WSYNC
        REPEND
        
        lda #%00100000   ; Generate the PF pattern for the next 164 lines
        sta PF0
        stx PF1
        stx PF2
        REPEAT 164
        	stx WSYNC
       	REPEND
        
        lda #%11100000	; load the 8-bit pattern for PF0 in A
        sta PF0		; Store...
        lda #%11111111  ; load the 8-bit pattern for PF1-PF2 in A
        sta PF1		; Store...
        sta PF2
        REPEAT 7
        	stx WSYNC
        REPEND
        
        ; Now finally, let us skip the last 7 lines by setting all PF values
        ; to zero.
        
        lda #%00000001	; CTRLPF register (D0 means reflect the PF
        sta CTRLPF	; Store that binary sequence into the CTRLPF
	
	stx PF0		; Set all of our player fields to #0
        stx PF1		;
        stx PF2		;
        
	REPEAT 7		; Now skip 7 scanlines, with no PF set
        	stx WSYNC
        REPEND
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Output 30 more VBLANK lines to handle the T.V., overscan. Thiw will 
;;;  complete our video signal generation.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       
       	ldy #2
       	sty VBLANK
       	REPEAT 30
        	sty WSYNC
        REPEND
        stx VBLANK
       		       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Jump to the begining of the frame generation code.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       
       jmp Start_Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Add the Reset/Recycle vectors for the CPU.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
        .word Begining
        .word Begining
