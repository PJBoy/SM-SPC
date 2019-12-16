main:
{
.initialisation
{
; The page 0 is clear, except for $00; page 1 has the stack. Clear all the rest of RAM
movw $00,ya

mov !misc0+1,#$02
mov !misc1+1,#!echoBufferEnd-$0200>>8
call memclear

; Set up echo with echo delay = 1
mov a,#$01 : call setUpEcho

; Disable echo buffer writes
set5 !flg

; DSP left/right track master volume = 60h
mov a,#$60
mov y,#$0C : call writeDspRegisterDirect
mov y,#$1C : call writeDspRegisterDirect

; DSP sample table address = $6D00
mov a,#!sampleTable>>8 : mov y,#$5D : call writeDspRegisterDirect

; Clear $F4..F7, and stop timers (and set an unused bit)
mov a,#$F0 : mov $00F1,a

; Timer 0 divider = 10h (2 ms)
mov a,#$10 : mov $00FA,a

; Music tempo = 1000h (31.3 ticks / second)
mov !musicTempo+1,a

; Enable timer 0
mov a,#$01 : mov $00F1,a
}

.loop_main
{
mov a,!disableNoteProcessing : bne .branch_musicTrack

; DSP registers update
mov y,#$0A

.loop_updateDsp
{
cmp y,#$05 : beq .branch_flg : bcs .branch_doUpdateDsp
cmp (!echoTimer),(!echoDelay) : bne .branch_next

.branch_flg
bbs7 !echoTimer,.branch_next

.branch_doUpdateDsp
mov a,dspRegisterAddresses-1+y : mov $00F2,a
mov a,directPageAddresses-1+y : mov x,a : mov a,(x) : mov $00F3,a

.branch_next
dbnz y,.loop_updateDsp
}

; Clear key on/off flags
mov !keyOnFlags,y : mov !keyOffFlags,y

; Update RNG
mov a,!randomNumber : eor a,!randomNumber+1 : lsr a : lsr a : notc : ror !randomNumber : ror !randomNumber+1

; Wait for timer 0 output to be non-zero
-
mov y,$00FD : beq -

; Save time since last loop
push y

; Sound effects clock += (time since last loop) * 20h
mov a,#$20 : mul ya : clrc : adc a,!soundEffectsClock : mov !soundEffectsClock,a

bcc .branch_soundFx_end

; CPU IO 1
call handleCpuIo1
mov x,#$01 : call writeReadCpuIo

; CPU IO 2
mov a,!disableProcessingCpuIo2 : bne +
call handleCpuIo2
mov x,#$02 : call writeReadCpuIo

+
; CPU IO 3
call handleCpuIo3
mov x,#$03 : call writeReadCpuIo

; Echo timer
cmp (!echoTimer),(!echoDelay) : beq .branch_soundFx_end
inc !echoTimer
.branch_soundFx_end

; Music track clock += (time since last loop) * ([music tempo] / 100h)
mov a,!musicTempo+1 : pop y : mul ya : clrc : adc a,!musicTrackClock : mov !musicTrackClock,a
bcc .branch_musicTrack_end

; Music
.branch_musicTrack
call handleMusicTrack
mov x,#$00 : call writeReadCpuIo
bra .loop_main
.branch_musicTrack_end

mov a,!cpuIo0_write : beq ++

; Update playing tracks
mov x,#$00
mov !musicVoiceBitset,#$01

-
mov a,!trackPointers+1+x : beq +
call updatePlayingTrack

+
inc x : inc x
asl !musicVoiceBitset : bne -

++
jmp .loop_main
}
}

; $1621
writeReadCpuIo:
{
;; Parameter:
;;     X: CPU IO index

; Write CPU IO [X]
mov a,!cpuIo0_write+x : mov $00F4+x,a

; Wait for CPU IO [X] to stabilise
-
mov a,$00F4+x : cmp a,$00F4+x : bne -

; Read CPU IO [X]
mov !cpuIo0_read+x,a

.ret
ret
}

