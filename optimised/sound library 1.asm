; $1EE4
goToProcessSound1:
{
jmp processSound1
}

; $1EE7
handleCpuIo1:
{
mov y,!cpuIo1_read_prev
mov a,!cpuIo1_read : mov !cpuIo1_read_prev,a
mov !cpuIo1_write,a
cmp y,!cpuIo1_read : bne .branch_change

.branch_noChange
mov a,!sound1 : bne goToProcessSound1
ret

.branch_change
cmp a,#$00 : beq .branch_noChange
mov a,!cpuIo1_read
cmp a,#$02 : beq +
cmp a,#$01 : beq +
mov a,!sound1Priority : bne .branch_noChange

+
mov a,!sound1 : beq +
mov a,#$00 : mov !sound1_enabledVoices,a
call resetSound1Channel0
call resetSound1Channel1
call resetSound1Channel2
call resetSound1Channel3

+
mov a,#$00
mov !sound1_channel0_legatoFlag,a
mov !sound1_channel1_legatoFlag,a
mov !sound1_channel2_legatoFlag,a
mov !sound1_channel3_legatoFlag,a
mov a,!cpuIo1_write : dec a : asl a : mov !i_sound1,a
mov x,!i_sound1 : mov a,sound1InstructionLists+x : mov !sound1_instructionListPointerSet,a : inc x : mov a,sound1InstructionLists+x : mov !sound1_instructionListPointerSet+1,a
mov a,!cpuIo1_write : mov !sound1,a
call goToJumpTableEntry

!sc = sound1Configurations_sound ; Shorthand for the `soundN` sublabels within the sound1Configurations label
dw !{sc}1,  !{sc}2,  !{sc}3,  !{sc}4,  !{sc}5,  !{sc}6,  !{sc}7,  !{sc}8,  !{sc}9,  !{sc}A,  !{sc}B,  !{sc}C,  !{sc}D,  !{sc}E,  !{sc}F,  !{sc}10,\
   !{sc}11, !{sc}12, !{sc}13, !{sc}14, !{sc}15, !{sc}16, !{sc}17, !{sc}18, !{sc}19, !{sc}1A, !{sc}1B, !{sc}1C, !{sc}1D, !{sc}1E, !{sc}1F, !{sc}20,\
   !{sc}21, !{sc}22, !{sc}23, !{sc}24, !{sc}25, !{sc}26, !{sc}27, !{sc}28, !{sc}29, !{sc}2A, !{sc}2B, !{sc}2C, !{sc}2D, !{sc}2E, !{sc}2F, !{sc}30,\
   !{sc}31, !{sc}32, !{sc}33, !{sc}34, !{sc}35, !{sc}36, !{sc}37, !{sc}38, !{sc}39, !{sc}3A, !{sc}3B, !{sc}3C, !{sc}3D, !{sc}3E, !{sc}3F, !{sc}40,\
   !{sc}41, !{sc}42
}

; $1FD1
processSound1:
{
mov a,#$FF : cmp a,!sound1_initialisationFlag : beq +
call sound1Initialisation
mov y,#$00 : mov a,(!sound1_instructionListPointerSet)+y : mov !sound1_channel0_p_instructionList,a : call getSound1ChannelInstructionListPointer : mov !sound1_channel0_p_instructionList+1,a
call getSound1ChannelInstructionListPointer              : mov !sound1_channel1_p_instructionList,a : call getSound1ChannelInstructionListPointer : mov !sound1_channel1_p_instructionList+1,a
call getSound1ChannelInstructionListPointer              : mov !sound1_channel2_p_instructionList,a : call getSound1ChannelInstructionListPointer : mov !sound1_channel2_p_instructionList+1,a
call getSound1ChannelInstructionListPointer              : mov !sound1_channel3_p_instructionList,a : call getSound1ChannelInstructionListPointer : mov !sound1_channel3_p_instructionList+1,a
mov a,!sound1_channel0_voiceIndex : call sound1MultiplyBy8 : mov !sound1_channel0_dspIndex,a
mov a,!sound1_channel1_voiceIndex : call sound1MultiplyBy8 : mov !sound1_channel1_dspIndex,a
mov a,!sound1_channel2_voiceIndex : call sound1MultiplyBy8 : mov !sound1_channel2_dspIndex,a
mov a,!sound1_channel3_voiceIndex : call sound1MultiplyBy8 : mov !sound1_channel3_dspIndex,a

mov y,#$00
mov !sound1_channel0_i_instructionList,y
mov !sound1_channel1_i_instructionList,y
mov !sound1_channel2_i_instructionList,y
mov !sound1_channel3_i_instructionList,y

mov y,#$01
mov !sound1_channel0_instructionTimer,y
mov !sound1_channel1_instructionTimer,y
mov !sound1_channel2_instructionTimer,y
mov !sound1_channel3_instructionTimer,y

+
%ProcessSoundChannel(1, 0, resetSound1Channel0, getNextSound1Channel0DataByte, 0, 1)
%ProcessSoundChannel(1, 1, resetSound1Channel1, getNextSound1Channel1DataByte, 6, 0)
%ProcessSoundChannel(1, 2, resetSound1Channel2, getNextSound1Channel2DataByte, 6, 0)
%ProcessSoundChannel(1, 3, resetSound1Channel3, getNextSound1Channel3DataByte, 5, 0)

ret
}

