SPC engine modification. Frees up just under 4kb of ARAM, which can be used for any of: sample data, tracker data, or echo buffer (each echo frames are 2kb each).
ARAM is rearranged so that sample data, tracker data, and echo buffer all use up the same pool of memory; so one can e.g. cut down on sample data to get more echo buffer space.

Run `asar --fix-checksum=off main.asm SM.smc` to patch a ROM to have the engine mod, the main engine NSPC is expected to be at its vanilla location $CF:8104.

As the modified engine uses a different ARAM layout, any NSPCs used with it need to be written accordingly.
In vanilla, the SPC data blocks are:
```
_ARAM_|___Description____
$1500 | SPC engine
$5800 | Note length table
$5820 | Trackers
$6C00 | Instrument table
$6D00 | Sample table
$6E00 | Sample data
```

In the engine mod (these ARAM addresses are just examples, read SPC engine metadata for real addresses):
```
_ARAM_|___Description____
$E0   | Extra (*)
$44D  | SPC engine
$3899 | Note length table
$38B1 | Instrument table
$3A00 | Sample table
$3B00 | Sample data / trackers
```

(*) Extra is a 3 byte block:
* A two-byte ARAM address of the trackers within the "sample data / trackers" region
* A one byte flag specifying late key-off, corresponding to mITroid's "disable key-off between patterns" patch

For the purposes of tooling, the first 15 bytes of the SPC engine are metadata (SPC engine block can be identified by looking for the SPC data block whose ARAM destination is also the terminator data block's destination - 0xF).
* 0x0: One byte version number
* Two byte pointers to:
** 0x1: SPC engine (entry point, metadata address + 0xF)
** 0x3: Shared trackers (part of the SPC engine)
** 0x5: Note length table
** 0x7: Instrument table
** 0x9: Sample table
** 0xB: Sample data / trackers
** 0xD: Extra

`repoint.py` is included to repoint vanilla NSPCs or mITroid generated NSPCs.

After patching a vanilla ROM with the ASM via asar, run:
* `python repoint.py rom SM.smc SM_repointed.smc` (arbitrary filepaths)

To repoint an NSPC file, run either:
* `python repoint.oy nspc music.nspc music_repointed.nspc --p_spcEngine=44D --p_sharedTrackers=34C5 --p_noteLengthTable=3899 --p_instrumentTable=38B1 --p_sampleTable=3A00 --p_sampleData=3B00 --p_extra=E0`
** Where all the pointers are reported by asar when assembling the engine mod
* `python repoint.oy nspc music.nspc music_repointed.nspc --rom=SM.smc`
** Where metadata is extracted from `--rom` argument (a patched ROM)

Version history:
* 1. Initial release (since introducing versioning)
