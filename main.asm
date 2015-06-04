.include "m2560def.inc"
.include "lcd.asm"
.include "keypad.asm"

.cseg
ser r17
out DDRC, r17
ldi r17, 0b01010101
out PORTC, r17
main:
	call poll_once
	jmp main