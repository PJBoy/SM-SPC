macro SetVoice(i_sound, i_voice)
{
!enabledVoices     = !sound<i_sound>_enabledVoices
!p_charVoiceBitset = !sound<i_sound>_p_charVoiceBitset
!p_charVoiceMask   = !sound<i_sound>_p_charVoiceMask
!bitset #= 1<<<i_voice>

set<i_voice> !enableSoundEffectVoices
clr<i_voice> !musicVoiceBitset
clr<i_voice> !echoEnableFlags
mov a,#!bitset : or a,!enabledVoices : mov !enabledVoices,a
mov y,#$00
mov a,#!bitset : mov (!p_charVoiceBitset)+y,a
mov a,#~!bitset : mov (!p_charVoiceMask)+y,a
}
endmacro


macro ResetSoundChannel(i_sound, i_channel)
{
!enabledVoices                    = !sound<i_sound>_enabledVoices
!disableByte                      = !sound<i_sound>_channel<i_channel>_disableByte
!voiceBitset                      = !sound<i_sound>_channel<i_channel>_voiceBitset
!voiceMask                        = !sound<i_sound>_channel<i_channel>_voiceMask
!voiceIndex                       = !sound<i_sound>_channel<i_channel>_voiceIndex
!trackOutputVolumeBackup          = !sound<i_sound>_channel<i_channel>_trackOutputVolumeBackup
!trackPhaseInversionOptionsBackup = !sound<i_sound>_channel<i_channel>_trackPhaseInversionOptionsBackup
!updateAdsrSettingsFlag           = !sound<i_sound>_channel<i_channel>_updateAdsrSettingsFlag

mov a,#$FF : mov !disableByte,a
mov a,#$00 : mov !updateAdsrSettingsFlag,a
mov a,!enabledVoices : and a,!voiceMask : mov !enabledVoices,a
mov a,!enableSoundEffectVoices : and a,!voiceMask : mov !enableSoundEffectVoices,a
mov a,!musicVoiceBitset : or a,!voiceBitset : mov !musicVoiceBitset,a
mov a,!keyOffFlags : or a,!voiceBitset : mov !keyOffFlags,a
mov x,!voiceIndex : mov a,!trackInstrumentIndices+x : call setInstrumentSettings
mov x,!voiceIndex
mov a,!trackOutputVolumeBackup          : mov !trackOutputVolumes+x,a
mov a,!trackPhaseInversionOptionsBackup : mov !trackPhaseInversionOptions+x,a
}
endmacro


