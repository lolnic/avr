; LCD driver
; Initialises the LCD and provides helper methods for
; interacting with the LCD and formatting strings and numbers
; Assumes:
;  * The stack is initialised

rcall lcd_init
rjmp eof

.dseg
	turn: .db "|/-",0
.cseg

.equ LCDCONTROLPORT = PORTA
.equ LCDCONTROLDDR = DDRA

.equ LCDDATAPORT = PORTF
.equ LCDDATADDR = DDRF

.include "m2560def.inc"

.macro do_lcd_command ; command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data ; data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data_reg ; data_reg
	push r16
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
	pop r16
.endmacro
.macro lcd_clear
	do_lcd_command 0b00000001
.endmacro

.macro lcd_lte_99 ; data_reg
	.def data_reg = @0
	; tens
	push data_reg
	push r31
	clr r31
	; while data_reg >= 10
	count_loop:
		cpi data_reg, 10
		brlt end_count_loop
		inc r31
		subi data_reg, 10
		rjmp count_loop
	end_count_loop:
	subi r31, -'0'
	subi data_reg, -'0'
	do_lcd_data_reg r31
	do_lcd_data_reg data_reg
	pop data_reg
	pop r31
	.undef data_reg
.endmacro

lcd_time: ; r16 = minutes
	      ; r17 = seconds
	lcd_lte_99 r16
	do_lcd_data ':'
	lcd_lte_99 r17
	ret

lcd_init:
	push r16
	ser r16
	out LCDDATADDR, r16
	out LCDCONTROLDDR, r16
	clr r16
	out LCDDATAPORT, r16
	out LCDCONTROLPORT, r16

	; init LCD
	do_lcd_command 0b00111000 ; function set 2x5x7
	rcall sleep_5ms ; wait for more than 4.1 ms
	do_lcd_command 0b00111000 ; function set 2x5x7
	rcall sleep_1ms ; wait for more than 100 microseconds
	do_lcd_command 0b00111000 ; function set 2x5x7
	do_lcd_command 0b00111000 ; function set 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink



	; create backslash character
	do_lcd_command 0b01000000
					do_lcd_data 0b00010000
	do_lcd_command 0b01000001
					do_lcd_data 0b00001000
	do_lcd_command 0b01000010
					do_lcd_data 0b00001000
	do_lcd_command 0b01000011
					do_lcd_data 0b00000100
	do_lcd_command 0b01000100
					do_lcd_data 0b00000100
	do_lcd_command 0b01000101
					do_lcd_data 0b00000010
	do_lcd_command 0b01000110
					do_lcd_data 0b00000010
	do_lcd_command 0b01000111
					do_lcd_data 0b00000001
	lcd_clear

	pop r16
	ret

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi LCDCONTROLPORT, @0
.endmacro
.macro lcd_clr
	cbi LCDCONTROLPORT, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out LCDDATAPORT, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out LCDDATAPORT, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out LCDDATADDR, r16
	out LCDDATAPORT, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out LCDDATADDR, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

eof: