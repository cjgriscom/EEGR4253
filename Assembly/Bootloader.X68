*-----------------------------------------------------------
* Program    : Bootloader Program
* Author     : Chandler Griscom
*-----------------------------------------------------------

SIM         EQU 1       ;0 = hardware state, 1 = simulation state

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

START       ORG     $000000
            DC.L    SUPER_STACK
            DC.L    MAIN
            
            ;ORG     $000084   TRAP vectors   
            ;DC.L    TRAP_0    33
            ;DC.L    TRAP_1    34
            ;DC.L    TRAP_2    35
            
            ORG     $000100   Interrupt vectors   
            DC.L    IRQ7      64: Should be GPIO IRQ
            DC.L    IRQ7      65: Periodic
            DC.L    DUART_IRQ 66: DUART RxRDYA or RXRDYB

            ORG     $000400  End of vector space
; begin program
MAIN        CLR.L  TIMER_MS
            CLR.L  TIMER_SEC
            JSR INIT_DUART
            
            ;MOVE.L #BUFFER_A_S, BUFFER_A_SP Start buffer pointer at beginning
            ;MOVE.L #BUFFER_A_S, BUFFER_A_EP Start buffer pointer at beginning     
            
            MOVE.L #IPL7routine, BOOTR_IPL7a ; Set the current IPL7 routine to heartbeat
            
LOOP        JSR GETCHAR_A
            MOVE.L #SRecPrompt, A0 -- Press s to load s record
            JSR PUTSTR
            JSR GETCHAR_A
            CMP.B #$73, D0 If user says 's', load s record
            BNE LOOP
            
NEXTLN      ; If last read was a D8 or D9, break!!!
            
            MOVE.L #SRecInsert, A0 -- Read next line
            JSR PUTSTR
            JSR GETCHAR_A S
            JSR GETCHAR_A Code
            MOVE.B D0, D7 Move code to D7
            
            CLR.L D6      Clear D6 for OR operations
            JSR GETCHAR_A Size MSB_Hex
            JSR HEX2BIN   Convert size to binary halfbyte
              BCS ERROR   ERROR HANDLING
            MOVE.B D0, D6 Copy to D6 for size record
            LSL.B #4, D6  Shift MSB left by 4
            JSR GETCHAR_A Size LSB_Hex
            JSR HEX2BIN   Convert size to binary halfbyte
              BCS ERROR   ERROR HANDLING
            OR.B D0, D6   OR it onto D6 for a complete size byte
            
            ; Use d5 for loop index
            CLR.L D5
SIZELOOP    
D0          ; Check if D1


ERROR       MOVE.L #SRecError, A0
            JSR PUTSTR
            JSR LOOP
            
EXECUTE     MOVE.L #EOSString, A0 End of stream; transferring execution!!!!
            JSR PUTSTR
            MOVE.B #$F0, LED  Turn on all LEDs for warning
            JSR (BOOTR_STRTa)

            
            ; Print String in A0
PUTSTR      MOVE.W D0, -(SP)
            MOVE.W D1, -(SP)
            CLR.W D1 Length will be stored here
pst_Next    CMP.W #400, D1 If >= 1024, 
            BHS pst_Quit   quit
            MOVE.B (A0)+, D0
            ADD #1, D1
            CMP.B #0, D0   If null,
            BEQ pst_Quit   quit
            JSR PUTCHAR_A
            BRA pst_Next
pst_Quit    MOVE.W (SP)+, D1
            MOVE.W (SP)+, D0
            MOVE.W (SP)+, SR
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
           
            MOVE.B #$80,ACR    selects baud rate set 2
            MOVE.B #BAUD,CSRA  set 19.2k baud Rx/Tx
            MOVE.B #$13,MR1A   8-bits, no parity, 1 stop bit
            MOVE.B #$07,MR2A   07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
            MOVE.B #$05,CRA    enable Tx and Rx
            MOVE.B 66, IVR     set interrupt vector
            ;JSR EN_DUART_IR    enable DUART interrupts
            
            RTS
            
            ;Enable Duart interrupts
EN_DUART_IR MOVE.B $22, IMR    set interrupt masks to just RxRDYA, RxRDYB
            RTS
            
            ;Disable Duart interrupts
DS_DUART_IR MOVE.B $00, IMR    set interrupt masks to nothing
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
            
            ; Periodic interrupt  TODO research if SR needs to be preserved
IRQ7        JMP     (BOOTR_IPL7a)

IPL7routine MOVE.W  SR, -(SP)
            MOVE.L  D0, -(SP)
            MOVE.W  TIMER_MS, D0
            ADD.W   #$1, D0
            MOVE.W  D0, TIMER_MS
            CMPI.W  #$03E7,D0
            BLS.S   IRQ7_QUIT
            CLR.W   TIMER_MS
            MOVE.L  TIMER_SEC, D0
            ADD.L   #$1, D0
            MOVE.B  D0, LED
            MOVE.L  D0, TIMER_SEC
IRQ7_QUIT   MOVE.L  (SP)+, D0
            MOVE.W  (SP)+, SR
            RTE  Return from exception
            
            ; DUART Interrupt... TODO check if it's from A or B serial (i.e. don't getchar)
