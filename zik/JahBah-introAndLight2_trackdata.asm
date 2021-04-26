; TIATracker music player
; Copyright 2016 Andre "Kylearan" Wichmann
; Website: https://bitbucket.org/kylearan/tiatracker
; Email: andre.wichmann@gmx.de
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; Song author: Glafouk
; Song name: Jah Bah (1Ko alt-take)

; @com.wudsn.ide.asm.hardware=ATARI2600

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - tt_InsCtrlTable: the AUDC value
; - tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in tt_InsFreqVolTable
; - tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - tt_InsReleaseIndexes: the index of the start of the Release phase
; - tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
tt_InsCtrlTable:
        dc.b $04, $04, $0c, $04, $0c, $06


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $0e, $0e, $15, $15, $19


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $0a, $11, $11, $15, $15, $1a


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $0b, $12, $12, $16, $16, $1b


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0: chrod
        dc.b $8f, $8f, $8f, $5f, $5f, $5f, $5c, $39
        dc.b $36, $33, $30, $00, $80, $00
; 1+2: leadBeep
        dc.b $8f, $8f, $8f, $80, $00, $80, $00
; 3+4: softBeep
        dc.b $86, $00, $86, $00
; 5: bass
        dc.b $8f, $8c, $00, $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - tt_PercIndexes: The index of the first percussion frame as defined
;       in tt_PercFreqTable and tt_PercCtrlVolTable
; - tt_PercFreqTable: The AUDF frequency value
; - tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
tt_PercIndexes:
        dc.b $01


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
tt_PercFreqTable:
; 0: Snare
        dc.b $10, $03, $05, $07, $05, $03, $01, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: Snare
        dc.b $8f, $8f, $6f, $8f, $8f, $8f, $82, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into tt_SequenceTable for
