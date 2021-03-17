lombric_kernel:	SUBROUTINE
	sta WSYNC
	ldy 7
.loop:
	lda lombric_sprite_a,Y
	sta GRP0
	lda lombric_sprite_b,Y
	sta GRP1
	sta WSYNC
	dey
	bpl .loop

	lda #$0
	sta GRP0
	sta GRP1
	rts

lombric_sprite_a:
	dc.b 1, 2, 3, 4, 5, 6, 7, 8
lombric_sprite_b:
	dc.b 8, 7, 6, 5, 4, 3, 2, 1
