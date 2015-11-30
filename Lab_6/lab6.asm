;===================================================================
; Jordan Lee, Justin Limb, Logan Barnes
; ECE 3730
; 09.21.2015
; Description: This program takes three numbers from memory, which 
; emulate numbers from an IR sensor. It then makes a decision based
; on the three numbers given. The decisions happen if the number is
; above a threshold of 55 (hex).
;===================================================================

;Put in dummy values in order to do this lab on the new board
                ORG  $1000
M4000           EQU  $00
M4001           EQU  $10
M4002           EQU  $50


CR:             EQU   $0D        ;Return carrier in ascii
LF:             EQU   $0A        ;Linefeed in ascii

;Initialize ports for piezo speaker and button press
PORTJ           EQU   $0268      ;Port J data register for switch input
DDRJ            EQU   $026A      ;Port J direction register
DDRJ_INI        EQU   $00        ;Port J input mask
PORTT           EQU   $0240      ;Port T data register for piezo speaker output
DDRT            EQU   $0242      ;Port T direction register
DDRT_INI        EQU   $20        ;Port T(5) output mask
SWITCH_1        EQU   $01        ;Port J(0) assertion testing
SWITCH_2        EQU   $02        ;Port J(1) assertion testing
PIEZO           EQU   $20        ;Port T(5) output for piezo sound

;Other needed constants
DELAY_AMT       EQU   $B7    ;Delay is (11 + 4 x   ) X j

PRINTF          EQU   $EE88      ;9S12

DEBUG           FCC                'DEBUG'
                DB CR,LF,0

                ;ORG $2000
THRESH          EQU  $55           ;Store the value 55 as TRESHOLD
                ORG  $2000         ;Start the program here
                JSR  POLL_SWITCH_1
                
                LDD  #DEBUG        ;Display debug message
                LDX  PRINTF
                JSR  0,X
                
                LDX  #$02          ;Put the amount for time delay into X (seconds)
                JSR  DELAY_SEC
                
                LDD  #DEBUG        ;Display debug message
                LDX  PRINTF
                JSR  0,X
                
                LDAA #M4000        ;Get input from sensor
                STAA $2800         ;Store input to 800
                LDAA #M4001        ;Repeat for next value
                STAA $2801
                LDAA #M4002        ;Repeat for final value
                STAA $2802
                LDAA #THRESH       ;Load THRESHOLD to Accumulator A
                CMPA $2800         ;Compare to value in 800
                BHI  GT1           ;Branch if greater than THRESHOLD
                LDAB #$1           ;Get Summation of 1 through 5
                ADDB #$2
                ADDB #$3
                ADDB #$4
                ADDB #$5
                STAB $2800         ;Store summation in 800
GT1             LDAA #THRESH       ;Check the second value
                CMPA $2801
                BHI  GT2
                LDAB #$00          ;Store 00 to 801
                STAB $2801
GT2             LDAA #THRESH       ;Check the third value
                CMPA $2802
                BHI  GT3
                LDAB $2802         ;Subtract 10 from 802
                SUBB #$10
                STAB $2802
GT3             JSR  GT3           ;Software Interrupt to hold information on the screen

POLL_SWITCH_1   LDAA PORTJ         ;Load A with port J for detecting switch
                ANDA #SWITCH_1     ;Verify port j(0) for testing switch
                CMPA #SWITCH_1     ;Is port j(0) a high?
                BNE  POLL_SWITCH_1 ;If no switch contact, poll again

                LDY     #$015E             ;Chirp length ((1/3500) * 0x15E = 100 mS)
CHIRP           LDAA    #PIEZO             ;Port T(5) mask into A
                STAA    PORTT              ;Output high to piezo port T(5)
                BSR     DELAY              ;Square wave time high
                CLRA
                STAA    PORTT              ;Turn off piezo
                BSR     DELAY              ;Square wave time low
                DEY
                BNE     CHIRP
                RTS
                
;DEL interval equals 250nS ((24MHz BUS speed / 1) * 6 cycles = 250nS)
;250nS * 0x236 = 143 uS --> (1 / (143 uS * 2 Delays) = 3.5 KHz Tone)
DELAY           LDX     #$0236
DEL             DEX                        ;1 cycle
                INX                        ;1 cycle
                DEX                        ;1 cycle
                BNE     DEL                ;3 cycles
                RTS

;Register X will have the amount in milliseconds for the delay
;Each cycle takes 40 nanoseconds to complete. 1 millisecond is 25000 cycles
;Each repetition of the subroutine will take 1 millisecond
DELAY_MSEC      DEX           ; 1 cycle
                PSHX          ;
                PULX
                BNE  DELAY_MSEC
                RTS

;This subroutine calls the DELAY_MSEC 1000 times. 1000 milliseconds = 1 second
DELAY_SEC       LDY     #$03E8
                PSHX
D_SEC           LDX     #$13E8
                JSR     DELAY_MSEC
                DEY
                BNE     D_SEC
                PULX
                BNE     DELAY_SEC
                RTS


PRINT_LCD       LDD     #DEBUG        ;Display switch assertion message
                LDX     PRINTF
                JSR     0,X
                RTS

POLL_SWITCH_2   LDAA PORTJ         ;Load A with port J for detecting switch
                ANDA #SWITCH_2     ;Verify port j(1) for testing switch
                CMPA #SWITCH_2     ;Is port j(1) a high?
                BNE  POLL_SWITCH_2 ;If no switch contact, poll again

                
                JSR  PRINT_LCD
                RTS