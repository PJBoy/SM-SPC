memclear_8bit:
{
;; Parameters
;;     !misc0: Destination
;;     Y: Size. 0 = 100h bytes

mov a,#$00
decw !misc0

-
mov (!misc0)+y,a
dec y : bne -

+
incw !misc0
ret
}

memclear:
{
;; Parameters
;;     !misc0: Destination
;;     !misc1: Size

; Clear blocks of 100h bytes
mov x,!misc1+1
beq +

mov y,#$00
-
call memclear_8bit
inc !misc0+1
dec x : bne -

+
; Clear the remaining bytes if any
mov y,!misc1
beq +
call memclear_8bit

+
ret
}
