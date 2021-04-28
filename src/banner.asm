; Position the sprites
; 12*8 = 96 pixels for the text
; i.ie 32 pixels on each side (160 - 96)/2
; +68 HBLANK = 100 pixels for RESP0
; Must be aligned !
FX_BANNER_POS_ALIGN equ *
	ALIGN 8
	;; echo "[FX banner pos] Align loss:", (* - FX_BANNER_POS_ALIGN)d, "bytes"
fx_banner_position:	SUBROUTINE
	;; GRP0 wanted position is 56 = (160-(6*8)) / 2
	;; GRP1 wanted position is 64 = grp0 + 8
FX_BANNER_POS equ *
	sta WSYNC
	ldx #7			; 7 -> 54 pixels
.posit:
	dex		; 2
	bne .posit	; 2** (3 if branching)
	;; echo "[FX banner pos] Loop:", (* - FX_BANNER_POS)d, "bytes"
	sta RESP0		; 54 pixels
	sta RESP1		; 63 pixels
	lda #$e0		; -> 56 pixels
	sta HMP0
	lda #$f0		; -> 64 pixels
	sta HMP1
	sta WSYNC
	sta HMOVE

	; Don't touch HMPx for 24 cycles
	ldx #4
.dont_hmp:
	dex
	bpl .dont_hmp
	rts

;;; Select banner
	MAC select_banner
	;; {1} is the base banner address (i.e: banner_0)
	lda #<{1}
	sta ptr
	lda #>{1}
	sta ptr+1
	ENDM

;;; Banner pointers setup
	MAC prepare_banner_pointers
	;; banner's base pointer needs to be passed in ptr
	;; ptr will be overwritten
	ldx #0
.loop:
	lda ptr
	sta header_buf,X
	lda ptr+1
	sta header_buf+1,X
	lda #16
	clc
	adc ptr
	sta ptr
	lda #0
	adc ptr+1
	sta ptr+1
	inx
	inx
	cpx #12
	bne .loop
	ENDM

banner_vblank:	SUBROUTINE
	;; Prepare banner pointers
	lda patcnt
	and #$04
	beq .title
.worm:
	lda framecnt
	REPEAT 4
	lsr
	REPEND
	and #$07		; 8 images
	tax
	lda smoke_tbl_l,X
	sta ptr
	lda smoke_tbl_h,X
	sta ptr+1
	bne .choice_done	; unconditional - smoking worm data high byte is not at address 0
.title:
	lda #<banner
	sta ptr
	lda #>banner
	sta ptr+1
.choice_done:
	prepare_banner_pointers

	;; Set banner color
	;; Banner smooth appearance and disappearance
	lda patcnt
	and #$01
	bne .greater_than_14
	lda framecnt
	cmp #14
	bcc .continue
.greater_than_14:
	lda patcnt
	and #$01
	beq .less_than_306
	lda framecnt
	cmp #146
	bcc .less_than_306
	lda #160
	sec
	sbc framecnt
	bne .continue		; unconditional - framecnt is <160
.less_than_306:
	lda #$0e
.continue:
	;; color should be grey
	;; lda LIGHT_GREY
	sta COLUP0
	sta COLUP1

	;; and position the banner
	jsr fx_banner_position
	rts

banner_kernel:	SUBROUTINE
	;; Shouldn't be reflection
	;; lda #$00
	;; sta REFP0
	;; sta REFP1
	;; 3 copies close & small (Number & Size)
	lda #$03
	sta NUSIZ0
	sta NUSIZ1
	;; vertical delay - tricks for 48 pixels sprites
	;; https://www.youtube.com/watch?v=J0LMSzv90W0
	lda #$01
	sta VDELP0
	sta VDELP1

	lda #15		; 16 lines
	sta ptr		; Using ptr as temp variable
.kernel_loop:
	ldy ptr
	lda (header_buf),Y
	sta GRP0
	sta WSYNC
	lda (header_buf+2),Y
	sta GRP1
	lda (header_buf+4),Y
	sta GRP0
	lda (header_buf+6),Y
	tax
	lda (header_buf+10),Y
	sta tmp	; Using as temp variable
	lda (header_buf+8),Y
	tay
	lda tmp
	stx GRP1		; banner_3
	sty GRP0		; banner_4
	sta GRP1		; banner_5
	sty GRP0
	dec ptr
	bpl .kernel_loop

	lda #$00
	;; Disable vertical delays
	sta VDELP0
	sta VDELP1
	;; Clear graphics
	sta GRP0
	sta GRP1
	;; Clear positionning
	sta HMP0
	sta HMP1

	sta WSYNC		; sync with worm header
	rts
