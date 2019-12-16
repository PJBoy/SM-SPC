handleCpuIo3:
{
mov a,#$02 : mov !i_soundLibrary,a

mov a,!disableProcessingCpuIo2 : beq + : +

mov y,!cpuIo3_read_prev
mov a,!cpuIo3_read : mov !cpuIo3_read_prev,a
mov !cpuIo3_write,a
cmp y,!cpuIo3_read : bne .branch_change

.branch_noChange
mov a,!sound3 : bne +
ret

+
jmp processSound3

.branch_change
cmp a,#$00 : beq .branch_noChange
mov a,!cpuIo3_read : cmp a,#$01 : beq +
mov a,!sound3LowHealthPriority : cmp a,#$02 : beq .branch_noChange
mov a,!cpuIo3_read : cmp a,#$02 : beq +
mov a,!sound3Priority : bne .branch_noChange

+
mov a,!sound3 : beq +
mov a,#$00 : mov !sound3_enabledVoices,a
call resetSound3Channel0
call resetSound3Channel1

+
mov a,#$00
mov !sound3_channel0_legatoFlag,a
mov !sound3_channel1_legatoFlag,a
mov a,!cpuIo3_write : dec a : asl a : mov !i_sound3,a
mov x,!i_sound3 : mov a,sound3InstructionLists+x : mov !sound3_instructionListPointerSet,a : inc x : mov a,sound3InstructionLists+x : mov !sound3_instructionListPointerSet+1,a
mov a,!cpuIo3_write : mov !sound3,a
cmp a,#$FE : beq processSound3
cmp a,#$FF : beq processSound3
call goToJumpTableEntry

!sc = sound3Configurations_sound ; Shorthand for the `soundN` sublabels within the sound3Configurations label
dw !{sc}1,  !{sc}2,  !{sc}3,  !{sc}4,  !{sc}5,  !{sc}6,  !{sc}7,  !{sc}8,  !{sc}9,  !{sc}A,  !{sc}B,  !{sc}C,  !{sc}D,  !{sc}E,  !{sc}F,  !{sc}10,\
   !{sc}11, !{sc}12, !{sc}13, !{sc}14, !{sc}15, !{sc}16, !{sc}17, !{sc}18, !{sc}19, !{sc}1A, !{sc}1B, !{sc}1C, !{sc}1D, !{sc}1E, !{sc}1F, !{sc}20,\
   !{sc}21, !{sc}22, !{sc}23, !{sc}24, !{sc}25, !{sc}26, !{sc}27, !{sc}28, !{sc}29, !{sc}2A, !{sc}2B, !{sc}2C, !{sc}2D, !{sc}2E, !{sc}2F
}

processSound3:
{
mov a,#$FF : cmp a,!sound3_initialisationFlag : beq +
call sound3Initialisation
mov y,#$00 : mov a,(!sound3_instructionListPointerSet)+y : mov !sound3_channel0_p_instructionListLow,a : call getSound3ChannelInstructionListPointer : mov !sound3_channel0_p_instructionListHigh,a
call getSound3ChannelInstructionListPointer              : mov !sound3_channel1_p_instructionListLow,a : call getSound3ChannelInstructionListPointer : mov !sound3_channel1_p_instructionListHigh,a
mov a,!sound3_channel0_voiceIndex : call sound3MultiplyBy8 : mov !sound3_channel0_dspIndex,a
mov a,!sound3_channel1_voiceIndex : call sound3MultiplyBy8 : mov !sound3_channel1_dspIndex,a

mov y,#$00
mov !sound3_channel0_i_instructionList,y
mov !sound3_channel1_i_instructionList,y

mov y,#$01
mov !sound3_channel0_instructionTimer,y
mov !sound3_channel1_instructionTimer,y

+
mov x,#$00+!sound1_n_channels+!sound2_n_channels : mov !i_globalChannel,x : call processSoundChannel
mov x,#$01+!sound1_n_channels+!sound2_n_channels : mov !i_globalChannel,x : call processSoundChannel

ret
}

