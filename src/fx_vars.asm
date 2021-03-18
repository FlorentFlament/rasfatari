;;; 1 note per 5 lines band (per channel)
;;; 240 lines -> 48 notes
;;; -1 note for space for smooth scrolling
;;; -2 notes for rasta bands
STACK_SIZE = 33

stack_idx       DS.B    1       ; Stack index for pushing notes
stack_ikern     DS.B    1       ; Kernel stack index for display
cur_note_c0     DS.B    1
cur_note_c1     DS.B    1
;;; 3 bytes available

stack_c0	DS.B	STACK_SIZE
stack_c1	DS.B	STACK_SIZE
