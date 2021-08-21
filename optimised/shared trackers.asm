; Macros
{
macro noteLength(length)
    db <length>
endmacro

macro noteParameters(length, volume, ringLength)
    db <length>, <volume><<4|<ringLength>
endmacro

macro note(note)
    db <note>
endmacro

macro percussionNote(note)
    db <note>
endmacro

!end = "db 0"
!tie = "db $C8"
!rest = "db $C9"

; Commands
{
macro selectInstrument(i_instrument)
    db $E0, <i_instrument>
endmacro

macro staticPanning(bias)
    db $E1, <bias>
endmacro

macro dynamicPanning(duration, targetBias)
    db $E2, <duration>, <targetBias>
endmacro

macro staticVibrato(delay, rate, extent)
    db $E3, <delay>, <rate>, <extent>
endmacro

macro endVibrato()
    db $E4
endmacro

macro staticMusicVolume(volume)
    db $E5, <volume>
endmacro

macro dynamicMusicVolume(duration, targetVolume)
    db $E6, <duration>, <targetVolume>
endmacro

macro staticMusicTempo(tempo)
    db $E7, <tempo>
endmacro

macro dynamicMusicTempo(duration, targetTempo)
    db $E8, <duration>, <targetTempo>
endmacro

macro musicTranspose(transpose)
    db $E9, <transpose>
endmacro

macro transpose(transpose)
    db $EA, <transpose>
endmacro

macro tremolo(delay, rate, extent)
    db $EB, <delay>, <rate>, <extent>
endmacro

macro endTremolo()
    db $EC
endmacro

macro staticVolume(volume)
    db $ED, <volume>
endmacro

macro dynamicVolume(duration, targetVolume)
    db $EE, <duration>, <targetVolume>
endmacro

macro repeatSubsection(p_subsection, n_repeats)
    db $EF : dw <p_subsection> : db <n_repeats>
endmacro

macro dynamicVibrato(duration)
    db $F0, <duration>
endmacro

macro slideOut(delay, duration, extent)
    db $F1, <delay>, <duration>, <extent>
endmacro

macro slideIn(delay, duration, extent)
    db $F2, <delay>, <duration>, <extent>
endmacro

macro endSlide()
    db $F3
endmacro

macro subtranspose(subtranspose)
    db $F4, <subtranspose>
endmacro

macro staticEcho(voices, volume_left, volume_right)
    db $F5, <voices>, <volume_left>, <volume_right>
endmacro

macro endEcho()
    db $F6
endmacro

macro echoParameters(delay, feedbackVolume, i_firFilter)
    db $F7, <delay>, <feedbackVolume>, <i_firFilter>
endmacro

macro dynamicEchoVolume(delay, volume_left, volume_right)
    db $F8, <delay>, <volume_left>, <volume_right>
endmacro

macro pitchSlide(delay, duration, extent)
    db $F9, <delay>, <duration>, <extent>
endmacro

macro setPercussionInstrumentsIndex(i)
    db $FA, <i>
endmacro

macro skipByte()
    db $FB
endmacro

macro skipAllNewNotes()
    db $FC
endmacro

macro stopSoundEffectsAndDisableMusicNoteProcessing()
    db $FD
endmacro

macro resumeSoundEffectsAndEnableMusicNoteProcessing()
    db $FE
endmacro
}
}

; Samus fanfare
musicTrack1:
{
.tracker
dw .trackPointers, $0000

.trackPointers
dw .track0, .track1, .track2, .track3, .track4, .track5, .track6, $0000

.track0
{
%setPercussionInstrumentsIndex($26)
%staticMusicTempo($12)
%staticMusicVolume($B4)
%staticEcho($0F, $0A, $0A)
%echoParameters($02, $0A, $00)
%selectInstrument($0B)
%transpose($F4)
%subtranspose($46)
%staticPanning($0A)
%staticVolume($AA)
%dynamicVolume($18, $DC)
%noteParameters($18, 7, $F)
%note($B2)
%staticVolume($AA)
%dynamicVolume($18, $DC)
%note($B5)
%staticVolume($AA)
%dynamicVolume($18, $DC)
%note($B2)
%staticVolume($AA)
%dynamicVolume($18, $DC)
%note($B0)
%noteLength($30)
%note($AD)
%staticVolume($AA)
%dynamicVolume($30, $82)
%note($AD)
%noteLength($0F)
!rest
!end
}

.track1
{
%selectInstrument($0B)
%transpose($F4)
%subtranspose($46)
%staticPanning($0A)
%noteLength($03)
!rest
%staticVolume($64)
%dynamicVolume($28, $FA)
%noteParameters($04, 7, $F)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A9)
%note($A9)
%note($A9)
%note($A9)
%note($A9)
%note($A9)
%staticVolume($FA)
%dynamicVolume($28, $64)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A6)
%note($A4)
%note($A4)
%note($A4)
%note($A4)
%note($A4)
%note($A4)
%staticVolume($3C)
%dynamicVolume($0A, $E6)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%staticVolume($E6)
%dynamicVolume($1E, $3C)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%note($AD)
%noteLength($0C)
!rest
}

