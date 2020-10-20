;;; Get current note being played
;;; X reg value corresponds to channel to be tested (0 or 1)
;;; Y and A are used
    MAC GET_CURRENT_NOTE
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

;;; Test if the instrument or percussion in `tmp` starts to play on any channel
;;; Note that instruments in `tmp` must have the frequency set to 0
;;; Z flag is set if `tmp` instrument/drum starts to play
;;; regs A, X, Y are used
    MAC IS_NEW_NOTE
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end

        ldx #1
.channels_loop:
        GET_CURRENT_NOTE
        cmp #TT_FIRST_PERC      ; Percussions and instruments have values >= TT_FIRST_PERC
        bcc .not_found

        ;; TODO: Update if more than one drum is used
        and #$e0                ; Cut frequency
        cmp tmp
        beq .end                ; Instr/Perc found
.not_found:
        dex
        bpl .channels_loop      ; try other channel
.end:
    ENDM

;;; Functions used in main
fx_init:        SUBROUTINE
        lda #$ff
        sta COLUPF
	rts

fx_vblank:      SUBROUTINE
        lda #$0                  ; Drum
        sta tmp
        IS_NEW_NOTE
        bne .end
        lda #0
        sta posy
.end:
        inc posy
	rts

fx_kernel:      SUBROUTINE
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

fx_overscan:    SUBROUTINE
	inc framecnt
	rts
