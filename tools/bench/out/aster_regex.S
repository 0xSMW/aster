	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48
	stp	x20, x19, [sp, #16]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	add	x29, sp, #32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	w20, #16960                     ; =0x4240
	movk	w20, #15, lsl #16
	mov	w0, #16960                      ; =0x4240
	movk	w0, #15, lsl #16
	bl	_malloc
	cbz	x0, LBB0_10
; %bb.1:
	mov	x19, x0
	mov	x8, #0                          ; =0x0
	mov	w9, #1                          ; =0x1
	mov	w10, #32557                     ; =0x7f2d
	movk	w10, #19605, lsl #16
	mov	w11, #1                         ; =0x1
	mov	w12, #25185                     ; =0x6261
	movk	w12, #30819, lsl #16
LBB0_2:                                 ; =>This Inner Loop Header: Depth=1
	madd	w9, w9, w10, w11
	ubfiz	w13, w9, #3, #2
	lsr	w13, w12, w13
	strb	w13, [x19, x8]
	add	x8, x8, #1
	cmp	x20, x8
	b.ne	LBB0_2
; %bb.3:
	mov	x8, #0                          ; =0x0
	mov	x11, #0                         ; =0x0
	add	x9, x19, #1
	sub	x10, x20, #1
	b	LBB0_5
LBB0_4:                                 ;   in Loop: Header=BB0_5 Depth=1
	add	x11, x11, #1
	cmp	x11, x20
	b.ge	LBB0_9
LBB0_5:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_6 Depth 2
	ldrb	w12, [x19, x11]
	cmp	w12, #97
	b.ne	LBB0_4
LBB0_6:                                 ;   Parent Loop BB0_5 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	cmp	x10, x11
	b.eq	LBB0_9
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=2
	mov	x12, x11
	add	x11, x11, #1
	ldrb	w13, [x9, x12]
	cmp	w13, #98
	b.eq	LBB0_6
; %bb.8:                                ;   in Loop: Header=BB0_5 Depth=1
	cmp	w13, #99
	add	x11, x11, #1
	csinc	x11, x11, x12, eq
	cinc	x8, x8, eq
	cmp	x11, x20
	b.lt	LBB0_5
LBB0_9:
	str	x8, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #48
	ret
LBB0_10:
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #48
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%llu\n"

.subsections_via_symbols
