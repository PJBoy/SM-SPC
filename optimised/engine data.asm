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

; $1E80
versionString:
db $2A, $56, $65, $72, $20, $53, $31, $2E, $32, $30, $2A ; "*Ver S1.20*"
