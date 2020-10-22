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

; Song author: 
; Song name: 

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
        dc.b $04, $0c, $04, $0c, $06, $04


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $00, $07, $07, $0d, $17


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $03, $03, $09, $09, $13, $21


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $04, $04, $0a, $0a, $14, $22


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0+1: leadBeep
        dc.b $8f, $8f, $8f, $80, $00, $80, $00
; 2+3: softBeep
        dc.b $86, $86, $86, $00, $86, $00
; 4: bass
        dc.b $8f, $8f, $8f, $8f, $8f, $8e, $8c, $00
        dc.b $80, $00
; 5: chrod
        dc.b $8f, $8f, $8f, $5f, $5f, $5f, $5f, $3d
        dc.b $3a, $37, $30, $00, $80, $00



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
        dc.b $07, $09, $0b, $0d, $0f, $11, $13, $15
        dc.b $17, $19, $1b, $1d, $1e, $1f, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: Snare
        dc.b $8f, $8e, $8d, $8c, $8b, $8a, $89, $88
        dc.b $87, $86, $85, $84, $83, $82, $00


        
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

; chorus0a
tt_pattern0:
        dc.b $4b, $4b, $4b, $08, $4b, $08, $4c, $08
        dc.b $75, $08, $08, $08, $50, $08, $50, $08
        dc.b $71, $08, $7d, $08, $4e, $08, $4e, $08
        dc.b $70, $08, $53, $08, $53, $08, $53, $08
        dc.b $00

; chorus0b
tt_pattern1:
        dc.b $50, $50, $50, $08, $4e, $08, $4b, $08
        dc.b $75, $08, $08, $08, $50, $08, $50, $08
        dc.b $7d, $08, $78, $08, $4e, $08, $4e, $08
        dc.b $53, $50, $53, $08, $55, $08, $53, $08
        dc.b $00

; chorus0c
tt_pattern2:
        dc.b $4e, $4e, $4b, $08, $4e, $08, $3d, $08
        dc.b $71, $08, $08, $08, $50, $08, $50, $08
        dc.b $70, $08, $71, $08, $4e, $08, $4e, $08
        dc.b $53, $50, $4e, $08, $50, $08, $53, $08
        dc.b $00

; mel0a
tt_pattern3:
        dc.b $8e, $08, $5d, $58, $55, $08, $53, $08
        dc.b $8b, $08, $8e, $08, $90, $08, $55, $08
        dc.b $8e, $08, $5d, $08, $5d, $08, $58, $08
        dc.b $93, $08, $55, $08, $90, $08, $5d, $08
        dc.b $00

; mel0b
tt_pattern4:
        dc.b $8e, $08, $53, $55, $53, $08, $5d, $08
        dc.b $93, $08, $90, $08, $8e, $08, $58, $08
        dc.b $90, $08, $5d, $08, $5d, $08, $58, $08
        dc.b $93, $08, $55, $08, $90, $08, $53, $55
        dc.b $00

; mel0c
tt_pattern5:
        dc.b $93, $08, $4e, $50, $53, $08, $4e, $08
        dc.b $8e, $08, $90, $08, $93, $08, $53, $08
        dc.b $8a, $08, $5d, $08, $5d, $08, $55, $08
        dc.b $93, $08, $58, $08, $90, $08, $58, $08
        dc.b $00

; mel1a
tt_pattern6:
        dc.b $8e, $08, $08, $08, $08, $08, $08, $08
        dc.b $31, $8e, $35, $8e, $90, $08, $8e, $08
        dc.b $08, $08, $08, $08, $08, $08, $2a, $8e
        dc.b $93, $08, $2e, $93, $90, $08, $08, $08
        dc.b $00

; mel1b
tt_pattern7:
        dc.b $8b, $08, $08, $08, $08, $08, $08, $08
        dc.b $31, $8b, $35, $8b, $8a, $08, $7d, $08
        dc.b $08, $08, $08, $08, $08, $08, $2a, $7d
        dc.b $8a, $08, $2e, $8a, $90, $08, $08, $08
        dc.b $00

