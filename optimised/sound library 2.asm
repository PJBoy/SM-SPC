; $3154
goToProcessSound2:
{
jmp processSound2
}

; $3157
handleCpuIo2:
{
mov y,!cpuIo2_read_prev
mov a,!cpuIo2_read : mov !cpuIo2_read_prev,a
mov !cpuIo2_write,a
cmp y,!cpuIo2_read : bne .branch_change

.branch_noChange
mov a,!sound2 : bne goToProcessSound2
ret

.branch_change
cmp a,#$00 : beq .branch_noChange
mov a,!cpuIo2_read
cmp a,#$71 : beq +
cmp a,#$7E : beq +
mov a,!sound2Priority : bne .branch_noChange

+
mov a,!sound2 : beq +
mov a,#$00 : mov !sound2_enabledVoices,a
call resetSound2Channel0
call resetSound2Channel1

+
mov a,#$00
mov !sound2_channel0_legatoFlag,a
mov !sound2_channel1_legatoFlag,a
mov a,!cpuIo2_write : dec a : asl a : mov !i_sound2,a
mov x,!i_sound2 : mov a,sound2InstructionLists+x : mov !sound2_instructionListPointerSet,a : inc x : mov a,sound2InstructionLists+x : mov !sound2_instructionListPointerSet+1,a
mov a,!cpuIo2_write : mov !sound2,a
call goToJumpTableEntry

!sc = sound2Configurations_sound ; Shorthand for the `soundN` sublabels within the sound2Configurations label
dw !{sc}1,  !{sc}2,  !{sc}3,  !{sc}4,  !{sc}5,  !{sc}6,  !{sc}7,  !{sc}8,  !{sc}9,  !{sc}A,  !{sc}B,  !{sc}C,  !{sc}D,  !{sc}E,  !{sc}F,  !{sc}10,\
   !{sc}11, !{sc}12, !{sc}13, !{sc}14, !{sc}15, !{sc}16, !{sc}17, !{sc}18, !{sc}19, !{sc}1A, !{sc}1B, !{sc}1C, !{sc}1D, !{sc}1E, !{sc}1F, !{sc}20,\
   !{sc}21, !{sc}22, !{sc}23, !{sc}24, !{sc}25, !{sc}26, !{sc}27, !{sc}28, !{sc}29, !{sc}2A, !{sc}2B, !{sc}2C, !{sc}2D, !{sc}2E, !{sc}2F, !{sc}30,\
   !{sc}31, !{sc}32, !{sc}33, !{sc}34, !{sc}35, !{sc}36, !{sc}37, !{sc}38, !{sc}39, !{sc}3A, !{sc}3B, !{sc}3C, !{sc}3D, !{sc}3E, !{sc}3F, !{sc}40,\
   !{sc}41, !{sc}42, !{sc}43, !{sc}44, !{sc}45, !{sc}46, !{sc}47, !{sc}48, !{sc}49, !{sc}4A, !{sc}4B, !{sc}4C, !{sc}4D, !{sc}4E, !{sc}4F, !{sc}50,\
   !{sc}51, !{sc}52, !{sc}53, !{sc}54, !{sc}55, !{sc}56, !{sc}57, !{sc}58, !{sc}59, !{sc}5A, !{sc}5B, !{sc}5C, !{sc}5D, !{sc}5E, !{sc}5F, !{sc}60,\
   !{sc}61, !{sc}62, !{sc}63, !{sc}64, !{sc}65, !{sc}66, !{sc}67, !{sc}68, !{sc}69, !{sc}6A, !{sc}6B, !{sc}6C, !{sc}6D, !{sc}6E, !{sc}6F, !{sc}70,\
   !{sc}71, !{sc}72, !{sc}73, !{sc}74, !{sc}75, !{sc}76, !{sc}77, !{sc}78, !{sc}79, !{sc}7A, !{sc}7B, !{sc}7C, !{sc}7D, !{sc}7E, !{sc}7F
}

; $32AF
processSound2:
{
mov a,#$FF : cmp a,!sound2_initialisationFlag : beq +
call sound2Initialisation
mov y,#$00 : mov a,(!sound2_instructionListPointerSet)+y : mov !sound2_channel0_p_instructionList,a : call getSound2ChannelInstructionListPointer : mov !sound2_channel0_p_instructionList+1,a
call getSound2ChannelInstructionListPointer              : mov !sound2_channel1_p_instructionList,a : call getSound2ChannelInstructionListPointer : mov !sound2_channel1_p_instructionList+1,a
mov a,!sound2_channel0_voiceIndex : call sound2MultiplyBy8 : mov !sound2_channel0_dspIndex,a
mov a,!sound2_channel1_voiceIndex : call sound2MultiplyBy8 : mov !sound2_channel1_dspIndex,a

mov y,#$00
mov !sound2_channel0_i_instructionList,y
mov !sound2_channel1_i_instructionList,y

mov y,#$01
mov !sound2_channel0_instructionTimer,y
mov !sound2_channel1_instructionTimer,y

+
%ProcessSoundChannel(2, 0, resetSound2Channel0, getNextSound2Channel0DataByte, 6, 1)
%ProcessSoundChannel(2, 1, resetSound2Channel1, getNextSound2Channel1DataByte, 6, 0)

ret
}

; $366D
resetSound2Channel0: : %ResetSoundChannel(2, 0) : jmp resetSound2IfNoEnabledVoices

; $36B0
resetSound2Channel1: : %ResetSoundChannel(2, 1) : jmp resetSound2IfNoEnabledVoices

; $36F3
resetSound2IfNoEnabledVoices:
{
mov a,!sound2_enabledVoices : bne +
mov a,#$00
mov !sound2,a
mov !sound2Priority,a
mov !sound2_initialisationFlag,a

+
ret
}

; $3704
getNextSound2Channel0DataByte:
{
mov y,!sound2_channel0_i_instructionList : mov a,(!sound2_channel0_p_instructionList)+y : inc !sound2_channel0_i_instructionList
ret
}

; $370D
getNextSound2Channel1DataByte:
{
mov y,!sound2_channel1_i_instructionList : mov a,(!sound2_channel1_p_instructionList)+y : inc !sound2_channel1_i_instructionList
ret
}

; $3716
; Sound 2 channel variable pointers
{
; $289A
sound2ChannelVoiceBitsets:
dw !sound2_channel0_voiceBitset, !sound2_channel1_voiceBitset

; $28A2
sound2ChannelVoiceMasks:
dw !sound2_channel0_voiceMask, !sound2_channel1_voiceMask

; $28AA
sound2ChannelVoiceIndices:
dw !sound2_channel0_voiceIndex, !sound2_channel1_voiceIndex
}

