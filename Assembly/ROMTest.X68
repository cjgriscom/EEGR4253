*-----------------------------------------------------------
* Title      : RomTest
*-----------------------------------------------------------

SUPER_STACK     EQU     $00FFE  ;note this stack pointer points to a location in ROM and therefore will not function as a stack, it is simply used as a place holder.


START   ORG     $00000000

        DC.L    SUPER_STACK
        DC.L    MAIN

        ORG     $0000004E       
MAIN    NOP
        NOP
	    NOP
	    NOP
        NOP
        NOP
	    NOP
        JMP     MAIN
        
        END     MAIN

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
