

    processor 6502
    seg code        
    org $F000       ; Designate the start of the Cartridge ROM
    
Start:
    sei             ; Disable Interrupts
    cld             ; Disable Binary Coded Decimal
    ldx #$FF        ; Load the value of the begining of RAM in the X register
    txs             ; Transfer that value to the Stack Pointer (S register)
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to clear out the entirety of the "Zero Page" Memory. 
;; ==================================================================
;; This is every addressable byte of memory for our RIOT chip. That is
;; all of the memory of the TIA Registers, as well as the PIA RAM.     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    lda #0           ; Load the literal value of zero into the A accumulator
    ldx #$FF         ; Load the literal hex value of the last position in
                     ; our "Zero Page" memory, into the X register.
CleanMemory:
    dex              ; Decrement the value stored in the X register by one, x--;
    sta $0,X         ; Store the literal value zero, into the location stored in
                     ; in the X register. This will decrease with the dex 
                     ; instruction.
    bne CleanMemory  ; Loop to the begining of the "CleanMemory" label, until the
                     ; P register returns high on the z flag. 
                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to calculate the Fibinacci sequence
;; ==============================================
;; Now that we have all locations in the "Zero Page", well zeroed... We can
;; now move on to something more interesting...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Variable set up for our calculation loop.

