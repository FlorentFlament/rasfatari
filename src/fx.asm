MAX_TIME = 47 ; 240 lines, 5 lines per period -> 48 periods

;;; Get current note being played
;;; the channel must be passed as a macro argument (0 or 1)
;;; Y is used
;;; Current note is returned in A
;;; - Bits 7..5: instrument
;;; - Bits 4..0: frequency
;;; Uses A and Y
    MAC GET_CURRENT_NOTE
.constructPatPtr:
        ldy tt_cur_pat_index_c{1}       ; get current pattern (index into tt_SequenceTable)
        lda tt_SequenceTable,y
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        ldy tt_cur_note_index_c{1}
        lda (tt_ptr),y
        bne .noEndOfPattern
        ; End of pattern: Advance to next pattern
        sta tt_cur_note_index_c{1}      ; a is 0
        inc tt_cur_pat_index_c{1}
        bne .constructPatPtr            ; unconditional
.noEndOfPattern:
    ENDM

;;; Swap instrument (bits 7-5) and frequency (bits 4-0)
;;; Note must be in A and the result will be in A
;;; At the end:
;;; Frequency occupies bits 7-3
;;; Instrument occupies bits 2-0
    MAC SWAP_NOTE
        REPEAT 3
        cmp #$80
        rol
        REPEND
    ENDM

;;; Argument is the channel to consider
;;; Y: index of note to test
;;; At exit Z is set if this is a new note
;;; Modifies A
    MAC IS_NEW_NOTE
        lda tt_envelope_index_c{1}
        cmp tt_InsADIndexes-1,Y
    ENDM

;;; Note must be in Y
;;; Uses A and Y
;;; At the end, the note volume is in A
    MAC GET_NOTE_VOLUME
        lda tt_envelope_index_c{1}
        cmp tt_InsReleaseIndexes-1,y    ; -1 because instruments start with #1
        bne .noEndOfSustain
        ; End of sustain: Go back to start of sustain
        lda tt_InsSustainIndexes-1,y    ; -1 because instruments start with #1
.noEndOfSustain:
        tay
        ; Set volume from envelope
        lda tt_InsFreqVolTable,y
        and #$0f                ; Extract volume
    ENDM

    MAC GET_PERC_VOLUME
        lda tt_envelope_index_c{1}
        cmp tt_InsReleaseIndexes-1,y    ; -1 because instruments start with #1
        bne .noEndOfSustain
        ; End of sustain: Go back to start of sustain
        lda tt_InsSustainIndexes-1,y    ; -1 because instruments start with #1
.noEndOfSustain:
        tay
        ; Set volume from envelope
        lda tt_PercCtrlVolTable,y
        and #$0f                ; Extract volume
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
;;; Channel must be provided as argument (0 or 1)
;;; Uses X, Y and A registers
    MAC PUSH_NEW_NOTE
        GET_CURRENT_NOTE {1}
        cmp #TT_FIRST_PERC       ; below that, there's only HOLD (or unused PAUSE)
        bcc .no_new_note
.new_note:
        SWAP_NOTE
        jmp .end

.no_new_note:
        ;; Silence or Sustain ?
        lda tt_cur_ins_c{1}     ; Load active instrument
        REPEAT 5                ; Extract instrument
        lsr
        REPEND
        tay
        bne .instrument
        GET_PERC_VOLUME {1}
        beq .silence
        bne .sustain            ; unconditional
.instrument:
        GET_NOTE_VOLUME {1}     ; Note is still in Y
        bne .sustain
.silence:
        lda #$00
        jmp .end

.sustain:
        ;; We need to swap previous note with current #$40
        ldx stack_idx
        inx
        cpx #STACK_SIZE
        bne .no_wrap
        ldx #0
.no_wrap:
        lda #STACK_BASE_c{1},X
        ldy #$40                ; Replace previous note with #$40
        sty #STACK_BASE_c{1},X
.end:
        ldx stack_idx
        sta #STACK_BASE_c{1},X
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
;;; channel must be provided as argument (0 or 1)
;;; Uses A, X
;;; A get cur_note
    MAC FETCH_NEXT_NOTE
        ldx stack_ikern
        lda #(STACK_BASE_c{1}),X
        sta cur_note_c{1}
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

        FETCH_NEXT_NOTE 0      ; cur_note_c0 is in A
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
        lda cur_note_c0
        beq .skip_c0_note
        lda #2
        sta ENAM0
.skip_c0_note:
        FETCH_NEXT_NOTE 1      ; cur_note_c1 is in A
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
        sleep 15
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
        lda cur_note_c1
        beq .skip_c1_note
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
        beq .new_notes
        jmp .end
.new_notes:
        PUSH_NEW_NOTE 0
        PUSH_NEW_NOTE 1
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
