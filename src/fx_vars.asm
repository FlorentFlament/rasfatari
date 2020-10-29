STACK_SIZE      = 48

stack_idx       DS.B    1       ; Stack index for pushing notes
stack_idkern    DS.B    1       ; Kernel stack index for display
cur_note_c0     DS.B    1
cur_note_c1     DS.B    1

STACK_BASE_c0 = *
STACK_BASE_c1 = (STACK_BASE_c0 + STACK_SIZE)
STACK_TOP = (STACK_BASE_c0 + 2*STACK_SIZE)
