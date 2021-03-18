#!/usr/bin/env python3
import sys

data = sys.stdin.read()

chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

for c in chars:
    if c not in data:
        print(c)