; $3722
sound2Initialisation:
{
mov a,#$09 : mov !sound2_voiceId,a
mov a,!enableSoundEffectVoices : mov !sound2_remainingEnabledSoundVoices,a
mov a,#$FF : mov !sound2_initialisationFlag,a
mov a,#$00
mov !sound2_2i_channel,a
mov !sound2_i_channel,a
mov !sound2_channel0_voiceBitset,a
mov !sound2_channel1_voiceBitset,a
mov !sound2_channel0_voiceIndex,a
mov !sound2_channel1_voiceIndex,a
mov a,#$FF
mov !sound2_channel0_voiceMask,a
mov !sound2_channel1_voiceMask,a
mov !sound2_channel0_disableByte,a
mov !sound2_channel1_disableByte,a

.loop
dec !sound2_voiceId : beq .ret
asl !sound2_remainingEnabledSoundVoices : bcs .loop
mov a,#$00 : cmp a,!sound2_n_voices : beq .ret
dec !sound2_n_voices
mov a,#$00 : mov x,!sound2_i_channel : mov !sound2_channel0_disableByte+x,a
inc !sound2_i_channel
mov a,!sound2_2i_channel : mov x,a : mov y,a
mov a,sound2ChannelVoiceBitsets+x : mov !sound2_p_charVoiceBitset,a
mov a,sound2ChannelVoiceMasks+x   : mov !sound2_p_charVoiceMask,a
mov a,sound2ChannelVoiceIndices+x : mov !sound2_p_charVoiceIndex,a
inc x
mov a,sound2ChannelVoiceBitsets+x : mov !sound2_p_charVoiceBitset+1,a
mov a,sound2ChannelVoiceMasks+x   : mov !sound2_p_charVoiceMask+1,a
mov a,sound2ChannelVoiceIndices+x : mov !sound2_p_charVoiceIndex+1,a
inc !sound2_2i_channel : inc !sound2_2i_channel
mov a,!sound2_voiceId : mov !sound2_i_voice,a : dec !sound2_i_voice : clrc : asl !sound2_i_voice
mov x,!sound2_i_voice : mov a,!trackOutputVolumes+x : mov !sound2_channel0_trackOutputVolumeBackup+y,a
inc y : mov a,!trackPhaseInversionOptions+x : mov !sound2_channel0_trackOutputVolumeBackup+y,a
mov y,#$00 : mov a,!sound2_i_voice : mov (!sound2_p_charVoiceIndex)+y,a
mov a,!sound2_voiceId : call goToJumpTableEntry
dw .voice0, .voice1, .voice2, .voice3, .voice4, .voice5, .voice6, .voice7

.ret
ret

.voice7 : %SetVoice(2, 7) : jmp .loop
.voice6 : %SetVoice(2, 6) : jmp .loop
.voice5 : %SetVoice(2, 5) : jmp .loop
.voice4 : %SetVoice(2, 4) : jmp .loop
.voice3 : %SetVoice(2, 3) : jmp .loop
.voice2 : %SetVoice(2, 2) : jmp .loop
.voice1 : %SetVoice(2, 1) : jmp .loop
.voice0 : %SetVoice(2, 0) : jmp .loop
}

; $38AF
getSound2ChannelInstructionListPointer:
{
inc y : mov a,(!sound2_instructionListPointerSet)+y
ret
}

; $38B3
sound2MultiplyBy8:
{
asl a : asl a : asl a
ret
}

; $38B7
sound2Configurations:
{
.sound1
.sound2
.sound3
.sound4
.sound5
call nSound2Voices_1_sound2Priority_1 : ret

.sound6
.sound7
call nSound2Voices_1_sound2Priority_0 : ret

.sound8
call nSound2Voices_1_sound2Priority_0 : ret

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
call nSound2Voices_1_sound2Priority_0 : ret

.sound16
.sound17
call nSound2Voices_1_sound2Priority_1 : ret

.sound18
call nSound2Voices_1_sound2Priority_0 : ret

.sound19
call nSound2Voices_2_sound2Priority_0 : ret

.sound1A
call nSound2Voices_2_sound2Priority_0 : ret

.sound1B
call nSound2Voices_1_sound2Priority_0 : ret

.sound1C
call nSound2Voices_1_sound2Priority_1 : ret

.sound1D
call nSound2Voices_1_sound2Priority_0 : ret

.sound1E
call nSound2Voices_2_sound2Priority_1 : ret

.sound1F
call nSound2Voices_1_sound2Priority_1 : ret

.sound20
.sound21
.sound22
.sound23
.sound24
.sound25
.sound26
call nSound2Voices_1_sound2Priority_0 : ret

.sound27
call nSound2Voices_2_sound2Priority_1 : ret

.sound28
.sound29
.sound2A
.sound2B
call nSound2Voices_1_sound2Priority_0 : ret

.sound2C
call nSound2Voices_2_sound2Priority_1 : ret

.sound2D
call nSound2Voices_1_sound2Priority_1 : ret

.sound2E
call nSound2Voices_2_sound2Priority_1 : ret

.sound2F
.sound30
.sound31
.sound32
.sound33
.sound34
call nSound2Voices_1_sound2Priority_0 : ret

.sound35
call nSound2Voices_1_sound2Priority_1 : ret

.sound36
call nSound2Voices_1_sound2Priority_0 : ret

.sound37
.sound38
call nSound2Voices_2_sound2Priority_0 : ret

.sound39
.sound3A
.sound3B
.sound3C
.sound3D
.sound3E
.sound3F
.sound40
.sound41
.sound42
.sound43
.sound44
.sound45
call nSound2Voices_1_sound2Priority_0 : ret

.sound46
call nSound2Voices_1_sound2Priority_1 : ret

.sound47
.sound48
.sound49
.sound4A
.sound4B
.sound4C
.sound4D
call nSound2Voices_1_sound2Priority_0 : ret

.sound4E
call nSound2Voices_2_sound2Priority_1 : ret

.sound4F
call nSound2Voices_1_sound2Priority_0 : ret

.sound50
.sound51
call nSound2Voices_2_sound2Priority_1 : ret

.sound52
.sound53
call nSound2Voices_1_sound2Priority_0 : ret

.sound54
call nSound2Voices_1_sound2Priority_1 : ret

.sound55
call nSound2Voices_1_sound2Priority_0 : ret

.sound56
call nSound2Voices_2_sound2Priority_0 : ret

.sound57
call nSound2Voices_1_sound2Priority_0 : ret

.sound58
call nSound2Voices_2_sound2Priority_0 : ret

.sound59
call nSound2Voices_2_sound2Priority_1 : ret

.sound5A
call nSound2Voices_2_sound2Priority_0 : ret

.sound5B
.sound5C
.sound5D
.sound5E
.sound5F
.sound60
.sound61
.sound62
call nSound2Voices_1_sound2Priority_0 : ret

.sound63
call nSound2Voices_2_sound2Priority_0 : ret

.sound64
.sound65
.sound66
.sound67
.sound68
.sound69
.sound6A
.sound6B
.sound6C
.sound6D
call nSound2Voices_1_sound2Priority_0 : ret

.sound6E
call nSound2Voices_2_sound2Priority_1 : ret

.sound6F
call nSound2Voices_2_sound2Priority_1 : ret

.sound70
.sound71
call nSound2Voices_1_sound2Priority_0 : ret

.sound72
.sound73
.sound74
call nSound2Voices_2_sound2Priority_1 : ret

.sound75
call nSound2Voices_2_sound2Priority_1 : ret

.sound76
call nSound2Voices_1_sound2Priority_0 : ret

.sound77
call nSound2Voices_2_sound2Priority_1 : ret

.sound78
call nSound2Voices_2_sound2Priority_0 : ret

.sound79
.sound7A
.sound7B
call nSound2Voices_2_sound2Priority_0 : ret

.sound7C
call nSound2Voices_1_sound2Priority_1 : ret

.sound7D
.sound7E
call nSound2Voices_1_sound2Priority_1 : ret

.sound7F
call nSound2Voices_2_sound2Priority_0 : ret
}

