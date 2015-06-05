.include "m2560def.inc"

.def temp = r16

jmp led_init

led_init:
	ser temp
	out DDRC, temp
	out DDRE, temp
	jmp led_eof

; Turns on lower n lights
.macro led_set_lights ; n
	push temp
	ldi temp, (1<<@0)-1
	out PORTC, temp
	pop temp
.endmacro

.macro door_light_on
	push temp
	ser temp
	out PORTE, temp
	pop temp
.endmacro

.macro door_light_off
	push temp
	clr temp
	out PORTE, temp
	pop temp
.endmacro
	
led_eof: