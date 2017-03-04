*-----------------------------------------------------------
* Title      : Copy RAM Buffer to ROM
* Written by : Chandler Griscom
*-----------------------------------------------------------
N_CONFIRMS  EQU 2 ; How many times should the toggle bit be verified?

            ORG     $17F000

; D6: Toggle bit status
; A0: RAM (Source) Start Address
; A1: ROM (Dest)   Start Address
; A2: RAM (Source) End Address
; begin program
COPYRR_MAIN
            BSR ERASE_SECT ; Erase initial sector TODO if this is not word-aligned it won't work
            
COPYRR_LOOP MOVE.B (A0)+, D1 ; Move data into position for copying
            BSR WRITE_BYTE   ; Write
            
            ; TODO further erases
            
            CMP.L A0, A2    ; If start != end,
            BNE COPYRR_LOOP ; then continue
            RTS


* Subroutine ROM_PRES_B
* Keys the 2-cycle software control codes into both rom chips
ROM_PRES_B  MOVE.W #$AAAA, $00AAAA
            MOVE.W #$5555, $005554
            RTS
            
* Subroutine ROM_CODES
* Fetches the manufacturer ID byte from 2 ROM chips into D0.W
* Fetches the software product ID byte from 2 ROM chips into D0.W
ROM_CODES   BSR ROM_PRES_B
            MOVE.W #$9090, $00AAAA ;Software entry mode
           
            MOVE.W $000000, D0 ; Manu ID (BF)
            MOVE.W $000002, D1 ; Dev ID (B7)
           
            MOVE.W #$F0F0, $00ABC0 ;Exit software entry mode
            RTS
            
ERASE_SECT
            BSR ROM_PRES_B
            MOVE.W #$8080, $00AAAA ;Erase sector pt1
            BSR ROM_PRES_B
            MOVE.W #$3030, (A1) ;Erase sector pt2
            BSR CP_toggle   Wait until erased
            ;ADDI #1, A1 ; High-toggling byte   TODO might not need to toggle both chips
            ;BSR CP_toggle   Wait until erased
            ;SUBI #1, A1 ; Restore A1
            RTS

; Sub: Wait for toggle bit to stop toggling on hi ROM
;  A6: the address to be checked
CP_toggle   MOVE.B #1, D4      Clear D4 (ROL status)
            MOVE.B (A1), D1    Read toggle bit to D1
CP_toggle2  
            BTST #N_CONFIRMS, D4 Test bit for N confirms
            BNE CP_tog_RET     If that bit is high, confirmation succeeded 3 times
            MOVE.B D1, D2      Save previous toggle bit
            MOVE.B (A1), D1    Read new toggle bit to D1
            EOR.B D1, D2       EOR new byte onto old one
            BTST #6, D2        If EOR indicates the byts are different (toggle bit6 = 1)
            BNE CP_toggle2     If same (0), continue.  If different (1), start over
            ROL.B #1, D4       Rotate D4 bit (same)
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
WRITE_EVEN  BSR ROM_PRES_B
            MOVE.W #$A000, $00AAAA ;Erase High pt2;Write pt 1
            MOVE.B D1, (A1)  ; Write byte
            ;MOVE.B D1, LED ; debug
            BSR CP_toggle
            RTS
            
            ;Odd/Low
WRITE_ODD   BSR ROM_PRES_B
            MOVE.W #$00A0, $00AAAA ;Erase High pt2;Write pt 1
            MOVE.B D1, (A1)  ; Write byte
            ;MOVE.B D1, LED ; debug
            BSR CP_toggle
            RTS

            END COPYRR_MAIN
            







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