; $1631
processNewNote:
{
;; Parameters:
;;     A: Note. Range is 80h..DFh
;;     Y: Note (same as A)

; Percussion note check
cmp y,#$CA : bcc +
call selectInstrument
mov y,#$A4
+

; Return if rest or tie note
cmp y,#$C8 : bcs writeReadCpuIo_ret

; Return if voice is not sound effect enabled
mov a,!enableSoundEffectVoices : and a,!musicVoiceBitset : bne writeReadCpuIo_ret

; Set track note according to [Y] after transposition
mov a,y : and a,#$7F : clrc : adc a,!musicTranspose : clrc : adc a,!trackTransposes+x : mov !trackNotes+x,a
mov a,!trackSubtransposes+x : mov !trackSubnotes+x,a

; Set track vibrato phase's initial value according to the track dynamic vibrato length
mov a,!trackDynamicVibratoLengths+x : lsr a : mov a,#$00 : ror a : mov !trackVibratoPhases+x,a

mov a,#$00
mov !trackVibratoDelayTimers+x,a
mov !trackDynamicVibratoTimers+x,a
mov !trackTremoloPhases+x,a
mov !trackTremoloDelayTimers+x,a
or (!musicVoiceVolumeUpdateBitset),(!musicVoiceBitset)
or (!keyOnFlags),(!musicVoiceBitset)

mov a,!trackSlideLengths+x : mov !trackPitchSlideTimers+x,a
beq .branch_pitchSlide_end

; Handle pitch slide
mov a,!trackSlideDelays+x : mov !trackPitchSlideDelayTimers+x,a

; Slide in check
mov a,!trackSlideDirections+x : bne +
mov a,!trackNotes+x : setc : sbc a,!trackSlideExtents+x : mov !trackNotes+x,a
+

mov a,!trackSlideExtents+x : clrc : adc a,!trackNotes+x
call setTrackTargetPitch

.branch_pitchSlide_end
call getTrackNote

; Fall through
}

; $169B
playNote:
{
; If [note] >= 34h (E_5):
;     Note += ([note] - 34h) / 100h
; Else if [note] < 13h (G_2):
;     Note += -1 + ([note] - 13h) / 80h

mov y,#$00
mov a,!note+1 : setc : sbc a,#$34
bcs +
mov a,!note+1 : setc : sbc a,#$13
bcs playNoteDirect
dec y
asl a
+

addw ya,!note : movw !note,ya

; Fall through
}

; $16B1
playNoteDirect:
{
; Coming into this function, $11.$10 is the note to be played, range of $11 is 0..53h = C_1..B_7.
; $11 (the whole part of the note) is decomposed into a key (0..11) and an octave (0..6)

; $1E66..7F is a table of multipliers to be used for the key.
; The multiplier is adjusted for the fractional part of the note by linear interpolation of the closest values from the table.
;
; So given
;     i_0 = x_0 = [$11]
;     i_1 = x_1 = [$11] + 1
;
; the indices for the $1E66 table for the keys less than and greater than [$11].[$10] respectively,
; let
;     y_0 = [$1E66 + i_0 * 2]
;     y_1 = [$1E66 + i_1 * 2]
;
; be the pitch corresponding multipliers and let x be the fractional part [$10] / 100h, then
;     y = x * (y_1 - y_0) / (x_1 - x_0) + y_0
;
; is the interpolated pitch multiplier. Note that x_1 - x_0 = 1

; The resulting pitch multiplier corresponds to octave 6, which is halved for each octave less than 6 the input note is

; Save track index
push x

; Y = [note] % 12 * 2
; X = [note] / 12
mov a,!note+1 : asl a : mov y,#$00 : mov x,#$18 : div ya,x
mov x,a

; Get pitch multiplier for note in octave 6
mov a,pitchTable+1+y : mov !misc0+1,a : mov a,pitchTable+y : mov !misc0,a
mov a,pitchTable+3+y : push a : mov a,pitchTable+2+y : pop y : subw ya,!misc0
mov y,!note : mul ya : mov a,y : mov y,#$00 : addw ya,!misc0
mov !misc0+1,y : asl a : rol !misc0+1 : mov !misc0,a

; Adjust for actual octave
bra +

-
lsr !misc0+1
ror a
inc x

+
cmp x,#$06
bne -
mov !misc0,a

; Restore track index
pop x

; Track instrument pitch multiplier
mov a,!trackInstrumentPitches+x   : mov y,!misc0+1 : mul ya : movw !misc1,ya
mov a,!trackInstrumentPitches+x   : mov y,!misc0   : mul ya : push y
mov a,!trackInstrumentPitches+1+x : mov y,!misc0   : mul ya : addw ya,!misc1 : movw !misc1,ya
mov a,!trackInstrumentPitches+1+x : mov y,!misc0+1 : mul ya : mov y,a : pop a : addw ya,!misc1 : movw !misc1,ya

; Write to DSP voice pitch scaler
mov a,x : xcn a : lsr a : or a,#$02 : mov y,a
mov a,!misc1
call writeDspRegister
inc y : mov a,!misc1+1

; Fall through
}

