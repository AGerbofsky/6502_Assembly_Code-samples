
    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Library files more or less "in-use".            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    include "vcs.h"
    include "macro.h"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Define an uninitialized segmennt of memory      ;;;
;;; at memory address $80 (Zero-Page) for which     ;;;
;;; to store our game variable "aliasees"           ;;;
;;; as well as the pointers to our Sprite bitmaps   ;;;
;;; and color look-up tables.                       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg.u Variables
    org $80
	
JetXPos     .byte   ;   Player0's X-Position
JetYPos     .byte   ;   Player0's Y-Position
BomberXPos	.byte	;   Player1's X-Position
BomberYPos	.byte	;   Player2's Y-Position

JetSpritePtr        .word   ;   Ptr to P0 BTM LUT
JetColorPtr         .word   ;   Ptr to P0 CLR LUT
BomberSpritePtr     .word   ;   Ptr to P1 BTM LUT
BomberColorPtr      .word   ;   Ptr to P1 CLR LUT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Before we move on, define some useful contants. ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JET_HEIGHT    = 9   ; Scanline height of Jet Sprite.
BOMBER_HEIGHT = 9   ; Scnl height of Bomber Sprite.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set our Program Counter to the location of      ;;;
;;; our stored program ROM which is at memory       ;;;
;;; address $F000 and ends at $FFFF (4kB)           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg Code
    org $F000
    
Start:
    sei
    cld
    ldx #$FF
    lda #$00
    tay

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clear out all off the contents in the zero      ;;;
;;; page by padding every location with #$00.       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ZPClean:
    txs
    dex
    pha
    bne ZPClean

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This is where we will initialize the variables  ;;;
;;; Stored in our unitialized "Variables" segment,  ;;;
;;; at location $80 in the Zero-Page.               ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #10
    stx JetYPos 
    ldx #0
    stx JetXPos
    ldx #83
    stx BomberYPos
    ldx #53
    stx BomberXPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initialize sprite related pointers to their     ;;;
;;; correct look-up tables.                         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #<JetSprite     ; Load the lo-byte 
    stx JetSpritePtr
    ldx #>JetSprite     ; Now load the hi-byte
    stx JetSpritePtr+1  ; Move the Ptr forward a byte.

    ldx #<JetColor      ; Load the lo-byte 
    stx JetColorPtr
    ldx #>JetColor      ; Now load the hi-byte
    stx JetColorPtr+1   ; Move the Ptr forward a byte.

    ldx #<BomberSprite  ; Do the same thing here...
    stx BomberSpritePtr
    ldx #>BomberSprite
    stx BomberSpritePtr+1

    ldx #<BomberColor
    stx BomberColorPtr
    ldx #>BomberColor
    stx BomberColorPtr+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Begin the process of generating our displayed   ;;;
;;; Graphics frame. We will start this process by   ;;;
;;; Configuring the VBLANK and VSYNC TIA registers. ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Frame:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Now we can worry about our VBLANK and VSYNC...  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #2
    stx VBLANK      ; Turn on VBLANK($02)
    stx VSYNC       ; Turn on VSYNC($00)
    REPEAT 3
        stx WSYNC   ; WSYNC makes the TIA wait 3 lines.
    REPEND          ; Sync TIA with CPU

    ldy #0
    sty VSYNC       ; Now turn off VSYNC. 
    REPEAT 37
        sty WSYNC   ; Generate 37 lines of VBLANK
    REPEND
    sty VBLANK      ; Now turn off VBLANK as well. 
    
    nop
    nop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This is the part where we start putting the     ;;;
;;; 96  visible scanlines together. We will use the ;;;
;;; time just before the beam starts drawing the    ;;;
;;; scanlines to do positional calculations.        ;;;
;;; RACE THE BEAM!                                  ;;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VisibleScanlines:

    ldx #$84        ; Set the Background color to #$84.
    stx COLUBK
    ldx #$C2        ; Set the Playfield color to #$C2. 
    stx COLUPF
    ldx #%00000001  ; Set CTRLPF to mirror the playfield. 
    stx CTRLPF
    ldx #$F0        ; Set the PF0 pattern to #F0
    stx PF0
    ldx #$FC        ; Set the PF1 pattern to #$FC
    stx PF1
    ldx #0
    stx PF2         ; Set the PF2 bit pattern to #$0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Implement a "2-line" kernel. This will solve    ;;;
;;; some issues releated to "racing the beam".      ;;;
;;; Consider it our player handicap.                ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #100 ; 4 aditional scanlines HAD to be added.
.visibleLineLoop:
.InsideJetSprite:
    txa         ; X -> A
    sec                ; Set our carry flag before sub.
    sbc JetYPos        ; Test if current scanline is
    cmp JET_HEIGHT     ; within the bounds of JetSprite.
    bcc .DrawP0Sprite  ; If the result is less than the
                       ; Sprite height, call the draw
                       ; routine.
    lda #0
.DrawP0Sprite:
    tay             ; Only Y can work in ind mode.
    lda (JetSpritePtr),Y ; Load P0 bitmap from LUT
    sta WSYNC   ; Wait for a scanline
    sta GRP0    ; Set graphics for Player 0.
    
    lda (JetColorPtr),Y  ; Now load P0 Color LUT.
    sta COLUP0

