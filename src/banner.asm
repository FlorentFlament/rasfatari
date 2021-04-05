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

banner_vblank:	SUBROUTINE
	;; Set banner color
	lda framecnt
	cmp #7
	bcs .greater_than_7
	asl
	ora #$f0
	jmp .continue
.greater_than_7:
	cmp #153
	bcs .greater_than_153
	lda #$ff
	jmp .continue
.greater_than_153:
	lda #160
	sec
	sbc framecnt
	asl
	ora #$f0
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

	lda #13		; 14 lines
	sta ptr		; Using ptr as temp variable
.kernel_loop:
	ldx ptr
	sta WSYNC
	lda banner_0,X
	sta GRP0
	lda banner_1,X
	sta GRP1
	lda banner_2,X
	sta GRP0
	ldy banner_3,X
	lda banner_5,X
	sta tmp	; Using as temp variable
	lda banner_4,X
	tax
	lda tmp
	sty GRP1		; banner_3
	stx GRP0		; banner_4
	sta GRP1		; banner_5
	stx GRP0
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
	sta WSYNC		; sync with worm header
	sta WSYNC		; sync with worm header
	rts
