	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3, 0x0                          ; -- Begin function main
lCPI0_0:
	.long	2147483657                      ; 0x80000009
	.long	0                               ; 0x0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	stp	x28, x27, [sp, #-96]!           ; 16-byte Folded Spill
	stp	x26, x25, [sp, #16]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #32]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #48]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #64]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #80]             ; 16-byte Folded Spill
	add	x29, sp, #80
	sub	sp, sp, #464
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
	mov	x19, x1
	mov	x20, x0
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_getenv
	mov	x21, x0
Lloh2:
	adrp	x0, l_.str.1@PAGE
Lloh3:
	add	x0, x0, l_.str.1@PAGEOFF
	bl	_getenv
	mov	x22, x0
	cmp	w20, #2
	b.lt	LBB0_2
; %bb.1:
	ldr	x26, [x19, #8]
	cbz	x22, LBB0_3
	b	LBB0_6
LBB0_2:
Lloh4:
	adrp	x0, l_.str.2@PAGE
Lloh5:
	add	x0, x0, l_.str.2@PAGEOFF
	bl	_getenv
	mov	x26, x0
	cbnz	x22, LBB0_6
LBB0_3:
	cbnz	x21, LBB0_6
; %bb.4:
	cbnz	x26, LBB0_6
; %bb.5:
Lloh6:
	adrp	x0, l_str@PAGE
Lloh7:
	add	x0, x0, l_str@PAGEOFF
	bl	_puts
	mov	w0, #1                          ; =0x1
	b	LBB0_24
LBB0_6:
Lloh8:
	adrp	x0, l_.str.4@PAGE
Lloh9:
	add	x0, x0, l_.str.4@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_14
; %bb.7:
	bl	_atoi
	cmp	w0, #0
	cset	w28, eq
Lloh10:
	adrp	x0, l_.str.5@PAGE
Lloh11:
	add	x0, x0, l_.str.5@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_15
LBB0_8:
	bl	_atoi
	str	w0, [sp, #260]                  ; 4-byte Folded Spill
Lloh12:
	adrp	x0, l_.str.6@PAGE
Lloh13:
	add	x0, x0, l_.str.6@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_16
LBB0_9:
	bl	_atoi
	mov	x27, x0
Lloh14:
	adrp	x0, l_.str.7@PAGE
Lloh15:
	add	x0, x0, l_.str.7@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_17
LBB0_10:
	bl	_atoi
	cmp	w0, #0
	cset	w8, eq
	str	w8, [sp, #256]                  ; 4-byte Folded Spill
	stur	xzr, [x29, #-256]
	stp	xzr, xzr, [sp, #272]
	str	xzr, [sp, #264]
	cbz	x21, LBB0_18
LBB0_11:
Lloh16:
	adrp	x1, l_.str.13@PAGE
Lloh17:
	add	x1, x1, l_.str.13@PAGEOFF
	mov	x0, x21
	bl	_fopen
	cbz	x0, LBB0_23
; %bb.12:
	mov	x21, x0
	mov	x1, #0                          ; =0x0
	mov	w2, #2                          ; =0x2
	bl	_fseek
	cbz	w0, LBB0_25
LBB0_13:
	mov	x0, x21
	b	LBB0_22
LBB0_14:
	mov	w28, #1                         ; =0x1
Lloh18:
	adrp	x0, l_.str.5@PAGE
Lloh19:
	add	x0, x0, l_.str.5@PAGEOFF
	bl	_getenv
	cbnz	x0, LBB0_8
LBB0_15:
	str	wzr, [sp, #260]                 ; 4-byte Folded Spill
Lloh20:
	adrp	x0, l_.str.6@PAGE
Lloh21:
	add	x0, x0, l_.str.6@PAGEOFF
	bl	_getenv
	cbnz	x0, LBB0_9
LBB0_16:
	mov	w27, #0                         ; =0x0
Lloh22:
	adrp	x0, l_.str.7@PAGE
Lloh23:
	add	x0, x0, l_.str.7@PAGEOFF
	bl	_getenv
	cbnz	x0, LBB0_10
LBB0_17:
	mov	w8, #1                          ; =0x1
	str	w8, [sp, #256]                  ; 4-byte Folded Spill
	stur	xzr, [x29, #-256]
	stp	xzr, xzr, [sp, #272]
	str	xzr, [sp, #264]
	cbnz	x21, LBB0_11
LBB0_18:
	cbz	x22, LBB0_55
; %bb.19:
Lloh24:
	adrp	x1, l_.str.13@PAGE
Lloh25:
	add	x1, x1, l_.str.13@PAGEOFF
	mov	x0, x22
	bl	_fopen
	cbz	x0, LBB0_23
; %bb.20:
	mov	x20, x0
	mov	x1, #0                          ; =0x0
	mov	w2, #2                          ; =0x2
	bl	_fseek
	cbz	w0, LBB0_57
LBB0_21:
	mov	x0, x20
LBB0_22:
	bl	_fclose
LBB0_23:
	mov	w0, #2                          ; =0x2
LBB0_24:
	add	sp, sp, #464
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #32]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #16]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp], #96             ; 16-byte Folded Reload
	ret
LBB0_25:
	mov	x0, x21
	bl	_ftell
	cmp	x0, #0
	b.le	LBB0_65
; %bb.26:
	mov	x23, x0
	mov	x0, x21
	mov	x1, #0                          ; =0x0
	mov	w2, #0                          ; =0x0
	bl	_fseek
	cbnz	w0, LBB0_13
; %bb.27:
	add	x0, x23, #1
	bl	_malloc
	cbz	x0, LBB0_13
; %bb.28:
	mov	x22, x0
	mov	w25, #1                         ; =0x1
	mov	w1, #1                          ; =0x1
	mov	x2, x23
	mov	x3, x21
	bl	_fread
	mov	x23, x0
	strb	wzr, [x22, x0]
	sub	x8, x29, #248
	add	x8, x8, #96
	str	x8, [sp, #232]                  ; 8-byte Folded Spill
	cbz	w28, LBB0_104
; %bb.29:
	mov	x28, x27
	mov	x24, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	x8, #0                          ; =0x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x27, #435                       ; =0x1b3
	movk	x27, #256, lsl #32
	add	x9, x22, #1
	stp	xzr, x9, [sp, #240]             ; 16-byte Folded Spill
	mov	w20, #9217                      ; =0x2401
	b	LBB0_32
LBB0_30:                                ;   in Loop: Header=BB0_32 Depth=1
	mov	x26, x8
LBB0_31:                                ;   in Loop: Header=BB0_32 Depth=1
	cmp	x26, x23
	b.hi	LBB0_127
LBB0_32:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_37 Depth 2
                                        ;     Child Loop BB0_52 Depth 2
	ldrb	w9, [x22, x26]
	cmp	w9, #13
	lsl	w9, w25, w9
	and	w9, w9, w20
	ccmp	w9, #0, #4, ls
	b.eq	LBB0_38
; %bb.33:                               ;   in Loop: Header=BB0_32 Depth=1
	strb	wzr, [x22, x26]
	cmp	x26, x8
	b.ls	LBB0_51
; %bb.34:                               ;   in Loop: Header=BB0_32 Depth=1
	cbz	w28, LBB0_41
; %bb.35:                               ;   in Loop: Header=BB0_32 Depth=1
	ldrb	w10, [x22, x8]
	cbz	w10, LBB0_39
; %bb.36:                               ;   in Loop: Header=BB0_32 Depth=1
	mov	x11, #0                         ; =0x0
	ldr	x9, [sp, #248]                  ; 8-byte Folded Reload
	add	x9, x9, x8
LBB0_37:                                ;   Parent Loop BB0_32 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	sxtb	x10, w10
	eor	x10, x19, x10
	mul	x19, x10, x27
	add	x12, x11, #1
	ldrb	w10, [x9, x11]
	mov	x11, x12
	cbnz	w10, LBB0_37
	b	LBB0_40
LBB0_38:                                ;   in Loop: Header=BB0_32 Depth=1
	add	x26, x26, #1
	b	LBB0_31
LBB0_39:                                ;   in Loop: Header=BB0_32 Depth=1
	mov	x12, #0                         ; =0x0
LBB0_40:                                ;   in Loop: Header=BB0_32 Depth=1
	add	x24, x12, x24
LBB0_41:                                ;   in Loop: Header=BB0_32 Depth=1
	add	x0, x22, x8
	sub	x1, x29, #248
	bl	_lstat
	cbnz	w0, LBB0_51
; %bb.42:                               ;   in Loop: Header=BB0_32 Depth=1
	ldurh	w8, [x29, #-244]
	and	w8, w8, #0xf000
	cmp	w8, #4, lsl #12                 ; =16384
	b.eq	LBB0_46
; %bb.43:                               ;   in Loop: Header=BB0_32 Depth=1
	cmp	w8, #8, lsl #12                 ; =32768
	b.ne	LBB0_47
; %bb.44:                               ;   in Loop: Header=BB0_32 Depth=1
	ldr	x8, [sp, #240]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cbnz	w8, LBB0_51
; %bb.45:                               ;   in Loop: Header=BB0_32 Depth=1
	add	x9, sp, #272
	ldr	x10, [sp, #272]
	ldr	x8, [sp, #232]                  ; 8-byte Folded Reload
	b	LBB0_50
LBB0_46:                                ;   in Loop: Header=BB0_32 Depth=1
	add	x8, sp, #280
	mov	w10, #1                         ; =0x1
	add	x9, sp, #280
	b	LBB0_50
LBB0_47:                                ;   in Loop: Header=BB0_32 Depth=1
	cbz	w28, LBB0_51
; %bb.48:                               ;   in Loop: Header=BB0_32 Depth=1
	cmp	w8, #10, lsl #12                ; =40960
	b.ne	LBB0_51
; %bb.49:                               ;   in Loop: Header=BB0_32 Depth=1
	add	x8, sp, #264
	mov	w10, #1                         ; =0x1
	add	x9, sp, #264
LBB0_50:                                ;   in Loop: Header=BB0_32 Depth=1
	ldr	x8, [x8]
	add	x8, x8, x10
	str	x8, [x9]
LBB0_51:                                ;   in Loop: Header=BB0_32 Depth=1
	add	x8, x26, #1
	cmp	x8, x23
	b.hs	LBB0_30
LBB0_52:                                ;   Parent Loop BB0_32 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w9, [x22, x8]
	cmp	w9, #13
	ccmp	w9, #10, #4, ne
	b.ne	LBB0_30
; %bb.53:                               ;   in Loop: Header=BB0_52 Depth=2
	add	x8, x8, #1
	cmp	x23, x8
	b.ne	LBB0_52
; %bb.54:                               ;   in Loop: Header=BB0_32 Depth=1
	mov	x8, x23
	mov	x26, x23
	b	LBB0_31
LBB0_55:
Lloh26:
	adrp	x0, l_.str.8@PAGE
Lloh27:
	add	x0, x0, l_.str.8@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_66
; %bb.56:
	bl	_atoi
	mov	x23, x0
Lloh28:
	adrp	x0, l_.str.9@PAGE
Lloh29:
	add	x0, x0, l_.str.9@PAGEOFF
	bl	_getenv
	str	w23, [sp, #92]                  ; 4-byte Folded Spill
	cbnz	x0, LBB0_67
	b	LBB0_75
LBB0_57:
	mov	x0, x20
	bl	_ftell
	cmp	x0, #0
	b.le	LBB0_102
; %bb.58:
	mov	x23, x0
	mov	x0, x20
	mov	x1, #0                          ; =0x0
	mov	w2, #0                          ; =0x0
	bl	_fseek
	cbnz	w0, LBB0_21
; %bb.59:
	add	x0, x23, #1
	bl	_malloc
	cbz	x0, LBB0_21
; %bb.60:
	mov	w1, #1                          ; =0x1
	mov	x2, x23
	mov	x3, x20
	mov	x19, x0
	bl	_fread
	stp	x0, x19, [sp, #160]             ; 16-byte Folded Spill
	strb	wzr, [x19, x0]
	mov	w8, #1048576                    ; =0x100000
	mov	w9, #256                        ; =0x100
	movk	w9, #16, lsl #16
	cmp	w28, #0
	csel	w8, w9, w8, ne
	str	w8, [sp, #152]                  ; 4-byte Folded Spill
Lloh30:
	adrp	x0, l_.str.14@PAGE
Lloh31:
	add	x0, x0, l_.str.14@PAGEOFF
	bl	_getenv
	mov	w19, #8388608                   ; =0x800000
	cbz	x0, LBB0_62
; %bb.61:
	bl	_atoi
	cmp	w0, #1
	csel	w19, w19, w0, lt
LBB0_62:
	mov	x0, x19
	bl	_malloc
	cbz	x0, LBB0_227
; %bb.63:
	mov	x26, x0
	mov	w8, #5                          ; =0x5
	stur	w8, [x29, #-248]
Lloh32:
	adrp	x8, lCPI0_0@PAGE
Lloh33:
	ldr	d0, [x8, lCPI0_0@PAGEOFF]
	stur	d0, [x29, #-244]
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cmp	w8, #0
	cset	w8, eq
	lsl	w8, w8, #9
	stp	wzr, w8, [x29, #-236]
	stur	wzr, [x29, #-228]
Lloh34:
	adrp	x0, l_.str.15@PAGE
Lloh35:
	add	x0, x0, l_.str.15@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_230
; %bb.64:
	bl	_atoi
	cmp	w0, #0
	cset	w8, ne
	ubfiz	x8, x8, #3, #32
	b	LBB0_231
LBB0_65:
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x0, x21
	b	LBB0_103
LBB0_66:
	mov	w23, #6                         ; =0x6
Lloh36:
	adrp	x0, l_.str.9@PAGE
Lloh37:
	add	x0, x0, l_.str.9@PAGEOFF
	bl	_getenv
	str	w23, [sp, #92]                  ; 4-byte Folded Spill
	cbz	x0, LBB0_75
LBB0_67:
	ldrb	w8, [x0]
	cmp	w8, #98
	b.ne	LBB0_75
; %bb.68:
	str	w27, [sp, #228]                 ; 4-byte Folded Spill
	mov	w8, #1048576                    ; =0x100000
	mov	w9, #256                        ; =0x100
	movk	w9, #16, lsl #16
	cmp	w28, #0
	csel	w1, w9, w8, ne
	mov	x0, x26
	str	w1, [sp, #116]                  ; 4-byte Folded Spill
	bl	_open
	tbnz	w0, #31, LBB0_23
; %bb.69:
	mov	x27, x0
	mov	w0, #4608                       ; =0x1200
	movk	w0, #122, lsl #16
	bl	_malloc
	str	x0, [sp, #80]                   ; 8-byte Folded Spill
	cbz	x0, LBB0_130
; %bb.70:
Lloh38:
	adrp	x0, l_.str.14@PAGE
Lloh39:
	add	x0, x0, l_.str.14@PAGEOFF
	bl	_getenv
	mov	w20, #8388608                   ; =0x800000
	cbz	x0, LBB0_72
; %bb.71:
	bl	_atoi
	cmp	w0, #1
	csel	w20, w20, w0, lt
LBB0_72:
	mov	x0, x20
	bl	_malloc
	cbz	x0, LBB0_129
; %bb.73:
	str	x0, [sp, #176]                  ; 8-byte Folded Spill
	mov	w8, #5                          ; =0x5
	stur	w8, [x29, #-248]
Lloh40:
	adrp	x8, lCPI0_0@PAGE
Lloh41:
	ldr	d0, [x8, lCPI0_0@PAGEOFF]
	stur	d0, [x29, #-244]
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cmp	w8, #0
	cset	w8, eq
	lsl	w8, w8, #9
	stp	wzr, w8, [x29, #-236]
	stur	wzr, [x29, #-228]
Lloh42:
	adrp	x0, l_.str.15@PAGE
Lloh43:
	add	x0, x0, l_.str.15@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_131
; %bb.74:
	bl	_atoi
	cmp	w0, #0
	cset	w8, ne
	ubfiz	x8, x8, #3, #32
	b	LBB0_132
LBB0_75:
	stp	x26, xzr, [x29, #-248]
	mov	w8, #6                          ; =0x6
	mov	w9, #20                         ; =0x14
	cmp	w28, #0
	csel	w1, w9, w8, ne
	sub	x0, x29, #248
	mov	x2, #0                          ; =0x0
	bl	_fts_open
	cbz	x0, LBB0_23
; %bb.76:
	mov	x22, x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	bl	_fts_read
	cbz	x0, LBB0_100
; %bb.77:
	mov	x20, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
	mov	x24, #0                         ; =0x0
	mov	x25, #435                       ; =0x1b3
	movk	x25, #256, lsl #32
	b	LBB0_81
LBB0_78:                                ;   in Loop: Header=BB0_81 Depth=1
	mov	x11, #0                         ; =0x0
LBB0_79:                                ;   in Loop: Header=BB0_81 Depth=1
	add	x24, x11, x24
LBB0_80:                                ;   in Loop: Header=BB0_81 Depth=1
	mov	x0, x22
	bl	_fts_read
	cbz	x0, LBB0_99
LBB0_81:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_95 Depth 2
	tbnz	w23, #31, LBB0_85
; %bb.82:                               ;   in Loop: Header=BB0_81 Depth=1
	ldrsh	w8, [x0, #86]
	cmp	w23, w8
	b.gt	LBB0_85
; %bb.83:                               ;   in Loop: Header=BB0_81 Depth=1
	ldrh	w8, [x0, #88]
	cmp	w8, #1
	b.ne	LBB0_85
; %bb.84:                               ;   in Loop: Header=BB0_81 Depth=1
	mov	x23, x0
	mov	x0, x22
	mov	x1, x23
	mov	w2, #4                          ; =0x4
	bl	_fts_set
	mov	x0, x23
	ldr	w23, [sp, #92]                  ; 4-byte Folded Reload
LBB0_85:                                ;   in Loop: Header=BB0_81 Depth=1
	ldrh	w8, [x0, #88]
	cmp	w8, #1
	b.eq	LBB0_90
; %bb.86:                               ;   in Loop: Header=BB0_81 Depth=1
	cmp	w8, #8
	b.ne	LBB0_96
; %bb.87:                               ;   in Loop: Header=BB0_81 Depth=1
	add	x21, x21, #1
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cbnz	w8, LBB0_92
; %bb.88:                               ;   in Loop: Header=BB0_81 Depth=1
	ldr	x9, [x0, #96]
	cbz	x9, LBB0_92
; %bb.89:                               ;   in Loop: Header=BB0_81 Depth=1
	ldr	x8, [sp, #272]
	add	x9, x9, #96
	add	x10, sp, #272
	b	LBB0_91
LBB0_90:                                ;   in Loop: Header=BB0_81 Depth=1
	add	x9, sp, #280
	add	x10, sp, #280
LBB0_91:                                ;   in Loop: Header=BB0_81 Depth=1
	ldr	x9, [x9]
	add	x8, x9, x8
	str	x8, [x10]
LBB0_92:                                ;   in Loop: Header=BB0_81 Depth=1
	cbz	w27, LBB0_80
; %bb.93:                               ;   in Loop: Header=BB0_81 Depth=1
	ldr	x8, [x0, #48]
	ldrb	w9, [x8]
	cbz	w9, LBB0_78
LBB0_94:                                ;   in Loop: Header=BB0_81 Depth=1
	mov	x10, #0                         ; =0x0
	add	x8, x8, #1
LBB0_95:                                ;   Parent Loop BB0_81 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	sxtb	x9, w9
	eor	x9, x19, x9
	mul	x19, x9, x25
	add	x11, x10, #1
	ldrb	w9, [x8, x10]
	mov	x10, x11
	cbnz	w9, LBB0_95
	b	LBB0_79
LBB0_96:                                ;   in Loop: Header=BB0_81 Depth=1
	cbz	w27, LBB0_92
; %bb.97:                               ;   in Loop: Header=BB0_81 Depth=1
	cmp	w8, #12
	b.ne	LBB0_92
; %bb.98:                               ;   in Loop: Header=BB0_81 Depth=1
	add	x20, x20, #1
	ldr	x8, [x0, #48]
	ldrb	w9, [x8]
	cbnz	w9, LBB0_94
	b	LBB0_78
LBB0_99:
	stur	x21, [x29, #-256]
	str	x20, [sp, #264]
	b	LBB0_101
LBB0_100:
	mov	x24, #0                         ; =0x0
LBB0_101:
	mov	x0, x22
	bl	_fts_close
	b	LBB0_327
LBB0_102:
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x0, x20
LBB0_103:
	bl	_fclose
	mov	x22, #0                         ; =0x0
	mov	x20, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	stp	xzr, xzr, [sp, #232]            ; 16-byte Folded Spill
	mov	x24, #0                         ; =0x0
	b	LBB0_328
LBB0_104:
	cbz	w27, LBB0_210
; %bb.105:
	str	w27, [sp, #228]                 ; 4-byte Folded Spill
	mov	x24, #0                         ; =0x0
	mov	x20, #0                         ; =0x0
	mov	x8, #0                          ; =0x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x25, #435                       ; =0x1b3
	movk	x25, #256, lsl #32
	add	x9, x22, #1
	stp	xzr, x9, [sp, #240]             ; 16-byte Folded Spill
	mov	w27, #1                         ; =0x1
	mov	w28, #9217                      ; =0x2401
	b	LBB0_108
LBB0_106:                               ;   in Loop: Header=BB0_108 Depth=1
	mov	x20, x8
LBB0_107:                               ;   in Loop: Header=BB0_108 Depth=1
	cmp	x20, x23
	b.hi	LBB0_128
LBB0_108:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_112 Depth 2
                                        ;     Child Loop BB0_124 Depth 2
	ldrb	w9, [x22, x20]
	cmp	w9, #13
	lsl	w9, w27, w9
	and	w9, w9, w28
	ccmp	w9, #0, #4, ls
	b.eq	LBB0_113
; %bb.109:                              ;   in Loop: Header=BB0_108 Depth=1
	strb	wzr, [x22, x20]
	cmp	x20, x8
	b.ls	LBB0_123
; %bb.110:                              ;   in Loop: Header=BB0_108 Depth=1
	ldrb	w10, [x22, x8]
	cbz	w10, LBB0_114
; %bb.111:                              ;   in Loop: Header=BB0_108 Depth=1
	mov	x11, #0                         ; =0x0
	ldr	x9, [sp, #248]                  ; 8-byte Folded Reload
	add	x9, x9, x8
LBB0_112:                               ;   Parent Loop BB0_108 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	sxtb	x10, w10
	eor	x10, x19, x10
	mul	x19, x10, x25
	add	x26, x11, #1
	ldrb	w10, [x9, x11]
	mov	x11, x26
	cbnz	w10, LBB0_112
	b	LBB0_115
LBB0_113:                               ;   in Loop: Header=BB0_108 Depth=1
	add	x20, x20, #1
	b	LBB0_107
LBB0_114:                               ;   in Loop: Header=BB0_108 Depth=1
	mov	x26, #0                         ; =0x0
LBB0_115:                               ;   in Loop: Header=BB0_108 Depth=1
	add	x0, x22, x8
	sub	x1, x29, #248
	bl	_stat
	cbnz	w0, LBB0_122
; %bb.116:                              ;   in Loop: Header=BB0_108 Depth=1
	ldurh	w8, [x29, #-244]
	and	w8, w8, #0xf000
	cmp	w8, #4, lsl #12                 ; =16384
	b.eq	LBB0_120
; %bb.117:                              ;   in Loop: Header=BB0_108 Depth=1
	cmp	w8, #8, lsl #12                 ; =32768
	b.ne	LBB0_122
; %bb.118:                              ;   in Loop: Header=BB0_108 Depth=1
	ldr	x8, [sp, #240]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cbnz	w8, LBB0_122
; %bb.119:                              ;   in Loop: Header=BB0_108 Depth=1
	add	x8, sp, #272
	ldr	x10, [sp, #272]
	ldr	x9, [sp, #232]                  ; 8-byte Folded Reload
	b	LBB0_121
LBB0_120:                               ;   in Loop: Header=BB0_108 Depth=1
	add	x9, sp, #280
	mov	w10, #1                         ; =0x1
	add	x8, sp, #280
LBB0_121:                               ;   in Loop: Header=BB0_108 Depth=1
	ldr	x9, [x9]
	add	x9, x9, x10
	str	x9, [x8]
LBB0_122:                               ;   in Loop: Header=BB0_108 Depth=1
	add	x24, x26, x24
LBB0_123:                               ;   in Loop: Header=BB0_108 Depth=1
	add	x8, x20, #1
	cmp	x8, x23
	b.hs	LBB0_106
LBB0_124:                               ;   Parent Loop BB0_108 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w9, [x22, x8]
	cmp	w9, #13
	ccmp	w9, #10, #4, ne
	b.ne	LBB0_106
; %bb.125:                              ;   in Loop: Header=BB0_124 Depth=2
	add	x8, x8, #1
	cmp	x23, x8
	b.ne	LBB0_124
; %bb.126:                              ;   in Loop: Header=BB0_108 Depth=1
	mov	x8, x23
	mov	x20, x23
	b	LBB0_107
LBB0_127:
	ldr	x8, [sp, #240]                  ; 8-byte Folded Reload
	stur	x8, [x29, #-256]
	mov	x27, x28
	b	LBB0_326
LBB0_128:
	ldr	x8, [sp, #240]                  ; 8-byte Folded Reload
	stur	x8, [x29, #-256]
	ldr	w27, [sp, #228]                 ; 4-byte Folded Reload
	b	LBB0_326
LBB0_129:
	ldr	x0, [sp, #80]                   ; 8-byte Folded Reload
	bl	_free
LBB0_130:
	mov	x0, x27
	b	LBB0_209
LBB0_131:
	mov	w8, #8                          ; =0x8
LBB0_132:
	str	x8, [sp, #144]                  ; 8-byte Folded Spill
Lloh44:
	adrp	x0, l_.str.16@PAGE
Lloh45:
	add	x0, x0, l_.str.16@PAGEOFF
	bl	_getenv
	cbz	x0, LBB0_135
; %bb.133:
	bl	_atoi
	cbz	w0, LBB0_135
; %bb.134:
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	orr	x8, x8, #0x2
	str	x8, [sp, #144]                  ; 8-byte Folded Spill
LBB0_135:
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x23, #435                       ; =0x1b3
	movk	x23, #256, lsl #32
	mov	w8, w28
	stp	x8, x20, [sp, #128]             ; 16-byte Folded Spill
	ldr	x8, [sp, #80]                   ; 8-byte Folded Reload
	stp	w27, wzr, [x8]
	ldr	w27, [sp, #228]                 ; 4-byte Folded Reload
	ldr	x11, [sp, #176]                 ; 8-byte Folded Reload
	cbz	w27, LBB0_139
; %bb.136:
	ldrb	w9, [x26]
	cbz	w9, LBB0_139
; %bb.137:
	mov	x10, #0                         ; =0x0
	add	x8, x26, #1
LBB0_138:                               ; =>This Inner Loop Header: Depth=1
	sxtb	x9, w9
	eor	x9, x19, x9
	mul	x19, x9, x23
	add	x24, x10, #1
	ldrb	w9, [x8, x10]
	mov	x10, x24
	cbnz	w9, LBB0_138
	b	LBB0_140
LBB0_139:
	mov	x24, #0                         ; =0x0
LBB0_140:
	stp	xzr, xzr, [sp, #192]            ; 16-byte Folded Spill
	mov	x28, #0                         ; =0x0
	stp	xzr, xzr, [sp, #96]             ; 16-byte Folded Spill
	stp	xzr, xzr, [sp, #208]            ; 16-byte Folded Spill
	stp	xzr, xzr, [sp, #232]            ; 16-byte Folded Spill
	mov	w8, #1                          ; =0x1
	str	x8, [sp, #248]                  ; 8-byte Folded Spill
                                        ; implicit-def: $w21
	mov	w9, #1                          ; =0x1
	b	LBB0_142
LBB0_141:                               ;   in Loop: Header=BB0_142 Depth=1
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	bl	_close
	ldr	x11, [sp, #176]                 ; 8-byte Folded Reload
	ldr	x9, [sp, #152]                  ; 8-byte Folded Reload
	cbz	x9, LBB0_229
LBB0_142:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_150 Depth 2
                                        ;       Child Loop BB0_153 Depth 3
                                        ;         Child Loop BB0_171 Depth 4
                                        ;       Child Loop BB0_186 Depth 3
	sub	x9, x9, #1
	ldr	x8, [sp, #80]                   ; 8-byte Folded Reload
	add	x8, x8, x9, lsl #3
	ldp	w10, w22, [x8]
	str	w10, [sp, #184]                 ; 4-byte Folded Spill
	ldr	w8, [sp, #92]                   ; 4-byte Folded Reload
	str	x9, [sp, #152]                  ; 8-byte Folded Spill
	tbnz	w8, #31, LBB0_144
; %bb.143:                              ;   in Loop: Header=BB0_142 Depth=1
	cmp	w22, w8
	b.ge	LBB0_141
LBB0_144:                               ;   in Loop: Header=BB0_142 Depth=1
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_146
; %bb.145:                              ;   in Loop: Header=BB0_142 Depth=1
	sub	x1, x29, #248
	ldp	x3, x8, [sp, #136]              ; 16-byte Folded Reload
	ldr	x9, [sp, #128]                  ; 8-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x2, x11
	bl	_getattrlistbulk
	mov	x20, x0
	b	LBB0_147
LBB0_146:                               ;   in Loop: Header=BB0_142 Depth=1
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	mov	x20, x11
	bl	_clock_gettime
	ldp	x25, x26, [x29, #-104]
	sub	x1, x29, #248
	ldp	x3, x8, [sp, #136]              ; 16-byte Folded Reload
	ldr	x9, [sp, #128]                  ; 8-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x2, x20
	bl	_getattrlistbulk
	mov	x20, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	sub	x8, x8, x25
	ldr	x10, [sp, #240]                 ; 8-byte Folded Reload
	sub	x10, x10, x26
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x8, x8, x10, x9
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #216]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #216]                  ; 8-byte Folded Spill
LBB0_147:                               ;   in Loop: Header=BB0_142 Depth=1
	cmp	w20, #1
	b.lt	LBB0_141
; %bb.148:                              ;   in Loop: Header=BB0_142 Depth=1
	ldr	w8, [sp, #92]                   ; 4-byte Folded Reload
	cmp	w8, #0
	add	w9, w22, #1
	str	w9, [sp, #76]                   ; 4-byte Folded Spill
	ccmp	w9, w8, #8, ge
	cset	w8, lt
	str	w8, [sp, #168]                  ; 4-byte Folded Spill
	b	LBB0_150
LBB0_149:                               ;   in Loop: Header=BB0_150 Depth=2
	sub	x1, x29, #248
	ldp	x3, x8, [sp, #136]              ; 16-byte Folded Reload
	ldr	x9, [sp, #128]                  ; 8-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	bl	_getattrlistbulk
	mov	x20, x0
	ldr	w27, [sp, #228]                 ; 4-byte Folded Reload
	cmp	w20, #0
	b.le	LBB0_141
LBB0_150:                               ;   Parent Loop BB0_142 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_153 Depth 3
                                        ;         Child Loop BB0_171 Depth 4
                                        ;       Child Loop BB0_186 Depth 3
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_182
; %bb.151:                              ;   in Loop: Header=BB0_150 Depth=2
	str	xzr, [sp, #160]                 ; 8-byte Folded Spill
	ldr	x2, [sp, #176]                  ; 8-byte Folded Reload
	mov	x12, x28
	cbz	w27, LBB0_183
LBB0_152:                               ;   in Loop: Header=BB0_150 Depth=2
	mov	x26, #0                         ; =0x0
	mov	w27, #0                         ; =0x0
LBB0_153:                               ;   Parent Loop BB0_142 Depth=1
                                        ;     Parent Loop BB0_150 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_171 Depth 4
	add	x8, x2, x26
	ldr	w25, [x8]
	cbz	w25, LBB0_206
; %bb.154:                              ;   in Loop: Header=BB0_153 Depth=3
	ldr	w10, [x8, #4]
	tbnz	w10, #0, LBB0_167
; %bb.155:                              ;   in Loop: Header=BB0_153 Depth=3
	mov	x11, #0                         ; =0x0
	mov	w9, #24                         ; =0x18
	tbz	w10, #3, LBB0_168
LBB0_156:                               ;   in Loop: Header=BB0_153 Depth=3
	ldr	w10, [x8, x9]
	add	x11, x8, x11
	add	x28, x11, w21, sxtw
	cmp	w10, #1
	b.eq	LBB0_176
; %bb.157:                              ;   in Loop: Header=BB0_153 Depth=3
	cmp	w10, #5
	b.eq	LBB0_175
; %bb.158:                              ;   in Loop: Header=BB0_153 Depth=3
	cmp	w10, #2
	b.ne	LBB0_169
; %bb.159:                              ;   in Loop: Header=BB0_153 Depth=3
	ldrb	w8, [x28]
	cmp	w8, #46
	b.ne	LBB0_163
; %bb.160:                              ;   in Loop: Header=BB0_153 Depth=3
	ldrb	w8, [x28, #1]
	cbz	w8, LBB0_174
; %bb.161:                              ;   in Loop: Header=BB0_153 Depth=3
	cmp	w8, #46
	b.ne	LBB0_163
; %bb.162:                              ;   in Loop: Header=BB0_153 Depth=3
	ldrb	w8, [x28, #2]
	cbz	w8, LBB0_174
LBB0_163:                               ;   in Loop: Header=BB0_153 Depth=3
	ldr	x8, [sp, #248]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #248]                  ; 8-byte Folded Spill
	ldr	w8, [sp, #168]                  ; 4-byte Folded Reload
	cbz	w8, LBB0_169
; %bb.164:                              ;   in Loop: Header=BB0_153 Depth=3
	str	x12, [sp, #120]                 ; 8-byte Folded Spill
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_179
; %bb.165:                              ;   in Loop: Header=BB0_153 Depth=3
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x1, x28
	ldr	w2, [sp, #116]                  ; 4-byte Folded Reload
	bl	_openat
	mov	x22, x0
	ldr	x12, [sp, #120]                 ; 8-byte Folded Reload
	tbz	w22, #31, LBB0_180
LBB0_166:                               ;   in Loop: Header=BB0_153 Depth=3
	ldr	x2, [sp, #176]                  ; 8-byte Folded Reload
	b	LBB0_169
LBB0_167:                               ;   in Loop: Header=BB0_153 Depth=3
	ldr	w21, [x8, #24]
	mov	w9, #32                         ; =0x20
	mov	w11, #24                        ; =0x18
	tbnz	w10, #3, LBB0_156
LBB0_168:                               ;   in Loop: Header=BB0_153 Depth=3
	add	x8, x8, x11
	add	x28, x8, w21, sxtw
LBB0_169:                               ;   in Loop: Header=BB0_153 Depth=3
	ldrb	w9, [x28]
	cbz	w9, LBB0_172
; %bb.170:                              ;   in Loop: Header=BB0_153 Depth=3
	mov	x10, #0                         ; =0x0
	add	x8, x28, #1
LBB0_171:                               ;   Parent Loop BB0_142 Depth=1
                                        ;     Parent Loop BB0_150 Depth=2
                                        ;       Parent Loop BB0_153 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	sxtb	x9, w9
	eor	x9, x19, x9
	mul	x19, x9, x23
	add	x11, x10, #1
	ldrb	w9, [x8, x10]
	mov	x10, x11
	cbnz	w9, LBB0_171
	b	LBB0_173
LBB0_172:                               ;   in Loop: Header=BB0_153 Depth=3
	mov	x11, #0                         ; =0x0
LBB0_173:                               ;   in Loop: Header=BB0_153 Depth=3
	add	x24, x11, x24
LBB0_174:                               ;   in Loop: Header=BB0_153 Depth=3
	add	x26, x26, x25
	add	w27, w27, #1
	cmp	w27, w20
	b.ne	LBB0_153
	b	LBB0_205
LBB0_175:                               ;   in Loop: Header=BB0_153 Depth=3
	ldr	x8, [sp, #200]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #200]                  ; 8-byte Folded Spill
	b	LBB0_169
LBB0_176:                               ;   in Loop: Header=BB0_153 Depth=3
	add	x12, x12, #1
	ldr	w10, [sp, #260]                 ; 4-byte Folded Reload
	cbnz	w10, LBB0_169
; %bb.177:                              ;   in Loop: Header=BB0_153 Depth=3
	ldr	w10, [x8, #16]
	tbz	w10, #9, LBB0_169
; %bb.178:                              ;   in Loop: Header=BB0_153 Depth=3
	orr	x9, x9, #0x4
	ldr	x8, [x8, x9]
	ldr	x9, [sp, #192]                  ; 8-byte Folded Reload
	add	x9, x9, x8
	str	x9, [sp, #192]                  ; 8-byte Folded Spill
	b	LBB0_169
LBB0_179:                               ;   in Loop: Header=BB0_153 Depth=3
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x9, x8, [x29, #-104]
	stp	x8, x9, [sp, #56]               ; 16-byte Folded Spill
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x1, x28
	ldr	w2, [sp, #116]                  ; 4-byte Folded Reload
	bl	_openat
	mov	x22, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	ldp	x11, x10, [sp, #56]             ; 16-byte Folded Reload
	sub	x8, x8, x10
	ldr	x10, [sp, #96]                  ; 8-byte Folded Reload
	sub	x10, x10, x11
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x11, x8, x10, x9
	ldr	x8, [sp, #104]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	stp	x11, x8, [sp, #96]              ; 16-byte Folded Spill
	ldr	x12, [sp, #120]                 ; 8-byte Folded Reload
	tbnz	w22, #31, LBB0_166
LBB0_180:                               ;   in Loop: Header=BB0_153 Depth=3
	mov	w8, #16959                      ; =0x423f
	movk	w8, #15, lsl #16
	ldr	x9, [sp, #152]                  ; 8-byte Folded Reload
	cmp	x9, x8
	ldr	x2, [sp, #176]                  ; 8-byte Folded Reload
	b.hi	LBB0_208
; %bb.181:                              ;   in Loop: Header=BB0_153 Depth=3
	ldr	x8, [sp, #80]                   ; 8-byte Folded Reload
	add	x8, x8, x9, lsl #3
	ldr	w10, [sp, #76]                  ; 4-byte Folded Reload
	stp	w22, w10, [x8]
	add	x9, x9, #1
	str	x9, [sp, #152]                  ; 8-byte Folded Spill
	b	LBB0_169
LBB0_182:                               ;   in Loop: Header=BB0_150 Depth=2
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	neg	x9, x9
	mov	x10, #-51712                    ; =0xffffffffffff3600
	movk	x10, #50277, lsl #16
	madd	x8, x8, x10, x9
	str	x8, [sp, #160]                  ; 8-byte Folded Spill
	ldr	x2, [sp, #176]                  ; 8-byte Folded Reload
	mov	x12, x28
	cbnz	w27, LBB0_152
LBB0_183:                               ;   in Loop: Header=BB0_150 Depth=2
	mov	x25, #0                         ; =0x0
	b	LBB0_186
LBB0_184:                               ;   in Loop: Header=BB0_186 Depth=3
	ldr	x8, [sp, #80]                   ; 8-byte Folded Reload
	add	x8, x8, x9, lsl #3
	ldr	w10, [sp, #76]                  ; 4-byte Folded Reload
	stp	w22, w10, [x8]
	add	x9, x9, #1
	str	x9, [sp, #152]                  ; 8-byte Folded Spill
LBB0_185:                               ;   in Loop: Header=BB0_186 Depth=3
	add	x25, x25, x26
	add	w27, w27, #1
	cmp	w20, w27
	b.eq	LBB0_205
LBB0_186:                               ;   Parent Loop BB0_142 Depth=1
                                        ;     Parent Loop BB0_150 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	add	x8, x2, x25
	ldr	w26, [x8]
	cbz	w26, LBB0_206
; %bb.187:                              ;   in Loop: Header=BB0_186 Depth=3
	ldr	w10, [x8, #4]
	tbnz	w10, #0, LBB0_189
; %bb.188:                              ;   in Loop: Header=BB0_186 Depth=3
	mov	x11, #0                         ; =0x0
	mov	w9, #24                         ; =0x18
	tbz	w10, #3, LBB0_185
	b	LBB0_190
LBB0_189:                               ;   in Loop: Header=BB0_186 Depth=3
	ldr	w21, [x8, #24]
	mov	w9, #32                         ; =0x20
	mov	w11, #24                        ; =0x18
	tbz	w10, #3, LBB0_185
LBB0_190:                               ;   in Loop: Header=BB0_186 Depth=3
	ldr	w10, [x8, x9]
	cmp	w10, #2
	b.eq	LBB0_195
; %bb.191:                              ;   in Loop: Header=BB0_186 Depth=3
	cmp	w10, #1
	b.ne	LBB0_185
; %bb.192:                              ;   in Loop: Header=BB0_186 Depth=3
	add	x12, x12, #1
	ldr	w10, [sp, #260]                 ; 4-byte Folded Reload
	cbnz	w10, LBB0_185
; %bb.193:                              ;   in Loop: Header=BB0_186 Depth=3
	ldr	w10, [x8, #16]
	tbz	w10, #9, LBB0_185
; %bb.194:                              ;   in Loop: Header=BB0_186 Depth=3
	orr	x9, x9, #0x4
	ldr	x8, [x8, x9]
	ldr	x9, [sp, #192]                  ; 8-byte Folded Reload
	add	x9, x9, x8
	str	x9, [sp, #192]                  ; 8-byte Folded Spill
	b	LBB0_185
LBB0_195:                               ;   in Loop: Header=BB0_186 Depth=3
	add	x8, x8, x11
	add	x22, x8, w21, sxtw
	ldrb	w8, [x22]
	cmp	w8, #46
	b.ne	LBB0_199
; %bb.196:                              ;   in Loop: Header=BB0_186 Depth=3
	ldrb	w8, [x22, #1]
	cbz	w8, LBB0_185
; %bb.197:                              ;   in Loop: Header=BB0_186 Depth=3
	cmp	w8, #46
	b.ne	LBB0_199
; %bb.198:                              ;   in Loop: Header=BB0_186 Depth=3
	ldrb	w8, [x22, #2]
	cbz	w8, LBB0_185
LBB0_199:                               ;   in Loop: Header=BB0_186 Depth=3
	ldr	x8, [sp, #248]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #248]                  ; 8-byte Folded Spill
	ldr	w8, [sp, #168]                  ; 4-byte Folded Reload
	cbz	w8, LBB0_185
; %bb.200:                              ;   in Loop: Header=BB0_186 Depth=3
	mov	x28, x12
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_202
; %bb.201:                              ;   in Loop: Header=BB0_186 Depth=3
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x1, x22
	ldr	w2, [sp, #116]                  ; 4-byte Folded Reload
	bl	_openat
	mov	x22, x0
	b	LBB0_203
LBB0_202:                               ;   in Loop: Header=BB0_186 Depth=3
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x9, x8, [x29, #-104]
	str	x9, [sp, #120]                  ; 8-byte Folded Spill
	str	x8, [sp, #64]                   ; 8-byte Folded Spill
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x1, x22
	ldr	w2, [sp, #116]                  ; 4-byte Folded Reload
	bl	_openat
	mov	x22, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	ldr	x10, [sp, #120]                 ; 8-byte Folded Reload
	sub	x8, x8, x10
	ldr	x10, [sp, #96]                  ; 8-byte Folded Reload
	ldr	x11, [sp, #64]                  ; 8-byte Folded Reload
	sub	x10, x10, x11
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x11, x8, x10, x9
	ldr	x8, [sp, #104]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	stp	x11, x8, [sp, #96]              ; 16-byte Folded Spill
LBB0_203:                               ;   in Loop: Header=BB0_186 Depth=3
	ldr	x2, [sp, #176]                  ; 8-byte Folded Reload
	mov	x12, x28
	tbnz	w22, #31, LBB0_185
; %bb.204:                              ;   in Loop: Header=BB0_186 Depth=3
	mov	w8, #16959                      ; =0x423f
	movk	w8, #15, lsl #16
	ldr	x9, [sp, #152]                  ; 8-byte Folded Reload
	cmp	x9, x8
	b.ls	LBB0_184
	b	LBB0_208
LBB0_205:                               ;   in Loop: Header=BB0_150 Depth=2
	mov	x27, x20
LBB0_206:                               ;   in Loop: Header=BB0_150 Depth=2
	mov	x28, x12
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbnz	w8, #0, LBB0_149
; %bb.207:                              ;   in Loop: Header=BB0_150 Depth=2
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	mov	x20, x2
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	ldr	x10, [sp, #232]                 ; 8-byte Folded Reload
	ldr	x11, [sp, #160]                 ; 8-byte Folded Reload
	add	x10, x11, x10
	add	x9, x10, x9
	mov	w26, #51712                     ; =0xca00
	movk	w26, #15258, lsl #16
	madd	x8, x8, x26, x9
	str	x8, [sp, #232]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #208]                  ; 8-byte Folded Reload
	add	x8, x8, w27, uxtw
	str	x8, [sp, #208]                  ; 8-byte Folded Spill
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x22, x25, [x29, #-104]
	sub	x1, x29, #248
	ldp	x3, x8, [sp, #136]              ; 16-byte Folded Reload
	ldr	x9, [sp, #128]                  ; 8-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
	mov	x2, x20
	bl	_getattrlistbulk
	mov	x20, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	sub	x8, x8, x22
	ldr	x10, [sp, #240]                 ; 8-byte Folded Reload
	sub	x10, x10, x25
	add	x9, x10, x9
	madd	x8, x8, x26, x9
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #216]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #216]                  ; 8-byte Folded Spill
	ldr	w27, [sp, #228]                 ; 4-byte Folded Reload
	cmp	w20, #0
	b.gt	LBB0_150
	b	LBB0_141
LBB0_208:
	mov	x0, x22
	bl	_close
	ldr	x0, [sp, #176]                  ; 8-byte Folded Reload
	bl	_free
	ldr	x0, [sp, #80]                   ; 8-byte Folded Reload
	bl	_free
	ldr	w0, [sp, #184]                  ; 4-byte Folded Reload
LBB0_209:
	bl	_close
	mov	w0, #2                          ; =0x2
	b	LBB0_24
LBB0_210:
	ldr	w8, [sp, #260]                  ; 4-byte Folded Reload
	cbz	w8, LBB0_309
; %bb.211:
	mov	x24, #0                         ; =0x0
	mov	x8, #0                          ; =0x0
	mov	w19, #1                         ; =0x1
	mov	w20, #9217                      ; =0x2401
	b	LBB0_214
LBB0_212:                               ;   in Loop: Header=BB0_214 Depth=1
	mov	x24, x8
LBB0_213:                               ;   in Loop: Header=BB0_214 Depth=1
	cmp	x24, x23
	b.hi	LBB0_228
LBB0_214:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_224 Depth 2
	ldrb	w9, [x22, x24]
	cmp	w9, #13
	lsl	w9, w19, w9
	and	w9, w9, w20
	ccmp	w9, #0, #4, ls
	b.eq	LBB0_220
; %bb.215:                              ;   in Loop: Header=BB0_214 Depth=1
	strb	wzr, [x22, x24]
	cmp	x24, x8
	b.ls	LBB0_223
; %bb.216:                              ;   in Loop: Header=BB0_214 Depth=1
	add	x0, x22, x8
	sub	x1, x29, #248
	bl	_stat
	cbnz	w0, LBB0_223
; %bb.217:                              ;   in Loop: Header=BB0_214 Depth=1
	ldurh	w8, [x29, #-244]
	and	w8, w8, #0xf000
	cmp	w8, #4, lsl #12                 ; =16384
	b.eq	LBB0_221
; %bb.218:                              ;   in Loop: Header=BB0_214 Depth=1
	cmp	w8, #8, lsl #12                 ; =32768
	b.ne	LBB0_223
; %bb.219:                              ;   in Loop: Header=BB0_214 Depth=1
	sub	x8, x29, #256
	b	LBB0_222
LBB0_220:                               ;   in Loop: Header=BB0_214 Depth=1
	add	x24, x24, #1
	b	LBB0_213
LBB0_221:                               ;   in Loop: Header=BB0_214 Depth=1
	add	x8, sp, #280
LBB0_222:                               ;   in Loop: Header=BB0_214 Depth=1
	ldr	x9, [x8]
	add	x9, x9, #1
	str	x9, [x8]
LBB0_223:                               ;   in Loop: Header=BB0_214 Depth=1
	add	x8, x24, #1
	cmp	x8, x23
	b.hs	LBB0_212
LBB0_224:                               ;   Parent Loop BB0_214 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w9, [x22, x8]
	cmp	w9, #13
	ccmp	w9, #10, #4, ne
	b.ne	LBB0_212
; %bb.225:                              ;   in Loop: Header=BB0_224 Depth=2
	add	x8, x8, #1
	cmp	x23, x8
	b.ne	LBB0_224
; %bb.226:                              ;   in Loop: Header=BB0_214 Depth=1
	mov	x8, x23
	mov	x24, x23
	b	LBB0_213
LBB0_227:
	ldr	x0, [sp, #168]                  ; 8-byte Folded Reload
	bl	_free
	b	LBB0_21
LBB0_228:
	mov	x24, #0                         ; =0x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	b	LBB0_326
LBB0_229:
	stur	x28, [x29, #-256]
	ldr	x9, [sp, #192]                  ; 8-byte Folded Reload
	ldr	x8, [sp, #248]                  ; 8-byte Folded Reload
	stp	x9, x8, [sp, #272]
	ldr	x8, [sp, #200]                  ; 8-byte Folded Reload
	str	x8, [sp, #264]
	mov	x0, x11
	bl	_free
	ldr	x0, [sp, #80]                   ; 8-byte Folded Reload
	bl	_free
	ldp	x20, x21, [sp, #208]            ; 16-byte Folded Reload
	ldp	x23, x22, [sp, #96]             ; 16-byte Folded Reload
	b	LBB0_328
LBB0_230:
	mov	w8, #8                          ; =0x8
LBB0_231:
	str	x8, [sp, #200]                  ; 8-byte Folded Spill
Lloh46:
	adrp	x0, l_.str.16@PAGE
Lloh47:
	add	x0, x0, l_.str.16@PAGEOFF
	bl	_getenv
	str	x19, [sp, #184]                 ; 8-byte Folded Spill
	str	w27, [sp, #228]                 ; 4-byte Folded Spill
	str	x20, [sp, #136]                 ; 8-byte Folded Spill
	cbz	x0, LBB0_234
; %bb.232:
	bl	_atoi
	cbz	w0, LBB0_234
; %bb.233:
	ldr	x8, [sp, #200]                  ; 8-byte Folded Reload
	orr	x8, x8, #0x2
	str	x8, [sp, #200]                  ; 8-byte Folded Spill
LBB0_234:
	mov	x21, #0                         ; =0x0
	mov	x25, #0                         ; =0x0
	stp	xzr, xzr, [sp, #208]            ; 16-byte Folded Spill
	stp	xzr, xzr, [sp, #232]            ; 16-byte Folded Spill
	mov	x24, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x22, #0                         ; =0x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	mov	x20, #435                       ; =0x1b3
	movk	x20, #256, lsl #32
                                        ; implicit-def: $w27
	ldp	x10, x9, [sp, #160]             ; 16-byte Folded Reload
	add	x8, x9, #1
	str	x8, [sp, #144]                  ; 8-byte Folded Spill
	mov	w11, #1                         ; =0x1
	mov	w12, #9217                      ; =0x2401
	mov	w8, w28
	str	x8, [sp, #192]                  ; 8-byte Folded Spill
	b	LBB0_237
LBB0_235:                               ;   in Loop: Header=BB0_237 Depth=1
	mov	x13, x22
LBB0_236:                               ;   in Loop: Header=BB0_237 Depth=1
	cmp	x13, x10
	b.hi	LBB0_308
LBB0_237:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_243 Depth 2
                                        ;     Child Loop BB0_259 Depth 2
                                        ;       Child Loop BB0_262 Depth 3
                                        ;         Child Loop BB0_277 Depth 4
                                        ;       Child Loop BB0_290 Depth 3
                                        ;     Child Loop BB0_255 Depth 2
	ldrb	w8, [x9, x13]
	cmp	w8, #13
	lsl	w8, w11, w8
	and	w8, w8, w12
	ccmp	w8, #0, #4, ls
	b.eq	LBB0_244
; %bb.238:                              ;   in Loop: Header=BB0_237 Depth=1
	strb	wzr, [x9, x13]
	cmp	x13, x22
	b.ls	LBB0_254
; %bb.239:                              ;   in Loop: Header=BB0_237 Depth=1
	str	x13, [sp, #176]                 ; 8-byte Folded Spill
	add	x0, x9, x22
	ldr	w1, [sp, #152]                  ; 4-byte Folded Reload
	bl	_open
	str	w0, [sp, #248]                  ; 4-byte Folded Spill
	tbnz	w0, #31, LBB0_253
; %bb.240:                              ;   in Loop: Header=BB0_237 Depth=1
	ldr	x8, [sp, #280]
	add	x8, x8, #1
	str	x8, [sp, #280]
	ldr	w8, [sp, #228]                  ; 4-byte Folded Reload
	cbz	w8, LBB0_245
; %bb.241:                              ;   in Loop: Header=BB0_237 Depth=1
	ldr	x8, [sp, #168]                  ; 8-byte Folded Reload
	ldrb	w9, [x8, x22]
	cbz	w9, LBB0_246
; %bb.242:                              ;   in Loop: Header=BB0_237 Depth=1
	mov	x10, #0                         ; =0x0
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	add	x8, x8, x22
	ldr	x22, [sp, #184]                 ; 8-byte Folded Reload
LBB0_243:                               ;   Parent Loop BB0_237 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	sxtb	x9, w9
	eor	x9, x19, x9
	mul	x19, x9, x20
	add	x11, x10, #1
	ldrb	w9, [x8, x10]
	mov	x10, x11
	cbnz	w9, LBB0_243
	b	LBB0_247
LBB0_244:                               ;   in Loop: Header=BB0_237 Depth=1
	add	x13, x13, #1
	b	LBB0_236
LBB0_245:                               ;   in Loop: Header=BB0_237 Depth=1
	ldr	x22, [sp, #184]                 ; 8-byte Folded Reload
	b	LBB0_248
LBB0_246:                               ;   in Loop: Header=BB0_237 Depth=1
	mov	x11, #0                         ; =0x0
	ldr	x22, [sp, #184]                 ; 8-byte Folded Reload
LBB0_247:                               ;   in Loop: Header=BB0_237 Depth=1
	add	x24, x11, x24
LBB0_248:                               ;   in Loop: Header=BB0_237 Depth=1
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_250
; %bb.249:                              ;   in Loop: Header=BB0_237 Depth=1
	sub	x1, x29, #248
	ldp	x9, x8, [sp, #192]              ; 16-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #248]                  ; 4-byte Folded Reload
	mov	x2, x26
	mov	x3, x22
	bl	_getattrlistbulk
	mov	x22, x0
	b	LBB0_251
LBB0_250:                               ;   in Loop: Header=BB0_237 Depth=1
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x23, x28, [x29, #-104]
	sub	x1, x29, #248
	ldp	x9, x8, [sp, #192]              ; 16-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #248]                  ; 4-byte Folded Reload
	mov	x2, x26
	mov	x3, x22
	bl	_getattrlistbulk
	mov	x22, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	sub	x8, x8, x23
	ldr	x10, [sp, #240]                 ; 8-byte Folded Reload
	sub	x10, x10, x28
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x8, x8, x10, x9
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #216]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #216]                  ; 8-byte Folded Spill
LBB0_251:                               ;   in Loop: Header=BB0_237 Depth=1
	cmp	w22, #1
	b.ge	LBB0_259
LBB0_252:                               ;   in Loop: Header=BB0_237 Depth=1
	ldr	w0, [sp, #248]                  ; 4-byte Folded Reload
	bl	_close
LBB0_253:                               ;   in Loop: Header=BB0_237 Depth=1
	ldp	x10, x9, [sp, #160]             ; 16-byte Folded Reload
	mov	w11, #1                         ; =0x1
	mov	w12, #9217                      ; =0x2401
	ldr	x13, [sp, #176]                 ; 8-byte Folded Reload
LBB0_254:                               ;   in Loop: Header=BB0_237 Depth=1
	add	x22, x13, #1
	cmp	x22, x10
	b.hs	LBB0_235
LBB0_255:                               ;   Parent Loop BB0_237 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w8, [x9, x22]
	cmp	w8, #13
	ccmp	w8, #10, #4, ne
	b.ne	LBB0_235
; %bb.256:                              ;   in Loop: Header=BB0_255 Depth=2
	add	x22, x22, #1
	cmp	x10, x22
	b.ne	LBB0_255
; %bb.257:                              ;   in Loop: Header=BB0_237 Depth=1
	mov	x22, x10
	mov	x13, x10
	b	LBB0_236
LBB0_258:                               ;   in Loop: Header=BB0_259 Depth=2
	sub	x1, x29, #248
	ldp	x9, x8, [sp, #192]              ; 16-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #248]                  ; 4-byte Folded Reload
	mov	x2, x26
	mov	x3, x22
	bl	_getattrlistbulk
	mov	x22, x0
	cmp	w22, #0
	b.le	LBB0_252
LBB0_259:                               ;   Parent Loop BB0_237 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_262 Depth 3
                                        ;         Child Loop BB0_277 Depth 4
                                        ;       Child Loop BB0_290 Depth 3
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_285
; %bb.260:                              ;   in Loop: Header=BB0_259 Depth=2
	mov	x23, #0                         ; =0x0
	ldr	w8, [sp, #228]                  ; 4-byte Folded Reload
	cbz	w8, LBB0_286
LBB0_261:                               ;   in Loop: Header=BB0_259 Depth=2
	mov	x10, #0                         ; =0x0
	mov	w28, #0                         ; =0x0
	ldp	x8, x9, [sp, #272]
LBB0_262:                               ;   Parent Loop BB0_237 Depth=1
                                        ;     Parent Loop BB0_259 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB0_277 Depth 4
	add	x13, x26, x10
	ldr	w11, [x13]
	cbz	w11, LBB0_304
; %bb.263:                              ;   in Loop: Header=BB0_262 Depth=3
	ldr	w12, [x13, #4]
	tbnz	w12, #0, LBB0_273
; %bb.264:                              ;   in Loop: Header=BB0_262 Depth=3
	mov	x15, #0                         ; =0x0
	mov	w14, #24                        ; =0x18
	tbz	w12, #3, LBB0_274
LBB0_265:                               ;   in Loop: Header=BB0_262 Depth=3
	ldr	w16, [x13, x14]
	add	x12, x13, x15
	add	x12, x12, w27, sxtw
	cmp	w16, #1
	b.eq	LBB0_282
; %bb.266:                              ;   in Loop: Header=BB0_262 Depth=3
	cmp	w16, #5
	b.eq	LBB0_281
; %bb.267:                              ;   in Loop: Header=BB0_262 Depth=3
	cmp	w16, #2
	b.ne	LBB0_275
; %bb.268:                              ;   in Loop: Header=BB0_262 Depth=3
	ldrb	w13, [x12]
	cmp	w13, #46
	b.ne	LBB0_272
; %bb.269:                              ;   in Loop: Header=BB0_262 Depth=3
	ldrb	w13, [x12, #1]
	cbz	w13, LBB0_280
; %bb.270:                              ;   in Loop: Header=BB0_262 Depth=3
	cmp	w13, #46
	b.ne	LBB0_272
; %bb.271:                              ;   in Loop: Header=BB0_262 Depth=3
	ldrb	w13, [x12, #2]
	cbz	w13, LBB0_280
LBB0_272:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x9, x9, #1
	b	LBB0_275
LBB0_273:                               ;   in Loop: Header=BB0_262 Depth=3
	ldr	w27, [x13, #24]
	mov	w14, #32                        ; =0x20
	mov	w15, #24                        ; =0x18
	tbnz	w12, #3, LBB0_265
LBB0_274:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x12, x13, x15
	add	x12, x12, w27, sxtw
LBB0_275:                               ;   in Loop: Header=BB0_262 Depth=3
	ldrb	w13, [x12]
	cbz	w13, LBB0_278
; %bb.276:                              ;   in Loop: Header=BB0_262 Depth=3
	mov	x14, #0                         ; =0x0
	add	x12, x12, #1
LBB0_277:                               ;   Parent Loop BB0_237 Depth=1
                                        ;     Parent Loop BB0_259 Depth=2
                                        ;       Parent Loop BB0_262 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	sxtb	x13, w13
	eor	x13, x19, x13
	mul	x19, x13, x20
	add	x15, x14, #1
	ldrb	w13, [x12, x14]
	mov	x14, x15
	cbnz	w13, LBB0_277
	b	LBB0_279
LBB0_278:                               ;   in Loop: Header=BB0_262 Depth=3
	mov	x15, #0                         ; =0x0
LBB0_279:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x24, x15, x24
LBB0_280:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x10, x10, x11
	add	w28, w28, #1
	cmp	w28, w22
	b.ne	LBB0_262
	b	LBB0_303
LBB0_281:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x21, x21, #1
	b	LBB0_275
LBB0_282:                               ;   in Loop: Header=BB0_262 Depth=3
	add	x25, x25, #1
	ldr	w15, [sp, #260]                 ; 4-byte Folded Reload
	cbnz	w15, LBB0_275
; %bb.283:                              ;   in Loop: Header=BB0_262 Depth=3
	ldr	w15, [x13, #16]
	tbz	w15, #9, LBB0_275
; %bb.284:                              ;   in Loop: Header=BB0_262 Depth=3
	orr	x14, x14, #0x4
	ldr	x13, [x13, x14]
	add	x8, x8, x13
	b	LBB0_275
LBB0_285:                               ;   in Loop: Header=BB0_259 Depth=2
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	neg	x9, x9
	mov	x10, #-51712                    ; =0xffffffffffff3600
	movk	x10, #50277, lsl #16
	madd	x23, x8, x10, x9
	ldr	w8, [sp, #228]                  ; 4-byte Folded Reload
	cbnz	w8, LBB0_261
LBB0_286:                               ;   in Loop: Header=BB0_259 Depth=2
	mov	x8, #0                          ; =0x0
	mov	w28, #0                         ; =0x0
	b	LBB0_290
LBB0_287:                               ;   in Loop: Header=BB0_290 Depth=3
	add	x10, sp, #280
	mov	w11, #1                         ; =0x1
LBB0_288:                               ;   in Loop: Header=BB0_290 Depth=3
	ldr	x12, [x10]
	add	x11, x12, x11
	str	x11, [x10]
LBB0_289:                               ;   in Loop: Header=BB0_290 Depth=3
	add	x8, x8, x9
	add	w28, w28, #1
	cmp	w22, w28
	b.eq	LBB0_307
LBB0_290:                               ;   Parent Loop BB0_237 Depth=1
                                        ;     Parent Loop BB0_259 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	add	x10, x26, x8
	ldr	w9, [x10]
	cbz	w9, LBB0_305
; %bb.291:                              ;   in Loop: Header=BB0_290 Depth=3
	ldr	w12, [x10, #4]
	tbnz	w12, #0, LBB0_293
; %bb.292:                              ;   in Loop: Header=BB0_290 Depth=3
	mov	x13, #0                         ; =0x0
	mov	w11, #24                        ; =0x18
	tbz	w12, #3, LBB0_289
	b	LBB0_294
LBB0_293:                               ;   in Loop: Header=BB0_290 Depth=3
	ldr	w27, [x10, #24]
	mov	w11, #32                        ; =0x20
	mov	w13, #24                        ; =0x18
	tbz	w12, #3, LBB0_289
LBB0_294:                               ;   in Loop: Header=BB0_290 Depth=3
	ldr	w12, [x10, x11]
	cmp	w12, #2
	b.eq	LBB0_299
; %bb.295:                              ;   in Loop: Header=BB0_290 Depth=3
	cmp	w12, #1
	b.ne	LBB0_289
; %bb.296:                              ;   in Loop: Header=BB0_290 Depth=3
	add	x25, x25, #1
	ldr	w12, [sp, #260]                 ; 4-byte Folded Reload
	cbnz	w12, LBB0_289
; %bb.297:                              ;   in Loop: Header=BB0_290 Depth=3
	ldr	w12, [x10, #16]
	tbz	w12, #9, LBB0_289
; %bb.298:                              ;   in Loop: Header=BB0_290 Depth=3
	orr	x11, x11, #0x4
	ldr	x11, [x10, x11]
	add	x10, sp, #272
	b	LBB0_288
LBB0_299:                               ;   in Loop: Header=BB0_290 Depth=3
	add	x10, x10, x13
	add	x10, x10, w27, sxtw
	ldrb	w11, [x10]
	cmp	w11, #46
	b.ne	LBB0_287
; %bb.300:                              ;   in Loop: Header=BB0_290 Depth=3
	ldrb	w11, [x10, #1]
	cbz	w11, LBB0_289
; %bb.301:                              ;   in Loop: Header=BB0_290 Depth=3
	cmp	w11, #46
	b.ne	LBB0_287
; %bb.302:                              ;   in Loop: Header=BB0_290 Depth=3
	ldrb	w10, [x10, #2]
	cbnz	w10, LBB0_287
	b	LBB0_289
LBB0_303:                               ;   in Loop: Header=BB0_259 Depth=2
	mov	x28, x22
LBB0_304:                               ;   in Loop: Header=BB0_259 Depth=2
	stp	x8, x9, [sp, #272]
LBB0_305:                               ;   in Loop: Header=BB0_259 Depth=2
	ldr	x22, [sp, #184]                 ; 8-byte Folded Reload
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbnz	w8, #0, LBB0_258
LBB0_306:                               ;   in Loop: Header=BB0_259 Depth=2
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	ldr	x10, [sp, #232]                 ; 8-byte Folded Reload
	add	x10, x23, x10
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x8, x8, x10, x9
	str	x8, [sp, #232]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #208]                  ; 8-byte Folded Reload
	add	x8, x8, w28, uxtw
	str	x8, [sp, #208]                  ; 8-byte Folded Spill
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x23, x28, [x29, #-104]
	sub	x1, x29, #248
	ldp	x9, x8, [sp, #192]              ; 16-byte Folded Reload
	orr	x4, x8, x9
	ldr	w0, [sp, #248]                  ; 4-byte Folded Reload
	mov	x2, x26
	mov	x3, x22
	bl	_getattrlistbulk
	mov	x22, x0
	sub	x1, x29, #104
	mov	w0, #6                          ; =0x6
	bl	_clock_gettime
	ldp	x8, x9, [x29, #-104]
	sub	x8, x8, x23
	ldr	x10, [sp, #240]                 ; 8-byte Folded Reload
	sub	x10, x10, x28
	add	x9, x10, x9
	mov	w10, #51712                     ; =0xca00
	movk	w10, #15258, lsl #16
	madd	x8, x8, x10, x9
	str	x8, [sp, #240]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #216]                  ; 8-byte Folded Reload
	add	x8, x8, #1
	str	x8, [sp, #216]                  ; 8-byte Folded Spill
	cmp	w22, #0
	b.gt	LBB0_259
	b	LBB0_252
LBB0_307:                               ;   in Loop: Header=BB0_259 Depth=2
	mov	x28, x22
	ldr	x22, [sp, #184]                 ; 8-byte Folded Reload
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_306
	b	LBB0_258
LBB0_308:
	stur	x25, [x29, #-256]
	str	x21, [sp, #264]
	mov	x0, x26
	mov	x20, x9
	bl	_free
	mov	x0, x20
	bl	_free
	ldr	x0, [sp, #136]                  ; 8-byte Folded Reload
	bl	_fclose
	mov	x22, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	ldr	w27, [sp, #228]                 ; 4-byte Folded Reload
	ldp	x20, x21, [sp, #208]            ; 16-byte Folded Reload
	b	LBB0_328
LBB0_309:
	mov	x20, #0                         ; =0x0
	mov	x25, #0                         ; =0x0
	mov	x8, #0                          ; =0x0
	mov	w19, #1                         ; =0x1
	mov	w24, #9217                      ; =0x2401
	b	LBB0_312
LBB0_310:                               ;   in Loop: Header=BB0_312 Depth=1
	mov	x25, x8
LBB0_311:                               ;   in Loop: Header=BB0_312 Depth=1
	cmp	x25, x23
	b.hi	LBB0_325
LBB0_312:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_322 Depth 2
	ldrb	w9, [x22, x25]
	cmp	w9, #13
	lsl	w9, w19, w9
	and	w9, w9, w24
	ccmp	w9, #0, #4, ls
	b.eq	LBB0_318
; %bb.313:                              ;   in Loop: Header=BB0_312 Depth=1
	strb	wzr, [x22, x25]
	cmp	x25, x8
	b.ls	LBB0_321
; %bb.314:                              ;   in Loop: Header=BB0_312 Depth=1
	add	x0, x22, x8
	sub	x1, x29, #248
	bl	_stat
	cbnz	w0, LBB0_321
; %bb.315:                              ;   in Loop: Header=BB0_312 Depth=1
	ldurh	w8, [x29, #-244]
	and	w8, w8, #0xf000
	cmp	w8, #4, lsl #12                 ; =16384
	b.eq	LBB0_319
; %bb.316:                              ;   in Loop: Header=BB0_312 Depth=1
	cmp	w8, #8, lsl #12                 ; =32768
	b.ne	LBB0_321
; %bb.317:                              ;   in Loop: Header=BB0_312 Depth=1
	add	x20, x20, #1
	add	x8, sp, #272
	ldr	x10, [sp, #272]
	ldr	x9, [sp, #232]                  ; 8-byte Folded Reload
	b	LBB0_320
LBB0_318:                               ;   in Loop: Header=BB0_312 Depth=1
	add	x25, x25, #1
	b	LBB0_311
LBB0_319:                               ;   in Loop: Header=BB0_312 Depth=1
	add	x9, sp, #280
	mov	w10, #1                         ; =0x1
	add	x8, sp, #280
LBB0_320:                               ;   in Loop: Header=BB0_312 Depth=1
	ldr	x9, [x9]
	add	x9, x9, x10
	str	x9, [x8]
LBB0_321:                               ;   in Loop: Header=BB0_312 Depth=1
	add	x8, x25, #1
	cmp	x8, x23
	b.hs	LBB0_310
LBB0_322:                               ;   Parent Loop BB0_312 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w9, [x22, x8]
	cmp	w9, #13
	ccmp	w9, #10, #4, ne
	b.ne	LBB0_310
; %bb.323:                              ;   in Loop: Header=BB0_322 Depth=2
	add	x8, x8, #1
	cmp	x23, x8
	b.ne	LBB0_322
; %bb.324:                              ;   in Loop: Header=BB0_312 Depth=1
	mov	x8, x23
	mov	x25, x23
	b	LBB0_311
LBB0_325:
	mov	x24, #0                         ; =0x0
	mov	x19, #899                       ; =0x383
	movk	x19, #29597, lsl #16
	movk	x19, #4016, lsl #32
	movk	x19, #5221, lsl #48
	stur	x20, [x29, #-256]
LBB0_326:
	mov	x0, x22
	bl	_free
	mov	x0, x21
	bl	_fclose
LBB0_327:
	mov	x22, #0                         ; =0x0
	mov	x20, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	stp	xzr, xzr, [sp, #232]            ; 16-byte Folded Spill
LBB0_328:
	ldur	x8, [x29, #-256]
	ldp	x10, x9, [sp, #272]
	cbz	w27, LBB0_332
; %bb.329:
	ldr	x11, [sp, #264]
	stp	x24, x19, [sp, #32]
	stp	x10, x11, [sp, #16]
	stp	x8, x9, [sp]
Lloh48:
	adrp	x0, l_.str.10@PAGE
Lloh49:
	add	x0, x0, l_.str.10@PAGEOFF
	bl	_printf
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbnz	w8, #0, LBB0_331
LBB0_330:
	stp	x20, x22, [sp, #32]
	stp	x23, x21, [sp, #16]
	ldp	x9, x8, [sp, #232]              ; 16-byte Folded Reload
	stp	x8, x9, [sp]
Lloh50:
	adrp	x0, l_.str.12@PAGE
Lloh51:
	add	x0, x0, l_.str.12@PAGEOFF
	bl	_printf
LBB0_331:
	mov	w0, #0                          ; =0x0
	b	LBB0_24
LBB0_332:
	stp	x9, x10, [sp, #8]
	str	x8, [sp]
Lloh52:
	adrp	x0, l_.str.11@PAGE
Lloh53:
	add	x0, x0, l_.str.11@PAGEOFF
	bl	_printf
	ldr	w8, [sp, #256]                  ; 4-byte Folded Reload
	tbz	w8, #0, LBB0_330
	b	LBB0_331
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh4, Lloh5
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh12, Lloh13
	.loh AdrpAdd	Lloh14, Lloh15
	.loh AdrpAdd	Lloh16, Lloh17
	.loh AdrpAdd	Lloh18, Lloh19
	.loh AdrpAdd	Lloh20, Lloh21
	.loh AdrpAdd	Lloh22, Lloh23
	.loh AdrpAdd	Lloh24, Lloh25
	.loh AdrpAdd	Lloh26, Lloh27
	.loh AdrpAdd	Lloh28, Lloh29
	.loh AdrpAdd	Lloh30, Lloh31
	.loh AdrpAdd	Lloh34, Lloh35
	.loh AdrpLdr	Lloh32, Lloh33
	.loh AdrpAdd	Lloh36, Lloh37
	.loh AdrpAdd	Lloh38, Lloh39
	.loh AdrpAdd	Lloh42, Lloh43
	.loh AdrpLdr	Lloh40, Lloh41
	.loh AdrpAdd	Lloh44, Lloh45
	.loh AdrpAdd	Lloh46, Lloh47
	.loh AdrpAdd	Lloh48, Lloh49
	.loh AdrpAdd	Lloh50, Lloh51
	.loh AdrpAdd	Lloh52, Lloh53
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"FS_BENCH_LIST"

l_.str.1:                               ; @.str.1
	.asciz	"FS_BENCH_TREEWALK_LIST"

l_.str.2:                               ; @.str.2
	.asciz	"FS_BENCH_ROOT"

l_.str.4:                               ; @.str.4
	.asciz	"FS_BENCH_FOLLOW_SYMLINKS"

l_.str.5:                               ; @.str.5
	.asciz	"FS_BENCH_COUNT_ONLY"

l_.str.6:                               ; @.str.6
	.asciz	"FS_BENCH_INVENTORY"

l_.str.7:                               ; @.str.7
	.asciz	"FS_BENCH_PROFILE"

l_.str.8:                               ; @.str.8
	.asciz	"FS_BENCH_MAX_DEPTH"

l_.str.9:                               ; @.str.9
	.asciz	"FS_BENCH_TREEWALK_MODE"

l_.str.10:                              ; @.str.10
	.asciz	"files=%llu dirs=%llu bytes=%llu links=%llu name_bytes=%llu hash=%llu\n"

l_.str.11:                              ; @.str.11
	.asciz	"files=%llu dirs=%llu bytes=%llu\n"

l_.str.12:                              ; @.str.12
	.asciz	"profile bulk_ns=%llu parse_ns=%llu open_ns=%llu calls=%llu entries=%llu open=%llu\n"

l_.str.13:                              ; @.str.13
	.asciz	"r"

l_.str.14:                              ; @.str.14
	.asciz	"FS_BENCH_BULK_BUF"

l_.str.15:                              ; @.str.15
	.asciz	"FS_BENCH_BULK_PACK"

l_.str.16:                              ; @.str.16
	.asciz	"FS_BENCH_BULK_NOINMEM"

l_str:                                  ; @str
	.asciz	"usage: fswalk <path> (|| set FS_BENCH_ROOT/FS_BENCH_LIST)"

.subsections_via_symbols
