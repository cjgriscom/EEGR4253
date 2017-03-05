*-----------------------------------------------------------
* Title      : S Record Test Program
* Written by : Chandler Griscom
*-----------------------------------------------------------

SIM         EQU 0       ;0 = hardware state, 1 = simulation state
GETCHAR_A   EQU $10C8
PUTCHAR_A   EQU $113A
PUTSTR_A    EQU $116E
CR          EQU $0D
LF          EQU $0A 
; RC H-Bridge Controller
; D7 holds car state

            ORG     $140000
; begin program
MAIN        LEA CarPrompt, A0
            JSR PUTSTR_A
            MOVE.B #$00, $F00001
            CLR.B D7
            
LOOP        MOVE.B D7, $F00001
            JSR GETCHAR_A
            CMP.B #'w', D0
            BEQ MOVEUP
            CMP.B #'a', D0
            BEQ MOVELEFT
            CMP.B #'s', D0
            BEQ MOVEDOWN
            CMP.B #'d', D0
            BEQ MOVERIGHT
            CMP.B #'q', D0
            BEQ STOP
            CMP.B #'r', D0
            BEQ RETURN
            
            BRA LOOP
            
            MOVE.B #$00, $F00001
RETURN      RTS
            
MOVEUP      AND.B #$FC, D7 ; Clear last 2 bits
            OR.B #$01, D7  ; Activate bit 0
            BRA LOOP
            
MOVEDOWN    AND.B #$FC, D7 ; Clear last 2 bits
            OR.B #$02, D7  ; Activate bit 1
            BRA LOOP
            
MOVELEFT    AND.B #$F3, D7 ; Clear bits 2-3
            OR.B #$04, D7  ; Activate bit 2
            BRA LOOP
            
MOVERIGHT   AND.B #$F3, D7 ; Clear bits 2-3
            OR.B #$08, D7  ; Activate bit 3
            BRA LOOP

STOP        MOVE.B #$00, D7
            BRA LOOP

            
            
            
CarPrompt   DC.B $1B,'[2J',$1B,'[H','--------- RC Car Controller ---------',CR,LF
            DC.B                    'Use w/a/s/d for directional control',CR,LF
            DC.B                    'Press q to stop movement.',CR,LF
            DC.B                    'Press r to exit.',CR,LF
            DC.B                    '-------------------------------------',CR,LF,0


            END     MAIN













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
