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


argparser = argparse.ArgumentParser(description = 'Repoint Super Metroid music data.')

subparsers = argparser.add_subparsers(dest = 'file_type', help='sub-command help')
parser_a = subparsers.add_parser('rom', help='a help')
parser_a.add_argument('rom_in',  type = argparse.FileType('rb'),  help = 'Filepath to input ROM')
parser_a.add_argument('rom_out', type = argparse.FileType('r+b'), help = 'Filepath to output ROM')
parser_b = subparsers.add_parser('nspc', help='a help')
parser_b.add_argument('rom_in',  type = argparse.FileType('rb'), help = 'Filepath to input NSPC')
parser_b.add_argument('rom_out', type = argparse.FileType('wb'), help = 'Filepath to output NSPC')
parser_b = subparsers.add_parser('nspctest', help='a help')
parser_b.add_argument('rom_in',  type = argparse.FileType('rb'), help = 'Filepath to input NSPC')
parser_b.add_argument('rom_out', type = argparse.FileType('r+b'), help = 'Filepath to output ROM')

argparser.add_argument('--p_spcEngine',       type = lambda n: int(n, 0x10), default = 0x43E,  help = 'New SPC engine ARAM pointer')
argparser.add_argument('--p_sharedTrackers',  type = lambda n: int(n, 0x10), default = 0x34AE, help = 'New shared trackers ARAM pointer')
argparser.add_argument('--p_noteLengthTable', type = lambda n: int(n, 0x10), default = 0x3882, help = 'New note length table ARAM pointer')
argparser.add_argument('--p_instrumentTable', type = lambda n: int(n, 0x10), default = 0x389A, help = 'New instrument table ARAM pointer')
argparser.add_argument('--p_sampleTable',     type = lambda n: int(n, 0x10), default = 0x3A00, help = 'New sample table ARAM pointer')
argparser.add_argument('--p_sampleData',      type = lambda n: int(n, 0x10), default = 0x3B00, help = 'New sample data ARAM pointer')
argparser.add_argument('--p_p_trackers',      type = lambda n: int(n, 0x10), default = 0x47,   help = 'Pointer to write trackers pointer to')

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
            raise RuntimeError(f'Unable to read {n} bytes from {len(self.data)} byte buffer (p_aram = ${self.p_aram:04X})')

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
            self.data = data.read(self.blockSize)

        def repoint(self, p_aram, size):
            self.p_aram = p_aram
            self.blockSize = size
            self.data = self.data[:size]

        def write(self, data):
            data.writeInt(self.blockSize, 2)
            data.writeInt(self.p_aram, 2)
            data.write(self.data)

        def pjlog(self):
            blockSize = f'{self.blockSize:04X}'
            p_aram = f'{self.p_aram:04X}'
            
            print('; Main SPC engine')
            print(f'{org(self.p_blockHeader)}dw {blockSize}, {p_aram}, ...')

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
                        print(f'{data:13}; Dynamic echo volume after {formatValue(self.timer)} tics with target echo volume left = {formatValue(self.left)} and target echo volume right = {formatValue(self.right)}')

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
                
                def size(self):
                    data = AramStream(0, [])
                    self.write(data)
                    return data.p_aram
            
            class Command:
                type_trackSetPointer = 0
                type_command = 1
                type_goto = 2
                
                def __init__(self, data):
                    self.p_aram = data.p_aram
                    
                    datum = data.readInt(2)
                    if datum >= 0x100:
                        # Track set pointer
                        self.type = self.type_trackSetPointer
                        self.p_trackSet = datum
                    elif datum in (0, 0x80, 0x81):
                        # Command
                        self.type = self.type_command
                        self.command = datum
                    else:
                        # Timer + destination
                        self.type = self.type_goto
                        self.timer = datum
                        self.p_destination = data.readInt(2)
                
                def write(self, data):
                    if self.type == self.type_trackSetPointer:
                        data.writeInt(self.p_trackSet, 2)
                    elif self.type == self.type_command:
                        data.writeInt(self.command, 2)
                    else: # self.type == self.type_goto:
                        data.writeInt(self.timer, 2)
                        data.writeInt(self.p_destination, 2)
                
                def size(self):
                    if self.type == self.type_goto:
                        return 4
                    
                    return 2
            
            '''
                p_snes    -> int ; Pointer to tracker data in SNES ROM (used for pjlog)
                p_aram    -> int ; Pointer to tracker data in ARAM (used for pjlog)
                i_tracker -> int ; Index of tracker in trackers list (used for pjlog)
                
                commands         -> [Command, ...]          ; List of tracker commands
                trackSetPointers -> {int, ...}              ; Set of track set pointers (can point outside of first data block)
                trackSets        -> [[int, [int] * 8], ...] ; List of track pointers grouped by track set pointer
                tracks           -> [Track, ...]            ; List of tracks (including repeated subsections and unused tracks)
            '''
            
            def _processTrackerCommands(self, data):
                'Read commands until zero terminator. Also gather the set of track set pointers'
                
                self.commands = []
                trackSetPointers = set()
                while data.p_aram not in trackSetPointers:
                    command = self.Command(data)
                    self.commands += [command]
                    if command.type == self.Command.type_command and command.command == 0:
                        break
                    elif command.type == self.Command.type_trackSetPointer:
                        trackSetPointers |= {command.p_trackSet}

                # Recording this so we can link up trackers from other APU data blocks
                self.trackSetPointers = trackSetPointers
            
            def _readTrackSets(self, data):
                '''
                    Read track sets.
                    This function just reads track sets from `data`, it doesn't synchronise with `self.trackSetPointers` in any way.
                '''
            
                trackSets = []
                while True:
                    # There's no size or terminator for track sets,
                    # so we just keep reading track sets until we fall into track data
                    previousTrackPointers = [pointer for [_, trackPointers] in trackSets for pointer in trackPointers if pointer]
                    if previousTrackPointers and data.p_aram >= min(previousTrackPointers):
                        break

                    p_trackSet = data.p_aram
                    trackPointers = [data.readInt(2) for _ in range(8)]
                    trackSets += [[p_trackSet, trackPointers]]
                
                return trackSets
            
            def _processTracks(self, data, trackSets, p_nextTrackSet):
                'Process tracks'
                
                # Gather initial set of tracks to process from the track sets, record their metadata for self.Track's ctor
                trackPointersQueue = {}
                for [p_trackSet, trackPointers] in trackSets:
                    for (i_track, trackPointer) in enumerate(trackPointers):
                        if trackPointer:
                            trackPointersQueue |= {trackPointer: (i_track, p_trackSet, self.i_tracker, False)}
                
                tracks = []
                while trackPointersQueue:
                    trackPointer = min(trackPointersQueue.keys())
                    (i_track, p_trackSet, i_tracker, isRepeatedSubsection) = trackPointersQueue[trackPointer]
                    del trackPointersQueue[trackPointer]

                    if trackPointer != data.p_aram:
                        raise RuntimeError(f'Unexpected track data: actual ${trackPointer:X} != expected ${data.p_aram:X}')

                    if trackPointersQueue:
                        trackEndPointer = min(trackPointersQueue.keys())
                    else:
                        trackEndPointer = trackPointer + len(data.data)

                    trackData = AramStream(data.p_aram, data.read(trackEndPointer - trackPointer))

                    track = self.Track(i_track, p_trackSet, i_tracker, isRepeatedSubsection, False, trackPointer - self.p_aram + self.p_snes, trackData)
                    tracks += [track]
                    
                    trackPointersQueue |= {p_subsection: (i_track, p_trackSet, i_tracker, True) for p_subsection in track.subsectionPointers}
                    if trackData.data:
                        tracks += [self.Track(0, 0, 0, False, True, trackData.p_aram - self.p_aram + self.p_snes, trackData)]
                
                return tracks
            
            def __init__(self, i_tracker, p_snes, data):
                self.p_snes = p_snes
                self.i_tracker = i_tracker
                self.p_aram = data.p_aram
                
                self._processTrackerCommands(data)
                
                self.trackSets = []
                self.tracks = []
                while data.data:
                    trackSets = self._readTrackSets(data)
                    p_nextTrackSet = min(p_trackSet for p_trackSet in self.trackSetPointers | {data.p_aram + len(data.data)} if p_trackSet > data.p_aram)
                    tracks = self._processTracks(AramStream(data.p_aram, data.read(p_nextTrackSet - data.p_aram)), trackSets, p_nextTrackSet)
                    
                    self.trackSets += trackSets
                    self.tracks += tracks

                if data.data:
                    raise RuntimeError(f'Leftover tracker data: ${data.p_aram:X}')

            def addTrackSet(self, data):
                while data.data:
                    trackSets = self._readTrackSets(data)
                    p_nextTrackSet = min(p_trackSet for p_trackSet in self.trackSetPointers | {data.p_aram + len(data.data)} if p_trackSet > data.p_aram)
                    tracks = self._processTracks(AramStream(data.p_aram, data.read(p_nextTrackSet - data.p_aram)), trackSets, p_nextTrackSet)
                    
                    self.trackSets += trackSets
                    self.tracks += tracks

                if data.data:
                    raise RuntimeError(f'Leftover tracker data: ${data.p_aram:X}')

            def repoint(self, p_aram):
                self.p_aram = p_aram
                
                oldTrackSetPointers = [trackSet[0] for trackSet in self.trackSets]
                oldCommandPointers = [command.p_aram for command in self.commands]
                oldTrackPointers = [track.p_aram for track in self.tracks]
                
                commandListSize = sum(command.size() for command in self.commands)
                p_aram += commandListSize
                
                # Repoint track sets
                for trackSet in self.trackSets:
                    trackSet[0] = p_aram
                    p_aram += 0x10
                
                p_aram_tracks = p_aram
                
                # Repoint commands and track set pointers
                p_aram = self.p_aram
                for command in self.commands:
                    command.p_aram = p_aram
                    if command.type == self.Command.type_trackSetPointer:
                        if command.p_trackSet not in oldTrackSetPointers:
                            raise RuntimeError(f"Bad track set pointer: ${command.p_trackSet:04X} not in {[f'${p:04X}' for p in oldTrackSetPointers]}")
                            
                        command.p_trackSet = self.trackSets[oldTrackSetPointers.index(command.p_trackSet)][0]
                    
                    p_aram += command.size()
                    
                # Repoint command goto targets
                for command in self.commands:
                    if command.type == self.Command.type_goto:
                        if command.p_destination not in oldCommandPointers:
                            raise RuntimeError("Bad command goto target pointer")
                            
                        command.p_destination = self.commands[oldCommandPointers.index(command.p_destination)].p_aram
                
                # Repoint tracks
                p_aram = p_aram_tracks
                for track in self.tracks:
                    track.p_aram = p_aram
                    p_aram += track.size()
                    if track.p_trackSet != 0:
                        track.p_trackSet = self.trackSets[oldTrackSetPointers.index(track.p_trackSet)][0] # for pjlog
                
                # Repoint track pointers
                for trackSet in self.trackSets:
                    for (i_track, p_track) in enumerate(trackSet[1]):
                        if p_track == 0:
                            continue
                            
                        if p_track not in oldTrackPointers:
                            raise RuntimeError(f"Bad track pointer: ${p_track:04X} not in {[f'${p:04X}' for p in oldTrackPointers]}")
                            
                        trackSet[1][i_track] = self.tracks[oldTrackPointers.index(p_track)].p_aram
                
                # Repoint subsection pointers
                for track in self.tracks:
                    for command in track.commands:
                        if isinstance(command, self.Track.RepeatSubsection):
                            if command.p_subsection not in oldTrackPointers:
                                raise RuntimeError("Bad track subsection pointer")
                            
                            command.p_subsection = self.tracks[oldTrackPointers.index(command.p_subsection)].p_aram

            def write(self, data):
                for command in self.commands:
                    command.write(data)

                for [_, trackPointers] in self.trackSets:
                    for p_track in trackPointers:
                        data.writeInt(p_track, 2)

                for track in self.tracks:
                    track.write(data)

            def pjlog(self):
                def org_aram(address):
                    snes_address = hex2snes(address - self.p_aram + snes2hex(self.p_snes))
                    return f'${snes_address >> 16:02X}:{snes_address & 0xFFFF:04X}/${address:04X}       '

                destinationPointers = {self.p_aram} | {command.p_destination for command in self.commands if command.type == self.Command.type_goto}
                
                commandListFragments = []
                commandListFragment = []
                for command in self.commands:
                    if command.p_aram in destinationPointers and commandListFragment:
                        commandListFragments += [f',\n{indent}'.join(commandListFragment)]
                        commandListFragment = []

                    data = AramStream(0, [])
                    command.write(data)
                    data = [data.readInt(2) for _ in range(len(data.data) // 2)]
                    commandListFragment += [','.join(f'{datum:04X}' for datum in data)]

                if commandListFragment:
                    commandListFragments += [f',\n{indent}'.join(commandListFragment)]
                
                if len(destinationPointers) != len(commandListFragments):
                    raise RuntimeError("len(destinationPointers) != len(commandListFragments)")

                trackSets = [(p_trackSet, ', '.join(f'{p_track:04X}' for p_track in trackPointers)) for [p_trackSet, trackPointers] in self.trackSets]

                print(f'; Tracker {self.i_tracker} commands')
                for (p_aram, commandListFragment) in zip(sorted(destinationPointers), commandListFragments):
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
            
            # Read tracker pointers, keep them about before self.trackers doesn't include the shared tracker pointers
            self.trackerPointers = []
            while data.p_aram not in self.trackerPointers:
                self.trackerPointers += [data.readInt(2)]
                #print(f'self.trackerPointers[-1] = ${self.trackerPointers[-1]:04X}')

            trackerPointers_sorted = sorted(self.trackerPointers + [self.p_aram + self.blockSize])
            trackerEndPointers = {begin: end for (begin, end) in zip(trackerPointers_sorted[:-1], trackerPointers_sorted[1:])}
            #trackerEndPointers = {trackerPointers_sorted[i]: trackerPointers_sorted[i + 1] for i in range(len(trackerPointers_sorted) - 1)}

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
            
            # TODO: modify to make trackers contiguous instead of naively using diff

            for (i_tracker, p_tracker) in enumerate(self.trackerPointers):
                if p_tracker >= 0x5800:
                    self.trackerPointers[i_tracker] = p_tracker + diff

            for tracker in self.trackers:
                tracker.repoint(tracker.p_aram + diff)

        def repointSharedTrackers(self, p_aram):
            diff = p_aram - 0x530E

            for (i_tracker, p_tracker) in enumerate(self.trackerPointers):
                if p_tracker < 0x5800:
                    self.trackerPointers[i_tracker] = p_tracker + diff

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
            print(f'{org_aram(self.p_aram)}dw {trackerPointers}')
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
            #print(f'Found SPC block {formatLong(p_blockHeader)}: ({formatValue(blockSize):>5}, ${p_aram:04X})')
            if blockSize == 0:
                break

            data = AramStream(p_aram, [int.from_bytes(rom_in.read(1), 'little') for _ in range(blockSize)])
            dataBlocks += [(p_blockHeader, data)]

        self.p_eof = hex2snes(rom_in.tell() - 4)

        def init_spcEngine(p_blockHeader, data, i_dataBlock):
            if args.file_type != 'rom':
                return
                
            if self.spcEngine is not None:
                raise RuntimeError("Duplicate SPC engine")
                
            self.spcEngine = MusicData.SpcEngine(p_blockHeader, data)
            self.blocks |= {i_dataBlock: self.spcEngine}

        def init_noteLengthTable(p_blockHeader, data, i_dataBlock):
            if self.noteLengthTable is not None:
                raise RuntimeError("Duplicate note length table")
                
            self.noteLengthTable = MusicData.NoteLengthTable(p_blockHeader, data)
            self.blocks |= {i_dataBlock: self.noteLengthTable}

        def init_trackers(p_blockHeader, data, i_dataBlock):
            if self.trackers is not None:
                raise RuntimeError("Duplicate trackers")
                
            self.trackers = MusicData.Trackers(p_blockHeader, data)
            self.blocks |= {i_dataBlock: self.trackers}

        def init_instrumentTable(p_blockHeader, data, i_dataBlock):
            if self.instrumentTable is not None:
                raise RuntimeError("Duplicate instrument table")
                
            self.instrumentTable = MusicData.InstrumentTable(p_blockHeader, data)
            self.blocks |= {i_dataBlock: self.instrumentTable}

        def init_sampleTable(p_blockHeader, data, i_dataBlock):
            if self.sampleTable is not None:
                raise RuntimeError("Duplicate sample table")
                
            self.sampleTable = MusicData.SampleTable(p_blockHeader, data)
            self.blocks |= {i_dataBlock: self.sampleTable}

        def init_sampleData(p_blockHeader, data, i_dataBlock):
            if self.sampleData is not None:
                raise RuntimeError(f"Duplicate sample data: old: ${self.sampleData.p_aram:04X}, new: ${data.p_aram:04X}")
                
            if self.sampleTable is None:
                raise RuntimeError("Sample data with no sample table")

            self.sampleData = MusicData.SampleData(p_blockHeader, data, self.sampleTable)
            self.blocks |= {i_dataBlock: self.sampleData}
        
        def handle_extra(p_blockHeader, data, i_dataBlock):
            if self.trackers is not None:
                blockSize = len(data.data)
                for tracker in self.trackers.trackers:
                    if data.p_aram in tracker.trackSetPointers:
                        tracker.addTrackSet(data)
                        break
                else:
                    return
                    
                self.trackers.blockSize += blockSize

        aramRegions = (
            (0,      0x5800,  init_spcEngine),
            (0x5800, 0x5820,  init_noteLengthTable),
            (0x5820, 0x6C00,  init_trackers),
            (0x6C00, 0x6D00,  init_instrumentTable),
            (0x6D00, 0x6E00,  init_sampleTable),
            (0x6E00, 0xB600,  init_sampleData), # Depends on sample table
            (0xB600, 0x10000, handle_extra)
        )
        
        # HACK: If tracker pointers are stored in a different block than the tracker data, merge the two blocks
        for (i_dataBlock_pointers, (p_blockHeader_pointers, data_pointers)) in enumerate(dataBlocks):
            if data_pointers.p_aram == 0x5828 and len(data_pointers.data) < 8:
                break
        
        if i_dataBlock_pointers != len(dataBlocks):
            for (i_dataBlock_data, (p_blockHeader_data, data_data)) in enumerate(dataBlocks):
                if data_data.p_aram == 0x5830:
                    print(f'Merging ${data_pointers.p_aram:04X} with ${data_data.p_aram:04X}')
                    dataBlocks[i_dataBlock_pointers] = (p_blockHeader_pointers, AramStream(data_pointers.p_aram, data_pointers.data + [0] * (8 - len(data_pointers.data)) + data_data.data))
                    del dataBlocks[i_dataBlock_data]
                    break
        
        self.blocks = {}
        for (p_aram_begin, p_aram_end, init) in aramRegions:
            for (i_dataBlock, (p_blockHeader, data)) in enumerate(dataBlocks):
                if data.data and p_aram_begin <= data.p_aram < p_aram_end:
                    init(p_blockHeader, data, i_dataBlock)
                    
        for (p_blockHeader, data) in dataBlocks:
            if len(data.data) != 0:
                print(f'Data block not (fully) processed: ${data.p_aram:04X} ({formatLong(p_blockHeader)}), {formatValue(len(data.data))} bytes remaining')

    def repoint(self):
        if self.spcEngine is not None:
            self.spcEngine.repoint(args.p_spcEngine, args.p_noteLengthTable - args.p_spcEngine)
            self.trackers.repointSharedTrackers(args.p_sharedTrackers)

        if self.noteLengthTable is not None:
            self.noteLengthTable.repoint(self.noteLengthTable.p_aram + args.p_noteLengthTable - 0x5800)

        if self.instrumentTable is not None:
            self.instrumentTable.repoint(self.instrumentTable.p_aram + args.p_instrumentTable - 0x6C00)

        if self.sampleTable is not None:
            self.sampleTable.repoint(self.sampleTable.p_aram + args.p_sampleTable - 0x6D00)

        if self.sampleData is not None:
            self.sampleData.repoint(self.sampleData.p_aram + args.p_sampleData - 0x6E00)
            
        p_trackers = self.sampleData.p_aram + self.sampleData.blockSize
        if self.trackers is not None:
            self.trackers.repoint(self.trackers.p_aram + p_trackers - 0x5820)

    def write(self, p_rom): # need to repoint music pointer table
        data = AramStream(0, [])

        if self.noteLengthTable is not None:
            self.noteLengthTable.write(data)

        if self.instrumentTable is not None:
            self.instrumentTable.write(data)

        if self.sampleTable is not None:
            self.sampleTable.write(data)

        if self.sampleData is not None:
            self.sampleData.write(data)

        if self.trackers is not None:
            self.trackers.write(data)

        if self.spcEngine is not None:
            self.spcEngine.write(data)
        
        # Write out location of p_trackers (newly required by engine change)
        p_trackers = self.sampleData.p_aram + self.sampleData.blockSize
        data.writeInt(2, 2)
        data.writeInt(args.p_p_trackers, 2)
        data.writeInt(p_trackers, 2)

        # SPC data terminator: 0000 dddd where d is the jump target for the SPC engine specifically and ignored otherwise
        data.writeInt(0, 2)
        if self.spcEngine is not None:
            data.writeInt(self.spcEngine.p_aram, 2)
        else:
            data.writeInt(0x1500, 2)

        rom_out.seek(p_rom)
        rom_out.write(bytes(data.data))
        return p_rom + len(data.data)

    def pjlog(self):
        print(f';;; {formatLong(hex2snes(self.address))}: {self.name} ;;;')
        print('{')
        for i, block in sorted(self.blocks.items()):
            #print(i)
            block.pjlog()

        print('; EOF')
        print(f'{org(self.p_eof)}dw 0000, 1500') # $1500 is potentially inaccurate
        print('}')



music = [
    'SPC engine',
    'Title sequence',
    'Empty Crateria',
    'Lower Crateria',
    'Upper Crateria',
    'Green Brinstar',
    'Red Brinstar',
    'Upper Norfair',
    'Lower Norfair',
    'Maridia',
    'Tourian',
    'Mother Brain',
    'Boss fight 1',
    'Boss fight 2',
    'Miniboss fight',
    'Ceres',
    'Wrecked Ship',
    'Zebes boom',
    'Intro',
    'Death',
    'Credits',
    '"The last Metroid is in captivity"',
    '"The galaxy is at peace"',
    'Shitroid (same as boss fight 2)',
    'Samus theme (same as upper Crateria)'
]

if args.file_type == 'rom':
    p_rom = snes2hex(0xCF_8000)
    for (i_music, musicName) in enumerate(music):
        rom_in.seek(snes2hex(0x8F_E7E1) + i_music * 3)
        p_musicData = int.from_bytes(rom_in.read(3), 'little')
        rom_out.seek(snes2hex(0x8F_E7E1) + i_music * 3)
        rom_out.write(int.to_bytes(hex2snes(p_rom), 3, 'little'))
        
        musicData = MusicData(snes2hex(p_musicData), musicName)
        musicData.repoint()
        if p_musicData == 0xCF_8000:
            #musicData.pjlog()
            pass
            
        p_rom = musicData.write(p_rom)
elif args.file_type == 'nspc':
    musicData = MusicData(0, "Custom NSPC")
    musicData.repoint()
    print(f'Max echo time = {(0x1_0000 - (musicData.trackers.p_aram + musicData.trackers.blockSize)) // 0x800} frames')
    #musicData.pjlog()
    p_rom = musicData.write(0)
else: # args.file_type == 'nspctest':
    rom_out.seek(snes2hex(0x8F_E7E1) + 6 * 3)
    p_musicData = int.from_bytes(rom_out.read(3), 'little')

    musicData = MusicData(0, "Custom NSPC")
    musicData.repoint()
    print(f'Max echo time = {(0x1_0000 - (musicData.trackers.p_aram + musicData.trackers.blockSize)) // 0x800} frames')
    musicData.write(snes2hex(p_musicData)) # Overwrite red brinstar
