!to "build/hello-world.bin"

PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

E  = %10000000
RW = %01000000
RS = %00100000

*=$8000

main:
 ldx #$ff 		; Set stack pointer to address 01ff
 txs

 lda #%11111111 ; Set all pins on port B to output
 sta DDRB

 lda #%11100000 ; Set top 3 pins on port A to output
 sta DDRA

 lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
 jsr lcd_instruction

 lda #%00000001 ; Clear display
 jsr lcd_instruction

 lda #%00000010 ; Return home
 jsr lcd_instruction

 lda #%00001111 ; Display on; cursor on; blink on
 jsr lcd_instruction

 lda #%00000110 ; Increment cursor; no display shift
 jsr lcd_instruction

 jsr print_message

 lda #" "		; Print ASCII character
 jsr print

 ldx #00 
 jmp print_ascii_table_forever

lcd_instruction:
 jsr lcd_wait
 sta PORTB
 lda #E 		; Toggle E bit to send instruction
 sta PORTA
 lda #0	
 sta PORTA
 rts

print:
 jsr lcd_wait
 sta PORTB
 lda #(RS | E) ; Toggle RS and E bits to write data
 sta PORTA
 lda #0
 sta PORTA
 jsr delay
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

print_message:
 pha
 phx
 ldx #0

print_message_loop:
 lda message,x
 beq print_message_break
 jsr print
 inx
 jmp print_message_loop

print_message_break:
 plx
 pla
 rts

lcd_wait:
 pha
 lda #%00000000 ; Set all pins on port B to input
 sta DDRB

lcd_busy:
 lda #RW
 sta PORTA
 lda #(RW | E) ; Toggle RW and E bits to read data
 sta PORTA
 lda PORTB
 and #%10000000
 bne lcd_busy
 lda #%11111111 ; Set all pins on port B to output
 sta DDRB
 pla
 rts

delay:
 phx
 phy
 ldx #127

delay_x_loop:
 ldy #0
 inx
 beq delay_break

delay_y_loop:
 iny
 beq delay_x_loop
 jmp delay_y_loop

delay_break:
 ply
 plx
 rts

message:
!text "Hello world =)"
!byte $00

*=$fffc

!word main 	   	; Set the program counter to the address of the main label
!word $0000   	; Some padding to fill the rest of the rom


