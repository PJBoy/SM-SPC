warnings disable Wfeature_deprecated
math pri on
lorom

!currentMusicTrack = $064C
!roomWidth_scrolls = $07A9
!previousPan = $07E1
!panPhase = $07E3
!layer1Position_x = $0911

org $8FE99B ; Free space
print pc," ; room_init_pan"
room_init_pan:
{
LDA #$0080 : STA !previousPan
STZ !panPhase
RTS
}

print pc," ; room_main_pan"
room_main_pan:
{
; [layer 1 X position] * FFh / ([room width in pixels] - 100h)
; [layer 1 X position] * FFh/100h / ([room width in scrolls] - 1)
; max(0, [layer 1 X position] - 1) / ([room width in scrolls] - 1)
; Close enough
; If division by zero (camera doesn't scroll), assume balanced pan

LDA !panPhase : BNE .end_phase0

LDA !roomWidth_scrolls : DEC : BNE +
LDA #$0080
BRA .calculatedPan

+
PHP : SEP #$10 : TAX
LDA !layer1Position_x : BEQ + : DEC : + : STA $4204
STX $4206
PLP
XBA : XBA : XBA : LDA $4214
; BRA .calculatedPan

.calculatedPan
CMP !previousPan : BEQ .ret
CMP #$00F2 : BEQ .ret
CMP !currentMusicTrack : BEQ .ret
STA !previousPan
LDA #$00F2 : STA $2140
INC !panPhase

.ret
RTS
.end_phase0

DEC : BNE .end_phase1
PHP : SEP #$10 : LDX $2140 : CPX #$F2 : BNE +
LDA !previousPan : STA $2140
INC !panPhase

+
PLP : RTS
.end_phase1

PHP : SEP #$10
LDX $2140 : CPX !previousPan : BNE +
LDX !currentMusicTrack : STA $2140
STZ !panPhase

+
PLP : RTS
}

; (These addresses are calculated for *after* the SPC engine repoint script)
org $D5FFB8+4*2 ; Maridia music tracker 0 track set 0 track 4+ pointers
dw $CEC3, $CF7C, $D02E, $D186 ; The tracker 1 trackset 0 track 0..3 pointers

org $D5FFB8+$10+4*2 ; Maridia music tracker 0 track set 1 track 4+ pointers
dw $CEC3, $CF7C, $D02E, $D186 ; The tracker 1 trackset 0 track 0..3 pointers

; Landing site room music + ASM pointers
org $8F9213+4 : db $1B : db $05 : org $8F9213+$12 : dw room_main_pan : org $8F9213+$18 : dw room_init_pan
org $8F922D+4 : db $1B : db $05 : org $8F922D+$12 : dw room_main_pan : org $8F922D+$18 : dw room_init_pan
org $8F9247+4 : db $1B : db $05 : org $8F9247+$12 : dw room_main_pan : org $8F9247+$18 : dw room_init_pan
