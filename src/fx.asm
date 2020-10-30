MAX_TIME = 47 ; 240 lines, 5 lines per period -> 48 periods

;;; Swap instrument (bits 7-5) and frequency (bits 4-0)
;;; Note must be in A and the result will be in A
    MAC SWAP_NOTE
        REPEAT 3
        cmp #$80
        rol
        REPEND
    ENDM

;;; Argument is channel (0 or 1)
    MAC GET_NOTE_FREQUENCY
        lda cur_note_c{1}
        lsr
        lsr
        and #$7c ; Extract note frequency
    ENDM

;;; Argument is channel (0 or 1)
    MAC GET_NOTE_COLOR
        lda cur_note_c{1}
        and #$07                ; Filter out note
	tax
        lda colors_table,X
    ENDM

;;; Get current note being played
;;; the channel must be passed as a macro argument (c0 or c1)
;;; Y is used
;;; Current note is returned in A
;;;
;;; - Bits 7..5: instrument
;;; - Bits 4..0: frequency
    MAC GET_CURRENT_NOTE
.constructPatPtr:
        ldy tt_cur_pat_index_{1}       ; get current pattern (index into tt_SequenceTable)
        lda tt_SequenceTable,y
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        ldy tt_cur_note_index_{1}
        lda (tt_ptr),y
        bne .noEndOfPattern
        ; End of pattern: Advance to next pattern
        sta tt_cur_note_index_{1}      ; a is 0
        inc tt_cur_pat_index_{1}
        bne .constructPatPtr            ; unconditional
.noEndOfPattern:
    ENDM

;;; stack_idx must be loaded into X and will still be in X at exit
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
;;; Uses X, Y and A registers
    MAC PUSH_NEW_NOTE
        GET_CURRENT_NOTE {1}
        SWAP_NOTE
        ldx stack_idx
        sta #STACK_BASE_{1},X    ; Store new note on stack_idx (default)
        cmp #$40                 ; #$40 is a non-note
        bne .end
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

;;; Increments stack_ikern (possibly wrapping around stack)
;;; Uses X
;;; At exit stack_ikern and X contain updated stack_ikern
    MAC INC_STACK_IKERN
        ldx stack_ikern
        inx
        cpx #STACK_SIZE
        bne .nowrap
        ldx #0
.nowrap:
        stx stack_ikern
    ENDM

;;; Store next note in cur_note
;;; channel must be provided as argument (c0 or c1)
;;; Uses A, X
;;; A get cur_note
    MAC FETCH_NEXT_NOTE
        ldx stack_ikern
        lda #(STACK_BASE_{1}),X
        sta cur_note_{1}
    ENDM

;;; Does rough positioning of note
;;; Argument: Channel for the note (0 or 1)
;;; A : must contain Horizontal position
    MAC ROUGH_POSITION_LOOP
        sec
        ; Beware ! this loop must not cross a page !
        echo "[FX position note Loop] M", ({1})d, "start :", *
.rough_loop:
        ; The rough_loop consumes 15 (5*3) pixels
        sbc #$0f              ; 2 cycles
        bcs .rough_loop ; 3 cycles
        echo "[FX position note Loop] M", ({1})d, "end :", *
        sta RESM{1}
    ENDM

;;; Fine position note passed as argument
;;; Argument: Channel for the note (0 or 1)
;;; A: must contain the remaining value of rough positioning
;;; At the end:
;;; A: is destroyed
    MAC FINE_POSITION_NOTE
        ;; A register has value in [-15 .. -1]
        clc
        adc #$07 ; A in [-8 .. 6]
        eor #$ff ; A in [-7 .. 7]
    REPEAT 4
        asl
    REPEND
        sta HMM{1} ; Fine position of missile or sprite
    ENDM

;;; Display a full band of 5 pixels of notes
;;; Uses A, X and Y
    MAC DISPLAY_BAND
        INC_STACK_IKERN

        FETCH_NEXT_NOTE c0      ; cur_note_c0 is in A
        cmp #$40                ; #$40 is a non-note
        bne .new_c0_note
        sta WSYNC
        sta WSYNC
        jmp .skip_c0_note

.new_c0_note:
        sta WSYNC
        lda #0                  ; turn off note chan0
        sta ENAM0
        sleep 5
        GET_NOTE_FREQUENCY 0
        ROUGH_POSITION_LOOP 0
        FINE_POSITION_NOTE 0
        lda #0
        sta HMM1                ; Don't move missile 1
        GET_NOTE_COLOR 0

        sta WSYNC
        sta HMOVE               ; Commit notes fine tuning
        sta COLUP0
        lda #2
        sta ENAM0
.skip_c0_note:
        FETCH_NEXT_NOTE c1      ; cur_note_c1 is in A
        cmp #$40                ; #$40 is a non-note
        bne .new_c1_note
        sta WSYNC
        sta WSYNC
        sta WSYNC
        jmp .skip_c1_note

.new_c1_note:
        sta WSYNC
        lda #0
        sta ENAM1
        sleep 20
        GET_NOTE_FREQUENCY 1
        ROUGH_POSITION_LOOP 1

        sta WSYNC
        FINE_POSITION_NOTE 1
        lda #0
        sta HMM0                ; Don't move missile 0
        GET_NOTE_COLOR 1

        sta WSYNC
        sta HMOVE               ; Commit notes fine tuning
        sta COLUP1
        lda #2
        sta ENAM1
.skip_c1_note:
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
        lda tt_timer
        cmp #TT_SPEED-1
        beq .new_notes
        jmp .end
.new_notes:
        PUSH_NEW_NOTE c0
        PUSH_NEW_NOTE c1
        DEC_STACK_IDX
.end:
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

        lda stack_idx
        sta stack_ikern ; Used to iterate on the stack each frame
        lda #MAX_TIME
        sta tmp
.loop:  ; 5 lines per loop
        DISPLAY_BAND
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
        dc.b $0e, $3c, $38, $2c, $4a, $c8, $6a, $8a
