worm_pos	DS.B	1
worm_ptr	DS.B	2
;;; State
;;; bit 7: direction 0 = left to right, 1 = right to left
;;; bits 6-5: triggers the worm when bits 6-5 = 0
;;; bits 7-6-5 gets incremented every 256 frames (i.e framecnt = 0)
;;; bits 1-0: color or the worm, value in [0; 2]
worm_state	DS.B	1
