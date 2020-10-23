STACK_TOP       = $f8
STACK_SIZE      = 60
NOTE_SIZE       = 2
STACK_BASE      = (STACK_TOP - STACK_SIZE)

tmp             DS.B    1
stack_idx       DS.B    1
cur_note        DS.B    2
state           DS.B    1
