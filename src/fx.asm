fx_init:
        lda #$ff
        sta COLUPF
	rts

fx_fetch_current_note:
        TT_FETCH_CURRENT_NOTE
        rts

fx_vblank:
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end_vblank
        ldx #1
        jsr fx_fetch_current_note
        cmp #$08                ; Silence
        beq .end_vblank
        and #$e0                ; Cut frequency
        cmp #$0                 ; Percussion
        ;cmp #$60                ; instrument
        bne .end_vblank
.note_found:
        lda #$ff
        sta posy
.end_vblank:
        inc posy
	rts

fx_kernel:
        ldy #0
.next_line:
        cpy posy
        bne .no_disp
        lda #2
        sta ENABL
        jmp .continue
.no_disp:
        lda #0
        sta ENABL
.continue:
	sta WSYNC
        iny
        cpy #240
        bne .next_line

        lda #0
        sta ENABL
        rts

fx_overscan:
	inc framecnt
	rts
