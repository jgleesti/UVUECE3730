;===================================================================
; Jordan Lee
; ECE 3730
; 09.21.2015
; Description: This program takes three numbers from memory, which 
; emulate numbers from an IR sensor. It then makes a decision based
; on the three numbers given. The decisions happen if the number is
; above a threshold of 55 (hex).
;===================================================================

;Put in dummy values in order to do this lab on the new board
M4000       EQU $00
M4001       EQU $10
M4002       EQU $50

THRESH      EQU $55            ;Store the value 55 as TRESHOLD
            ORG $2000          ;Start the program here
            LDAA #M4000          ;Get input from sensor
            STAA $2800          ;Store input to 800
            LDAA #M4001          ;Repeat for next value
            STAA $2801
            LDAA #M4002          ;Repeat for final value
            STAA $2802
            LDAA #THRESH           ;Load THRESHOLD to Accumulator A
            CMPA $2800          ;Compare to value in 800
            BHI GT1            ;Branch if greater than THRESHOLD
            LDAB #$1            ;Get Summation of 1 through 5
            ADDB #$2
            ADDB #$3
            ADDB #$4
            ADDB #$5
            STAB $2800          ;Store summation in 800
GT1         LDAA #THRESH           ;Check the second value
            CMPA $2801
            BHI GT2
            LDAB #$00           ;Store 00 to 801
            STAB $0801
GT2         LDAA #THRESH           ;Check the third value
            CMPA $2802
            BHI GT3
            LDAB $2802          ;Subtract 10 from 802
            SUBB #$10
            STAB $2802
GT3         SWI                 ;Software Interrupt to check if numbers are correct.