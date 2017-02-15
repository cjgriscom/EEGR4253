*-----------------------------------------------------------
* Program    : InterruptTest
*-----------------------------------------------------------



SUPER_STACK     EQU     $104000	; MUST BE A VALID RAM LOCATION
TIMER_SEC       EQU     $100000
TIMER_MS        EQU     $100004


START   	ORG     $000000
        	DC.L    SUPER_STACK
        	DC.L    MAIN
        	
        	ORG     $000100 -- Interrupt vectors   
        	DC.L    IRQ7     -- 64: Should be GPIO IRQ
        	DC.L    IRQ7     -- 65: Periodic

        	ORG     $000400 -- End of vector space
MAIN        CLR.L  TIMER_MS
            CLR.L  TIMER_SEC
LOOP    	JSR	RAM_TEST
		    JMP	LOOP
        
RAM_TEST    MOVE.L  $110000, D0
            
		    RTS




            ORG     $000900 -- Periodic interrupt
IRQ7        MOVE.W  TIMER_MS, D0
            ADD.W   #$1, D0
            MOVE.W  D0, TIMER_MS
            CMPI.W  #$03E7,D0
            BLS.S   LWR1000
            CLR.W   TIMER_MS
            MOVE.L  TIMER_SEC, D0
            ADD.L   #$1, D0
            MOVE.L  D0, TIMER_SEC
            MOVE.B  D0, $F00000
LWR1000     NOP
            RTE -- Return from exception
            
            END     MAIN
            
            




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
