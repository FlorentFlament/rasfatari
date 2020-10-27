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

;;; Push a note into our circular notes stack
;;; the channel must be passed as a macro argument (c0 or c1)
;;; Uses Y and A registers
    MAC PUSH_NEW_NOTE
        GET_CURRENT_NOTE {1}    ; INTO A
        ldy stack_idx
        sta #STACK_BASE,Y ; doesn't touch flags
        bne .no_wrap
        ldy #STACK_SIZE
.no_wrap:
        dey
        sty stack_idx
    ENDM

;;; Swap non-notes (silences) with notes for better display
;;; Uses A, X, Y, tmp
    MAC REORDER_NOTES
        cmp #TT_FIRST_PERC ; Percussions and instruments have values >= TT_FIRST_PERC
        bcs .new_note
        ;; Current note is a "non-note" and must be swapper with the next note
        ldx stack_idx
        inx
        cpx #STACK_SIZE
        bne .no_wrap_x
        ldx #0
.no_wrap_x:
        txa
        tay
        iny
        cpy #STACK_SIZE
        bne .no_wrap_y
        ldy #0
.no_wrap_y:
        ;; Perform swapping
        lda #STACK_BASE,Y
        sta tmp
        lda #STACK_BASE,X
        sta #STACK_BASE,Y
        lda tmp
        sta #STACK_BASE,X
.new_note:
    ENDM

;;; tmp contains the stack index to use and is updated
;;; Store next note in cur_note (and cur_note+1)
;;; Uses X and A
    MAC FETCH_NEXT_NOTE
        ldx tmp
        inx
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        stx tmp
        lda #(STACK_BASE),X
        sta cur_note
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

s_position_movable:     SUBROUTINE
        POSITION_MOVABLE BL
        rts

;;; Beware, this action has 2 WSYNCs
    MAC POSITION_NOTE
        lda #0
        sta COLUPF
        lda cur_note
        and #$1f ; Extract note frequency
        cmp #20                 ; If the note is far on the right, we must skip the WSYNC
                                ; This threshold is not tuned yet (though seems to be good)
        bpl .no_wsync
        sta WSYNC
        jsr s_position_movable
        sta WSYNC
        jmp .end
.no_wsync:
        sta WSYNC
        jsr s_position_movable
.end:
        sta HMOVE
    ENDM

;;; Uses A and X
    MAC DRAW_NOTES
        lda cur_note
        REPEAT 5
        lsr
        REPEND
        tax
        lda colors_table,X ; Maybe we will need this lookup into fetch_next_note
        sta WSYNC
        sta COLUPF
        lda #2
        sta ENABL
.no_disp:
    ENDM

;;; Functions used in main
fx_init:        SUBROUTINE
        ;; Init stack
        lda #(STACK_SIZE - 1)
        sta stack_idx

        ;; Init Ball
        lda #$ff
        sta COLUPF              ; color
        lda #$30
        sta CTRLPF
	rts

fx_vblank:      SUBROUTINE
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end
        PUSH_NEW_NOTE c0
        ;; PUSH_NEW_NOTE c1
        REORDER_NOTES
.end:
        lda stack_idx
        sta tmp ; Used to iterate on the stack
        FETCH_NEXT_NOTE
        POSITION_NOTE
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
        ldy #MAX_TIME
.loop:  ; 5 lines per loop
        FETCH_NEXT_NOTE ; into cur_note as well as A reg
        cmp #TT_FIRST_PERC ; Percussions and instruments have values >= TT_FIRST_PERC
        REPEAT 2
        sta WSYNC
        REPEND
        bcs .new_note
        REPEAT 3
        sta WSYNC
        REPEND
        jmp .continue
.new_note:
        POSITION_NOTE
        DRAW_NOTES
.continue:
        dey
        bmi .end
        jmp .loop
.end:
        lda #0
        sta ENABL
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
