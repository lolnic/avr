.include "m2560def.inc"
.include "motor.asm"
.include "led.asm"

.dseg
	power_level_mem: .byte 1
.cseg

.def power_level = r25
.equ LO = 1
.equ MD = 2
.equ HI = 3

jmp magnetron_init

magnetron_init:
	ldi r16, LO
	call magnetron_set_power_level
	call motor_off
	jmp magnetron_eof

magnetron_set_power_level: ; r16 = new power level
	push power_level
	mov power_level, r16
	store power_level
	cpi power_level, LO
	breq lo_
	cpi power_level, MD
	breq md_
	led_set_lights 8
	jmp end_set_power_level
	md_: led_set_lights 4
	jmp end_set_power_level
	lo_: led_set_lights 2
	end_set_power_level:
	pop power_level
	ret

magnetron_on:
	push power_level
	load power_level

	motor:
	call motor_on

	pop power_level
	ret

magnetron_off:
	call motor_off
	ret


magnetron_eof:
