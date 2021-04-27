#!/usr/bin/env python3
from sys import argv
from PIL import Image

from asmlib import lst2asm
from imglib import *

def parse_font_file(fname):
    im = Image.open(fname).convert('1')
    raw = list(im.getdata())

    if len(raw) != 48*16:
        print("Format of image \"{}\" doesn't match.".format(fname))
        print("Expecting {}=48x16 pixels, but got {}".format(48*16, len(raw)))
        exit(1)

    chunks = [raw[x:x+8] for x in range(0, len(raw), 8)]
    bhunks = [lbool2int((e!=0 for e in l)) for l in chunks]
    # return bhunks[6:-6] # Removing empty first and last lines
    return bhunks

def main():
    fname = argv[1]
    data = parse_font_file(fname)
    for i in range(6): # We've got 6 sprites
        print("banner_{}:".format(i))
        print("{}".format(lst2asm(reversed(data[i: len(data): 6]))))

main()
