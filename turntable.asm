.include "m2560def.inc"

.dseg
rotation_mem: .byte 1
direction_mem: .byte 1
waiting_mem: .byte 1
on_mem: .byte 1

.cseg

jmp turntable_init

rot: .db "-/|",0,"-/|",0

.equ FORWARDS = 1
.equ BACKWARDS = 2

.equ REVS_PER_MINUTE = 3
.equ SECONDS_PER_REV = 60/REVS_PER_MINUTE
.equ NUM_ROT_CHARS = 8
.equ QUARTER_SECONDS_PER_MOVE = SECONDS_PER_REV*4 / NUM_ROT_CHARS

.def on = r26
.def waiting = r27
.def rotation = r28
.def direction = r29

.macro turntable_status ; output register
	push zh
	push zl
	push rotation
	push r16
	load rotation

	clr r16
	ldi zh, high(rot<<1)
	ldi zl, low(rot<<1)
	add zl, rotation
	adc zh, r16

	lpm @0, Z

	pop r16
	pop rotation
	pop zl
	pop zh
.endmacro

turntable_init:
	clr rotation
	store rotation
	ldi direction, FORWARDS
	store direction
	clr waiting
	store waiting
	clr on
	store on
	jmp turntable_eof

rotate_forwards:
	load rotation
	cpi rotation, NUM_ROT_CHARS-1
	breq reset_forward_rot

	inc rotation
	store rotation
	ret

	reset_forward_rot:
	clr rotation
	store rotation
	ret

rotate_backwards:
	load rotation
	cpi rotation, 0
	breq reset_backward_rot

	dec rotation
	store rotation
	ret
	
	reset_backward_rot:
	ldi rotation, NUM_ROT_CHARS-1
	store rotation
	ret

turntable_250ms_tick:
	push on
	push waiting
	push rotation
	push direction

	; If the turntable is not on, it can't turn
	load on
	cpi on, 0
	breq end_turntable_tick

	; Check if it's time for the representation of the rotation to change
	load waiting
	inc waiting
	store waiting
	cpi waiting, QUARTER_SECONDS_PER_MOVE
	brne end_turntable_tick
	clr waiting
	store waiting

	; Rotate the turntable in the appropriate direction
	load direction
	cpi direction, FORWARDS
	breq f
	call rotate_backwards
	jmp end_turntable_tick
	f: call rotate_forwards

	end_turntable_tick:
	pop direction
	pop waiting
	pop rotation
	pop on
	ret

turntable_start:
	push on
	load on
	ldi on, 1
	store on
	pop on
	ret

turntable_stop:
	push on
	push direction
	push waiting
	load on
	load direction
	load waiting

	clr on
	store on

	clr waiting
	store waiting

	cpi direction, FORWARDS
	breq go_back
	ldi direction, FORWARDS
	jmp end_turntable_stop
	go_back: ldi direction, BACKWARDS

	end_turntable_stop:
	store direction
	pop waiting
	pop direction
	pop on
	ret

turntable_eof: