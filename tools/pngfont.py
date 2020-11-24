#!/usr/bin/env python3
from os import path
from sys import argv
from PIL import Image

from asmlib import lst2asm
from imglib import *

CHARACTERS = ("a","b","c","d","e","f","g","h","i","j","k","l","m",
              "n","o","p","q","r","s","t","u","v","w","x","y","z",
              "point","intero","excla","bonus1","bonus2")

def parse_font_file(fname):
    im = Image.open(fname).convert('1')

    # Slicing image data into a "list" of lines to allow iterating over it multiple times
    raw = list(im.getdata())
    lines = [raw[x:x+8] for x in range(0, len(raw), 8)]

    return [lbool2int((e!=0 for e in l)) for l in lines]

def print_header():
    print("""PART_FX_TEXT_ALIGNED equ *
	ALIGN 256
	echo "[FX text font] Align loss:", (* - PART_FX_TEXT_ALIGNED)d, "bytes"
    """)
    print("text_font:")

def main():
    fontdir = argv[1]
    print_header()
    print("{} ; <spc>".format(lst2asm([False]*8)))
    for c in CHARACTERS:
        fname = path.join(fontdir, "8x8-font-{}.png".format(c))
        font = reversed(parse_font_file(fname))
        print("{} ; {}".format(lst2asm(font), c))

main()
