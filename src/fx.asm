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
;;; Uses X and A registers
    MAC PUSH_NEW_NOTE
        GET_CURRENT_NOTE {1}    ; INTO A
        cmp #TT_FIRST_PERC      ; Percussions and instruments have values >= TT_FIRST_PERC
        bcc .end
        sec
        sbc 4
        ldx stack_idx
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
.end:
    ENDM

    MAC UPDATE_NOTES
        ldx #(STACK_SIZE - NOTE_SIZE)
.loop:
        lda #(STACK_BASE+1),X
        beq .next_note
        ;; TODO: Make speed parametrizable
    REPEAT 1 ; speed
        dec #(STACK_BASE+1),X
    REPEND
.next_note:
    REPEAT NOTE_SIZE
        dex
    REPEND
        bpl .loop
    ENDM

;;; regs A, X, Y are used
    MAC PUSH_NEW_NOTES
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end
        PUSH_NEW_NOTE c0
        PUSH_NEW_NOTE c1
.end:
    ENDM

;;; Updates tmp reg
;;; Store next note in cur_note (and cur_note+1)
;;; A value is cur_note; Can be used by SET_COLOR
    MAC FETCH_NEXT_STACK_NOTE
        ldx tmp
    REPEAT NOTE_SIZE
        inx
    REPEND
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        stx tmp
        lda #(STACK_BASE+1),X
        sta cur_note+1
        lda #(STACK_BASE),X
        sta cur_note
    ENDM

;;; Horizontal position must be in cur_note
;;; Argument is the object to use (P0, P1, M0, M1, BL)
;;; current note frequency must be loaded into A
;;; i.e cur_note & 0x1f
    MAC POSITION_NOTE
        asl
        asl
        SLEEP 5
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

;;; A register must containt cur_note
    MAC SET_COLOR
        lda cur_note
        REPEAT 5
        lsr
        REPEND
        tax
        lda colors_table,X
        sta COLUPF
    ENDM

;;; Functions used in main
fx_init:        SUBROUTINE
        ;; Init stack
        lda #(STACK_SIZE - NOTE_SIZE)
        sta stack_idx
        ;; Init state
        lda #0
        sta state

        ;; Init Ball
        lda #$ff
        sta COLUPF              ; color
        lda #$30
        sta CTRLPF
	rts

fx_vblank:      SUBROUTINE
        PUSH_NEW_NOTES
        UPDATE_NOTES
	rts


;;; State machine actions

    MAC S0_FETCH_NOTE
        FETCH_NEXT_STACK_NOTE
        lda #0
        sta ENABL
        SET_COLOR
        inc state
    ENDM

    ;; Beware, this action has 2 WSYNCs
    MAC S1_POSITION_NOTE
        sta WSYNC
        lda cur_note
        and #$1f                ; Extract frequency / position
        cmp #20                 ; If the note is far on the right, we must skip the WSYNC
                                ; This threshold is not tuned yet (though seems to be good)
        bpl .no_wsync
        POSITION_NOTE BL
        sta WSYNC
        jmp .end
.no_wsync:
        POSITION_NOTE BL
.end:
        sta HMOVE
        inc state
    ENDM

;;; Y must contains current line count
    MAC S1_NOSYNC_WAIT_OR_DRAW
        cpy cur_note + 1
        bcs .no_disp           ; cur_line >= cur_note(line)
        ;; cur_line < cur_note(line)
        ;; Displaying line
        lda #2
        sta ENABL
        lda #0
        sta state
.no_disp:
    ENDM

    MAC S2_WAIT_OR_DRAW
        sta WSYNC
        S1_NOSYNC_WAIT_OR_DRAW
    ENDM


fx_kernel:      SUBROUTINE
        ldx stack_idx
        stx tmp ; Used to iterate on the stack
        ldy #240
.loop:
        lda state
        cmp #1
        beq .position_note      ; state == 1
        bcc .fetch_note         ; state == 0
        ;; state == 2
        S2_WAIT_OR_DRAW
        jmp .next_line
.fetch_note:
        S0_FETCH_NOTE
        jmp .next_line
.position_note:
        S1_POSITION_NOTE
        dey
        beq .end
        S1_NOSYNC_WAIT_OR_DRAW
.next_line:
        dey
        beq .end
        jmp .loop

.end:
        lda #0
        sta ENABL
        sta state
        rts

fx_overscan:    SUBROUTINE
	inc framecnt
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
