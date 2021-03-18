; Text to display is pointed to by ptr
	MAC m_fx_text_load
	ldy #11 ; Load the 12 characters to be displayed
.next:
	; Compute offset in the txt_buf buffer and move to X
	tya
	asl
	tax

	; Compute pointer towards LSB towards font
	lda (ptr),Y
	asl
	asl
	asl
	sta txt_buf,X
	; MSB
	lda #>text_font
	sta txt_buf+1,X

	dey
	bpl .next
	ENDM

; Setup text to be displayed
; fx_text_idx contains the text index to fetch
; Uses tmp, ptr
; txt_buf will be filled with the appropriate pointers
	MAC m_text_setup
.setup:
	; Multiply by 12 fx_text_idx
	; *4 first
	lda #0
	sta tmp ; MSB
	lda fx_text_idx
	REPEAT 2
	asl
	rol tmp
	REPEND
	sta ptr
	lda tmp
	sta ptr + 1

	; *8 then
	lda ptr ; LSB
	asl
	rol tmp ; MSB

	; *12 - Add ptr to A and tmp
	clc
	adc ptr
	sta ptr
	lda tmp
	adc ptr + 1
	sta ptr + 1

	; + text
	; No possible carry by multiplying x in [0..255] by 12
	lda ptr
	adc #<text
	sta ptr
	lda ptr + 1
	adc #>text
	sta ptr + 1
.load_text:
	;; Then load the text from ptr
	m_fx_text_load
	ENDM

fx_text_setup:	SUBROUTINE
	m_text_setup
	rts

text_init:	SUBROUTINE
	lda #7
	sta fx_text_cnt
	lda #0
	sta fx_text_idx
	rts

text_vblank:	SUBROUTINE
	lda framecnt
	and #$07
	bne .continue
	dec fx_text_cnt
	bpl .continue
	inc fx_text_idx
	lda #11
	sta fx_text_cnt
.continue:
	jsr fx_text_setup
	;; Check for end of text signified by #$00
	ldy #0
	lda (ptr),Y
	bne .end
	lda #0			; Loop text
	sta fx_text_idx
	jsr fx_text_setup
.end
	rts

text_overscan:	SUBROUTINE
	rts

;;; FX Text Main Kernel part
;;; Note that this doesn't need to be aligned
;;; Y in [0; 7] to store the number of lines to display (skipping top lines)
;;; tmp in [0; 7] to store the number of lines to display as well (skipping bottom lines)
;;; Uses X, Y and A
	MAC m_fx_text_kernel_main
	;; Moving characters 8 pixels to the right
	lda #$80
	sta HMP0
	lda #$80
	sta HMP1
	; odd lines - Shifted by 8 pix to the right -> 108
	; Exploiting a bug to move the sprites of +8 pixels
	; This happens when writing HMOVE at the end of the scanline.
	; L54: Display 2*8 lines
	; This uses Y reg
	lda #LIGHT_GREY
	sta COLUP0
	sta COLUP1
	jmp .constant
	ALIGN 128,$ea		; loop size is 83 bytes - align with nops
.constant:
	sta WSYNC
.txt_ln:			; 76 machine cycles per line
	sta HMOVE		; 3   3
	lda (txt_buf+2),Y	; 5   8
	sta GRP0		; 3  11
	lda (txt_buf+6),Y	; 5  16
	sta GRP1		; 3  19
	lda (txt_buf+22),Y	; 5  24
	tax		; 2  26 78
	REPEAT 3
	nop
	REPEND		; 6  32
	lda (txt_buf+10),Y	; 5  37
	sta GRP0		; 3  40 120
	lda (txt_buf+14),Y	; 5  45
	sta GRP1		; 3  48
	lda (txt_buf+18),Y	; 5  53
	sta GRP0		; 3  56
	stx GRP1		; 3  59 154
	sta HMCLR		; 3  62
	REPEAT 4
	nop
	REPEND		; 8  70
	sta HMOVE		; 3  73 - End of scanline
	;; even lines
	;; Moving characters 8 pixels to the left
	lda (txt_buf+0),Y	; 5   2
	sta GRP0		; 3   5
	lda (txt_buf+4),Y	; 5  10
	sta GRP1		; 3  13
	lda (txt_buf+20),Y	; 5  18
	tax		; 2  20
	;; Moving characters 8 pixels to the right
	lda #$80		; 2  22
	sta HMP0		; 3  25
	lda #$80		; 2  27
	sta HMP1		; 3  30
	;; Updating sprites graphics
	lda (txt_buf+8),Y	; 5  35
	sta GRP0		; 3  38
	lda (txt_buf+12),Y	; 5  43
	sta GRP1		; 3  46
	lda (txt_buf+16),Y	; 5  51
	sta GRP0		; 3  54
	stx GRP1		; 3  57
	;; Shorten the loop when tmp<0 - useful for scroller
	dec tmp			; 5  62
	bmi .end		; 2  64
	cpy framecnt		; 3  67 ; Just spend 3 clock cycles
	nop			; 2  69
	nop			; 2  71
	;; Updating color
	;;lda text_color,Y	; 4  61
	;;sta COLUP0		; 3  64
	;;sta COLUP1		; 3  67
	;; looping logic
	dey			; 2 73
	bpl .txt_ln		; 3(2+1) 76
	echo "[Text loop] length:", (* - TEXT_LOOP_START)d, "bytes"