; $2732
resetSound1Channel0: : %ResetSoundChannel(1, 0) : jmp resetSound1IfNoEnabledVoices

; $2775
resetSound1Channel1: : %ResetSoundChannel(1, 1) : jmp resetSound1IfNoEnabledVoices

; $27B8
resetSound1Channel2: : %ResetSoundChannel(1, 2) : jmp resetSound1IfNoEnabledVoices

; $27FB
resetSound1Channel3: : %ResetSoundChannel(1, 3) : jmp resetSound1IfNoEnabledVoices

; $283E
resetSound1IfNoEnabledVoices:
{
mov a,!sound1_enabledVoices : bne +
mov a,#$00
mov !sound1,a
mov !sound1Priority,a
mov !sound1_initialisationFlag,a

+
ret
}

; $284F
getNextSound1Channel0DataByte:
{
mov y,!sound1_channel0_i_instructionList : mov a,(!sound1_channel0_p_instructionList)+y : inc !sound1_channel0_i_instructionList
ret
}

; $2858
getNextSound1Channel1DataByte:
{
mov y,!sound1_channel1_i_instructionList : mov a,(!sound1_channel1_p_instructionList)+y : inc !sound1_channel1_i_instructionList
ret
}

; $2861
getNextSound1Channel2DataByte:
{
mov y,!sound1_channel2_i_instructionList : mov a,(!sound1_channel2_p_instructionList)+y : inc !sound1_channel2_i_instructionList
ret
}

; $286A
getNextSound1Channel3DataByte:
{
mov y,!sound1_channel3_i_instructionList : mov a,(!sound1_channel3_p_instructionList)+y : inc !sound1_channel3_i_instructionList
ret
}

; $2873
; Unused rets
ret
ret

; $2875
goToJumpTableEntry:
{
cmp a,#$01 : beq .branch_pointlessSpecialCase
dec a : asl a : mov y,a

.branch_continue
pop a : mov !p_return_word,a : pop a : mov !p_return_word+1,a
mov a,(!p_return)+y : mov x,a : inc y : mov a,(!p_return)+y : mov !p_return_word+1,a : mov !p_return_word,x
mov x,#$00 : jmp (!p_return_word+x)

.branch_pointlessSpecialCase
mov y,#$00
jmp .branch_continue
}

; $289A
; Sound 1 channel variable pointers
{
; $289A
sound1ChannelVoiceBitsets:
dw !sound1_channel0_voiceBitset, !sound1_channel1_voiceBitset, !sound1_channel2_voiceBitset, !sound1_channel3_voiceBitset

; $28A2
sound1ChannelVoiceMasks:
dw !sound1_channel0_voiceMask, !sound1_channel1_voiceMask, !sound1_channel2_voiceMask, !sound1_channel3_voiceMask

; $28AA
sound1ChannelVoiceIndices:
dw !sound1_channel0_voiceIndex, !sound1_channel1_voiceIndex, !sound1_channel2_voiceIndex, !sound1_channel3_voiceIndex
}

