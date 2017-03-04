*-----------------------------------------------------------
* Title      : ROM Burner
* Written by : Chandler Griscom
*-----------------------------------------------------------

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
BAUD        EQU $CC     baud rate value = 38400 baud

BS          EQU $08
CR          EQU $0D
LF          EQU $0A 

N_CONFIRMS  EQU 2 ; How many times should the toggle bit be verified?

            ORG     $160000

; D6: Toggle bit status
; A2: Subroutine address for write operation
; begin program
MAIN        OR.W  #$0700, SR 

            JSR INIT_DUART TODO replace with RAM subroutine
            
LOOP        MOVE.L #CLS, A0
            JSR PUTSTR
            MOVE.L #MAINPrompt, A0
            JSR PUTSTR
            
            JSR ROM_CODES ; Print manufacturer codes
            MOVE.L #TableString, A0
            JSR PUTSTR
            MOVE.L #MANUString, A0
            JSR PUTSTR
            JSR PRINT2CODE
            MOVE.L #IDString, A0
            JSR PUTSTR
            MOVE.W D1, D0
            JSR PRINT2CODE
            MOVE.L #DatString, A0
            JSR PUTSTR
            MOVE.W $000000, D0
            JSR PRINT2CODE
            MOVE.L #EndLine, A0
            JSR PUTSTR
            
            
LOOP_GET    JSR GETCHAR_A
            
            CMP.B #'b', D0 If user says 'b', load boot S record
            BEQ S_REC_BOOT 
            
            CMP.B #'c', D0 If user says 'c', enter copy mode
            BEQ COPY_LO_HI
            
            CMP.B #'h', D0 If user says 'h', hotswap
            BEQ hotswap
            
            CMP.B #'r', D0 If user says 'r', refresh
            BEQ LOOP
            
            CMP.B #'R', D0 If user says 'R', return to monitor
            BEQ RETURN
            
            BRA LOOP_GET
            
RETURN      RTS
            
PRINT2CODE  JSR BIN2HEX
            ROL.L #8, D0
            JSR PUTCHAR_A
            ROL.L #8, D0
            JSR PUTCHAR_A
            MOVE.B #' ', D0
            JSR PUTCHAR_A
            ROL.L #8, D0
            JSR PUTCHAR_A
            ROL.L #8, D0
            JSR PUTCHAR_A
            MOVE.B #CR, D0
            JSR PUTCHAR_A
            MOVE.B #LF, D0
            JSR PUTCHAR_A
            RTS

presskey    MOVE.L #PressKeyStr, A0
            JSR PUTSTR
            JSR GETCHAR_A
            BRA LOOP

hotswap     
   ;      4          3       2              1             0
   ;  ROM_Hotswap    Spk  Reset_UART  En_GPI_FlowCtrl    N/A
            MOVE.B #$AA, D0 LED Code
            MOVE.L #HotEnable, A0 Notify user of instructions
            JSR PUTSTR
            EOR.B #$04, CPLD_STATUS Reset DUART
            OR.B #$10, CPLD_STATUS Pause CPU
            
            ; Wait for reset button press...
            
            EOR.B #$04, CPLD_STATUS Resume DUART
            JSR INIT_DUART
            MOVE.B CPLD_STATUS, LED
            BRA LOOP
            
* Subroutine ROM_PRES_B
* Keys the 2-cycle software control codes into both rom chips
ROM_PRES_B  MOVE.W #$AAAA, $00AAAA
            MOVE.W #$5555, $005554
            RTS
            
            
* Subroutine ROM_CODES
* Fetches the manufacturer ID byte from 2 ROM chips into D0.W
* Fetches the software product ID byte from 2 ROM chips into D0.W
ROM_CODES   JSR ROM_PRES_B
            MOVE.W #$9090, $00AAAA ;Software entry mode
           
            MOVE.W $000000, D0 ; Manu ID (BF)
            MOVE.W $000002, D1 ; Dev ID (B7)
            
            MOVE.W #$F0F0, $00ABC0 ;Exit software entry mode
            RTS
            
