.include "m2560def.inc"

jmp includes
.org OVF0addr
jmp Timer0OVF ; Jump to the interrupt handler for
; Timer0 overflow.

includes:
.include "macro.asm"
.include "lcd.asm"
.include "keypad.asm"
.include "timer.asm"
.include "turntable.asm"
.include "magnetron.asm"
jmp main

.def mode = r20
.def minutes = r21
.def seconds = r22
.def lcd_dirty = r26
.def power_level_updated = r26
.def numdigits = r17
.def timer_count = r17
.equ ENTRY = 1
.equ RUNNING = 2
.equ PAUSED = 3
.equ FINISHED = 4

.dseg
start_dseg:
.byte 4
digits: .byte 4
numdigits_mem: .byte 1
mode_mem: .byte 1
lcd_dirty_mem: .byte 1
minutes_mem: .byte 1
seconds_mem: .byte 1
timer_count_mem: .byte 1
power_level_updated_mem: .byte 1
end_dseg:
.cseg

power_level_str: .db "Set Power 1/2/3",0
done_str: .db "Done",0
remove_str: .db "Remove food",0

main:
	; Init callbacks
	set_keypad_callback key_pressed
	set_timer_callback timer_fired


	; zero memory
	ldi zh, high(start_dseg)
	ldi zl, low(start_dseg)
	ldi r16, 0
	loop:
		st Z+, r16 
		cpi zl, low(end_dseg)
		breq memory_wiped
		jmp loop
	memory_wiped:

	; The LCD needs to be rendered again
	ldi lcd_dirty, 1
	store lcd_dirty

	; we start in entry mode
	ldi mode, ENTRY
	store mode

	poll_loop:
		; Poll the keypad
		call poll_keypad_once

		; Check if the LCD needs to be rendered again
		load lcd_dirty
		cpi lcd_dirty, 1
		breq render_lcd
		jmp poll_loop

		render_lcd:
			lcd_clear
			clr lcd_dirty
			store lcd_dirty

			push mode
			load mode
			cpi mode, FINISHED
			brne continue_render
			lcd_print_str done_str
			lcd_bot_left
			lcd_print_str remove_str
			jmp poll_loop

			continue_render:

			load minutes
			load seconds

			push r16
			push r17
			mov r16, minutes
			mov r17, seconds
			call lcd_time
			pop r17
			pop r16
			
			lcd_top_right
			turntable_status r17
			do_lcd_data_reg r17

			jmp poll_loop

user_new_power_level:
	push power_level_updated

	cpi r16, '1'
	breq set_num
	cpi r16, '2'
	breq set_num
	cpi r16, '3'
	breq set_num
	cpi r16, '#'
	brne end_user_new_power_level
	jmp user_chose

	set_num:
		subi r16, '0'
		call magnetron_set_power_level

	user_chose:
	ser power_level_updated
	store power_level_updated
	set_keypad_callback key_pressed
	end_user_new_power_level:
	pop power_level_updated
	ret

get_new_power_level:
	push power_level_updated
	clr power_level_updated
	store power_level_updated
	set_keypad_callback user_new_power_level
	lcd_clear
	lcd_print_str power_level_str
	poll_loop_2:
		call poll_keypad_once
		load power_level_updated
		cpi power_level_updated, 0xFF
		brne poll_loop_2
	pop power_level_updated
	ret
		

normalise_time:
	push minutes
	push seconds

	load minutes
	load seconds

	normalise_loop:
		; We can't do anything if minutes is at the limit
		cpi minutes, 99
		breq end_normalise_time

		cpi seconds, 60
		brlt end_normalise_time
		subi seconds, 60
		inc minutes
		jmp normalise_loop


	end_normalise_time:
	store minutes
	store seconds

	pop seconds
	pop minutes
	ret

add_minute:
	push minutes
	load minutes
	inc minutes
	store minutes
	pop minutes
	ret

start:
	push r16
	push minutes
	push seconds
	push mode
	clr r16

	load minutes
	load seconds

	cp seconds, r16
	cpc minutes, r16
	brne go
	rcall add_minute
	go:
	ldi mode, RUNNING
	store mode
	call timer_on
	call turntable_start
	call magnetron_on
	pop mode
	pop r16
	pop seconds
	pop minutes
	ret

stop_entry:
	push numdigits
	clr numdigits
	store numdigits
	call set_min_sec
	pop numdigits
	ret

unpause:
	push mode
	ldi mode, RUNNING
	store mode
	call timer_on
	call turntable_start
	call magnetron_on
	pop mode
	ret

restart:
	push numdigits
	push mode
	clr numdigits
	store numdigits
	call set_min_sec
	ldi mode, ENTRY
	store mode
	pop mode
	pop numdigits
	ret

