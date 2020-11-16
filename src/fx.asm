;;; Colors
GREEN = $56
YELLOW = $2a
RED = $66
LIGHT_GREY = $0c
DARK_GREY = $06

;;; Get current note being played
;;; the channel must be passed as a macro argument (0 or 1)
;;; Current note is returned in A
;;; - Bits 7..5: instrument
;;; - Bits 4..0: frequency
;;; Uses A, X and Y and tmp
    MAC GET_CURRENT_NOTE
	;; Don't touch tt_cur_note_index_c{1} and tt_cur_pat_index_c{1}
        ;; Use copies instead
        ldx tt_cur_note_index_c{1}      ; get current note into pattern
        lda tt_cur_pat_index_c{1}       ; get current pattern (index into tt_SequenceTable)
        sta tmp
.constructPatPtr:
        ldy tmp
        lda tt_SequenceTable,y
        and #$7f                ; If we arrive at the end of tune, we loop
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        txa
        tay
        lda (tt_ptr),y
        bne .noEndOfPattern
        ; End of pattern: Advance to next pattern
        tax                             ; A is 0
        inc tmp
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

    MAC GET_VOLUME_COMMON
        lda tt_envelope_index_c{1}
        cmp tt_InsReleaseIndexes-1,y    ; -1 because instruments start with #1
        bne .noEndOfSustain
        ; End of sustain: Go back to start of sustain
        lda tt_InsSustainIndexes-1,y    ; -1 because instruments start with #1
.noEndOfSustain:
        tay
    ENDM

;;; Note must be in Y
;;; Uses A and Y
;;; At the end, the note volume is in A
    MAC GET_NOTE_VOLUME
        GET_VOLUME_COMMON {1}
        ; Set volume from envelope
        lda tt_InsFreqVolTable,y
        and #$0f                ; Extract volume
    ENDM
    MAC GET_PERC_VOLUME
        GET_VOLUME_COMMON {1}
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
        lda stack_c{1},X
        ldy #$40                ; Replace previous note with #$40
        sty stack_c{1},X
.end:
        ldx stack_idx
        sta stack_c{1},X
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
        lda stack_c{1},X
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

        sta WSYNC
        sta HMOVE               ; Commit notes fine tuning
        GET_NOTE_COLOR 0
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
        sleep 19
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

    MAC RASTA_BAND
        lda #GREEN
        sta COLUBK
        sta WSYNC
        sta WSYNC
        lda #YELLOW
        sta COLUBK
        sta WSYNC
        sta WSYNC
        lda #RED
        sta COLUBK
        sta WSYNC
    ENDM

;;; Functions used in main
fx_init:        SUBROUTINE
        ;; Init stack
        lda #(STACK_SIZE - 1)
        sta stack_idx
        rts

fx_vblank:      SUBROUTINE
        ;; Setup missiles
        lda #$30
        sta NUSIZ0
        sta NUSIZ1

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
        sta WSYNC
        RASTA_BAND

        sec
        lda #4
        sbc tt_timer
        tay
.pre_loop:
        sta WSYNC
        lda #$00
        sta COLUBK
        dey
        bpl .pre_loop

        lda stack_idx
        sta stack_ikern ; Used to iterate on the stack each frame
        lda #STACK_SIZE-1
        sta tmp
.loop:  ; 5 lines per loop
        DISPLAY_BAND
        dec tmp
        bmi .end
        jmp .loop

.end:

        ldy tt_timer
.post_loop:
	sta WSYNC
        lda #0
        sta ENAM0
        sta ENAM1
        dey
        bpl .post_loop

	RASTA_BAND
	sta WSYNC
	lda #$00
	sta COLUBK
        rts

fx_overscan:    SUBROUTINE
	rts

colors_table:
        dc.b LIGHT_GREY		; Drum
	dc.b GREEN		; LeadBeep - High
	dc.b GREEN		; LeadBeep - Low
	dc.b YELLOW		; SoftBeep - High
	dc.b YELLOW		; SoftBeep - Low
	dc.b DARK_GREY		; Bass
	dc.b RED		; Chords
