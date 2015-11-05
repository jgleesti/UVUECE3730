********************************************************************************
* Description: Program starts by the push of a button connected to Port J. The *
* piezo speaker will then chirp and begin the program as follows: Allows user  *
* to select (high, medium, or low) velocity and time values utilizing dbug     *
* subroutines.  The program will calculate the velocity change as a function   *
* of time and display results to screen. TA, TC, delta velocity, and the total *
* time will be calculated based on the user's selection and displayed to the   *
* screen.                                                                      *
*                                                                              *
* Group3 (33.3% each)                                                          *
* Logan Barnes, Jordan Lee, Justin Limb                                        *
* Date: 10/31/2015                                                             *
* ECE 3730                                                                     *
* Ch. 5 Project                                                                *
* Code is utilized for a 9S12 trainer board                                    *
********************************************************************************


                ORG   $1000
R_MOTOR         RMW   !30        ;Reserve 30 words of data for right motor
L_MOTOR         RMW   !30        ;Reserve 30 words of data for left motor

CR:             EQU   $0D        ;Return carrier in ascii
LF:             EQU   $0A        ;Linefeed in ascii

PORTJ           EQU   $0268      ;Port J data register for switch input
DDRJ            EQU   $026A      ;Port J direction register
DDRJ_INI        EQU   $00        ;Port J input mask
PORTT           EQU   $0240      ;Port T data register for piezo speaker output
DDRT            EQU   $0242      ;Port T direction register
DDRT_INI        EQU   $20        ;Port T(5) output mask
SWITCH          EQU   $01        ;Port J(0) assertion testing
PIEZO           EQU   $20        ;Port T(5) output for piezo sound

GETCHAR         EQU   $EE84      ;9S12
PUTCHAR         EQU   $EE86      ;9S12
PRINTF          EQU   $EE88      ;9S12

HIGH            EQU   $2710      ;10k decimal
MEDIUM          EQU   $03E8      ;1k decimal
LOW             EQU   $0064      ;100 decimal

TA              EQU   $1800      ;Address to store ta
TC              EQU   $1802      ;Address to store tc
TT              EQU   $1804      ;Address to store total time
DELTA_V         EQU   $1806      ;Address to store delta velocity
NEG_DELTA_V     EQU   $1808      ;Address to store negative delta velocity
V_CONSTANT      EQU   $180A      ;Address to store constant velocity
T_TOTAL         EQU   $180C      ;Address to store total time that user selects

STACK           EQU   $2000      ;Highest address of data RAM in 9S12
RATIO           EQU   !5         ;Ratio of time intervals for calculations 20%
INCREMENT       EQU   !10        ;# of velocity increments in acc interval

ASSERT_MSG      FCC                '         SWITCH ASSERTED - STARTING PROGRAM'
                DB CR,LF,CR,LF,0
INTRO_MSG       FCC                '                MOTOR CONTROL SOFTWARE'
                DB CR,LF,CR,LF,0
V1_MSG          FCC                'Please choose a constant velocity:'
                DB CR,LF,0                 ;Return, Line feed, NULL terminator.
V2_MSG          FCC                'High(1), Medium(2), or Low(3)'
                DB CR,LF,0
T1_MSG          FCC                'Please choose a total time period:'
                DB CR,LF,0
T2_MSG          FCC                'High(1), Medium(2), or Low(3)'
                DB CR,LF,0
V_P_MSG         FCC                '                           VELOCITY PROFILE'
                DB CR,LF,CR,LF,0
V_OUT           FCC                'Velocity %d:                 %X'
                DB CR,LF,0
TA_OUT          FCC                'TA:                          %X'
                DB CR,LF,0
TC_OUT          FCC                'TC:                          %X'
                DB CR,LF,0
TTOTAL_OUT      FCC                'Ttotal:                      %X'
                DB CR,LF,0
DELTAV_OUT      FCC                'DeltaV:                      %X'
                DB CR,LF,CR,LF,0
NEWLINE         FCC                ''
                DB CR,LF,CR,LF,0
DEBUG           FCC                'DEBUG'
                DB CR,LF,0


