	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #96
	stp	x26, x25, [sp, #16]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #32]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #48]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #64]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #80]             ; 16-byte Folded Spill
	add	x29, sp, #80
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w25, -72
	.cfi_offset w26, -80
	mov	w0, #8                          ; =0x8
	bl	_malloc
	cbz	x0, LBB0_3
; %bb.1:
	mov	x19, x0
	bl	_pipe
	cbz	w0, LBB0_5
LBB0_2:
	mov	x0, x19
	bl	_free
LBB0_3:
	mov	w0, #1                          ; =0x1
LBB0_4:
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #32]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #96
	ret
LBB0_5:
	ldp	w21, w20, [x19]
	mov	w0, #4096                       ; =0x1000
	bl	_malloc
	cbz	x0, LBB0_11
; %bb.6:
	mov	x22, x0
	mov	w1, #97                         ; =0x61
	mov	w2, #4096                       ; =0x1000
	bl	_memset
	mov	x23, #0                         ; =0x0
	mov	w24, #2000                      ; =0x7d0
	mov	w25, #1                         ; =0x1
	b	LBB0_8
LBB0_7:                                 ;   in Loop: Header=BB0_8 Depth=1
	subs	x24, x24, #1
	b.eq	LBB0_10
LBB0_8:                                 ; =>This Inner Loop Header: Depth=1
	mov	x0, x20
	mov	x1, x22
	mov	w2, #4096                       ; =0x1000
	bl	_write
	stp	w21, w25, [sp, #8]
	add	x0, sp, #8
	mov	w1, #1                          ; =0x1
	mov	w2, #-1                         ; =0xffffffff
	bl	_poll
	cmp	w0, #1
	b.lt	LBB0_7
; %bb.9:                                ;   in Loop: Header=BB0_8 Depth=1
	mov	x0, x21
	mov	x1, x22
	mov	w2, #4096                       ; =0x1000
	bl	_read
	bic	x8, x0, x0, asr #63
	add	x23, x8, x23
	b	LBB0_7
LBB0_10:
	str	x23, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x22
	bl	_free
	mov	x0, x21
	bl	_close
	mov	x0, x20
	bl	_close
	mov	x0, x19
	bl	_free
	mov	w0, #0                          ; =0x0
	b	LBB0_4
LBB0_11:
	mov	x0, x21
	bl	_close
	mov	x0, x20
	bl	_close
	b	LBB0_2
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%llu\n"

.subsections_via_symbols
