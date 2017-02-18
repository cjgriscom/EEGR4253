*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
BUFFER_A_SP EQU $4000
BUFFER_A_EP EQU $4004
BUFFER_A_S  EQU $4008
BUFFER_A_E  EQU $4020

    ORG    $1000
START:     MOVE.L #BUFFER_A_S, BUFFER_A_SP
            MOVE.L #BUFFER_A_S, BUFFER_A_EP             ; first instruction of program
loop        JSR READ
            JSR PUTC
            JSR READ
            JSR PUTC
            JSR READ
            JSR PUTC
            JSR READ
            JSR PUTC
            JSR GETC
            JSR PRINT
            JSR GETC
            JSR PRINT
            JSR GETC
            JSR PRINT
            JSR GETC
            JSR PRINT
            JMP loop
    SIMHALT

PRINT       MOVE.B D0, D1
            MOVE.L #06, D0
            TRAP   #15
            RTS
            
READ        MOVE.L #05, D0
            TRAP   #15
            MOVE.B D1, D0
            RTS

GETC        ; Circular queue read
            MOVE.L BUFFER_A_SP, A0   Load the start pointer
            MOVE.B (A0)+, D0       Insert the read byte
            CMP.L #BUFFER_A_E, A0 If not at end of buffer,
            BNE BUFFER_A_RF       Branch to finish
            MOVE.L #BUFFER_A_S, A0
BUFFER_A_RF MOVE.L A0, BUFFER_A_SP
            RTS

PUTC        MOVE.L BUFFER_A_EP, A0   Load the end pointer
            MOVE.B D0, (A0)+       Insert the read byte
            CMP.L #BUFFER_A_E, A0 If not at end of buffer,
            BNE BUFFER_A_WF       Branch to finish
            MOVE.L #BUFFER_A_S, A0
BUFFER_A_WF MOVE.L A0, BUFFER_A_EP
            RTS
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