MAIN        ORG     $2000              ;Start program at this address 9S12
            LDS     #STACK             ;Max address for RAM in 9S12 for stack
            LDAA    #DDRJ_INI          ;Load DDRJ mask to A
            STAA    DDRJ               ;Configure port j(0) as input pin
            LDAA    #DDRT_INI          ;Load DDRT mask to A
            STAA    DDRT               ;Configure port T(5) as output pin

	    JSR     POLL_SWITCH        ;Poll the switch for starting
            JSR     SPLASH             ;Display initial prompt for entering data
            LDD     V_CONSTANT         ;Load register D with constant velocity
            LDY     T_TOTAL            ;Load register Y with total time value
            BSR     SUB1               ;Call first subroutine by value
            BSR     SUB2               ;Call second subroutine
            LDY     #R_MOTOR           ;Call by reference
            JSR     DISP_DATA          ;Display data to screen subroutine
            SWI                        ;End
            END

            
;Poll the switch on port J (0) for assertion
;Chirp piezo once asserted
POLL_SWITCH LDAA    PORTJ              ;Load A with port J for detecting switch
            ANDA    #SWITCH            ;Verify port j(0) for testing switch
            CMPA    #SWITCH            ;Is port j(0) a high?
            BNE     POLL_SWITCH        ;If no switch contact, poll again
            LDD     #ASSERT_MSG        ;Display switch assertion message
            LDX     PRINTF
            JSR     0,X

	    LDY     #$015E             ;Chirp length ((1/3500) * 0x15E = 100 mS)
CHIRP       LDAA    #PIEZO             ;Port T(5) mask into A
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
DELAY       LDX     #$0236
DEL         DEX                        ;1 cycle
            INX                        ;1 cycle
            DEX                        ;1 cycle
            BNE     DEL                ;3 cycles
            RTS


SUB1        STY     TT                 ;Store total time into memory
            LDX     #INCREMENT         ;Load X with acceleration ratio time (10)
            IDIV                       ;Divide D (vel value) by register X (10)
            STX     DELTA_V            ;Store delta velocity into $1806
            TFR     X,D
            COMA                       ;Complement A for making negative number
            COMB                       ;Complement B for making negative number
            TFR     D,X
            INX                        ;Add 1 to complemented value to make 2's
                                       ;complement (negative delta velocity)
            STX     NEG_DELTA_V        ;Create negative delta velocity for
                                       ;subtracting later
            TFR     Y,D                ;Transfer total time into D for division
            LDX     #RATIO             ;Load X with time interval ratio time (5)
            IDIV                       ;Divide D (tot time) by time interval (5)
            STX     TA                 ;Acceleration time ends (ta) 16 bits
                                       ;(1/5 of total time), store into $1800
            TFR     Y,D                ;Transfer total time into D
            SUBD    TA                 ;Time when deceleration begins (tc)
            STD     TC                 ;Store time of deceleration into $1802
            RTS                        ;Return from subroutine


SUB2        LDD     #$0
            LDX     #R_MOTOR           ;Starting index address for right motor
            LDY     #L_MOTOR           ;Starting index address for left motor
ACC_VEL     STD     2,X+               ;Store values of velocity for right motor
            STD     2,Y+               ;Store values of velocity for left motor
            ADDD    DELTA_V            ;Add delta velocity to accumulative vel.
            CPD     V_CONSTANT         ;Compare accumulative vel with peak vel
            BLE     ACC_VEL            ;Accumulate vel values until constant

            ADDD    NEG_DELTA_V        ;Set constant velocity again
            PSHD                       ;Store D to free up register for A
            LDAA    #$8                ;Num of times constant vel will display
CON_VEL     PSHA                       ;Save counter to free up D register
            LDD     1,SP               ;Retrieve constant velocity from stack
            STD     2,X+               ;Store values of velocity for right motor
            STD     2,Y+               ;Store values of velocity for left motor
            PULA                       ;Retrieve counter from stack
            DECA                       ;Decrement cycle step-counter
            BNE     CON_VEL            ;Store constant vel until counter is 0

            PULD                       ;Retrieve constant velocity from stack
DEC_VEL     STD     2,X+               ;Store values of velocity for right motor
            STD     2,Y+               ;Store values of velocity for left motor
            ADDD    NEG_DELTA_V        ;Subtract delta vel from accumulative vel
            CPD     #$0                ;Compare accumulative velocity with 0
            BGE     DEC_VEL            ;Decrement velocity values until negative
            RTS


; Get input from the user asking for a constant velocity and a total time.
; The EQUated values should be used for both time and velocity.

; Print welcome
SPLASH      LDD     #INTRO_MSG
            LDX     PRINTF
            JSR     0,X
; Tell user to input constant velocity
            LDD     #V1_MSG
            LDX     PRINTF
            JSR     0,X
            LDD     #V2_MSG
            LDX     PRINTF
            JSR     0,X

