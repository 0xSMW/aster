	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	mov	w0, #8388608                    ; =0x800000
	bl	_malloc
	mov	x19, x0
	mov	w0, #8388608                    ; =0x800000
	bl	_malloc
	mov	x20, x0
	mov	w0, #1                          ; =0x1
	cbz	x19, LBB0_13
; %bb.1:
	cbz	x20, LBB0_13
; %bb.2:
	mov	x21, #36045                     ; =0x8ccd
	movk	x21, #60757, lsl #16
	movk	x21, #45015, lsl #32
	movk	x21, #65361, lsl #48
	mov	x22, #32557                     ; =0x7f2d
	movk	x22, #19605, lsl #16
	movk	x22, #62509, lsl #32
	movk	x22, #22609, lsl #48
	mov	w23, #3392                      ; =0xd40
	movk	w23, #3, lsl #16
	mov	x0, x19
	mov	w1, #8388608                    ; =0x800000
	bl	_bzero
	mov	x0, x20
	mov	w1, #8388608                    ; =0x800000
	bl	_bzero
	mov	x9, #0                          ; =0x0
	mov	w10, #1                         ; =0x1
	mov	x8, #1                          ; =0x1
LBB0_3:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	madd	x10, x10, x22, x8
	orr	x11, x10, #0x1
	eor	x12, x11, x10, lsr #33
	mul	x12, x12, x21
	eor	x13, x12, x12, lsr #33
LBB0_4:                                 ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	and	x12, x13, #0xfffff
	ldr	x14, [x19, x12, lsl #3]
	add	x13, x12, #1
	cmp	x14, #0
	ccmp	x14, x11, #4, ne
	b.ne	LBB0_4
; %bb.5:                                ;   in Loop: Header=BB0_3 Depth=1
	str	x11, [x19, x12, lsl #3]
	str	x9, [x20, x12, lsl #3]
	add	x9, x9, #1
	cmp	x9, x23
	b.ne	LBB0_3
; %bb.6:
	mov	x9, #0                          ; =0x0
	mov	x10, #0                         ; =0x0
	mov	w11, #1                         ; =0x1
	b	LBB0_8
LBB0_7:                                 ;   in Loop: Header=BB0_8 Depth=1
	mov	x12, #0                         ; =0x0
	add	x9, x12, x9
	add	x10, x10, #1
	cmp	x10, x23
	b.eq	LBB0_12
LBB0_8:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_9 Depth 2
	madd	x11, x11, x22, x8
	orr	x12, x11, #0x1
	eor	x13, x12, x11, lsr #33
	mul	x13, x13, x21
	lsr	x14, x13, #33
	eor	w13, w14, w13
	and	x13, x13, #0xfffff
	ldr	x14, [x19, x13, lsl #3]
	cbz	x14, LBB0_7
LBB0_9:                                 ;   Parent Loop BB0_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	cmp	x14, x12
	b.eq	LBB0_11
; %bb.10:                               ;   in Loop: Header=BB0_9 Depth=2
	add	w13, w13, #1
	and	x13, x13, #0xfffff
	ldr	x14, [x19, x13, lsl #3]
	cbnz	x14, LBB0_9
	b	LBB0_7
LBB0_11:                                ;   in Loop: Header=BB0_8 Depth=1
	ldr	x12, [x20, x13, lsl #3]
	add	x9, x12, x9
	add	x10, x10, #1
	cmp	x10, x23
	b.ne	LBB0_8
LBB0_12:
	str	x9, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	x0, x20
	bl	_free
	mov	w0, #0                          ; =0x0
LBB0_13:
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%llu\n"

.subsections_via_symbols
