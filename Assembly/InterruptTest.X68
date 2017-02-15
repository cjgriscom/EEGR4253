*-----------------------------------------------------------
* Program    : InterruptTest
*-----------------------------------------------------------



SUPER_STACK     EQU     $00010face	; MUST BE A VALID RAM LOCATION



START   	ORG     $000000
        	DC.L    SUPER_STACK
        	DC.L    MAIN
        	
        	ORG     $000100 -- Interrupt vectors   
        	DC.L    IRQ7     -- 64: Should be GPIO IRQ
        	DC.L    IRQ7     -- 65: Periodic

        	ORG     $000400 -- End of vector space        
MAIN    	JSR	RAM_TEST
		    JMP	MAIN
        
RAM_TEST 	NOP
        	NOP
        	NOP
		    RTS




            ORG     $000900 -- Periodic interrupt       
IRQ7    	MOVE.W  #$FFFF, d0
            MOVE.W  d0, $F00000
		    MOVE.W  #$AAAA, d0
            MOVE.W  d0, $F00000
            RTE -- Return from exception
            
            END     MAIN
            
            
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