paused_key_pressed:
	cpi r16, '*'
	brne paused_notstar
	call unpause
	paused_notstar:
	cpi r16, '#'
	brne paused_nothash
	call restart
	paused_nothash:
	ret

finished_key_pressed:
	cpi r16, '#'
	brne noop
	push mode
	ldi mode, ENTRY
	store mode
	pop mode
	noop:
	ret

; Callback for when the keypad is pressed.
; The ascii value of the key hit is in r16
key_pressed:
	ldi lcd_dirty, 1
	store lcd_dirty
	; Jump to subroutine based on mode
	load mode
	cpi mode, ENTRY
	breq entry_key_pressed
	cpi mode, RUNNING
	breq running_key_pressed
	cpi mode, PAUSED
	breq paused_key_pressed
	jmp finished_key_pressed

entry_key_pressed:
	push numdigits
	push xl
	push xh
	push r18
	push mode
	load numdigits

	cpi r16, '0'
	brlt entry_nan
	cpi r16, '9'+1
	brge entry_nan

	cpi numdigits, 4
	breq end_entry_key

	ldi xl, low(digits)
	ldi xh, high(digits)
	clr r18
	add xl, numdigits
	adc xh, r18
	inc numdigits
	subi r16, '0'
	st X, r16
	store numdigits
	call set_min_sec

	jmp end_entry_key

	entry_nan:
	
	cpi r16, '*'
	brne entry_notstar
	rcall start

	entry_notstar:
	cpi r16, '#'
	brne entry_nothash
	rcall stop_entry

	entry_nothash:
	cpi r16, 'A'
	brne entry_nota
	rcall get_new_power_level

	entry_nota:

	end_entry_key:
	ldi lcd_dirty, 1
	store lcd_dirty

	pop mode
	pop r18
	pop xh
	pop xl
	pop r17
	ret

pause:
	push mode
	call timer_off
	call turntable_stop
	call magnetron_off
	ldi mode, PAUSED
	store mode
	pop mode
	ret

running_key_pressed:
	cpi r16, '*'
	brne running_notstar
	call add_minute
	
	running_notstar:
	cpi r16, '#'
	brne running_nothash
	rcall pause

	running_nothash:
	cpi r16, 'C'
	brne running_notc
	rcall add_30

	running_notc:
	cpi r16, 'D'
	brne running_notd
	rcall sub_30

	running_notd:

	ret

add_30:
	push seconds

	load seconds

	subi seconds, -30
	store seconds
	call normalise_time

	pop seconds
	ret

sub_30:
	push seconds
	push minutes

	load minutes
	load seconds

	cpi seconds, 30
	brge subtract

	cpi minutes, 1
	brlt end_sub_30 ; There is less than 30 seconds of time

	dec minutes
	subi seconds, -60

	subtract:

	subi seconds, 30
	store minutes
	store seconds

	call normalise_time

	end_sub_30:
	pop minutes
	pop seconds
	ret

set_min_sec: ; arg r17 = number of digits in time
	push r24
	push r18
	push yl
	push yh
	push r0

	ldi yl, low(digits)
	ldi yh, high(digits)

	ldi r24, 4
	sub r24, numdigits
	sub yl, r24
	sbci yh, 0
	clr minutes
	clr seconds

	ldi r18, 10

	ldd r24, Y+0
	mul r24, r18
	mov minutes, r0
	ldd r24, Y+1
	add minutes, r24
	ldd r24, Y+2
	mul r24, r18
	mov seconds, r0
	ldd r24, Y+3
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
	push lcd_dirty
	push timer_count
	push minutes
	push seconds
	push numdigits
	push mode

	call turntable_250ms_tick
	call magnetron_250ms_tick

	; Only continue if it's been one second
	load timer_count
	inc timer_count
	store timer_count
	cpi timer_count, 4
	breq one_second
	jmp timer_ret

	one_second:

	ldi lcd_dirty, 1
	store lcd_dirty
	clr timer_count
	store timer_count
	load minutes
	load seconds
	cpi seconds, 0
	breq do_minutes
	dec seconds
	store seconds
	jmp timer_ret
	do_minutes:
	cpi minutes, 0
	breq timer_zero
	ldi seconds, 59
	dec minutes
	store minutes
	store seconds
	jmp timer_ret
	timer_zero:
	call timer_off
	call turntable_stop
	call magnetron_off
	clr numdigits
	store numdigits
	ldi mode, FINISHED
	store mode

	timer_ret:
	pop mode
	pop numdigits
	pop seconds
	pop minutes
	pop timer_count
	pop lcd_dirty
	ret