resetSound3Channel0: : mov x,#$00+!sound1_n_channels+!sound2_n_channels : mov !i_globalChannel,x : jmp resetSoundChannel
resetSound3Channel1: : mov x,#$01+!sound1_n_channels+!sound2_n_channels : mov !i_globalChannel,x : jmp resetSoundChannel

; Sound 3 channel variable pointers
{
sound3ChannelVoiceBitsets:
dw !sound3_channel0_voiceBitset, !sound3_channel1_voiceBitset

sound3ChannelVoiceMasks:
dw !sound3_channel0_voiceMask, !sound3_channel1_voiceMask

sound3ChannelVoiceIndices:
dw !sound3_channel0_voiceIndex, !sound3_channel1_voiceIndex
}

sound3Initialisation:
{
mov a,#$09 : mov !sound3_voiceId,a
mov a,!enableSoundEffectVoices : mov !sound3_remainingEnabledSoundVoices,a
mov a,#$FF : mov !sound3_initialisationFlag,a
mov a,#$00
mov !sound3_2i_channel,a
mov !sound3_i_channel,a
mov !sound3_channel0_voiceBitset,a
mov !sound3_channel1_voiceBitset,a
mov !sound3_channel0_voiceIndex,a
mov !sound3_channel1_voiceIndex,a
mov a,#$FF
mov !sound3_channel0_voiceMask,a
mov !sound3_channel1_voiceMask,a
mov !sound3_channel0_disableByte,a
mov !sound3_channel1_disableByte,a

.loop
dec !sound3_voiceId : beq .ret
asl !sound3_remainingEnabledSoundVoices : bcs .loop
mov a,#$00 : cmp a,!sound3_n_voices : beq .ret
dec !sound3_n_voices
mov a,#$00 : mov x,!sound3_i_channel : mov !sound3_channel0_disableByte+x,a
inc !sound3_i_channel
mov a,!sound3_2i_channel : mov x,a
mov a,sound3ChannelVoiceBitsets+x : mov !sound3_p_charVoiceBitset,a
mov a,sound3ChannelVoiceMasks+x   : mov !sound3_p_charVoiceMask,a
mov a,sound3ChannelVoiceIndices+x : mov !sound3_p_charVoiceIndex,a
inc x
mov a,sound3ChannelVoiceBitsets+x : mov !sound3_p_charVoiceBitset+1,a
mov a,sound3ChannelVoiceMasks+x   : mov !sound3_p_charVoiceMask+1,a
mov a,sound3ChannelVoiceIndices+x : mov !sound3_p_charVoiceIndex+1,a
inc !sound3_2i_channel : inc !sound3_2i_channel
mov a,!sound3_voiceId : mov !sound3_i_voice,a : dec !sound3_i_voice : clrc : asl !sound3_i_voice
mov x,!sound3_i_voice : mov y,!sound3_i_channel
mov a,!trackOutputVolumes+x         : mov !sound3_trackOutputVolumeBackups+y,a
mov a,!trackPhaseInversionOptions+x : mov !sound3_trackOutputVolumeBackups+y,a
mov y,#$00 : mov a,!sound3_i_voice : mov (!sound3_p_charVoiceIndex)+y,a
mov a,!sound3_voiceId : call goToJumpTableEntry
dw .voice0, .voice1, .voice2, .voice3, .voice4, .voice5, .voice6, .voice7

.ret
ret

.voice7 : %SetVoice(3, 7) : jmp .loop
.voice6 : %SetVoice(3, 6) : jmp .loop
.voice5 : %SetVoice(3, 5) : jmp .loop
.voice4 : %SetVoice(3, 4) : jmp .loop
.voice3 : %SetVoice(3, 3) : jmp .loop
.voice2 : %SetVoice(3, 2) : jmp .loop
.voice1 : %SetVoice(3, 1) : jmp .loop
.voice0 : %SetVoice(3, 0) : jmp .loop
}

getSound3ChannelInstructionListPointer:
{
inc y : mov a,(!sound3_instructionListPointerSet)+y
ret
}

sound3MultiplyBy8:
{
asl a : asl a : asl a
ret
}

