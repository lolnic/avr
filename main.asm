.include "m2560def.inc"

jmp includes
.org OVF0addr
jmp Timer0OVF ; Jump to the interrupt handler for
; Timer0 overflow.

includes:
.include "lcd.asm"
.include "keypad.asm"
.include "timer.asm"

.cseg

set_keypad_callback key_pressed
set_timer_callback timer_fired

main:
	call poll_once
	jmp main

key_pressed:
	cpi r16, '*'
	breq start_timer
	cpi r16, '#'
	breq stop_timer
	ret
	start_timer:
		rcall timer_on
		ret
	stop_timer:
		rcall timer_off
		ret

timer_fired:
	do_lcd_data 0
	ret