.end:
	ENDM

;;; Macro that skips lines to move the text up and down
	MAC m_fx_text_skip_lines
	lda fx_text_cnt
	lsr
	tay
	lda text_skip_table,Y
	tay
.skip_lines:
	sta WSYNC
	dey
	bpl .skip_lines
	ENDM

fx_text_print_line:	SUBROUTINE
	sta WSYNC
	m_fx_text_kernel_main
	rts

; FX Text Kernel
; This will be used twice (2 different kernels)
text_kernel:	SUBROUTINE
	lda #$06 ; 3 copies small (Number & Size)
	sta NUSIZ0
	sta NUSIZ1
	jsr fx_text_position

	lda framecnt
	and #$04
	bne .no_additional_wsync
	sta WSYNC
	;; skip an additional line to account for the fact that each text line is on 2 lines

.no_additional_wsync:
	ldy fx_text_cnt
.skip_loop:
	cpy #8
	bcc .display
	sta WSYNC
	sta WSYNC
	dey
	jmp .skip_loop

.display:
	sty tmp
	jsr fx_text_print_line
	lda #$0
	sta GRP0
	sta GRP1

	inc fx_text_idx
	jsr fx_text_setup

	lda #14
	sec
	sbc fx_text_cnt
	sta tmp
	ldy #7
	jsr fx_text_print_line
	lda #$0
	sta GRP0
	sta GRP1

	inc fx_text_idx
	jsr fx_text_setup

	lda #2
	sec
	sbc fx_text_cnt
	bmi .end
	sta tmp
	ldy #7
	jsr fx_text_print_line
	lda #$0
	sta GRP0
	sta GRP1

.end:
	dec fx_text_idx
	dec fx_text_idx
	rts

; Position the sprites
; 12*8 = 96 pixels for the text
; i.ie 32 pixels on each side (160 - 96)/2
; +68 HBLANK = 100 pixels for RESP0
; Must be aligned !
FX_TEXT_POS_ALIGN equ *
	ALIGN 8
	echo "[FX text pos] Align loss:", (* - FX_TEXT_POS_ALIGN)d, "bytes"
fx_text_position SUBROUTINE
FX_TEXT_POS equ *
	sta WSYNC
	ldx #6  		; 2 - Approx 128 pixels / 15
.posit	dex		; 2
	bne .posit	; 2** (3 if branching)
	echo "[FX text pos] Loop:", (* - FX_TEXT_POS)d, "bytes"
	sta RESP0		; 3 34 (2 + 5*(2+3) + 4 + 3)
	; 102 pixels - 68 = 34 ; -> 39 observerd on Stella
	nop
	sta RESP1
	lda #$70		; -> now 100 pixels
	sta HMP0
	lda #$60
	sta HMP1
	sta WSYNC
	sta HMOVE

	; Don't touch HMPx for 24 cycles
	ldx #4
.dont_hmp	dex
	bpl .dont_hmp
	rts

text:
	dc.b "            "
	dc.b "            "
	dc.b "   FLUSH    "
	dc.b "  PRESENTS  "
	dc.b "  RASFATARI "
	dc.b "            "
	dc.b "AN ATARI VCS"
	dc.b "_K INTRO    "
	dc.b "RELEASED AT "
	dc.b "SHADOW PARTY"
	dc.b "        ][]\"
	dc.b "            "
	dc.b "][][QS CRAP "
	dc.b "BUT AT LEAST"
	dc.b "WE COULD PUT"
	dc.b "THOSE BITS  "
	dc.b "TOGETHER    "
	dc.b "ON OUR GOOD "
	dc.b "OLD MACHINE "
	dc.b "            "
	dc.b "  CREDITS   "
	dc.b "MSX NQ GFX  "
	dc.b "GLAFOUK     "
	dc.b "      CODE  "
	dc.b "      FLEWWW"
	dc.b "            "
	dc.b "GREETINGS   "
	dc.b "TO ALL THE  "
	dc.b "PEOP WE LOVE"
	dc.b "INCLUDING   "
	dc.b "BUT NOT     "
	dc.b "LIMITED TO  "
	dc.b "      ALTAIR"
	dc.b "CLUSTER     "
	dc.b "       COINE"
	dc.b "COOKIE CREW "
	dc.b "   DELICIOUS"
	dc.b "   AMIGANS  "
	dc.b "DENTIFRICE  "
	dc.b "         DMA"
	dc.b "DUNE        "
	dc.b "     GENESIS"
	dc.b "     PROJECT"
	dc.b "GOBLINISH   "
	dc.b "         JAC"
	dc.b " LABORATOIRE"
	dc.b "MYSTIC BYTES"
	dc.b "       NOICE"
	dc.b "POPSY TEAM  "
	dc.b "        RBBS"
	dc.b "RESISTANCE  "
	dc.b "  SECTOR ONE"
	dc.b "SWYNG       "
	dc.b "     TENFOUR"
	dc.b "TMP         "
	dc.b "    TRILOBIT"
	dc.b "UNDEAD      "
	dc.b "SCENERS     "
	dc.b "    UP ROUGH"
	dc.b "  ULTRASYD  "
	dc.b "VITAL MOTION"
	dc.b "       WAMMA"
	dc.b "XAYAX       "
	dc.b "       X MEN"
	dc.b "   AND YOU  "
	dc.b 0,"           "
	dc.b "            "
