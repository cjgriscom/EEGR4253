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
        
RAM_TEST 	NOP
        	NOP
		    NOP
		    RTS

        	END     MAIN

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