sound3Configurations:
{
.sound1
mov a,#$01 : mov !sound3_n_voices,a
mov a,#$00 : mov !sound3LowHealthPriority,a
mov a,#$01 : mov !sound3Priority,a
ret

.sound2
mov a,#$01 : mov !sound3_n_voices,a
mov a,#$02 : mov !sound3LowHealthPriority,a
ret

.sound3
call nSound3Voices_1_sound3Priority_0 : ret

.sound4
.sound5
call nSound3Voices_2_sound3Priority_0 : ret

.sound6
call nSound3Voices_1_sound3Priority_0 : ret

.sound7
.sound8
call nSound3Voices_2_sound3Priority_1 : ret

.sound9
call nSound3Voices_1_sound3Priority_0 : ret

.soundA
call nSound3Voices_1_sound3Priority_1 : ret

.soundB
call nSound3Voices_2_sound3Priority_0 : ret

.soundC
.soundD
call nSound3Voices_1_sound3Priority_0 : ret

.soundE
call nSound3Voices_2_sound3Priority_1 : ret

.soundF
call nSound3Voices_2_sound3Priority_0 : ret

.sound10
call nSound3Voices_1_sound3Priority_0 : ret

.sound11
call nSound3Voices_1_sound3Priority_0 : ret

.sound12
call nSound3Voices_1_sound3Priority_1 : ret

.sound13
call nSound3Voices_1_sound3Priority_0 : ret

.sound14
.sound15
call nSound3Voices_2_sound3Priority_1 : ret

.sound16
call nSound3Voices_1_sound3Priority_0 : ret

.sound17
call nSound3Voices_1_sound3Priority_0 : ret

.sound18
call nSound3Voices_1_sound3Priority_0 : ret

.sound19
call nSound3Voices_2_sound3Priority_1 : ret

.sound1A
call nSound3Voices_1_sound3Priority_0 : ret

.sound1B
call nSound3Voices_2_sound3Priority_1 : ret

.sound1C
.sound1D
.sound1E
.sound1F
call nSound3Voices_1_sound3Priority_0 : ret

.sound20
.sound21
call nSound3Voices_1_sound3Priority_1 : ret

.sound22
.sound23
call nSound3Voices_1_sound3Priority_0 : ret

.sound24
call nSound3Voices_1_sound3Priority_1 : ret

.sound25
.sound26
.sound27
.sound28
.sound29
.sound2A
.sound2B
call nSound3Voices_1_sound3Priority_0 : ret

.sound2C
call nSound3Voices_2_sound3Priority_1 : ret

.sound2D
call nSound3Voices_1_sound3Priority_0 : ret

.sound2E
call nSound3Voices_2_sound3Priority_1 : ret

.sound2F
call nSound3Voices_1_sound3Priority_0 : ret
}

nSound3Voices_1_sound3Priority_0:
{
mov a,#$01 : mov !sound3_n_voices,a
mov a,#$00 : mov !sound3Priority,a
ret
}

nSound3Voices_2_sound3Priority_0:
{
mov a,#$02 : mov !sound3_n_voices,a
mov a,#$00 : mov !sound3Priority,a
ret
}

nSound3Voices_2_sound3Priority_1:
{
mov a,#$02 : mov !sound3_n_voices,a
mov a,#$01 : mov !sound3Priority,a
ret
}

nSound3Voices_1_sound3Priority_1:
{
mov a,#$01 : mov !sound3_n_voices,a
mov a,#$01 : mov !sound3Priority,a
ret
}