; $3987
nSound2Voices_1_sound2Priority_0:
{
mov a,#$01 : mov !sound2_n_voices,a
mov a,#$00 : mov !sound2Priority,a
ret
}

; $3992
nSound2Voices_1_sound2Priority_1:
{
mov a,#$01 : mov !sound2_n_voices,a
mov a,#$01 : mov !sound2Priority,a
ret
}

; $399D
nSound2Voices_2_sound2Priority_0:
{
mov a,#$02 : mov !sound2_n_voices,a
mov a,#$00 : mov !sound2Priority,a
ret
}

; $39A8
nSound2Voices_2_sound2Priority_1:
{
mov a,#$02 : mov !sound2_n_voices,a
mov a,#$01 : mov !sound2Priority,a
ret
}

; $39B3
sound2InstructionLists:
{
dw .sound1,  .sound2,  .sound3,  .sound4,  .sound5,  .sound6,  .sound7,  .sound8,  .sound9,  .soundA,  .soundB,  .soundC,  .soundD,  .soundE,  .soundF,  .sound10,\
   .sound11, .sound12, .sound13, .sound14, .sound15, .sound16, .sound17, .sound18, .sound19, .sound1A, .sound1B, .sound1C, .sound1D, .sound1E, .sound1F, .sound20,\
   .sound21, .sound22, .sound23, .sound24, .sound25, .sound26, .sound27, .sound28, .sound29, .sound2A, .sound2B, .sound2C, .sound2D, .sound2E, .sound2F, .sound30,\
   .sound31, .sound32, .sound33, .sound34, .sound35, .sound36, .sound37, .sound38, .sound39, .sound3A, .sound3B, .sound3C, .sound3D, .sound3E, .sound3F, .sound40,\
   .sound41, .sound42, .sound43, .sound44, .sound45, .sound46, .sound47, .sound48, .sound49, .sound4A, .sound4B, .sound4C, .sound4D, .sound4E, .sound4F, .sound50,\
   .sound51, .sound52, .sound53, .sound54, .sound55, .sound56, .sound57, .sound58, .sound59, .sound5A, .sound5B, .sound5C, .sound5D, .sound5E, .sound5F, .sound60,\
   .sound61, .sound62, .sound63, .sound64, .sound65, .sound66, .sound67, .sound68, .sound69, .sound6A, .sound6B, .sound6C, .sound6D, .sound6E, .sound6F, .sound70,\
   .sound71, .sound72, .sound73, .sound74, .sound75, .sound76, .sound77, .sound78, .sound79, .sound7A, .sound7B, .sound7C, .sound7D, .sound7E, .sound7F

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

; Sound 1: Collected small health drop
.sound1
dw ..voice0
..voice0 : db $15,$80,$0A,$C7,$0A, $15,$50,$0A,$C7,$0A, $15,$20,$0A,$C7,$0A, $FF

; Sound 2: Collected big health drop
.sound2
dw ..voice0
..voice0 : db $15,$E0,$0A,$C7,$0A, $15,$60,$0A,$C7,$0A, $15,$30,$0A,$C7,$0A, $FF

; Sound 3: Collected missile drop
.sound3
dw .artilleryVoice

; Collected missile / super missile / power bomb drop
.artilleryVoice
db $0C,$60,$0A,$AF,$02, $0C,$00,$0A,$AF,$01, $0C,$60,$0A,$AF,$02, $0C,$00,$0A,$AF,$01, $0C,$60,$0A,$AF,$02, $FF

; Sound 4: Collected super missile drop
.sound4
dw .artilleryVoice

; Sound 5: Collected power bomb drop
.sound5
dw .artilleryVoice

; Sound 6: Block destroyed by contact damage
.sound6
dw ..voice0
..voice0 : db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $FF

; Sound 7: (Super) missile hit wall
.sound7
dw .explosionVoice

; (Super) missile hit wall / bomb explosion
.explosionVoice
db $08,$E0,$0A,$98,$03, $08,$E0,$0A,$95,$03, $08,$E0,$0A,$9A,$03, $08,$E0,$0A,$8C,$03, $08,$E0,$0A,$8C,$20, $FF

; Sound 8: Bomb explosion
.sound8
dw .explosionVoice

; Sound 9: Enemy killed
.sound9
dw ..voice0
..voice0 : db $08,$D0,$0A,$8B,$08, $F5,$D0,$BC, $09,$D0,$0A,$98,$10, $FF

; Sound Ah: Block crumbled or destroyed by shot
.soundA
dw ..voice0
..voice0 : db $08,$70,$0A,$9D,$07, $FF

; Sound Bh: Enemy killed by contact damage
.soundB
dw ..voice0
..voice0 : db $08,$D0,$0A,$99,$02, $08,$D0,$0A,$9C,$03, $0F,$D0,$0A,$8B,$03, $0F,$E0,$0A,$8C,$03, $0F,$D0,$0A,$8E,$0E, $FF

; Sound Ch: Beam hit wall
.soundC
dw ..voice0
..voice0 : db $08,$70,$0A,$98,$03, $08,$70,$0A,$95,$03, $F5,$F0,$BC, $09,$70,$0A,$98,$06, $FF

; Sound Dh: Splashed into water
.soundD
dw ..voice0
..voice0 : db $0F,$70,$0A,$93,$03, $0F,$E0,$0A,$90,$08, $0F,$70,$0A,$84,$15, $FF

; Sound Eh: Splashed out of water
.soundE
dw ..voice0
..voice0 : db $0F,$60,$0A,$90,$03, $0F,$60,$0A,$84,$15, $FF

; Sound Fh: Low pitched air bubbles
.soundF
dw ..voice0
..voice0 : db $0E,$60,$0A,$80,$05, $0E,$60,$0A,$85,$05, $0E,$60,$0A,$91,$05, $0E,$60,$0A,$89,$05, $FF

; Sound 10h: Lava/acid damaging Samus
.sound10
dw ..voice0
..voice0 : db $F5,$30,$BB, $12,$10,$0A,$95,$15, $FF

; Sound 11h: High pitched air bubbles
.sound11
dw ..voice0
..voice0 : db $0E,$60,$0A,$8C,$05, $0E,$60,$0A,$91,$05, $FF

; Sound 12h: Plays at random in heated rooms
.sound12
dw ..voice0
..voice0 : db $22,$60,$0A,$84,$1C, $22,$60,$0A,$90,$19, $0E,$60,$0A,$80,$10, $22,$60,$0A,$89,$19, $0E,$60,$0A,$80,$07, $0E,$60,$0A,$84,$10, $22,$60,$0A,$8B,$1B, $FF

; Sound 13h: Plays at random in heated rooms
.sound13
dw ..voice0
..voice0 : db $0E,$60,$0A,$80,$0A, $0E,$60,$0A,$84,$07, $22,$60,$0A,$8B,$1F, $22,$60,$0A,$89,$16, $0E,$60,$0A,$80,$0A, $0E,$60,$0A,$87,$10, $FF

; Sound 14h: Plays at random in heated rooms
.sound14
dw ..voice0
..voice0 : db $0E,$60,$0A,$80,$0A, $0E,$60,$0A,$87,$10, $22,$60,$0A,$84,$1A, $0E,$60,$0A,$80,$0A, $0E,$60,$0A,$84,$07, $22,$60,$0A,$91,$16, $0E,$60,$0A,$80,$0A, $0E,$60,$0A,$87,$10, $FF

; Sound 15h: Maridia elevatube
.sound15
dw ..voice0
..voice0 : db $25,$00,$0A,$AB,$03, $FF

; Sound 16h:
.sound16
dw ..voice0
..voice0 : db $25,$60,$0A,$A8,$10, $FF

; Sound 17h: Morph ball eye's ray
.sound17
dw ..voice0
..voice0 : db $F5,$70,$AA, $06,$40,$0A,$A1,$40,\
              $FE,$00, $06,$40,$0A,$AA,$F0, $FB,\
              $FF

; Sound 18h: Ambient sound in Red Brinstar mainstreet
.sound18
dw ..voice0
..voice0 : db $0B,$20,$0A,$8C,$03, $0B,$30,$0A,$8C,$03, $0B,$40,$0A,$8C,$03, $0B,$50,$0A,$8C,$03, $0B,$60,$0A,$8C,$03, $0B,$70,$0A,$8C,$03, $0B,$80,$0A,$8C,$03, $0B,$60,$0A,$8C,$03, $0B,$50,$0A,$8C,$03, $0B,$40,$0A,$8C,$03, $0B,$30,$0A,$8C,$03, $FF

; Sound 19h:
.sound19
dw ..voice0, ..voice1
..voice0 : db $10,$50,$0A,$C1,$03, $10,$40,$0A,$C2,$03, $10,$30,$0A,$C3,$03, $10,$20,$0A,$C4,$03, $10,$10,$0A,$C5,$03, $10,$10,$0A,$C6,$03, $10,$10,$0A,$C7,$03, $10,$00,$0A,$C7,$30, $10,$60,$0A,$C7,$03, $10,$50,$0A,$C6,$03, $10,$30,$0A,$C5,$03, $10,$30,$0A,$C4,$03, $10,$20,$0A,$C3,$03, $10,$20,$0A,$C2,$03, $10,$10,$0A,$C1,$03, $10,$10,$0A,$C0,$03, $FF
..voice1 : db $08,$D0,$0A,$99,$03, $08,$D0,$0A,$9C,$04, $0F,$30,$0A,$8B,$03, $0F,$40,$0A,$8C,$03, $0F,$50,$0A,$8E,$0E, $FF

; Sound 1Ah: n00b tube shattering
.sound1A
dw ..voice0, ..voice1
..voice0 : db $08,$D0,$0A,$94,$03, $08,$D0,$0A,$97,$02, $08,$D0,$0A,$98,$03, $08,$D0,$0A,$9A,$04, $08,$D0,$0A,$97,$03, $08,$D0,$0A,$9A,$04, $08,$D0,$0A,$9D,$03, $08,$D0,$0A,$9F,$03, $08,$D0,$0A,$94,$1A, $25,$40,$0A,$8C,$26, $FF
..voice1 : db $25,$D0,$0A,$98,$10, $25,$D0,$0A,$93,$16, $25,$90,$0A,$8F,$15, $FF

; Sound 1Bh:
.sound1B
dw ..voice0
..voice0 : db $08,$D0,$0A,$94,$19, $FF

; Sound 1Ch:
.sound1C
dw ..voice0
..voice0 : db $0D,$40,$0C,$8B,$02, $0D,$50,$0C,$89,$02, $0D,$60,$0C,$87,$03, $0D,$50,$0C,$85,$03, $FF

; Sound 1Dh: Dachora cry
.sound1D
dw ..voice0
..voice0 : db $14,$D0,$0A,$9F,$03, $14,$D0,$0A,$A4,$03, $14,$90,$0A,$A4,$03, $14,$40,$0A,$A3,$03, $14,$30,$0A,$A2,$03, $FF

; Sound 1Eh:
.sound1E
dw ..voice0, ..voice1
..voice0 : db $08,$D0,$0A,$94,$59, $FF
..voice1 : db $25,$D0,$0A,$98,$10, $25,$D0,$0A,$93,$16, $25,$90,$0A,$8F,$15, $FF

; Sound 1Fh:
.sound1F
dw ..voice0
..voice0 : db $25,$D0,$0A,$90,$09, $00,$D8,$0A,$97,$07, $FF

; Sound 20h: Shot fly
.sound20
dw ..voice0
..voice0 : db $14,$80,$0A,$9F,$03, $14,$80,$0A,$98,$0A, $14,$40,$0A,$98,$03, $14,$30,$0A,$98,$03, $FF

; Sound 21h: Shot skree / wall/ninja space pirate
.sound21
dw .skreeVoice

; Shot skree / wall/ninja space pirate / skree launches attack
.skreeVoice
db $14,$80,$0A,$98,$03, $14,$A0,$0A,$9D,$07, $14,$50,$0A,$98,$03, $14,$30,$0A,$9D,$06, $FF

; Sound 22h: Shot pipe bug / high-rising slow-falling enemy
.sound22
dw ..voice0
..voice0 : db $14,$D0,$0A,$90,$03, $14,$E0,$0A,$93,$03, $14,$D0,$0A,$95,$03, $14,$50,$0A,$95,$03, $FF

; Sound 23h: Shot slug / sidehopper / zoomer
.sound23
dw ..voice0
..voice0 : db $14,$E0,$0C,$84,$03, $14,$D0,$0C,$89,$03, $14,$E0,$0C,$84,$03, $14,$D0,$0C,$89,$03, $FF

; Sound 24h: Small explosion (enemy death)
.sound24
dw ..voice0
..voice0 : db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$25, $FF

; Sound 25h: Ceres door explosion (also used by Mother Brain)
.sound25
dw .ceresDoorExplosion

; Ceres door explosion / sound 76h
.ceresDoorExplosion
db $00,$E0,$0A,$91,$08, $08,$D0,$0A,$A1,$03, $08,$D0,$0A,$9E,$03, $08,$D0,$0A,$A3,$03, $08,$D0,$0A,$8E,$03, $08,$D0,$0A,$8E,$25, $FF

; Sound 26h:
.sound26
dw ..voice0
..voice0 : db $00,$D8,$0A,$95,$05, $01,$90,$0A,$A4,$08, $F5,$F0,$80, $0B,$A0,$0A,$B0,$0E, $F5,$F0,$80, $0B,$70,$0A,$B0,$0E, $F5,$F0,$80, $0B,$30,$0A,$B0,$0E, $FF

; Sound 27h: Shot torizo
.sound27
dw ..voice0, ..voice1
..voice0 : db $14,$D0,$0A,$8B,$11, $14,$D0,$0A,$89,$20, $14,$80,$0A,$89,$05, $14,$30,$0A,$89,$05, $FF
..voice1 : db $14,$D0,$0A,$80,$09, $14,$D0,$0A,$82,$20, $14,$80,$0A,$82,$05, $14,$30,$0A,$82,$05, $FF

; Sound 28h:
.sound28
dw .sound28_2A_Voice

; Sound 28h / 2Ah
.sound28_2A_Voice
db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$03, $08,$D0,$0A,$8C,$25, $FF

; Sound 29h: Mother Brain rising into phase 2
.sound29
dw ..voice0
..voice0 : db $08,$40,$0A,$9F,$04, $08,$40,$0A,$9C,$03, $08,$40,$0A,$A1,$03, $08,$40,$0A,$93,$04, $08,$40,$0A,$93,$25, $FF

; Sound 2Ah:
.sound2A
dw .sound28_2A_Voice

; Sound 2Bh: Ridley's fireball hit surface
.sound2B
dw ..voice0
..voice0 : db $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$98,$03, $08,$D0,$0A,$95,$03, $08,$D0,$0A,$9A,$03, $08,$D0,$0A,$8C,$20, $FF

; Sound 2Ch: Shot Spore Spawn
.sound2C
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$8E,$40, $FF
..voice1 : db $25,$00,$0A,$87,$15, $25,$D0,$0A,$87,$40, $FF

; Sound 2Dh:
.sound2D
dw ..voice0
..voice0 : db $25,$D0,$0A,$95,$45, $FF

; Sound 2Eh:
.sound2E
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$9F,$60, $25,$D0,$0A,$9A,$30, $25,$D0,$0A,$98,$30, $FF
..voice1 : db $25,$00,$0A,$9A,$45, $25,$D0,$0A,$9C,$60, $25,$D0,$0A,$97,$50, $FF

; Sound 2Fh: Yapping maw
.sound2F
dw ..voice0
..voice0 : db $08,$50,$0A,$AD,$03, $08,$50,$0A,$AD,$04, $F5,$90,$C7, $10,$40,$0A,$BC,$07, $10,$20,$0A,$C3,$03, $FF

; Sound 30h: Shot super-desgeega
.sound30
dw ..voice0
..voice0 : db $25,$90,$0A,$93,$06, $25,$B0,$0A,$98,$10, $25,$40,$0A,$98,$03, $25,$30,$0A,$98,$03, $FF

; Sound 31h: Brinstar plant chewing
.sound31
dw ..voice0
..voice0 : db $0F,$70,$0A,$8B,$0D, $0F,$80,$0A,$92,$0D, $FF

; Sound 32h: Etecoon wall-jump
.sound32
dw ..voice0
..voice0 : db $1D,$70,$0A,$AC,$0B, $FF

; Sound 33h: Etecoon cry
.sound33
dw ..voice0
..voice0 : db $1D,$70,$0A,$B4,$04, $1D,$70,$0A,$B0,$04, $FF

; Sound 34h: Spike shooting plant spikes
.sound34
dw .popVoice

; Spike shooting plant spikes / shot Maridia floater
.popVoice
db $00,$D8,$0A,$90,$16, $FF

; Sound 35h: Etecoon's theme
.sound35
dw ..voice0
..voice0 : db $1D,$70,$0A,$A9,$07, $1D,$20,$0A,$A9,$07, $1D,$70,$0A,$AE,$07, $1D,$20,$0A,$AE,$07, $1D,$70,$0A,$B0,$07, $1D,$20,$0A,$B0,$07, $1D,$70,$0A,$B2,$07, $1D,$20,$0A,$B2,$07, $1D,$70,$0A,$B4,$07, $1D,$20,$0A,$B4,$07, $1D,$70,$0A,$B0,$07, $1D,$20,$0A,$B0,$07, $1D,$70,$0A,$AB,$07, $1D,$20,$0A,$AB,$07, $1D,$70,$0A,$B0,$07, $1D,$20,$0A,$B0,$07, $1D,$70,$0A,$B5,$07, $1D,$20,$0A,$B5,$07, $1D,$70,$0A,$B2,$07, $1D,$20,$0A,$B2,$07, $1D,$70,$0A,$AE,$07, $1D,$20,$0A,$AE,$07, $1D,$70,$0A,$AB,$07, $1D,$20,$0A,$AB,$07, $1D,$70,$0A,$AD,$20, $FF

; Sound 36h: Shot rio / Norfair lava-jumping enemy / lava seahorse
.sound36
dw ..voice0
..voice0 : db $14,$80,$0A,$8C,$03, $14,$A0,$0A,$91,$05, $14,$50,$0A,$8C,$03, $14,$30,$0A,$91,$06, $FF

; Sound 37h: Refill/map station engaged
.sound37
dw ..voice0, ..voice1
..voice0 : db $03,$90,$0A,$89,$05, $F5,$F0,$BB, $07,$40,$0A,$B0,$20,\
              $FE,$00, $07,$40,$0A,$BB,$0A, $FB, $FF
..voice1 : db $03,$90,$0A,$87,$05, $F5,$F0,$C7, $07,$40,$0A,$BC,$20,\
              $FE,$00, $0B,$10,$0A,$B9,$07, $FB, $FF

; Sound 38h: Refill/map station disengaged
.sound38
dw ..voice0, ..voice1
..voice0 : db $F5,$F0,$B0, $07,$90,$0A,$BB,$08, $FF
..voice1 : db $F5,$F0,$80, $0B,$10,$0A,$B9,$08, $FF

; Sound 39h: Dachora speed booster
.sound39
dw sound3InstructionLists_speedBoosterVoice

; Sound 3Ah:
.sound3A
dw ..voice0
..voice0 : db $07,$60,$0A,$C7,$10, $FF

; Sound 3Bh: Dachora shinespark
.sound3B
dw sound3InstructionLists_shinesparkVoice0

; Sound 3Ch: Dachora shinespark ended
.sound3C
dw sound3InstructionLists_shinesparkEndedVoice

; Sound 3Dh: Dachora stored shinespark
.sound3D
dw sound3InstructionLists_storedShinesparkVoice

; Sound 3Eh: Shot Maridia spikey shells / Norfair erratic fireball / ripped / kamer / Maridia snail / yapping maw / Wrecked Ship orbs
.sound3E
dw ..voice0
..voice0 : db $13,$60,$0A,$95,$05, $13,$40,$0A,$95,$03, $13,$10,$0A,$95,$03, $FF

; Sound 3Fh:
.sound3F
dw ..voice0
..voice0 : db $00,$70,$0A,$95,$0C, $FF

; Sound 40h:
.sound40
dw ..voice0
..voice0 : db $F5,$F0,$80, $0B,$30,$0A,$C7,$08, $FF

; Sound 41h:
.sound41
dw ..voice0
..voice0 : db $FF

; Sound 42h:
.sound42
dw ..voice0
..voice0 : db $08,$D0,$0A,$94,$20, $FF

; Sound 43h:
.sound43
dw ..voice0
..voice0 : db $08,$D0,$0A,$94,$03, $08,$D0,$0A,$97,$03, $08,$D0,$0A,$99,$20, $FF

; Sound 44h:
.sound44
dw ..voice0
..voice0 : db $FF

; Sound 45h: Typewriter stroke - Ceres self destruct sequence
.sound45
dw ..voice0
..voice0 : db $03,$50,$0A,$98,$02, $03,$50,$0A,$98,$02, $FF

; Sound 46h:
.sound46
dw ..voice0
..voice0 : db $08,$D0,$0A,$8E,$07, $08,$D0,$0A,$8E,$10, $08,$D0,$0A,$8E,$09, $08,$D0,$0A,$8E,$0E, $FF

; Sound 47h: Shot waver
.sound47
dw ..voice0
..voice0 : db $14,$D0,$0A,$98,$03, $14,$E0,$0A,$97,$03, $14,$D0,$0A,$95,$03, $14,$50,$0A,$95,$03, $FF

; Sound 48h:
.sound48
dw ..voice0
..voice0 : db $00,$D8,$0A,$95,$08, $F5,$F0,$8C, $0B,$D0,$0A,$A3,$06, $F5,$F0,$8C, $0B,$B0,$0A,$A3,$06, $F5,$F0,$8C, $0B,$70,$0A,$A3,$06, $FF

; Sound 49h: Shot fish / crab / Maridia refill candy
.sound49
dw ..voice0
..voice0 : db $14,$80,$0A,$AB,$04, $14,$50,$0A,$AB,$04, $14,$30,$0A,$AB,$04, $14,$20,$0A,$AB,$04, $FF

; Sound 4Ah: Shot mini-Draygon
.sound4A
dw ..voice0
..voice0 : db $24,$70,$0A,$9C,$03, $24,$50,$0A,$9A,$04, $24,$40,$0A,$9A,$06, $24,$10,$0A,$9A,$06, $FF

; Sound 4Bh:
.sound4B
dw ..voice0
..voice0 : db $08,$A0,$0C,$98,$08, $FF

; Sound 4Ch: Ki-hunter / eye door acid spit
.sound4C
dw ..voice0
..voice0 : db $00,$40,$0A,$9C,$08, $0F,$80,$0A,$93,$13, $FF

; Sound 4Dh: Gunship hover
.sound4D
dw ..voice0
..voice0 : db $0B,$20,$0A,$89,$03, $0B,$30,$0A,$89,$03, $0B,$40,$0A,$89,$03, $0B,$50,$0A,$89,$03, $0B,$60,$0A,$89,$03, $0B,$70,$0A,$89,$03, $0B,$80,$0A,$89,$03, $0B,$60,$0A,$89,$03, $0B,$50,$0A,$89,$03, $0B,$40,$0A,$89,$03, $0B,$30,$0A,$89,$03, $FF

; Sound 4Eh: Ceres Ridley getaway
.sound4E
dw ..voice0, ..voice1
..voice0 : db $F5,$B0,$C7, $05,$D0,$0A,$98,$46, $FF
..voice1 : db $F5,$A0,$C7, $09,$D0,$0F,$80,$50, $F5,$50,$80, $09,$D0,$0A,$AB,$46, $FF

; Sound 4Fh:
.sound4F
dw ..voice0
..voice0 : db $0F,$B0,$0A,$93,$10, $0F,$40,$0A,$93,$03, $0F,$30,$0A,$93,$03, $FF

; Sound 50h:
.sound50
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$9A,$0E, $FF
..voice1 : db $24,$00,$0A,$8C,$03, $24,$90,$0A,$98,$14, $FF

; Sound 51h: Shot Wrecked Ship ghost
.sound51
dw ..voice0, ..voice1
..voice0 : db $19,$60,$0A,$A4,$13, $19,$50,$0A,$A4,$13, $19,$30,$0A,$A4,$13, $19,$10,$0A,$A4,$13, $FF
..voice1 : db $19,$60,$0A,$9F,$16, $19,$50,$0A,$9F,$16, $19,$30,$0A,$9F,$16, $19,$10,$0A,$9F,$16, $FF

; Sound 52h:
.sound52
dw ..voice0
..voice0 : db $22,$D0,$0A,$92,$2B, $FF

; Sound 53h: Shot mini-Crocomire
.sound53
dw ..voice0
..voice0 : db $0F,$B0,$0A,$93,$10, $0F,$40,$0A,$93,$03, $0F,$30,$0A,$93,$03, $FF

; Sound 54h:
.sound54
dw ..voice0
..voice0 : db $14,$B0,$0A,$93,$05, $14,$80,$0A,$9C,$0A, $14,$40,$0A,$9C,$03, $14,$30,$0A,$9C,$03, $FF

; Sound 55h: Shot beetom
.sound55
dw ..voice0
..voice0 : db $F5,$F0,$80, $0B,$40,$0A,$C5,$04, $F5,$F0,$80, $0B,$30,$0A,$F6,$03, $F5,$F0,$80, $0B,$20,$0A,$F6,$03, $FF

; Sound 56h: Acquired suit
.sound56
dw ..voice0, ..voice1
..voice0 : db $09,$D0,$0F,$87,$10, $F5,$B0,$C7, $05,$D0,$0F,$80,$60, $FF
..voice1 : db $09,$D0,$05,$82,$30, $F5,$A0,$80, $05,$D0,$05,$C7,$60, $FF

; Sound 57h: Shot door/gate with dud shot / shot reflec
.sound57
dw ..voice0
..voice0 : db $08,$70,$0A,$98,$03, $08,$50,$0A,$95,$03, $08,$40,$0A,$9A,$03, $FF

; Sound 58h: Shot mochtroid
.sound58
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$98,$0D, $FF
..voice1 : db $24,$00,$0A,$94,$03, $24,$80,$0A,$9A,$15, $FF

; Sound 59h: Ridley's roar
.sound59
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$9D,$30, $FF
..voice1 : db $25,$D0,$0A,$A1,$30, $FF

; Sound 5Ah: Shot metroid
.sound5A
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$98,$15, $FF
..voice1 : db $24,$00,$0A,$96,$03, $24,$80,$0A,$95,$1D, $FF

; Sound 5Bh: Skree launches attack
.sound5B
dw .skreeVoice

; Sound 5Ch: Skree hits the ground
.sound5C
dw ..voice0
..voice0 : db $0F,$B0,$0A,$8B,$08, $F5,$F0,$BC, $01,$70,$0A,$98,$09, $F5,$F0,$BC, $01,$60,$0A,$98,$09, $F5,$F0,$BC, $01,$50,$0A,$98,$09, $F5,$F0,$BC, $01,$40,$0A,$98,$09, $FF

; Sound 5Dh: Sidehopper jumped
.sound5D
dw ..voice0
..voice0 : db $01,$B0,$0A,$80,$0F, $01,$60,$0A,$80,$03, $01,$40,$0A,$80,$03, $FF

; Sound 5Eh: Sidehopper landed
.sound5E
dw ..voice0
..voice0 : db $00,$A0,$0A,$84,$0F, $00,$60,$0A,$84,$03, $00,$40,$0A,$84,$03, $FF

; Sound 5Fh: Shot Lower Norfair rio / desgeega / Norfair slow fireball / walking lava seahorse / Botwoon
.sound5F
dw ..voice0
..voice0 : db $14,$90,$0A,$82,$0A, $14,$80,$0A,$82,$03, $14,$60,$0A,$82,$03, $FF

; Sound 60h:
.sound60
dw ..voice0
..voice0 : db $25,$70,$0A,$AB,$20, $FF

; Sound 61h:
.sound61
dw ..voice0
..voice0 : db $F5,$50,$B0, $09,$D0,$0A,$8C,$20, $FF

; Sound 62h:
.sound62
dw ..voice0
..voice0 : db $F5,$F0,$B0, $09,$D0,$0A,$8C,$10, $FF

; Sound 63h: Mother Brain's ketchup beam
.sound63
dw ..voice0, ..voice1
..voice0 : db $00,$E0,$0A,$95,$05, $01,$E0,$0A,$A4,$05, $08,$E0,$0A,$9F,$04, $08,$E0,$0A,$9C,$03, $08,$E0,$0A,$A1,$03, $08,$E0,$0A,$93,$04, $08,$E0,$0A,$93,$08, $08,$D0,$0A,$8B,$13, $08,$D0,$0A,$89,$13, $08,$D0,$0A,$85,$16, $08,$D0,$0A,$82,$18, $FF
..voice1 : db $00,$E0,$0A,$95,$05, $18,$E0,$0A,$A4,$05, $18,$E0,$0A,$9F,$04, $18,$E0,$0A,$9C,$03, $18,$E0,$0A,$A1,$03, $18,$E0,$0A,$93,$04, $18,$E0,$0A,$93,$08, $18,$E0,$0A,$8C,$05, $18,$E0,$0A,$87,$04, $18,$E0,$0A,$84,$03, $FF

; Sound 64h:
.sound64
dw ..voice0
..voice0 : db $F5,$50,$B0, $09,$D0,$0A,$8C,$18, $FF

; Sound 65h:
.sound65
dw ..voice0
..voice0 : db $14,$A0,$0A,$97,$03, $14,$A0,$0A,$97,$03, $14,$A0,$0A,$97,$03, $14,$30,$0A,$97,$03, $14,$20,$0A,$97,$03, $FF

; Sound 66h: Shot ki-hunter / walking space pirate
.sound66
dw ..voice0
..voice0 : db $14,$80,$0A,$98,$0A, $14,$40,$0A,$98,$03, $14,$30,$0A,$98,$03, $FF

; Sound 67h: Space pirate / Mother Brain laser
.sound67
dw .laserVoice

; Space pirate / Mother Brain laser / sound 6Bh
.laserVoice
db $00,$D8,$0A,$98,$05, $F5,$F0,$C7, $0B,$50,$0A,$B0,$03, $F5,$F0,$C7, $0B,$50,$0A,$B0,$03, $F5,$F0,$C7, $0B,$50,$0A,$B0,$03, $F5,$F0,$BC, $0B,$50,$0A,$B0,$03, $FF

; Sound 68h: Shot Wrecked Ship robot
.sound68
dw ..voice0
..voice0 : db $1B,$A0,$0A,$94,$06, $1B,$90,$0A,$8C,$20, $FF

; Sound 69h: Shot Shaktool
.sound69
dw ..voice0
..voice0 : db $02,$80,$0A,$89,$05, $02,$40,$0A,$89,$03, $02,$10,$0A,$89,$03, $FF

; Sound 6Ah: Shot Maridia floater
.sound6A
dw .popVoice

; Sound 6Bh:
.sound6B
dw .laserVoice

; Unused byte
db $FF

; Sound 6Ch:
.sound6C
dw ..voice0
..voice0 : db $00,$40,$0A,$A8,$08, $FF

; Sound 6Dh: Ceres tiles falling from ceiling
.sound6D
dw ..voice0
..voice0 : db $00,$E0,$0A,$91,$08, $08,$90,$0A,$A1,$03, $08,$90,$0A,$9E,$03, $08,$90,$0A,$A3,$03, $08,$90,$0A,$8E,$03, $08,$90,$0A,$8E,$25, $FF

; Sound 6Eh: Shot Mother Brain phase 1
.sound6E
dw ..voice0, ..voice1
..voice0 : db $23,$D0,$0A,$80,$20, $FF
..voice1 : db $23,$D0,$0A,$87,$20, $FF

; Sound 6Fh: Mother Brain's cry - low pitch
.sound6F
dw ..voice0, ..voice1
..voice0 : db $25,$E0,$0A,$80,$C0, $FF
..voice1 : db $24,$E0,$0A,$8C,$C0, $FF

; Sound 70h:
.sound70
dw ..voice0
..voice0 : db $1A,$60,$0A,$AB,$06, $1A,$60,$0A,$B0,$09, $FF

; Sound 71h: Silence
.sound71
dw ..voice0
..voice0 : db $09,$00,$0A,$8C,$03, $FF

; Sound 72h:
.sound72
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$8C,$30, $FF
..voice1 : db $24,$00,$0A,$9D,$03, $24,$80,$0A,$87,$45, $FF

; Sound 73h:
.sound73
dw ..voice0, ..voice1
..voice0 : db $25,$E0,$0A,$A3,$40, $FF
..voice1 : db $25,$00,$0A,$A6,$0C, $25,$80,$0A,$A3,$40, $FF

; Sound 74h:
.sound74
dw ..voice0, ..voice1
..voice0 : db $25,$90,$0A,$92,$53, $FF
..voice1 : db $26,$E0,$0A,$A6,$09, $26,$E0,$0A,$A4,$0D, $26,$E0,$0A,$A2,$0D, $26,$E0,$0A,$A0,$0D, $FF

; Sound 75h:
.sound75
dw ..voice0, ..voice1
..voice0 : db $0D,$00,$0C,$A3,$05, $0D,$A0,$0C,$A3,$02, $0D,$C0,$0C,$A1,$02, $0D,$C0,$0C,$9F,$03, $0D,$C0,$0C,$9D,$03, $0D,$B0,$0C,$9C,$03, $0D,$A0,$0C,$9A,$02, $0D,$90,$0C,$A3,$02, $0D,$90,$0C,$98,$04, $0D,$A0,$0C,$97,$02, $0D,$C0,$0C,$95,$02, $0D,$C0,$0C,$93,$03, $0D,$C0,$0C,$91,$03, $0D,$B0,$0C,$90,$03, $0D,$A0,$0C,$8E,$02, $0D,$90,$0C,$97,$02, $0D,$90,$0C,$8C,$04, $FF
..voice1 : db $0D,$A0,$0C,$97,$02, $0D,$B0,$0C,$90,$03, $0D,$C0,$0C,$91,$03, $0D,$C0,$0C,$91,$03, $0D,$B0,$0C,$90,$03, $0D,$90,$0C,$97,$02, $0D,$90,$0C,$97,$02, $0D,$90,$0C,$8C,$04, $0D,$A0,$0C,$8B,$02, $0D,$90,$0C,$8B,$02, $0D,$C0,$0C,$87,$03, $0D,$C0,$0C,$85,$03, $0D,$C0,$0C,$89,$02, $0D,$B0,$0C,$84,$03, $0D,$C0,$0C,$89,$02, $0D,$90,$0C,$80,$04, $FF

; Sound 76h:
.sound76
dw .ceresDoorExplosion

; Sound 77h:
.sound77
dw ..voice0, ..voice1
..voice0 : db $25,$D0,$0A,$A7,$15, $25,$D0,$0A,$A3,$20, $25,$D0,$0A,$A2,$63, $25,$00,$0A,$A2,$09, $25,$D0,$0A,$A2,$60, $25,$00,$0A,$A2,$09, $25,$D0,$0A,$A2,$60, $25,$00,$0A,$A2,$09, $25,$D0,$0A,$A3,$20, $25,$D0,$0A,$A2,$33, $FF
..voice1 : db $26,$D0,$0A,$A6,$0D, $26,$D0,$0A,$A6,$0D, $26,$D0,$0A,$A5,$0D, $26,$D0,$0A,$A4,$0D, $26,$D0,$0A,$A7,$0D, $26,$D0,$0A,$A2,$0D, $26,$00,$0A,$AA,$7B, $26,$00,$0A,$AA,$90, $26,$D0,$0A,$A7,$0D, $26,$D0,$0A,$A6,$0D, $26,$D0,$0A,$A5,$0D, $26,$D0,$0A,$A4,$0D, $26,$D0,$0A,$A3,$0D, $26,$D0,$0A,$A2,$0D, $FF

; Sound 78h:
.sound78
dw ..voice0, ..voice1
..voice0 : db $24,$A0,$0A,$9C,$20, $FF
..voice1 : db $24,$00,$0A,$9D,$05, $24,$80,$0A,$95,$40, $FF

; Sound 79h:
.sound79
dw ..voice0, ..voice1
..voice0 : db $26,$D0,$0A,$95,$38, $FF
..voice1 : db $26,$00,$0A,$95,$0A, $26,$D0,$0A,$9C,$38, $FF

; Sound 7Ah:
.sound7A
dw ..voice0, ..voice1
..voice0 : db $26,$D0,$0A,$8E,$40, $FF
..voice1 : db $26,$00,$0A,$8E,$0A, $26,$D0,$0A,$99,$40, $FF

; Sound 7Bh:
.sound7B
dw ..voice0, ..voice1
..voice0 : db $26,$D0,$0A,$9E,$3D, $FF
..voice1 : db $26,$00,$0A,$9E,$0A, $26,$D0,$0A,$9D,$3D, $FF

; Sound 7Ch:
.sound7C
dw ..voice0
..voice0 : db $24,$90,$0A,$94,$1A, $24,$30,$0A,$94,$10, $FF

; Sound 7Dh:
.sound7D
dw ..voice0
..voice0 : db $22,$D0,$0A,$88,$90, $22,$D0,$0A,$8E,$37, $FF

; Sound 7Eh: Mother Brain's cry - high pitch
.sound7E
dw ..voice0
..voice0 : db $25,$D0,$0A,$87,$C0, $FF

; Sound 7Fh: Mother Brain charging her rainbow
.sound7F
dw ..voice0, ..voice1
..voice0 : db $FE,$00, $24,$D0,$0A,$84,$0D, $24,$D0,$0A,$85,$0D, $24,$D0,$0A,$87,$0D, $24,$D0,$0A,$89,$0D, $24,$D0,$0A,$8B,$0D, $24,$D0,$0A,$8C,$0D, $24,$D0,$0A,$8E,$0D, $24,$D0,$0A,$90,$0D, $24,$D0,$0A,$91,$0D, $24,$D0,$0A,$93,$0D, $FB, $FF
..voice1 : db $24,$00,$0A,$80,$04,\
              $FE,$00, $24,$D0,$0A,$84,$0D, $24,$D0,$0A,$85,$0D, $24,$D0,$0A,$87,$0D, $24,$D0,$0A,$89,$0D, $24,$D0,$0A,$8B,$0D, $24,$D0,$0A,$8C,$0D, $24,$D0,$0A,$8E,$0D, $24,$D0,$0A,$90,$0D, $24,$D0,$0A,$91,$0D, $24,$D0,$0A,$93,$0D, $FB,\
              $FF
}
