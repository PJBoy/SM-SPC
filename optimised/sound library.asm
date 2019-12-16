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


resetSoundIfNoEnabledVoices:
{
; Requires !i_soundLibrary to be set

mov x,!i_soundLibrary
mov a,!sound_enabledVoices+x : bne +
mov a,#$00
mov !sounds+x,a
mov !sound_priorities+x,a
mov !sound_initialisationFlags+x,a

+
ret
}


resetSoundChannel:
{
;; Parameters:
;;     X: Global channel index. Range 0..7

; Requires !i_soundLibrary to be set

mov a,!sound_voiceIndices+x : mov !i_voice,a

mov a,#$FF : mov !sound_disableBytes+x,a
mov a,#$00 : mov !sound_updateAdsrSettingsFlags+x,a
mov a,!sound_voiceMasks+x : mov x,!i_soundLibrary : and a,!sound_enabledVoices+x : mov !sound_enabledVoices+x,a : mov x,!i_globalChannel
mov a,!enableSoundEffectVoices : and a,!sound_voiceMasks+x : mov !enableSoundEffectVoices,a
mov a,!musicVoiceBitset : or a,!sound_voiceBitsets+x : mov !musicVoiceBitset,a
mov a,!keyOffFlags : or a,!sound_voiceBitsets+x : mov !keyOffFlags,a
mov x,!i_voice : mov a,!trackInstrumentIndices+x : call setInstrumentSettings : mov x,!i_globalChannel
mov a,!sound_trackOutputVolumeBackups+x : push a
mov a,!sound_trackPhaseInversionOptionsBackups+x
mov x,!i_voice
mov !trackPhaseInversionOptions+x,a
pop a : mov !trackOutputVolumes+x,a

jmp resetSoundIfNoEnabledVoices
}


getNextDataByte:
{
;; Parameters:
;;     X: Global channel index. Range 0..7
push x
mov x,!i_globalChannel

mov a,!sound_p_instructionListsLow+x : mov y,!sound_p_instructionListsHigh+x : movw !misc0,ya
mov a,!sound_i_instructionLists+x : mov y,a
inc a : mov !sound_i_instructionLists+x,a
mov a,(!misc0)+y

pop x
ret
}