; $28B2
sound1Initialisation:
{
mov a,#$09 : mov !sound1_voiceId,a
mov a,!enableSoundEffectVoices : mov !sound1_remainingEnabledSoundVoices,a
mov a,#$FF : mov !sound1_initialisationFlag,a
mov a,#$00
mov !sound1_2i_channel,a
mov !sound1_i_channel,a
mov !sound1_channel0_voiceBitset,a
mov !sound1_channel1_voiceBitset,a
mov !sound1_channel2_voiceBitset,a
mov !sound1_channel3_voiceBitset,a
mov !sound1_channel0_voiceIndex,a
mov !sound1_channel1_voiceIndex,a
mov !sound1_channel2_voiceIndex,a
mov !sound1_channel3_voiceIndex,a
mov a,#$FF
mov !sound1_channel0_voiceMask,a
mov !sound1_channel1_voiceMask,a
mov !sound1_channel2_voiceMask,a
mov !sound1_channel3_voiceMask,a
mov !sound1_channel0_disableByte,a
mov !sound1_channel1_disableByte,a
mov !sound1_channel2_disableByte,a
mov !sound1_channel3_disableByte,a

.loop
dec !sound1_voiceId : beq .ret
asl !sound1_remainingEnabledSoundVoices : bcs .loop
mov a,#$00 : cmp a,!sound1_n_voices : beq .ret
dec !sound1_n_voices
mov a,#$00 : mov x,!sound1_i_channel : mov !sound1_channel0_disableByte+x,a
inc !sound1_i_channel
mov a,!sound1_2i_channel : mov x,a : mov y,a
mov a,sound1ChannelVoiceBitsets+x : mov !sound1_p_charVoiceBitset,a
mov a,sound1ChannelVoiceMasks+x   : mov !sound1_p_charVoiceMask,a
mov a,sound1ChannelVoiceIndices+x : mov !sound1_p_charVoiceIndex,a
inc x
mov a,sound1ChannelVoiceBitsets+x : mov !sound1_p_charVoiceBitset+1,a
mov a,sound1ChannelVoiceMasks+x   : mov !sound1_p_charVoiceMask+1,a
mov a,sound1ChannelVoiceIndices+x : mov !sound1_p_charVoiceIndex+1,a
inc !sound1_2i_channel : inc !sound1_2i_channel
mov a,!sound1_voiceId : mov !sound1_i_voice,a : dec !sound1_i_voice : clrc : asl !sound1_i_voice
mov x,!sound1_i_voice : mov a,!trackOutputVolumes+x : mov !sound1_channel0_trackOutputVolumeBackup+y,a
inc y : mov a,!trackPhaseInversionOptions+x : mov !sound1_channel0_trackOutputVolumeBackup+y,a
mov y,#$00 : mov a,!sound1_i_voice : mov (!sound1_p_charVoiceIndex)+y,a
mov a,!sound1_voiceId : call goToJumpTableEntry
dw .voice0, .voice1, .voice2, .voice3, .voice4, .voice5, .voice6, .voice7

.ret
ret

.voice7 : %SetVoice(1, 7) : jmp .loop
.voice6 : %SetVoice(1, 6) : jmp .loop
.voice5 : %SetVoice(1, 5) : jmp .loop
.voice4 : %SetVoice(1, 4) : jmp .loop
.voice3 : %SetVoice(1, 3) : jmp .loop
.voice2 : %SetVoice(1, 2) : jmp .loop
.voice1 : %SetVoice(1, 1) : jmp .loop
.voice0 : %SetVoice(1, 0) : jmp .loop
}

; $2A57
getSound1ChannelInstructionListPointer:
{
inc y : mov a,(!sound1_instructionListPointerSet)+y
ret
}

; $2A5B
sound1MultiplyBy8:
{
asl a : asl a : asl a
ret
}

; $2A5F
sound1Configurations:
{
.sound1
call nSound1Voices_4_sound1Priority_0_dup : ret

.sound2
.sound3
.sound4
.sound5
.sound6
.sound7
call nSound1Voices_1_sound1Priority_0 : ret

.sound8
call nSound1Voices_2_sound1Priority_0
ret

.sound9
.soundA
.soundB
.soundC
.soundD
.soundE
.soundF
.sound10
.sound11
.sound12
.sound13
.sound14
.sound15
.sound16
.sound17
.sound18
.sound19
.sound1A
.sound1B
.sound1C
.sound1D
.sound1E
.sound1F
.sound20
.sound21
.sound22
.sound23
call nSound1Voices_1_sound1Priority_0
ret

.sound24
call nSound1Voices_2_sound1Priority_0
ret

.sound25
.sound26
call nSound1Voices_1_sound1Priority_0
ret

.sound27
call nSound1Voices_2_sound1Priority_0
ret

.sound28
.sound29
.sound2A
.sound2B
call nSound1Voices_1_sound1Priority_0
ret

.sound2C
call nSound1Voices_1_sound1Priority_0
ret

.sound2D
call nSound1Voices_1_sound1Priority_0
ret

.sound2E
call nSound1Voices_4_sound1Priority_0
ret

.sound2F
.sound30
.sound31
.sound32
call nSound1Voices_1_sound1Priority_0
ret

.sound33
call nSound1Voices_2_sound1Priority_0
ret

.sound34
call nSound1Voices_1_sound1Priority_0
ret

.sound35
call nSound1Voices_1_sound1Priority_1
ret

.sound36
.sound37
.sound38
.sound39
.sound3A
.sound3B
.sound3C
.sound3D
.sound3E
.sound3F
call nSound1Voices_1_sound1Priority_0
ret

.sound40
call nSound1Voices_3_sound1Priority_1
ret

.sound41
call nSound1Voices_2_sound1Priority_0
ret

.sound42
call nSound1Voices_2_sound1Priority_0 : ret
}

