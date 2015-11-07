;Displaying "YES" on LCD for Dragon12+ Trainer Board
;with HCS12 D-Bug12 Program installed. This code is for asmIde and MiniIde Assemblers
;Modified by Mazidi from Chapter 12 of HS12 book by Mazidi & Causey
;On Dragon12+ LCD data pins of D7-D4 are connected to Pk5-Pk2, En=Pk1,and RS=Pk0,

#include "C:\AsmIDE\Reg9s12.H"

LCD_DATA EQU PORTK
LCD_CTRL EQU PORTK
RS       EQU %00000001
EN       EQU %00000010

;----------------------USE $1000-$1FFF for Scratch Pad and Stack
R1      EQU     $1001
R2      EQU     $1002
R3      EQU     $1003
TEMP    EQU     $1200

;code section
        ORG   $2000     ;
        LDS   #$2000    ;Stack
        LDAA  #$FF
        STAA  DDRK
        LDAA  #$33
        JSR   COMWRT4
	JSR   DELAY
        LDAA  #$32
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #$28
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #$0E
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #$01
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #$06
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #$80
        JSR   COMWRT4
        JSR   DELAY
        LDAA  #'Y'
        JSR   DATWRT4
        JSR   DELAY
        LDAA  #'E'
        JSR   DATWRT4
        JSR   DELAY
        LDAA  #'S'
        JSR   DATWRT4
        JSR   DELAY

AGAIN: BRA        AGAIN
;----------------------------
COMWRT4:
        STAA        TEMP
        ANDA  #$F0
        LSRA
        LSRA
        STAA  LCD_DATA
        BCLR  LCD_CTRL,RS
        BSET  LCD_CTRL,EN
        NOP
        NOP
        NOP
        BCLR  LCD_CTRL,EN
        LDAA  TEMP
        ANDA  #$0F
        LSLA
        LSLA
        STAA  LCD_DATA
        BCLR  LCD_CTRL,RS
        BSET  LCD_CTRL,EN
        NOP
        NOP
        NOP
        BCLR  LCD_CTRL,EN
        RTS
;--------------
DATWRT4:
        STAA         TEMP
        ANDA   #$F0
        LSRA
        LSRA
        STAA   LCD_DATA
        BSET   LCD_CTRL,RS
        BSET   LCD_CTRL,EN
        NOP
        NOP
        NOP
        BCLR   LCD_CTRL,EN
        LDAA   TEMP
        ANDA   #$0F
            LSLA
        LSLA
          STAA   LCD_DATA
          BSET   LCD_CTRL,RS
        BSET   LCD_CTRL,EN
        NOP
        NOP
        NOP
        BCLR   LCD_CTRL,EN
        RTS
;-------------------

DELAY

        PSHA                ;Save Reg A on Stack
        LDAA    #1
        STAA    R3
;-- 1 msec delay. The D-Bug12 works at speed of 48MHz with XTAL=8MHz on Dragon12+ board
;Freq. for Instruction Clock Cycle is 24MHz (1/2 of 48Mhz).
;(1/24MHz) x 10 Clk x240x100=1 msec. Overheads are excluded in this calculation.
L3      LDAA    #100
        STAA    R2
L2      LDAA    #240
        STAA    R1
L1      NOP         ;1 Intruction Clk Cycle
        NOP         ;1
        NOP         ;1
        DEC     R1  ;4
        BNE     L1  ;3
        DEC     R2  ;Total Instr.Clk=10
        BNE     L2
        DEC     R3
        BNE     L3
;--------------
        PULA                        ;Restore Reg A
        RTS
;-------------------