; mel1c
tt_pattern8:
        dc.b $7d, $08, $08, $08, $08, $08, $08, $08
        dc.b $30, $7d, $31, $7d, $8a, $08, $8b, $08
        dc.b $08, $08, $08, $08, $08, $08, $28, $8b
        dc.b $93, $08, $2a, $93, $90, $08, $08, $08
        dc.b $00

; mel2a
tt_pattern9:
        dc.b $53, $08, $53, $08, $7d, $08, $53, $08
        dc.b $4b, $08, $8a, $08, $50, $50, $50, $08
        dc.b $8e, $08, $50, $08, $4e, $08, $4e, $08
        dc.b $8b, $08, $53, $08, $90, $08, $53, $08
        dc.b $00

; mel2b
tt_pattern10:
        dc.b $53, $08, $53, $08, $7d, $08, $53, $08
        dc.b $50, $08, $78, $08, $50, $50, $53, $08
        dc.b $8e, $08, $50, $08, $4e, $08, $4e, $08
        dc.b $8b, $08, $53, $08, $90, $08, $53, $08
        dc.b $00

; mel2c
tt_pattern11:
        dc.b $53, $08, $53, $08, $7d, $08, $53, $08
        dc.b $55, $08, $75, $08, $53, $53, $50, $08
        dc.b $8e, $08, $50, $08, $4e, $08, $4e, $08
        dc.b $90, $08, $53, $08, $95, $08, $53, $08
        dc.b $00

; mel3a
tt_pattern12:
        dc.b $9d, $08, $95, $08, $93, $08, $9d, $08
        dc.b $4e, $4e, $4a, $9d, $90, $08, $93, $08
        dc.b $4e, $50, $4e, $93, $95, $08, $93, $08
        dc.b $50, $4e, $53, $08, $50, $08, $4e, $08
        dc.b $00

; mel3b
tt_pattern13:
        dc.b $8e, $08, $90, $08, $93, $08, $90, $08
        dc.b $3d, $3d, $38, $90, $93, $08, $90, $08
        dc.b $32, $32, $35, $90, $8e, $08, $8a, $08
        dc.b $3d, $3d, $38, $08, $53, $08, $4a, $08
        dc.b $00

; mel3c
tt_pattern14:
        dc.b $7d, $08, $78, $08, $90, $08, $8e, $08
        dc.b $50, $50, $4e, $8e, $7d, $08, $78, $08
        dc.b $4a, $50, $4e, $90, $8e, $08, $8a, $08
        dc.b $3d, $3d, $38, $08, $53, $08, $4a, $08
        dc.b $00

; mel5a
tt_pattern15:
        dc.b $7d, $08, $78, $08, $08, $08, $08, $08
        dc.b $75, $08, $5d, $75, $5d, $75, $58, $75
        dc.b $72, $08, $7d, $08, $55, $7d, $5d, $7d
        dc.b $78, $08, $8a, $08, $4b, $4b, $4e, $08
        dc.b $00

; mel5b
tt_pattern16:
        dc.b $7d, $08, $8e, $08, $53, $8e, $50, $8e
        dc.b $90, $08, $8e, $08, $4e, $8e, $4a, $8e
        dc.b $93, $08, $90, $08, $55, $55, $53, $90
        dc.b $93, $08, $95, $08, $53, $95, $5d, $08
        dc.b $00

; mel5c
tt_pattern17:
        dc.b $6e, $08, $75, $08, $4e, $75, $50, $75
        dc.b $78, $08, $75, $08, $4b, $4b, $4a, $75
        dc.b $72, $08, $70, $08, $50, $50, $4e, $70
        dc.b $6e, $70, $38, $70, $35, $08, $3d, $08
        dc.b $00

; mel4a
tt_pattern18:
        dc.b $4b, $08, $4a, $08, $75, $08, $72, $08
        dc.b $4e, $08, $4e, $08, $50, $08, $70, $08
        dc.b $4e, $08, $4e, $08, $7d, $08, $78, $08
        dc.b $53, $08, $53, $08, $50, $08, $75, $08
        dc.b $00

; mel4b
tt_pattern19:
        dc.b $3d, $08, $4a, $08, $7d, $08, $78, $08
        dc.b $4e, $08, $4e, $08, $4a, $08, $90, $08
        dc.b $4e, $08, $4e, $08, $7d, $08, $8a, $08
        dc.b $53, $08, $53, $08, $50, $08, $93, $08
        dc.b $00