DUART_IRQ   JSR GETCHAR_A
            MOVE.B D0, LED
            JSR PUTCHAR_A
            RTE  Return from exception
            
* Subroutine DEC2BIN -- Convert ASCII Decimal to Binary
* Inputs: D0 - ASCII Byte
* Output: D0 - Converted Binary Byte
*         Carry Bit - set to 1 on error
DEC2BIN:    CMP.B   #$30, D0   ; Check if less than ASCII 0
            BLO     DEC2BINERR
            CMP.B   #$39, D0   ; Check if greater than ASCII 9
            BHI     DEC2BINERR
            SUB.B   #$30, D0   ; Subtract 30 (ASCII 0) and move on
            RTS
DEC2BINERR: ORI     #$01, SR   ; Error, set Status Register carry bit               
            RTS

* Subroutine HEX2BIN -- Convert ASCII Hex to Binary
* Inputs: D0 - ASCII Byte
* Output: D0 - Converted Binary Byte
*         Carry Bit - set to 1 on error
HEX2BIN:    CMP.B   #$30, D0
            BLO     HEX2BINERR ; Less than ASCII 0; error
            CMP.B   #$39, D0
            BHI     HEX2BIN_UC ; Greater than ASCII 9; branch to uppercase check
            SUB.B   #$30, D0   ; Within decimal range; subtract and return
            RTS
HEX2BIN_UC: CMP.B   #$41, D0
            BLO     HEX2BINERR ; Less than ASCII A; error
            CMP.B   #$46, D0
            BHI     HEX2BIN_LC ; Greater than ASCII F; branch to lowercase check
            SUB.B   #$37, D0   ; Within uppercase range; subtract and return
            RTS
HEX2BIN_LC: CMP.B   #$61, D0
            BLO     HEX2BINERR ; Less than ASCII a; error
            CMP.B   #$66, D0
            BHI     HEX2BINERR ; Greater than ASCII f; branch to lowercase check
            SUB.B   #$57, D0   ; Within lowercase range; subtract and return
            RTS 
HEX2BINERR: ORI     #$01, SR   ; Error, set Status Register carry bit               
            RTS
            
* Subroutine BIN2HEX -- Convert Binary to ASCII Hexadecimal
* Inputs: D0 - Binary Word
* Output: D0 - 4-byte ASCII String
*         Carry Bit - set to 1 on error
BIN2HEX:    MOVE.W  D1, -(SP)     ;D1 is used for rotate operations; push the old one onto stack
            MOVE.W  D0, D1        ;Move D0 to D1 for rotate operations; D0 will contain final result
            
            AND.B   #$0F, D0      ;Mask out the left 4 bits
            ADD.B   #$30, D0      ;Adjust for ASCII
            CMP.B   #$3A, D0      ;Compare with ASCII '9' + 1
            BLO     B2H_Byte2     ;If within range, go on
            ADD.B   #07, D0       ;Add 7 more to bring into the uppercase range
            
B2H_Byte2:  ROR.W   #4, D1        ;Rotate source to next half-byte
            ROR.L   #8, D0        ;Rotate destination to the next byte
            MOVE.B  D1, D0        ;Copy it over
            AND.B   #$0F, D0      ;Mask out the left 4 bits
            ADD.B   #$30, D0      ;Adjust for ASCII
            CMP.B   #$3A, D0      ;Compare with ASCII '9' + 1
            BLO     B2H_Byte3     ;If within range, go on
            ADD.B   #07, D0       ;Add 7 more to bring into the uppercase range
            
B2H_Byte3:  ROR.W   #4, D1        ;Rotate source to next half-byte
            ROR.L   #8, D0        ;Rotate destination to the next byte
            MOVE.B  D1, D0        ;Copy it over
            AND.B   #$0F, D0      ;Mask out the left 4 bits
            ADD.B   #$30, D0      ;Adjust for ASCII
            CMP.B   #$3A, D0      ;Compare with ASCII '9' + 1
            BLO     B2H_Byte4     ;If within range, go on
            ADD.B   #07, D0       ;Add 7 more to bring into the uppercase range
            
B2H_Byte4:  ROR.W   #4, D1        ;Rotate source to next half-byte
            ROR.L   #8, D0        ;Rotate destination to the next byte
            MOVE.B  D1, D0        ;Copy it over
            AND.B   #$0F, D0      ;Mask out the left 4 bits
            ADD.B   #$30, D0      ;Adjust for ASCII
            CMP.B   #$3A, D0      ;Compare with ASCII '9' + 1
            BLO     B2H_End       ;If within range, finish
            ADD.B   #07, D0       ;Add 7 more to bring into the uppercase range
            
B2H_End:    ROR.L   #8, D0        ;One more rotate so that D0 is in correct order
            MOVE.W  (SP)+, D1     ;Restore D1
            RTS

SRecPrompt  DC.B CR,LF,'Press s to upload an S record.',CR,LF,0
SRecInsert  DC.B CR,LF,'Insert next line:',CR,LF,0
SRecError   DC.B CR,LF,'Error reading S record.',CR,LF,0
EOSString   DC.B CR,LF,'End of stream; transferring execution!',CR,LF,0

            END     MAIN
            




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
