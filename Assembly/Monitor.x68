*-----------------------------------------------------------
* Title      : S Record Test Program
* Written by : Chandler Griscom
*-----------------------------------------------------------

SIM         EQU 0       ;0 = hardware state, 1 = simulation state

BUFFER_A_SP EQU $104000
BUFFER_A_EP EQU $104004
BUFFER_A_S  EQU $104008
BUFFER_A_E  EQU $104208
SUPER_STACK EQU $103F00
TIMER_SEC   EQU $103F04
TIMER_MS    EQU $103F08
DUINT_DISABLE EQU $103F10 ; Interrupts disabled?

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
BAUD        EQU $CC     baud rate value = 19200 baud

CR          EQU $0D
LF          EQU $0A 

START       ORG     $000000
            DC.L    SUPER_STACK Initial Stack Pointer
            DC.L    MAIN        Initial PC
            DC.L    $001400   Berr
            DC.L    $001400   Address Error
            DC.L    $001400   Illegal Instruction
            DC.L    $001400   Div by zero
            
            
            ORG     $000084   TRAP vectors   
            DC.L    $113000   33: TRAP_0
            DC.L    $114000   34
            DC.L    $115000   35
            
            ORG     $000100   Interrupt vectors   
            DC.L    $112000   64: Should be GPIO IRQ
            DC.L    $001000   65: Periodic
            DC.L    $001200   66: DUART RxRDYA or RXRDYB
            
            ORG     $001000 ; Vector is set in bootloader
IPL6        MOVE.L  D0, -(SP)
            MOVE.W  TIMER_MS, D0
            ADD.W   #$1, D0
            MOVE.W  D0, TIMER_MS
            CMPI.W  #$03E7,D0
            BLS.S   IRQ6_QUIT
            CLR.W   TIMER_MS
            MOVE.L  TIMER_SEC, D0
            ADD.L   #$1, D0
            MOVE.B  D0, LED
            MOVE.L  D0, TIMER_SEC
IRQ6_QUIT   MOVE.L  (SP)+, D0
            RTE

            ORG     $001200 ; Vector is set in bootloader

; DUART Interrupt

DUART_IRQ   MOVE.L D0,-(SP)
            MOVE.L A0,-(SP)
TestA       MOVE.B SRA, D0  Read the A status register
            BTST #RxRDY, D0 Test reciever A ready status
            BEQ TestB  Goto B if no character in buffer
            MOVE.B RBA, D0  Else, Read the character into D0
            JSR PUTCHAR_A ; Echo TODO REMOVE
            
            ; Circular queue write A
            MOVE.L BUFFER_A_EP, A0 Load the end pointer
            MOVE.B D0, (A0)+       Insert the read byte
            CMP.L #BUFFER_A_E, A0 If not at end of buffer,
            BNE BUFFER_A_WF       Branch to finish
            MOVE.L #BUFFER_A_S, A0
BUFFER_A_WF MOVE.L A0, BUFFER_A_EP
            
            BRA TestA Flush buffer again (if nothing exists it will branch to TestB)
TestB
            
DU_Ret      MOVE.L (SP)+, A0
            MOVE.L (SP)+, D0
            RTE  Return from exception
            
            ORG     $001400 ; Vector is set in bootloader
EXCEPTION   LEA SUPER_STACK, SP
            MOVE.L #EXPSTRING, A0
            JSR PUTSTR
            JMP MAIN

            
            ; Begin program
            ORG     $000400 ; Vector is set in bootloader
MAIN        

            ; Init buffers
            MOVE.L #BUFFER_A_S, BUFFER_A_SP
            MOVE.L #BUFFER_A_S, BUFFER_A_EP
            
            CLR.L  TIMER_MS
            CLR.L  TIMER_SEC

            JSR INIT_DUART

            JSR ENABLE_I ;Disable all interrupts
sLOOP       
            
            MOVE.L #SRecPrompt, A0 -- Press s to load s record
            JSR PUTSTR
getLOOP     JSR GETCHAR_A
            CMP.B #'s', D0 If user says 's', load s record
            BEQ S_REC_UP 
            CMP.B #'i', D0 If user says 'i', disable interrupts
            BEQ sDISABLE_I 
            CMP.B #'I', D0 If user says 'I', enable interrupts
            BEQ sENABLE_I 
            CMP.B #'r', D0 If user says 'r', refresh
            BEQ sLOOP
            BRA getLOOP

sDISABLE_I  JSR DISABLE_I
            BRA sLOOP
sENABLE_I   JSR ENABLE_I
            BRA sLOOP
            

DISABLE_I   OR.W  #$0700, SR 
            JSR DS_DUART_IR
            RTS
            
