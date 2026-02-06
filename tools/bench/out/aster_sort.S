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
	mov	w22, #27128                     ; =0x69f8
	movk	w22, #24, lsl #16
	add	x0, x22, #8
	bl	_malloc
	cbz	x0, LBB0_53
; %bb.1:
	mov	x19, x0
	mov	x8, #0                          ; =0x0
	mov	w9, #1                          ; =0x1
	mov	x10, #32557                     ; =0x7f2d
	movk	x10, #19605, lsl #16
	movk	x10, #62509, lsl #32
	movk	x10, #22609, lsl #48
	mov	x11, #1                         ; =0x1
LBB0_2:                                 ; =>This Inner Loop Header: Depth=1
	madd	x9, x9, x10, x11
	str	x9, [x19, x8]
	add	x12, x8, #8
	cmp	x22, x8
	mov	x8, x12
	b.ne	LBB0_2
; %bb.3:
	add	x0, x22, #8
	bl	_malloc
	mov	x21, x0
	mov	w0, #2048                       ; =0x800
	bl	_malloc
	mov	x20, x0
	cbz	x21, LBB0_54
; %bb.4:
	cbz	x20, LBB0_54
; %bb.5:
	mov	w23, #3392                      ; =0xd40
	movk	w23, #3, lsl #16
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, x19
	mov	w9, #3392                       ; =0xd40
	movk	w9, #3, lsl #16
LBB0_6:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w10, [x8], #8
	ldr	x11, [x20, x10, lsl #3]
	add	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	subs	x9, x9, #1
	b.ne	LBB0_6
; %bb.7:
	mov	x8, #0                          ; =0x0
LBB0_8:                                 ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_8
; %bb.9:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_10:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x19, x8]
	and	x10, x9, #0xff
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x21, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_10
; %bb.11:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, #0                          ; =0x0
LBB0_12:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x21, x8
	ldrb	w9, [x9, #1]
	ldr	x10, [x20, x9, lsl #3]
	add	x10, x10, #1
	str	x10, [x20, x9, lsl #3]
	add	x9, x8, #8
	cmp	x22, x8
	mov	x8, x9
	b.ne	LBB0_12
; %bb.13:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_14:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_14
; %bb.15:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_16:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x21, x8]
	ubfx	x10, x9, #8, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x19, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_16
; %bb.17:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, x19
	mov	w9, #3392                       ; =0xd40
	movk	w9, #3, lsl #16
LBB0_18:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w10, [x8, #2]
	ldr	x11, [x20, x10, lsl #3]
	add	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	add	x8, x8, #8
	subs	x9, x9, #1
	b.ne	LBB0_18
; %bb.19:
	mov	x8, #0                          ; =0x0
LBB0_20:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_20
; %bb.21:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_22:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x19, x8]
	ubfx	x10, x9, #16, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x21, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_22
; %bb.23:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, #0                          ; =0x0
LBB0_24:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x21, x8
	ldrb	w9, [x9, #3]
	ldr	x10, [x20, x9, lsl #3]
	add	x10, x10, #1
	str	x10, [x20, x9, lsl #3]
	add	x9, x8, #8
	cmp	x22, x8
	mov	x8, x9
	b.ne	LBB0_24
; %bb.25:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_26:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_26
; %bb.27:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_28:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x21, x8]
	ubfx	x10, x9, #24, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x19, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_28
; %bb.29:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, x19
	mov	w9, #3392                       ; =0xd40
	movk	w9, #3, lsl #16
LBB0_30:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w10, [x8, #4]
	ldr	x11, [x20, x10, lsl #3]
	add	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	add	x8, x8, #8
	subs	x9, x9, #1
	b.ne	LBB0_30
; %bb.31:
	mov	x8, #0                          ; =0x0
LBB0_32:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_32
; %bb.33:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_34:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x19, x8]
	ubfx	x10, x9, #32, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x21, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_34
; %bb.35:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, #0                          ; =0x0
LBB0_36:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x21, x8
	ldrb	w9, [x9, #5]
	ldr	x10, [x20, x9, lsl #3]
	add	x10, x10, #1
	str	x10, [x20, x9, lsl #3]
	add	x9, x8, #8
	cmp	x22, x8
	mov	x8, x9
	b.ne	LBB0_36
; %bb.37:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_38:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_38
; %bb.39:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_40:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x21, x8]
	ubfx	x10, x9, #40, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x19, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_40
; %bb.41:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, x19
LBB0_42:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w9, [x8, #6]
	ldr	x10, [x20, x9, lsl #3]
	add	x10, x10, #1
	str	x10, [x20, x9, lsl #3]
	add	x8, x8, #8
	subs	x23, x23, #1
	b.ne	LBB0_42
; %bb.43:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_44:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_44
; %bb.45:
	mov	w8, #27128                      ; =0x69f8
	movk	w8, #24, lsl #16
LBB0_46:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x19, x8]
	ubfx	x10, x9, #48, #8
	ldr	x11, [x20, x10, lsl #3]
	sub	x11, x11, #1
	str	x11, [x20, x10, lsl #3]
	str	x9, [x21, x11, lsl #3]
	sub	x8, x8, #8
	cmn	x8, #8
	b.ne	LBB0_46
; %bb.47:
	mov	x0, x20
	mov	w1, #2048                       ; =0x800
	bl	_bzero
	mov	x8, #0                          ; =0x0
LBB0_48:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x21, x8
	ldrb	w9, [x9, #7]
	ldr	x10, [x20, x9, lsl #3]
	add	x10, x10, #1
	str	x10, [x20, x9, lsl #3]
	add	x9, x8, #8
	cmp	x22, x8
	mov	x8, x9
	b.ne	LBB0_48
; %bb.49:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_50:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x20, x8]
	add	x9, x10, x9
	str	x9, [x20, x8]
	add	x8, x8, #8
	cmp	x8, #2048
	b.ne	LBB0_50
LBB0_51:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [x21, x22]
	lsr	x9, x8, #53
	and	x9, x9, #0x7f8
	ldr	x10, [x20, x9]
	sub	x10, x10, #1
	str	x10, [x20, x9]
	str	x8, [x19, x10, lsl #3]
	sub	x22, x22, #8
	cmn	x22, #8
	b.ne	LBB0_51
; %bb.52:
	mov	x0, x21
	bl	_free
	b	LBB0_57
LBB0_53:
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
LBB0_54:
	cbz	x21, LBB0_56
; %bb.55:
	mov	x0, x21
	bl	_free
LBB0_56:
	cbz	x20, LBB0_58
LBB0_57:
	mov	x0, x20
	bl	_free
LBB0_58:
	ldr	x8, [x19]
	str	x8, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	w0, #0                          ; =0x0
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