; mel4c
tt_pattern20:
        dc.b $32, $08, $35, $08, $93, $08, $8e, $08
        dc.b $32, $08, $30, $08, $50, $08, $8e, $08
        dc.b $53, $08, $53, $08, $7d, $08, $8e, $08
        dc.b $4a, $08, $53, $08, $50, $08, $90, $08
        dc.b $00

; b+p+m0a
tt_pattern21:
        dc.b $b6, $08, $9d, $08, $d3, $08, $b6, $08
        dc.b $11, $08, $b6, $08, $d3, $08, $9d, $08
        dc.b $b8, $08, $98, $08, $d5, $08, $b8, $08
        dc.b $11, $08, $b6, $08, $d5, $08, $08, $08
        dc.b $00

; b+p+m0b
tt_pattern22:
        dc.b $b6, $08, $9d, $08, $d3, $08, $b6, $08
        dc.b $11, $08, $b6, $08, $d3, $08, $9d, $08
        dc.b $b8, $08, $95, $08, $d5, $08, $be, $08
        dc.b $11, $08, $b8, $08, $d3, $08, $11, $08
        dc.b $00

; b+p+m0c
tt_pattern23:
        dc.b $b6, $08, $9d, $08, $d3, $08, $b6, $08
        dc.b $11, $08, $b6, $08, $d3, $08, $93, $08
        dc.b $b8, $08, $9d, $08, $d5, $08, $b0, $08
        dc.b $11, $08, $b6, $08, $d3, $08, $11, $08
        dc.b $00

; p+m0a
tt_pattern24:
        dc.b $9d, $08, $9d, $08, $d3, $08, $9d, $08
        dc.b $11, $08, $98, $08, $d3, $08, $9d, $08
        dc.b $08, $08, $98, $08, $d5, $08, $9d, $08
        dc.b $11, $08, $08, $08, $d5, $08, $08, $08
        dc.b $00

; p+m0b
tt_pattern25:
        dc.b $98, $08, $9d, $08, $d3, $08, $9d, $08
        dc.b $11, $08, $95, $08, $d3, $08, $9d, $08
        dc.b $08, $08, $95, $08, $d5, $08, $9d, $08
        dc.b $11, $08, $08, $08, $d3, $08, $08, $08
        dc.b $00

; p+m0c
tt_pattern26:
        dc.b $6a, $6e, $70, $08, $d3, $08, $75, $72
        dc.b $70, $78, $75, $08, $d3, $08, $7d, $78
        dc.b $75, $72, $75, $08, $d5, $08, $7d, $8a
        dc.b $8e, $90, $8e, $08, $d3, $08, $93, $08
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
        dc.b <tt_pattern20, <tt_pattern21, <tt_pattern22, <tt_pattern23
        dc.b <tt_pattern24, <tt_pattern25, <tt_pattern26
tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16, >tt_pattern17, >tt_pattern18, >tt_pattern19
        dc.b >tt_pattern20, >tt_pattern21, >tt_pattern22, >tt_pattern23
        dc.b >tt_pattern24, >tt_pattern25, >tt_pattern26        


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
        dc.b $00, $01, $00, $02, $03, $04, $03, $05
        dc.b $00, $01, $00, $02, $06, $07, $06, $08
        dc.b $09, $0a, $09, $0b, $09, $0a, $09, $0b
        dc.b $0c, $0d, $0c, $0e, $00, $01, $00, $02
        dc.b $0f, $10, $0f, $11, $12, $13, $12, $14
        dc.b $12, $13, $12, $14, $80

        
        ; ---------- Channel 1 ----------
        dc.b $15, $16, $15, $17, $15, $16, $15, $17
        dc.b $15, $16, $15, $17, $15, $16, $15, $17
        dc.b $15, $16, $15, $17, $18, $19, $18, $19
        dc.b $15, $16, $15, $17, $15, $16, $15, $19
        dc.b $15, $16, $15, $17, $15, $16, $15, $17
        dc.b $18, $19, $18, $1a, $ad


        echo "Track size: ", *-tt_TrackDataStart
