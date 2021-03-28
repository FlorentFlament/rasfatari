#!/usr/bin/env python3
from sys import argv
from PIL import Image

from asmlib import lst2asm
from imglib import *

def parse_font_file(fname):
    im = Image.open(fname).convert('1')

    # Getting a 16x8 list
    raw = list(im.getdata())
    chunks = [raw[x:x+8] for x in range(0, len(raw), 8)]
    bhunks = [lbool2int((e!=0 for e in l)) for l in chunks]
    return bhunks[6:-6]

def print_header0():
    print("sprite1:")

def main():
    fname = argv[1]
    data = parse_font_file(fname)
    for i in range(6): # We've got 6 sprites
        print("banner_{}:".format(i))
        print("{}".format(lst2asm(reversed(data[i: len(data): 6]))))

main()
