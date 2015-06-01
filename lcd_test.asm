.include "m2560def.inc"
.include "lcd.asm"

ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16

ldi r22, 'a'
do_lcd_data_reg r22
inc r22
do_lcd_data_reg r22
inc r22
do_lcd_data_reg r22
ldi r22, 59
lcd_lte_99 r22

ldi r16, 12
ldi r17, 9
call lcd_time


halt:
	rjmp halt