.include "m2560def.inc"

jmp includes
.org OVF0addr
jmp Timer0OVF ; Jump to the interrupt handler for
; Timer0 overflow.

includes:
.include "lcd.asm"
.include "keypad.asm"
.include "timer.asm"
jmp main

.def mode = r20
.def minutes = r21
.def seconds = r22
.def lcd_dirty = r26
.equ ENTRY = 1
.equ RUNNING = 2
.equ PAUSED = 3
.equ FINISHED = 4

.dseg
start_dseg:
.byte 4
digits: .byte 4
numdigits: .byte 1
mode_mem: .byte 1
lcd_dirty_mem: .byte 1
minutes_mem: .byte 1
seconds_mem: .byte 1
end_dseg:
.cseg

main:
	set_keypad_callback key_pressed
	set_timer_callback timer_fired

	ldi zh, high(start_dseg)
	ldi zl, low(end_dseg)
	ldi r16, 0
	loop:
		st Z+, r16 
		cpi zl, low(end_dseg)
		breq memory_wiped
		jmp loop
	memory_wiped:

	ldi r16, 1
	sts lcd_dirty_mem, r16

	ldi r16, 0
	sts numdigits, r16

	ldi mode, ENTRY
	sts mode_mem, mode

	call set_min_sec

	poll_loop:
		call poll_keypad_once
		lds lcd_dirty, lcd_dirty_mem
		cpi lcd_dirty, 1
		breq render_lcd
		jmp poll_loop

		render_lcd:
			lcd_clear
			clr lcd_dirty
			sts lcd_dirty_mem, lcd_dirty

			lds minutes, minutes_mem
			lds seconds, seconds_mem
			push r16
			push r17
			mov r16, minutes
			mov r17, seconds
			call lcd_time
			pop r17
			pop r16
			jmp poll_loop
		

key_pressed:
	lds mode, mode_mem
	cpi mode, ENTRY
	breq entry_key_pressed
	cpi mode, RUNNING
	breq running_key_pressed
	cpi mode, PAUSED
	breq paused_key_pressed
	jmp finished_key_pressed

entry_key_pressed:
	push r17
	push xl
	push xh
	push r18
	lds r17, numdigits

	cpi r16, '0'
	brlt entry_nan
	cpi r16, '9'+1
	brge entry_nan

	;do_lcd_data 'a'
	cpi r17, 4
	breq end_entry_key
	;do_lcd_data 'b'

	ldi xl, low(digits)
	ldi xh, high(digits)
	clr r18
	add xl, r17
	adc xh, r18
	inc r17
	subi r16, '0'
	st X, r16
	sts numdigits, r17
	call set_min_sec

	jmp end_entry_key
	entry_nan:
	call timer_on

	end_entry_key:
	ldi lcd_dirty, 1
	sts lcd_dirty_mem, lcd_dirty
	pop r18
	pop xh
	pop xl
	pop r17
	ret

running_key_pressed:
	ret

paused_key_pressed:
	ret

finished_key_pressed:
	ret

set_min_sec: ; arg r17 = number of digits in time
	push r24
	push r18
	push yl
	push yh
	push r0

	do_lcd_data 'm'
	ldi yl, low(digits)
	ldi yh, high(digits)

	ldi r24, 4
	sub r24, r17
	sub yl, r24
	sbci yh, 0
	clr minutes
	clr seconds

	ldi r18, 10

	ldd r24, Y+0
	;lcd_lte_99 r24
	mul r24, r18
	mov minutes, r0
	ldd r24, Y+1
	;lcd_lte_99 r24
	add minutes, r24
	ldd r24, Y+2
	;lcd_lte_99 r24
	mul r24, r18
	mov seconds, r0
	ldd r24, Y+3
	;lcd_lte_99 r24
	add seconds, r24

	sts minutes_mem, minutes
	sts seconds_mem, seconds

	pop r0
	pop yh
	pop yl
	pop r18
	pop r24
	ret

timer_fired:
	ldi lcd_dirty, 1
	sts lcd_dirty_mem, lcd_dirty
	lds minutes, minutes_mem
	lds seconds, seconds_mem
	cpi seconds, 0
	breq do_minutes
	dec seconds
	sts seconds_mem, seconds
	ret
	do_minutes:
	cpi minutes, 0
	breq timer_zero
	ldi seconds, 59
	dec minutes
	sts minutes_mem, minutes
	sts seconds_mem, seconds
	ret
	timer_zero:
	call timer_off
	ret