.InsideBomberSprite:
    txa                ; X -> A
    sec                ; Set our carry flag before sub.
    sbc BomberYPos     ; Test if current scanline is
    cmp BOMBER_HEIGHT  ; within the bounds of JetSprite.
    bcc .DrawP1Sprite  ; If the result is less than the
                       ; Sprite height, call the draw
                       ; routine.
    lda #0
.DrawP1Sprite:
    tay             ; Only Y can work in ind mode.

    lda #%00000101
    sta NUSIZ1      ; Stretch Player 1 Sprite

    lda (BomberSpritePtr),Y ; Load P0 bitmap from LUT
    sta WSYNC            ; Wait for a scanline.
    sta GRP1             ; Set graphics for Player 0.
    
    lda (BomberColorPtr),Y  ; Now load P0 Color LUT.
    sta COLUP1

    dex 
    bne .visibleLineLoop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Generate our overscan.                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
    ldx #2
    stx VBLANK      ; Turn on VBLANK once more...

    REPEAT 30
        stx WSYNC
    REPEND

    sty VBLANK      ; Turn off VBLANK yet again...
    
    nop
    nop
    nop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Calculations to make before the initial VBLANK. ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda JetXPos
    ldy #0          ; For Player 0.
    jsr DefineObjectXPos ; Call Sub-R. to calculate
                         ; Player 0's X position.

    lda BomberXPos
    ldy #1          ; For Player 1.
    jsr DefineObjectXPos ; Call the same sub-routine
                         ; for Player 1's X Position.

    sta WSYNC
    sta HMOVE       ; Apply the horizontal offsets.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Process the Joystick Input for Player 0.        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000  ; Player 0 Joystick up.
    bit SWCHA       ; Test if for joystick up.
    bne CheckP0Down ; Move along if not true.
    inc JetYPos

CheckP0Down:
    lda #%00100000  ; Check if Joystick is down.
    bit SWCHA
    bne CheckP0Left
    dec JetYPos

CheckP0Left:
    lda #%01000000
    bit SWCHA
    bne CheckP0Right
    dec JetXPos

CheckP0Right:
    lda #%10000000
    bit SWCHA
    bne EndInputCheck
    inc JetXPos

EndInputCheck:  ; Fallback if there was no input.

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Jump back to the begining of fram generation.   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    jmp Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutine to handle the game objects           ;;;
;;; horizontal positioning with a "fine" offset.    ;;;
;;; Where A will be the target X-Coordinate         ;;;
;;; position and Y is the game object type. 1 being ;;;
;;; Player 1, 2 being Missle 0, 3 being Missle 1,   ;;;
;;; and 4 being Ball.                               ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DefineObjectXPos .subroutine
    sta WSYNC   ; Begin with a new scanline.
    sec         ; Set the carry flag.

.XPosCalculate:
    sbc #15     ; Sub 15 from the value in A.
    bcs .XPosCalculate ; Loop until Carry is triggered.
    
    eor #7      ; Set the offset range.
    asl         ; Shift the value to the left 4 times.
    asl         ; This places the value in the hi-
    asl         ; byte as HMOVE only uses the hi-byte.
    asl

    sta HMP0,Y  ; Store the adjusted value in the
    sta RESP0,Y ; HMxx and RExx registers.
    rts         ; Exit the sub-routine when finished.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Define the entry point for the Player0  "jet"   ;;;
;;; sprite look-up table(s).                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JetSprite:
    .byte #%00000000        ;       ........
    .byte #%00010100        ;       ...#.#..
    .byte #%01111111        ;       .#######
    .byte #%00111110        ;       ..#####.
    .byte #%00011100        ;       ...###..
    .byte #%00011100        ;       ...###..
    .byte #%00001000        ;       ....#...
    .byte #%00001000        ;       ....#...
    .byte #%00001000        ;       ....#...

;JET_HEIGHT = . - JetSprite

JetSpriteTurn:
    .byte #%00000000        ;       ........
    .byte #%00001000        ;       ....#...
    .byte #%00111110        ;       ..#####.
    .byte #%00011100        ;       ...###..
    .byte #%00011100        ;       ...###..
    .byte #%00011100        ;       ...###..
    .byte #%00001000        ;       ....#...
    .byte #%00001000        ;       ....#...
    .byte #%00001000        ;       ....#...

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$0E
    .byte #$08

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Define the entry point for the Player1          ;;;  
;;; "bomber" sprite look-up table(s).               ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BomberSprite:
    .byte #%00000000        ;       ........
    .byte #%00001000        ;       ....#...
    .byte #%00001000        ;       ....#...
    .byte #%00101010        ;       ..#.#.#.
    .byte #%00111110        ;       ..#####.
    .byte #%01111111        ;       .#######
    .byte #%00101010        ;       ..#.#.#.
    .byte #%00001000        ;       ....#...
    .byte #%00011100        ;       ...###..

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Pad the last three bytes of our ROM cartridge   ;;;
;;; with reset vectors, creates an infinate game-   ;;;
;;; loop.                                           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Start
    .word Start