; $171E
writeDspRegister:
{
;; Parameters:
;;     A: Value to write
;;     Y: DSP register index

; Return if voice is sound effect enabled
push a : mov a,!musicVoiceBitset : and a,!enableSoundEffectVoices : pop a : bne writeDspRegisterDirect_ret

; Fall through
}

; $1726
writeDspRegisterDirect:
{
;; Parameters:
;;     A: Value to write
;;     Y: DSP register index

mov $00F2,y : mov $00F3,a

.ret
ret
}

; $1E8B
receiveDataFromCpu:
{
; Data format:
;     ssss dddd [xx xx...] (data block 0)
;     ssss dddd [xx xx...] (data block 1)
;     ...
;     0000 aaaa
; Where:
;     s = data block size in bytes
;     d = destination address
;     x = data
;     a = entry address. Ignored (used by boot ROM for first APU transfer)

; CPU IO 0..1 = AAh BBh
; Wait until [CPU IO 0] = CCh
; For each data block:
;     Destination address = [CPU IO 2..3]
;     Echo [CPU IO 0]
;     [CPU IO 1] != 0
;     Index = 0
;     For each data byte:
;         Wait until [CPU IO 0] = index
;         Echo index back through [CPU IO 0]
;         Destination address + index = [CPU IO 1]
;         Increment index
;         If index = 0:
;             Destination address += 100h
;     [CPU IO 0] > index
; Entry address = [CPU IO 2..3] (ignored)
; Echo [CPU IO 0]
; [CPU IO 1] == 0

mov a,#$AA : mov $00F4,a
mov a,#$BB : mov $00F5,a

-
mov a,$00F4 : cmp a,#$CC : bne -
bra .branch_processDataBlock

.loop_dataBlock
mov y,$00F4 : bne .loop_dataBlock

.loop_dataByte
cmp y,$00F4 : bne +
mov a,$00F5
mov $00F4,y
mov (!misc0)+y,a : inc y : bne .loop_dataByte
inc !misc0+1
bra .loop_dataByte

+
bpl .loop_dataByte
cmp y,$00F4 : bpl .loop_dataByte

.branch_processDataBlock
mov a,$00F6 : mov y,$00F7 : movw !misc0,ya
mov y,$00F4 : mov a,$00F5 : mov $00F4,y
bne .loop_dataBlock

; Reset CPU IO input latches and enable/reset timer 0
mov x,#$31 : mov $00F1,x
ret
}

; $1E1D
panningVolumeMultipliers:
db $00, $01, $03, $07, $0D, $15, $1E, $29, $34, $42, $51, $5E, $67, $6E, $73, $77, $7A, $7C, $7D, $7E, $7F

; $1E32
echoFirFilters:
db $7F,$00,$00,$00,$00,$00,$00,$00 ; Sharp echo
db $58,$BF,$DB,$F0,$FE,$07,$0C,$0C ; Echo + reverb
db $0C,$21,$2B,$2B,$13,$FE,$F3,$F9 ; Smooth echo
db $34,$33,$00,$D9,$E5,$01,$FC,$EB ; ???

; $1E52
dspRegisterAddresses: ; For DSP update
db $2C, $3C, $0D, $4D, $6C, $4C, $5C, $3D, $2D, $5C

; $1E5C
directPageAddresses: ; For DSP update
db !echoVolumeLeft+1, !echoVolumeRight+1, !echoFeedbackVolume, !echoEnableFlags, !flg, !keyOnFlags, !zero, !noiseEnableFlags, !pitchModulationFlags, !keyOffFlags

; $1E66
pitchTable:
dw $085F, $08DE, $0965, $09F4, $0A8C, $0B2C, $0BD6, $0C8B, $0D4A, $0E14, $0EEA, $0FCD, $10BE
