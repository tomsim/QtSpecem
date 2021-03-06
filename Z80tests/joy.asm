;
; kempston/cursor/fuller/sinclair/timex 2068 joystick detection and testing
; Rui Ribeiro/2020
;
; MIT License
;
; pasmo --tapbas joy.asm joy.tap
;

CL_ALL		EQU     $0DAF ; clearing the whole display area

; UDGs EQUs

; sysvar for defining UDG
UDG		EQU	$5C7B

;
; UDG CHARs
;

UUP     	EQU     $90
ULEFT   	EQU     $91
UFIRE   	EQU     $92
URIGHT  	EQU     $93
UDOWN   	EQU     $94

; Print EQUs

; AT control code
AT      	EQU     $16

; line and column for the joystick status
LINE1   	EQU     10
COL     	EQU     13

; ATTR EQUs

ATTR_BIT_ON	EQU	$3A ; red   ink, white paper
ATTR_BIT_OFF	EQU	$38 ; black ink, white paper

; beginning of attr area
ATTR		EQU	$5800

; first actual memory ATTR location (UP)
FIRST_ATTR	EQU	ATTR+(LINE1*32)+COL

; memory offsets from first location
; so ATTR mapping tables can be 1 byte
; ought not to be 0, it was selected for ignoring a bit

A_UP     	EQU     2      ; ATTR+(LINE1*32)+COL+2              
A_LEFT   	EQU     2*32   ; ATTR+((LINE1+2)*32)+COL              
A_FIRE   	EQU     2*32+2 ; ATTR+((LINE1+2)*32)+COL+2
A_RIGHT  	EQU     2*32+4 ; ATTR+((LINE1+2)*32)+COL+4
A_DOWN   	EQU     4*32+2 ; ATTR+((LINE1+4)*32)+COL+2

; Begin of program/asm code

	ORG	32768

	; point UDGs to our table
	LD	HL,UDGs		
	LD 	(UDG),HL		

	; clear screen
	CALL	CL_ALL

	; print our screen
	LD	HL,MAIN_SCREEN
	CALL	PRINT

L_DETECT:
	; if space pressed leave
        CALL    T_SPACE
	RET	NZ

	; wait for an interrupt
	HALT               ; CALL    DELAY

	; detect joystick type
	CALL	DETECT_JOY

	; go to loop if not detected
	JR	C,L_DETECT

	; print joystck name
        CALL	JOY_NAME

	 
L_TEST:	
	; if space pressed leaves to BASIC
	CALL	T_SPACE
	RET	NZ

	; wait for an interrupt
	HALT                ; CALL	DELAY

        ; show joytstick actions	
        CALL	TEST_JOY

	JR	L_TEST

	; Never reachs here
	;RET

;
; loads joystick port
; Entry:
;      HL=pointing to first element of detection array
; Exit:
;      BC=joytick port to be tested
;      HL=pointing to second element of detection array
;      C=1 end of detection array
;      if C=0, 
;		A with IN value
;		E with value to be tested
;

LOAD_JOY_PORT:
        LD      C,(HL)
        INC     HL
        LD      B,(HL)
        INC     HL
	; if BC=0 we have reached the end of the detection array
        LD      A,B
        OR      C
	JR	NZ,ALL_OK
	SCF	; returns C=1 (end,error)
        RET     
ALL_OK:        
        IN      A,(C)	;	A=read joystick port
        LD      E,(HL)	;	E=expected left direction value from detection array
        INC     HL
        RET

;
; DETECT JOYSTICK
; Returns:
; C=1 error
; otherwise
; BC=PORT to read
; HL pointing to third element of detection array
;

DETECT_JOY:
        LD 	HL,KEMPSTON_P	; point to beginning of joystick detection array
        CALL	LOAD_JOY_PORT   ; get joytick port in BC and A with read value, 
				; E with value to test
        CP	E 		; exception, kempston must be detected as is
	JR	Z,DETECTED
LOOP_JOY:
        LD	BC,4		; point to next joystick
	ADD	HL,BC
	CALL	LOAD_JOY_PORT	; get joytick port in BC and A with read value
				; E with value to test
	RET	C		; return if no more joyticks in table, C=1 error
	CPL			; the rest of joystick makes are active low
				; negate bits
	AND	E		
	JR	Z,LOOP_JOY	; if value not as expected, try next joystick in table
DETECTED:
        SCF
	CCF			; C=0, success
	RET

;
; PRINTS JOYSTICK NAME
; HL= pointer to detected joystick name
; Returns:
; HL pointing to fourth element of detection array
;

JOY_NAME:
	PUSH	BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; DE=string of joystick name
	INC	HL
        PUSH	HL

	; copy DE to HL
	;PUSH	DE
	;POP	HL
	EX	DE,HL

	CALL	PRINT

	; print 10 spaces
	LD	B,10