.track2
{
%selectInstrument($0B)
%transpose($00)
%subtranspose($46)
%staticVolume($C8)
%staticPanning($03)
%noteParameters($18, 7, $F)
%note($8F)
%note($8E)
%staticVolume($B4)
%note($8C)
%note($89)
%note($30)
%note($82)
%note($82)
%noteLength($0F)
!rest
}

.track3
{
%selectInstrument($0B)
%transpose($00)
%subtranspose($1E)
%staticVolume($C8)
%staticPanning($11)
%noteLength($03)
!rest
%noteParameters($18, 7, $F)
%note($8F)
%note($8E)
%note($8C)
%note($89)
%subtranspose($00)
%noteLength($30)
%note($82)
%noteLength($2D)
%note($82)
%noteLength($0F)
!rest
}

.track4
{
%selectInstrument($0B)
%transpose($F4)
%subtranspose($46)
%staticVolume($BE)
%staticPanning($0A)
%noteParameters($18, 7, $F)
%note($A2)
%note($A1)
%note($9F)
%note($A1)
%noteLength($30)
%note($8E)
%note($8E)
%noteLength($0F)
!rest
}

.track5
{
%selectInstrument($02)
%transpose($00)
%staticPanning($06)
%staticVolume($3C)
%dynamicVolume($32, $82)
%noteLength($05)
!rest
%noteParameters($05, 7, $F)
%note($93)
%noteLength($0A)
!rest
%noteLength($0F)
%note($97)
%noteLength($14)
!rest
%noteLength($08)
%note($93)
%staticPanning($08)
%noteLength($04)
!rest
%note($95)
!rest
%note($97)
%noteLength($0B)
!rest
%staticPanning($03)
%noteLength($05)
!rest
%note($93)
%noteLength($0A)
!rest
%noteLength($0F)
%note($93)
%noteLength($1E)
!rest
%noteLength($08)
%note($90)
%staticPanning($0D)
%noteLength($04)
!rest
%note($93)
!rest
%staticVolume($AA)
%dynamicVolume($1E, $14)
%note($93)
%noteLength($1C)
!rest
}

.track6
{
%selectInstrument($02)
%transpose($00)
%staticPanning($0E)
%staticVolume($3C)
%dynamicVolume($32, $82)
%noteParameters($05, 7, $F)
%note($91)
%noteLength($1E)
!rest
%noteLength($06)
!rest
%note($93)
%noteLength($10)
!rest
%staticPanning($0C)
%noteLength($04)
%note($93)
!rest
%note($90)
!rest
%noteLength($09)
%note($93)
%staticPanning($11)
%noteLength($05)
%note($91)
%noteLength($24)
!rest
%noteLength($06)
%note($93)
%noteLength($10)
!rest
%staticPanning($07)
%noteLength($04)
%note($93)
%noteLength($0E)
!rest
%noteLength($04)
%note($97)
!rest
%noteLength($06)
%note($97)
%staticVolume($AA)
%dynamicVolume($1E, $14)
%noteLength($04)
%note($93)
%noteLength($14)
!rest
!end
}
}

