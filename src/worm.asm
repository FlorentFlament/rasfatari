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
	lda #WORM_COL
	sta COLUP0
	sta COLUP1

	lda worm_pos
	and #$7f
	sta WSYNC
	SLEEP 17
	ROUGH_POSITION_WORM 0
	FINE_POSITION_WORM 0

	lda worm_pos
	and #$7f
	clc
	adc #8
	sta WSYNC
	SLEEP 17
	ROUGH_POSITION_WORM 1
	FINE_POSITION_WORM 1

	sta WSYNC
	sta HMOVE		; Commit notes fine tuning

	lda framecnt
	and #$01
	bne .end
	dec worm_pos
.end:
	rts

worm_kernel:	SUBROUTINE

	ldy #7
.loop:
	lda worm_sprite0,Y
	sta GRP0
	lda worm_sprite1,Y
	sta GRP1
	sta WSYNC
	sta WSYNC
	dey
	bpl .loop

	lda #$0
	sta GRP0
	sta GRP1
	rts

worm_sprite1:
	dc.b $9f, $fc, $e0, $00, $00, $00, $00, $00
worm_sprite0:
	dc.b $07, $0f, $1c, $38, $58, $78, $30, $00
