!to "build/display-porta.bin"

;;;;;;;;;;;;;;;;
;;;; Offset ;;;;
;;;;;;;;;;;;;;;;

*=$8000

;;;;;;;;;;;;;;
;;;; Data ;;;;
;;;;;;;;;;;;;;

year_1:
!word 1955

year_2:
!word 1956

year_3:
!word 1982

player_1_label:
!text "P1:"
!byte $00

player_2_label:
!text "P2:"
!byte $00

;;;;;;;;;;;;;;;;;;;
;;;; Variables ;;;;
;;;;;;;;;;;;;;;;;;;

PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003
ACR = $600b
PCR = $600c
IFR = $600d
IER = $600e

E  = %10000000
RW = %01000000
RS = %00100000

string_ptr = $86

player_1_counter = $0200
player_2_counter = player_1_counter + 2

number = player_2_counter + 2
mod_10 = number + 2
string = mod_10 + 2

mem_cmp = string + 6
mem_start = mem_cmp + 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Instructions (main) ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main:
 ; Set stack pointer to address 01ff
 ldx #$ff 		
 txs

 jsr lcd_init

main_loop:
 lda PORTA
 and #%00000011
 sta number
 lda #0
 sta number + 1

 jsr number_to_string
 jsr print_string

 jsr lcd_return
 jmp main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Memory Utilities ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

fill_memory_from_x_to_y:
 sta mem_start,x
 stx mem_cmp
 cpy mem_cmp
 beq fill_memory_from_x_to_y_complete
 inx
 jmp fill_memory_from_x_to_y

fill_memory_from_x_to_y_complete:
 rts

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Print Utilities ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

print:
 jsr lcd_wait
 sta PORTB
 lda #(RS | E) ; Toggle RS and E bits to write data
 sta PORTA
 lda #0
 sta PORTA
 rts

print_memory_from_x_to_y:
 pha

print_memory_from_x_to_y_start:
 lda mem_start,x
 jsr print
 stx mem_cmp
 cpy mem_cmp
 beq print_memory_from_x_to_y_complete
 inx
 jmp print_memory_from_x_to_y_start

print_memory_from_x_to_y_complete:
 pla
 rts

print_ascii_table_forever:
 txa
 jsr print 
 inx
 jmp print_ascii_table_forever

print_random_chars_forever:
 lda $00,x
 jsr print 
 inx
 jmp print_random_chars_forever

print_string:
 pha
 phx
 ldx #0

print_string_loop:
 lda string,x
 beq print_string_break
 jsr print
 inx
 jmp print_string_loop

print_string_break:
 plx
 pla
 rts

print_string_ptr:
 pha
 phy
 ldy #0

print_string_ptr_loop:
 lda (string_ptr),y
 beq print_string_ptr_break
 jsr print
 iny
 jmp print_string_ptr_loop

print_string_ptr_break:
 ply
 pla
 rts

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; String Utilities ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

; Add the character in the A register to the beginning
; of the null-terminated variable `string`
push_char:
 ldy #0 ; Set character index to zero
 
push_char_loop:
 pha ; Push new character onto the stack
 lda string,y ; Get character at index and push it into X register
 tax 
 pla ; Pop new character off the stack
 sta string,y ; Store new character at the current index
 beq push_char_break
 iny ; Increment index
 txa ; Move previous character into A register
 jmp push_char_loop

push_char_break:
 rts

; Convert the `number` variable to a sequence of
; characters and store them in the `string` variable
number_to_string:
 pha
 phx
 phy

 ; Initialize string
 lda #0
 sta string

number_to_string_divide:
 ; Initialize the remainder to zero
 lda #0
 sta mod_10
 sta mod_10 + 1

 ; Initialize X register to 16 as a counter (for processing 2-byte numbers)
 ldx #16
 clc 

number_to_string_division_loop:
 ; Rotate dividend and remainder
 rol number
 rol number + 1
 rol mod_10
 rol mod_10 + 1

 ; a,y = dividend - divisor
 sec
 lda mod_10
 sbc #10
 tay ; Save low byte to Y register
 lda mod_10 + 1
 sbc #0
 bcc number_to_string_ignore_result
 sty mod_10
 sta mod_10 + 1

number_to_string_ignore_result:
 dex 
 bne number_to_string_division_loop

 ; Shift carry bit into number
 rol number
 rol number + 1

number_to_string_save_remainder:
 clc
 lda mod_10
 adc #"0"
 jsr push_char

 ; If number is not zero, continue dividing (via shift and subtraction)
 lda number
 ora number + 1
 bne number_to_string_divide
 
 ply
 plx
 pla
 rts

;;;;;;;;;;;;;;;;;;;;;;
;;;; LCD Uitities ;;;;
;;;;;;;;;;;;;;;;;;;;;;

lcd_init:
 ; Set all pins on port B to output
 lda #%11111111 
 sta DDRB

 ; Set top 3 pins on port A to output
 lda #%11100000 
 sta DDRA
 
 ; Set 8-bit mode; 2-line display; 5x8 font
 lda #%00111000 
 jsr lcd_instruction

 ; Display on; cursor off; blink off
 lda #%00001100 
 jsr lcd_instruction

 ; Increment cursor; no display shift
 lda #%00000110 
 jsr lcd_instruction

 jsr lcd_clear
 jsr lcd_return
 rts

lcd_clear:
 lda #%00000001 
 jsr lcd_instruction
 rts

lcd_return:
 lda #%00000010 
 jsr lcd_instruction
 rts

lcd_instruction:
 jsr lcd_wait
 sta PORTB
 lda #E ; Toggle E bit to send instruction
 sta PORTA
 lda #0	
 sta PORTA
 rts

lcd_wait:
 pha
 lda #%00000000 ; Set all pins on port B to input
 sta DDRB

lcd_wait_busy:
 lda #RW
 sta PORTA
 lda #(RW | E) ; Toggle RW and E bits to read data
 sta PORTA
 lda PORTB
 and #%10000000
 bne lcd_wait_busy
 lda #%11111111 ; Set all pins on port B to output
 sta DDRB
 pla
 rts

;;;;;;;;;;;;;;;;;;;;;;;
;;;; CPU Utilities ;;;;
;;;;;;;;;;;;;;;;;;;;;;;

delay:
 phx
 phy
 ldx #255
 ldy #40

delay_loop:
 dex
 bne delay_loop
 dey 
 bne delay_loop

 ply 
 plx
 rts

idle:
 jmp idle

;;;;;;;;;;;;;;;;
;;;; Offset ;;;;
;;;;;;;;;;;;;;;;

*=$fffa

;;;;;;;;;;;;;;
;;;; Data ;;;;
;;;;;;;;;;;;;;

!word nmi ; NMI interrupt handler
!word main ; Set the program counter to the address of the main label
!word irq ; IRQ interrupt handler