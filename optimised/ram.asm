; Utility constants for this file
{
!sound1_n_channels = 4
!sound2_n_channels = 2
!sound3_n_channels = 2
}

macro generate(prefix, suffix, p_base, n, step)
    !i = 0
    while !i < <n>
        !{<prefix>!{i}<suffix>} #= <p_base>+!i*<step>
        !i #= !i+1
    endif
endmacro

; CPU IO cache registers
{
%generate(cpuIo, _read,      $00, 4, 1)
%generate(cpuIo, _write,     $04, 4, 1)
%generate(cpuIo, _read_prev, $08, 4, 1)
}

!musicTrackStatus = $0C
; $0D: Unused
!zero             = $0E

; Temporaries
{
!note                = $10
!panningBias         = $10
!noteOrPanningBias   = $10
!signBit             = $12
!dspVoiceVolumeIndex = $12
!noteModifiedFlag    = $13
!misc0               = $14
!misc1               = $16
}

!randomNumber            = $18
!enableSoundEffectVoices = $1A
!disableNoteProcessing   = $1B
; $1C..1F: Unused
!p_return                = $20
!p_return_word           = $0020 ; Note: specifying mov.w doesn't (currently) generate a word length operand

; Sound 1
{
!sound1_instructionListPointerSet  = $22
!sound1_p_charVoiceBitset          = $24
!sound1_p_charVoiceMask            = $26
!sound1_p_charVoiceIndex           = $28
!sound1_channel0_p_instructionList = $2A
!sound1_channel1_p_instructionList = $2C
!sound1_channel2_p_instructionList = $2E
}

!trackPointers     = $30
!p_tracker         = $40
!trackerTimer      = $42
!soundEffectsClock = $43
!trackIndex        = $44

; DSP cache
{
!keyOnFlags           = $45
!keyOffFlags          = $46
!musicVoiceBitset     = $47
!flg                  = $48
!noiseEnableFlags     = $49
!echoEnableFlags      = $4A
!pitchModulationFlags = $4B
}

; Echo
{
!echoTimer            = $4C
!echoDelay            = $4D
!echoFeedbackVolume   = $4E
; $4F: Unused
}

; Music
{
!musicTranspose                 = $50
!musicTrackClock                = $51
!musicTempo                     = $52
!dynamicMusicTempoTimer         = $54
!targetMusicTempo               = $55
!musicTempoDelta                = $56
!musicVolume                    = $58
!dynamicMusicVolumeTimer        = $5A
!targetMusicVolume              = $5B
!musicVolumeDelta               = $5C
!musicVoiceVolumeUpdateBitset   = $5E
!percussionInstrumentsBaseIndex = $5F
}

; Echo
{
!echoVolumeLeft         = $60
!echoVolumeRight        = $62
!echoVolumeLeftDelta    = $64
!echoVolumeRightDelta   = $66
!dynamicEchoVolumeTimer = $68
!targetEchoVolumeLeft   = $69
!targetEchoVolumeRight  = $6A
; $6B..6F: Unused
}

; Track
{
!trackNoteTimers                 = $70
!trackNoteRingTimers             = $71
!trackRepeatedSubsectionCounters = $80
; $81..8F: Unused
!trackDynamicVolumeTimers        = $90
!trackDynamicPanningTimers       = $91
!trackPitchSlideTimers           = $A0
!trackPitchSlideDelayTimers      = $A1
!trackVibratoDelayTimers         = $B0
!trackVibratoExtents             = $B1
!trackTremoloDelayTimers         = $C0
!trackTremoloExtents             = $C1
}

; Sounds
{
!sound1_channel3_p_instructionList = $D0
!p_echoBuffer                      = $D2
!sound2_instructionListPointerSet  = $D4
!sound2_p_charVoiceBitset          = $D6
!sound2_p_charVoiceMask            = $D8
!sound2_p_charVoiceIndex           = $DA
!sound2_channel0_p_instructionList = $DC
!sound2_channel1_p_instructionList = $DE
!sound3_instructionListPointerSet  = $E0
!sound3_p_charVoiceBitset          = $E2
!sound3_p_charVoiceMask            = $E4
!sound3_p_charVoiceIndex           = $E6
!sound3_channel0_p_instructionList = $E8
!sound3_channel1_p_instructionList = $EA
; $EC: Unused
}

!p_clear = $EE
; $F0..FF: IO ports

!trackDynamicVibratoTimers = $100 ; Note: This one is referenced in code via $00 with direct page = $100

!p_stackBegin = $01CF
; $01D0..FF: Unused

