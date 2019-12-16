; Samus fanfare
musicTrack1:
{
.tracker
dw .trackPointers, $0000

.trackPointers
dw .track0, .track1, .track2, .track3, .track4, .track5, .track6, $0000

.track0
db $FA, $26, $E7, $12, $E5, $B4, $F5, $0F, $0A, $0A, $F7, $02, $0A, $00, $E0, $0B,\
   $EA, $F4, $F4, $46, $E1, $0A, $ED, $AA, $EE, $18, $DC, $18, $7F, $B2, $ED, $AA,\
   $EE, $18, $DC, $B5, $ED, $AA, $EE, $18, $DC, $B2, $ED, $AA, $EE, $18, $DC, $B0,\
   $30, $AD, $ED, $AA, $EE, $30, $82, $AD, $0F, $C9, $00

.track1
db $E0, $0B, $EA, $F4, $F4, $46, $E1, $0A, $03, $C9, $ED, $64, $EE, $28, $FA, $04,\
   $7F, $A6, $A6, $A6, $A6, $A6, $A6, $A9, $A9, $A9, $A9, $A9, $A9, $ED, $FA, $EE,\
   $28, $64, $A6, $A6, $A6, $A6, $A6, $A6, $A4, $A4, $A4, $A4, $A4, $A4, $ED, $3C,\
   $EE, $0A, $E6, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD,\
   $AD, $AD, $AD, $ED, $E6, $EE, $1E, $3C, $AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD,\
   $0C, $C9

.track2
db $E0, $0B, $EA, $00, $F4, $46, $ED, $C8, $E1, $03, $18, $7F, $8F, $8E, $ED, $B4,\
   $8C, $89, $30, $82, $82, $0F, $C9

.track3
db $E0, $0B, $EA, $00, $F4, $1E, $ED, $C8, $E1, $11, $03, $C9, $18, $7F, $8F, $8E,\
   $8C, $89, $F4, $00, $30, $82, $2D, $82, $0F, $C9

.track4
db $E0, $0B, $EA, $F4, $F4, $46, $ED, $BE, $E1, $0A, $18, $7F, $A2, $A1, $9F, $A1,\
   $30, $8E, $8E, $0F, $C9

.track5
db $E0, $02, $F4, $00, $E1, $06, $ED, $3C, $EE, $32, $82, $05, $C9, $05, $7F, $93,\
   $0A, $C9, $0F, $97, $14, $C9, $08, $93, $E1, $08, $04, $C9, $95, $C9, $97, $0B,\
   $C9, $E1, $03, $05, $C9, $93, $0A, $C9, $0F, $93, $1E, $C9, $08, $90, $E1, $0D,\
   $04, $C9, $93, $C9, $ED, $AA, $EE, $1E, $14, $93, $1C, $C9

.track6
db $E0, $02, $F4, $00, $E1, $0E, $ED, $3C, $EE, $32, $82, $05, $7F, $91, $1E, $C9,\
   $06, $C9, $93, $10, $C9, $E1, $0C, $04, $93, $C9, $90, $C9, $09, $93, $E1, $11,\
   $05, $91, $24, $C9, $06, $93, $10, $C9, $E1, $07, $04, $93, $0E, $C9, $04, $97,\
   $C9, $06, $97, $ED, $AA, $EE, $1E, $14, $04, $93, $14, $C9, $00
}

