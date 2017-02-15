*-----------------------------------------------------------
* Program    : InterruptTest
*-----------------------------------------------------------



SUPER_STACK     EQU     $104000	; MUST BE A VALID RAM LOCATION
TIMER           EQU     $100000


START   	ORG     $000000
        	DC.L    SUPER_STACK
        	DC.L    MAIN
        	
        	ORG     $000100 -- Interrupt vectors   
        	DC.L    IRQ7     -- 64: Should be GPIO IRQ
        	DC.L    IRQ7     -- 65: Periodic

        	ORG     $000400 -- End of vector space
MAIN        MOVE.L  #$0, D0
            MOVE.L  d0, TIMER
LOOP    	JSR	RAM_TEST
		    JMP	LOOP
        
RAM_TEST    MOVE.L  $110000, D0
            
		    RTS




            ORG     $000900 -- Periodic interrupt
IRQ7        MOVE.L  $110000, D0
            ADD.L   #$1, D0
            MOVE.L  D0, $110000
            DIVU.W  #$3E8, D0
            MOVE.B  D0, D1
            MOVE.B  D1, $F00000
            RTE -- Return from exception
            
            END     MAIN
            
            



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