; Music
{
!trackNoteLengths                       = $0200
!trackNoteRingLengths                   = $0201
!trackNoteVolume                        = $0210
!trackInstrumentIndices                 = $0211
!trackInstrumentPitches                 = $0220
!trackRepeatedSubsectionAddresses       = $0230
!trackRepeatedSubsectionReturnAddresses = $0240
; $0250..5F: Unused
; $0260..6E: Unused
!trackPitches                           = $0261
; $0270..7F: Unused
!trackSlideLengths                      = $0280
!trackSlideDelays                       = $0281
!trackSlideDirections                   = $0290
!trackSlideExtents                      = $0291
!trackVibratoPhases                     = $02A0
!trackVibratoRates                      = $02A1
!trackVibratoDelays                     = $02B0
!trackDynamicVibratoLengths             = $02B1
!trackVibratoExtentDeltas               = $02C0
!trackStaticVibratoExtents              = $02C1
!trackTremoloPhases                     = $02D0
!trackTremoloRates                      = $02D1
!trackTremoloDelays                     = $02E0
; $02E1..EF: Unused
!trackTransposes                        = $02F0
; $02F1..FF: Unused
!trackVolumes                           = $0300
!trackVolumeDeltas                      = $0310
!trackTargetVolumes                     = $0320
!trackOutputVolumes                     = $0321
!trackPanningBiases                     = $0330
!trackPanningBiasDeltas                 = $0340
!trackTargetPanningBiases               = $0350
!trackPhaseInversionOptions             = $0351
!trackSubnotes                          = $0360
!trackNotes                             = $0361
!trackNoteDeltas                        = $0370
!trackTargetNotes                       = $0380
!trackSubtransposes                     = $0381
}

!n_clear = $0390
; $0391: Unused

; Sound 1
{
!sound1                                                    = $0392
!i_sound1                                                  = $0393
%generate(sound1_channel, _i_instructionList,                $0394, !sound1_n_channels, 1)
%generate(sound1_channel, _instructionTimer,                 $0398, !sound1_n_channels, 1)
%generate(sound1_channel, _disableByte,                      $039C, !sound1_n_channels, 1)
!sound1_i_channel                                          = $03A0
!sound1_n_voices                                           = $03A1
!sound1_i_voice                                            = $03A2
!sound1_remainingEnabledSoundVoices                        = $03A3
!sound1_initialisationFlag                                 = $03A4
!sound1_voiceId                                            = $03A5
%generate(sound1_channel, _voiceBitset,                      $03A6, !sound1_n_channels, 1)
%generate(sound1_channel, _voiceMask,                        $03AA, !sound1_n_channels, 1)
!sound1_2i_channel                                         = $03AE
%generate(sound1_channel, _voiceIndex,                       $03AF, !sound1_n_channels, 1)
!sound1_enabledVoices                                      = $03B3
%generate(sound1_channel, _dspIndex,                         $03B4, !sound1_n_channels, 1)
%generate(sound1_channel, _trackOutputVolumeBackup,          $03B8, !sound1_n_channels, 2)
%generate(sound1_channel, _trackPhaseInversionOptionsBackup, $03B9, !sound1_n_channels, 2)
%generate(sound1_channel, _releaseFlag,                      $03C0, !sound1_n_channels, 2)
%generate(sound1_channel, _releaseTimer,                     $03C1, !sound1_n_channels, 2)
%generate(sound1_channel, _repeatCounter,                    $03C8, !sound1_n_channels, 1)
%generate(sound1_channel, _repeatPoint,                      $03CC, !sound1_n_channels, 1)
%generate(sound1_channel, _adsrSettings,                     $03D0, !sound1_n_channels, 2)
%generate(sound1_channel, _updateAdsrSettingsFlag,           $03D8, !sound1_n_channels, 1)
%generate(sound1_channel, _note,                             $03DC, !sound1_n_channels, 7)
%generate(sound1_channel, _subnote,                          $03DD, !sound1_n_channels, 7)
%generate(sound1_channel, _subnoteDelta,                     $03DE, !sound1_n_channels, 7)
%generate(sound1_channel, _targetNote,                       $03DF, !sound1_n_channels, 7)
%generate(sound1_channel, _pitchSlideFlag,                   $03E0, !sound1_n_channels, 7)
%generate(sound1_channel, _legatoFlag,                       $03E1, !sound1_n_channels, 7)
%generate(sound1_channel, _pitchSlideLegatoFlag,             $03E2, !sound1_n_channels, 7)
}

