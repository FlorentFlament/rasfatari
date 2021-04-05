worm_colors:
	dc.b RED, YELLOW, GREEN

worm_sprite0_ptrl:
	dc.b <worm_sprite0_a, <worm_sprite0_b, <worm_sprite0_c, <worm_sprite0_d
worm_sprite0_ptrh:
	dc.b >worm_sprite0_a, >worm_sprite0_b, >worm_sprite0_c, >worm_sprite0_d

worm_sprite0_a:
	dc.b $9f, $fc, $e0, $00, $00, $00, $00, $00
worm_sprite1_a:
	dc.b $07, $0f, $1c, $38, $58, $78, $30, $00
worm_sprite0_b:
	dc.b $8e, $dc, $f8, $70, $00, $00, $00, $00
worm_sprite1_b:
	dc.b $03, $07, $0e, $0e, $16, $1e, $0c, $00
worm_sprite0_c:
	dc.b $10, $30, $60, $60, $c0, $c0, $80, $00
worm_sprite1_c:
	dc.b $04, $0e, $0f, $1f, $2d, $3d, $18, $00
worm_sprite0_d:
	dc.b $70, $f8, $cc, $80, $00, $00, $00, $00
worm_sprite1_d:
	dc.b $0c, $1e, $3f, $3b, $58, $78, $30, $00
