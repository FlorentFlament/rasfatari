MAX_TIME = 47 ; 240 lines, 5 lines per period -> 48 periods

;;; Get current note being played
;;; the channel must be passed as a macro argument (c0 or c1)
;;; Y is used
;;; Current note is returned in A
;;;
;;; - Bits 7..5: instrument
;;; - Bits 4..0: frequency
    MAC GET_CURRENT_NOTE
        ldy tt_cur_pat_index_{1}       ; get current pattern (index into tt_SequenceTable)
        lda tt_SequenceTable,y
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        ldy tt_cur_note_index_{1}
        lda (tt_ptr),y
    ENDM

;;; decreases stack_idx taking into account stack wrapping
    MAC DEC_STACK_IDX
        ldx stack_idx
        bne .no_wrap
        ldx #STACK_SIZE
.no_wrap:
        dex
        stx stack_idx
    ENDM

;;; Push note of provided channel into a circular notes stacks
;;; Channel must be provided as argument (c0 or c1)
;;; stack_idx must be loaded into X and will still be in X at exit
;;; Uses Y and A registers
    MAC PUSH_NEW_NOTE
        GET_CURRENT_NOTE {1}     ; INTO A
        sta #STACK_BASE_{1},X    ; Store new note on stack_idx (default)
        cmp #TT_FIRST_PERC ; Percussions and instruments have values >= TT_FIRST_PERC
        bcs .end
.non_note:
        ;; This is a non_note, we need to swap it with the previous note
        inx
        cpx #STACK_SIZE
        bne .no_wrap
        ldx #0
.no_wrap:
        ldy #STACK_BASE_{1},X
        sta #STACK_BASE_{1},X
        ldx stack_idx
        sty #STACK_BASE_{1},X
.end:
    ENDM

;;; Increments stack_idkern (possibly wrapping around stack)
;;; Uses X
;;; At exit stack_idkern and X contain updated stack_idkern
    MAC INC_STACK_IDKERN
        ldx stack_idkern
        inx
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        stx stack_idkern
    ENDM

;;; Store next note in cur_note
;;; channel must be provided as argument (c0 or c1)
;;; Uses A
;;; A get cur_note
    MAC FETCH_NEXT_NOTE
        lda #(STACK_BASE_{1}),X
        sta cur_note_{1}
    ENDM

;;; Horizontal position must be in cur_note
;;; Argument is the object to use (P0, P1, M0, M1, BL)
;;; current note frequency must be loaded into A
;;; i.e cur_note & 0x1f
    MAC POSITION_MOVABLE
        asl
        asl
        SLEEP 2
        sec
        ; Beware ! this loop must not cross a page !
        echo "[FX position note Loop]", ({1})d, "start :", *
.rough_loop:
        ; The rough_loop consumes 15 (5*3) pixels
        sbc #$0f              ; 2 cycles
        bcs .rough_loop ; 3 cycles
        echo "[FX position note Loop]", ({1})d, "end :", *
        sta RES{1}

        ; A register has value in [-15 .. -1]
        adc #$07 ; A in [-8 .. 6]
        eor #$ff ; A in [-7 .. 7]
    REPEAT 4
        asl
    REPEND
        sta HM{1} ; Fine position of missile or sprite
    ENDM

s_position_movable_P0:     SUBROUTINE
        POSITION_MOVABLE M0
        rts

s_position_movable_P1:     SUBROUTINE
        POSITION_MOVABLE M1
        rts

;;; Beware, this action has 2 WSYNCs
;;; Channel must be provided as argument (c0 or c1)
    MAC POSITION_NOTE
        lda #0
        sta COLU{2}
        lda cur_note_{1}
        and #$1f ; Extract note frequency
        cmp #20                 ; If the note is far on the right, we must skip the WSYNC
                                ; This threshold is not tuned yet (though seems to be good)
        bpl .no_wsync
        sta WSYNC
        jsr s_position_movable_{2}
        sta WSYNC
        jmp .end
.no_wsync:
        sta WSYNC
        jsr s_position_movable_{2}
.end:
        sta HMOVE
    ENDM

;;; Draw notes of both channels
;;; Uses A, X and Y
    MAC DRAW_NOTES
        lda cur_note_c0
        REPEAT 5
        lsr
        REPEND
        tax
        lda cur_note_c1
        REPEAT 5
        lsr
        REPEND
        tay
        lda colors_table,X
        ldx colors_table,Y
        sta WSYNC
        sta COLUP0
        stx COLUP1
        lda #2
        sta ENAM0
        sta ENAM1
.no_disp:
    ENDM

;;; Functions used in main
fx_init:        SUBROUTINE
        ;; Init stack
        lda #(STACK_SIZE - 1)
        sta stack_idx

        ;; Init Ball
        lda #$ff
        sta COLUP0
        sta COLUP1
        lda #$30
        sta NUSIZ0
        sta NUSIZ1
	rts

fx_vblank:      SUBROUTINE
        ldx stack_idx
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end
        PUSH_NEW_NOTE c0
        PUSH_NEW_NOTE c1
        DEC_STACK_IDX
.end:
        stx stack_idkern ; Used to iterate on the stack each frame
        INC_STACK_IDKERN
        FETCH_NEXT_NOTE c0
        FETCH_NEXT_NOTE c1
        POSITION_NOTE c0, P0
        POSITION_NOTE c1, P1
	rts


fx_kernel:      SUBROUTINE
        sec
        lda #4
        sbc tt_timer
        tay
.pre_loop:
        sta WSYNC
        dey
        bpl .pre_loop

        DRAW_NOTES
        lda #MAX_TIME
        sta tmp
.loop:  ; 5 lines per loop
        INC_STACK_IDKERN
        FETCH_NEXT_NOTE c0 ; into cur_note as well as A reg
        FETCH_NEXT_NOTE c1 ; into cur_note as well as A reg
        cmp #TT_FIRST_PERC ; Percussions and instruments have values >= TT_FIRST_PERC
        bcs .new_note
        REPEAT 5
        sta WSYNC
        REPEND
        jmp .continue
.new_note:
        POSITION_NOTE c0, P0
        POSITION_NOTE c1, P1
        DRAW_NOTES c0
        DRAW_NOTES c1
.continue:
        dec tmp
        bmi .end
        jmp .loop
.end:
        lda #0
        sta ENAM0
        sta ENAM1
        rts

fx_overscan:    SUBROUTINE
	rts

;;; 8 possible colors
;;; Drum (0): White - 0e
;;; LeadBeep (1): Light Green - 3c
;;; leadBeep (2): Dark Green - 38
;;; SoftBeep (3): Light Yellow - 2c
;;; SoftBeep (4): Orange - 4a
;;; Bass (5): Purple - c8
;;; Chords (6): Red - 6a
colors_table:
        dc.b $0e, $3c, $38, $2c, $4a, $c8, $6a, $0e
