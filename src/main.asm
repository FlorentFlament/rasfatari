;;;-----------------------------------------------------------------------------
;;; Header

	PROCESSOR 6502
	INCLUDE "vcs.h"		; Provides RIOT & TIA memory map
	INCLUDE "macro.h"	; This file includes some helper macros
	INCLUDE "colors.h"

;;;-----------------------------------------------------------------------------
;;; RAM segment

	SEG.U   ram
	ORG     $0080

	echo ""
	echo "-RAM-"
framecnt	DS.B	1
tmp             DS.B	1
        INCLUDE "JahBah-intro2_variables.asm"
ptr = tt_ptr			; Reusing tt_ptr as temporary pointer
	INCLUDE "worm_vars.asm"
        INCLUDE "fx_vars.asm"
	INCLUDE "text_vars.asm"
        echo "Used RAM:", (*)d, "bytes"

;;;-----------------------------------------------------------------------------
;;; Code segment

	SEG code
	ORG $F000

	;; Loading aligned (and non-aligned) data
	echo ""
	echo "-DATA-"

TEXT_FONT_START equ *
	INCLUDE "text_font.asm"
	echo "Font   size:", (* - TEXT_FONT_START)d, "bytes"

        INCLUDE "JahBah-intro2_trackdata.asm"

BANNER_DATA_START equ *
	INCLUDE "banner_data.asm"
	echo "Banner size:", (* - BANNER_DATA_START)d, "bytes"

WORM_DATA_START equ *
	INCLUDE "worm_data.asm"
	echo "Worm   size:", (* - WORM_DATA_START)d, "bytes"

TEXT_DATA_START equ *
	INCLUDE "text_data.asm"
	echo "Text   size:", (* - TEXT_DATA_START)d, "bytes"

	echo ""
	echo "-CODE-"

MAIN_CODE_START equ *
init:   CLEAN_START		; Initializes Registers & Memory
        INCLUDE "JahBah-intro2_init.asm"
	;; jsr worm_init
	jsr fx_init
	jsr text_init

main_loop:	SUBROUTINE
	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

	; 34 VBlank lines (76 cycles/line)
	lda #39			; (/ (* 34.0 76) 64) = 40.375
	sta TIM64T
	jsr fx_vblank
        INCLUDE "JahBah_player.asm"
	;; jsr worm_vblank
	jsr text_vblank
	jsr wait_timint

.kernel:
	; 248 Kernel lines
	lda #19			; (/ (* 248.0 76) 1024) = 18.40
	sta T1024T
	jsr banner_kernel
	;; jsr worm_kernel
	jsr fx_kernel		; scanline 33 - cycle 23
	jsr text_kernel
	jsr wait_timint		; scanline 289 - cycle 30

	; 26 Overscan lines
	lda #22			; (/ (* 26.0 76) 64) = 30.875
	sta TIM64T
	jsr fx_overscan
	jsr text_overscan
	inc framecnt
	jsr wait_timint

	jmp main_loop		; scanline 308 - cycle 15


; X register must contain the number of scanlines to skip
; X register will have value 0 on exit
wait_timint:
	lda TIMINT
	beq wait_timint
	rts
	echo "Main   size:", (* - MAIN_CODE_START)d, "bytes - Music player size"

BANNER_START equ *
	INCLUDE "banner.asm"
	echo "Banner size:", (* - BANNER_START)d, "bytes"

WORM_START equ *
	INCLUDE "worm.asm"
	echo "Worm   size:", (* - WORM_START)d, "bytes"

FX_START equ *
	INCLUDE "fx.asm"
	echo "FX     size:", (* - FX_START)d, "bytes"

TEXT_START equ *
	INCLUDE "text.asm"
	echo "Text   size:", (* - TEXT_START)d, "bytes"

	echo ""
	echo "-TOTAL-"
        echo "Used ROM:", (* - $F000)d, "bytes"

;;;-----------------------------------------------------------------------------
;;; Reset Vector

	SEG reset
	ORG $FFFC
	DC.W init
	DC.W init
