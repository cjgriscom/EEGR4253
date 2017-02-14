*-----------------------------------------------------------
* Program    : RamTest
*-----------------------------------------------------------



SUPER_STACK     EQU     $00010face	; MUST BE A VALID RAM LOCATION


START   	ORG     $000000
        	DC.L    SUPER_STACK
        	DC.L    MAIN

        	ORG     $000100        
MAIN    	JSR	RAM_TEST
		    JMP	MAIN
        
RAM_TEST 	MOVE.W  #$FFFF, d0
            MOVE.W  d0, $F00000
        	NOP
        	NOP
		    MOVE.W  #$AAAA, d0
            MOVE.W  d0, $F00000
		    RTS

        	END     MAIN


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