; Item fanfare
musicTrack2:
{
.tracker
dw .trackPointers, $0000

.trackPointers
dw .track0, .track1, .track2, .track3, .track4, .track5, .track6, $0000

.track0
{
%setPercussionInstrumentsIndex($26)
%staticMusicTempo($2D)
%staticMusicVolume($96)
%staticEcho($0F,$0A,$0A)
%echoParameters($02,$0A,$00)
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($E6)
%staticPanning($03)
%noteParameters($60, 7, $F)
%note($8A)
%note($89)
%note($87)
%noteLength($2A)
%note($82)
%staticMusicVolume($AA)
%dynamicMusicVolume($28,$3C)
!tie
%noteLength($04)
!rest
!end
}

.track1
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($E6)
%staticPanning($11)
%noteParameters($60, 7, $F)
%note($8A)
%note($89)
%note($87)
%noteLength($54)
%note($82)
%noteLength($04)
!rest
}

.track2
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($DC)
%staticPanning($06)
%noteParameters($30, 7, $F)
%note($9A)
%noteLength($18)
%note($9D)
%note($A2)
%noteLength($30)
%note($A1)
%note($9C)
%note($A2)
%noteLength($18)
%note($9D)
%note($9A)
%noteLength($54)
%note($9A)
%noteLength($04)
!rest
}

.track3
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($DC)
%staticPanning($0E)
%noteParameters($60, 7, $F)
%note($9D)
%note($9C)
%note($9A)
%noteLength($54)
%note($95)
%noteLength($04)
!rest
}

.track4
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($D2)
%staticPanning($0A)
%noteLength($04)
!rest
%noteParameters($18, 7, $F)
%note($9D)
%note($A2)
%note($A4)
%note($A6)
%note($A8)
%note($A4)
%note($9F)
%note($A4)
%staticVolume($A0)
%note($A9)
%staticVolume($BD)
%note($A6)
%note($A2)
%note($9F)
%noteLength($54)
!rest
}

.track5
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($DC)
%staticPanning($08)
%noteParameters($1C, 7, $F)
%note($9D)
%noteLength($14)
!rest
%noteLength($1C)
%note($A4)
%noteLength($14)
!rest
%noteLength($1C)
%note($A8)
%noteLength($14)
!rest
%noteLength($1C)
%note($9F)
%noteLength($14)
!rest
%staticVolume($C8)
%noteLength($1C)
%note($A9)
%dynamicMusicTempo($A0,$0A)
%staticVolume($E5)
%noteLength($14)
!rest
%noteLength($1C)
%note($A2)
%noteLength($14)
!rest
%staticPanning($0A)
%noteLength($54)
%note($A1)
%noteLength($04)
!rest
}

.track6
{
%selectInstrument($0B)
%subtranspose($46)
%transpose($00)
%staticVolume($AA)
%staticPanning($0C)
%noteLength($18)
!rest
%noteParameters($1C, 7, $F)
%note($A2)
%noteLength($14)
!rest
%noteLength($18)
%note($A6)
%noteLength($04)
!tie
%noteLength($14)
!rest
%noteLength($1C)
%note($A4)
%noteLength($14)
!rest
%noteLength($18)
%note($A4)
%noteLength($04)
!tie
%noteLength($14)
!rest
%noteLength($1C)
%note($A6)
%noteLength($14)
!rest
%noteLength($18)
%note($9F)
%noteLength($04)
!tie
%noteLength($50)
!rest
%noteLength($04)
!rest
!end
}
}

