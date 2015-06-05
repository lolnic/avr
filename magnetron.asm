; Driver for the fictional magnetron.
; Actually interfaces with the motor and LED drivers

.include "m2560def.inc"
.include "motor.asm"
.include "led.asm"

.dseg
	power_level_mem: .byte 1
	tick_mem: .byte 1
.cseg

.def power_level = r25
.def tick = r26
.equ LO = 1
.equ MD = 2
.equ HI = 3

jmp magnetron_init

; Set up the magnetron's data
magnetron_init:
	ldi r16, LO
	call magnetron_set_power_level
	call motor_off
	clr tick
	store tick
	jmp magnetron_eof

; Sets the power level of the magnetron
; power level must be one of LO, MD, HI
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

; Call to tell the magnetron that 250ms has passed
; May toggle the on/off state of the motor
magnetron_250ms_tick:
	push tick
	push power_level
	load power_level
	cpi power_level, HI
	breq on_tick

	load tick
	cp tick, power_level
	brlt on_tick
	jmp off_tick

	on_tick:
	call motor_on
	jmp magnetron_tick_return

	off_tick:
	call motor_off

	magnetron_tick_return:
	inc tick
	cpi tick, 4
	breq reset_tick
	jmp done_tick
	reset_tick:
	clr tick
	done_tick:
	store tick
	pop power_level
	pop tick 
	ret

; Turns on the magnetron
magnetron_on:
	push power_level
	load power_level

	motor:
	call motor_on

	pop power_level
	ret

; Turns off the magnetron
magnetron_off:
	call motor_off
	ret


magnetron_eof:
