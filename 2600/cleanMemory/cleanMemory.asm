
	processor 6502		; Define the Processor architecture
	seg code
	org $F000		; Define the code origin, in memory, @ $F000

Start:
	sei		      ; Disable the interrupts. All Atari cartridges must start with this
	cld		      ; Disable the BCD decimal math mode. Improves performance.
	ldx #$FF	      ; Load the X register with #$FF.
	txs		      ; Transfer the value of the X register to the S(stack) register.
                  	      ; Initialize the stack pointer, with the value of $FF.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the Zero Page region ($00 to $FF).
; Meaning the entire TIA register space as well as RAM.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #0		; A = 0
	ldx #$FF	; X = #$FF
	sta $FF		; makesure $FF is zeroed before the begining of "MemLoop"

MemLoop:
	dex		; Decrement the value of the X register.
	sta $0,X	; Store zero at address $0 + X
	bne MemLoop	; Loop until the Negative flag has been triggered.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill ROM size to exacly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
	.word Start    	   ; Reset vector @ $FFFC (where the program starts)
	.word Start	   ; Interrupt vector at $FFFE (unused by the VCS)
