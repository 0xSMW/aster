	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
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
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
	mov	w10, #44                        ; =0x2c
	mov	w11, #10                        ; =0xa
	mov	w12, #10000                     ; =0x2710
	mov	w13, #1000                      ; =0x3e8
	mov	w14, #-48000                    ; =0xffff4480
	mov	w15, #100                       ; =0x64
	mov	x16, #-5280                     ; =0xffffffffffffeb60
	mov	w17, #20000                     ; =0x4e20
Lloh0:
	adrp	x0, l_.str.1@PAGE
Lloh1:
	add	x0, x0, l_.str.1@PAGEOFF
	b	LBB0_2
LBB0_1:                                 ;   in Loop: Header=BB0_2 Depth=1
	add	x8, x1, x8
	add	x9, x9, #1
	cmp	x9, x17
	b.eq	LBB0_35
LBB0_2:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_5 Depth 2
                                        ;       Child Loop BB0_27 Depth 3
                                        ;       Child Loop BB0_31 Depth 3
                                        ;       Child Loop BB0_21 Depth 3
	mov	x1, #0                          ; =0x0
	mov	x4, #0                          ; =0x0
	b	LBB0_5
LBB0_3:                                 ;   in Loop: Header=BB0_5 Depth=2
	add	x2, x3, #1
	mov	x1, x4
LBB0_4:                                 ;   in Loop: Header=BB0_5 Depth=2
	add	x4, x2, #1
LBB0_5:                                 ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_27 Depth 3
                                        ;       Child Loop BB0_31 Depth 3
                                        ;       Child Loop BB0_21 Depth 3
	cmp	x4, #43
	b.gt	LBB0_1
; %bb.6:                                ;   in Loop: Header=BB0_5 Depth=2
	mov	x2, x4
	ldrb	w3, [x0, x4]
	cmp	x4, #36
	b.gt	LBB0_20
; %bb.7:                                ;   in Loop: Header=BB0_5 Depth=2
	sub	w4, w3, #48
	cmp	w3, #34
	ccmp	w4, #10, #0, ne
	b.lo	LBB0_20
; %bb.8:                                ;   in Loop: Header=BB0_5 Depth=2
	add	x4, x0, x2
	ldrb	w5, [x4, #1]
	sub	w6, w5, #48
	cmp	w5, #34
	ccmp	w6, #10, #0, ne
	b.lo	LBB0_20
; %bb.9:                                ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w5, [x4, #2]
	sub	w6, w5, #48
	cmp	w5, #34
	ccmp	w6, #10, #0, ne
	b.lo	LBB0_20
; %bb.10:                               ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w5, [x4, #3]
	cmp	w5, #34
	b.eq	LBB0_20
; %bb.11:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	w5, w5, #48
	cmp	w5, #10
	b.lo	LBB0_20
; %bb.12:                               ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w5, [x4, #4]
	cmp	w5, #34
	b.eq	LBB0_20
; %bb.13:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	w5, w5, #48
	cmp	w5, #10
	b.lo	LBB0_20
; %bb.14:                               ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w5, [x4, #5]
	cmp	w5, #34
	b.eq	LBB0_20
; %bb.15:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	w5, w5, #48
	cmp	w5, #10
	b.lo	LBB0_20
; %bb.16:                               ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w5, [x4, #6]
	cmp	w5, #34
	b.eq	LBB0_20
; %bb.17:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	w5, w5, #48
	cmp	w5, #10
	b.lo	LBB0_20
; %bb.18:                               ;   in Loop: Header=BB0_5 Depth=2
	ldrb	w4, [x4, #7]
	cmp	w4, #34
	b.eq	LBB0_20
; %bb.19:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	w5, w4, #58
	add	x4, x2, #8
	cmn	w5, #10
	b.lo	LBB0_5
LBB0_20:                                ;   in Loop: Header=BB0_5 Depth=2
	cmp	w3, #34
	b.ne	LBB0_23
LBB0_21:                                ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_5 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	mov	x3, x2
	mov	x4, x1
	cmp	x2, #42
	b.gt	LBB0_3
; %bb.22:                               ;   in Loop: Header=BB0_21 Depth=3
	add	x1, x0, x3
	ldrb	w5, [x1, #1]
	add	x1, x4, #1
	add	x2, x3, #1
	cmp	w5, #34
	b.ne	LBB0_21
	b	LBB0_3
LBB0_23:                                ;   in Loop: Header=BB0_5 Depth=2
	sub	w3, w3, #48
	cmp	w3, #9
	b.hi	LBB0_4
; %bb.24:                               ;   in Loop: Header=BB0_5 Depth=2
	cmp	x2, #40
	b.le	LBB0_26
; %bb.25:                               ;   in Loop: Header=BB0_5 Depth=2
	mov	x3, #0                          ; =0x0
	b	LBB0_30
LBB0_26:                                ;   in Loop: Header=BB0_5 Depth=2
	mov	x3, #0                          ; =0x0
	mov	x4, x2
LBB0_27:                                ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_5 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	add	x2, x0, x4
	ldrb	w7, [x2]
	ldrb	w6, [x2, #1]
	ldrb	w5, [x2, #2]
	ldrb	w19, [x2, #3]
	sub	w2, w7, #58
	sub	w20, w6, #58
	sub	w21, w5, #58
	sub	w22, w19, #58
	cmn	w2, #10
	ccmn	w20, #10, #0, hs
	ccmn	w21, #10, #0, hs
	ccmn	w22, #10, #0, hs
	b.lo	LBB0_29
; %bb.28:                               ;   in Loop: Header=BB0_27 Depth=3
	add	x2, x4, #4
	mul	x3, x3, x12
	madd	w7, w7, w13, w14
	and	x19, x19, #0xf
	umaddl	x3, w6, w15, x3
	umaddl	x3, w5, w11, x3
	add	x5, x7, x19
	add	x5, x5, x16
	add	x3, x3, x5
	cmp	x4, #37
	mov	x4, x2
	b.lt	LBB0_27
	b	LBB0_30
LBB0_29:                                ;   in Loop: Header=BB0_5 Depth=2
	mov	x2, x4
LBB0_30:                                ;   in Loop: Header=BB0_5 Depth=2
	cmp	x2, #44
	csel	x4, x2, x10, gt
LBB0_31:                                ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_5 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	mov	x5, x3
	cmp	x4, x2
	b.eq	LBB0_34
; %bb.32:                               ;   in Loop: Header=BB0_31 Depth=3
	ldrb	w3, [x0, x2]
	sub	w6, w3, #58
	and	x3, x3, #0xf
	madd	x3, x5, x11, x3
	add	x2, x2, #1
	cmn	w6, #11
	b.hi	LBB0_31
; %bb.33:                               ;   in Loop: Header=BB0_5 Depth=2
	sub	x4, x2, #1
LBB0_34:                                ;   in Loop: Header=BB0_5 Depth=2
	add	x1, x5, x1
	b	LBB0_5
LBB0_35:
	str	x8, [sp]
Lloh2:
	adrp	x0, l_.str@PAGE
Lloh3:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh2, Lloh3
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%llu\n"

l_.str.1:                               ; @.str.1
	.asciz	"{\"id\":123,\"name\":\"alpha\",\"val\":456,\"flag\":1}"

.subsections_via_symbols
