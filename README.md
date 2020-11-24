# Atari VCS DASM Framework

This repository contains a simple DASM based Atari VCS framework. This
is based on the [Atari VCS Hello
World](https://github.com/FlorentFlament/hello-vcs), but uses the RIOT
timer to provide more freedom for the FX. Additionally, an FX
displaying pseudo-random colors is provided as an example. This code
is aimed at being reused as a starting point to make amazing demos for
the Atari VCS platform !


## Prerequisite

* This code has been written in DASM. The assembler can be downloaded
  from [DASM project's page](http://dasm-dillon.sourceforge.net/)

* An Atari VCS emulator (though binaries can be tested on the real
  hardware instead). [Stella](https://stella-emu.github.io) is an
  excellent emulator and debugger for the Atari 2600.

* Make is needed to be able to use the Makefile. Though one can launch
  the commands of the Makefile without using make.


## Launching hello-vcs

    $ make
    dasm main.asm -f3 -omain.bin -lmain.lst -smain.sym -d
    Debug trace OFF

    Complete.
    $ make run
    stella main.bin


## Files

* `main.asm` contains the framework, doing some initializing and
  executing the main loop, ensuring appropriate synchronization
  signals are sent to the TIA.

* `fx.asm` is an example of FX. It consists in displaying a grid of
  random colors changing a couple of times per second.

* `vcs.h` is copied from DASM repository. It contains the address
  mapping of the Atari VCS RIOT and TIA registers.

* `macro.h` is copied from DASM repository. It contains a couple of
  helper macros.

* `Makefile`

* `README.md` is this very file.