; Elevator
musicTrack3:
{
.tracker
dw .introTrackPointers
- : dw .loopTrackPointers, $00FF,-, $0000

.loopTrackPointers
dw .loopTrack0, .loopTrack1, .loopTrack2, .loopTrack3, $0000, $0000, $0000, $0000

.introTrackPointers
dw .introTrack0, .introTrack1, .introTrack2, .introTrack3, .introTrack4, $0000, $0000, $0000

.loopTrack0
{
%staticMusicVolume($DC)
%staticMusicTempo($10)
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($46)
%staticPanning($07)
%staticEcho($0F,$0A,$0A)
%echoParameters($02,$0A,$00)
%noteLength($30)
!rest
%noteParameters($18, 2, $F)
%note($BA)
%note($B5)
%note($B9)
%note($B1)
%noteLength($48)
!rest
%noteLength($18)
%note($B0)
%note($B6)
%note($BB)
!rest
!rest
%noteParameters($18, 1, $F)
%note($B5)
%noteLength($0C)
!rest
%noteLength($18)
%note($B2)
%noteLength($0C)
!rest
%noteLength($24)
!rest
%noteLength($60)
!rest
!rest
%noteLength($0C)
!rest
!end
}

.loopTrack1
{
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($32)
%staticPanning($0A)
%noteLength($30)
!rest
%noteParameters($18, 2, $F)
%note($A6)
%note($A1)
%note($A5)
%note($9D)
%noteLength($48)
!rest
%noteLength($18)
%note($9C)
%note($A2)
%note($A7)
!rest
!rest
%note($AD)
%noteLength($0C)
!rest
%noteLength($18)
%note($AA)
%noteLength($0C)
!rest
%noteLength($21)
!rest
%noteLength($60)
!rest
!rest
%noteLength($0F)
!rest
}

.loopTrack2
{
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($3C)
%staticPanning($0D)
%noteLength($20)
!rest
%noteParameters($06, 0, $F)
%note($BA)
%note($B5)
%note($B9)
%note($B1)
%note($B0)
%note($B6)
%note($BB)
%noteLength($2A)
!rest
%noteLength($06)
%note($BA)
%note($B5)
%note($B9)
%note($B1)
%note($B0)
%note($B6)
%note($BB)
%noteLength($36)
!rest
%noteLength($06)
%note($B9)
%note($B1)
%note($BA)
%note($B5)
%note($B0)
%note($B6)
%note($BB)
%noteLength($3E)
!rest
%noteLength($06)
%note($BA)
%note($B5)
%note($B9)
%note($B1)
%note($B0)
%note($B6)
%note($BB)
%noteLength($20)
!rest
%noteLength($06)
%note($B5)
%note($BA)
%note($B9)
%note($B1)
%note($B0)
%note($B6)
%note($BB)
%noteLength($11)
!rest
%noteLength($60)
!rest
!rest
%noteLength($07)
!rest
}

.loopTrack3
{
%selectInstrument($0B)
%subtranspose($46)
%staticPanning($0A)
%staticVolume($3C)
%dynamicVolume($3C,$C8)
%noteParameters($3C, 7, $F)
%note($80)
%staticVolume($C8)
%dynamicVolume($30,$3C)
%noteLength($30)
!tie
%repeatSubsection(.loopTrack3_repeatedSubsection, $05)
}

.introTrack0
{
%setPercussionInstrumentsIndex($26)
%staticMusicTempo($10)
%staticMusicVolume($C8)
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($46)
%staticEcho($0F,$0A,$0A)
%echoParameters($02,$0A,$00)
%staticPanning($07)
%dynamicPanning($C0,$0D)
%noteLength($0C)
!rest
!end
}

.introTrack1
{
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($32)
%noteLength($0C)
!rest
}

.introTrack2
{
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($3C)
%noteLength($0C)
!rest
}

.introTrack3
{
%selectInstrument($0B)
%subtranspose($46)
%staticPanning($0A)
%noteLength($0C)
!rest
}

.introTrack4
{
%selectInstrument($0C)
%subtranspose($28)
%staticVolume($28)
%staticPanning($0D)
%noteLength($0C)
!rest
!end
}

.loopTrack3_repeatedSubsection
{
%staticVolume($3C)
%dynamicVolume($3C,$C8)
%noteLength($3C)
%note($80)
%staticVolume($C8)
%dynamicVolume($30,$3C)
%noteLength($30)
!tie
!end
}
}

; Pre-statue hall
musicTrack4:
{
.tracker
- : dw .trackPointers, $00FF,-, $0000

.trackPointers
dw .track0, $0000, $0000, $0000, $0000, $0000, $0000, $0000

.track0
{
%setPercussionInstrumentsIndex($26)
%staticMusicTempo($10)
%staticMusicVolume($E6)
%staticEcho($01,$00,$00)
%echoParameters($02,$00,$00)
%selectInstrument($0B)
%subtranspose($46)
%staticPanning($0A)
%staticVolume($32)
%dynamicVolume($3C,$B4)
%noteParameters($3C, 7, $F)
%note($80)
%staticVolume($B4)
%dynamicVolume($30,$32)
%noteLength($30)
!tie
%staticVolume($32)
%dynamicVolume($3C,$B4)
%noteLength($3C)
%note($80)
%staticVolume($B4)
%dynamicVolume($30,$32)
%noteLength($30)
!tie
!end
!end
}
}
