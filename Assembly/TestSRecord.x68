*-----------------------------------------------------------
* Title      : S Record Test Program
* Written by : Chandler Griscom
*-----------------------------------------------------------

SIM         EQU 0       ;0 = hardware state, 1 = simulation state

;BUFFER_A_SP EQU $104000
;BUFFER_A_EP EQU $104004
;BUFFER_A_S  EQU $104008
;BUFFER_A_E  EQU $108000
SUPER_STACK EQU $103F00
TIMER_SEC   EQU $103F04
TIMER_MS    EQU $103F08

BOOTR_IPL7a EQU $10400C Use to set the address of the S record's IPL7 routine. May be modified by S record

CPLD_STATUS EQU $300001

LED         EQU $F00001

MR1A        EQU $200001 Mode Register1
MR2A        EQU $200001 points here after MR1A is set
SRA         EQU $210001 Status Register (read)
CSRA        EQU $210001 Clock Select Register
CRA         EQU $220001 Command Register
TBA         EQU $230001 Transfer Holding Register
RBA         EQU $230001 Receive Holding Register
ACR         EQU $240001 Auxiliary control register

IMR         EQU $250001 Interrupt Mask Register
ICR         EQU $250001 Interrupt control register
IVR         EQU $2C0001 Interrupt vector register

RxRDY       EQU 0       Recieve ready bit position
TxRDY       EQU 2       Transmit ready bit position
BAUD        EQU $BB     baud rate value = 9600 baud

CR          EQU $0D
LF          EQU $0A 

DU_IP_Loc   EQU     $111000
TRAP_0_Loc  EQU     $112000 ; These locs correspond to the current bootloader vectors
TRAP_1_Loc  EQU     $113000
TRAP_2_Loc  EQU     $114000

            ORG     $111000 ; Vector is set in bootloader
; DUART Interrupt... TODO check if it's from A or B serial (i.e. don't getchar)
DUART_IRQ   MOVE.L #DUART_IPL, A0
            JSR PUTSTR
            RTE  Return from exception

            ORG     $160000
; begin program
MAIN                    
            MOVE.L #IPL7routine, D0
            MOVE.L D0, BOOTR_IPL7a ; Set the current IPL7 routine to heartbeat
            
            CLR.L  TIMER_MS
            CLR.L  TIMER_SEC

            JSR INIT_DUART
            
            ;MOVE.L #BUFFER_A_S, BUFFER_A_SP Start buffer pointer at beginning
            ;MOVE.L #BUFFER_A_S, BUFFER_A_EP Start buffer pointer at beginning     
            
LOOP        
            BRA LOOP
                        
            ; Print String in A0
PUTSTR      MOVE.W D0, -(SP)
            MOVE.W D1, -(SP)
            CLR.W D1 Length will be stored here
pst_Next    CMP.W #$200, D1 If >= 512, 
            BHS pst_Quit   quit
            MOVE.B (A0)+, D0
            ADD #1, D1
            CMP.B #0, D0   If null,
            BEQ pst_Quit   quit
            JSR PUTCHAR_A
            BRA pst_Next
pst_Quit    MOVE.W (SP)+, D1
            MOVE.W (SP)+, D0
            RTS

INIT_DUART  ;Reset Duart
            ;MOVE.B #30, CRA
            ;MOVE.B #20, CRA
            ;MOVE.B #10, CRA
            
            ;MOVE.B #$00, ACR Select Baud
            ;MOVE.B BAUD, CSRA Set Baud to Constant for both rx/tx
            ;MOVE.B #$93, MR1A Set port A to 8-bit, no parity, 1 stop bit, enable RxRTS
            ;MOVE.B #$37, MR2A Set normal, TxRTS, TxCTS, 1 stop bit
            ;MOVE.B #$05, CRA Enable A transmitter/recvr
           
            ;MOVE.B #$80,ACR    selects baud rate set 2
            ;MOVE.B #BAUD,CSRA  set 19.2k baud Rx/Tx
            ;MOVE.B #$13,MR1A   8-bits, no parity, 1 stop bit
            ;MOVE.B #$07,MR2A   07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
            ;MOVE.B #$05,CRA    enable Tx and Rx
            MOVE.B #$22, IMR    set interrupt masks to just RxRDYA, RxRDYB
            MOVE.B #66, IVR     set interrupt vector
            RTS
            

; TODO HASCHAR, move getchar code into interrupt
; Get_CHAR puts the read character into D0
GETCHAR_A IF.B SIM <EQ> #00 THEN.L  --Hardware Code--
            MOVE.L D1,-(SP) Save working register
In_poll_A   MOVE.B SRA, D1  Read the A status register
            BTST #RxRDY, D1 Test reciever ready status
            BEQ In_poll_A   UNTIL char recieved
            MOVE.B RBA, D0  Read the character into D0
            MOVE.L (SP)+, D1 Restore working register
         ELSE                    --Simulation code--
            MOVE.L D1, -(SP)
            MOVE.L #05, D0
            TRAP   #15
            MOVE.B D1, D0
            MOVE.L (SP)+, D1
         ENDI
            RTS

; PUTCHAR_A outputs D0 to the DUART channel A
PUTCHAR_A IF.B SIM <EQ> #00 THEN.L  --Hardware Code--
            MOVE.L D1, -(SP)
Out_poll_A  MOVE.B SRA, D1   
            BTST   #TxRDY, D1
            BEQ    Out_poll_A
            MOVE.B D0, TBA
            MOVE.L (SP)+, D1
          ELSE                    --Simulation code--
            MOVE.L D0, -(SP) ; Task
            MOVE.L D1, -(SP) ;Char to display
            MOVE.B D0, D1
            MOVE.L #06, D0
            TRAP   #15
            MOVE.L (SP)+, D1
            MOVE.L (SP)+, D0
          ENDI
            RTS

IPL7routine MOVE.L  D0, -(SP)
            MOVE.W  TIMER_MS, D0
            ADD.W   #$1, D0
            MOVE.W  D0, TIMER_MS

            CMPI.W  #$03E7,D0
            BLS.S   IRQ7_QUIT
            CLR.W   TIMER_MS
            MOVE.L  TIMER_SEC, D0
            ADD.L   #$1, D0
            MOVE.L  D0, TIMER_SEC
            NOT D0
            MOVE.B  D0, LED
            MOVE.L #HelloWorld, A0 -- Press s to load s record
            JSR PUTSTR
IRQ7_QUIT   MOVE.L  (SP)+, D0
            RTS

    
HelloWorld  DC.B CR,LF,'Hello World!',CR,LF,0
DUART_IPL   DC.B CR,LF,'Recieved Duart interrupt!',CR,LF,0

            END     MAIN
            










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
