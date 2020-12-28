!to "build/blink.bin"

*=$8000

reset:
 lda #$ff  	;; Load ff into the acc
 sta $6002 	;; Store contents of acc into address 6002 (data direction register b of via chip)

 lda #$50  	;; Load 50 into the acc

loop:
 ror		;; Rotate contents of acc to the right (some sort of bit shift)
 sta $6000	;; Send contents of acc to address 6000 (port b output register of via chip)

 jmp loop	;; Jump back to the loop

*=$fffc

!word reset ;; Set the program counter to the address of the reset label
!word $0000 ;; Some padding to fill the rest of the rom