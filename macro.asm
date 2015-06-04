.include "m2560def.inc"

.macro store ; register_alias
	sts @0_mem, @0
.endmacro

.macro load ; register_alias
	lds @0, @0_mem
.endmacro