ERASE_BOOT  LEA $000000, A6 Store high-byte toggling address here
            MOVE.L #ErasingBoot, A0
            JSR PUTSTR
            JSR ROM_PRES_B
            MOVE.W #$8080, $00AAAA ;Erase sector pt1
            JSR ROM_PRES_B
            MOVE.W #$3030, (A6) ;Erase sector pt2
            JSR CP_toggle   Wait until erased
            LEA $000001, A6 Store low-byte toggling address here
            JSR CP_toggle   Wait until erased
            MOVE.L #ErasedBoot, A0
            JSR PUTSTR
            RTS
            
ERASE_HIGH  LEA $000000, A6 Store high-byte toggling address here
            MOVE.L #ErasingHi, A0
            JSR PUTSTR
            JSR ROM_PRES_B
            MOVE.W #$8000, $00AAAA ;Erase High pt1
            JSR ROM_PRES_B
            MOVE.W #$1000, $00AAAA ;Erase High pt2
            JSR CP_toggle   Wait until erased
            MOVE.L #ErasedHi, A0
            JSR PUTSTR
            RTS
            
ERASE_LOW   LEA $000001, A6 Store low-byte toggling address here
            MOVE.L #ErasingLo, A0
            JSR PUTSTR
            JSR ROM_PRES_B
            MOVE.W #$0080, $00AAAA ;Erase High pt1
            JSR ROM_PRES_B
            MOVE.W #$0010, $00AAAA ;Erase High pt2
            JSR CP_toggle   Wait until erased
            MOVE.L #ErasedLo, A0
            JSR PUTSTR
            RTS
            
 ;----- Copy Routine -----;
COPY_LO_HI  
            JSR ERASE_HIGH
            LEA $000000, A6 Store high-byte toggling address here

            
COPY_LOOP   
COPY_WRITE  JSR ROM_PRES_B
            MOVE.W #$A000, $00AAAA ;Write pt 1
            MOVE.B 1(A6), D0 ; Get byte
            MOVE.B D0, (A6)  ; Write byte
            

            
            ; Advance address
            MOVE.L A6, D1
            ADDI.L #2, D1
            MOVE.L D1, A6
            MOVE.B D1, LED
            

            ;JSR BIN2HEX
            ;JSR PUTCHAR_A
            
            
            MOVE.L #$100000, D4 ; REMOVE THIS LINE D4 contains finished address 100000
            CMP.L D4, D1  ; Is addr exceeding ROM bounds?
            BEQ COPY_DONE ; Done; return to menu
            
            JSR CP_toggle ; Verify using toggle bit

            BRA COPY_WRITE
            
COPY_DONE   BRA PressKey
            
; Sub: Wait for toggle bit to stop toggling on hi ROM
;  A6: the address to be checked
CP_toggle   MOVE.B #1, D4      Clear D4 (ROL status)
            MOVE.B (A6), D1    Read toggle bit to D1
CP_toggle2  ;MOVE.B #'x', D0    TODO remove confirm code
            ;JSR PUTCHAR_A
            BTST #N_CONFIRMS, D4 Test bit for N confirms
            BNE CP_tog_RET     If that bit is high, confirmation succeeded 3 times
            MOVE.B D1, D2      Save previous toggle bit
            MOVE.B (A6), D1    Read new toggle bit to D1
            EOR.B D1, D2       EOR new byte onto old one
            BTST #6, D2        If EOR indicates the byts are different (toggle bit6 = 1)
            BNE CP_toggle2     If same (0), continue.  If different (1), start over
            ROL.B #1, D4       Rotate D4 bit (same)
            ;MOVE.B #'0', D0    TODO remove confirm code
            ;JSR PUTCHAR_A
            BRA CP_toggle2     Return
CP_tog_RET  RTS
 ;----- End Copy Routine -----;
 
* Subroutine WRITE_BYTE
* D1: Data Byte
* A1: Address for write
* D3: Reserved
WRITE_BYTE  
            MOVE.L A1, D3
            BTST #0, D3
            BNE WRITE_ODD     If set (1), go to odd
            
            ;Even/High
WRITE_EVEN  JSR ROM_PRES_B
            MOVE.W #$A000, $00AAAA ;Erase High pt2;Write pt 1
            MOVE.B D1, (A1)  ; Write byte
            MOVE.L A1, A6 Store toggling address here
            ;MOVE.B D1, LED ; debug
            JSR CP_toggle
            RTS
            
            ;Odd/Low
