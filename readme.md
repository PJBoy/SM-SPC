# SM-SPC
A fully symbolic, asar-assemblable source code for Super Metroid's SPC (audio) engine.

The vanilla directory contains the source code for generating a byte-for-byte copy of the data block of the SPC engine and writing it to the correct location ($CF:8104). See vanilla/main.asm for instruction.

The main directory is reserved for customisations/optimisations to the engine.

The assembler used by this project is currently (thedopefish's fork of) asar: https://github.com/thedopefish/asar

The Super Metroid SPC engine was both disassembled and rewritten in source form by myself.
The original disassembly (with line addresses and comments) can be viewed here: http://patrickjohnston.org/ASM/ROM%20data/Super%20Metroid/SPC%20disassembly.asm
