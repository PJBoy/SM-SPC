import argparse, os, sys

# Address conversion
snes2hex = lambda address: address >> 1 & 0x3F8000 | address & 0x7FFF
hex2snes = lambda address: address << 1 & 0xFF0000 | address & 0xFFFF | 0x808000

# Format a 24-bit address as $pp:pppp
formatLong = lambda address: f'${address >> 16:02X}:{address & 0xFFFF:04X}'

# Format a non-address value
formatValue = lambda v: f'{v:X}' + ('h' if v >= 0xA else '')

# For the pjlog functions:
org = lambda address: f'{formatLong(address)}             '
indent = '                        '


argparser = argparse.ArgumentParser(description = 'Print Super Metroid music data.')
argparser.add_argument('rom_in',  type = argparse.FileType('rb'),  help = 'Filepath to Super Metroid ROM')
argparser.add_argument('rom_out', type = argparse.FileType('r+b'), help = 'Filepath to Super Metroid ROM')
argparser.add_argument('--p_spcEngine',       type = lambda n: int(n, 0x10), help = 'New SPC engine ARAM pointer')
argparser.add_argument('--p_sharedTrackers',  type = lambda n: int(n, 0x10), help = 'New shared trackers ARAM pointer')
argparser.add_argument('--p_noteLengthTable', type = lambda n: int(n, 0x10), help = 'New note length table ARAM pointer')
argparser.add_argument('--p_instrumentTable', type = lambda n: int(n, 0x10), help = 'New instrument table ARAM pointer')
argparser.add_argument('--p_trackers',        type = lambda n: int(n, 0x10), help = 'New trackers ARAM pointer')
argparser.add_argument('--p_sampleTable',     type = lambda n: int(n, 0x10), help = 'New sample table ARAM pointer')
argparser.add_argument('--p_sampleData',      type = lambda n: int(n, 0x10), help = 'New sample data ARAM pointer')
args = argparser.parse_args()
rom_in = args.rom_in
rom_out = args.rom_out


class AramStream:
    '''
        Initialised with a list of data and a corresponding ARAM pointer,
        provides queue-like access to the data and updates the ARAM pointer accordingly.
    '''

    def __init__(self, p_aram, data):
        self.p_aram = p_aram
        self.data = data

    def peek(self, n):
        if n > len(self.data):
            raise RuntimeError(f'Unable to read {n} bytes from {len(self.data)} byte buffer')

        return self.data[:n]

    def read(self, n):
        ret = self.peek(n)
        del self.data[:n]
        self.p_aram += n
        return ret

    def peekInt(self, n = 1):
        return int.from_bytes(self.peek(n), 'little')

    def readInt(self, n = 1):
        return int.from_bytes(self.read(n), 'little')

    def write(self, data):
        self.data += data
        self.p_aram += len(data)

    def writeInt(self, v, n = 1):
        self.write([*int.to_bytes(v, n, 'little')])

