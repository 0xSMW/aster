	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; -- Begin function main
lCPI0_0:
	.quad	0x0000000000000000              ; double 0
	.quad	0x8000000000000000              ; double -0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x22, x21, [sp, #16]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #32]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	mov	w21, #23040                     ; =0x5a00
	movk	w21, #610, lsl #16
	mov	w0, #23040                      ; =0x5a00
	movk	w0, #610, lsl #16
	bl	_malloc
	mov	x19, x0
	mov	w0, #23040                      ; =0x5a00
	movk	w0, #610, lsl #16
	bl	_malloc
	mov	x20, x0
	mov	w0, #1                          ; =0x1
	cbz	x19, LBB0_5
; %bb.1:
	cbz	x20, LBB0_5
; %bb.2:
Lloh0:
	adrp	x1, l_.memset_pattern@PAGE
Lloh1:
	add	x1, x1, l_.memset_pattern@PAGEOFF
	mov	x0, x19
	mov	w2, #23040                      ; =0x5a00
	movk	w2, #610, lsl #16
	bl	_memset_pattern16
Lloh2:
	adrp	x1, l_.memset_pattern.1@PAGE
Lloh3:
	add	x1, x1, l_.memset_pattern.1@PAGEOFF
	mov	x0, x20
	mov	w2, #23040                      ; =0x5a00
	movk	w2, #610, lsl #16
	bl	_memset_pattern16
	mov	x8, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	fneg.2d	v0, v0
Lloh4:
	adrp	x9, lCPI0_0@PAGE
Lloh5:
	ldr	q1, [x9, lCPI0_0@PAGEOFF]
	mov.16b	v2, v0
	mov.16b	v3, v0
LBB0_3:                                 ; =>This Inner Loop Header: Depth=1
	add	x9, x19, x8
	ldp	q4, q5, [x9]
	ldp	q6, q7, [x9, #32]
	add	x9, x20, x8
	ldp	q16, q17, [x9]
	ldp	q18, q19, [x9, #32]
	fmla.2d	v1, v16, v4
	fmla.2d	v0, v17, v5
	fmla.2d	v2, v18, v6
	fmla.2d	v3, v19, v7
	add	x8, x8, #64
	cmp	x21, x8
	b.ne	LBB0_3
; %bb.4:
	fadd.2d	v0, v0, v1
	fadd.2d	v0, v2, v0
	fadd.2d	v0, v3, v0
	faddp.2d	d0, v0
	str	d0, [sp]
Lloh6:
	adrp	x0, l_.str@PAGE
Lloh7:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	x0, x20
	bl	_free
	mov	w0, #0                          ; =0x0
LBB0_5:
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
	.loh AdrpLdr	Lloh4, Lloh5
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh6, Lloh7
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%f\n"

	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; @.memset_pattern
l_.memset_pattern:
	.quad	0x3ff0000000000000              ; double 1
	.quad	0x3ff0000000000000              ; double 1

	.p2align	4, 0x0                          ; @.memset_pattern.1
l_.memset_pattern.1:
	.quad	0x4000000000000000              ; double 2
	.quad	0x4000000000000000              ; double 2

.subsections_via_symbols
