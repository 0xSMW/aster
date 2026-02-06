	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	stp	d15, d14, [sp, #-112]!          ; 16-byte Folded Spill
	stp	d13, d12, [sp, #16]             ; 16-byte Folded Spill
	stp	d11, d10, [sp, #32]             ; 16-byte Folded Spill
	stp	d9, d8, [sp, #48]               ; 16-byte Folded Spill
	stp	x22, x21, [sp, #64]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #80]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #96]             ; 16-byte Folded Spill
	add	x29, sp, #96
	sub	sp, sp, #624
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset b8, -56
	.cfi_offset b9, -64
	.cfi_offset b10, -72
	.cfi_offset b11, -80
	.cfi_offset b12, -88
	.cfi_offset b13, -96
	.cfi_offset b14, -104
	.cfi_offset b15, -112
	mov	w0, #131072                     ; =0x20000
	bl	_malloc
	mov	x19, x0
	mov	w0, #131072                     ; =0x20000
	bl	_malloc
	mov	x20, x0
	mov	w0, #131072                     ; =0x20000
	bl	_malloc
	mov	x21, x0
	mov	w0, #1                          ; =0x1
	cbz	x19, LBB0_12
; %bb.1:
	cbz	x20, LBB0_12
; %bb.2:
	cbz	x21, LBB0_12
; %bb.3:
	mov	x0, x21
	mov	w1, #131072                     ; =0x20000
	bl	_bzero
Lloh0:
	adrp	x1, l_.memset_pattern@PAGE
Lloh1:
	add	x1, x1, l_.memset_pattern@PAGEOFF
	mov	x0, x19
	mov	w2, #131072                     ; =0x20000
	bl	_memset_pattern16
Lloh2:
	adrp	x1, l_.memset_pattern.1@PAGE
Lloh3:
	add	x1, x1, l_.memset_pattern.1@PAGEOFF
	mov	x0, x20
	mov	w2, #131072                     ; =0x20000
	bl	_memset_pattern16
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_4:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_5 Depth 2
	mov	x14, #0                         ; =0x0
	add	x10, x21, x9, lsl #10
	mov	x13, x10
	ldr	q1, [x13, #64]!
	mov	x12, x10
	ldr	q0, [x12, #128]!
	stp	q1, q0, [x29, #-176]            ; 32-byte Folded Spill
	mov	x11, x10
	ldr	q1, [x11, #192]!
	ldp	q0, q14, [x10]
	stp	q0, q1, [x29, #-144]            ; 32-byte Folded Spill
	ldp	q13, q12, [x10, #32]
	ldp	q11, q10, [x10, #80]
	ldr	q9, [x10, #112]
	ldp	q8, q31, [x10, #144]
	ldr	q30, [x10, #176]
	ldp	q29, q28, [x10, #208]
	ldp	q27, q26, [x10, #240]
	ldp	q25, q24, [x10, #272]
	ldp	q23, q22, [x10, #304]
	ldp	q21, q20, [x10, #336]
	ldp	q19, q18, [x10, #368]
	ldp	q17, q16, [x10, #400]
	ldp	q7, q6, [x10, #432]
	ldp	q1, q0, [x10, #464]
	stur	q1, [x29, #-240]                ; 16-byte Folded Spill
	stur	q0, [x29, #-192]                ; 16-byte Folded Spill
	mov	x15, x8
	ldp	q1, q0, [x10, #496]
	stp	q1, q0, [sp, #48]               ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #528]
	stp	q1, q0, [sp, #80]               ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #560]
	stp	q1, q0, [sp, #112]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #592]
	stp	q1, q0, [sp, #144]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #624]
	stp	q1, q0, [sp, #176]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #656]
	stp	q1, q0, [sp, #208]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #688]
	stp	q1, q0, [sp, #240]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #720]
	stp	q1, q0, [sp, #272]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #752]
	stp	q1, q0, [sp, #304]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #784]
	stp	q1, q0, [sp, #336]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #816]
	stp	q1, q0, [sp, #368]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #848]
	stp	q1, q0, [sp, #400]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #880]
	stp	q1, q0, [sp, #432]              ; 32-byte Folded Spill
	ldp	q1, q2, [x10, #912]
	stur	q1, [x29, #-256]                ; 16-byte Folded Spill
	ldp	q0, q4, [x10, #944]
	stp	q2, q0, [x29, #-224]            ; 32-byte Folded Spill
	ldp	q3, q2, [x10, #976]
	ldr	q1, [x10, #1008]
LBB0_5:                                 ;   Parent Loop BB0_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	q4, [sp, #16]                   ; 16-byte Folded Spill
	stur	q1, [x29, #-112]                ; 16-byte Folded Spill
	ldr	d15, [x19, x15]
	add	x16, x20, x14
	ldp	q0, q1, [x16]
	mov.16b	v4, v3
	mov.16b	v3, v2
	ldur	q2, [x29, #-144]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-144]                ; 16-byte Folded Spill
	fmla.2d	v14, v1, v15[0]
	str	q14, [sp, #32]                  ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #32]
	fmla.2d	v13, v0, v15[0]
	fmla.2d	v12, v1, v15[0]
	ldp	q0, q1, [x16, #64]
	ldur	q2, [x29, #-176]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-176]                ; 16-byte Folded Spill
	fmla.2d	v11, v1, v15[0]
	ldp	q0, q1, [x16, #96]
	fmla.2d	v10, v0, v15[0]
	fmla.2d	v9, v1, v15[0]
	ldp	q0, q1, [x16, #128]
	ldur	q2, [x29, #-160]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-160]                ; 16-byte Folded Spill
	fmla.2d	v8, v1, v15[0]
	ldp	q0, q1, [x16, #160]
	fmla.2d	v31, v0, v15[0]
	fmla.2d	v30, v1, v15[0]
	ldp	q0, q1, [x16, #192]
	mov.16b	v14, v13
	mov.16b	v13, v12
	mov.16b	v12, v11
	mov.16b	v11, v10
	mov.16b	v10, v9
	mov.16b	v9, v8
	mov.16b	v8, v31
	mov.16b	v31, v30
	mov.16b	v30, v29
	mov.16b	v29, v28
	mov.16b	v28, v27
	mov.16b	v27, v26
	mov.16b	v26, v25
	mov.16b	v25, v24
	mov.16b	v24, v23
	mov.16b	v23, v22
	mov.16b	v22, v21
	mov.16b	v21, v20
	mov.16b	v20, v19
	mov.16b	v19, v18
	mov.16b	v18, v17
	mov.16b	v17, v16
	ldur	q2, [x29, #-128]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-128]                ; 16-byte Folded Spill
	mov.16b	v2, v3
	mov.16b	v3, v4
	ldur	q4, [x29, #-192]                ; 16-byte Folded Reload
	ldur	q5, [x29, #-240]                ; 16-byte Folded Reload
	mov.16b	v16, v17
	mov.16b	v17, v18
	mov.16b	v18, v19
	mov.16b	v19, v20
	mov.16b	v20, v21
	mov.16b	v21, v22
	mov.16b	v22, v23
	mov.16b	v23, v24
	mov.16b	v24, v25
	mov.16b	v25, v26
	mov.16b	v26, v27
	mov.16b	v27, v28
	mov.16b	v28, v29
	mov.16b	v29, v30
	mov.16b	v30, v31
	mov.16b	v31, v8
	mov.16b	v8, v9
	mov.16b	v9, v10
	mov.16b	v10, v11
	mov.16b	v11, v12
	mov.16b	v12, v13
	mov.16b	v13, v14
	ldr	q14, [sp, #32]                  ; 16-byte Folded Reload
	fmla.2d	v29, v1, v15[0]
	ldp	q0, q1, [x16, #224]
	fmla.2d	v28, v0, v15[0]
	fmla.2d	v27, v1, v15[0]
	ldp	q0, q1, [x16, #256]
	fmla.2d	v26, v0, v15[0]
	fmla.2d	v25, v1, v15[0]
	ldp	q0, q1, [x16, #288]
	fmla.2d	v24, v0, v15[0]
	fmla.2d	v23, v1, v15[0]
	ldp	q0, q1, [x16, #320]
	fmla.2d	v22, v0, v15[0]
	fmla.2d	v21, v1, v15[0]
	ldp	q0, q1, [x16, #352]
	fmla.2d	v20, v0, v15[0]
	fmla.2d	v19, v1, v15[0]
	ldp	q0, q1, [x16, #384]
	fmla.2d	v18, v0, v15[0]
	fmla.2d	v17, v1, v15[0]
	ldp	q0, q1, [x16, #416]
	fmla.2d	v16, v0, v15[0]
	fmla.2d	v7, v1, v15[0]
	ldp	q0, q1, [x16, #448]
	fmla.2d	v6, v0, v15[0]
	fmla.2d	v5, v1, v15[0]
	stur	q5, [x29, #-240]                ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #480]
	fmla.2d	v4, v0, v15[0]
	stur	q4, [x29, #-192]                ; 16-byte Folded Spill
	ldr	q4, [sp, #16]                   ; 16-byte Folded Reload
	ldp	q0, q5, [sp, #48]               ; 32-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	str	q0, [sp, #48]                   ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #512]
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #80]                   ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #64]               ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #544]
	ldr	q5, [sp, #96]                   ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #112]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #96]               ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #576]
	ldr	q5, [sp, #128]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #144]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #128]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #608]
	ldr	q5, [sp, #160]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #176]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #160]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #640]
	ldr	q5, [sp, #192]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #208]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #192]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #672]
	ldr	q5, [sp, #224]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #240]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #224]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #704]
	ldr	q5, [sp, #256]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #272]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #256]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #736]
	ldr	q5, [sp, #288]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #304]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #288]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #768]
	ldr	q5, [sp, #320]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #336]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #320]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #800]
	ldr	q5, [sp, #352]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #368]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #352]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #832]
	ldr	q5, [sp, #384]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #400]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #384]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #864]
	ldr	q5, [sp, #416]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #432]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #416]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #896]
	ldr	q5, [sp, #448]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	str	q5, [sp, #448]                  ; 16-byte Folded Spill
	ldur	q0, [x29, #-256]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stur	q0, [x29, #-256]                ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #928]
	ldur	q5, [x29, #-224]                ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldur	q0, [x29, #-208]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [x29, #-224]            ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #960]
	fmla.2d	v4, v0, v15[0]
	fmla.2d	v3, v1, v15[0]
	ldp	q0, q1, [x16, #992]
	fmla.2d	v2, v0, v15[0]
	ldur	q0, [x29, #-112]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stur	q0, [x29, #-112]                ; 16-byte Folded Spill
	ldur	q1, [x29, #-112]                ; 16-byte Folded Reload
	add	x14, x14, #1024
	add	x15, x15, #8
	cmp	x14, #32, lsl #12               ; =131072
	b.ne	LBB0_5
; %bb.6:                                ;   in Loop: Header=BB0_4 Depth=1
	ldur	q0, [x29, #-144]                ; 16-byte Folded Reload
	stp	q0, q14, [x10]
	stp	q13, q12, [x10, #32]
	ldp	q5, q0, [x29, #-176]            ; 32-byte Folded Reload
	stp	q5, q11, [x13]
	stp	q10, q9, [x13, #32]
	stp	q0, q8, [x12]
	stp	q31, q30, [x12, #32]
	ldur	q0, [x29, #-128]                ; 16-byte Folded Reload
	stp	q0, q29, [x11]
	stp	q28, q27, [x11, #32]
	stp	q26, q25, [x10, #256]
	stp	q24, q23, [x10, #288]
	stp	q22, q21, [x10, #320]
	stp	q20, q19, [x10, #352]
	stp	q18, q17, [x10, #384]
	stp	q16, q7, [x10, #416]
	ldur	q0, [x29, #-240]                ; 16-byte Folded Reload
	stp	q6, q0, [x10, #448]
	ldur	q5, [x29, #-192]                ; 16-byte Folded Reload
	ldp	q6, q7, [sp, #48]               ; 32-byte Folded Reload
	stp	q5, q6, [x10, #480]
	ldp	q5, q6, [sp, #80]               ; 32-byte Folded Reload
	stp	q7, q5, [x10, #512]
	ldp	q5, q7, [sp, #112]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #544]
	ldp	q5, q6, [sp, #144]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #576]
	ldp	q5, q7, [sp, #176]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #608]
	ldp	q5, q6, [sp, #208]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #640]
	ldp	q5, q7, [sp, #240]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #672]
	ldp	q5, q6, [sp, #272]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #704]
	ldp	q5, q7, [sp, #304]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #736]
	ldp	q5, q6, [sp, #336]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #768]
	ldp	q5, q7, [sp, #368]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #800]
	ldp	q5, q6, [sp, #400]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #832]
	ldp	q5, q7, [sp, #432]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #864]
	ldur	q0, [x29, #-256]                ; 16-byte Folded Reload
	stp	q7, q0, [x10, #896]
	ldp	q5, q0, [x29, #-224]            ; 32-byte Folded Reload
	stp	q5, q0, [x10, #928]
	stp	q4, q3, [x10, #960]
	add	x9, x9, #1
	add	x8, x8, #1024
	stp	q2, q1, [x10, #992]
	cmp	x9, #128
	b.ne	LBB0_4
; %bb.7:
	mov	x8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_8:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_9 Depth 2
	mov	x14, #0                         ; =0x0
	add	x10, x21, x9, lsl #10
	mov	x13, x10
	ldr	q1, [x13, #64]!
	mov	x12, x10
	ldr	q0, [x12, #128]!
	stp	q1, q0, [x29, #-176]            ; 32-byte Folded Spill
	mov	x11, x10
	ldr	q1, [x11, #192]!
	ldp	q0, q14, [x10]
	stp	q0, q1, [x29, #-144]            ; 32-byte Folded Spill
	ldp	q13, q12, [x10, #32]
	ldp	q11, q10, [x10, #80]
	ldr	q9, [x10, #112]
	ldp	q8, q31, [x10, #144]
	ldr	q30, [x10, #176]
	ldp	q29, q28, [x10, #208]
	ldp	q27, q26, [x10, #240]
	ldp	q25, q24, [x10, #272]
	ldp	q23, q22, [x10, #304]
	ldp	q21, q20, [x10, #336]
	ldp	q19, q18, [x10, #368]
	ldp	q17, q16, [x10, #400]
	ldp	q7, q6, [x10, #432]
	ldp	q1, q0, [x10, #464]
	stur	q1, [x29, #-240]                ; 16-byte Folded Spill
	stur	q0, [x29, #-192]                ; 16-byte Folded Spill
	mov	x15, x8
	ldp	q1, q0, [x10, #496]
	stp	q1, q0, [sp, #48]               ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #528]
	stp	q1, q0, [sp, #80]               ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #560]
	stp	q1, q0, [sp, #112]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #592]
	stp	q1, q0, [sp, #144]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #624]
	stp	q1, q0, [sp, #176]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #656]
	stp	q1, q0, [sp, #208]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #688]
	stp	q1, q0, [sp, #240]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #720]
	stp	q1, q0, [sp, #272]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #752]
	stp	q1, q0, [sp, #304]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #784]
	stp	q1, q0, [sp, #336]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #816]
	stp	q1, q0, [sp, #368]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #848]
	stp	q1, q0, [sp, #400]              ; 32-byte Folded Spill
	ldp	q1, q0, [x10, #880]
	stp	q1, q0, [sp, #432]              ; 32-byte Folded Spill
	ldp	q1, q2, [x10, #912]
	stur	q1, [x29, #-256]                ; 16-byte Folded Spill
	ldp	q0, q4, [x10, #944]
	stp	q2, q0, [x29, #-224]            ; 32-byte Folded Spill
	ldp	q3, q2, [x10, #976]
	ldr	q1, [x10, #1008]
LBB0_9:                                 ;   Parent Loop BB0_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	q4, [sp, #16]                   ; 16-byte Folded Spill
	stur	q1, [x29, #-112]                ; 16-byte Folded Spill
	ldr	d15, [x19, x15]
	add	x16, x20, x14
	ldp	q0, q1, [x16]
	mov.16b	v4, v3
	mov.16b	v3, v2
	ldur	q2, [x29, #-144]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-144]                ; 16-byte Folded Spill
	fmla.2d	v14, v1, v15[0]
	str	q14, [sp, #32]                  ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #32]
	fmla.2d	v13, v0, v15[0]
	fmla.2d	v12, v1, v15[0]
	ldp	q0, q1, [x16, #64]
	ldur	q2, [x29, #-176]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-176]                ; 16-byte Folded Spill
	fmla.2d	v11, v1, v15[0]
	ldp	q0, q1, [x16, #96]
	fmla.2d	v10, v0, v15[0]
	fmla.2d	v9, v1, v15[0]
	ldp	q0, q1, [x16, #128]
	ldur	q2, [x29, #-160]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-160]                ; 16-byte Folded Spill
	fmla.2d	v8, v1, v15[0]
	ldp	q0, q1, [x16, #160]
	fmla.2d	v31, v0, v15[0]
	fmla.2d	v30, v1, v15[0]
	ldp	q0, q1, [x16, #192]
	mov.16b	v14, v13
	mov.16b	v13, v12
	mov.16b	v12, v11
	mov.16b	v11, v10
	mov.16b	v10, v9
	mov.16b	v9, v8
	mov.16b	v8, v31
	mov.16b	v31, v30
	mov.16b	v30, v29
	mov.16b	v29, v28
	mov.16b	v28, v27
	mov.16b	v27, v26
	mov.16b	v26, v25
	mov.16b	v25, v24
	mov.16b	v24, v23
	mov.16b	v23, v22
	mov.16b	v22, v21
	mov.16b	v21, v20
	mov.16b	v20, v19
	mov.16b	v19, v18
	mov.16b	v18, v17
	mov.16b	v17, v16
	ldur	q2, [x29, #-128]                ; 16-byte Folded Reload
	fmla.2d	v2, v0, v15[0]
	stur	q2, [x29, #-128]                ; 16-byte Folded Spill
	mov.16b	v2, v3
	mov.16b	v3, v4
	ldur	q4, [x29, #-192]                ; 16-byte Folded Reload
	ldur	q5, [x29, #-240]                ; 16-byte Folded Reload
	mov.16b	v16, v17
	mov.16b	v17, v18
	mov.16b	v18, v19
	mov.16b	v19, v20
	mov.16b	v20, v21
	mov.16b	v21, v22
	mov.16b	v22, v23
	mov.16b	v23, v24
	mov.16b	v24, v25
	mov.16b	v25, v26
	mov.16b	v26, v27
	mov.16b	v27, v28
	mov.16b	v28, v29
	mov.16b	v29, v30
	mov.16b	v30, v31
	mov.16b	v31, v8
	mov.16b	v8, v9
	mov.16b	v9, v10
	mov.16b	v10, v11
	mov.16b	v11, v12
	mov.16b	v12, v13
	mov.16b	v13, v14
	ldr	q14, [sp, #32]                  ; 16-byte Folded Reload
	fmla.2d	v29, v1, v15[0]
	ldp	q0, q1, [x16, #224]
	fmla.2d	v28, v0, v15[0]
	fmla.2d	v27, v1, v15[0]
	ldp	q0, q1, [x16, #256]
	fmla.2d	v26, v0, v15[0]
	fmla.2d	v25, v1, v15[0]
	ldp	q0, q1, [x16, #288]
	fmla.2d	v24, v0, v15[0]
	fmla.2d	v23, v1, v15[0]
	ldp	q0, q1, [x16, #320]
	fmla.2d	v22, v0, v15[0]
	fmla.2d	v21, v1, v15[0]
	ldp	q0, q1, [x16, #352]
	fmla.2d	v20, v0, v15[0]
	fmla.2d	v19, v1, v15[0]
	ldp	q0, q1, [x16, #384]
	fmla.2d	v18, v0, v15[0]
	fmla.2d	v17, v1, v15[0]
	ldp	q0, q1, [x16, #416]
	fmla.2d	v16, v0, v15[0]
	fmla.2d	v7, v1, v15[0]
	ldp	q0, q1, [x16, #448]
	fmla.2d	v6, v0, v15[0]
	fmla.2d	v5, v1, v15[0]
	stur	q5, [x29, #-240]                ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #480]
	fmla.2d	v4, v0, v15[0]
	stur	q4, [x29, #-192]                ; 16-byte Folded Spill
	ldr	q4, [sp, #16]                   ; 16-byte Folded Reload
	ldp	q0, q5, [sp, #48]               ; 32-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	str	q0, [sp, #48]                   ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #512]
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #80]                   ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #64]               ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #544]
	ldr	q5, [sp, #96]                   ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #112]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #96]               ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #576]
	ldr	q5, [sp, #128]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #144]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #128]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #608]
	ldr	q5, [sp, #160]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #176]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #160]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #640]
	ldr	q5, [sp, #192]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #208]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #192]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #672]
	ldr	q5, [sp, #224]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #240]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #224]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #704]
	ldr	q5, [sp, #256]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #272]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #256]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #736]
	ldr	q5, [sp, #288]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #304]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #288]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #768]
	ldr	q5, [sp, #320]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #336]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #320]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #800]
	ldr	q5, [sp, #352]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #368]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #352]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #832]
	ldr	q5, [sp, #384]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #400]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #384]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #864]
	ldr	q5, [sp, #416]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldr	q0, [sp, #432]                  ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [sp, #416]              ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #896]
	ldr	q5, [sp, #448]                  ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	str	q5, [sp, #448]                  ; 16-byte Folded Spill
	ldur	q0, [x29, #-256]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stur	q0, [x29, #-256]                ; 16-byte Folded Spill
	ldp	q0, q1, [x16, #928]
	ldur	q5, [x29, #-224]                ; 16-byte Folded Reload
	fmla.2d	v5, v0, v15[0]
	ldur	q0, [x29, #-208]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stp	q5, q0, [x29, #-224]            ; 32-byte Folded Spill
	ldp	q0, q1, [x16, #960]
	fmla.2d	v4, v0, v15[0]
	fmla.2d	v3, v1, v15[0]
	ldp	q0, q1, [x16, #992]
	fmla.2d	v2, v0, v15[0]
	ldur	q0, [x29, #-112]                ; 16-byte Folded Reload
	fmla.2d	v0, v1, v15[0]
	stur	q0, [x29, #-112]                ; 16-byte Folded Spill
	ldur	q1, [x29, #-112]                ; 16-byte Folded Reload
	add	x14, x14, #1024
	add	x15, x15, #8
	cmp	x14, #32, lsl #12               ; =131072
	b.ne	LBB0_9
; %bb.10:                               ;   in Loop: Header=BB0_8 Depth=1
	ldur	q0, [x29, #-144]                ; 16-byte Folded Reload
	stp	q0, q14, [x10]
	stp	q13, q12, [x10, #32]
	ldp	q5, q0, [x29, #-176]            ; 32-byte Folded Reload
	stp	q5, q11, [x13]
	stp	q10, q9, [x13, #32]
	stp	q0, q8, [x12]
	stp	q31, q30, [x12, #32]
	ldur	q0, [x29, #-128]                ; 16-byte Folded Reload
	stp	q0, q29, [x11]
	stp	q28, q27, [x11, #32]
	stp	q26, q25, [x10, #256]
	stp	q24, q23, [x10, #288]
	stp	q22, q21, [x10, #320]
	stp	q20, q19, [x10, #352]
	stp	q18, q17, [x10, #384]
	stp	q16, q7, [x10, #416]
	ldur	q0, [x29, #-240]                ; 16-byte Folded Reload
	stp	q6, q0, [x10, #448]
	ldur	q5, [x29, #-192]                ; 16-byte Folded Reload
	ldp	q6, q7, [sp, #48]               ; 32-byte Folded Reload
	stp	q5, q6, [x10, #480]
	ldp	q5, q6, [sp, #80]               ; 32-byte Folded Reload
	stp	q7, q5, [x10, #512]
	ldp	q5, q7, [sp, #112]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #544]
	ldp	q5, q6, [sp, #144]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #576]
	ldp	q5, q7, [sp, #176]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #608]
	ldp	q5, q6, [sp, #208]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #640]
	ldp	q5, q7, [sp, #240]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #672]
	ldp	q5, q6, [sp, #272]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #704]
	ldp	q5, q7, [sp, #304]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #736]
	ldp	q5, q6, [sp, #336]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #768]
	ldp	q5, q7, [sp, #368]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #800]
	ldp	q5, q6, [sp, #400]              ; 32-byte Folded Reload
	stp	q7, q5, [x10, #832]
	ldp	q5, q7, [sp, #432]              ; 32-byte Folded Reload
	stp	q6, q5, [x10, #864]
	ldur	q0, [x29, #-256]                ; 16-byte Folded Reload
	stp	q7, q0, [x10, #896]
	ldp	q5, q0, [x29, #-224]            ; 32-byte Folded Reload
	stp	q5, q0, [x10, #928]
	stp	q4, q3, [x10, #960]
	add	x9, x9, #1
	add	x8, x8, #1024
	stp	q2, q1, [x10, #992]
	cmp	x9, #128
	b.ne	LBB0_8
; %bb.11:
	ldr	d0, [x21]
	str	d0, [sp]
Lloh4:
	adrp	x0, l_.str@PAGE
Lloh5:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	x0, x20
	bl	_free
	mov	x0, x21
	bl	_free
	mov	w0, #0                          ; =0x0
LBB0_12:
	add	sp, sp, #624
	ldp	x29, x30, [sp, #96]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #80]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #64]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #48]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #32]             ; 16-byte Folded Reload
	ldp	d13, d12, [sp, #16]             ; 16-byte Folded Reload
	ldp	d15, d14, [sp], #112            ; 16-byte Folded Reload
	ret
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh4, Lloh5
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
