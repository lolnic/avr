; Useful macros

.include "m2560def.inc"

; Store a register in memory
; If the register is called x, then it will be stored
; at the label x_mem
; x_mem must be defined and be in the data segment
.macro store ; register_alias
	sts @0_mem, @0
.endmacro

; Loads a register stored by the store macro
.macro load ; register_alias
	lds @0, @0_mem
.endmacro