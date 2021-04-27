;;;;; FX VARS ;;;;;

;;; 1 note per 5 lines band (per channel)
;;; 240 lines -> 48 notes
;;; -1 note for space for smooth scrolling
;;; -2 notes for rasta bands
STACK_SIZE = 33

stack_idx       DS.B    1       ; Stack index for pushing notes
stack_ikern     DS.B    1       ; Kernel stack index for display
cur_note_c0     DS.B    1
cur_note_c1     DS.B    1
;;; 2 bytes available

stack_c0	DS.B	STACK_SIZE
stack_c1	DS.B	STACK_SIZE


;;;;; TEXT VARS ;;;;;

; Variables required for a single text display
; Pointer towards the text to be displayed
fx_text_idx	ds 1
fx_text_cnt	ds 1		; Counter for the text movement

; 12 pointers used to display the text.
; txt_buf is long to initialize so this is done during vblank and must
; not be overriden during the screen display.
; It cannot be mutualized with other FXs ont the screen.
txt_buf	ds 12*2


;;;;; WORM VARS ;;;;;

worm_pos	DS.B	1
worm_ptr	DS.B	2