; Sound 2
{
!sound2                                                    = $03F8
!i_sound2                                                  = $03F9
%generate(sound2_channel, _i_instructionList,                $03FA, !sound2_n_channels, 1)
%generate(sound2_channel, _instructionTimer,                 $03FC, !sound2_n_channels, 1)
%generate(sound2_channel, _disableByte,                      $03FE, !sound2_n_channels, 1)

!trackSkipNewNotesFlags = $0400
; $0401..0F: Unused
; $0410..3F: Unused

; Sound 2 again
!sound2_i_channel                                          = $0440
!sound2_n_voices                                           = $0441
!sound2_i_voice                                            = $0442
!sound2_remainingEnabledSoundVoices                        = $0443
!sound2_initialisationFlag                                 = $0444
!sound2_voiceId                                            = $0445
%generate(sound2_channel, _voiceBitset,                      $0446, !sound2_n_channels, 1)
%generate(sound2_channel, _voiceMask,                        $0448, !sound2_n_channels, 1)
!sound2_2i_channel                                         = $044A
%generate(sound2_channel, _voiceIndex,                       $044B, !sound2_n_channels, 1)
!sound2_enabledVoices                                      = $044D
%generate(sound2_channel, _dspIndex,                         $044E, !sound2_n_channels, 1)
%generate(sound2_channel, _trackOutputVolumeBackup,          $0450, !sound2_n_channels, 2)
%generate(sound2_channel, _trackPhaseInversionOptionsBackup, $0451, !sound2_n_channels, 2)
%generate(sound2_channel, _releaseFlag,                      $0454, !sound2_n_channels, 2)
%generate(sound2_channel, _releaseTimer,                     $0455, !sound2_n_channels, 2)
%generate(sound2_channel, _repeatCounter,                    $0458, !sound2_n_channels, 1)
%generate(sound2_channel, _repeatPoint,                      $045A, !sound2_n_channels, 1)
%generate(sound2_channel, _adsrSettings,                     $045C, !sound2_n_channels, 2)
%generate(sound2_channel, _updateAdsrSettingsFlag,           $0460, !sound2_n_channels, 1)
%generate(sound2_channel, _note,                             $0462, !sound2_n_channels, 7)
%generate(sound2_channel, _subnote,                          $0463, !sound2_n_channels, 7)
%generate(sound2_channel, _subnoteDelta,                     $0464, !sound2_n_channels, 7)
%generate(sound2_channel, _targetNote,                       $0465, !sound2_n_channels, 7)
%generate(sound2_channel, _pitchSlideFlag,                   $0466, !sound2_n_channels, 7)
%generate(sound2_channel, _legatoFlag,                       $0467, !sound2_n_channels, 7)
%generate(sound2_channel, _pitchSlideLegatoFlag,             $0468, !sound2_n_channels, 7)
}

; Sound 3
{
!sound3                                                    = $0470
!i_sound3                                                  = $0471
%generate(sound3_channel, _i_instructionList,                $0472, !sound3_n_channels, 1)
%generate(sound3_channel, _instructionTimer,                 $0474, !sound3_n_channels, 1)
%generate(sound3_channel, _disableByte,                      $0476, !sound3_n_channels, 1)
!sound3_i_channel                                          = $0478
!sound3_n_voices                                           = $0479
!sound3_i_voice                                            = $047A
!sound3_remainingEnabledSoundVoices                        = $047B
!sound3_initialisationFlag                                 = $047C
!sound3_voiceId                                            = $047D
%generate(sound3_channel, _voiceBitset,                      $047E, !sound3_n_channels, 1)
%generate(sound3_channel, _voiceMask,                        $0480, !sound3_n_channels, 1)
!sound3_2i_channel                                         = $0482
%generate(sound3_channel, _voiceIndex,                       $0483, !sound3_n_channels, 1)
!sound3_enabledVoices                                      = $0485
%generate(sound3_channel, _dspIndex,                         $0486, !sound3_n_channels, 1)
%generate(sound3_channel, _trackOutputVolumeBackup,          $0488, !sound3_n_channels, 2)
%generate(sound3_channel, _trackPhaseInversionOptionsBackup, $0489, !sound3_n_channels, 2)
%generate(sound3_channel, _releaseFlag,                      $048C, !sound3_n_channels, 2)
%generate(sound3_channel, _releaseTimer,                     $048D, !sound3_n_channels, 2)
%generate(sound3_channel, _repeatCounter,                    $0490, !sound3_n_channels, 1)
%generate(sound3_channel, _repeatPoint,                      $0492, !sound3_n_channels, 1)
%generate(sound3_channel, _adsrSettings,                     $0494, !sound3_n_channels, 2)
%generate(sound3_channel, _updateAdsrSettingsFlag,           $0498, !sound3_n_channels, 1)
%generate(sound3_channel, _note,                             $049A, !sound3_n_channels, 7)
%generate(sound3_channel, _subnote,                          $049B, !sound3_n_channels, 7)
%generate(sound3_channel, _subnoteDelta,                     $049C, !sound3_n_channels, 7)
%generate(sound3_channel, _targetNote,                       $049D, !sound3_n_channels, 7)
%generate(sound3_channel, _pitchSlideFlag,                   $049E, !sound3_n_channels, 7)
%generate(sound3_channel, _legatoFlag,                       $049F, !sound3_n_channels, 7)
%generate(sound3_channel, _pitchSlideLegatoFlag,             $04A0, !sound3_n_channels, 7)
}

; $04A8: Unused
!disableProcessingCpuIo2 = $04A9
; $04AA..B0: Unused
!i_echoFirFilterSet      = $04B1
; $04B2..B9: Unused
!sound3LowHealthPriority = $04BA
!sound1Priority          = $04BB
!sound2Priority          = $04BC
!sound3Priority          = $04BD
; $04BE..FF: Unused

!echoBufferBegin = $500
!echoBufferEnd   = $1500

; $1500..56E1: SPC engine
; $56E2..57FF: Unused

!noteRingLengthTable = $5800
!noteVolumeTable     = $5808
; $5818..1F: Unused

!trackerData = $5820
; $6819..6BFF: Unused

!instrumentTable = $6C00
; $6CEA..FF: Unused

!sampleTable = $6D00
; $6DA0..FF: Unused

; $6E00..FFFF: Sample data