SPACES:	LD	A,' '
	RST	$10
	DJNZ	SPACES

        POP	HL
	POP	BC
	RET

;
; TEST JOYSTICK
; ENTRIES:
;        HL pointing to addr of 8 words mapping bits to ATTR
;        BC port of joystick
;

TEST_JOY:
	PUSH	HL
	PUSH	BC

; dealing with exceptions to the rules
; Cursor joytick reads two I/O ports


;	XOR	A
;	LD	(CURS_TMP),A
	EXX
	LD	D,0
	EXX
	
	LD	DE,CURSORP

	; 16 bit CP HL,DE	
	OR	A
	SBC	HL,DE
	ADD	HL,DE
	JR	NZ,NO_CURSOR	; jump if HL not equal CURSORP

	; read from cursor Joystick, first port
	; $F7FE row 1-5, for 5 (left)
	IN	A,(C)
	CPL	
	AND	$10	; and with key 5
	; shift it to an unused bit on the other port
	; store it in D'
        SRA     A 
	SRA	A
	SRA	A       
	EXX
        ;LD      (CURS_TMP),A
	LD	D,A
	EXX

	; replace port for cursor joystick for rest of buttons
        ; keyboard row 6-0
	LD	BC,$EFFE

NO_CURSOR:	

	LD	E,(HL)
	INC	HL
	LD	D,(HL)
			; DE pointing to attr 8 word array now

	IN	A,(C)   ; Read joystick port

	LD	L,A     ; save it in L

        ; Kempston joytick is not active low

	LD	A,$1F
	CP	C	
	JR	Z,IS_KEMPSTON

	; other joysticks besides kempston are active low
	; invert bits
	LD	A,L
	CPL		; invert bits reading

	; still dealing with the Cursor exception
	; adding back the left key, another port
        ; on bit 1, unused bit of the port with the most keys
        ; if not cursor joystick, D' will be 0

	LD	L,A

	; load D' into A
	EXX
	;LD	A,(CURS_TMP)
	LD	A,D
	EXX

	OR	L	; OR joystick reading with A (formely D')
	LD	L,A	; store it

IS_KEMPSTON:

; now is time for rotating the 8 bits of joystick input

	LD	B,8

; we will need HL, use C for the joy port input

        LD      C,L
BITS:	
	; get screen attribute offset in A
	; from corresponding bit behaviour array
	; if 0, the offset will be calculated
	; but no action taken
	LD	A,(DE)
	INC	DE	; point to next bit

	; build attribute byte in HL
	LD	HL,FIRST_ATTR
	; HL=HL+A
	ADD	A,L
	LD	L,A
	JR	NC,NO_C
	INC	H

	; HL=attribute area address

NO_C:	SLA	C	; shift left, bit 7 into carry
	JR	NC,BIT_0

        CP	0	; if behaviour is 0, no action
	JR	Z,BIT_1

	; in direction or fire, change UDG atribute colour	
	LD	(HL),ATTR_BIT_ON  ; ink red
	JR	BIT_1

	; in inaction, possible restoration to former colour
BIT_0:	LD	(HL),ATTR_BIT_OFF ; ink black

BIT_1:	DJNZ	BITS	; B not 0, go to next bit

	POP	BC
	POP	HL
	RET

;	
; Print a string in HL
; terminated by $
;

PRINT:	LD	A,(HL)
	CP	'$'
	RET	Z
	RST	$10
	INC	HL
	JR	PRINT

;
;DELAY:	
;	HALT
;	RET

;
; INPUT: none
; returns: Z=0 if SPACE pressed
;

T_SPACE:
        PUSH	BC
	LD	BC,$7FFE	; keyboard row SPACE-B
	IN	A,(C)
	CPL
	AND	1		; test for SPACE
	POP	BC
	RET

;
; DATA
;

;
; We store it in D'
; Cursor Joystick status of left direction
;CURS_TMP:  DEFB	0
;

;
;Array: Detection port
;       Value
;       Pointer to descriptive text
;       Pointer to bits behaviour 
;   

KEMPSTON_P:
           DEFW $1F		; kempston port
           DEFB $02		; left
           DEFW KEMPSTON_T	; "Kempston$"
           DEFW KEMPSTON_B	; array pointer of Kempston 8 bit behaviour
FULLER_P:  DEFW $7F		; fuller port
           DEFB $04		; left
           DEFW FULLER_T	; "Fuller$"
           DEFW FULLER_B	; array pointer of Fuller 8 bit behaviour
CURSOR_P:  DEFW $F7FE		; Cursor first port (1-5 row)
           DEFB $10		; test for 5
           DEFW CURSOR_T	; "Cursor$"
CURSORP:   DEFW CURSOR_B	; array pointer of Cursor 8 bit behaviour
SINCLAIR:  DEFW $F7FE		; Sinclair port (1-5 row)
           DEFB $01		; "Sinclair$"
           DEFW SINCLAIR_T
           DEFW SINCLAIR_B	; array pointer of Sinclair 8 bit behaviour
SINCLAIR_2: 
           DEFW	$EFFE		; Sinclair port (6-0 row)
	   DEFB $10		; test for 6
	   DEFW SINCLAIR_T	; "Sinclair$"
           DEFW SINCLAIR_B2	; array pointer of Sinclair 8 bit behaviour
T2068_P1:  DEFW $01F6		; Timex 2068 port of 1st Joystick
           DEFB $04		; left
           DEFW T2068_T		; "Timex 2068$"
           DEFW T2068_B		; array pointer of Timex 2068 8 bit behaviour
T2068_P2:  DEFW $02F6		; Timex 2068 port of 2nd Joystick
           DEFB $04		; left
           DEFW T2068_T		; "Timex 2068$"
           DEFW T2068_B		; array pointer of Timex 2068 8 bit behaviour
END_P:	   DEFW	0		; end of array

;
; name of joytick - need to print spaces after printing it
;

KEMPSTON_T:
           DEFB AT, 4, 8, "Kempston$"
FULLER_T:  DEFB AT, 4, 8, "Fuller$"
CURSOR_T:  DEFB AT, 4, 8, "Cursor$"
SINCLAIR_T:
           DEFB AT, 4, 8, "Sinclair$"
T2068_T:   DEFB AT, 4, 8, "Timex 2068$"

;
; Bits of select ports behaviour, 7 to 0
; CURSOR bits are read from $EFFE except left from $f7fe
; 0 no action
;

KEMPSTON_B: DEFB A_FIRE, 0, 0, A_FIRE, A_UP,    A_DOWN,  A_LEFT,  A_RIGHT
FULLER_B:   DEFB A_FIRE, 0, 0, 0,      A_RIGHT, A_LEFT,  A_DOWN,  A_UP
CURSOR_B:   DEFB 0,      0, 0, A_DOWN, A_UP,    A_RIGHT, A_LEFT,  A_FIRE
T2068_B:    DEFB 0,      0, 0, A_FIRE, A_RIGHT, A_LEFT,  A_DOWN,  A_UP
SINCLAIR_B: DEFB 0,      0, 0, A_FIRE, A_UP,    A_DOWN,  A_RIGHT, A_LEFT
SINCLAIR_B2:
            DEFB 0,      0, 0, A_LEFT, A_RIGHT, A_DOWN,  A_UP,    A_FIRE

;
; Main text screen
; LINE, COL positions are used to calculate video attribute addresses
;

MAIN_SCREEN: 
        DEFB	AT, 0, 4, "Joystick diagnostics v0.3"
        DEFB    AT, 4, 8, "Left on joystick"
        DEFB	AT, LINE1  , COL, ' ' , ' ', UUP, ' ', ' '
	DEFB    AT, LINE1+2, COL, ULEFT, ' ', UFIRE, ' ', URIGHT
	DEFB	AT, LINE1+4, COL, ' ' , ' ', UDOWN, ' ', ' '
        DEFB    AT, 19, 9, "SPACE to quit"
	DEFB	'$'

;
; UDGs
;

UDGs:	
	; up
	DEFB    %00010000
	DEFB    %00111000
	DEFB    %01010100
	DEFB    %10010010
	DEFB	%00010000
	DEFB	%00010000
	DEFB	%00010000
	DEFB	%00010000

	; left
	DEFB	%00000000
	DEFB	%00010000
	DEFB	%00100000
	DEFB	%01000000
	DEFB	%11111111
	DEFB	%01000000
	DEFB	%00100000
	DEFB	%00010000

        ; fire
	DEFB	%00011000
	DEFB	%00111100
	DEFB	%01000010
	DEFB	%10011001
	DEFB	%10011001
	DEFB	%01000010
	DEFB	%00111100
	DEFB	%00011000

        ; right
	DEFB	%00000000
	DEFB	%00001000
	DEFB	%00000100
	DEFB	%00000010
	DEFB	%11111111
	DEFB	%00000010
	DEFB	%00000100
	DEFB	%00001000

        ; down
	DEFB	%00010000
	DEFB	%00010000
	DEFB	%00010000
	DEFB	%00010000
	DEFB	%10010010
	DEFB	%01010100
	DEFB	%00111000
	DEFB	%00010000

; Pasmo uses this directive to USR to this value in the BASIC loader
	END	32768	

