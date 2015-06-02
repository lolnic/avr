.include "m2560def.inc"
.include "lcd.asm"

ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16

lcd_bot_right
do_lcd_data '/'
lcd_top_left
do_lcd_data 0
lcd_bot_left
do_lcd_data 'a'
lcd_top_right
do_lcd_data 'b'

;lcd_clear


halt:
	rjmp halt