.include "m2560def.inc"

.equ OVERFLOWS_PER_CALLBACK = 7812
.def temp =r16


.dseg
TempCounter:
.byte 2 ; Temporary counter. Used to determine
; if one second has passed
timer_callback:
.byte 2


.cseg
jmp timer_eof

.macro clear
	push yl
	push yh
	push temp

	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp

	pop temp
	pop yh
	pop yl
.endmacro

.macro call_timer_callback
	push r17
	push zh
	push zl
	
	clr r17
	lds zh, timer_callback
	lds zl, timer_callback+1

	cp zl, r17
	cpc zh, r17
	breq nocall

	icall
	nocall:
	pop zl
	pop zh
	pop r17
.endmacro

.macro set_timer_callback; label
	push zh
	push zl
	push r16
	ldi zh, high(timer_callback)
	ldi zl, low(timer_callback)
	ldi r16, high(@0)
	st Z+, r16
	ldi r16, low(@0)
	st Z, r16
	pop r16
	pop zl
	pop zh
.endmacro

Timer0OVF: ; interrupt subroutine to Timer0
	;push temp ; Prologue starts.
	in temp, SREG
	push temp 
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r26
	push r25
	push r24 ; Prologue ends.

	; Load the value of the temporary counter.
	lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1 ; Increase the temporary counter by one.


	; Check if (r25:r24) = OVERFLOWS_PER_CALLBACK
	cpi r24, low(OVERFLOWS_PER_CALLBACK)
	ldi temp, high(OVERFLOWS_PER_CALLBACK)
	cpc r25, temp
	brne NotSecond

	clear TempCounter ; Reset the temporary counter.

	call_timer_callback

	rjmp EndIF
	NotSecond:
	; Store the new value of the temporary counter.
	sts TempCounter, r24
	sts TempCounter+1, r25
	EndIF:
	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop r26
	pop YL
	pop YH
	pop temp
	out SREG, temp
	;pop temp
	reti ; Return from the interrupt.

timer_on:
	push temp

	clear TempCounter
	ldi temp, 0b00000010
	out TCCR0B, temp ; Prescaling value=8
	ldi temp, 1<<TOIE0 ; =278 microseconds
	sts TIMSK0, temp ; T/C0 interrupt enable

	pop temp
	ret

timer_off:
	push temp
	ldi temp, 0
	out TCCR0B, temp
	sts TIMSK0, temp
	pop temp
	ret




timer_eof: