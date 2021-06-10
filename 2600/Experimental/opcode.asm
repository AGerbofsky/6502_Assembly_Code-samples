

    Processor 6502
    
    seg code
    org $F000

START_PROGRAM:
    hex 78      ; sei - Set Immediate Interrupt. Turn off.
    hex d8      ; cld - Set BCD bit. Turn BCD off.
    hex a2 ff   ; ldx immediate (2-bytes).  Load $ff into the X register.
    hex 9a      ; txs. Transfer the value of X into the S register.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Clean all addresses contained within the zero page
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    hex a9 00   ; lda immediate (2-bytes) - Load the value of #0 into A.
    hex a2 ff   ; ldx immediate (2-bytes) - Load the value of #$ into X.
    hex 85 ff   ; sta zero-page (3-bytes) - Store the value stored in the
                ; A register, at the zero-page location $ff. sta ram_FF.

CLEAN_MEMORY:
    hex ca      ; dex - Decrement the value stored in the X register (2-bytes).
    hex 95 00   ; sta - Zero-paged, with index of X (2-bytes). Store the 
                ; value of #0 at the location stored within the X register.
    hex d0 fb   ; bne - Relative (2-bytes). Add a relative offset, if the 
                ; value stored in the X register LEQ 0.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Start a new frame by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FRAME:
    hex a9 02   ; lda immediate (2-bytes). Load #2 into the A register.
    hex 85 01   ; sta Zero-page (3-bytes). Store the value of the A register
                ; into location $01 on the Zero-page, or the VBLANK TIA register.
                ; This action turns on the VBLANK signal.
    hex 85 00   ; sta Zero-page (3-bytes). Now store the value of the A register
                ; into location $00, or the VSYNC register on the TIA. Turns on
                ; VSYNC signal.
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Generate the 3 Vertiacal Sync scanlines for NTSC CRT displays.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    hex 85 02   ; sta - Store at Zero-page $02 (TIA WSYNC register) (3-bytes)
                ; from the value stored on the accumulator.
    hex 85 02   ; sta Zero-page (3-bytes) - Store the value contained within the
                ; A register, at the location of the TIA's WSYNC register, 2/3.
    hex 85 02   ; sta Zero-page (3-bytes) - Store the value of the A register
                ; into location $0 of the Zero-page, (WSYNC register on the TIA).
    
    hex a9 00   ; lda immediate (2-bytes). Store #$00 on the A register.
    hex 85 01   ; sta Zero-page (3-bytes). Store the value of the A register in
                ; the VSYNC register of the TIA. This turns the VSYNC signal off.
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Let the TIA generate the 37 VBLANK scanlines, recommended for NTSC displays.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    hex a2 25   ; ldx immediate (2-bytes) - Load the value of #37 into 
                ; the X register.
VERTICLE_BLANK:
    hex 85 02   ; sta Zero-page (3-bytes) - Store the value of the Acumulator
                ; into the $02 location of the Zero-page; store the value of
                ; the A register into the WSYNC register of the TIA.
    hex ca      ; dex Zero-paged with X index (2-bytes) - Decrement the value of
                ; the X register.
    hex d0 fb   ; bne relative (2-bytes) - Branch to the begnining of the 
                ; VERTICLE_BLANK label, relative to {X|X <= 0}.

    hex a9 00   ; lda immediate (2-bytes) - Load the value of #$0 into the A
                ; register.
    hex 85 01   ; sta Zero-page (3-bytes) - Store the value of the Accumulator
                ; into the TIA VBLANK register. This will turn the VBLNAK 
                ; flag off.
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    hex a2 c0   ; ldx immediate (2-bytes) - Load the value #192 into the X 
                ; register.

VISIBLE_SCANLINES:
    hex 86 09   ; stx Zero-page (3-bytes) - Store the value of the X register at
                ; the memory location $09 in Zero-page. This is the COLUBK 
                ; register of the TIA register.
    hex 85 02   ; sta Zero-page (3-bytes) - Store the value of the A register at
                ; the memory location $02 in Zero-page. This is the WSYNC 
                ; register of the TIA.
    hex ca      ; dex Zero-page with X index (2-bytes) - Decrement the value
                ; stored in the X register.
    hex d0 fb   ; Bne relative (2-bytes) - Branch to the begnining of the 
                ; VERTICLE_BLANK label, relative to {X|X <= 0}.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Output the 30 OVERSCAN lines. we do this using our 
;;  VBLANK, once again.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    hex a9 02   ; lda immediate (2-bytes) - Load the value of #$02 into the A
                ; register.
    hex 85 01   ; sta Zero-page (3-bytes) - Store the value of the a register 
                ; into the location $01 of Zero-page memory. This is the VBLANK 
                ; register of the TIA.
    hex a2 1e   ; ldx immediate (2-bytes) - Load the value of #30 into the X
                ; register

START_OVERSCAN:
    hex 85 02   ; sta Zero-page (3-bytes) - Store the value A register into the
                ; the $02 location of Zero-page memory. This is the WSYNC
                ; register on the TIA.
    hex ca      ; dex Zero-page, with X indexing (2-bytes) - Decrement the value
                ; stored in the X register.
    hex d0 fb       ; Bne relative (2-bytes) - Branch to the begnining of the 
                    ; VERTICLE_BLANK label, relative to {X|X <= 0}.
    hex 4c 10 f0    ; jmp absolute (3-bytes) - Jump to the START_FRAME label.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pad our remaining 4k of ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	org $FFFC
	.word START
	.word START
                                    