sound3InstructionLists:
{
dw .sound1,  .sound2,  .sound3,  .sound4,  .sound5,  .sound6,  .sound7,  .sound8,  .sound9,  .soundA,  .soundB,  .soundC,  .soundD,  .soundE,  .soundF,  .sound10,\
   .sound11, .sound12, .sound13, .sound14, .sound15, .sound16, .sound17, .sound18, .sound19, .sound1A, .sound1B, .sound1C, .sound1D, .sound1E, .sound1F, .sound20,\
   .sound21, .sound22, .sound23, .sound24, .sound25, .sound26, .sound27, .sound28, .sound29, .sound2A, .sound2B, .sound2C, .sound2D, .sound2E, .sound2F

; Instruction list format:
{
; Commands:
;     F5h dd tt - legato pitch slide with subnote delta = d, target note = t
;     F8h dd tt -        pitch slide with subnote delta = d, target note = t
;     F9h aaaa - voice's ADSR settings = a
;     FBh - repeat
;     FCh - enable noise
;     FDh - decrement repeat counter and repeat if non-zero
;     FEh cc - set repeat pointer with repeat counter = c
;     FFh - end

; Otherwise:
;     ii vv pp nn tt
;     i: Instrument index
;     v: Volume
;     p: Panning
;     n: Note. F6h is a tie
;     t: Length
}

; Sound 1: Silence
.sound1
dw ..voice0
..voice0 : db $11,$00,$0A,$BC,$03, $FF

; Sound 2: Low health beep
.sound2
dw ..voice0
..voice0 : db $FE,$00, $15,$90,$0A,$BC,$F0, $FB, $FF

; Sound 3: Speed booster
.sound3
dw .speedBoosterVoice

; Speed booster / Dachora speed booster (sound library 2)
.speedBoosterVoice
db $F5,$E0,$C7, $05,$60,$0A,$98,$12, $F5,$E0,$C7, $05,$70,$0A,$A4,$11, $F5,$E0,$C7, $05,$80,$0A,$B0,$10, $F5,$E0,$C7, $05,$80,$0A,$B4,$08, $F5,$E0,$C7, $05,$80,$0A,$B9,$07, $F5,$E0,$C7, $05,$80,$0A,$BC,$06, $F5,$E0,$C1, $05,$80,$0A,$BC,$06, $F5,$E0,$C7, $05,$80,$0A,$C5,$06,\
   $FE,$00, $05,$60,$0A,$C7,$10, $FB,\
   $FF

; Sound 4: Samus landed hard
.sound4
dw ..voice0, ..voice1
..voice0 : db $03,$90,$0A,$80,$03, $FF
..voice1 : db $03,$A0,$0A,$84,$05, $FF

; Sound 5: Samus landed / wall-jumped
.sound5
dw ..voice0, ..voice1
..voice0 : db $03,$40,$0A,$80,$03, $FF
..voice1 : db $03,$50,$0A,$84,$05, $FF

; Sound 6: Samus' footsteps
.sound6
dw ..voice0
..voice0 : db $09,$80,$0A,$82,$03, $FF

; Sound 7: Door opened
.sound7
dw ..voice0, ..voice1
..voice0 : db $F5,$F0,$A9, $06,$80,$0A,$91,$18, $FF
..voice1 : db $F5,$F0,$A8, $02,$80,$0A,$90,$18, $FF

; Sound 8: Door closed
.sound8
dw ..voice0, ..voice1
..voice0 : db $F5,$F0,$89, $06,$80,$0A,$A1,$15, $FF
..voice1 : db $F5,$F0,$87, $02,$80,$0A,$9F,$15, $FF

; Sound 9: Missile door shot with missile
.sound9
dw ..voice0
..voice0 : db $02,$B0,$0A,$8C,$03, $02,$D0,$0A,$90,$03, $02,$D0,$0A,$8C,$03, $02,$D0,$0A,$90,$03, $FF

; Sound Ah: Enemy frozen
.soundA
dw ..voice0
..voice0 : db $0D,$70,$0C,$A3,$01, $0D,$80,$0C,$A1,$01, $0D,$80,$0C,$9F,$02, $0D,$80,$0C,$9D,$02, $0D,$70,$0C,$9C,$02, $0D,$50,$0C,$9A,$01, $0D,$60,$0C,$97,$01, $0D,$60,$0C,$98,$03, $FF

; Sound Bh: Elevator
.soundB
dw ..voice0, ..voice1
..voice0 : db $FE,$00, $0B,$90,$0A,$80,$70, $FB, $FF
..voice1 : db $FE,$00, $06,$40,$0A,$98,$13, $FB, $FF

; Sound Ch: Stored shinespark
.soundC
dw .storedShinesparkVoice

; Stored shinespark / Dachora stored shinespark (sound library 2)
.storedShinesparkVoice
db $05,$A0,$0A,$C7,$B0, $FF

; Sound Dh: Typewriter stroke - intro
.soundD
dw ..voice0
..voice0 : db $03,$50,$0A,$98,$02, $03,$50,$0A,$98,$02, $FF

; Sound Eh: Gate opening/closing
.soundE
dw ..voice0, ..voice1
..voice0 : db $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $03,$50,$0C,$85,$05, $FF
..voice1 : db $F5,$60,$A9, $06,$90,$0A,$91,$20, $FF

; Sound Fh: Shinespark
.soundF
dw .shinesparkVoice0, .shinesparkVoice1

; Shinespark / Dachora shinespark (sound library 2)
.shinesparkVoice0 : db $01,$00,$0A,$90,$0C, $01,$D0,$0A,$91,$0C, $01,$D0,$0A,$93,$0C, $01,$D0,$0A,$95,$0A, $01,$D0,$0A,$95,$0A, $01,$D0,$0A,$97,$08, $01,$D0,$0A,$97,$08, $01,$D0,$0A,$98,$06, $01,$D0,$0A,$98,$06, $01,$D0,$0A,$9A,$04, $01,$D0,$0A,$9A,$04, $FF
.shinesparkVoice1 : db $F5,$90,$C7, $05,$C0,$0A,$98,$10, $F5,$F0,$C7, $05,$C0,$0A,$F6,$30, $05,$C0,$0A,$C1,$03, $05,$C0,$0A,$C3,$03, $05,$C0,$0A,$C5,$03, $05,$C0,$0A,$C7,$03, $FF

; Sound 10h: Shinespark ended
.sound10
dw .shinesparkEndedVoice

; Shinespark ended / Dachora shinespark ended (sound library 2)
.shinesparkEndedVoice
db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$15, $FF

; Sound 11h:
.sound11
dw ..voice0
..voice0 : db $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$15, $FF

; Sound 12h: (Empty)
.sound12
dw ..voice0
..voice0 : db $FF

; Sound 13h: Mother Brain's projectile hits surface
.sound13
dw ..voice0
..voice0 : db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$25, $FF

; Sound 14h: Gunship elevator activated
.sound14
dw ..voice0, ..voice1
..voice0 : db $06,$00,$0A,$91,$23, $06,$A0,$0A,$91,$18, $F5,$F0,$A9, $06,$A0,$0A,$91,$18, $FF
..voice1 : db $02,$00,$0A,$90,$23, $02,$20,$0A,$90,$18, $F5,$F0,$A8, $02,$20,$0A,$90,$18, $FF

; Sound 15h: Gunship elevator deactivated
.sound15
dw ..voice0, ..voice1
..voice0 : db $F5,$F0,$89, $06,$80,$0A,$A1,$15, $FF
..voice1 : db $F5,$F0,$87, $02,$10,$0A,$9F,$15, $FF

; Sound 16h:
.sound16
dw ..voice0
..voice0 : db $08,$D0,$0A,$A3,$03, $08,$D0,$0A,$8E,$03, $08,$D0,$0A,$8E,$25, $FF

; Sound 17h: Mother Brain's blue rings
.sound17
dw ..voice0
..voice0 : db $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $F5,$F0,$C3, $0B,$90,$0A,$A6,$03, $FF

; Sound 18h: (Empty)
.sound18
dw ..voice0
..voice0 : db $FF

; Sound 19h:
.sound19
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$93,$26, $FF
..voice1 : db $25,$A0,$0A,$8C,$3B, $FF

; Sound 1Ah: (Empty)
.sound1A
dw ..voice0
..voice0 : db $FF

; Sound 1Bh:
.sound1B
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$8E,$30, $25,$D0,$0A,$8E,$30, $25,$D0,$0A,$8E,$40, $FF
..voice1 : db $25,$00,$0A,$A6,$0C, $25,$80,$0A,$98,$30, $25,$80,$0A,$98,$30, $25,$80,$0A,$9A,$10, $25,$80,$0A,$98,$40, $FF

; Sound 1Ch:
.sound1C
dw ..voice0
..voice0 : db $00,$D0,$0A,$9C,$20, $FF

; Sound 1Dh:
.sound1D
dw ..voice0
..voice0 : db $F5,$F0,$B5, $09,$D0,$0A,$93,$08, $F5,$F0,$B5, $09,$D0,$0A,$93,$08, $FF

; Sound 1Eh: Earthquake (Kraid)
.sound1E
dw ..voice0
..voice0 : db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$25, $FF

; Sound 1Fh:
.sound1F
dw ..voice0
..voice0 : db $00,$D0,$0A,$90,$08, $01,$D0,$0A,$8C,$20, $FF

; Sound 20h: (Empty)
.sound20
dw ..voice0
..voice0 : db $FF

; Sound 21h: Ridley whips its tail
.sound21
dw ..voice0
..voice0 : db $07,$D0,$0A,$C7,$10, $FF

; Sound 22h:
.sound22
dw ..voice0
..voice0 : db $09,$B0,$0A,$8C,$05, $0E,$B0,$0A,$91,$05, $09,$B0,$0A,$8C,$05, $0E,$B0,$0A,$91,$05, $09,$B0,$0A,$8C,$05, $0E,$B0,$0A,$91,$05, $FF

; Sound 23h: Baby metroid cry 1
.sound23
dw ..voice0
..voice0 : db $25,$20,$0A,$95,$40, $FF

; Sound 24h: Baby metroid cry - Ceres
.sound24
dw ..voice0
..voice0 : db $24,$20,$0A,$95,$40, $FF

; Sound 25h: Silence (clear speed booster / elevator sound)
.sound25
dw ..voice0
..voice0 : db $07,$00,$0A,$C7,$03, $FF

; Sound 26h: Baby metroid cry 2
.sound26
dw ..voice0
..voice0 : db $25,$20,$0A,$92,$09, $25,$30,$0A,$92,$40, $FF

; Sound 27h: Baby metroid cry 3
.sound27
dw ..voice0
..voice0 : db $25,$30,$0A,$91,$40, $FF

; Sound 28h:
.sound28
dw ..voice0
..voice0 : db $00,$D0,$0A,$91,$08, $00,$D0,$0A,$91,$08, $00,$D0,$0A,$91,$08, $00,$D0,$0A,$91,$08, $00,$D0,$0A,$91,$08, $00,$D0,$0A,$91,$08, $FF

; Sound 29h: Phantoon related
.sound29
dw ..voice0
..voice0 : db $00,$D0,$0A,$91,$06, $00,$D0,$0A,$91,$06, $00,$D0,$0A,$91,$06, $00,$D0,$0A,$91,$06, $00,$D0,$0A,$91,$06, $FF

; Sound 2Ah: Pause menu ambient beep
.sound2A
dw ..voice0
..voice0 : db $0B,$20,$0A,$C7,$03, $0B,$20,$0A,$C7,$03, $0B,$10,$0A,$C7,$03, $FF

; Sound 2Bh:
.sound2B
dw ..voice0
..voice0 : db $FE,$00, $05,$60,$0A,$C7,$10, $FB, $FF

; Sound 2Ch: Ceres door opening
.sound2C
dw ..voice0, ..voice1
..voice0 : db $F5,$F0,$A9, $06,$70,$0A,$91,$18, $FF
..voice1 : db $F5,$F0,$A4, $06,$70,$0A,$8C,$18, $FF

; Sound 2Dh: Gaining/losing incremental health
.sound2D
dw ..voice0
..voice0 : db $06,$70,$0A,$A8,$01, $06,$00,$0A,$A8,$01, $06,$70,$0A,$A8,$01, $06,$00,$0A,$A8,$01, $06,$70,$0A,$A8,$01, $06,$00,$0A,$A8,$01, $06,$70,$0A,$A8,$01, $06,$00,$0A,$A8,$01, $FF

; Sound 2Eh: Mother Brain's glass shattering
.sound2E
dw ..voice0, ..voice1
..voice0 : db $08,$D0,$0A,$94,$59, $FF
..voice1 : db $25,$D0,$0A,$98,$10, $25,$D0,$0A,$93,$16, $25,$90,$0A,$8F,$15, $FF

; Sound 2Fh: (Empty)
.sound2F
dw ..voice0
..voice0 : db $FF
}
