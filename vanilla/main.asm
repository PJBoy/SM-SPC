; Build with:
;     asar --fix-checksum=off main.asm SM.sfc

; where SM.sfc is your vanilla ROM with an sfc extension (asar requirement).
; The `--fix-checksum=off` is there because asar's checksum generation is incorrect (probably related to the bottom of this file)

math pri on ; Use conventional maths priority (otherwise is strict left-to-right evaluation)
warnings disable W1018 ; "xkas-style conditional compilation detected. Please use the if command instead. [rep 0]"
lorom


; The SPC engine data block is written directly via the spc700-inline arch,
; which handles writing the data block header containing the block size and ARAM destination.
; Note that an org statement defines a new data block (i.e. only use org once, at the beginning)

org $CF8104 ; The actual ROM location the data block is going to be written to

arch spc700-inline
org $1500 ; In the inline arch, this implies `base $1500` and is used as destination for the data block header

incsrc "ram.asm"

; $1500
print "$",pc, ": Engine"
incsrc "engine.asm"

; $172D
print "$",pc, ": Music"
incsrc "music.asm"

; $1E1D
print "$",pc, ": Engine data"
incsrc "engine data.asm"

; $1E8B
print "$",pc, ": System"
incsrc "system.asm"

; Contains macros to generate code that's generic across sound libraries
incsrc "sound library.asm"

; $1EE4
print "$",pc, ": Sound library 1"
incsrc "sound library 1.asm"

; $3154
print "$",pc, ": Sound library 2"
incsrc "sound library 2.asm"

; $4703
print "$",pc, ": Sound library 3"
incsrc "sound library 3.asm"

; $530E
print "$",pc, ": Shared trackers"
incsrc "shared trackers.asm"

; $56E2
print "$",pc, ": EOF"


; The inline arch writes a terminator data block, which we don't want. The below is reverting that
arch 65816
org $CFC2EA

dw read2($CFC2EA), read2($CFC2EC)
