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

;;; Push a note into our circular notes stack
;;; Uses X and A registers
    MAC PUSH_NOTE
        ldx stack_idx
        lda #$01
        sta #STACK_BASE,X
        lda #240
        sta #(STACK_BASE+1),X

        lda stack_idx
        bne .no_wrap
        lda #STACK_SIZE
.no_wrap:
        sec
        sbc #NOTE_SIZE
        sta stack_idx
    ENDM

    MAC UPDATE_NOTES
        ldx #(STACK_SIZE - NOTE_SIZE)
.loop:
        lda #(STACK_BASE+1),X
        beq .next_note
        dec #(STACK_BASE+1),X
.next_note:
    REPEAT NOTE_SIZE
        dex
    REPEND
        bpl .loop
    ENDM


;;; Functions used in main
fx_init:        SUBROUTINE
        ;; Init stack
        lda #(STACK_SIZE - NOTE_SIZE)
        sta stack_idx

        ;; Init Ball
        lda #$ff
        sta COLUPF              ; color
        lda #$30
        sta CTRLPF
	rts

fx_vblank:      SUBROUTINE
        lda #$40                  ; Drum
        sta tmp
        IS_NEW_NOTE
        bne .end
        PUSH_NOTE
.end:
        UPDATE_NOTES
	rts

;;; Updates X reg and tmp var
    MAC FETCH_NEXT_STACK_NOTE
    REPEAT NOTE_SIZE
        inx
    REPEND
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        lda #(STACK_BASE+1),X
        sta tmp
    ENDM


fx_kernel:      SUBROUTINE
        ldx stack_idx
        FETCH_NEXT_STACK_NOTE

        ldy #240
.loop:
        cpy tmp
        bne .no_disp

        lda #2
        sta ENABL
        FETCH_NEXT_STACK_NOTE
        beq .next_line          ; unconditional
.no_disp:
        lda #0
        sta ENABL
.next_line:
	sta WSYNC
        dey
        bne .loop

        lda #0
        sta ENABL
        rts

fx_overscan:    SUBROUTINE
	inc framecnt
	rts
