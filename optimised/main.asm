; Build with:
;     asar --fix-checksum=off main.asm SM.sfc

; where SM.sfc is your vanilla ROM with an sfc extension (asar requirement).
; The `--fix-checksum=off` is there because asar's checksum generation is incorrect (probably related to the bottom of this file)

math pri on ; Use conventional maths priority (otherwise is strict left-to-right evaluation)
warnings disable W1018 ; "xkas-style conditional compilation detected. Please use the if command instead. [rep 0]"


; The SPC engine data block is written directly via the spc700-inline arch,
; which handles writing the data block header containing the block size and ARAM destination.
; Note that an org statement defines a new data block (i.e. only use org once, at the beginning)

lorom
org $CF8104 ; The actual ROM location the data block is going to be written to

arch spc700-inline
org $1500 ; In the inline arch, this implies `base $1500` and is used as destination for the data block header

incsrc "ram.asm"

print "$",pc, ": Engine"
incsrc "engine.asm"

print "$",pc, ": Utility"
incsrc "utility.asm"

print "$",pc, ": Music"
incsrc "music.asm"

; Contains macros to generate code that's generic across sound libraries
incsrc "sound library.asm"

print "$",pc, ": Sound library 1"
incsrc "sound library 1.asm"

print "$",pc, ": Sound library 2"
incsrc "sound library 2.asm"

print "$",pc, ": Sound library 3"
incsrc "sound library 3.asm"

print "$",pc, ": Sound library 3 end"

; The trackers are pointed to by external music data, so it needs to stay here for now and can't be modified in any way
warnpc $530E
padbyte $00 : pad $CFBF16 ; Asar requires a CPU address here. Possibly a bug, if so fix this if the bug gets fixed

print "$",pc, ": Shared trackers"
incsrc "shared trackers.asm"

print "$",pc, ": EOF"

; padbyte $00 : pad $CFC2EA ; Asar requires a CPU address here. Possibly a bug, if so fix this if the bug gets fixed
warnpc $56E2

; The inline arch writes a terminator data block, which we don't want. The below is reverting that
arch 65816
org $CFC2EA

dw read2($CFC2EA), read2($CFC2EC)