class MusicData:
    '''
        Represents music data given in the APU data block format:
            ssss dddd [xx xx...] (data block 0)
            ssss dddd [xx xx...] (data block 1)
            ...
            0000 aaaa
        Where:
            s = data block size in bytes
            d = destination address
            x = data
            a = entry address. Ignored by SPC engine after first APU transfer

        The data blocks are parsed into:
            SPC engine
            Note length table
            Trackers
            Instrument table
            Sample table
            Sample data

        None of them are required to exist except the sample table, which is needed if there's sample data present.
        It's assumed there's only one of each block.

        TODO: Handle SPC engine patches (mITroid for omitting a key-off)
        TODO: Support user defined ARAM regions for APU block destination addresses, this script doesn't support reading its own output >_>
    '''

    class SpcEngine:
        "Boring class that opaquely holds the data it's given and its destination address"
        def __init__(self, p_blockHeader, data):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram
            self.data = data.data

        def repoint(self, p_aram):
            self.p_aram = p_aram

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            data.write(self.data)

    class NoteLengthTable:
        '''
            8 bytes of note ring lengths
            10h bytes of note volumes

            Every music data in vanilla uses the exact same table.
        '''

        def __init__(self, p_blockHeader, data):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram
            if self.blockSize != 0x18:
                raise RuntimeError("Bad note length table length")

            self.ringLengths = data.read(8)
            self.volumes = data.read(0x10)

        def repoint(self, p_aram):
            self.p_aram = p_aram

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            data.write(self.ringLengths)
            data.write(self.volumes)

        def pjlog(self):
            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'

            ringLengths = ','.join(f'{length:02X}' for length in self.ringLengths)
            volumes = ','.join(f'{volume:02X}' for volume in self.volumes)

            print('; Note length table')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram},')
            print(f'{indent}{ringLengths},')
            print(f'{indent}{volumes}')

    class Trackers:
        '''
            Format:
                 ______________ First tracker pointer
                |     _________ Second tracker pointer
                |    |     ____ Other tracker pointers
                |    |    |
                aaaa bbbb [...]
        '''
        class Tracker:
            '''
                A tracker is a list of two byte entries that are either track set pointers or commands.
                Commands are entries less than 100h:
                    0000: Terminator
                    0080: Disable note processing
                    0081: Enable note processing
                    00tt pppp: Wait max(1, t) tics, then go to p (where t is signed and p is a pointer to somewhere in the commands list)

                E.g. the title sequence:
                    $582C: 5838 ; Track set 0
                    $582E: 5858 ; Track set 1
                    $5830: 5848 ; Track set 2
                    $5832: 00FF,5830 ; Go to $5830 after 1 tic
                    $5836: 0000 ; Terminator

                Track set pointers:
                     ______________________________________ Pointer to track 0
                    |     _________________________________ Pointer to track 1
                    |    |     ____________________________ Pointer to track 2
                    |    |    |     _______________________ Pointer to track 3
                    |    |    |    |     __________________ Pointer to track 4
                    |    |    |    |    |     _____________ Pointer to track 5
                    |    |    |    |    |    |     ________ Pointer to track 6
                    |    |    |    |    |    |    |     ___ Pointer to track 7
                    |    |    |    |    |    |    |    |
                    aaaa bbbb cccc dddd eeee ffff gggg hhhh

                    Where track i is played on voice i.

                In addition to the track sets pointed to by the commands list,
                there are unreferenced track sets to account for (case in point: vanilla title sequence).

                In addition to the tracks pointed to by the track set pointers,
                there are repeated subsections referenced by the tracks themselves (via command EFh),
                and some unreferenced track sections to account for
            '''
            class Track:
                '''
                    A track is a list of one byte entries that are note lengths, notes, a tie, a rest, or commands.
                    A tie is an entry with value C8h (continues to play the previous note for a note length).
                    A rest is an entry with value C9h (plays nothing for a note length).

                    Note lengths:
                    {
                        ll    ; Set note length
                        ll rv ; Set note length, volume and ring length

                        Notes lengths are entries with 1 <= l < 80h and set note length = l tics.
                        If the next byte is less than 80h, then rv is interpreted as a parameter.
                        r is an index into a table of note ring lengths that are fractions out of 100h of the note's length for which the note will ring within
                        v is an index into a table of note volume multipliers that are fractions out of 100h.
                    }

                    Notes:
                    {
                        nn

                        Notes are entries with 80h <= n < C8h.
                        The note octave is (n - 80h) / 12 + 1, the note key is given by the table:
                            C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B

                        where the table is indexed by (n - 80h) % 12.

                        E.g. A4h is middle C (C_4)
                    }

                    Percussion notes:
                    {
                        nn

                        Percussion notes are entries with CAh <= n < E0h.
                        They play C_4 on percussion instrument (n - CAh) where the percussion instruments base index is given by command FAh.
                    }

                    Commands:
                    {
                        E0 ii       ; Select instrument i
                        E1 pp       ; Panning bias = (p & 1Fh) / 14h. If p & 80h, left side phase inversion is enabled. If p & 40h, right side phase inversion is enabled
                        E2 tt bb    ; Dynamic panning over t tics with target panning bias b / 14h
                        E3 dd rr ee ; Static vibrato after d tics at rate r with extent e
                        E4          ; End vibrato
                        E5 vv       ; Music volume multiplier = v / 100h
                        E6 tt vv    ; Dynamic music volume over t tics with target volume multiplier v / 100h
                        E7 tt       ; Music tempo = t / (0x100 * 0.002) tics per second
                        E8 tt TT    ; Dynamic music tempo over
                        E9 tt       ; Set music transpose of t semitones
                        EA tt       ; Set transpose of t semitones
                        EB dd rr ee ; Tremolo after d tics at rate r with extent e
                        EC          ; End tremolo
                        ED vv       ; Volume multiplier = v / 100h
                        EE tt vv    ; Dynamic volume over t tics with target volume multiplier v / 100h
                        EF pppp cc  ; Repeat subsection p, (c - 1) times (TODO: check this...)
                        F0 ll       ; Dynamic vibrato over l tics with target extent 0 (unused)
                        F1 dd ll ee ; Slide out after d tics for l tics by e semitones
                        F2 dd ll ee ; Slide in after d tics for l tics by e semitones  (unused)
                        F3          ; End slide
                        F4 ss       ; Set subtranspose of s / 100h semitones
                        F5 vv ll rr ; Static echo on voices v with echo volume left = l and echo volume right = r
                        F6          ; End echo (unused)
                        F7 dd ff ii ; Set echo parameters: echo delay = d, echo feedback volume = f, echo FIR filter index = i (range 0..3)
                        F8 tt ll rr ; Dynamic echo volume after d tics with target echo volume left = l and target echo volume right = r (unused)
                        F9 dd ll tt ; Pitch slide after d tics over l tics by t semitones
                        FA ii       ; Percussion instruments base index = i
                        FB          ; Skip next byte (unused)
                        FC          ; Skip all new notes (unused)
                        FD          ; Stop sound effects and disable music note processing (unused)
                        FE          ; Resume sound effects and enable music note processing (unused)
                    }
                '''
                class End:
                    def __init__(self, data):
                        data.read(1)

                    def write(self, data):
                        data.writeInt(0)

                    def pjlog(self):
                        print('00')

                class NoteLength:
                    def __init__(self, data):
                        self.noteLength = data.readInt()
                        self.i_volume = None
                        self.i_ringLength = None

                        if data.peekInt() < 0x80:
                            argument = data.readInt()
                            self.i_volume = argument & 0xF
                            self.i_ringLength = argument >> 4

                    def write(self, data):
                        data.writeInt(self.noteLength)
                        if self.i_volume is not None:
                            data.writeInt(self.i_volume | self.i_ringLength << 4)

                    def pjlog(self):
                        data = f'{self.noteLength:02X},'
                        comment = f'Note length = {formatValue(self.noteLength)} tics'
                        if self.i_volume is not None:
                            data += f'{self.i_ringLength:X}{self.i_volume:X},'
                            volume = [0x19, 0x32, 0x4C, 0x65, 0x72, 0x7F, 0x8C, 0x98, 0xA5, 0xB2, 0xBF, 0xCB, 0xD8, 0xE5, 0xF2, 0xFC][self.i_volume]
                            ringLength = [0x32, 0x65, 0x7F, 0x98, 0xB2, 0xCB, 0xE5, 0xFC][self.i_ringLength]
                            comment += f', note volume multiplier = {formatValue(volume)} / 100h, note ring length multiplier = {formatValue(ringLength)} / 100h'

                        print(f'{data:13}; {comment}')

                class Note:
                    def __init__(self, data):
                        self.datum = data.readInt()
                        self.octave = (self.datum - 0x80) // 12 + 1
                        self.note = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'][(self.datum - 0x80) % 12]

                    def write(self, data):
                        data.writeInt(self.datum)

                    def pjlog(self):
                        data = f'{self.datum:02X},'
                        print(f'{data:13}; Note {self.note}_{self.octave}')

                class Tie:
                    def __init__(self, data):
                        data.readInt()

                    def write(self, data):
                        data.writeInt(0xC8)

                    def pjlog(self):
                        data = 'C8,'
                        print(f'{data:13}; Tie')

                class Rest:
                    def __init__(self, data):
                        data.readInt()

                    def write(self, data):
                        data.writeInt(0xC9)

                    def pjlog(self):
                        data = 'C9,'
                        print(f'{data:13}; Rest')

                class PercussionNote:
                    def __init__(self, data):
                        self.note = data.readInt() - 0xCA

                    def write(self, data):
                        data.writeInt(self.note + 0xCA)

                    def pjlog(self):
                        data = f'{self.note + 0xCA:02X},'
                        print(f'{data:13}; Percussion note {formatValue(self.note)}')

                class SelectInstrument:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.instrument = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.instrument)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.instrument:02X},'
                        print(f'{data:13}; Select instrument {formatValue(self.instrument)}')

                class StaticPanning:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        datum = data.readInt()
                        self.panningBias = datum & 0x1F
                        self.inversion = datum >> 6

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.panningBias | self.inversion << 6)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.panningBias | self.inversion << 6:02X},'
                        inversion = ['no', 'right side', 'left side', 'both side'][self.inversion]
                        print(f'{data:13}; Panning bias = {formatValue(self.panningBias)} / 14h with {inversion} phase inversion')

                class DynamicPanning:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.timer = data.readInt()
                        self.bias = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.timer)
                        data.writeInt(self.bias)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.timer:02X},{self.bias:02X},'
                        print(f'{data:13}; Dynamic panning over {formatValue(self.timer)} tics with target panning bias {formatValue(self.bias)} / 14h')

                class StaticVibrato:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.rate = data.readInt()
                        self.extent = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.rate)
                        data.writeInt(self.extent)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.rate:02X},{self.extent:02X},'
                        print(f'{data:13}; Static vibrato after {formatValue(self.delay)} tics at rate {formatValue(self.rate)} with extent {formatValue(self.extent)}')

                class EndVibrato:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; End vibrato')

                class StaticMusicVolume:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.volume = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.volume)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.volume:02X},'
                        print(f'{data:13}; Music volume multiplier = {formatValue(self.volume)} / 100h')

                class DynamicMusicVolume:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.timer = data.readInt()
                        self.volume = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.timer)
                        data.writeInt(self.volume)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.timer:02X},{self.volume:02X},'
                        print(f'{data:13}; Dynamic music volume over {formatValue(self.timer)} tics with target volume multiplier {formatValue(self.volume)} / 100h')

                class StaticMusicTempo:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.tempo = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.tempo)

                    def pjlog(self):
                        ticRate = self.tempo / (0x100 * 0.002)
                        data = f'{self.commandId:02X},{self.tempo:02X},'
                        print(f'{data:13}; Music tempo = {ticRate} tics per second')

                class DynamicMusicTempo:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.timer = data.readInt()
                        self.tempo = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.timer)
                        data.writeInt(self.tempo)

                    def pjlog(self):
                        ticRate = self.tempo / (0x100 * 0.002)
                        data = f'{self.commandId:02X},{self.timer:02X},{self.tempo:02X},'
                        print(f'{data:13}; Dynamic music tempo over {formatValue(self.timer)} tics with target tempo {ticRate} tics per second')

                class MusicTranspose:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.transpose = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.transpose)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.transpose:02X},'
                        print(f'{data:13}; Set music transpose of {formatValue(self.transpose)} semitones')

                class Transpose:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.transpose = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.transpose)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.transpose:02X},'
                        print(f'{data:13}; Set transpose of {formatValue(self.transpose)} semitones')

                class Tremolo:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.rate = data.readInt()
                        self.extent = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.rate)
                        data.writeInt(self.extent)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.rate:02X},{self.extent:02X},'
                        print(f'{data:13}; Tremolo after {formatValue(self.delay)} tics at rate {formatValue(self.rate)} with extent {formatValue(self.extent)}')

                class EndTremolo:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; End tremolo')

                class StaticVolume:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.volume = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.volume)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.volume:02X},'
                        print(f'{data:13}; Volume multiplier = {formatValue(self.volume)} / 100h')

                class DynamicVolume:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.timer = data.readInt()
                        self.volume = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.timer)
                        data.writeInt(self.volume)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.timer:02X},{self.volume:02X},'
                        print(f'{data:13}; Dynamic volume over {formatValue(self.timer)} tics with target volume multiplier {formatValue(self.volume)} / 100h')

                class RepeatSubsection:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.p_subsection = data.readInt(2)
                        self.counter = data.readInt() - 1 # TODO: check

                    def repoint(self, p_subsection):
                        self.p_subsection = p_subsection

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.p_subsection, 2)
                        data.writeInt(self.counter + 1)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.p_subsection:04X},{self.counter + 1:02X},'
                        print(f'{data:13}; Repeat subsection ${self.p_subsection:04X} {formatValue(self.counter)} times')

                class DynamicVibrato:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.length = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.length)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.length:02X},'
                        print(f'{data:13}; Dynamic vibrato over {formatValue(self.length)} tics with target extent 0')

                class SlideOut:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.length = data.readInt()
                        self.extent = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.length)
                        data.writeInt(self.extent)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.length:02X},{self.extent:02X},'
                        print(f'{data:13}; Slide out after {formatValue(self.delay)} tics for {formatValue(self.length)} tics by {formatValue(self.extent)} semitones')

                class SlideIn:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.length = data.readInt()
                        self.extent = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.length)
                        data.writeInt(self.extent)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.length:02X},{self.extent:02X},'
                        print(f'{data:13}; Slide in after {formatValue(self.delay)} tics for {formatValue(self.length)} tics by {formatValue(self.extent)} semitones')

                class EndSlide:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; End slide')

                class Subtranspose:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.subtranspose = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.subtranspose)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.subtranspose:02X},'
                        print(f'{data:13}; Set subtranspose of {formatValue(self.subtranspose)} / 100h semitones')

                class StaticEcho:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.enable = data.readInt()
                        self.left = data.readInt()
                        self.right = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.enable)
                        data.writeInt(self.left)
                        data.writeInt(self.right)

                    def pjlog(self):
                        voices = '/'.join(f'{i}' for i in range(8) if self.enable & 1 << i) or '(none)'
                        data = f'{self.commandId:02X},{self.enable:02X},{self.left:02X},{self.right:02X},'
                        print(f'{data:13}; Static echo on voices {voices} with echo volume left = {formatValue(self.left)} and echo volume right = {formatValue(self.right)}')

                class EndEcho:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; End echo')

                class EchoParameters:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.feedback = data.readInt()
                        self.i_fir = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.feedback)
                        data.writeInt(self.i_fir)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.feedback:02X},{self.i_fir:02X},'
                        print(f'{data:13}; Set echo parameters: echo delay = {formatValue(self.delay)}, echo feedback volume = {formatValue(self.feedback)}, echo FIR filter index = {formatValue(self.i_fir)}')

                class DynamicEchoVolume:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.timer = data.readInt()
                        self.left = data.readInt()
                        self.right = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.timer)
                        data.writeInt(self.left)
                        data.writeInt(self.right)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.timer:02X},{self.left:02X},{self.right:02X},'
                        print(f'{data:13}; Dynamic echo volume after {formatValue(self.delay)} tics with target echo volume left = {formatValue(self.left)} and target echo volume right = {formatValue(self.right)}')

                class PitchSlide:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.delay = data.readInt()
                        self.length = data.readInt()
                        self.target = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.delay)
                        data.writeInt(self.length)
                        data.writeInt(self.target)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.delay:02X},{self.length:02X},{self.target:02X},'
                        print(f'{data:13}; Pitch slide after {formatValue(self.delay)} tics over {formatValue(self.length)} tics by {formatValue(self.target)} semitones')

                class SetPercussionInstrumentsIndex:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        self.i_instruments = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)
                        data.writeInt(self.i_instruments)

                    def pjlog(self):
                        data = f'{self.commandId:02X},{self.i_instruments:02X},'
                        print(f'{data:13}; Percussion instruments base index = {formatValue(self.i_instruments)}')

                class SkipByte:
                    def __init__(self, data):
                        self.commandId = data.readInt()
                        # self.parameter = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; Skip byte')

                class SkipAllNewNotes:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; Skip all new notes')

                class StopSoundEffectsAndDisableMusicNoteProcessing:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; Stop sound effects and disable music note processing')

                class ResumeSoundEffectsAndEnableMusicNoteProcessing:
                    def __init__(self, data):
                        self.commandId = data.readInt()

                    def write(self, data):
                        data.writeInt(self.commandId)

                    def pjlog(self):
                        data = f'{self.commandId:02X},'
                        print(f'{data:13}; Resume sound effects and disable music note processing')

                commandClasses = [
                    SelectInstrument,
                    StaticPanning,
                    DynamicPanning,
                    StaticVibrato,
                    EndVibrato,
                    StaticMusicVolume,
                    DynamicMusicVolume,
                    StaticMusicTempo,
                    DynamicMusicTempo,
                    MusicTranspose,
                    Transpose,
                    Tremolo,
                    EndTremolo,
                    StaticVolume,
                    DynamicVolume,
                    RepeatSubsection,
                    DynamicVibrato,
                    SlideOut,
                    SlideIn,
                    EndSlide,
                    Subtranspose,
                    StaticEcho,
                    EndEcho,
                    EchoParameters,
                    DynamicEchoVolume,
                    PitchSlide,
                    SetPercussionInstrumentsIndex,
                    SkipByte,
                    SkipAllNewNotes,
                    StopSoundEffectsAndDisableMusicNoteProcessing,
                    ResumeSoundEffectsAndEnableMusicNoteProcessing
                ]

                def __init__(self, i_track, p_trackSet, i_tracker, isRepeatedSubsection, isUnusedSection, p_snes, data):
                    self.i_track = i_track
                    self.p_trackSet = p_trackSet
                    self.i_tracker = i_tracker
                    self.isRepeatedSubsection = isRepeatedSubsection
                    self.isUnusedSection = isUnusedSection
                    self.p_snes = p_snes
                    self.p_aram = data.p_aram

                    self.commands = []
                    while data.data:
                        commandId = data.peekInt()
                        if commandId == 0:
                            self.commands += [self.End(data)]
                            break
                        elif commandId < 0x80:
                            self.commands += [self.NoteLength(data)]
                        elif commandId < 0xC8:
                            self.commands += [self.Note(data)]
                        elif commandId == 0xC8:
                            self.commands += [self.Tie(data)]
                        elif commandId == 0xC9:
                            self.commands += [self.Rest(data)]
                        elif commandId < 0xE0:
                            self.commands += [self.PercussionNote(data)]
                        else:
                            self.commands += [self.commandClasses[commandId - 0xE0](data)]

                    self.subsectionPointers = {command.p_subsection for command in self.commands if isinstance(command, self.RepeatSubsection)}

                def repoint(self, p_aram):
                    diff = p_aram - self.p_aram
                    self.p_aram += diff

                    self.p_trackSet += diff
                    for command in self.commands:
                        if isinstance(command, self.RepeatSubsection):
                            command.repoint(command.p_subsection + diff)

                def write(self, data):
                    for command in self.commands:
                        command.write(data)

                def pjlog(self):
                    def org_aram(address):
                        snes_address = hex2snes(address - self.p_aram + snes2hex(self.p_snes))
                        return f'${snes_address >> 16:02X}:{snes_address & 0xFFFF:04X}/${address:04X}       '

                    if self.isRepeatedSubsection:
                        print(f'; Repeated subsection - tracker {self.i_tracker}, track set ${self.p_trackSet:04X}, track {self.i_track}')
                    elif self.isUnusedSection:
                        print('; Unused section')
                    else:
                        print(f'; Tracker {self.i_tracker}, track set ${self.p_trackSet:04X}, track {self.i_track} commands')

                    print('{')
                    print(f'{org_aram(self.p_aram)}dx ', end = '')
                    isFirst = True
                    for command in self.commands:
                        if isFirst:
                            isFirst = False
                        else:
                            print(indent, end = '')

                        command.pjlog()

                    print('}')

            def __init__(self, i_tracker, p_snes, data):
                self.p_snes = p_snes
                self.i_tracker = i_tracker
                self.p_aram = data.p_aram

                # Process tracker commands
                self.commands = []
                self.destinationPointers = {self.p_aram}
                trackSetPointers = set()
                while True:
                    p_aram = data.p_aram
                    datum = data.readInt(2)
                    if datum >= 0x100:
                        # Track set pointer
                        self.commands += [[p_aram, [datum]]]
                        trackSetPointers |= {datum}
                    elif datum in (0, 0x80, 0x81):
                        # Command
                        self.commands += [[p_aram, [datum]]]
                        if datum == 0:
                            break
                    else:
                        # Timer + destination
                        p_destination = data.readInt(2)
                        self.commands += [[p_aram, [datum, p_destination]]]
                        self.destinationPointers |= {p_destination}

                # Read track sets
                self.trackSets = []
                while True:
                    previousTrackPointers = [p_track for [_, trackPointers] in self.trackSets for p_track in trackPointers if p_track]
                    if previousTrackPointers and data.p_aram >= min(previousTrackPointers):
                        break

                    p_trackSet = data.p_aram
                    trackPointers = [data.readInt(2) for _ in range(8)]
                    self.trackSets += [[p_trackSet, trackPointers]]

                # Process tracks
                trackPointersQueue = {}
                for [p_trackSet, trackPointers] in self.trackSets:
                    for (i_track, p_track) in enumerate(trackPointers):
                        if p_track != 0:
                            trackPointersQueue |= {p_track: (i_track, p_trackSet, i_tracker, False, False)}

                self.tracks = []
                while trackPointersQueue:
                    p_track = min(trackPointersQueue.keys())
                    (i_track, p_trackSet, i_tracker, isRepeatedSubsection, isUnusedSection) = trackPointersQueue[p_track]
                    del trackPointersQueue[p_track]

                    if p_track != data.p_aram:
                        raise RuntimeError(f'Unexpected track data: actual ${p_track:X} != expected ${data.p_aram:X}')

                    if trackPointersQueue:
                        p_end_track = min(trackPointersQueue)
                    else:
                        p_end_track = p_track + len(data.data)

                    trackData = AramStream(p_track, data.read(p_end_track - p_track))

                    track = self.Track(i_track, p_trackSet, i_tracker, isRepeatedSubsection, isUnusedSection, p_track - self.p_aram + self.p_snes, trackData)
                    self.tracks += [track]
                    trackPointersQueue |= {p_subsection: (i_track, p_trackSet, i_tracker, True, False) for p_subsection in track.subsectionPointers}
                    if trackData.data:
                        self.tracks += [self.Track(0, 0, 0, False, True, trackData.p_aram - self.p_aram + self.p_snes, trackData)]

                if data.data:
                    raise RuntimeError(f'Leftover tracker data: ${data.p_aram:X}')

            def repoint(self, p_aram):
                diff = p_aram - self.p_aram
                self.p_aram += diff

                for (i_command, [_, commandData]) in enumerate(self.commands):
                    self.commands[i_command][0] += diff
                    if commandData[0] >= 0x100:
                        # Track set pointer
                        commandData[0] += diff
                    elif commandData[0] not in (0, 0x80, 0x81):
                        # Timer + destination
                        commandData[1] += diff

                for (i_trackSet, [_, trackPointers]) in enumerate(self.trackSets):
                    self.trackSets[i_trackSet][0] += diff
                    for i in range(len(trackPointers)):
                        if trackPointers[i] != 0:
                            trackPointers[i] += diff

                self.destinationPointers = {p + diff for p in self.destinationPointers}

                for track in self.tracks:
                    track.repoint(track.p_aram + diff)

            def write(self, data):
                for [_, commandData] in self.commands:
                    for datum in commandData:
                        data.writeInt(datum, 2)

                for [_, trackPointers] in self.trackSets:
                    for p_track in trackPointers:
                        data.writeInt(p_track, 2)

                for track in self.tracks:
                    track.write(data)

            def pjlog(self):
                def org_aram(address):
                    snes_address = hex2snes(address - self.p_aram + snes2hex(self.p_snes))
                    return f'${snes_address >> 16:02X}:{snes_address & 0xFFFF:04X}/${address:04X}       '

                commandListFragments = []
                commandListFragment = []
                for [p_aram, commandData] in self.commands:
                    if p_aram in self.destinationPointers and commandListFragment:
                        commandListFragments += [f',\n{indent}'.join(commandListFragment)]
                        commandListFragment = []

                    commandListFragment += [','.join(f'{datum:04X}' for datum in commandData)]

                if commandListFragment:
                    commandListFragments += [f',\n{indent}'.join(commandListFragment)]

                trackSets = [(p_trackSet, ', '.join(f'{p_track:04X}' for p_track in trackPointers)) for [p_trackSet, trackPointers] in self.trackSets]

                print(f'; Tracker {self.i_tracker} commands')
                for (p_aram, commandListFragment) in zip(sorted(self.destinationPointers), commandListFragments):
                    print(f'{org_aram(p_aram)}dw {commandListFragment}')

                print()
                print(f'; Tracker {self.i_tracker} track pointers')
                for (p_trackSet, trackPointers) in trackSets:
                    print(f'{org_aram(p_trackSet)}dw {trackPointers}')

                for track in self.tracks:
                    print()
                    track.pjlog()

        def __init__(self, p_blockHeader, data):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram

            # Read tracker pointers
            self.trackerPointers = []
            while data.p_aram not in self.trackerPointers:
                self.trackerPointers += [data.readInt(2)]

            trackerPointers_sorted = sorted(self.trackerPointers + [self.p_aram + self.blockSize])
            trackerEndPointers = {trackerPointers_sorted[i]: trackerPointers_sorted[i + 1] for i in range(len(trackerPointers_sorted) - 1)}

            # Process trackers
            self.trackers = []
            for (i_tracker, p_tracker) in enumerate(self.trackerPointers):
                if p_tracker < self.p_aram:
                    # Pointer to shared tracker (music track 1..4)
                    # Or tracker commands overlap (doesn't happen in vanilla(?))
                    continue

                if p_tracker != data.p_aram:
                    raise RuntimeError("Bad trackers")

                p_end_tracker = trackerEndPointers[p_tracker]
                trackerSize = p_end_tracker - p_tracker
                self.trackers += [self.Tracker(i_tracker, p_blockHeader + 4 + p_tracker - self.p_aram, AramStream(data.p_aram, data.read(trackerSize)))]

        def repoint(self, p_aram):
            diff = p_aram - self.p_aram
            self.p_aram += diff

            for i in range(len(self.trackerPointers)):
                if self.trackerPointers[i] >= self.p_aram:
                    self.trackerPointers[i] += diff

            for tracker in self.trackers:
                tracker.repoint(tracker.p_aram + diff)

        def repointSharedTrackers(self, p_aram):
            diff = p_aram - 0x530E
            for i in range(len(self.trackerPointers)):
                if self.trackerPointers[i] < self.p_aram:
                    self.trackerPointers[i] += diff

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)

            for p_tracker in self.trackerPointers:
                data.writeInt(p_tracker, 2)

            for tracker in self.trackers:
                tracker.write(data)

        def pjlog(self):
            def org_aram(address):
                snes_address = hex2snes(address - self.p_aram + snes2hex(self.p_blockHeader) + 4)
                return f'${snes_address >> 16:02X}:{snes_address & 0xFFFF:04X}/${address:04X}       '

            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'

            trackerPointers = ', '.join(f'{p_tracker:04X}' for p_tracker in self.trackerPointers)

            print('; Trackers')
            print('{')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram},')
            print()
            print('; Tracker pointers')
            print(f'{indent}{trackerPointers}')
            print()
            for tracker in self.trackers:
                tracker.pjlog()
                print()

            print('}')

    class InstrumentTable:
        '''
            Format:
                ii aaaa gg pp pp
            Where:
                i = sample table index. If i & 80h: enable noise with noise frequency = i & 1Fh with sample table index = 0 instead
                a = ADSR settings
                g = gain settings
                p = instrument pitch multiplier. 16-bit *big* endian

            Lazy implementation
        '''
        def __init__(self, p_blockHeader, data):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram

            n_instruments = self.blockSize // 6
            if self.blockSize != n_instruments * 6:
                raise RuntimeError("Bad instrument table length")

            self.instruments = [[data.readInt(), data.readInt(2), data.readInt(), data.readInt(), data.readInt()] for i in range(n_instruments)]

        def repoint(self, p_aram):
            self.p_aram = p_aram

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            for (i_sampleTable, adsr, gain, pitchMultiplier_high, pitchMultiplier_low) in self.instruments:
                data.writeInt(i_sampleTable)
                data.writeInt(adsr, 2)
                data.writeInt(gain)
                data.writeInt(pitchMultiplier_high)
                data.writeInt(pitchMultiplier_low)

        def pjlog(self):
            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'

            instrumentEntries = [f'{instrument[0]:02X},{instrument[1]:04X},{instrument[2]:02X},{instrument[3]:02X},{instrument[4]:02X}' for instrument in self.instruments]
            instrumentRows = [', '.join(instrumentEntries[i*4 : (i+1)*4]) for i in range((len(instrumentEntries) + 3) // 4)]
            instruments = f',\n{indent}'.join(instrumentRows)

            print('; Instrument table')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram},')
            print(f'{indent}{instruments}')

    class SampleTable:
        '''
            Sample table contains up to 100h entries of four bytes:
                ssss llll
            Where:
                s = start address (used when voice is keyed on)
                l = loop address (used when end of sample data is reached)

            Lazy implementation
        '''
        def __init__(self, p_blockHeader, data):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram

            n_samples = self.blockSize // 4
            if self.blockSize != n_samples * 4:
                raise RuntimeError("Bad sample table length")

            self.samples = [[data.readInt(2), data.readInt(2)] for i in range(n_samples)]

        def repoint(self, p_aram):
            diff = p_aram - self.p_aram
            self.p_aram += diff
            for i in range(len(self.samples)):
                if self.samples[i][0] == 0xFFFF:
                    continue

                self.samples[i][0] += diff
                self.samples[i][1] += diff

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            for (p_start, p_loop) in self.samples:
                data.writeInt(p_start, 2)
                data.writeInt(p_loop, 2)

        def pjlog(self):
            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'

            sampleEntries = [f'{sample[0]:04X},{sample[1]:04X}' for sample in self.samples]
            sampleRows = [', '.join(sampleEntries[i*8 : (i+1)*8]) for i in range((len(sampleEntries) + 7) // 8)]
            samples = f',\n{indent}'.join(sampleRows)

            print('; Sample table')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram},')
            print(f'{indent}{samples}')

    class SampleData:
        '''
            Sample data is written in 9 byte blocks, a header byte followed by 8 bytes of 4-bit signed samples (high nybble first).
            Header byte has the format:
                aaaaiill
                a: Amplifier amount. The sample is shifted left by s - 1 into a 15-bit sample
                i: Interpolation mode
                {
                    0: Output sample as is
                    1: Output sample + p * 15/16
                    2: Output sample + p * 61/32 - P * 15/16
                    3: Output sample + p * 115/64 - P * 13/16

                    Where p is the previous sample and P is the sample before
                }
                l: Loop mode
                {
                    0/2: Continue to next sample data block
                    1: Loop and mute (jump to loop address from sample table, set voice end flag ($7C), release, envelope = 0)
                    3: Loop (jump to loop address from sample table, set voice end flag ($7C))
                }

            This class doesn't decode the BRR data, but it does load the data into a list of 9-byte blocks,
            separating these lists into sections according to pointers from the sample table or BRR terminators.

            In vanilla, the last sample is always followed by some FF bytes, so this class has to account for that
        '''
        def __init__(self, p_blockHeader, data, sampleTable):
            self.p_blockHeader = p_blockHeader
            self.blockSize = len(data.data)
            self.p_aram = data.p_aram

            sampleTablePointers = sorted(set(sample[i] for i in range(2) for sample in sampleTable.samples if sample[i] != 0xFFFF) | {self.p_aram + self.blockSize})
            if self.p_aram != sampleTablePointers[0]:
                raise RuntimeError(f"Weird sample data - doesn't begin where the sample table says: {self.p_aram:X} != {sampleTablePointers[0]:X}")

            self.sampleSections = []
            i_table = 0
            while data.p_aram != self.p_aram + self.blockSize:
                p_aram_section = data.p_aram
                sampleSection = []
                while True:
                    sampleBlock = data.read(min(len(data.data), 9))
                    sampleSection += [sampleBlock]

                    if data.p_aram == sampleTablePointers[i_table + 1]:
                        i_table += 1
                        break

                    if len(sampleBlock) < 9 or sampleBlock[0] & 1:
                        break

                self.sampleSections += [[p_aram_section, sampleSection]]

        def repoint(self, p_aram):
            diff = p_aram - self.p_aram
            self.p_aram += diff
            for i in range(len(self.sampleSections)):
                self.sampleSections[i][0] += diff

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            for (_, sampleSection) in self.sampleSections:
                for sampleBlock in sampleSection:
                    data.write(sampleBlock)

        def pjlog(self):
            def org_aram(address):
                snes_address = hex2snes(address - self.p_aram + snes2hex(self.p_blockHeader) + 4)
                return f'${snes_address >> 16:02X}:{snes_address & 0xFFFF:04X}/${address:04X}       '

            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'

            print('; Sample data')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram}')
            for (p_aram_section, sampleSection) in self.sampleSections:
                sampleEntries = [','.join(f'{s:02X}' for s in sampleBlock) for sampleBlock in sampleSection]
                sampleRow = ', '.join(sampleEntries)
                print(f'{org_aram(p_aram_section)}db {sampleRow}')

    def __init__(self, address, name):
        self.address = address
        self.name = name

        self.spcEngine       = None # $1500
        self.noteLengthTable = None # $5800
        self.trackers        = None # $5820/28
        self.instrumentTable = None # $6C00/90
        self.sampleTable     = None # $6D00/60
        self.sampleData      = None # $6E00+

        dataBlocks = []
        rom_in.seek(address)
        while True:
            p_blockHeader = hex2snes(rom_in.tell())
            blockSize = int.from_bytes(rom_in.read(2), 'little')
            p_aram = int.from_bytes(rom_in.read(2), 'little')
            #print(f'Found SPC block {formatLong(p_blockHeader)}: ({formatValue(blockSize)}, ${p_aram:02X})')
            if blockSize == 0:
                break

            data = AramStream(p_aram, [int.from_bytes(rom_in.read(1), 'little') for _ in range(blockSize)])
            dataBlocks += [(p_blockHeader, data)]

        self.p_eof = hex2snes(rom_in.tell() - 4)

        def init_spcEngine(p_blockHeader, data):
            self.spcEngine = MusicData.SpcEngine(p_blockHeader, data)

        def init_noteLengthTable(p_blockHeader, data):
            self.noteLengthTable = MusicData.NoteLengthTable(p_blockHeader, data)

        def init_trackers(p_blockHeader, data):
            self.trackers = MusicData.Trackers(p_blockHeader, data)

        def init_instrumentTable(p_blockHeader, data):
            self.instrumentTable = MusicData.InstrumentTable(p_blockHeader, data)

        def init_sampleTable(p_blockHeader, data):
            self.sampleTable = MusicData.SampleTable(p_blockHeader, data)

        def init_sampleData(p_blockHeader, data):
            if self.sampleTable is None:
                raise RuntimeError("Sample data with no sample table")

            self.sampleData = MusicData.SampleData(p_blockHeader, data, self.sampleTable)

        aramRegions = (
            (0,      0x5800,  init_spcEngine),
            (0x5800, 0x5820,  init_noteLengthTable),
            (0x5820, 0x6C00,  init_trackers),
            (0x6C00, 0x6D00,  init_instrumentTable),
            (0x6D00, 0x6E00,  init_sampleTable),
            (0x6E00, 0x10000, init_sampleData) # Depends on sample table
        )

        for (p_aram_begin, p_aram_end, init) in aramRegions:
            for (p_blockHeader, data) in dataBlocks:
                if p_aram_begin <= data.p_aram < p_aram_end:
                    init(p_blockHeader, data)

    def repoint(self):
        if self.spcEngine is not None:
            self.spcEngine.p_aram = args.p_spcEngine
            self.trackers.repointSharedTrackers(args.p_sharedTrackers)

        if self.noteLengthTable is not None:
            self.noteLengthTable.repoint(self.noteLengthTable.p_aram + args.p_noteLengthTable - 0x5800)

        if self.trackers is not None:
            self.trackers.repoint(self.trackers.p_aram + args.p_trackers - 0x5820)

        if self.instrumentTable is not None:
            self.instrumentTable.repoint(self.instrumentTable.p_aram + args.p_instrumentTable - 0x6C00)

        if self.sampleTable is not None:
            self.sampleTable.repoint(self.sampleTable.p_aram + args.p_sampleTable - 0x6D00)

        if self.sampleData is not None:
            self.sampleData.repoint(self.sampleData.p_aram + args.p_sampleData - 0x6E00)

    def write(self, p_rom):
        data = AramStream(0, [])

        if self.spcEngine is not None:
            self.spcEngine.write(data)

        if self.instrumentTable is not None:
            self.instrumentTable.write(data)

        if self.noteLengthTable is not None:
            self.noteLengthTable.write(data)

        if self.trackers is not None:
            self.trackers.write(data)

        if self.sampleTable is not None:
            self.sampleTable.write(data)

        if self.sampleData is not None:
            self.sampleData.write(data)

        # SPC data terminator: 0000 dddd where d is the jump target for the SPC engine specifically and ignored otherwise
        data.writeInt(0, 2)
        if self.spcEngine is not None:
            data.writeInt(self.spcEngine.p_aram, 2)
        else:
            data.writeInt(0x1500, 2)

        rom_out.seek(p_rom)
        rom_out.write(bytes(data.data))

    def pjlog(self):
        print(f';;; {formatLong(hex2snes(self.address))}: {self.name} ;;;')
        print('{')
        if self.instrumentTable is not None:
            self.instrumentTable.pjlog()
            print()

        if self.noteLengthTable is not None:
            self.noteLengthTable.pjlog()
            print()

        if self.trackers is not None:
            self.trackers.pjlog()
            print()

        if self.sampleTable is not None:
            self.sampleTable.pjlog()
            print()

        if self.sampleData is not None:
            self.sampleData.pjlog()
            print()

        print('; EOF')
        print(f'{org(self.p_eof)}dw 0000, 1500') # $1500 is potentially inaccurate
        print('}')



music = [
    (0xCF_8000, 'SPC engine'),
    (0xD0_E20D, 'Title sequence'),
    (0xD1_B62A, 'Empty Crateria'),
    (0xD2_88CA, 'Lower Crateria'),
    (0xD2_D9B6, 'Upper Crateria'),
    (0xD3_933C, 'Green Brinstar'),
    (0xD3_E812, 'Red Brinstar'),
    (0xD4_B86C, 'Upper Norfair'),
    (0xD4_F420, 'Lower Norfair'),
    (0xD5_C844, 'Maridia'),
    (0xD6_98B7, 'Tourian'),
    (0xD6_EF9D, 'Mother Brain'),
    (0xD7_BF73, 'Boss fight 1'),
    (0xD8_99B2, 'Boss fight 2'),
    (0xD8_EA8B, 'Miniboss fight'),
    (0xD9_B67B, 'Ceres'),
    (0xD9_F5DD, 'Wrecked Ship'),
    (0xDA_B650, 'Zebes boom'),
    (0xDA_D63B, 'Intro'),
    (0xDB_A40F, 'Death'),
    (0xDB_DF4F, 'Credits'),
    (0xDC_AF6C, '"The last Metroid is in captivity"'),
    (0xDC_FAC7, '"The galaxy is at peace"'),
    (0xDD_B104, 'Shitroid (same as boss fight 2)'),
    (0xDE_81C1, 'Samus theme (same as upper Crateria)')
]

#music = [
#    (0xDF_8005, 'Unused. Boss fight 2 / Shitroid - alternate'),
#    (0xDF_8513, 'Unused. Upper Crateria / Samus theme - higher pitched version')
#]

for (p_musicData, musicName) in music:
    musicData = MusicData(snes2hex(p_musicData), musicName)
    musicData.repoint()
    musicData.write(snes2hex(p_musicData))
