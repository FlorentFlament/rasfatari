INCDIRS=inc zik src
DFLAGS=$(patsubst %,-I%,$(INCDIRS)) -f3 -d

# asm files
SRC=$(wildcard src/*.asm)
ZIK=$(wildcard zik/*.asm)

all: main.bin hardware.bin

main.bin: src/main.asm $(SRC) $(ZIK)
	dasm $< -o$@ -lmain.lst -smain.sym $(DFLAGS)

hardware.bin: src/main.asm $(SRC) $(ZIK)
	dasm $< -o$@ -DHARDWARE_COLORS -lhardware.lst -shardware.sym $(DFLAGS)

run: main.bin
	stella $<

clean:
	rm -f main.bin main.lst main.sym
	rm -f hardware.bin hardware.lst hardware.sym
