STACK_TOP       = $fc
STACK_SIZE      = 100
STACK_BASE      = (STACK_TOP - STACK_SIZE)

tmp             DS.B    1
stack_idx       DS.B    1
cur_note        DS.B    1
