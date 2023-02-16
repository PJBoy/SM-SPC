; Build with:
;     asar --fix-checksum=off main.asm SM.sfc

; where SM.sfc is your vanilla ROM with an sfc extension (asar requirement).
; The `--fix-checksum=off` is there because asar's checksum generation is incorrect (probably related to the bottom of this file)

warnings disable Wfeature_deprecated ; The workarounds for the things warned about do not work
math pri on ; Use conventional maths priority (otherwise is strict left-to-right evaluation)

!printAramSummary = ""
if defined("printRamMsl") || defined("printRamMap") : undef printAramSummary


; The SPC engine data block is written directly via the spc700-inline arch,
; which handles writing the data block header containing the block size and ARAM destination.
; Note that an org statement defines a new data block (i.e. only use org once, at the beginning)

lorom
org $CF8104 ; The actual ROM location the data block is going to be written to

!version = 1

incsrc "ram.asm"

arch spc700-inline
org !p_end_ram

main_metadata:
{
db !version
dw main_engine,\
   main_sharedTrackers,\
   !noteRingLengthTable,\
   !instrumentTable,\
   !sampleTable,\
   !sampleData,\
   !p_extra
}

main_engine:
incsrc "engine.asm"

main_utility:
incsrc "utility.asm"

main_music:
incsrc "music.asm"

incsrc "sound library.asm" ; Contains code that's generic across sound libraries

main_soundLibrary1:
incsrc "sound library 1.asm"

main_soundLibrary2:
incsrc "sound library 2.asm"

main_soundLibrary3:
incsrc "sound library 3.asm"

main_sharedTrackers:
incsrc "shared trackers.asm"

main_eof:

assert main_eof == !noteRingLengthTable, "Need to update ram.asm"

if defined("printAramSummary")
    print "$",hex(!p_end_ram), ": RAM end"
    print "$",hex(main_metadata), ": Metadata"
    print "$",hex(main_engine), ": Engine"
    print "$",hex(main_utility), ": Utility"
    print "$",hex(main_music), ": Music"
    print "$",hex(main_soundLibrary1), ": Sound library 1"
    print "$",hex(main_soundLibrary2), ": Sound library 2"
    print "$",hex(main_soundLibrary3), ": Sound library 3"
    print "$",hex(main_sharedTrackers), ": Shared trackers"
    print "$",hex(main_eof), ": EOF"
    print "$",hex(!noteRingLengthTable), ": Note length table"
    print "$",hex(!instrumentTable), ": Instrument table"
    print "$",hex(!sampleTable), ": Sample table"
    print "$",hex(!sampleData), ": Sample data / trackers / echo buffer"
    print ""
    
    ; These are the options to pass to repoint.py
    print \
        "REPOINT:",\
        " --p_spcEngine=",hex(main_engine),\
        " --p_sharedTrackers=",hex(main_sharedTrackers),\
        " --p_noteLengthTable=",hex(!noteRingLengthTable),\
        " --p_instrumentTable=",hex(!instrumentTable),\
        " --p_sampleTable=",hex(!sampleTable),\
        " --p_sampleData=",hex(!sampleData),\
        " --p_extra=",hex(!p_extra)
endif

padbyte $00 : pad $CFC2EA ; Asar requires a CPU address here. Possibly a bug, if so fix this if the bug gets fixed
warnpc $56E2

; The inline arch writes a terminator data block, which we don't want. The below is reverting that
arch 65816
org $CFC2EA

dw read2($CFC2EA), read2($CFC2EC)

; Write engine pointer to EOF data block's ARAM destination
org $D0E20B
dw main_engine
