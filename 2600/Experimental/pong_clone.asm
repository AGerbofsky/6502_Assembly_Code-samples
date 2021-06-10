


	processor 6502
        
        include "vcs.h"
        include "macro.h"
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Define an uninitialized segment for "aliasees" 		;;;
;;;	pertaining general game object positioning and other	;;; 
;;;	important data.						;;;
;;;								;;;
;;;	*Note: This segment demand "6-bytes"*.			;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg.u Variables
        org $80

	;; Aliases pertaining to sprite positioning and sizes

Paddle_Size	.byte
P0_YPos		.byte
P0_XPos		.byte
P1_YPos		.byte
P1_XPos		.byte
Vis_Scanlines	.byte
Ver_Blnk_Scnl	.byte
_Overscan	.byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Begining of our 4k Cartridge ROM. located at $F000.	;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg code
	org $F000

Start:
	sei
        cld
        
        ldx #$FF
        lda #$00
        txs
        tay	;; This will be helpful later on...
        
        ;; Begining or our RAM zeroing loop.
Zero:
	sta $00,X
        dex
	bne Zero
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Fill our Aliasees with the necessary data.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #192
        stx Vis_Scanlines

	ldx #7
        stx Paddle_Size
        
        ldx #37
        stx Ver_Blnk_Scnl
        
        ldx #30
        stx _Overscan
        
        ldx #180
        stx P0_YPos

	ldx #$FF	; Value of Yellow.
        stx $08		; Location of COLUPF register.
        
        ldx #$80	; Value of Blue.
        stx $09		; Location of COLUBK register.
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Enable playfield mirroring by configuring the		;;;
;;;	CTRLPF register.					;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
	ldx #%00000010
        stx $0A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Begin generating or frame. Start by configureing our 	;;;
;;;	VBLANK and VSYNC registers.				;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Frame:
	ldx #2
        
        ;; $01 and $00 is the location of VBLANK and VSYNC, 
        ;; respectively
        stx $01
        stx $00
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Now generate 3 lines of verticle syncronization.	;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        ldy Paddle_Size
        
        sty $02		;; Location of WSYNC
        sty $02
        sty $02
        
        ldx #0
        stx $01		;; Use that transfer from earlier to turn
        		;; off our VBLANK, located at $01.
                        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Now generate 37 lines of verticle blank.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx Ver_Blnk_Scnl
        lda #2
        
V_Blank:
	sta $02,X
        dex
        bne V_Blank
        
        sty $00
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Begin generating our 192 visible scanlines.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx Vis_Scanlines
        
Visible_Scanlines:
	txa
        sec
        sbc P0_YPos
        cmp Paddle_Size
        bcc Ld_Paddle_Bitmap
        lda #0
        
Ld_Paddle_Bitmap:
	tay
        
        lda Paddle_Bitmap,Y
        sta $02
        sta $1B
        
        lda P0_Colors,Y
        sta $06
        
        dex
        bne Visible_Scanlines
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Finish generating our frame by generating 30 lines	;;;
;;;	of overscan.						;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #2
        ldy _Overscan
        
        stx $01
Overscan:
	stx $03,Y
	bne Overscan
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Jump back to the very begining of our frame		;;;
;;;	generation, sub-routine.				;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	jmp Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Sub-routines pertaining to game object sprite 		;;;
;;;	bit-maps.						;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Paddle_Bitmap:
	org $FFE7
        
	.byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        .byte #%00011000	;	...##...
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Sub-routines pertaining to game object sprite 		;;;
;;;	bit-maps colors						;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0_Colors:
	org $FFEE
        
        .byte #$00
        .byte #$00
        .byte #$00
        .byte #$00
	.byte #$00
        .byte #%00
        .byte #%00
        
P1_Colors:
	org $FFF5
        
        .byte #$00
        .byte #$00
        .byte #$00
        .byte #$00
	.byte #$00
        .byte #%00
        .byte #%00        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Pad the end of our ROM with a reset vectors.		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC
        
	.word Start
        .word Start

