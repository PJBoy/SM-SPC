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

; $1ED7
memclear:
mov a,#$00
mov y,#$00

-
mov (!p_clear)+y,a : inc y : cmp y,!n_clear : bne -
ret
}
