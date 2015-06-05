; Keypad driver

.include "m2560def.inc"

.def row = r16 ; current row number
.def col = r17 ; current column number
.def rmask = r18 ; mask for current row during scan
.def cmask = r19 ; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def finalcol = r22
.def finalrow = r23
.equ PORTDIR = 0xF0 ; PD7-4: output, PD3-0, input
.equ INITCOLMASK = 0xEF ; scan from the rightmost column,
.equ INITROWMASK = 0x01 ; scan from the top row
.equ ROWMASK = 0x0F ; for obtaining input from Port D
.equ KEYPADPORT = PORTK
.equ KEYPADPIN = PINK
.equ KEYPADDDR = DDRK

.dseg
keypad_callback: .byte 2

.cseg

call init_keypad
jmp keypad_eof

; Call the callback for when a keypad button is pressed
.macro call_keypad_callback; char_pressed
	push r16
	mov r16, @0
	push r17
	push zh
	push zl

	clr r17
	lds zh, keypad_callback
	lds zl, keypad_callback+1

	cp zl, r17
	cpc zh, r17
	breq nocall

	icall
	nocall:
	pop zl
	pop zh
	pop r17
	pop r16
.endmacro

; Set up the callback
.macro set_keypad_callback; label
	push zh
	push zl
	push r16
	ldi zh, high(keypad_callback)
	ldi zl, low(keypad_callback)
	ldi r16, high(@0)
	st Z+, r16
	ldi r16, low(@0)
	st Z, r16
	pop r16
	pop zl
	pop zh
.endmacro

; Prepare the keypad for reading
init_keypad:
	push temp1
	ldi temp1, PORTDIR
	sts KEYPADDDR, temp1
	pop temp1
	ret

; Check if the keypad is being pressed
; if it isn't, return
; If it is, wait for the key to stop being pressed
; and call the callback function
poll_keypad_once:
	push row
	push col
	push rmask
	push cmask
	push temp1
	push temp2
	push finalrow
	push finalcol

	ser finalrow
	ser finalcol

	; Loop until a button is not being pressed
	debounce_poll:
		ldi cmask, INITCOLMASK ; initial column mask
		clr col ; initial column
		colloop:
			cpi col, 4
			breq debounced ; If all keys are scanned, exit.
			sts KEYPADPORT, cmask ; Otherwise, scan a column.
			
			; Slow down the scan operation.
			ldi temp1, 0xFF
			delay: dec temp1
			brne delay

			lds temp1, KEYPADPIN ; Read PORTA
			andi temp1, ROWMASK ; Get the keypad output value
			cpi temp1, 0xF ; Check if any row is low
			breq nextcol
			; If yes, find which row is low
			ldi rmask, INITROWMASK ; Initialize for row check
			clr row ; 

			rowloop:
				cpi row, 4
				breq nextcol ; the row scan is over.
				mov temp2, temp1
				and temp2, rmask ; check un-masked bit
				breq found_key ; if bit is clear, the key is pressed
				inc row ; else move to the next row
				lsl rmask
				jmp rowloop

			found_key:
			; We found a key that was pressed. Record it.
			mov finalrow, row
			mov finalcol, col
			jmp debounce_poll

			nextcol: ; if row scan is over
			lsl cmask
			inc col ; increase column value
			jmp colloop ; go to the next column
	debounced:
		mov row, finalrow
		mov col, finalcol
		; Check if finalrow is the default value
		; If it is, a key was never pressed
		cpi finalrow, 0xFF
		breq poll_ret


	; Convert the (row, col) coordinates to ascii chars
	convert:
		cpi col, 3 ; If the pressed key is in col.3
		breq letters ; we have a letter
		; If the key is not in col.3 and
		cpi row, 3 ; If the key is in row3,
		breq symbols ; we have a symbol or 0
		mov temp1, row ; Otherwise we have a number in 1-9
		lsl temp1
		add temp1, row
		add temp1, col ; temp1 = row*3 + col
		subi temp1, -'1' ; Add the value of character ‘1’
		jmp callback

	letters:
		ldi temp1, 'A'
		add temp1, row ; Get the ASCII value for the key
		jmp callback
	
	symbols:
		cpi col, 0 ; Check if we have a star
		breq star
		cpi col, 1 ; or if we have zero
		breq zero
		ldi temp1, '#' ; if not we have hash
		jmp callback
		star:
		ldi temp1, '*' ; Set to star
		jmp callback
		zero:
		ldi temp1, '0' ; Set to zero
		jmp callback

	callback: call_keypad_callback temp1

	poll_ret:
		pop finalcol
		pop finalrow
		pop temp2
		pop temp1
		pop cmask
		pop rmask
		pop col
		pop row
		ret

keypad_eof:
