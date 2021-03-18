#!/usr/bin/env python3
from sys import argv
from PIL import Image

from asmlib import lst2asm
from imglib import *

def parse_font_file(fname):
    im = Image.open(fname).convert('1')

    # Getting a 16x8 list
    raw = list(im.getdata())
    sprite0 = [raw[x:x+8] for x in range(0, len(raw), 16)]
    sprite1 = [raw[x:x+8] for x in range(8, len(raw), 16)]
    lines = sprite0 + sprite1

    return [lbool2int((e!=0 for e in l)) for l in lines]

def print_header0():
    print("sprite1:")

def main():
    fname = argv[1]
    data = list(reversed(parse_font_file(fname)))
    print("worm_sprite0:")
    print("{}".format(lst2asm(data[0:8])))
    print("worm_sprite1:")
    print("{}".format(lst2asm(data[8:16])))

main()