; $2AAB
nSound1Voices_1_sound1Priority_0:
{
mov a,#$01 : mov !sound1_n_voices,a
mov a,#$00 : mov !sound1Priority,a
ret
}

; $2AB6
nSound1Voices_1_sound1Priority_1:
{
mov a,#$01 : mov !sound1_n_voices,a
mov a,#$01 : mov !sound1Priority,a
ret
}

; $2AC1
nSound1Voices_2_sound1Priority_0:
{
mov a,#$02 : mov !sound1_n_voices,a
mov a,#$00 : mov !sound1Priority,a
ret
}

; $2ACC
nSound1Voices_3_sound1Priority_1:
{
mov a,#$03 : mov !sound1_n_voices,a
mov a,#$01 : mov !sound1Priority,a
ret
}

; $2AD7
nSound1Voices_4_sound1Priority_0:
{
mov a,#$04 : mov !sound1_n_voices,a
mov a,#$00 : mov !sound1Priority,a
ret
}

; $2AE2
nSound1Voices_4_sound1Priority_0_dup:
{
mov a,#$04 : mov !sound1_n_voices,a
mov a,#$00 : mov !sound1Priority,a
ret
}

; $2AED
sound1InstructionLists:
{
dw .sound1,  .sound2,  .sound3,  .sound4,  .sound5,  .sound6,  .sound7,  .sound8,  .sound9,  .soundA,  .soundB,  .soundC,  .soundD,  .soundE,  .soundF,  .sound10,\
   .sound11, .sound12, .sound13, .sound14, .sound15, .sound16, .sound17, .sound18, .sound19, .sound1A, .sound1B, .sound1C, .sound1D, .sound1E, .sound1F, .sound20,\
   .sound21, .sound22, .sound23, .sound24, .sound25, .sound26, .sound27, .sound28, .sound29, .sound2A, .sound2B, .sound2C, .sound2D, .sound2E, .sound2F, .sound30,\
   .sound31, .sound32, .sound33, .sound34, .sound35, .sound36, .sound37, .sound38, .sound39, .sound3A, .sound3B, .sound3C, .sound3D, .sound3E, .sound3F, .sound40,\
   .sound41, .sound42

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

; Sound 1: Power bomb explosion
.sound1
dw ..voice0, ..voice1, ..voice2, ..voice3
..voice0 : db $F5,$B0,$C7, $05,$D0,$0A,$98,$46, $FF
..voice1 : db $F5,$A0,$C7, $09,$D0,$0F,$80,$50, $F5,$50,$80, $09,$D0,$0A,$AB,$46, $FF
..voice2 : db $09,$D0,$0F,$87,$10, $F5,$B0,$C7, $05,$D0,$0F,$80,$60, $FF
..voice3 : db $09,$D0,$05,$82,$30, $F5,$A0,$80, $05,$D0,$05,$C7,$60, $FF

; Sound 2: Silence
.sound2
dw ..voice0
..voice0 : db $15,$00,$0A,$BC,$03, $FF

; Sound 3: Missile
.sound3
dw ..voice0
..voice0 : db $00,$D8,$0A,$95,$08, $01,$D8,$0A,$8B,$30, $FF

; Sound 4: Super missile
.sound4
dw ..voice0
..voice0 : db $00,$D0,$0A,$95,$08, $01,$D0,$0A,$90,$30, $FF

; Sound 5: Grapple start
.sound5
dw ..voice0
..voice0 : db $01,$80,$0A,$9D,$10, $02,$50,$0A,$93,$07, $02,$50,$0A,$93,$03, $02,$50,$0A,$93,$05, $02,$50,$0A,$93,$08, $02,$50,$0A,$93,$04, $02,$50,$0A,$93,$06, $02,$50,$0A,$93,$04, $FF

; Sound 6: Grappling
.sound6
dw ..voice0
..voice0 : db $0D,$50,$0A,$80,$03, $0D,$50,$0A,$85,$04,\
              $FE,$00, $02,$50,$0A,$93,$07, $02,$50,$0A,$93,$03, $02,$50,$0A,$93,$05, $02,$50,$0A,$93,$08, $02,$50,$0A,$93,$04, $02,$50,$0A,$93,$06, $02,$50,$0A,$93,$04, $FB,\
              $FF

; Sound 7: Grapple end
.sound7
dw ..voice0
..voice0 : db $02,$50,$0A,$93,$05, $FF

; Sound 8: Charging beam
.sound8
dw ..voice0, ..voice1
..voice0 : db $05,$00,$0A,$B4,$15, $F5,$30,$C7, $05,$50,$0A,$B7,$25,\
              $FE,$00, $07,$60,$0A,$C7,$30, $FB,\
              $FF
..voice1 : db $02,$00,$0A,$9C,$07, $02,$10,$0A,$9C,$03, $02,$00,$0A,$9C,$05, $02,$20,$0A,$9C,$08

; Shared by charging beam and resume charging beam
.resumeChargingBeamVoice
db $02,$20,$0A,$9C,$04, $02,$30,$0A,$9C,$06, $02,$00,$0A,$9C,$04, $02,$30,$0A,$9C,$03, $02,$30,$0A,$9C,$07, $02,$00,$0A,$9C,$0A, $02,$30,$0A,$9C,$03, $02,$00,$0A,$9C,$04, $02,$40,$0A,$9C,$03, $02,$40,$0A,$9C,$07, $02,$00,$0A,$9C,$05, $02,$40,$0A,$9C,$06, $02,$40,$0A,$9C,$03, $02,$00,$0A,$9C,$0A, $02,$50,$0A,$9C,$03, $02,$50,$0A,$9C,$03, $02,$60,$0A,$9C,$05, $02,$00,$0A,$9C,$06, $02,$60,$0A,$9C,$07, $02,$00,$0A,$9C,$03, $02,$60,$0A,$9C,$04, $02,$60,$0A,$9C,$03, $02,$00,$0A,$9C,$03,\
   $FE,$00, $02,$40,$0A,$9C,$05, $02,$40,$0A,$9C,$06, $02,$40,$0A,$9C,$07, $02,$40,$0A,$9C,$03, $02,$40,$0A,$9C,$04, $02,$40,$0A,$9C,$03, $02,$40,$0A,$9C,$03, $FB,\
   $FF

; Sound 9: X-ray
.sound9
dw ..voice0
..voice0 : db $F5,$70,$AD, $06,$40,$0A,$A4,$40,\
              $FE,$00, $06,$40,$0A,$AD,$F0, $FB,\
              $FF

; Sound Ah: X-ray end
.soundA
dw ..voice0
..voice0 : db $06,$00,$0A,$AD,$03, $FF

; Sound Bh: Uncharged power beam
.soundB
dw ..voice0
..voice0 : db $04,$90,$0A,$89,$03, $04,$90,$0A,$84,$0E, $FF

; Sound Ch: Uncharged ice beam
.soundC
dw .weakUnchargedIceVoice

; Uncharged ice / ice + wave beam
.weakUnchargedIceVoice
db $04,$B0,$0A,$8B,$03, $04,$B0,$0A,$89,$07, $F5,$90,$C7, $10,$90,$0A,$BC,$0A, $10,$60,$0A,$C3,$06, $10,$30,$0A,$C7,$03, $10,$20,$0A,$C7,$03, $FF

; Sound Dh: Uncharged wave beam
.soundD
dw ..voice0
..voice0 : db $04,$90,$0A,$89,$03, $04,$70,$0A,$84,$0B, $04,$30,$0A,$84,$08, $FF

; Sound Eh: Uncharged ice + wave beam
.soundE
dw .weakUnchargedIceVoice

; Sound Fh: Uncharged spazer beam
.soundF
dw .unchargedSpazerVoice

; Uncharged spazer / spazer + wave beam
.unchargedSpazerVoice
db $00,$D0,$0A,$98,$0C, $04,$C0,$0A,$80,$10, $04,$30,$0A,$80,$08, $04,$10,$0A,$80,$06, $FF

; Sound 10h: Uncharged spazer + ice beam
.sound10
dw .strongUnchargedIceVoice

; Uncharged spazer + ice / spazer + ice + wave / plasma + ice / plasma + ice + wave beam
.strongUnchargedIceVoice
db $00,$D0,$0A,$98,$0C, $F5,$90,$C7, $10,$90,$0A,$BC,$0A, $10,$60,$0A,$C3,$06, $10,$30,$0A,$C7,$03, $10,$20,$0A,$C7,$03, $FF

; Sound 11h: Uncharged spazer + ice + wave beam
.sound11
dw .strongUnchargedIceVoice

; Sound 12h: Uncharged spazer + wave beam
.sound12
dw .unchargedSpazerVoice

; Sound 13h: Uncharged plasma beam
.sound13
dw .unchargedPlasmaVoice

; Uncharged plasma / plasma + wave beam
.unchargedPlasmaVoice
db $00,$D0,$0A,$98,$0C, $04,$B0,$0A,$80,$13, $FF

; Sound 14h: Uncharged plasma + ice beam
.sound14
dw .strongUnchargedIceVoice

; Sound 15h: Uncharged plasma + ice + wave beam
.sound15
dw .strongUnchargedIceVoice

; Sound 16h: Uncharged plasma + wave beam
.sound16
dw .unchargedPlasmaVoice

; Sound 17h: Charged power beam
.sound17
dw ..voice0
..voice0 : db $04,$D0,$0A,$84,$05, $04,$D0,$0A,$80,$0C, $02,$80,$0A,$98,$03, $02,$60,$0A,$98,$03, $02,$50,$0A,$98,$03, $FF

; Sound 18h: Charged ice beam
.sound18
dw .chargedIceVoice

; Charged ice / ice + wave / spazer + ice / spazer + ice + wave / plasma + ice / plasma + ice + wave beam
.chargedIceVoice
db $00,$E0,$0A,$98,$0C, $F5,$B0,$C7, $10,$E0,$0A,$BC,$0A, $10,$70,$0A,$C3,$06, $10,$30,$0A,$C7,$03, $10,$20,$0A,$C7,$03, $FF

; Sound 19h: Charged wave beam
.sound19
dw ..voice0
..voice0 : db $04,$E0,$0A,$84,$03, $04,$E0,$0A,$80,$10, $04,$50,$0A,$80,$04, $04,$30,$0A,$80,$09, $FF

; Sound 1Ah: Charged ice + wave beam
.sound1A
dw .chargedIceVoice

; Sound 1Bh: Charged spazer beam
.sound1B
dw .chargedSpazerVoice

; Charged spazer / spazer + wave beam
.chargedSpazerVoice
db $00,$D0,$0A,$95,$08, $04,$D0,$0A,$80,$0F, $04,$80,$0A,$80,$0D, $04,$20,$0A,$80,$0A, $FF

; Sound 1Ch: Charged spazer + ice beam
.sound1C
dw .chargedIceVoice

; Sound 1Dh: Charged spazer + ice + wave beam
.sound1D
dw .chargedIceVoice

; Sound 1Eh: Charged spazer + wave beam
.sound1E
dw .chargedSpazerVoice

; Sound 1Fh: Charged plasma beam / hyper beam
.sound1F
dw .chargedPlasmaVoice

; Charged plasma / hyper / plasma + wave beam
.chargedPlasmaVoice
db $00,$D0,$0A,$98,$0E, $04,$D0,$0A,$80,$10, $04,$70,$0A,$80,$10, $04,$30,$0A,$80,$10, $FF

; Sound 20h: Charged plasma + ice beam
.sound20
dw .chargedIceVoice

; Sound 21h: Charged plasma + ice + wave beam
.sound21
dw .chargedIceVoice

; Sound 22h: Charged plasma + wave beam
.sound22
dw .chargedPlasmaVoice

; Sound 23h: Ice SBA
.sound23
dw ..voice0
..voice0 : db $FE,$00, $10,$50,$0A,$C0,$03, $10,$50,$0A,$C1,$03, $10,$60,$0A,$C3,$03, $10,$60,$0A,$C5,$03, $10,$70,$0A,$C7,$03, $10,$60,$0A,$C5,$03, $10,$50,$0A,$C3,$03, $10,$50,$0A,$C1,$03, $FB, $FF

; Sound 24h: Ice SBA end
.sound24
dw ..voice0, ..voice1
..voice0 : db $10,$D0,$0A,$BC,$0A, $10,$70,$0A,$C3,$06, $10,$30,$0A,$C7,$03, $10,$20,$0A,$C7,$03, $10,$50,$0A,$C3,$06, $10,$40,$0A,$C7,$03, $10,$40,$0A,$C7,$03, $10,$30,$0A,$C3,$06, $10,$20,$0A,$C7,$03, $10,$20,$0A,$C7,$03, $FF
..voice1 : db $04,$D0,$0A,$80,$10, $04,$70,$0A,$80,$10, $04,$30,$0A,$80,$10, $FF

; Sound 25h: Spazer SBA
.sound25
dw ..voice0
..voice0 : db $04,$D0,$0A,$80,$10, $04,$70,$0A,$80,$10, $04,$30,$0A,$80,$02, $04,$D0,$0A,$80,$10, $04,$70,$0A,$80,$10, $04,$30,$0A,$80,$10, $FF

; Sound 26h: Spazer SBA end
.sound26
dw ..voice0
..voice0 : db $04,$D0,$0A,$80,$10, $04,$70,$0A,$80,$04, $04,$30,$0A,$80,$02, $04,$30,$0A,$80,$06, $04,$30,$0A,$80,$06, $04,$70,$0A,$80,$07, $04,$70,$0A,$80,$07, $FF

; Sound 27h: Plasma SBA
.sound27
dw ..voice0, ..voice1
..voice0 : db $F5,$30,$C7, $07,$90,$0A,$B7,$25, $F5,$30,$B7, $07,$90,$0A,$F6,$25, $F5,$B0,$C7, $07,$90,$0A,$F6,$25, $FF
..voice1 : db $F5,$30,$C7, $05,$90,$0A,$B7,$27, $F5,$30,$B7, $05,$90,$0A,$F6,$27, $F5,$B0,$C7, $05,$90,$0A,$F6,$27, $FF

; Sound 28h: Wave SBA
.sound28
dw ..voice0
..voice0 : db $F5,$30,$C7, $05,$50,$0A,$B7,$25, $FF

; Sound 29h: Wave SBA end
.sound29
dw ..voice0
..voice0 : db $05,$00,$0A,$B7,$03, $FF

; Sound 2Ah: Selected save file
.sound2A
dw ..voice0
..voice0 : db $07,$90,$0A,$C5,$12, $FF

; Sound 2Bh: (Empty)
.sound2B
dw ..voice0
..voice0 : db $FF

; Sound 2Ch: (Empty)
.sound2C
dw ..voice0
..voice0 : db $FF

; Sound 2Dh: (Empty)
.sound2D
dw ..voice0
..voice0 : db $FF

; Sound 2Eh: Saving
.sound2E
dw ..voice0, ..voice1, ..voice2, ..voice3
..voice0 : db $F5,$F0,$B1, $06,$45,$0A,$99,$19, $06,$45,$0A,$B1,$80, $F5,$F0,$99, $06,$45,$0A,$B1,$19, $FF
..voice1 : db $F5,$F0,$A7, $06,$45,$0A,$8F,$19, $06,$45,$0A,$A7,$80, $F5,$F0,$8F, $06,$45,$0A,$A7,$19, $FF
..voice2 : db $F5,$F0,$A0, $06,$45,$0A,$88,$19, $06,$45,$0A,$A0,$80, $F5,$F0,$88, $06,$45,$0A,$A0,$19, $FF
..voice3 : db $F5,$F0,$98, $06,$45,$0A,$80,$19, $06,$45,$0A,$98,$80, $F5,$F0,$80, $06,$45,$0A,$98,$19, $FF

; Sound 2Fh: Underwater space jump (without gravity suit)
.sound2F
dw ..voice0
..voice0 : db $07,$80,$0A,$C7,$10, $FF

; Sound 30h: Resumed spin jump
.sound30
dw ..voice0
..voice0 : db $FE,$00, $07,$80,$0A,$C7,$10, $FB, $FF

; Sound 31h: Spin jump
.sound31
dw ..voice0
..voice0 : db $07,$30,$0A,$C5,$10, $07,$40,$0A,$C6,$10, $07,$50,$0A,$C7,$10,\
              $FE,$00, $07,$80,$0A,$C7,$10, $FB,\
              $FF

; Sound 32h: Spin jump end
.sound32
dw ..voice0
..voice0 : db $0A,$00,$0A,$87,$03, $FF

; Sound 33h: Screw attack
.sound33
dw ..voice0, ..voice1
..voice0 : db $07,$30,$0A,$C7,$04, $07,$40,$0A,$C7,$05, $07,$50,$0A,$C7,$06, $07,$60,$0A,$C7,$07, $07,$70,$0A,$C7,$09, $07,$80,$0A,$C7,$0D, $07,$80,$0A,$C7,$0F,\
              $FE,$00, $07,$80,$0A,$C7,$10, $FB,\
              $FF
..voice1 : db $F5,$E0,$BC, $05,$60,$0A,$98,$0E, $F5,$E0,$BC, $05,$70,$0A,$A4,$08, $F5,$E0,$BC, $05,$80,$0A,$B0,$06,\
              $FE,$00, $05,$80,$0A,$BC,$03, $05,$80,$0A,$C4,$03, $05,$80,$0A,$C6,$03, $FB,\
              $FF

; Sound 34h: Screw attack end
.sound34
dw ..voice0
..voice0 : db $0A,$00,$0A,$87,$03, $FF

; Sound 35h: Samus damaged
.sound35
dw ..voice0
..voice0 : db $13,$60,$0A,$A4,$10, $13,$10,$0A,$A4,$07, $FF

; Sound 36h: Scrolling map
.sound36
dw ..voice0
..voice0 : db $0C,$60,$0A,$B0,$02, $FF

; Sound 37h: Toggle reserve mode / moved cursor
.sound37
dw ..voice0
..voice0 : db $03,$60,$0A,$9C,$04, $FF

; Sound 38h: Pause menu transition / toggled equipment
.sound38
dw ..voice0
..voice0 : db $F5,$90,$C7, $15,$90,$0A,$B0,$15, $FF

; Sound 39h: Switch HUD item
.sound39
dw ..voice0
..voice0 : db $03,$40,$0A,$9C,$03, $FF

; Sound 3Ah: (Empty)
.sound3A
dw ..voice0
..voice0 : db $FF

; Sound 3Bh: Hexagon map -> square map transition
.sound3B
dw ..voice0
..voice0 : db $05,$90,$0A,$9C,$0B, $F5,$F0,$C2, $05,$90,$0A,$9C,$12, $FF

; Sound 3Ch: Square map -> hexagon map transition
.sound3C
dw ..voice0
..voice0 : db $05,$90,$0A,$9C,$0B, $F5,$F0,$80, $05,$90,$0A,$9C,$12, $FF

; Sound 3Dh: Dud shot
.sound3D
dw ..voice0
..voice0 : db $08,$70,$0A,$99,$03, $08,$70,$0A,$9C,$05, $FF

; Sound 3Eh: Space jump
.sound3E
dw ..voice0
..voice0 : db $07,$30,$0A,$C7,$04, $07,$40,$0A,$C7,$05, $07,$50,$0A,$C7,$06, $07,$60,$0A,$C7,$07, $07,$70,$0A,$C7,$09, $07,$80,$0A,$C7,$0D, $07,$80,$0A,$C7,$0F,\
              $FE,$00, $07,$80,$0A,$C7,$10, $FB,\
              $FF

; Sound 3Fh: Resumed space jump
.sound3F
dw ..voice0
..voice0 : db $FE,$00, $07,$80,$0A,$C7,$10, $FB, $FF

; Sound 40h: Mother Brain's rainbow beam
.sound40
dw ..voice0, ..voice1, ..voice2
..voice0 : db $FE,$00, $23,$D0,$0A,$89,$07, $23,$D0,$0A,$8B,$07, $23,$D0,$0A,$8C,$07, $23,$D0,$0A,$8E,$07, $23,$D0,$0A,$90,$07, $23,$D0,$0A,$91,$07, $23,$D0,$0A,$93,$07, $23,$D0,$0A,$95,$07, $23,$D0,$0A,$97,$07, $FB, $FF
..voice1 : db $FE,$00, $06,$D0,$0A,$BA,$F0, $FB, $FF
..voice2 : db $FE,$00, $06,$D0,$0A,$B3,$F0, $FB, $FF

; Sound 41h: Resume charging beam
.sound41
dw ..voice0, .resumeChargingBeamVoice
..voice0 : db $F5,$70,$C7, $05,$50,$0A,$C0,$03,\
              $FE,$00, $07,$60,$0A,$C7,$30, $FB,\
              $FF

; Sound 42h:
.sound42
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$9C,$20, $FF
..voice1 : db $24,$00,$0A,$9D,$05, $24,$80,$0A,$95,$40, $FF
}
