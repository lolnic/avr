; Motor driver

.include "m2560def.inc"
.def temp=r16

jmp motor_init

motor_init:
	ldi temp, 0b00001000
	sts DDRL, temp ; Bit 3 will function as OC5A.
	ldi temp, 0x00 ; the value controls the PWM duty cycle
	sts OCR5AL, temp
	clr temp
	sts OCR5AH, temp
	; Set the Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS50)
	sts TCCR5B, temp
	ldi temp, (1<< WGM50)|(1<<COM5A1)
	sts TCCR5A, temp
	jmp motor_eof

motor_on:
	push temp
	ldi temp, 0x09
	sts OCR5AL, temp
	pop temp
	ret

motor_off:
	push temp
	clr temp
	sts OCR5AL, temp
	pop temp
	ret

motor_eof: