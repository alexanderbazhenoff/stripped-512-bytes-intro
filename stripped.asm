; This Source Code Form is subject to the terms of the Mozilla
; Public License, v. 2.0. If a copy of the MPL was not distributed
; with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

 DISPLAY ".stripped. a SI2b by alx^brainwave :)"
 DISPLAY "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


BEGIN                   EQU #6000
BEG_OUTMULT_ROUT        EQU #667D
END_OUTMULT_ROUT        EQU BEG_OUTMULT_ROUT+#1440
BEG_MULT_BUFFER_P       EQU #FC00
COPYFROM                EQU #670B
SINTABL128              EQU #DE00
SINTABL64               EQU SINTABL128+#100
COLUMNS_BEG             EQU #E000
ZOOM_COLUMNS_BEG        EQU #8000
SYNCHRO                 EQU #01C7 ;+/-#01
FLASHCOL                EQU 0

TABLE_SIN               EQU  #AA00

A_TO_STACK              EQU  #2D28
FROM_STACK              EQU  #2DD5

multiply                EQU  #04
cos                     EQU  #20
stk_data                EQU  #34
end_calc                EQU  #38

        ORG BEGIN

;------ generating rows output routines ------------------------
        LD HL,RECOD_DAT
        LD DE,RECOD_DAT+6
        LD BC,#47A+#96
        LDIR 
        LD (HL),#21
        INC HL

;------ plase an address of multicolour buffer here
;       (label COPYFROM)
        INC HL
        INC HL

;------ decrunch multicolour output ----------------------------
        LD D,#58
        LD C,E

INS_OUTMUL
        LD A,8
INS_OUTMUL1
        PUSH DE
        LD (HL),#5E
        INC HL
        LD (HL),#23
        INC HL
        LD (HL),#56
        INC HL
INS_TIPA
        LD (HL),#31
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD B,8
INS_TIPA2
        LD (HL),#D5
        INC HL
        DJNZ INS_TIPA2

        EX DE,HL
        ADD HL,BC
        EX DE,HL
        BIT 4,E
        JR Z,INS_TIPA

        LD (HL),#CB
        INC HL
        LD (HL),#C5
        INC HL
        DEC A
        JR Z,INS_END
        POP DE
        JR INS_OUTMUL1
INS_END
        BIT 2,D
        JR Z,INS_OUTMUL


;------ setting JP to exit from multicolour routines -----------
        LD H,#7C
        LD (HL),#C3
        INC HL
        LD (HL),.EXITMULT
        INC HL
        LD (HL),'EXITMULT

;------ zero all memory beyond JP ------------------------------
CLEAR_TOPMEMORY_L
        INC HL
        LD (HL),A
        CP (HL)
        JR Z,CLEAR_TOPMEMORY_L

;------ im2 routines :) ----------------------------------------
        DEC HL
        LD (HL),#C9


;------ calculate sine with 128 and 64 amplitude ---------------
        LD BC,SINTABL128
LOOP_SIN
        PUSH BC
        CALL A_TO_STACK+1

        ;calculate int ((cos (pi/32))*counter)
        RST #28
        DB stk_data ;pi/32
        DD #EB490FDA54
        DB multiply
        DB cos
        DB stk_data ;127
        DB #40,#B0,#00,#80
        DB multiply
        DB end_calc

        CALL FROM_STACK
        POP BC
        LD (BC),A
        INC B
        RRA 
        LD (BC),A
        DEC B
        LD H,#5A        ;----------------
        LD L,C          ;decrunch process
        LD (HL),#3F     ;----------------
        INC C

        JR NZ,LOOP_SIN

;------ install IM2 vector #3Bxx -------------------------------
        LD A,#3B
        LD I,A

;------ fill all screen by texture -----------------------------
        IF FLASHCOL
        LD A,#55        ;#55 for non-flashcolour mode (nfc)
        ELSE 
        LD A,#FF
        ENDIF 
LP_FG   INC L
        IF FLASHCOL
        JR NZ,MTKFG     ;JR NZ for nfc
        ELSE 
        JR MTKFG
        ENDIF 
        CPL 
MTKFG   DEC L
        LD (HL),A
        CP (HL)
        DEC HL
        JR Z,LP_FG

;------ generating rows ----------------------------------------
        LD D,'COLUMNS_BEG
        LD HL,COLUMNS_DATA
GENCOL_L
        LD A,(HL)
        AND #3F
        LD E,0
GENCOL1 LD (DE),A
        INC E
        JR NZ,GENCOL1
        LD A,(HL)
        AND #C0
        LD B,A
        XOR #C0
        LD E,A
GENCOLM INC HL
        LD A,(HL)
        INC HL
        PUSH HL
        LD H,(HL)
        LD L,A
GENCOL2 LD A,(HL)
        BIT 7,A
        JR GENCOLL
        AND 7+#40
        LD C,A
        AND 7
        ADD A,A
        ADD A,A
        ADD A,A
        OR C
GENCOLL LD (DE),A
        INC HL
        INC E
        DJNZ GENCOL2
        POP HL
        INC HL
        INC D
        BIT 3,D
        JR Z,GENCOL_L

;------ dectrunch of colour columns zooming -----------------------
        LD D,'ZOOM_COLUMNS_BEG
        LD B,#40         ;B=#40
ZOOM_COLDEC_L
        LD L,0

ZOOM_COLDEC_L2
        LD H,'SINTABL64

        LD A,(HL)
        SUB B
        JR NC,ZOOM_COLDEC_M
        XOR A