WRITE_ODD   JSR ROM_PRES_B
            MOVE.W #$00A0, $00AAAA ;Erase High pt2;Write pt 1
            MOVE.B D1, (A1)  ; Write byte
            MOVE.L A1, A6 Store toggling address here
            ;MOVE.B D1, LED ; debug
            JSR CP_toggle
            RTS
 
 
 ;----- S Records -----;
S_REC_BOOT  JSR ERASE_BOOT
            LEA WRITE_BYTE, A2 ; Load write procedure into A2
            
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
            NOP
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
            JSR (A2) ; Jump to previously defined write routine location
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
            BRA presskey
            
            
S9          CMP.B #$39, D7 If this is a S9 record...
            BNE ERROR If it's not an S9 at this point something went wrong
            BRA S8_Valid S8 code does the same thing
            
            ; Else Error!
ERROR       MOVE.L #SRecError, A0
            JSR PUTSTR
            JSR LOOP
            

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

; TODO remove after bootloader is finished
INIT_DUART  ;Reset Duart
            MOVE.B #30, CRA
            MOVE.B #20, CRA
            MOVE.B #10, CRA
            
            MOVE.B #$00,ACR    selects baud rate set 1
            ;MOVE.B #$80,ACR    selects baud rate set 2
            MOVE.B #BAUD,CSRA  set 19.2k (1: 36.4k) baud Rx/Tx
            MOVE.B #$13,MR1A   8-bits, no parity, 1 stop bit
            MOVE.B #$07,MR2A   07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
            MOVE.B #$05,CRA    enable Tx and Rx
            
            MOVE.B #$00,IMR
            RTS
            


; GETCHAR puts the read character into D0
GETCHAR_A   MOVE.B SRA, D0  Read the A status register
            BTST #RxRDY, D0 Test reciever ready status
            BEQ GETCHAR_A   UNTIL char recieved
            MOVE.B RBA, D0  Read the character into D0
            RTS

; PUTCHAR_A outputs D0 to the DUART channel A
PUTCHAR_A   MOVE.W D0, -(SP)
PUTCHAR_Apl  MOVE.B SRA, D0
            BTST   #TxRDY, D0
            BEQ    PUTCHAR_Apl
            MOVE.W (SP)+, D0
            MOVE.B D0, TBA
            RTS
            
* TODO Callable RAM routines

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

MAINPrompt  DC.B       '------ ROM Burner ------',CR,LF
            DC.B       'b: Write the boot record',CR,LF
            DC.B       'c: Copy low to high',CR,LF
            DC.B       'h: Pause and hotswap ROM',CR,LF
            DC.B       'r: Refresh',CR,LF
            DC.B       'R: Exit ROMBurner',CR,LF,CR,LF,0
ENDLine     DC.B       '------------------------',CR,LF,0
SRecInsert  DC.B '.',0
SRecError   DC.B CR,LF,'Error reading S record.',CR,LF,0
HotEnable   DC.B 'HOTSWAPPING ENABLED',CR,LF,'Carefully reseat the',CR,LF,'ROM chips, then press',CR,LF,'the reset button.',CR,LF,0
TableString DC.B 'Chip #:          HI LO',CR,LF,0
MANUString  DC.B 'Manufacturer ID: ',0
IDString    DC.B 'Product ID:      ',0
DatString   DC.B 'Data at $0:      ',0
CLS         DC.B $1B,'[2J',$1B,'[H',0
PressKeyStr DC.B CR,LF,'Press any key to continue...',CR,LF,0
ErasingHi   DC.B 'Erasing high...',CR,LF,0
ErasedHi    DC.B 'Erased high.',CR,LF,0
ErasingLo   DC.B 'Erasing low...',CR,LF,0
ErasedLo    DC.B 'Erased low.',CR,LF,0
ErasingBoot DC.B 'Erasing boot record ($0000 -> $1FFF)...',CR,LF,0
ErasedBoot  DC.B 'Erased boot record.',CR,LF,0


            END     MAIN
            







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
