banner:
	dc.b $00, $3f, $30, $00, $c3, $cc, $cc, $c3
	dc.b $c0, $c3, $c0, $30, $00, $30, $3f, $00
	dc.b $00, $ff, $00, $00, $0c, $c3, $c3, $cf
	dc.b $cc, $03, $00, $00, $00, $00, $ff, $00
	dc.b $00, $ff, $00, $00, $30, $33, $33, $30
	dc.b $30, $3c, $30, $0c, $00, $00, $ff, $00
	dc.b $00, $ff, $00, $00, $c3, $33, $33, $f3
	dc.b $33, $c3, $03, $0f, $00, $00, $ff, $00
	dc.b $00, $ff, $00, $00, $0c, $33, $33, $0f
	dc.b $03, $0c, $00, $c0, $00, $00, $ff, $00
	dc.b $00, $fc, $0c, $00, $33, $33, $33, $33
	dc.b $30, $33, $30, $0c, $00, $0c, $fc, $00

smoke0:
	dc.b $03, $0f, $3f, $3c, $30, $3c, $0c, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $c3, $f3, $ff, $ff, $3f, $0f, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $f0, $ff, $ff, $ff, $ff, $ff, $3f, $0f
	dc.b $01, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $c3, $fc, $f0, $ff, $9c, $9c
	dc.b $f8, $60, $00, $00, $00, $00, $00, $00
	dc.b $3c, $c3, $03, $0c, $f0, $03, $03, $03
	dc.b $0c, $0c, $03, $03, $0c, $30, $30, $0c
	dc.b $00, $00, $30, $30, $30, $0c, $0c, $03
	dc.b $03, $0c, $0c, $0c, $30, $30, $0c, $03

smoke1:
	dc.b $03, $0f, $0f, $3c, $30, $30, $30, $30
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $c0, $f3, $ff, $ff, $3f, $0c, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $3c, $ff, $ff, $ff, $ff, $3f, $0f, $03
	dc.b $03, $03, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $c0, $c3, $fc, $f0, $ff, $9c
	dc.b $fc, $f0, $c0, $00, $00, $00, $00, $00
	dc.b $00, $3c, $c3, $03, $3c, $c0, $03, $03
	dc.b $00, $00, $03, $0c, $30, $30, $0c, $0c
	dc.b $00, $00, $00, $30, $30, $0c, $0c, $0c
	dc.b $c3, $c3, $03, $0c, $0c, $30, $30, $0c

smoke2:
	dc.b $03, $0f, $0f, $3c, $30, $f0, $30, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $c0, $f3, $ff, $ff, $3f, $0f, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $30, $fc, $fc, $ff, $ff, $cf, $0f, $0f
	dc.b $03, $03, $03, $00, $00, $00, $00, $00
	dc.b $00, $00, $03, $0c, $f0, $f3, $fc, $fc
	dc.b $9c, $9c, $f0, $c0, $00, $00, $00, $00
	dc.b $3c, $c3, $03, $0c, $f0, $03, $03, $03
	dc.b $03, $0c, $0c, $30, $30, $0c, $0c, $03
	dc.b $00, $00, $00, $30, $30, $30, $0c, $0c
	dc.b $0c, $30, $c0, $c0, $30, $0c, $03, $03

smoke_tbl_l:
	dc.b <smoke0, <smoke1, <smoke2, <smoke1, <smoke0, <smoke2, <smoke1, <smoke2
smoke_tbl_h:
	dc.b >smoke0, >smoke1, >smoke2, >smoke1, >smoke0, >smoke2, >smoke1, >smoke2