processSoundChannel:
{
;; Parameters:
;;     X: Global channel index. Range 0..7

; Requires !i_soundLibrary to be set
; Valid indexed non-DP address mode opcodes are mov/cmp/adc/sbc/and/or/eor

mov a,#$FF : cmp a,!sound_disableBytes+x : bne + : jmp .branch_end : +

mov a,!sound_voiceIndices+x : mov !i_voice,a
mov a,!sound_instructionTimers+x : dec a : mov !sound_instructionTimers+x,a : beq + : jmp .branch_processInstruction_end : +
mov a,!sound_legatoFlags+x : beq + : bra .loop_commands : +
mov a,#$00
mov !sound_pitchSlideFlags+x,a
mov !sound_subnoteDeltas+x,a
mov !sound_targetNotes+x,a
mov a,#$FF : cmp a,!sound_releaseFlags+x : beq +
mov a,!sound_voiceBitsets+x : or a,!keyOffFlags : mov !keyOffFlags,a
mov a,#$02 : mov !sound_releaseTimers+x,a
mov a,#$01 : mov !sound_instructionTimers+x,a
mov a,#$FF : mov !sound_releaseFlags+x,a

+
mov a,!sound_releaseTimers+x : dec a : mov !sound_releaseTimers+x,a : beq + : jmp .branch_end : +
mov a,#$00 : mov !sound_releaseFlags+x,a
mov a,!sound_voiceMasks+x : and a,!musicVoiceBitset : mov !musicVoiceBitset,a
mov a,!sound_voiceMasks+x : and a,!noiseEnableFlags : mov !noiseEnableFlags,a

.loop_commands
call getNextDataByte
cmp a,#$F9 : bne +
call getNextDataByte : mov !sound_adsrSettingsLow+x,a
call getNextDataByte : mov !sound_adsrSettingsHigh+x,a
mov a,#$FF : mov !sound_updateAdsrSettingsFlags+x,a
jmp .loop_commands

+
cmp a,#$F5 : bne +
mov !sound_pitchSlideLegatoFlags+x,a
bra ++

+
cmp a,#$F8 : bne .branch_pitchSlide_end
mov a,#$00 : mov !sound_pitchSlideLegatoFlags+x,a

++
call getNextDataByte : mov !sound_subnoteDeltas+x,a
call getNextDataByte : mov !sound_targetNotes+x,a
mov a,#$FF : mov !sound_pitchSlideFlags+x,a
call getNextDataByte
.branch_pitchSlide_end

cmp a,#$FF : bne +
call resetSoundChannel
jmp .branch_end

+
cmp a,#$FE : bne +
call getNextDataByte : mov !sound_repeatCounters+x,a
mov a,!sound_i_instructionLists+x : mov !sound_repeatPoints+x,a
call getNextDataByte

+
cmp a,#$FD : bne .branch_repeatCommand
mov a,!sound_repeatCounters+x : dec a : mov !sound_repeatCounters+x,a : bne + : jmp .loop_commands : +

.loop_repeatCommand
mov a,!sound_repeatPoints+x : mov !sound_i_instructionLists+x,a
call getNextDataByte

.branch_repeatCommand
cmp a,#$FB : bne + : jmp .loop_repeatCommand : +
cmp a,#$FC : bne +
mov a,!sound_voiceBitsets+x : or a,!noiseEnableFlags : mov !noiseEnableFlags,a
jmp .loop_commands

; Process note instruction
+
mov x,!i_voice : call setInstrumentSettings
mov x,!i_globalChannel : call getNextDataByte
mov x,!i_voice : mov !trackOutputVolumes+x,a
mov a,#$00 : mov !trackPhaseInversionOptions+x,a

mov x,!i_globalChannel : call getNextDataByte : mov !panningBias+1,a : mov !panningBias,#$00
mov x,!i_voice : call writeDspVoiceVolumes
mov x,!i_globalChannel : call getNextDataByte
cmp a,#$F6 : beq +
mov !sound_notes+x,a
mov a,#$00 : mov !sound_subnotes+x,a

+
mov a,!sound_notes+x : mov y,a : mov a,!sound_subnotes+x : movw !note,ya : mov x,!i_voice : call playNoteDirect
mov x,!i_globalChannel : call getNextDataByte : mov !sound_instructionTimers+x,a
mov a,!sound_updateAdsrSettingsFlags+x : beq +
mov a,!sound_dspIndices+x : or a,#$05 : mov y,a : mov a,!sound_adsrSettingsLow+x : call writeDspRegisterDirect
mov a,!sound_dspIndices+x : or a,#$06 : mov y,a : mov a,!sound_adsrSettingsHigh+x : call writeDspRegisterDirect

+
mov a,!sound_legatoFlags+x : bne .branch_processInstruction_end
mov a,!sound_voiceBitsets+x : or a,!keyOnFlags : mov !keyOnFlags,a

.branch_processInstruction_end
mov a,!sound_pitchSlideFlags+x : cmp a,#$FF : bne .branch_end
mov a,!sound_pitchSlideLegatoFlags+x : beq +
mov a,#$FF : mov !sound_legatoFlags+x,a

+
mov a,!sound_notes+x : cmp a,!sound_targetNotes+x : bcc +
mov a,!sound_subnotes+x : setc : sbc a,!sound_subnoteDeltas+x : mov !sound_subnotes+x,a : bcs ++
mov a,!sound_notes+x : dec a : mov !sound_notes+x,a
mov a,!sound_targetNotes+x : cmp a,!sound_notes+x : bne ++
mov a,#$00
mov !sound_pitchSlideFlags+x,a
mov !sound_legatoFlags+x,a
bra ++

+
mov a,!sound_subnoteDeltas+x : clrc : adc a,!sound_subnotes+x : mov !sound_subnotes+x,a : bcc ++
mov a,!sound_notes+x : inc a : mov !sound_notes+x,a
mov a,!sound_targetNotes+x : cmp a,!sound_notes+x : bne ++
mov a,#$00
mov !sound_pitchSlideFlags+x,a
mov !sound_legatoFlags+x,a

++
mov a,!sound_notes+x : mov y,a : mov a,!sound_subnotes+x : movw !note,ya
mov x,!i_voice : call playNoteDirect

.branch_end
ret
}
