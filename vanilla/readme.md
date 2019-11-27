This directory contains the source code for generating a byte-for-byte copy of the data block of the SPC engine and writing it to the correct location ($CF:8104). See main.asm for instruction.

The files here are assembled into the following order:
* engine.asm
* music.asm
* engine data.asm
* system.asm
* sound library 1.asm
* sound library 2.asm
* sound library 3.asm
* shared trackers.asm

This is a rough and arbitrary division, there will be routines in music.asm that are called by the sound libraries for example.

engine.asm contains the entry point, main game loop and some general utility functions.  
engine data.asm contains some associated data.  
system.asm contains just the CPU->APU data transfer function and a memclear function.

The three sound libraries handle the three types of sound effect Super Metroid can play.
Each is associated with a CPU IO channel ($F5/$F6/$F7) and have unique sets of sound effects that be played by that library.

Sound library 1 is mostly Samus related, sound library 2 is mostly enemy ralted, and sound library 3 more miscallaneous. See http://patrickjohnston.org/ASM/Lists/Super%20Metroid/Sound%20effects.asm

Library 1 sound effects are able to use up to four voices, whilst library 2/3 sound effects may only use up to two voices.