ENABLE_I    AND.W #$F8FF, SR
            JSR EN_DUART_IR
            RTS


* Subroutine ROM_PRESEQ
* Keys the 2-cycle software control codes into both rom chips
ROM_PRESEQ  MOVE.W #$AAAA, $00AAAA
            MOVE.W #$5555, $005554
            RTS
            
* Subroutine ROM_CODES
* Fetches the manufacturer ID byte from 2 ROM chips into D0.W
* Fetches the software product ID byte from 2 ROM chips into D0.W
ROM_CODES   JSR ROM_PRESEQ
            MOVE.W #$9090, $00AAAA ;Software entry mode
           
            MOVE.W $000000, D0 ; Manu ID (BF)
            MOVE.W $000002, D1 ; Dev ID (B7)
            
            MOVE.W #$F0F0, $00ABC0 ;Exit software entry mode
            RTS

 ;----- S Records -----;
S_REC_UP    BRA NEXTLN
            
            ; Eat checksum and carriage return
CRLF_NEXTLN JSR GETCHAR_A chksum
            JSR GETCHAR_A chksum    
            JSR GETCHAR_A CR
            JSR GETCHAR_A LF            
            
NEXTLN      
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
            SUB.B #1, D6  Subtract 1 to ignore the checksum TODO add checksum functionality
            
            ; Clear working registers
            CLR.L D1
            CLR.L D5 ; Use d5 for loop index
SIZELOOP    CMP.W D6, D5 Break if i >= size
            BHS CRLF_NEXTLN
            ADD #$1, D5 i++
            ; READ AND CONVERT BYTE
            LSL.L #4, D1  Shift total left by 4
            JSR GETCHAR_A Addr MSB_Hex
            JSR HEX2BIN   Convert addr to binary halfbyte
              BCS ERROR   ERROR HANDLING
            OR.B D0, D1   Or onto D1 for addr record
            LSL.L #4, D1  Shift total left by 4
            JSR GETCHAR_A Addr LSB_Hex
            JSR HEX2BIN   Convert addr to binary halfbyte
              BCS ERROR   ERROR HANDLING
            OR.B D0, D1   Or onto D1 for addr record
            ; END READ AND CONVERT
S0          CMP.B #$30, D7 If this is a S0 record...
            BNE S1
            
            ; S0 Code: Informational Data (echo ASCII)
            MOVE.B D1, D0
            JSR PUTCHAR_A
            ; End S0 Code
            BRA SIZELOOP  Branch back to loop

S1          CMP.B #$31, D7 If this is a S1 record...
            BNE S2
            ; S1 Code: 16-bit address data
            CMP.W #1, D5  If i = 1 (incomplete)
            BEQ SIZELOOP  Continue

            CMP.W #2, D5  If i = 2 (address is ready for setting)
            BNE S1_2_Write  Write the data if i /= 3
            MOVE.L D1, A1 Copy resulting base address to A1
            CLR.L D1      Clear D1 for next round
            BRA SIZELOOP  Branch back to loop
            
S1_2_Write  ; Else this is i > 3
            MOVE.B D1, (A1)
            ADD #1, A1 Advance to next byte
            CLR.L D1      Clear D1 for next round
            ; End S1 Code
            BRA SIZELOOP Branch back to loop
            
            
S2          CMP.B #$32, D7 If this is a S2 record...
            BNE S8
            
            ; S2 Code: 24-bit address data
            CMP.W #1, D5  If i = 1 (incomplete)
            BEQ SIZELOOP  Continue
            
            CMP.W #2, D5  If i = 2 (incomplete)
            BEQ SIZELOOP  Continue

            CMP.W #3, D5  If i = 3 (address is ready for setting)
            BNE S1_2_Write  Write the data if i /= 3
            MOVE.L D1, A1 Copy resulting base address to A1
            CLR.L D1      Clear D1 for next round
            BRA SIZELOOP  Branch back to loop
            
            
S8          CMP.B #$38, D7 If this is a S8 record...
            BNE S9 
            
            ; S8 Code: 24-bit address
S8_Valid    CMP.W D6, D5  Continue if i /= size
            BNE SIZELOOP Else execute record
            
            MOVE.L D1, A1 Move to A1
            ; Eat carriage return and checksum
            JSR GETCHAR_A chk
            JSR GETCHAR_A chk
            JSR GETCHAR_A CR
            JSR GETCHAR_A LF 
            BRA EXECUTE Execute!
            
            
S9          CMP.B #$39, D7 If this is a S9 record...
            BNE ERROR If it's not an S9 at this point something went wrong
            BRA S8_Valid S8 code does the same thing
            
            ; Else Error!
