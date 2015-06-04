.include "m2560def.inc"
.include "lcd.asm"
.include "keypad.asm"

.cseg

set_keypad_callback key_pressed

main:
	call poll_once
	jmp main

key_pressed:
	do_lcd_data_reg r16
	ret
