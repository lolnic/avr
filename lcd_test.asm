.include "m2560def.inc"
.include "lcd.asm"

ldi r22, 'a'
do_lcd_data_reg r22
inc r22
do_lcd_data_reg r22
inc r22
do_lcd_data_reg r22

halt:
	rjmp halt