ERROR       MOVE.L #SRecError, A0
            JSR PUTSTR
            JSR sLOOP
            
EXECUTE     MOVE.L #EOSString, A0 -- End of stream; press e to begin execution!!!
            JSR PUTSTR
            JSR GETCHAR_A
            CMP.B #$65, D0 If user says 'e', load s record
            BNE sLOOP Otherwise start over :(
            MOVE.B #$F0, LED  Turn on all LEDs for warning
            JMP     (A1)
 ;------ S Records ------;

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
            MOVE.B #30, CRA
            MOVE.B #20, CRA
            MOVE.B #10, CRA
            
            ;MOVE.B #$00, ACR Select Baud
            ;MOVE.B BAUD, CSRA Set Baud to Constant for both rx/tx
            ;MOVE.B #$93, MR1A Set port A to 8-bit, no parity, 1 stop bit, enable RxRTS
            ;MOVE.B #$37, MR2A Set normal, TxRTS, TxCTS, 1 stop bit
            ;MOVE.B #$05, CRA Enable A transmitter/recvr
           
            MOVE.B #$00,ACR    selects baud rate set 1
            ;MOVE.B #$80,ACR    selects baud rate set 2
            MOVE.B #BAUD,CSRA  set 19.2k (1: 36.4k) baud Rx/Tx
            MOVE.B #$13,MR1A   8-bits, no parity, 1 stop bit
            MOVE.B #$07,MR2A   07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
            MOVE.B #$05,CRA    enable Tx and Rx
            MOVE.B #66, IVR     set interrupt vector - dec 66
            JSR EN_DUART_IR    enable DUART interrupts
            
            RTS
            
            ;Enable Duart interrupts
EN_DUART_IR MOVE.B #$22, IMR    set interrupt masks to just RxRDYA, RxRDYB
            MOVE.B #$FF, DUINT_DISABLE
            RTS
            
            ;Disable Duart interrupts
DS_DUART_IR MOVE.B #$00, IMR    set interrupt masks to nothing
            CLR.B DUINT_DISABLE
            RTS


; WARNING WARNING using IF.B sim directives causes ROM access (go figure -_-)
; GETCHAR puts the read character into D0
GETCHAR_A IF.B SIM <EQ> #00 THEN.L  --Hardware Code--
            MOVE.L A0,-(SP)
In_buff_A   MOVE.L BUFFER_A_SP, D0
            CMP.L BUFFER_A_EP, D0
            BNE READ_BUFFA Start and end pointer are not equal; read buffer character
            
            ; Otherwise poll the DUART
            CMP.B #$00, DUINT_DISABLE
            BNE In_buff_A ; Interrupts are enabled; don't poll
            
In_poll_A   MOVE.B SRA, D0  Read the A status register
            BTST #RxRDY, D0 Test reciever ready status
            BEQ In_poll_A   UNTIL char recieved
            MOVE.B RBA, D0  Read the character into D0
            JMP READ_RETA
            
            ; Circular queue read
READ_BUFFA  MOVE.L BUFFER_A_SP, A0 Load the start pointer
            MOVE.B (A0)+, D0       Extract the read byte
            CMP.L #BUFFER_A_E, A0 If not at end of buffer,
            BNE BUFFER_A_RF       Branch to finish
            MOVE.L #BUFFER_A_S, A0
BUFFER_A_RF MOVE.L A0, BUFFER_A_SP
READ_RETA   MOVE.L (SP)+, A0
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

SRecPrompt  DC.B CR,LF,'----------- MONITOR PROGRAM -----------',CR,LF
            DC.B       'Press d to edit DUART settings.',CR,LF
            DC.B       'Press v to view a memory address.',CR,LF
            DC.B       'Press e to edit a memory address.',CR,LF
            DC.B       'Press V to view a memory address range.',CR,LF
            DC.B       'Press E to edit a memory address range.',CR,LF
            DC.B       'Press s to upload an S record.',CR,LF
            DC.B       'Press x to execute an S record.',CR,LF
            DC.B       'Press i to disable interrupts.',CR,LF
            DC.B       'Press I to enable interrupts.',CR,LF
            DC.B       'Press h to hotswap ROM.',CR,LF
            DC.B       '---------------------------------------',CR,LF,0
SRecInsert  DC.B CR,LF,'Insert next line:',CR,LF,0
SRecError   DC.B CR,LF,'Error reading S record.',CR,LF,0
EOSString   DC.B CR,LF,'End of stream; press e to transfer execution!',CR,LF,0
EXPSTRING   DC.B CR,LF,'Encountered exception; resetting!',CR,LF,0


            END     MAIN
            














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