; Capture constant velocity
; Get the user's input
            LDX     GETCHAR            ;Get user input
            JSR     0,X
            LDX     PUTCHAR            ;Display user input to screen
            JSR     0,X
            CMPB    #'1                ;Is user input a '1' for high?
            BEQ     STORE_HV           ;If '1', jump to routine for storing high
            CMPB    #'2                ;Is user input a '2' for medium?
            BEQ     STORE_MV           ;If '2', jump to routine for storing med
            LDD     #LOW               ;Not high or medium, must be low
            STD     V_CONSTANT         ;Store low value to memory
            BRA     TOT_TIME           ;Skip to enter total time
STORE_MV    LDD     #MEDIUM
            STD     V_CONSTANT         ;Store medium value to memory
            BRA     TOT_TIME           ;Skip to enter total time
STORE_HV    LDD     #HIGH
            STD     V_CONSTANT         ;Store high value to memory

; Tell user to input total time
TOT_TIME    LDD     #NEWLINE           ;Print out blank lines
            LDX     PRINTF
            JSR     0,X
            LDD     #T1_MSG
            LDX     PRINTF
            JSR     0,X
            LDD     #T2_MSG
            LDX     PRINTF
            JSR     0,X

; Get the user's input and capture total time
            LDX     GETCHAR           ;Get user input
            JSR     0,X
            LDX     PUTCHAR           ;Display user input to screen
            JSR     0,X
            CMPB    #'1               ;Is user input a '1' for high?
            BEQ     STORE_HT          ;If '1', jump to routine for storing high
            CMPB    #'2               ;Is user input a '2' for medium?
            BEQ     STORE_MT          ;If '2', jump to routine for storing med
            LDD     #LOW              ;Not high or medium, must be low
            STD     T_TOTAL           ;Store low value to memory
            BRA     END_TOT_TIM       ;Skip to end of subroutine
STORE_MT    LDD     #MEDIUM
            STD     T_TOTAL           ;Store medium value to memory
            BRA     END_TOT_TIM       ;Skip to end of subroutine
STORE_HT    LDD     #HIGH
            STD     T_TOTAL           ;Store high value to memory

END_TOT_TIM LDD     #NEWLINE          ;Print out blank lines
            LDX     PRINTF
            JSR     0,X
            RTS                       ;End subroutine
            
;Output data to terminal once program has run
DISP_DATA   PSHY                      ;Save Y on stack (dbug routines change Y)
            LDD     #V_P_MSG
            LDX     PRINTF
            JSR     0,X
                        
            LDD     #$0               ;Start counter at 0
            PSHD                      ;Save counter to stack
            LEAS    -2,SP             ;Move stack pointer 1 word above counter
                                      ;to prevent erasing counter

PRINT_VALUE LEAS    4,SP              ;Lower stack pointer 1 word (2 bytes)
            PULY
            LDD     2,Y+              ;Store index address of velocity values to
                                      ;D and increment index by 2
            PSHY
            LEAS    -2,SP
            PSHD                      ;Velocity as 2nd parameter of string
                                      ;Printf routine will read this from stack
            LDD     2,SP              ;Retrieve counter from stack
            INCB                      ;Increment counter
            STD     2,SP              ;Store counter back to stack
            PSHD                      ;Counter as 1st parameter of string
                                      ;Printf routine will read this from stack
            LDD     #V_OUT
            LDX     PRINTF
            JSR     0,X               ;Print out velocity value message and both
                                      ;parameters in string from stack
            PULD                      ;Retrieve counter from stack
            CPD     #!30              ;Number of times to iterate data to screen
            BNE     PRINT_VALUE       ;Continue until all values have displayed

;Display ta, tc, tt, delta velocity to screen
            LDD     #NEWLINE
            LDX     PRINTF
            JSR     0,X
            LDD     TA
            PSHD
            LDD     #TA_OUT
            LDX     PRINTF
            JSR     0,X
            LDD     TC
            PSHD
            LDD     #TC_OUT
            LDX     PRINTF
            JSR     0,X
            LDD     TT
            PSHD
            LDD     #TTOTAL_OUT
            LDX     PRINTF
            JSR     0,X
            LDD     DELTA_V
            PSHD
            LDD     #DELTAV_OUT
            LDX     PRINTF
            JSR     0,X
            LEAS    !14,SP            ;Adjust stack pointer for return address
            RTS