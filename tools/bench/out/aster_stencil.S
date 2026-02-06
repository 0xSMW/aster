	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #480
	stp	x28, x27, [sp, #384]            ; 16-byte Folded Spill
	stp	x26, x25, [sp, #400]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #416]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #432]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #448]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #464]            ; 16-byte Folded Spill
	add	x29, sp, #464
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
	.cfi_offset w27, -88
	.cfi_offset w28, -96
	mov	w0, #2097152                    ; =0x200000
	bl	_malloc
	mov	x21, x0
	mov	w0, #2097152                    ; =0x200000
	bl	_malloc
	mov	x22, x0
	mov	w0, #1                          ; =0x1
	cbz	x21, LBB0_37
; %bb.1:
	cbz	x22, LBB0_37
; %bb.2:
	mov	x0, x22
	mov	w1, #2097152                    ; =0x200000
	bl	_bzero
Lloh0:
	adrp	x1, l_.memset_pattern@PAGE
Lloh1:
	add	x1, x1, l_.memset_pattern@PAGEOFF
	mov	x0, x21
	mov	w2, #2097152                    ; =0x200000
	bl	_memset_pattern16
	mov	x13, #0                         ; =0x0
	mov	w15, #4616                      ; =0x1208
	mov	w26, #5128                      ; =0x1408
	mov	w17, #5640                      ; =0x1608
	mov	w27, #6152                      ; =0x1808
	mov	w1, #6664                       ; =0x1a08
	mov	w28, #7176                      ; =0x1c08
	fmov.2d	v0, #0.50000000
	fmov.2d	v1, #0.12500000
	mov	w3, #4664                       ; =0x1238
	mov	w20, #5160                      ; =0x1428
	mov	w19, #5176                      ; =0x1438
	mov	w10, #5656                      ; =0x1618
	mov	w12, #5672                      ; =0x1628
	fmov	d2, #0.50000000
	fmov	d3, #0.12500000
	mov	w14, #5688                      ; =0x1638
	mov	w16, #6168                      ; =0x1818
	mov	w0, #6184                       ; =0x1828
	mov	w2, #6200                       ; =0x1838
	mov	w9, #6680                       ; =0x1a18
	mov	w8, #6696                       ; =0x1a28
	mov	w4, #6712                       ; =0x1a38
	mov	w25, #7192                      ; =0x1c18
	mov	w5, #7208                       ; =0x1c28
	mov	w6, #7224                       ; =0x1c38
	stp	x22, x21, [sp, #8]              ; 16-byte Folded Spill
LBB0_3:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
                                        ;       Child Loop BB0_5 Depth 3
                                        ;         Child Loop BB0_6 Depth 4
                                        ;       Child Loop BB0_9 Depth 3
                                        ;         Child Loop BB0_10 Depth 4
                                        ;       Child Loop BB0_13 Depth 3
                                        ;         Child Loop BB0_14 Depth 4
                                        ;       Child Loop BB0_17 Depth 3
                                        ;         Child Loop BB0_18 Depth 4
                                        ;       Child Loop BB0_21 Depth 3
                                        ;         Child Loop BB0_22 Depth 4
                                        ;       Child Loop BB0_25 Depth 3
                                        ;         Child Loop BB0_26 Depth 4
                                        ;       Child Loop BB0_29 Depth 3
                                        ;         Child Loop BB0_30 Depth 4
                                        ;       Child Loop BB0_33 Depth 3
	str	x13, [sp, #24]                  ; 8-byte Folded Spill
	mov	x13, x22
	mov	w11, #4104                      ; =0x1008
	add	x23, x22, x11
	add	x22, x21, x11
	mov	w11, #8760                      ; =0x2238
	add	x24, x21, x11
	add	x15, x13, x15
	mov	w11, #9272                      ; =0x2438
	add	x11, x21, x11
	str	x11, [sp, #168]                 ; 8-byte Folded Spill
	add	x11, x13, x26
	str	x11, [sp, #160]                 ; 8-byte Folded Spill
	mov	w11, #9784                      ; =0x2638
	add	x11, x21, x11
	str	x11, [sp, #152]                 ; 8-byte Folded Spill
	add	x11, x13, x17
	str	x11, [sp, #144]                 ; 8-byte Folded Spill
	mov	x17, x24
	mov	w11, #10296                     ; =0x2838
	add	x11, x21, x11
	str	x11, [sp, #136]                 ; 8-byte Folded Spill
	add	x11, x13, x27
	str	x11, [sp, #128]                 ; 8-byte Folded Spill
	mov	w11, #10808                     ; =0x2a38
	add	x11, x21, x11
	str	x11, [sp, #120]                 ; 8-byte Folded Spill
	add	x11, x13, x1
	str	x11, [sp, #112]                 ; 8-byte Folded Spill
	mov	x1, x15
	mov	w11, #11320                     ; =0x2c38
	add	x11, x21, x11
	str	x11, [sp, #104]                 ; 8-byte Folded Spill
	str	x13, [sp, #32]                  ; 8-byte Folded Spill
	add	x11, x13, x28
	str	x11, [sp, #96]                  ; 8-byte Folded Spill
	mov	x13, #0                         ; =0x0
	mov	x15, x21
	mov	w24, #1                         ; =0x1
LBB0_4:                                 ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_5 Depth 3
                                        ;         Child Loop BB0_6 Depth 4
                                        ;       Child Loop BB0_9 Depth 3
                                        ;         Child Loop BB0_10 Depth 4
                                        ;       Child Loop BB0_13 Depth 3
                                        ;         Child Loop BB0_14 Depth 4
                                        ;       Child Loop BB0_17 Depth 3
                                        ;         Child Loop BB0_18 Depth 4
                                        ;       Child Loop BB0_21 Depth 3
                                        ;         Child Loop BB0_22 Depth 4
                                        ;       Child Loop BB0_25 Depth 3
                                        ;         Child Loop BB0_26 Depth 4
                                        ;       Child Loop BB0_29 Depth 3
                                        ;         Child Loop BB0_30 Depth 4
                                        ;       Child Loop BB0_33 Depth 3
	mov	w11, #8136                      ; =0x1fc8
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-96]                ; 8-byte Folded Spill
	mov	w11, #12232                     ; =0x2fc8
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-104]               ; 8-byte Folded Spill
	mov	w11, #16264                     ; =0x3f88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-112]               ; 8-byte Folded Spill
	mov	w11, #8072                      ; =0x1f88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-120]               ; 8-byte Folded Spill
	mov	w11, #12168                     ; =0x2f88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-128]               ; 8-byte Folded Spill
	mov	w11, #16200                     ; =0x3f48
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-136]               ; 8-byte Folded Spill
	mov	w11, #8008                      ; =0x1f48
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-144]               ; 8-byte Folded Spill
	mov	w11, #12104                     ; =0x2f48
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-152]               ; 8-byte Folded Spill
	mov	w11, #16136                     ; =0x3f08
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-160]               ; 8-byte Folded Spill
	mov	w11, #7944                      ; =0x1f08
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-168]               ; 8-byte Folded Spill
	mov	w11, #12040                     ; =0x2f08
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-176]               ; 8-byte Folded Spill
	mov	w11, #16072                     ; =0x3ec8
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-184]               ; 8-byte Folded Spill
	mov	w11, #7880                      ; =0x1ec8
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-192]               ; 8-byte Folded Spill
	mov	w11, #11976                     ; =0x2ec8
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-200]               ; 8-byte Folded Spill
	mov	w11, #16008                     ; =0x3e88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-208]               ; 8-byte Folded Spill
	mov	w11, #7816                      ; =0x1e88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-216]               ; 8-byte Folded Spill
	mov	w11, #11912                     ; =0x2e88
	bfi	x11, x13, #17, #46
	stur	x11, [x29, #-224]               ; 8-byte Folded Spill
	mov	w11, #15944                     ; =0x3e48
	bfi	x11, x13, #17, #46
	str	x11, [sp, #232]                 ; 8-byte Folded Spill
	mov	w11, #7752                      ; =0x1e48
	bfi	x11, x13, #17, #46
	str	x11, [sp, #224]                 ; 8-byte Folded Spill
	mov	w11, #11848                     ; =0x2e48
	bfi	x11, x13, #17, #46
	str	x11, [sp, #216]                 ; 8-byte Folded Spill
	mov	w11, #15880                     ; =0x3e08
	bfi	x11, x13, #17, #46
	str	x11, [sp, #208]                 ; 8-byte Folded Spill
	mov	w11, #7688                      ; =0x1e08
	bfi	x11, x13, #17, #46
	str	x11, [sp, #200]                 ; 8-byte Folded Spill
	mov	w11, #11784                     ; =0x2e08
	bfi	x11, x13, #17, #46
	stp	x24, x11, [sp, #184]            ; 16-byte Folded Spill
	add	x7, x24, #32
	cmp	x24, #479
	mov	w11, #511                       ; =0x1ff
	str	x7, [sp, #48]                   ; 8-byte Folded Spill
	csel	x30, x11, x7, hi
	stp	x22, x23, [sp, #72]             ; 16-byte Folded Spill
	mov	x7, x22
	str	x15, [sp, #176]                 ; 8-byte Folded Spill
	mov	x22, x15
	mov	w11, #16328                     ; =0x3fc8
	str	x13, [sp, #88]                  ; 8-byte Folded Spill
	orr	x11, x11, x13, lsl #17
	str	x11, [sp, #40]                  ; 8-byte Folded Spill
	mov	w27, #4632                      ; =0x1218
	mov	w28, #4648                      ; =0x1228
LBB0_5:                                 ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_6 Depth 4
	mov	x11, #0                         ; =0x0
LBB0_6:                                 ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_5 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldp	q4, q5, [x13]
	ldp	q6, q7, [x13, #32]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x22, x11
	ldur	q16, [x15, #8]
	ldur	q17, [x15, #24]
	ldur	q18, [x15, #40]
	ldur	q19, [x15, #56]
	ldr	q20, [x13, #4096]
	ldr	q21, [x13, #4112]
	ldr	q22, [x13, #4128]
	ldr	q23, [x13, #4144]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x15, #4096]
	ldr	q21, [x15, #4112]
	ldr	q22, [x15, #4128]
	ldr	q23, [x15, #4144]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x15, #4160]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x23, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_6
; %bb.7:                                ;   in Loop: Header=BB0_5 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_5
; %bb.8:                                ;   in Loop: Header=BB0_4 Depth=2
	ldp	x7, x23, [sp, #176]             ; 16-byte Folded Reload
	stp	x1, x17, [sp, #56]              ; 16-byte Folded Spill
	mov	x22, x1
	mov	x24, x17
LBB0_9:                                 ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_10 Depth 4
	mov	x11, #0                         ; =0x0
	mov	w26, #4616                      ; =0x1208
LBB0_10:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_9 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x26]
	ldr	q5, [x13, x27]
	ldr	q6, [x13, x28]
	ldr	q7, [x13, x3]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #520
	add	x17, x13, #536
	add	x1, x13, #552
	add	x3, x13, #568
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	mov	w3, #4664                       ; =0x1238
	add	x15, x24, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #4608]
	ldr	q21, [x13, #4624]
	ldr	q22, [x13, #4640]
	ldr	q23, [x13, #4656]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #4672]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_10
; %bb.11:                               ;   in Loop: Header=BB0_9 Depth=3
	add	x23, x23, #1
	add	x24, x24, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x23, x30
	b.lo	LBB0_9
; %bb.12:                               ;   in Loop: Header=BB0_4 Depth=2
	ldp	x23, x28, [sp, #168]            ; 16-byte Folded Reload
	mov	x7, x28
	ldr	x22, [sp, #160]                 ; 8-byte Folded Reload
	ldr	x24, [sp, #184]                 ; 8-byte Folded Reload
	mov	w26, #5128                      ; =0x1408
	mov	w27, #5144                      ; =0x1418
LBB0_13:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_14 Depth 4
	mov	x11, #0                         ; =0x0
LBB0_14:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_13 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x26]
	ldr	q5, [x13, x27]
	ldr	q6, [x13, x20]
	ldr	q7, [x13, x19]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #1032
	add	x17, x13, #1048
	add	x1, x13, #1064
	add	x3, x13, #1080
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	add	x15, x23, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #5120]
	ldr	q21, [x13, #5136]
	ldr	q22, [x13, #5152]
	ldr	q23, [x13, #5168]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #5184]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_14
; %bb.15:                               ;   in Loop: Header=BB0_13 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_13
; %bb.16:                               ;   in Loop: Header=BB0_4 Depth=2
	mov	x7, x28
	ldp	x22, x23, [sp, #144]            ; 16-byte Folded Reload
	ldr	x24, [sp, #184]                 ; 8-byte Folded Reload
LBB0_17:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_18 Depth 4
	mov	x11, #0                         ; =0x0
	mov	w27, #5640                      ; =0x1608
LBB0_18:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_17 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x27]
	ldr	q5, [x13, x10]
	ldr	q6, [x13, x12]
	ldr	q7, [x13, x14]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #1544
	add	x17, x13, #1560
	add	x1, x13, #1576
	add	x3, x13, #1592
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	add	x15, x23, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #5632]
	ldr	q21, [x13, #5648]
	ldr	q22, [x13, #5664]
	ldr	q23, [x13, #5680]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #5696]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_18
; %bb.19:                               ;   in Loop: Header=BB0_17 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_17
; %bb.20:                               ;   in Loop: Header=BB0_4 Depth=2
	mov	x7, x28
	ldp	x22, x23, [sp, #128]            ; 16-byte Folded Reload
	ldr	x24, [sp, #184]                 ; 8-byte Folded Reload
	mov	w27, #6152                      ; =0x1808
LBB0_21:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_22 Depth 4
	mov	x11, #0                         ; =0x0
LBB0_22:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_21 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x27]
	ldr	q5, [x13, x16]
	ldr	q6, [x13, x0]
	ldr	q7, [x13, x2]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #2056
	add	x17, x13, #2072
	add	x1, x13, #2088
	add	x3, x13, #2104
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	add	x15, x23, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #6144]
	ldr	q21, [x13, #6160]
	ldr	q22, [x13, #6176]
	ldr	q23, [x13, #6192]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #6208]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_22
; %bb.23:                               ;   in Loop: Header=BB0_21 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_21
; %bb.24:                               ;   in Loop: Header=BB0_4 Depth=2
	mov	x7, x28
	ldp	x22, x23, [sp, #112]            ; 16-byte Folded Reload
	ldr	x24, [sp, #184]                 ; 8-byte Folded Reload
LBB0_25:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_26 Depth 4
	mov	x11, #0                         ; =0x0
	mov	w28, #6664                      ; =0x1a08
LBB0_26:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_25 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x28]
	ldr	q5, [x13, x9]
	ldr	q6, [x13, x8]
	ldr	q7, [x13, x4]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #2568
	add	x17, x13, #2584
	add	x1, x13, #2600
	add	x3, x13, #2616
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	add	x15, x23, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #6656]
	ldr	q21, [x13, #6672]
	ldr	q22, [x13, #6688]
	ldr	q23, [x13, #6704]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #6720]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_26
; %bb.27:                               ;   in Loop: Header=BB0_25 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_25
; %bb.28:                               ;   in Loop: Header=BB0_4 Depth=2
	ldp	x7, x24, [sp, #176]             ; 16-byte Folded Reload
	ldp	x22, x23, [sp, #96]             ; 16-byte Folded Reload
	mov	w28, #7176                      ; =0x1c08
LBB0_29:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_30 Depth 4
	mov	x11, #0                         ; =0x0
LBB0_30:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ;       Parent Loop BB0_29 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	add	x13, x7, x11
	ldr	q4, [x13, x28]
	ldr	q5, [x13, x25]
	ldr	q6, [x13, x5]
	ldr	q7, [x13, x6]
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	add	x15, x13, #3080
	add	x17, x13, #3096
	add	x1, x13, #3112
	add	x3, x13, #3128
	ldr	q16, [x15]
	ldr	q17, [x17]
	ldr	q18, [x1]
	ldr	q19, [x3]
	add	x15, x23, x11
	ldp	q20, q21, [x15, #-48]
	ldp	q22, q23, [x15, #-16]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #7168]
	ldr	q21, [x13, #7184]
	ldr	q22, [x13, #7200]
	ldr	q23, [x13, #7216]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldr	q20, [x13, #7232]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x13, x22, x11
	stp	q4, q5, [x13]
	stp	q6, q7, [x13, #32]
	add	x11, x11, #64
	cmp	x11, #512
	b.ne	LBB0_30
; %bb.31:                               ;   in Loop: Header=BB0_29 Depth=3
	add	x24, x24, #1
	add	x23, x23, #1, lsl #12           ; =4096
	add	x22, x22, #1, lsl #12           ; =4096
	add	x7, x7, #1, lsl #12             ; =4096
	cmp	x24, x30
	b.lo	LBB0_29
; %bb.32:                               ;   in Loop: Header=BB0_4 Depth=2
	mov	x7, #0                          ; =0x0
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	add	x13, x21, x11
	ldur	x11, [x29, #-96]                ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-96]                ; 8-byte Folded Spill
	ldur	x11, [x29, #-104]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-104]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-112]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-112]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-120]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-120]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-128]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-128]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-136]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-136]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-144]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-144]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-152]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-152]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-160]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-160]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-168]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-168]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-176]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-176]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-184]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-184]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-192]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-192]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-200]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-200]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-208]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-208]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-216]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-216]               ; 8-byte Folded Spill
	ldur	x11, [x29, #-224]               ; 8-byte Folded Reload
	add	x11, x21, x11
	stur	x11, [x29, #-224]               ; 8-byte Folded Spill
	ldr	x11, [sp, #232]                 ; 8-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #232]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #224]                 ; 8-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #224]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #216]                 ; 8-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #216]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #208]                 ; 8-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #208]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #200]                 ; 8-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #200]                 ; 8-byte Folded Spill
	ldp	x23, x11, [sp, #184]            ; 16-byte Folded Reload
	add	x11, x21, x11
	str	x11, [sp, #192]                 ; 8-byte Folded Spill
	ldr	x1, [sp, #32]                   ; 8-byte Folded Reload
	mov	x3, x30
	mov	x30, x13
LBB0_33:                                ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_4 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	lsl	x22, x7, #12
	ldr	x11, [sp, #200]                 ; 8-byte Folded Reload
	add	x13, x11, x22
	add	x24, x21, x23, lsl #12
	ldr	x11, [sp, #192]                 ; 8-byte Folded Reload
	add	x15, x11, x22
	mov	w11, #3592                      ; =0xe08
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	sub	x13, x24, #504
	ldr	q16, [x13]
	sub	x13, x24, #488
	ldr	q17, [x13]
	sub	x13, x24, #472
	ldr	q18, [x13]
	sub	x13, x24, #456
	ldr	q19, [x13]
	ldr	x13, [sp, #208]                 ; 8-byte Folded Reload
	add	x13, x13, x22
	prfm	pldl1keep, [x13]
	ldr	x13, [sp, #224]                 ; 8-byte Folded Reload
	add	x13, x13, x22
	mov	w17, #7688                      ; =0x1e08
	ldr	q20, [x24, x17]
	mov	w17, #7704                      ; =0x1e18
	ldr	q21, [x24, x17]
	fmul.2d	v4, v4, v0
	mov	w17, #7720                      ; =0x1e28
	ldr	q22, [x24, x17]
	mov	w17, #7736                      ; =0x1e38
	ldr	q23, [x24, x17]
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3656                      ; =0xe48
	ldr	x15, [sp, #216]                 ; 8-byte Folded Reload
	add	x15, x15, x22
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	sub	x13, x24, #440
	ldr	q16, [x13]
	sub	x13, x24, #424
	ldr	q17, [x13]
	sub	x13, x24, #408
	ldr	q18, [x13]
	sub	x13, x24, #392
	ldr	q19, [x13]
	ldr	x13, [sp, #232]                 ; 8-byte Folded Reload
	add	x13, x13, x22
	fmul.2d	v4, v4, v0
	prfm	pldl1keep, [x13]
	mov	w13, #7752                      ; =0x1e48
	ldr	q20, [x24, x13]
	mov	w13, #7768                      ; =0x1e58
	ldr	q21, [x24, x13]
	fmul.2d	v5, v5, v0
	mov	w13, #7784                      ; =0x1e68
	ldr	q22, [x24, x13]
	mov	w13, #7800                      ; =0x1e78
	ldr	q23, [x24, x13]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	fmul.2d	v6, v6, v0
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	ldp	x15, x13, [x29, #-224]          ; 16-byte Folded Reload
	add	x13, x13, x22
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3720                      ; =0xe88
	bfi	x11, x23, #12, #52
	add	x15, x15, x22
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	sub	x13, x24, #376
	ldr	q16, [x13]
	sub	x13, x24, #360
	ldr	q17, [x13]
	sub	x13, x24, #344
	ldr	q18, [x13]
	sub	x13, x24, #328
	ldr	q19, [x13]
	ldur	x13, [x29, #-208]               ; 8-byte Folded Reload
	add	x13, x13, x22
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-192]               ; 8-byte Folded Reload
	add	x13, x13, x22
	fmul.2d	v4, v4, v0
	mov	w17, #7816                      ; =0x1e88
	ldr	q20, [x24, x17]
	mov	w17, #7832                      ; =0x1e98
	ldr	q21, [x24, x17]
	fmul.2d	v5, v5, v0
	mov	w17, #7848                      ; =0x1ea8
	ldr	q22, [x24, x17]
	mov	w17, #7864                      ; =0x1eb8
	ldr	q23, [x24, x17]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	fmul.2d	v6, v6, v0
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	ldur	x15, [x29, #-200]               ; 8-byte Folded Reload
	add	x15, x15, x22
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3784                      ; =0xec8
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	sub	x13, x24, #312
	ldr	q16, [x13]
	sub	x13, x24, #296
	ldr	q17, [x13]
	sub	x13, x24, #280
	ldr	q18, [x13]
	sub	x13, x24, #264
	ldr	q19, [x13]
	ldur	x13, [x29, #-184]               ; 8-byte Folded Reload
	add	x13, x13, x22
	prfm	pldl1keep, [x13]
	mov	w13, #7880                      ; =0x1ec8
	ldr	q20, [x24, x13]
	mov	w13, #7896                      ; =0x1ed8
	ldr	q21, [x24, x13]
	mov	w13, #7912                      ; =0x1ee8
	ldr	q22, [x24, x13]
	mov	w13, #7928                      ; =0x1ef8
	ldr	q23, [x24, x13]
	ldur	x13, [x29, #-168]               ; 8-byte Folded Reload
	add	x13, x13, x22
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	ldur	q23, [x15, #40]
	ldur	q24, [x15, #56]
	ldur	x15, [x29, #-176]               ; 8-byte Folded Reload
	add	x15, x15, x22
	fadd.2d	v16, v16, v20
	fmul.2d	v4, v4, v0
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fmul.2d	v7, v7, v0
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v24
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3848                      ; =0xf08
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-160]               ; 8-byte Folded Reload
	add	x13, x13, x22
	ldur	q16, [x24, #-248]
	ldur	q17, [x24, #-232]
	ldur	q18, [x24, #-216]
	ldur	q19, [x24, #-200]
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-144]               ; 8-byte Folded Reload
	add	x13, x13, x22
	fmul.2d	v4, v4, v0
	mov	w17, #7944                      ; =0x1f08
	ldr	q20, [x24, x17]
	mov	w17, #7960                      ; =0x1f18
	ldr	q21, [x24, x17]
	fmul.2d	v5, v5, v0
	mov	w17, #7976                      ; =0x1f28
	ldr	q22, [x24, x17]
	mov	w17, #7992                      ; =0x1f38
	ldr	q23, [x24, x17]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	fmul.2d	v6, v6, v0
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	ldur	x15, [x29, #-152]               ; 8-byte Folded Reload
	add	x15, x15, x22
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3912                      ; =0xf48
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-136]               ; 8-byte Folded Reload
	add	x13, x13, x22
	ldur	q16, [x24, #-184]
	ldur	q17, [x24, #-168]
	ldur	q18, [x24, #-152]
	ldur	q19, [x24, #-136]
	fmul.2d	v4, v4, v0
	prfm	pldl1keep, [x13]
	mov	w13, #8008                      ; =0x1f48
	ldr	q20, [x24, x13]
	mov	w13, #8024                      ; =0x1f58
	ldr	q21, [x24, x13]
	fmul.2d	v5, v5, v0
	mov	w13, #8040                      ; =0x1f68
	ldr	q22, [x24, x13]
	mov	w13, #8056                      ; =0x1f78
	ldr	q23, [x24, x13]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	fmul.2d	v6, v6, v0
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	ldp	x15, x13, [x29, #-128]          ; 16-byte Folded Reload
	add	x13, x13, x22
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #3976                      ; =0xf88
	bfi	x11, x23, #12, #52
	add	x15, x15, x22
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	q4, q5, [x15]
	ldp	q6, q7, [x15, #32]
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-112]               ; 8-byte Folded Reload
	add	x13, x13, x22
	ldur	q16, [x24, #-120]
	ldur	q17, [x24, #-104]
	ldur	q18, [x24, #-88]
	ldur	q19, [x24, #-72]
	prfm	pldl1keep, [x13]
	ldur	x13, [x29, #-96]                ; 8-byte Folded Reload
	add	x13, x13, x22
	mov	w17, #8072                      ; =0x1f88
	ldr	q20, [x24, x17]
	mov	w17, #8088                      ; =0x1f98
	ldr	q21, [x24, x17]
	fmul.2d	v4, v4, v0
	mov	w17, #8104                      ; =0x1fa8
	ldr	q22, [x24, x17]
	mov	w17, #8120                      ; =0x1fb8
	ldr	q23, [x24, x17]
	fmul.2d	v5, v5, v0
	fmul.2d	v6, v6, v0
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	fmul.2d	v7, v7, v0
	ldur	q20, [x15, #-8]
	ldur	q21, [x15, #8]
	ldur	q22, [x15, #24]
	ldur	q23, [x15, #40]
	fadd.2d	v16, v16, v20
	fadd.2d	v17, v17, v21
	fadd.2d	v18, v18, v22
	fadd.2d	v19, v19, v23
	ldur	q20, [x15, #56]
	fadd.2d	v16, v16, v21
	fadd.2d	v17, v17, v22
	fadd.2d	v18, v18, v23
	fadd.2d	v19, v19, v20
	fmla.2d	v4, v1, v16
	fmla.2d	v5, v1, v17
	fmla.2d	v6, v1, v18
	fmla.2d	v7, v1, v19
	add	x11, x1, x11
	stp	q4, q5, [x11]
	stp	q6, q7, [x11, #32]
	mov	w11, #4040                      ; =0xfc8
	ldur	x15, [x29, #-104]               ; 8-byte Folded Reload
	add	x15, x15, x22
	bfi	x11, x23, #12, #52
	prfm	pldl1keep, [x15]
	add	x15, x21, x11
	ldp	d7, d4, [x15, #-8]
	prfm	pldl1keep, [x13]
	add	x13, x30, x22
	fmul	d4, d4, d2
	ldp	d5, d17, [x24, #-56]
	prfm	pldl1keep, [x13]
	ldr	d6, [x24, #8136]
	fadd	d5, d5, d6
	fadd	d5, d5, d7
	ldr	d6, [x15, #8]
	mov	w13, #4048                      ; =0xfd0
	bfi	x13, x23, #12, #52
	add	x15, x21, x13
	fadd	d5, d5, d6
	ldp	d7, d6, [x15, #-8]
	fmul	d6, d6, d2
	ldr	d16, [x24, #8144]
	fmadd	d4, d5, d3, d4
	ldur	d5, [x24, #-40]
	fadd	d16, d17, d16
	fadd	d7, d16, d7
	ldr	d16, [x15, #8]
	str	d4, [x1, x11]
	fadd	d4, d7, d16
	mov	w11, #4056                      ; =0xfd8
	bfi	x11, x23, #12, #52
	add	x15, x21, x11
	fmadd	d4, d4, d3, d6
	ldp	d6, d7, [x15, #-8]
	ldr	d16, [x15, #8]
	mov	w15, #4064                      ; =0xfe0
	bfi	x15, x23, #12, #52
	str	d4, [x1, x13]
	add	x13, x21, x15
	ldp	d17, d4, [x13, #-8]
	ldr	d18, [x13, #8]
	ldr	d19, [x24, #8152]
	fmul	d7, d7, d2
	fadd	d5, d5, d19
	fadd	d5, d5, d6
	fadd	d5, d5, d16
	fmul	d4, d4, d2
	ldr	d6, [x24, #8160]
	fmadd	d5, d5, d3, d7
	ldp	d7, d16, [x24, #-32]
	fadd	d6, d7, d6
	fadd	d6, d6, d17
	str	d5, [x1, x11]
	fadd	d5, d6, d18
	fmadd	d4, d5, d3, d4
	mov	w11, #4072                      ; =0xfe8
	bfi	x11, x23, #12, #52
	str	d4, [x1, x15]
	add	x13, x21, x11
	ldp	d5, d4, [x13, #-8]
	ldr	d6, [x13, #8]
	ldr	d7, [x24, #8168]
	fmul	d4, d4, d2
	fadd	d7, d16, d7
	fadd	d5, d7, d5
	fadd	d5, d5, d6
	fmadd	d4, d5, d3, d4
	str	d4, [x1, x11]
	mov	w11, #4080                      ; =0xff0
	bfi	x11, x23, #12, #52
	ldur	d4, [x24, #-16]
	ldr	d5, [x24, #8176]
	add	x13, x21, x11
	ldp	d7, d6, [x13, #-8]
	ldr	d16, [x13, #8]
	fmul	d6, d6, d2
	fadd	d4, d4, d5
	fadd	d4, d4, d7
	fadd	d4, d4, d16
	fmadd	d4, d4, d3, d6
	str	d4, [x1, x11]
	add	x23, x23, #1
	add	x7, x7, #1
	cmp	x23, x3
	b.lo	LBB0_33
; %bb.34:                               ;   in Loop: Header=BB0_4 Depth=2
	ldp	x23, x13, [sp, #80]             ; 16-byte Folded Reload
	add	x13, x13, #1
	add	x23, x23, #32, lsl #12          ; =131072
	ldp	x11, x15, [sp, #168]            ; 16-byte Folded Reload
	add	x15, x15, #32, lsl #12          ; =131072
	ldp	x17, x22, [sp, #64]             ; 16-byte Folded Reload
	add	x22, x22, #32, lsl #12          ; =131072
	add	x17, x17, #32, lsl #12          ; =131072
	ldr	x1, [sp, #56]                   ; 8-byte Folded Reload
	add	x1, x1, #32, lsl #12            ; =131072
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #168]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #160]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #160]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #152]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #152]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #144]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #144]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #136]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #136]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #128]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #128]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #120]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #120]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #112]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #112]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #104]                 ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #104]                 ; 8-byte Folded Spill
	ldr	x11, [sp, #96]                  ; 8-byte Folded Reload
	add	x11, x11, #32, lsl #12          ; =131072
	str	x11, [sp, #96]                  ; 8-byte Folded Spill
	ldr	x11, [sp, #184]                 ; 8-byte Folded Reload
	cmp	x11, #479
	ldr	x24, [sp, #48]                  ; 8-byte Folded Reload
	mov	w3, #4664                       ; =0x1238
	b.lo	LBB0_4
; %bb.35:                               ;   in Loop: Header=BB0_3 Depth=1
	ldp	x13, x7, [sp, #24]              ; 16-byte Folded Reload
	add	x13, x13, #1
	mov	x22, x21
	mov	x21, x7
	cmp	x13, #3
	mov	w15, #4616                      ; =0x1208
	mov	w17, #5640                      ; =0x1608
	mov	w1, #6664                       ; =0x1a08
	b.ne	LBB0_3
; %bb.36:
	ldr	d0, [x7]
	str	d0, [sp]
Lloh2:
	adrp	x0, l_.str@PAGE
Lloh3:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	ldr	x0, [sp, #16]                   ; 8-byte Folded Reload
	bl	_free
	ldr	x0, [sp, #8]                    ; 8-byte Folded Reload
	bl	_free
	mov	w0, #0                          ; =0x0
LBB0_37:
	ldp	x29, x30, [sp, #464]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #448]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #432]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #416]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #400]            ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #384]            ; 16-byte Folded Reload
	add	sp, sp, #480
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh2, Lloh3
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

.subsections_via_symbols