; Item fanfare
musicTrack2:
{
.tracker
dw .trackPointers, $0000

.trackPointers
dw .track0, .track1, .track2, .track3, .track4, .track5, .track6, $0000

.track0
db $FA, $26, $E7, $2D, $E5, $96, $F5, $0F, $0A, $0A, $F7, $02, $0A, $00, $E0, $0B,\
   $F4, $46, $EA, $00, $ED, $E6, $E1, $03, $60, $7F, $8A, $89, $87, $2A, $82, $E5,\
   $AA, $E6, $28, $3C, $C8, $04, $C9, $00

.track1
db $E0, $0B, $F4, $46, $EA, $00, $ED, $E6, $E1, $11, $60, $7F, $8A, $89, $87, $54,\
   $82, $04, $C9

.track2
db $E0, $0B, $F4, $46, $EA, $00, $ED, $DC, $E1, $06, $30, $7F, $9A, $18, $9D, $A2,\
   $30, $A1, $9C, $A2, $18, $9D, $9A, $54, $9A, $04, $C9

.track3
db $E0, $0B, $F4, $46, $EA, $00, $ED, $DC, $E1, $0E, $60, $7F, $9D, $9C, $9A, $54,\
   $95, $04, $C9

.track4
db $E0, $0B, $F4, $46, $EA, $00, $ED, $D2, $E1, $0A, $04, $C9, $18, $7F, $9D, $A2,\
   $A4, $A6, $A8, $A4, $9F, $A4, $ED, $A0, $A9, $ED, $BD, $A6, $A2, $9F, $54, $C9

.track5
db $E0, $0B, $F4, $46, $EA, $00, $ED, $DC, $E1, $08, $1C, $7F, $9D, $14, $C9, $1C,\
   $A4, $14, $C9, $1C, $A8, $14, $C9, $1C, $9F, $14, $C9, $ED, $C8, $1C, $A9, $E8,\
   $A0, $0A, $ED, $E5, $14, $C9, $1C, $A2, $14, $C9, $E1, $0A, $54, $A1, $04, $C9

.track6
db $E0, $0B, $F4, $46, $EA, $00, $ED, $AA, $E1, $0C, $18, $C9, $1C, $7F, $A2, $14,\
   $C9, $18, $A6, $04, $C8, $14, $C9, $1C, $A4, $14, $C9, $18, $A4, $04, $C8, $14,\
   $C9, $1C, $A6, $14, $C9, $18, $9F, $04, $C8, $50, $C9, $04, $C9, $00
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
db $E5, $DC, $E7, $10, $E0, $0C, $F4, $28, $ED, $46, $E1, $07, $F5, $0F, $0A, $0A,\
   $F7, $02, $0A, $00, $30, $C9, $18, $2F, $BA, $B5, $B9, $B1, $48, $C9, $18, $B0,\
   $B6, $BB, $C9, $C9, $18, $1F, $B5, $0C, $C9, $18, $B2, $0C, $C9, $24, $C9, $60,\
   $C9, $C9, $0C, $C9, $00

.loopTrack1
db $E0, $0C, $F4, $28, $ED, $32, $E1, $0A, $30, $C9, $18, $2F, $A6, $A1, $A5, $9D,\
   $48, $C9, $18, $9C, $A2, $A7, $C9, $C9, $AD, $0C, $C9, $18, $AA, $0C, $C9, $21,\
   $C9, $60, $C9, $C9, $0F, $C9

.loopTrack2
db $E0, $0C, $F4, $28, $ED, $3C, $E1, $0D, $20, $C9, $06, $0F, $BA, $B5, $B9, $B1,\
   $B0, $B6, $BB, $2A, $C9, $06, $BA, $B5, $B9, $B1, $B0, $B6, $BB, $36, $C9, $06,\
   $B9, $B1, $BA, $B5, $B0, $B6, $BB, $3E, $C9, $06, $BA, $B5, $B9, $B1, $B0, $B6,\
   $BB, $20, $C9, $06, $B5, $BA, $B9, $B1, $B0, $B6, $BB, $11, $C9, $60, $C9, $C9,\
   $07, $C9

.loopTrack3
db $E0, $0B, $F4, $46, $E1, $0A, $ED, $3C, $EE, $3C, $C8, $3C, $7F, $80, $ED, $C8,\
   $EE, $30, $3C, $30, $C8, $EF, $88, $56, $05

.introTrack0
db $FA, $26, $E7, $10, $E5, $C8, $E0, $0C, $F4, $28, $ED, $46, $F5, $0F, $0A, $0A,\
   $F7, $02, $0A, $00, $E1, $07, $E2, $C0, $0D, $0C, $C9, $00

.introTrack1
db $E0, $0C, $F4, $28, $ED, $32, $0C, $C9

.introTrack2
db $E0, $0C, $F4, $28, $ED, $3C, $0C, $C9

.introTrack3
db $E0, $0B, $F4, $46, $E1, $0A, $0C, $C9

.introTrack4
db $E0, $0C, $F4, $28, $ED, $28, $E1, $0D, $0C, $C9, $00, $ED, $3C, $EE, $3C, $C8,\
   $3C, $80, $ED, $C8, $EE, $30, $3C, $30, $C8, $00
}

; Pre-statue hall
musicTrack4:
{
.tracker
- : dw .trackPointers, $00FF,-, $0000

.trackPointers
dw .track0, $0000, $0000, $0000, $0000, $0000, $0000, $0000

.track0
db $FA, $26, $E7, $10, $E5, $E6, $F5, $01, $00, $00, $F7, $02, $00, $00, $E0, $0B,\
   $F4, $46, $E1, $0A, $ED, $32, $EE, $3C, $B4, $3C, $7F, $80, $ED, $B4, $EE, $30,\
   $32, $30, $C8, $ED, $32, $EE, $3C, $B4, $3C, $80, $ED, $B4, $EE, $30, $32, $30,\
   $C8, $00, $00
}
