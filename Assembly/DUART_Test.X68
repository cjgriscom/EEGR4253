*-----------------------------------------------------------
* Program    : DUARTTest
*-----------------------------------------------------------



SUPER_STACK EQU $104000
TIMER_SEC   EQU $100000
TIMER_MS    EQU $100004

CPLD_STATUS EQU $300001

LED         EQU $F00001

MR1A   	    EQU $200001 Mode Register1
MR2A  	    EQU $200001	points here after MR1A is set
SRA    	    EQU $210001 Status Register (read)
CSRA    	EQU $210001 Clock Select Register
CRA   	    EQU $220001	Command Register
TBA		    EQU $230001 Transfer Holding Register
RBA		    EQU $230001	Receive Holding Register
ACR		    EQU	$240001	Auxiliary control register
RxRDY		EQU	0	    Recieve ready bit position
TxRDY		EQU	2	    Transmit ready bit position
BAUD		EQU	$CC     baud rate value = 19,200 baud


START   	ORG     $000000
        	DC.L    SUPER_STACK
        	DC.L    MAIN
        	
        	ORG     $000100  Interrupt vectors   
        	DC.L    IRQ7     64: Should be GPIO IRQ
        	DC.L    IRQ7     65: Periodic

        	ORG     $000400  End of vector space
MAIN        CLR.L  TIMER_MS
            CLR.L  TIMER_SEC
            JSR INIT_DUART
            
LOOP    	JSR	RAM_TEST
            NOP
		    JMP	LOOP
        
RAM_TEST    
            
            JSR GET_CHAR
            MOVE.B D2,D0
            MOVE.B D2, LED
            JSR PUT_CHAR
            
		    RTS

INIT_DUART  ;Reset Duart
            MOVE.B #30, CRA
            MOVE.B #20, CRA
            MOVE.B #10, CRA
            
            ;MOVE.B #$00, ACR Select Baud
            ;MOVE.B BAUD, CSRA Set Baud to Constant for both rx/tx
            ;MOVE.B #$93, MR1A Set port A to 8-bit, no parity, 1 stop bit, enable RxRTS
            ;MOVE.B #$37, MR2A Set normal, TxRTS, TxCTS, 1 stop bit
            ;MOVE.B #$05, CRA Enable A transmitter/recvr
           
            MOVE.B #$80,ACR	   selects baud rate set 2
            MOVE.B #BAUD,CSRA  set 19.2k baud Rx/Tx
      	    MOVE.B #$13,MR1A   8-bits, no parity, 1 stop bit
            MOVE.B #$07,MR2A   07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
            MOVE.B #$05,CRA    enable Tx and Rx

            
            RTS
            
; Get_CHAR puts the read character into D2
GET_CHAR    MOVE.L D1,-(SP) Save working register
In_poll_A   MOVE.B SRA, D1  Read the A status register
            BTST #RxRDY, D1 Test reciever ready status
            BEQ In_poll_A   UNTIL char recieved
            MOVE.B RBA, D2  Read the character into D2
            MOVE.L (SP)+, D1 Restore working register
            RTS
            
PUT_CHAR    MOVE.L D1, -(SP)
Out_poll_A  MOVE.B SRA, D1          
            BTST   #TxRDY, D1
            BEQ    Out_poll_A
            MOVE.B D0, TBA
            MOVE.L (SP)+, D1
            RTS


            ORG     $001000  Periodic interrupt
IRQ7        MOVE.W  TIMER_MS, D0
            ADD.W   #$1, D0
            MOVE.W  D0, TIMER_MS
            CMPI.W  #$03E7,D0
            BLS.S   LWR1000
            CLR.W   TIMER_MS
            MOVE.L  TIMER_SEC, D0
            ADD.L   #$1, D0
            MOVE.L  D0, TIMER_SEC
           
LWR1000     RTE  Return from exception
            
            END     MAIN
            
            




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