macro ProcessSoundChannel(i_sound, i_channel, resetChannel, getNextDataByte, n_nops, doPointlessUnusedCommandCheck)
{
!i_instructionList      = !sound<i_sound>_channel<i_channel>_i_instructionList
!instructionTimer       = !sound<i_sound>_channel<i_channel>_instructionTimer
!disableByte            = !sound<i_sound>_channel<i_channel>_disableByte
!voiceBitset            = !sound<i_sound>_channel<i_channel>_voiceBitset
!voiceMask              = !sound<i_sound>_channel<i_channel>_voiceMask
!voiceIndex             = !sound<i_sound>_channel<i_channel>_voiceIndex
!dspIndex               = !sound<i_sound>_channel<i_channel>_dspIndex
!releaseFlag            = !sound<i_sound>_channel<i_channel>_releaseFlag
!releaseTimer           = !sound<i_sound>_channel<i_channel>_releaseTimer
!repeatCounter          = !sound<i_sound>_channel<i_channel>_repeatCounter
!repeatPoint            = !sound<i_sound>_channel<i_channel>_repeatPoint
!adsrSettings           = !sound<i_sound>_channel<i_channel>_adsrSettings
!updateAdsrSettingsFlag = !sound<i_sound>_channel<i_channel>_updateAdsrSettingsFlag
!soundNote              = !sound<i_sound>_channel<i_channel>_note
!soundSubnote           = !sound<i_sound>_channel<i_channel>_subnote
!subnoteDelta           = !sound<i_sound>_channel<i_channel>_subnoteDelta
!targetNote             = !sound<i_sound>_channel<i_channel>_targetNote
!pitchSlideFlag         = !sound<i_sound>_channel<i_channel>_pitchSlideFlag
!legatoFlag             = !sound<i_sound>_channel<i_channel>_legatoFlag
!pitchSlideLegatoFlag   = !sound<i_sound>_channel<i_channel>_pitchSlideLegatoFlag

mov a,#$FF : cmp a,!disableByte : bne + : jmp ?branch_end : +

dec !instructionTimer : beq + : jmp ?branch_processInstruction_end : +
mov a,!legatoFlag : beq + : bra ?loop_commands : +
mov a,#$00
mov !pitchSlideFlag,a
mov !subnoteDelta,a
mov !targetNote,a
mov a,#$FF : cmp a,!releaseFlag : beq +
mov a,!voiceBitset : or a,!keyOffFlags : mov !keyOffFlags,a
mov a,#$02 : mov !releaseTimer,a
mov a,#$01 : mov !instructionTimer,a
mov a,#$FF : mov !releaseFlag,a

+
dec !releaseTimer : beq + : jmp ?branch_end : +
mov a,#$00 : mov !releaseFlag,a
mov a,!voiceMask : and a,!musicVoiceBitset : mov !musicVoiceBitset,a
mov a,!voiceMask : and a,!noiseEnableFlags : mov !noiseEnableFlags,a

?loop_commands
call <getNextDataByte>
if <doPointlessUnusedCommandCheck>
    cmp a,#$FA : bne + : +
endif
cmp a,#$F9 : bne +
call <getNextDataByte> : mov !adsrSettings,a
call <getNextDataByte> : mov !adsrSettings+1,a
mov a,#$FF : mov !updateAdsrSettingsFlag,a
jmp ?loop_commands

+
cmp a,#$F5 : bne +
mov !pitchSlideLegatoFlag,a
bra ++

+
cmp a,#$F8 : bne ?branch_pitchSlide_end
mov a,#$00 : mov !pitchSlideLegatoFlag,a

++
call <getNextDataByte> : mov !subnoteDelta,a
call <getNextDataByte> : mov !targetNote,a
mov a,#$FF : mov !pitchSlideFlag,a
call <getNextDataByte>
?branch_pitchSlide_end

cmp a,#$FF : bne +
call <resetChannel>
jmp ?branch_end

+
cmp a,#$FE : bne +
call <getNextDataByte> : mov !repeatCounter,a
mov a,!i_instructionList : mov !repeatPoint,a
call <getNextDataByte>

+
cmp a,#$FD : bne ?branch_repeatCommand
dec !repeatCounter : bne + : jmp ?loop_commands : +

?loop_repeatCommand
mov a,!repeatPoint : mov !i_instructionList,a
call <getNextDataByte>

?branch_repeatCommand
cmp a,#$FB : bne + : jmp ?loop_repeatCommand : +
cmp a,#$FC : bne +
mov a,!voiceBitset : or a,!noiseEnableFlags : mov !noiseEnableFlags,a
jmp ?loop_commands

; Process note instruction
+
mov x,!voiceIndex
call setInstrumentSettings
call <getNextDataByte> : mov x,!voiceIndex : mov !trackOutputVolumes+x,a
mov a,#$00 : mov !trackPhaseInversionOptions+x,a
call <getNextDataByte> : mov !note+1,a : mov !note,#$00
call writeDspVoiceVolumes
call <getNextDataByte>
cmp a,#$F6 : beq +
mov !soundNote,a
mov a,#$00 : mov !soundSubnote,a

+
mov y,!soundNote : mov a,!soundSubnote : movw !note,ya
mov x,!voiceIndex
call playNoteDirect
call <getNextDataByte> : mov !instructionTimer,a
mov a,!updateAdsrSettingsFlag : beq +
mov a,!dspIndex : or a,#$05 : mov y,a : mov a,!adsrSettings : call writeDspRegisterDirect
mov a,!dspIndex : or a,#$06 : mov y,a : mov a,!adsrSettings+1 : call writeDspRegisterDirect

+
mov a,!legatoFlag : bne ?branch_processInstruction_end
mov a,!voiceBitset : or a,!keyOnFlags : mov !keyOnFlags,a

?branch_processInstruction_end
rep <n_nops> : nop ; Random NOPs!

mov a,!pitchSlideFlag : cmp a,#$FF : bne ?branch_end
mov a,!pitchSlideLegatoFlag : beq +
mov a,#$FF : mov !legatoFlag,a

+
mov a,!soundNote : cmp a,!targetNote : bcc +
mov a,!soundSubnote : setc : sbc a,!subnoteDelta : mov !soundSubnote,a : bcs ++
dec !soundNote
mov a,!targetNote : cmp a,!soundNote : bne ++
mov a,#$00
mov !pitchSlideFlag,a
mov !legatoFlag,a
bra ++

+
mov a,!subnoteDelta : clrc : adc a,!soundSubnote : mov !soundSubnote,a : bcc ++
inc !soundNote
mov a,!targetNote : cmp a,!soundNote : bne ++
mov a,#$00
mov !pitchSlideFlag,a
mov !legatoFlag,a

++
mov a,!soundSubnote : mov y,!soundNote : movw !note,ya
mov x,!voiceIndex
call playNoteDirect

?branch_end
}
endmacro
