.dseg

pushbutton_callback: .byte 2

.cseg

jmp pushbutton_init

.macro call_pushbutton_callback
	push r17
	push zh
	push zl
	
	clr r17
	lds zh, pushbutton_callback
	lds zl, pushbutton_callback+1

	cp zl, r17
	cpc zh, r17
	breq nocall

	icall
	nocall:
	pop zl
	pop zh
	pop r17
.endmacro

.macro set_pushbutton_callback; label
	push zh
	push zl
	push r16
	ldi zh, high(pushbutton_callback)
	ldi zl, low(pushbutton_callback)
	ldi r16, high(@0)
	st Z+, r16
	ldi r16, low(@0)
	st Z, r16
	pop r16
	pop zl
	pop zh
.endmacro


pb0_int:
	push r16
	ldi r16, 0
	call_pushbutton_callback
	pop r16
	reti

pb1_int:
	push r16
	ldi r16, 1
	call_pushbutton_callback
	pop r16
	reti

pushbutton_init:

	ldi temp, (2 << ISC00) ; set INT0 as falling
	sts EICRB, temp ; edge triggered interrupt
	in temp, EIMSK ; enable INT0
	ori temp, (1<<INT0)
	ori temp, (1<<INT1)
	out EIMSK, temp

	jmp pushbutton_eof
	

pushbutton_eof: