*-----------------------------------------------------------
* Title      : S Record Test Program
* Written by : Chandler Griscom
*-----------------------------------------------------------

;BUFFER_A_SP EQU $104000
;BUFFER_A_EP EQU $104004
;BUFFER_A_S  EQU $104008
;BUFFER_A_E  EQU $108000
SUPER_STACK EQU $103F00
TIMER_SEC   EQU $103F04
TIMER_MS    EQU $103F08

BOOTR_STRTa EQU $104008 Contains the address of the S record's start address
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
    
SRecPrompt  DC.B CR,LF,'Hello World!',CR,LF,0

* Put variables and constants here

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
