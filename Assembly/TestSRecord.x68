*-----------------------------------------------------------
* Title      : S Record Test Program
* Written by : Chandler Griscom
*-----------------------------------------------------------

SIM         EQU 0       ;0 = hardware state, 1 = simulation state

            ORG     $160000
; begin program
MAIN        MOVE.B #$AA, $F00001
            MOVE.B #$55, $F00001
            RTS
            
            END     MAIN
            













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