ZOOM_COLDEC_M
        ADD A,L
        LD E,A
        LD H,'COLUMNS_BEG
        LD A,(HL)
        LD (DE),A
        INC L
        BIT 7,L
        JR Z,ZOOM_COLDEC_L2
        INC D
        DJNZ ZOOM_COLDEC_L

;------ set interrups mode -------------------------------------
        IM 2

;------ init AY registers --------------------------------------
MBEGIN  LD BC,#FFFD
        LD HL,#0709
        OUT (C),L
        LD A,#BF
        OUT (#FD),A
        OUT (C),H
        OUT (#FD),A
        LD HL,#0C0B
        OUT (C),L
        OUT (#FD),A
        OUT (C),H
        LD B,A
        LD A,#B+2+4+8
        OUT (C),A

;------ intro kernel -------------------------------------------

KERNAL
        LD IX,ACTION
        LD IY,BEG_MULT_BUFFER_P
        LD HL,SINTABL64+#10
        LD D,H
        LD E,L
        CALL ACTION_

;       LD (IX+#14),#2C
;       LD (IX+#18),#1C
        DEC H           ;128
        DEC D           ;128
        LD L,B
        CALL WLOOP

                        ;128
                        ;128
                        ;LD E,#40
        CALL ACTION2

        LD IY,BEG_MULT_BUFFER_P-#20
        LD A,#E
        INC H           ;64
        INC D           ;64
        LD E,#10
        CALL ACTION0

        LD A,#6
        LD (HTACT),A
        DEC H           ;128
                        ;64
        LD E,#20
        CALL ACTION0
        LD IY,BEG_MULT_BUFFER_P



        LD (IX+#31),B       ;(ZOOM_SW)=0
        LD A,#7E
        INC H           ;64
                        ;64
        LD E,#40
        LD L,E
        CALL ACTION

                        ;64
                        ;64
        LD L,B
        LD E,#20
        CALL WLOOP

                        ;64
                        ;64
        LD E,#40
        CALL WLOOP

        DEC H           ;128
        DEC D           ;128
                        ;LD E,#40
        CALL ACTION2
        JR $ ;although DI HALT is also possible

;------ data for colour columns creation  ----------------------
COLUMNS_DATA
        DB #80
        DW SINTABL128
        DB #80
        DW SINTABL128

        DB #40+#3F
        DW #04D6+#1E
        DB #40+#3F
        DW #04D6

        DB #80+27
        DW #06EA
        DB #80+27
        DW #0418

        DB #80+45
        DW #36A9
        DB #40+45
        DW #1FFB




;------ here comes after multicolour output --------------------
;       ORG BEGIN+#200-6-#49-7
EXITMULT
        LD SP,#3131
STEK    EQU $-2
        EXX 

;------ AY player ----------------------------------------------
PLAYER  LD A,B
        PUSH AF
        EXX 
        LD BC,#FFFD
        AND #1F
        JR Z,DRUM
        AND #1F
HMASK   EQU $-1
        CP #F
HTACT   EQU $-1
        LD HL,#0608
        JR Z,HAT
        LD A,#A0
        OUT (C),L
        JR MUTE
HAT     OUT (C),H
        LD A,B
        OUT (#FD),A
        INC H
        OUT (C),H
        LD A,#B6
        OUT (#FD),A
        OUT (C),L
        LD A,#AB
MUTE    OUT (#FD),A
        JR ENDPLAY
DRUM    LD HL,#D02
        OUT (C),L
        LD A,L
        OUT (C),A
        LD B,#FF
        LD A,#A0
        OUT (#FD),A
        OUT (C),H
        OUT (#FD),A
ENDPLAY
;------ main cycle ---------------------------------------------
        EXX 
        POP AF
        DJNZ WLOOP
        RET 
ZUZU

;------ control movement variations plus pause -----------------
        ORG BEGIN+#200-6-#49
ACTION2 LD E,#40
ACTION_ XOR A
ACTION0 EXX 
        LD HL,ATRADR
        INC (HL)
        INC (HL)
        LD L,.ATRADR2
        INC (HL)
        INC (HL)
        EXX 
ACTION  LD (MOVE_MASK),A
WLOOP   EXX 
        EI 
        HALT 
        LD A,(BEG_MULT_BUFFER_P)
        OUT (#FE),A
        LD BC,SYNCHRO
PAUSE   EQU $-2
        LD D,B
        LDIR 
        EXX 
        LD A,(HL)
        INC L
SPEED1  INC L
        EXA 
        LD A,(DE)
        INC E
SPEED2  INC E
        EXX 

        LD D,'COLUMNS_BEG-2
ATRADR2 EQU $-1
        LD E,A

        PUSH IY
        POP HL
        AND #7E
MOVE_MASK EQU $-1
        LD B,0
        LD C,A
        ADD HL,BC
        LD (COPYFROM),HL

        EXA 
        LD H,'COLUMNS_BEG+1-2
ATRADR  EQU $-1
        LD L,A

        RRA 
        ADD A,#80
        JR NOZOOM
ZOOM_SW EQU $-1
ZOOM    LD D,A
        LD H,A
NOZOOM
        LD (STEK),SP
        LD SP,BEG_MULT_BUFFER_P+385



;------ commands for columns output to buffer routines ---------
        ORG BEGIN+#200-6
RECOD_DAT
        LD C,(HL)
        INC L
        LD A,(DE)
        LD B,A
        INC E
        PUSH BC

;------ this required for debug only ---------------------------
        ORG #5C00
START   LD (MAINSP),SP
        JP #6000
EXIT    LD SP,#3131
MAINSP  EQU $-2
        LD HL,#2758
        EXX 
        IM 1
        EI 
        RET 

        ORG BEGIN

        ORG #5C00

