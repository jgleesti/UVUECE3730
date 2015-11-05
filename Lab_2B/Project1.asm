;===================================================================
; Jordan Lee
; ECE 3730
; 09.21.2015
; Description: This program takes three numbers from memory, which 
; emulate numbers from an IR sensor. It then makes a decision based
; on the three numbers given. The decisions happen if the number is
; above a threshold of 55.
;===================================================================
TRESH 	EQU $55    	;Store the value 55 as TRESHOLD
    	ORG $4100  	;Start the program here
    	LDAA $4000  	;Get input from sensor
    	STAA $0800  	;Store input to 800
    	LDAA $4001  	;Repeat
    	STAA $0801
    	LDAA $4002  	;Repeat
    	STAA $0802
    	LDAA #TRESH   	;Load THRESHOLD to Accumulator A
    	CMPA $0800  	;Compare to value in 800
    	BHI GT1    	;Branch if greater than THRESHOLD
    	LDAB #$1    	;Get Summation of 1 through 5
    	ADDB #$2
    	ADDB #$3
    	ADDB #$4
    	ADDB #$5
    	STAB $0800  	;Store summation in 800
GT1 	LDAA #TRE   	;Check the second value
    	CMPA $0801
    	BHI GT2
    	LDAB #$00   	;Store 00 to 801
    	STAB $0801
GT2 	LDAA #TRE   	;Check the third value
    	CMPA $0802
    	BHI GT3
    	LDAB $0802  	;Subtract 10 from 802
    	SUBB #$10
    	STAB $0802
GT3 	SWI         	;Software Interrupt to check if numbers are correct.