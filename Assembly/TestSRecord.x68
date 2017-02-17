*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $161000
START:                  ; first instruction of program

* Put program code here

LOOP
    MOVE.B #$AA, $F00001
    NOP
    MOVE.B #$0F, $F00001
    NOP
    MOVE.B #$55, $F00001
    NOP
    MOVE.B #$0F, $F00001
    JMP LOOP

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
