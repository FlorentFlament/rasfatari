;;; Does rough positioning of note
;;; Argument: Channel for the note (0 or 1)
;;; A : must contain Horizontal position
    MAC ROUGH_POSITION_WORM
	sec
	; Beware ! this loop must not cross a page !
	echo "[FX position note Loop] M", ({1})d, "start :", *
.rough_loop:
	; The rough_loop consumes 15 (5*3) pixels
	sbc #$0f	      ; 2 cycles
	bcs .rough_loop ; 3 cycles
	echo "[FX position note Loop] M", ({1})d, "end :", *
	sta RESP{1}
    ENDM

;;; Fine position note passed as argument
;;; Argument: Channel for the note (0 or 1)
;;; A: must contain the remaining value of rough positioning
;;; At the end:
;;; A: is destroyed
    MAC FINE_POSITION_WORM
	;; A register has value in [-15 .. -1]
	clc
	adc #$07 ; A in [-8 .. 6]
	eor #$ff ; A in [-7 .. 7]
    REPEAT 4
	asl
    REPEND
	sta HMP{1} ; Fine position of missile or sprite
    ENDM

worm_init:
	lda #0
	sta worm_pos

worm_vblank:	SUBROUTINE
	lda worm_pos
	sta WSYNC
	SLEEP 14
	ROUGH_POSITION_WORM 0
	FINE_POSITION_WORM 0

	lda worm_pos
	clc
	adc #8
	sta WSYNC
	SLEEP 14
	ROUGH_POSITION_WORM 1
	FINE_POSITION_WORM 1

	sta WSYNC
	sta HMOVE		; Commit notes fine tuning

	lda framecnt
	and #$01
	bne .end
	dec worm_pos

.end:
	lda framecnt
	lsr
	lsr
	and #$03
	tay
	lda worm_sprite0_ptrl,Y
	sta worm_ptr
	lda worm_sprite0_ptrh,Y
	sta worm_ptr+1
	rts

worm_kernel:	SUBROUTINE
	lda worm_pos
	cmp #(160-16)
	bcs .transparent_worm
	lda #WORM_COL
	bne .color_chosen	; inconditional
.transparent_worm:
	lda #0

.color_chosen:
	sta COLUP0
	sta COLUP1

	lda worm_ptr
	clc
	adc #8
	sta ptr
	lda worm_ptr+1
	adc #0
	sta ptr+1

	sta WSYNC
	ldy #7
.loop:
	lda (ptr),Y
	sta GRP0
	lda (worm_ptr),Y
	sta GRP1
	sta WSYNC
	sta WSYNC
	dey
	bpl .loop

	lda #$0
	sta GRP0
	sta GRP1
	rts

worm_sprite0_ptrl:
	dc.b <worm_sprite0_a, <worm_sprite0_b, <worm_sprite0_c, <worm_sprite0_d
worm_sprite0_ptrh:
	dc.b >worm_sprite0_a, >worm_sprite0_b, >worm_sprite0_c, >worm_sprite0_d

worm_sprite0_a:
	dc.b $9f, $fc, $e0, $00, $00, $00, $00, $00
worm_sprite1_a:
	dc.b $07, $0f, $1c, $38, $58, $78, $30, $00
worm_sprite0_b:
	dc.b $8e, $dc, $f8, $70, $00, $00, $00, $00
worm_sprite1_b:
	dc.b $03, $07, $0e, $0e, $16, $1e, $0c, $00
worm_sprite0_c:
	dc.b $10, $30, $60, $60, $c0, $c0, $80, $00
worm_sprite1_c:
	dc.b $04, $0e, $0f, $1f, $2d, $3d, $18, $00
worm_sprite0_d:
	dc.b $70, $f8, $cc, $80, $00, $00, $00, $00
worm_sprite1_d:
	dc.b $0c, $1e, $3f, $3b, $58, $78, $30, $00
