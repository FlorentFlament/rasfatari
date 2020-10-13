    MAC GET_NOTE
        ldy tt_cur_pat_index_c0,x       ; get current pattern (index into tt_SequenceTable)
        lda tt_SequenceTable,y
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        ldy tt_cur_note_index_c0,x
        lda (tt_ptr),y
    ENDM

fx_init:
        lda #$ff
        sta COLUPF
	rts

fx_vblank:
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end_vblank

        ;; Search rewind ball if starting a drum
        ldx #1
        GET_NOTE
        cmp #$08                ; Silence
        beq .end_vblank
        and #$e0                ; Cut frequency
        cmp #$0                 ; Percussion
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