;       each channel.
;
; So tt_SequenceTable holds indexes into tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs TT_USE_SLIDE): Adjust frequency of last melodic note
;       by -7..+7 and keep playing it
; - Play new note with melodic instrument
; - Play new note with percussion instrument
; - End of pattern
;
; A note is defined by:
; - Bits 7..5: 1-7 means play melodic instrument 1-7 with a new note
;       and frequency in bits 4..0. If bits 7..5 are 0, bits 4..0 are
;       defined as:
;       - 0: End of pattern
;       - [1..15]: Slide -7..+7 (needs TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------
TT_FREQ_MASK    = %00011111
TT_INS_HOLD     = 8
TT_INS_PAUSE    = 16
TT_FIRST_PERC   = 17

; New pattern
tt_pattern0:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; introA
tt_pattern1:
        dc.b $08, $08, $08, $08, $33, $08, $08, $08
        dc.b $70, $08, $6e, $08, $33, $08, $08, $08
        dc.b $6a, $08, $70, $08, $35, $08, $08, $08
        dc.b $11, $08, $6e, $08, $33, $08, $11, $08
        dc.b $00

; chorus0a
tt_pattern2:
        dc.b $6b, $6b, $6b, $08, $6b, $08, $6c, $08
        dc.b $95, $08, $08, $08, $70, $08, $70, $08
        dc.b $91, $08, $9d, $08, $6e, $08, $6e, $08
        dc.b $90, $08, $73, $08, $73, $08, $73, $08
        dc.b $00

; chorus0b
tt_pattern3:
        dc.b $70, $70, $70, $08, $6e, $08, $6b, $08
        dc.b $95, $08, $08, $08, $70, $08, $70, $08
        dc.b $9d, $08, $98, $08, $6e, $08, $6e, $08
        dc.b $73, $70, $73, $08, $75, $08, $73, $08
        dc.b $00

; chorus0c
tt_pattern4:
        dc.b $6e, $6e, $6b, $08, $6e, $08, $5d, $08
        dc.b $91, $08, $08, $08, $70, $08, $70, $08
        dc.b $90, $08, $91, $08, $6e, $08, $6e, $08
        dc.b $73, $70, $6e, $08, $70, $08, $73, $08
        dc.b $00

; mel0a
tt_pattern5:
        dc.b $ae, $08, $7d, $78, $75, $08, $73, $08
        dc.b $ab, $08, $ae, $08, $b0, $08, $75, $08
        dc.b $ae, $08, $7d, $08, $7d, $08, $78, $08
        dc.b $b3, $08, $75, $08, $b0, $08, $7d, $08
        dc.b $00

; mel0b
tt_pattern6:
        dc.b $ae, $08, $73, $75, $73, $08, $7d, $08
        dc.b $b3, $08, $b0, $08, $ae, $08, $78, $08
        dc.b $b0, $08, $7d, $08, $7d, $08, $78, $08
        dc.b $b3, $08, $75, $08, $b0, $08, $73, $75
        dc.b $00

; mel0c
tt_pattern7:
        dc.b $b3, $08, $6e, $70, $73, $08, $6e, $08
        dc.b $ae, $08, $b0, $08, $b3, $08, $73, $08
        dc.b $aa, $08, $7d, $08, $7d, $08, $75, $08
        dc.b $b3, $08, $78, $08, $b0, $08, $78, $08
        dc.b $00

; mel1a
tt_pattern8:
        dc.b $ae, $08, $08, $08, $6b, $ae, $6a, $ae
        dc.b $51, $ae, $55, $ae, $b0, $08, $ae, $08
        dc.b $08, $08, $08, $08, $08, $08, $4a, $ae
        dc.b $b3, $08, $4e, $b3, $b0, $08, $08, $08
        dc.b $00

; mel1b
tt_pattern9:
        dc.b $ab, $08, $08, $08, $6e, $ab, $70, $ab
        dc.b $51, $ab, $55, $ab, $aa, $08, $9d, $08
        dc.b $08, $08, $08, $08, $73, $9d, $4a, $9d
        dc.b $70, $5d, $4e, $aa, $6e, $aa, $70, $08
        dc.b $00

; mel1c
tt_pattern10:
        dc.b $9d, $08, $08, $08, $6e, $9d, $5d, $9d
        dc.b $50, $9d, $51, $9d, $aa, $08, $ab, $08
        dc.b $08, $08, $6e, $ab, $70, $ab, $4a, $ab
        dc.b $08, $b3, $4e, $b3, $55, $b0, $6e, $08
        dc.b $00

; mel4a
tt_pattern11:
        dc.b $6b, $08, $6a, $08, $95, $08, $92, $08
        dc.b $6e, $08, $6e, $08, $70, $08, $90, $08
        dc.b $6e, $08, $6e, $08, $9d, $08, $98, $08
        dc.b $73, $08, $73, $08, $70, $08, $95, $08
        dc.b $00

; mel4b
tt_pattern12:
        dc.b $5d, $08, $6a, $08, $9d, $08, $98, $08
        dc.b $6e, $08, $6e, $08, $6a, $08, $b0, $08
        dc.b $6e, $08, $6e, $08, $9d, $08, $aa, $08
        dc.b $73, $08, $73, $08, $70, $08, $b3, $08
        dc.b $00

; mel4c
tt_pattern13:
        dc.b $52, $08, $55, $08, $b3, $08, $ae, $08
        dc.b $52, $08, $50, $08, $70, $08, $ae, $08
        dc.b $73, $08, $73, $08, $9d, $08, $ae, $08
        dc.b $6a, $08, $73, $08, $70, $08, $b0, $08
        dc.b $00

; introD
tt_pattern14:
        dc.b $08, $08, $08, $08, $33, $08, $08, $08
        dc.b $00

; IntroB
tt_pattern15:
        dc.b $d6, $08, $10, $08, $08, $08, $08, $08
        dc.b $d6, $08, $d9, $08, $d6, $08, $10, $08
        dc.b $d6, $08, $10, $08, $08, $08, $08, $08
        dc.b $d0, $08, $d9, $08, $6e, $08, $6e, $08
        dc.b $00

; b+p+m0a
tt_pattern16:
        dc.b $d6, $08, $bd, $08, $33, $08, $d6, $08
        dc.b $11, $08, $d6, $08, $33, $08, $bd, $08
        dc.b $d9, $08, $b8, $08, $35, $08, $d9, $08
        dc.b $11, $08, $d6, $08, $35, $08, $08, $08
        dc.b $00

; b+p+m0b
tt_pattern17:
        dc.b $d6, $08, $bd, $08, $33, $08, $d6, $08
        dc.b $11, $08, $d6, $08, $33, $08, $bd, $08
        dc.b $d9, $08, $b5, $08, $35, $08, $df, $08
        dc.b $11, $08, $d9, $08, $33, $08, $11, $08
        dc.b $00

; b+p+m0c
tt_pattern18:
        dc.b $d6, $08, $bd, $08, $33, $08, $d6, $08
        dc.b $11, $08, $d6, $08, $33, $08, $b3, $08
        dc.b $d9, $08, $bd, $08, $35, $08, $d0, $08
        dc.b $11, $08, $d6, $08, $33, $08, $11, $08
        dc.b $00

; p+m0a
tt_pattern19:
        dc.b $bd, $08, $bd, $08, $33, $08, $bd, $08
        dc.b $11, $08, $b8, $08, $33, $08, $bd, $08
        dc.b $08, $08, $b8, $08, $35, $08, $bd, $08
        dc.b $11, $08, $08, $08, $35, $08, $08, $08
        dc.b $00

; p+m0c
tt_pattern20:
        dc.b $8a, $8e, $90, $08, $33, $08, $95, $92
        dc.b $90, $98, $95, $08, $33, $08, $9d, $98
        dc.b $95, $92, $95, $08, $35, $08, $9d, $aa
        dc.b $ae, $b0, $ae, $08, $33, $08, $b3, $08
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
tt_PatternPtrLo:
        dc.b <tt_pattern0, <tt_pattern1, <tt_pattern2, <tt_pattern3
        dc.b <tt_pattern4, <tt_pattern5, <tt_pattern6, <tt_pattern7
        dc.b <tt_pattern8, <tt_pattern9, <tt_pattern10, <tt_pattern11
        dc.b <tt_pattern12, <tt_pattern13, <tt_pattern14, <tt_pattern15
        dc.b <tt_pattern16, <tt_pattern17, <tt_pattern18, <tt_pattern19
        dc.b <tt_pattern20
tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16, >tt_pattern17, >tt_pattern18, >tt_pattern19
        dc.b >tt_pattern20        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $00, $00, $00, $01, $02, $03, $02
        dc.b $04, $05, $06, $05, $07, $02, $03, $02
        dc.b $04, $08, $09, $08, $0a, $0b, $0c, $0b
        dc.b $0d, $85

        
        ; ---------- Channel 1 ----------
        dc.b $0e, $0e, $0e, $0e, $0f, $10, $11, $10
        dc.b $12, $10, $11, $10, $12, $10, $11, $10
        dc.b $12, $10, $11, $10, $12, $10, $11, $13
        dc.b $14, $9f


        echo "Track size: ", *-tt_TrackDataStart
