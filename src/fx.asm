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
        ;; TODO: "Scale" frequency
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

;;; Test if the instrument or percussion in `tmp` starts to play on any channel
;;; Note that instruments in `tmp` must have the frequency set to 0
;;; Z flag is set if `tmp` instrument/drum starts to play
;;; regs A, X, Y are used
    MAC PUSH_NEW_NOTES
        lda tt_timer
        cmp #TT_SPEED-1
        bne .end
        PUSH_NEW_NOTE c0
        PUSH_NEW_NOTE c1
.end:
    ENDM

;;; Updates X reg and tmp var
;;; Store it in cur_note
    MAC FETCH_NEXT_STACK_NOTE
    REPEAT NOTE_SIZE
        inx
    REPEND
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        lda #(STACK_BASE),X
        sta cur_note
        lda #(STACK_BASE+1),X
        sta cur_note+1
    ENDM

;;; Horizontal position must be in cur_note
;;; Argument is the object to use (P0, P1, M0, M1, BL)
    MAC POSITION_NOTE
        lda cur_note
        and #$1f
        asl
        sec
        ; Beware ! this loop must not cross a page !
        echo "[FX position dot Loop]", ({1})d, "start :", *
.rough_loop:
        ; The pos_star loop consumes 15 (5*3) pixels
        sbc #$0f              ; 2 cycles
        bcs .rough_loop ; 3 cycles
        echo "[FX position dot Loop]", ({1})d, "end :", *
        sta RES{1}

        ; A register has value is in [-15 .. -1]
        adc #$07 ; A in [-8 .. 6]
        eor #$ff ; A in [-7 .. 7]
    REPEAT 4
        asl
    REPEND
        sta HM{1} ; Fine position of missile or sprite
    ENDM

    MAC SET_COLOR
        lda cur_note
        and #$e0
        ora #$0a
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
        lda #$40
        sta tmp
        PUSH_NEW_NOTES
        UPDATE_NOTES
	rts


fx_kernel:      SUBROUTINE
        ldx stack_idx
        ldy #240
.loop:
        lda state
        cmp #1
        sta WSYNC
        beq .position_note      ; state == 1
        bcc .fetch_note         ; state == 0
        ;; wait and draw        ; state == 2
        cpy cur_note+1
        bcs .no_disp           ; cur_line >= cur_note(line)
        ;; cur_line < cur_note(line)
        ;; Displaying line
        STA HMOVE
        lda #2
        sta ENABL
        lda #0
        sta state
        jmp .next_line
.position_note:
        lda #0
        sta ENABL
        POSITION_NOTE BL
        inc state
        jmp .next_line
.fetch_note:
        lda #0
        sta ENABL
        FETCH_NEXT_STACK_NOTE
        SET_COLOR
        inc state
        jmp .next_line
.no_disp:
        lda #0
        sta ENABL
.next_line:
        dey
        bne .loop

        lda #0
        sta ENABL
        sta state
        rts

fx_overscan:    SUBROUTINE
	inc framecnt
	rts
