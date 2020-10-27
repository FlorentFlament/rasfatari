STACK_TOP       = $fc
STACK_SIZE      = 48
STACK_BASE_c1   = (STACK_TOP - STACK_SIZE)
STACK_BASE_c0   = (STACK_BASE_c1 - STACK_SIZE)

tmp             DS.B    1
stack_idx       DS.B    1
cur_note_c0     DS.B    1
cur_note_c1     DS.B    1
