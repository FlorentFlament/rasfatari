;;; Does rough positioning of note
;;; Argument: Channel for the note (0 or 1)
;;; A : must contain Horizontal position
    MAC ROUGH_POSITION_WORM
	sec
	; Beware ! this loop must not cross a page !
	;; echo "[FX position worm Loop] P", ({1})d, "start :", *
.rough_loop:
	; The rough_loop consumes 15 (5*3) pixels
	sbc #$0f	      ; 2 cycles
	bcs .rough_loop ; 3 cycles
	;; echo "[FX position worm Loop] P", ({1})d, "end :", *
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
	lda #$ff
	sta worm_pos
	lda #$02
	sta worm_state
	rts

    MAC POSITION_WORM
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
    ENDM

worm_vblank:	SUBROUTINE
	lda framecnt
	bne .finalize
	;; State is in worm_state 3 upper bits
	lda worm_state
	clc
	adc #$20
	sta worm_state

	;; Will we launch the worm ?
	and #$60
	bne .finalize
.lauching_worm:
	inc worm_state
	lda worm_state
	and #$03
	cmp #3
	bcc .color_ok
	lda worm_state
	and #$fc
	sta worm_state
.color_ok:
	lda worm_state
	and #$80
	bne .right_left_init
.left_right_init:
	lda #$00
	beq .direction_chosen	; inconditional
.right_left_init:
	lda #(160-16)
.direction_chosen:
	sta worm_pos

.finalize:
	lda framecnt
	lsr
	lsr
	and #$03
	tay
	lda worm_sprite0_ptrl,Y
	sta worm_ptr
	lda worm_sprite0_ptrh,Y
	sta worm_ptr+1

	lda worm_pos
	cmp #(160-15)
	bcs .end

	POSITION_WORM
	lda framecnt
	and #$01
	beq .end
	lda worm_state
	and #$80
	bne .right_left_move
.left_right_move:
	inc worm_pos
	jmp .end
.right_left_move:
	dec worm_pos

.end:
	lda worm_state
	and #$80
	bne .no_reflection	; Reflection unset by text_fx anyway ..
	lda #$08
	sta REFP0
	sta REFP1
.no_reflection:
	rts

worm_kernel:	SUBROUTINE
	lda worm_pos
	cmp #(160-15)
	bcs .transparent_worm
	lda worm_state
	and #$03
	tax
	lda worm_colors,X
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
	lda worm_state
	and #$80
	beq .left_right_display
.right_left_display:
	lda (ptr),Y
	sta GRP0
	lda (worm_ptr),Y
	sta GRP1
	jmp .end_display
.left_right_display:
	lda (ptr),Y
	sta GRP1
	lda (worm_ptr),Y
	sta GRP0
.end_display:
	sta WSYNC
	sta WSYNC
	dey
	bpl .loop

	lda #$0
	sta GRP0
	sta GRP1
	rts
