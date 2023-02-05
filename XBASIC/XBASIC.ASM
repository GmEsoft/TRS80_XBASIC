;=====	XBASIC	12/04/86

;-----	Define the version of XBASIC
DEFVERS	MACRO
	DB	"XBASIC v0.0.1-alpha"
	DB	0DH,00H
	ENDM

;-----	Define a DOS exit
DEFV	MACRO	#A,#B
	ORG	#A
	JP	#B
	ENDM

;-----	Compare HL with arg1, JR to arg2 if equal
CP_JRZ	MACRO	#A,#J
	LD	DE,#A
	CALL	1C90H		;Compare HL,DE (RST 18H)
	JR	Z,#J
	ENDM

;-----	Intercept a return address on the stack
;	#A	Stack level
;	#B	Test address
;	#C	Jump address
;	Intercept return address at SP+#A;
;	if equal to #B replace it with #C
INTRCPT	MACRO	#A,#B,#C
	LD	HL,#A+2
	LD	DE,#B
	LD	BC,#C
	RST	30H
	ENDM

DEFT	MACRO	#A,#B
	DEFB	'#A'+80H
	DEFM	'#B'
	ENDM

;-----	Install vectors


	ORG	4026H		;*PR DCB
	DEFW	PR

	ORG	40ECH		;EDIT line number
	DEFW	10

	ORG	40E4H		;AUTO increment value
	DEFW	10

	DEFV	4003H,RST10H	; RST 10H vector
	DEFV	4006H,RST18H	; RST 18H vector
	DEFV	400FH,RST30H	; RST 30H vector
	DEFV	4152H,EXT	; CVI -> EXT$ (EXPAND)
	DEFV	4155H,FN0	; FN vector
	DEFV	4158H,BASFN	; CVS -> BASFN
	DEFV	415BH,DEF0	; DEF vector
	DEFV	415EH,CAPS	; CVD -> CAPS$
	DEFV	4161H,DEEK_	; EOF -> DEEK
	DEFV	4164H,ASN	; LOC -> ASN
	DEFV	4167H,ACS	; LOF -> ACS
	DEFV	416AH,COMP	; MKI$ -> COMP$
	DEFV	416DH,HEX	; MKS$ -> HEX$
	DEFV	4170H,BIN	; MKD$ -> BIN$
	DEFV	4173H,EXEC	; CMD -> EXEC
	DEFV	4176H,LOC	; TIME$ -> LOC
	DEFV	4179H,PLAY	; OPEN -> PLAY
	DEFV	417CH,ZAP	; FIELD -> ZAP
	DEFV	417FH,BEEP	; GET -> BEEP
	DEFV	4182H,DRAW	; PUT -> DRAW
	DEFV	4185H,INVERS	; CLOSE -> INVERSE
	DEFV	4188H,NOISE	; LOAD -> NOISE
	DEFV	418BH,MERGE	; MERGE
	DEFV	418EH,MOVE	; NAME -> MOVE
	DEFV	4191H,STORE	; KILL -> GENER
	DEFV	4194H,AMPERS	; '&' vector (&B,&0,&[H]...)
	DEFV	4197H,CALL	; LSET -> CALL
	DEFV	419AH,DOKE	; RSET -> DOKE
	DEFV	419DH,INS50	; INSTR vector
	DEFV	41A0H,RENEW	; SAVE -> RENEW
	DEFV	41A3H,LINE	; LINE input
	DEFV	41A6H,XERROR	; DOS exit for error processing
	DEFV	41A9H,US0	; USR0-9 vector
	DEFV	41ACH,XRES	; called at 1A1CH: return to "READY >" prompt
	DEFV	41AFH,XEDIT	; called at 0368H: Keyboard routine 0361H DOS exit
	DEFV	41BEH,PRE	; called at 2174H: termination of PRINT stmt:
				;   turn off cass and reset curr dev to video
	DEFV	41C1H,TT4	; called at 032CH: output to screen, printer or tape
	DEFV	41C4H,T1	; called at 0358H: scan keyboard
	DEFV	41CAH,PRI	; called at 206FH: PRINT routine, check arg '#'
	DEFV	41D0H,TT1	; called at 2103H: position video to next line
	DEFV	41D3H,TAB255	; PRINT TAB and PRINT#-1 DOS exit

	ORG	4016H		;*KI DCB + 1
	DEFW	KIDVR		;
	DEFW	0
	DEFW	4030H
	NOP
	DEFS	1		;*DO DCB
	DEFW	DODVR		;
	DEFS	2
	NOP
	DEFB	8FH		;Block cursor
	NOP

PTBCDE	EQU	09B4H
CSNG	EQU	0AB1H
SNGPSH	EQU	09A4H
GTBCDE	EQU	09BFH
SNGMUL	EQU	0847H
SNGSUB	EQU	0713H
SNGSQR	EQU	13E7H
SNGDIV	EQU	08A2H
SNGATN	EQU	15BDH
CHKSGN	EQU	0994H


MEM1	EQU	411DH		;start of WRA1 DP value; general purpose variable
BCHFLG	EQU	MEM1+2



;=====	Main XBASIC system
	ORG	42E8H

;-----	Intercept RST 10H vector
RST10H	PUSH	IX
	EXX
	LD	IX,0
	ADD	IX,SP
	LD	L,(IX+4)
	LD	H,(IX+5)
	CP_JRZ	1EC5H,CG	;intercept GOTO routine to CG (computed GOTO)
	CP_JRZ	1B1AH,CG	;intercept LIST routine to CG
	CP_JRZ	1F76H,CG	;intercept ON ERROR GOTO routine to CG
	CP_JRZ	1FAAH,CG	;intercept ON n GOTO routine to CG
	CP_JRZ	1FC4H,CG	;intercept RESUME routine to CG
	LD	DE,1D5BH	;intercept execution phase to QT (quoted label)
	LD	L,(IX+2)
	LD	H,(IX+3)
	CALL	1C90H		;Compare HL,DE (RST 18H)
	EXX
	POP	IX
	JR	Z,QT
	EXX
	INTRCPT	2,1A82H,SK2	;intercept input line w/o AUTO increment, to SK2
	EXX
	JP	1D78H		;load and examine next char (RST 10H original ROM code)

;-----	Quoted label at beginning of line
;	1000 "LABEL" ...
;	... GOSUB "LABEL"
QT	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	PUSH	AF
	CP	'"'
	JR	Z,QT1
	POP	AF
	RET

QT1	POP	AF
QT2	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	JR	NZ,QT3
	OR	A
	RET	Z
QT3	CP	'"'
	JR	NZ,QT2
	JP	1D78H		;load and examine next char (RST 10H original ROM code)

;-----	Computed GOTO, GOSUB, LIST ...
;	GOTO (expr)
;	GOTO "LABEL"
CG	EXX
	POP	IX
CR	CALL	1D78H		;load and examine next char (RST 10H original ROM code)
	LD	DE,0
	RET	Z
	JP	C,1E60H		;jump inside read line numer
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	RST	20H		;Check NTF (Num Type Flag of ACC)
	JR	Z,CG1		;jump if string
	PUSH	HL
	CALL	0FBDH		;conv number in ACC to asciiz -> HL
	CALL	1E5AH		;parse line number @HL -> DE
	POP	HL
L99	DEC	HL
	JP	1D78H		;load and examine next char (RST 10H original ROM code)

;-----	Goto "label" (case-sensitive!)
CG1	LD	DE,(4121H)	;int in ACC
	PUSH	HL
	EXX
	LD	HL,40B5H	;string work area
	LD	(40B3H),HL	;string work area ptr
	LD	HL,(40A4H)	;start of BASIC program
CG2	LD	A,(HL)
	INC	HL
	LD	B,(HL)
	LD	C,A
	OR	B
	JP	Z,1ED9H		;?UL Error
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	CALL	1D78H		;load and examine next char (RST 10H original ROM code)
	CP	'"'
	JR	Z,CG3
CG4	LD	H,B
	LD	L,C
	JR	CG2

CG3	EXX
	EX	DE,HL
	LD	B,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	DEC	HL
	DEC	HL
	EX	DE,HL
CG5	LD	A,B
	OR	A
	JR	Z,CG6
	LD	A,(HL)
	INC	HL
	EXX
	INC	HL
	CP	(HL)
	JR	NZ,CG4
	EXX
	DJNZ	CG5
CG6	EXX
	INC	HL
	LD	A,(HL)
	POP	HL
	OR	A
	JR	Z,L99
	CP	'"'
	JR	Z,L99
	PUSH	HL
	JR	CG4

;-----	called at 0358H: scan keyboard
T1	EXX
	POP	BC
	POP	DE
	LD	HL,1D21H	;RET address to check if T1 was called at 1D1EH (code execution)
	CALL	1C90H		;Compare HL,DE (RST 18H)
	PUSH	DE
	PUSH	BC
	EXX
	RET	NZ		;return if not

;-----	Loop for POKE a,d[,d...]
T10	DEC	HL
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	RET	Z
	PUSH	HL
	LD	HL,(40E6H)	;addr of last byte executed in current line
	LD	A,(HL)
	OR	A
	JR	NZ,INS10
	INC	HL
	INC	HL
	INC	HL
	INC	HL
INS10	RST	10H		;skip blanks
	POP	HL

;-----	NEW new_start
	CP	0BBH		;NEW token ?
	JR	NZ,T2
	CALL	2B02H		;parse int value to DE
	EX	DE,HL
	LD	(40A4H),HL	;start of BASIC program
	DEC	HL
	LD	(HL),0
	POP	HL
	JP	1B4AH		;NEW routine

;-----	RESTORE line_num
T2	CP	90H		;RESTORE token ?
	JR	NZ,T3
	DEC	HL
	CALL	CR
	PUSH	HL
	CALL	1B2CH		;Search matching line
	JP	NC,1ED9H	;?UL Error
	DEC	BC
	LD	(40FFH),BC	;DATA pointer
	POP	HL
	RET

;-----	POKE addr,value1[,value2...]
T3	CP	0B1H		;POKE token ?
	JR	NZ,T4
	INC	DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B1CH		;eval byte value to A
	POP	DE
	LD	(DE),A
	JR	T10

;-----	CLEAR string_pool[,himem]
T4	CP	0B8H		;CLEAR token ?
	RET	NZ
	POP	BC
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	LD	(40B1H),DE	;HIMEM=top or usable RAM
	POP	DE
	JP	1E80H		;CLEAR routine

;-----	RST 30H vector
;	verify caller ret address at stack level HL against DE
;	on match, replace caller address with BC
RST30H	PUSH	AF
	ADD	HL,SP
	LD	A,(HL)
	CP	E
	JR	NZ,TT0
	INC	HL
	LD	A,(HL)
	CP	D
	JR	NZ,TT0
	LD	(HL),B
	DEC	HL
	LD	(HL),C
TT0	POP	AF
	RET

;-----	called at 2103H: position video to next line
TT1	EXX
	INTRCPT	4,2FE6H,SK1	;intercept end of EDIT command, to SK1
	INTRCPT	4,2F46H,SK5	;intercept disp curr line in edit mode to SK5
	EXX
	RET

;-----	RST 18H vector
;	Intercept Compare HL,DE to stuff alternate RET address
RST18H	EXX
	INTRCPT	2,1A6BH,SK3	;if called at AUTO, return to SK3
	EXX
	JP	1C90H		;Compare HL,DE (original RST 18H code in ROM)

;-----	intercept end of EDIT command (from 2FE6H)
SK1	POP	BC
	POP	DE
	LD	A,D
	AND	E
	INC	A
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	RET	Z
	SCF
	INC	HL
	PUSH	AF
	JP	SK21

;-----	intercept input line w/o AUTO increment (from 1A82H)
SK2	INC	A
	DEC	A
	JP	Z,1A33H		;Jump to direct input phase
	PUSH	AF
	CALL	1E5AH		;parse line number @HL -> DE
SK20	DEC	HL
	LD	A,(HL)
	CP	20H
	JR	Z,SK20
	INC	HL
	LD	A,(HL)
	CP	20H
	CALL	Z,09C9H		;increment HL
SK21	PUSH	DE
	CALL	CMPRES
	JP	1A9CH		;ROM processing after tokenization

;-----	intercept when called at AUTO (from 1A6BH)
SK3	POP	DE
	JP	NC,1A5AH	;clear AUTO and return to direct input
	LD	(40E2H),HL	;current line number
	OR	0FFH
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	RET	Z
	SCF
	INC	HL
	PUSH	AF
	PUSH	DE
	CALL	CMPRES
	JP	1A9CH		;ROM processing after tokenization

;-----	intercept LIST routine before line expansion (from 2B67H)
SK4	CALL	EXPAND
	JP	2B6AH		;ROM processing after detokenization

;-----	intercept disp curr line in edit mode (from 2F46H)
SK5	POP	BC
	POP	HL
	PUSH	HL
	CALL	0FAFH		;disp line number in HL
	LD	A,' '
	CALL	032AH		;disp char
	JP	2E86H		;jump in EDIT routine

;-----	Expand with new tokens table
EXPAND	PUSH	HL
	LD	HL,(40A7H)	;input buffer pointer
	LD	B,H
	LD	C,L
	POP	HL
	LD	D,0FFH
	JR	EXT1

EXT0	INC	BC
	DEC	D
	RET	Z
EXT1	LD	A,(HL)
	OR	A
	INC	HL
	LD	(BC),A
	RET	Z
	JP	P,EXT0
	CP	0FBH
	JR	NZ,EXT2
	DEC	BC
	DEC	BC
	DEC	BC
	DEC	BC
	INC	D
	INC	D
	INC	D
	INC	D
EXT2	CP	95H
	CALL	Z,0B24H		;decrement BC
	SUB	7FH
	PUSH	HL
	LD	E,A
	LD	HL,TABLE
EXT3	LD	A,(HL)
	OR	A
	INC	HL
	JP	P,EXT3
	DEC	E
	JR	NZ,EXT3
	AND	7FH
EXT4	LD	(BC),A
	INC	BC
	DEC	D
	JP	Z,28D8H		;POP AF and RET
	LD	A,(HL)
	INC	HL
	OR	A
	JP	P,EXT4
	POP	HL
	JR	EXT1

;-----	intercept EDIT routine after line expansion (from 2E86H)
SK6	POP	DE
	PUSH	DE
	CALL	1B2CH		;Search matching line
	LD	H,B
	LD	L,C
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	CALL	EXPAND
	JP	2E86H		;jump in EDIT routine

;-----	Compress with new tokens table
CMPRES	XOR	A		;clear DATA flag
	LD	(40B0H),A	;DATA flag, to skip tokenizing data
	LD	C,A
	EX	DE,HL
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	DEC	HL
	EX	DE,HL
CM0	LD	A,(HL)
	CP	20H
	JP	Z,CMB
	LD	B,A
	CP	22H
	JP	Z,CMF
	OR	A
	JP	Z,CMG
	LD	A,(40B0H)	;DATA flag, to skip tokenizing data
	OR	A
	LD	A,(HL)
	JP	NZ,CMB
	CP	3FH
	LD	A,0B2H
	JP	Z,CMB
	LD	A,(HL)
	CP	30H
	JR	C,CM1
	CP	3CH
	JP	C,CMB
CM1	PUSH	DE
	LD	DE,TABLE-1
	PUSH	BC
	LD	BC,CM8
	PUSH	BC
	LD	B,7FH
	LD	A,(HL)
	CP	61H
	JR	C,CM2
	CP	7BH
	JR	NC,CM2
	AND	5FH
	LD	(HL),A
CM2	LD	C,(HL)
	EX	DE,HL
CM3	INC	HL
	OR	(HL)
	JP	P,CM3
	INC	B
	LD	A,(HL)
	AND	7FH
	RET	Z
	CP	C
	JR	NZ,CM3
	EX	DE,HL
	PUSH	HL
CM4	INC	DE
	LD	A,(DE)
	OR	A
	JP	M,CM7
	LD	C,A
	LD	A,B
	CP	8DH
	JR	NZ,CM5
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	DEC	HL
CM5	INC	HL
	LD	A,(HL)
	CP	61H
	JR	C,CM6
	AND	5FH
CM6	CP	C
	JR	Z,CM4
	POP	HL
	JR	CM2

CM7	LD	C,B
	POP	AF
	EX	DE,HL
	RET

CM8	EX	DE,HL
	LD	A,C
	POP	BC
	POP	DE
	EX	DE,HL
	CP	95H
	LD	(HL),3AH
	JR	NZ,CM9
	INC	C
	INC	HL
CM9	CP	0FBH
	JR	NZ,CMA
	LD	(HL),3AH
	INC	HL
	LD	B,93H
	LD	(HL),B
	INC	HL
	EX	DE,HL
	INC	C
	INC	C
	JR	CMF

CMA	EX	DE,HL
CMB	INC	HL
	LD	(DE),A
	INC	DE
	INC	C
	SUB	':'		;':' ?
	JR	Z,CMC		;if yes, clear DATA flag
	CP	4EH		; = DATA token - ':' ?
	JR	NZ,CMD		;if yes, set DATA flag
CMC	LD	(40B0H),A	;DATA flag, to skip tokenizing data
CMD	SUB	59H
	JP	NZ,CM0
	LD	B,A
CME	LD	A,(HL)
	OR	A
	JR	Z,CMG
	CP	B
	JR	Z,CMB
CMF	INC	HL
	LD	(DE),A
	INC	C
	INC	DE
	JR	CME

CMG	LD	HL,0005H
	LD	B,H
	ADD	HL,BC
	LD	B,H
	LD	C,L
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(DE),A
	INC	DE
	LD	(DE),A
	INC	DE
	LD	(DE),A
	RET

;-----	called at 206FH: PRINT routine
;	initialize PRINT #var$, [USING "...";] ...
PRI	CP	'#'
	RET	NZ
	CALL	2828H		;check for illegal direct
	PUSH	HL
	LD	(4044H),HL	;TODO: TBD (TIME$)
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	RST	20H		;Check NTF (Num Type Flag of ACC)
	JR	Z,PRINI1	;jump if string
	POP	HL
	DEC	HL
	JP	1D78H		;load and examine next char (RST 10H original ROM code)

PRINI1	RST	08H		;check next char
	DEFB	','
	LD	DE,(40A7H)	;input buffer pointer
	LD	(4040H),DE	;save input buffer pointer (OWN?)
	XOR	A
	LD	(4042H),A	;own storage (TIME$)
	LD	(4025H),A	;*PR device type
	INC	A
	LD	(409CH),A	;output device type := printer
	LD	(4043H),A	;own storage (TIME$)
	POP	DE
	RET

;-----	called at 032CH: output to screen, printer or tape
TT4	EXX
	INTRCPT	6,2B67H,SK4	;intercept LIST routine before line expansion, to SK4
	INTRCPT	6,2E86H,SK6	;intercept EDIT routine after line expansion, to SK6
	EXX
	LD	A,(4043H)	;own storage (TIME$)
	DEC	A
	RET	NZ
	PUSH	HL
	LD	HL,(4040H)	;saved input buffer pointer (OWN?)
	LD	(HL),C
	INC	HL
	LD	(4040H),HL	;save input buffer pointer (OWN?)
	LD	HL,4042H	;own storage (TIME$)
	XOR	A
	INC	(HL)
	CALL	Z,XRES0
	JP	C,29A3H		;concatenate 2 strings ?
	POP	HL
	RET

;-----	called at 2174H: turn off cass and reset curr dev to video
;	finalize PRINT #var$, [USING "...";] ...
PRE	LD	A,(4043H)	;own storage (TIME$)
	DEC	A
	RET	NZ
	CALL	XRES0
	PUSH	DE
	PUSH	BC
	PUSH	HL
	LD	HL,(4044H)	;TODO: TBD (TIME$)
	RST	08H		;check next char
	DEFB	'#'
	CALL	260DH		;locate variable
	PUSH	DE
	LD	HL,(4040H)	;saved input buffer pointer (OWN?)
	LD	(HL),0
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	LD	B,0
	CALL	2868H		;quote routine (quote char=B,<NUL>)
	POP	DE
	POP	HL
	LD	BC,PREXI1
	PUSH	BC
	PUSH	DE
	XOR	A
	JP	1F32H		;jump into LET routine

PREXI1	POP	BC
	POP	DE
	RET

XRES0	XOR	A
	LD	(409BH),A	;LPRINT current line position

;-----	called at 1A1CH: return to "READY >" prompt
;	Reser flags
XRES	XOR	A
	LD	(4043H),A	;own storage (TIME$)
	LD	A,6
	LD	(4025H),A	;*PR device type := 6 (default)
	SCF
	RET

TABLE	EQU	$

;*MLIST OFF
	DEFT	E,ND		;80
	DEFT	F,OR		;81
	DEFT	R,ESET		;82
	DEFT	S,ET		;83
	DEFT	C,LS		;84
	DEFT	E,XEC		;85 EXEC (from CMD)
	DEFT	R,ANDOM		;86
	DEFT	N,EXT		;87
	DEFT	D,ATA		;88
	DEFT	I,NPUT		;89
	DEFT	D,IM		;8A
	DEFT	R,EAD		;8B
	DEFT	L,ET		;8C
	DEFT	G,OTO		;8D
	DEFT	R,UN		;8E
	DEFT	I,F		;8F
	DEFT	R,ESTORE	;90
	DEFT	G,OSUB		;91
	DEFT	R,ETURN		;92
	DEFT	R,EM		;93
	DEFT	S,TOP		;94
	DEFT	E,LSE		;95
	DEFT	T,RON		;96
	DEFT	T,ROFF		;97
	DEFT	D,EFSTR		;98
	DEFT	D,EFINT		;99
	DEFT	D,EFSNG		;9A
	DEFT	D,EFDBL		;9B
	DEFT	L,INE		;9C
	DEFT	E,DIT		;9D
	DEFT	E,RROR		;9E
	DEFT	R,ESUME		;9F
	DEFT	O,UT		;A0
	DEFT	O,N		;A1
	DEFT	P,LAY		;A2 PLAY music$
	DEFT	Z,AP		;A3 ZAP (sound)
	DEFT	B,EEP		;A4 BEEP loops, pitch
	DEFT	D,RAW		;A5 DRAW x1,y1,x2,y2,col
	DEFT	I,NVERSE	;A6 INVERSE (video)
	DEFT	N,OISE		;A7 NOISE (sound)
	DEFT	M,ERGE		;A8 MERGE (program)
	DEFT	M,OVE		;A9 MOVE (block of memory)
	DEFT	S,TORE		;AA STORE (tokenized string)
	DEFT	C,ALL		;AB CALL addr
	DEFT	D,OKE		;AC DOKE addr,word
	DEFT	R,ENEW		;AD RENEW (reverse NEW)
	DEFT	S,YSTEM		;AE
	DEFT	L,PRINT		;AF
	DEFT	D,EF		;B0
	DEFT	P,OKE		;B1
	DEFT	P,RINT		;B2
	DEFT	C,ONT		;B3
	DEFT	L,IST		;B4
	DEFT	L,LIST		;B5
	DEFT	D,ELETE		;B6
	DEFT	A,UTO		;B7
	DEFT	C,LEAR		;B8
	DEFT	C,LOAD		;B9
	DEFT	C,SAVE		;BA
	DEFT	N,EW		;BB
	DEFT	T,AB(		;BC
	DEFT	T,O		;BD
	DEFT	F,N		;BE
	DEFT	U,SING		;BF
	DEFT	V,ARPTR		;C0
	DEFT	U,SR		;C1
	DEFT	E,RL		;C2
	DEFT	E,RR		;C3
	DEFT	S,TRING$	;C4
	DEFT	I,NSTR		;C5
	DEFT	P,OINT		;C6
	DEFT	L,OC		;C7 LOC (from TIME$)
	DEFT	M,EM		;C8
	DEFT	I,NKEY$		;C9
	DEFT	T,HEN		;CA
	DEFT	N,OT		;CB
	DEFT	S,TEP		;CC
	DEFB	'+'+80H		;CD
	DEFB	'-'+80H		;CE
	DEFB	'*'+80H		;CF
	DEFB	'/'+80H		;D0
	DEFB	91+80H		;D1
	DEFT	A,ND		;D2
	DEFT	O,R		;D3
	DEFB	'>'+80H		;D4
	DEFB	'='+80H		;D5
	DEFB	'<'+80H		;D6
	DEFT	S,GN		;D7
	DEFT	I,NT		;D8
	DEFT	A,BS		;D9
	DEFT	F,RE		;DA
	DEFT	I,NP		;DB
	DEFT	P,OS		;DC
	DEFT	S,QR		;DD
	DEFT	R,ND		;DE
	DEFT	L,OG		;DF
	DEFT	E,XP		;E0
	DEFT	C,OS		;E1
	DEFT	S,IN		;E2
	DEFT	T,AN		;E3
	DEFT	A,TN		;E4
	DEFT	P,EEK		;E5
	DEFT	E,XT$		;E6 EXT$(tokenized string)
	DEFT	B,ASFN		;E7 BASFN (from CVS)
	DEFT	C,APS$		;E8 CAPS$ (capitalize string)
	DEFT	D,EEK		;E9 DEEK(nnnn) -> word
	DEFT	A,SN		;EA ASN(x) -> arc sinus
	DEFT	A,CS		;EB ACS(x) -> arc cosinus
	DEFT	C,OMP$		;EC COMP$(string) -> tokenized string
	DEFT	H,EX$		;ED HEX$(x) -> hexadecimal string of x
	DEFT	B,IN$		;EE BIN$(x) -> binary string of x
	DEFT	C,INT		;EF
	DEFT	C,SNG		;F0
	DEFT	C,DBL		;F1
	DEFT	F,IX		;F2
	DEFT	L,EN		;F3
	DEFT	S,TR$		;F4
	DEFT	V,AL		;F5
	DEFT	A,SC		;F6
	DEFT	C,HR$		;F7
	DEFT	L,EFT$		;F8
	DEFT	R,IGHT$		;F9
	DEFT	M,ID$		;FA
	DEFB	"'"+80H		;FB
	DEFB	80H

;-----	Extended keyboard driver
;	blinking cursor
;	caps lock
;	switch LC with UC
KIDVR	LD	HL,BKI1
	PUSH	HL
	LD	A,(4022H)	;Char under cursor
	OR	A
	RET	Z
	LD	HL,401CH	;blink flag (0=no blink)
	LD	A,(HL)
	OR	A
	RET	NZ
	DEC	HL		;401BH=blink rate timer
	DEC	(HL)
	RET	NZ
	PUSH	HL
	LD	DE,(4020H)	;cursor position
	LD	HL,4022H	;Char under cursor
	LD	A,(DE)
	XOR	(HL)
	INC	HL		;4023H=cursor char
	XOR	(HL)
	LD	(DE),A
	INC	HL		;4024H=blink rate (timer reload)
	LD	A,(HL)
	POP	HL
	LD	(HL),A		;401BH=blink rate timer
	POP	HL
BKI1	CALL	03E3H		;ROM keyboard driver
	OR	A
	JR	NZ,BKI2
	LD	A,(387FH)	;test all keys except SHIFT
	OR	A
	JR	NZ,BKI3
	LD	(4018H),A	;clear 4018H=???
	RET

;	No key read but some keys are down
BKI3	LD	HL,401AH	;*KI repeat timer
	LD	B,(HL)
	DJNZ	$
	XOR	A
	DEC	HL
	DEC	HL
	DEC	(HL)		;4018H=*KI repeat counter
	RET	NZ
	LD	(HL),10H	;reload counter
	LD	HL,4036H	;clear buffer to repeat keys
	LD	DE,4037H
	LD	BC,0006H
	LD	(HL),00H
	LDIR
	JR	KIDVR

;	A key was read
BKI2	LD	HL,4019H	;CAPS flag
	CP	20H		;space ?
	JR	NZ,BKI4
	LD	A,(403CH)	;Space bar down ?
	BIT	7,A
	LD	A,20H
	RET	NZ		;ret if yes
	XOR	(HL)		;else Shift-0 => toggle caps lock
	LD	(HL),A
	XOR	A		;return NUL
	RET

;-----	Toggle case with caps lock flag
BKI4	CP	60H
	RET	Z
	CP	5BH
	RET	Z
	CP	41H
	RET	C
	XOR	20H
	CP	60H
	RET	C
	XOR	(HL)		;All caps if caps lock flag set
	RET

;-----	Extended lower-case display driver
;	with blinking cursor
DODVR	LD	HL,BDO1
	PUSH	HL
	LD	L,(IX+03H)
	LD	H,(IX+04H)
	JP	C,049AH		;get last char request
	LD	A,(IX+05H)
	OR	A
	JR	Z,BDO2
	LD	(HL),A
BDO2	LD	A,C
	CP	20H
	JP	C,0506H		;process control characters
	CP	80H
	JP	NC,04A6H	;graphic or space compression chars
	JP	047DH		;displayable character (not converted to UC)

BDO1	RET	Z
	LD	A,(4023H)	;cursor char
	LD	(HL),A
	LD	A,(4024H)	;cursor blink rate
	LD	(401BH),A	;reload blink timer
	LD	A,C
	RET

;-----	Extended program editor
XEDIT	EXX
	POP	BC
	POP	DE
	LD	HL,1A7EH	;called at BASIC direct command mode?
	CALL	1C90H		;Compare HL,DE (RST 18H)
	PUSH	DE
	PUSH	BC
	EXX
	RET	NZ		;return if not
	LD	A,0EH		;cursor on
	CALL	0033H		;DDISA: Display char
	CALL	0049H		;WAITKI: Wait key in
	PUSH	AF
	CP	'.'
	JP	Z,CURLIN
	CP	','
	JP	Z,EDIT
	CP	01H
	JP	Z,XEQLIN
	CP	5BH
	JR	Z,PRVLIN
	CP	0AH
	JR	Z,NXTLIN
	CP	'/'
	JP	Z,AUTO
	CP	':'
	JP	Z,LSTART
	CP	'@'
	JP	Z,LEND
NOLIST	POP	AF
	EX	(SP),HL
	POP	HL
	PUSH	BC
	LD	HL,(40A7H)	;input buffer pointer
	LD	B,0FFH
	PUSH	HL
	LD	HL,0374H	;push ret addr to process input
	EX	(SP),HL
	PUSH	HL
	LD	C,B
	JP	05E3H		;keyboard input processing

NXTLIN	LD	DE,(40ECH)	;EDIT line number
	LD	A,D
	AND	E
	INC	A
	JR	NZ,BEDIT1
	LD	DE,0000H
BEDIT1	CALL	1B2CH		;Search matching line
	JR	C,BEDIT2
	JR	Z,NOLIST
	LD	H,B
	LD	L,C
BEDIT2	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	JR	Z,CURLIN
BEDIT3	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	PUSH	BC
	EX	(SP),HL
	LD	(40ECH),HL	;EDIT line number
	LD	A,1DH		;beginning of line
	CALL	032AH		;disp char
	CALL	0FAFH		;disp line number in HL
	LD	A,' '
	CALL	032AH		;disp char
	POP	HL
	CALL	EXPAND
	LD	HL,(40A7H)	;input buffer pointer
	CALL	2B75H		;disp null-terminated string
	CALL	20FEH		;display CR
	POP	DE
	POP	DE
	POP	DE
	JP	1A76H		;direct input mode with '>' prompt

PRVLIN	LD	DE,(40ECH)	;EDIT line number
	CALL	1B2CH		;Search matching line
	PUSH	BC
	POP	DE
	LD	HL,(40A4H)	;start of BASIC program
	RST	18H		;Compare HL with DE
	JR	Z,CURLIN
BEDIT4	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	A,B
	OR	C
	JR	Z,NOLIST
	PUSH	BC
	EX	(SP),HL
	RST	18H		;Compare HL with DE
	POP	HL
	JR	Z,BEDIT3
	LD	H,B
	LD	L,C
	JR	BEDIT4

CURLIN	LD	DE,(40ECH)	;EDIT line number
	LD	A,D
	AND	E
	INC	A
	JR	Z,XEQLIN
BEDIT6	CALL	1B2CH		;Search matching line
	JR	C,BEDIT5
	JP	Z,NOLIST
BEDIT5	PUSH	BC
	POP	HL
	INC	HL
	INC	HL
	JR	BEDIT3

XEQLIN	LD	DE,(40F5H)	;last line executed
	JR	BEDIT6

EDIT	LD	A,1DH		;beginning of line
	CALL	032AH		;disp char
	LD	DE,(40ECH)	;EDIT line number
	JP	2E6AH		;edit line in DE

AUTO	LD	A,1DH		;beginning of line
	CALL	032AH		;disp char
	LD	DE,(40ECH)	;EDIT line number
	PUSH	DE
	CALL	1B2CH		;Search matching line
	POP	HL
	LD	DE,(40E4H)	;AUTO increment value
	JR	NC,BEDIT7
	ADD	HL,DE
BEDIT7	EX	(SP),HL
	JP	2025H		;jump into AUTO routine

LSTART	LD	HL,(40A4H)	;start of BASIC program
	LD	DE,(40ECH)	;EDIT line number
	CALL	01C9H		;clear the screen
	POP	BC
	POP	BC
	POP	BC
	JP	2B3BH		;jump into LIST routine

LEND	LD	A,1DH		;beginning of line
	CALL	032AH		;disp char
	LD	DE,(40ECH)	;EDIT line number
	LD	HL,0FFFAH
	CALL	1B2AH		;search matching line
	JP	2B32H		;jump into LIST routine

;-----	func BASFN(tokens$)
;	Evaluate BASIC expression in tokenized string tokens$
BASFN	CALL	29D7H		;get addr of current string ptr into HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	JP	2337H		;evaluate expression ACC := EVAL(*HL)

;-----	func COMP$(text$)
;	Tokenize BASIC string in text$
COMP	CALL	29D7H		;get addr of current string ptr into HL
	LD	DE,(40A7H)	;input buffer pointer
	PUSH	DE
	CALL	29C8H		;move *HL chars from *(HL+1) to DE
	XOR	A
	LD	(DE),A
	POP	HL
	CALL	CMPRES
	LD	B,00H
	CALL	2868H		;quote routine (quote char=B,<NUL>)
	CALL	29DAH		;get addr of curr value into HL
	LD	BC,2A2BH	;to return to interpreter ?
	PUSH	BC
	LD	A,(HL)		;A = length of string
	INC	A		; + 1 ...
	JP	2844H		;return value as string

;-----	func EXT$(tokens$)
;	expand tokenized string
EXT	CALL	2A13H		;get string addr into DE, 1st char in A
	EX	DE,HL
	CALL	EXPAND
	LD	HL,(40A7H)	;input buffer pointer
	DEC	HL
	LD	B,00H
	CALL	2868H		;quote routine (quote char=B,<NUL>)
	JP	283CH		;return value as String

;-----	stmt DRAW x1,y1,x2,y2,color
;	Draw a line from (x1,y1) to (x2,y2) in given color
DRAW	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B1CH		;eval byte value to A
	LD	(COLOUR),A
	POP	DE
	POP	BC
	EX	(SP),HL
	PUSH	BC
	LD	(YB),DE
	LD	(YA),HL
	CALL	0A39H		;compare INT values, sign of diff in A
	LD	A,0
	RL	A		;CY set if HL<DE
	LD	(SY),A
	OR	A
	JR	Z,NOEXC1
	EX	DE,HL
NOEXC1	SBC	HL,DE
	LD	(DY),HL
	POP	DE
	POP	BC
	POP	HL
	PUSH	BC
	LD	(XB),DE
	LD	(XA),HL
	CALL	0A39H		;compare INT values, sign of diff in A
	LD	A,0
	RL	A
	LD	(SX),A
	OR	A
	JR	Z,NOEXC2
	EX	DE,HL
NOEXC2	SBC	HL,DE
	LD	(DX),HL
	PUSH	DE
	LD	BC,(XA)
	LD	DE,(YA)
	CALL	PLOT
	POP	DE
	LD	DE,(DY)
	CALL	0A39H		;compare INT values, sign of diff in A
	JR	C,DRAW2
	LD	BC,(YA)
	SRL	D
	RR	E
	PUSH	DE
	LD	HL,(XA)
DRAW10	LD	DE,(XB)
	RST	18H		;Compare HL with DE
	JR	Z,ENDRAW
	INC	HL
	LD	A,(SX)
	OR	A
	JR	NZ,DRAW12
	DEC	HL
	DEC	HL
DRAW12	EX	(SP),HL
	LD	DE,(DY)
	ADD	HL,DE
	LD	DE,(DX)
	CALL	0A39H		;compare INT values, sign of diff in A
	JR	C,DRAW11
	SBC	HL,DE
	INC	BC
	LD	A,(SY)
	OR	A
	JR	NZ,DRAW11
	DEC	BC
	DEC	BC
DRAW11	EX	(SP),HL
	PUSH	BC
	LD	D,B
	LD	E,C
	LD	B,H
	LD	C,L
	CALL	PLOT
	POP	BC
	JR	DRAW10

DRAW2	LD	BC,(XA)
	SRL	H
	RR	L
	PUSH	HL
	LD	HL,(YA)
DRAW20	LD	DE,(YB)
	RST	18H		;Compare HL with DE
	JR	Z,ENDRAW
	INC	HL
	LD	A,(SY)
	OR	A
	JR	NZ,DRAW22
	DEC	HL
	DEC	HL
DRAW22	EX	(SP),HL
	LD	DE,(DX)
	ADD	HL,DE
	LD	DE,(DY)
	CALL	0A39H		;compare INT values, sign of diff in A
	JR	C,DRAW21
	SBC	HL,DE
	INC	BC
	LD	A,(SX)
	OR	A
	JR	NZ,DRAW21
	DEC	BC
	DEC	BC
DRAW21	EX	(SP),HL
	EX	DE,HL
	CALL	PLOT
	EX	DE,HL
	JR	DRAW20

ENDRAW	POP	HL
	POP	HL
	RET

YA	DEFW	0
YB	DEFW	0
XA	DEFW	0
XB	DEFW	0
DX	DEFW	0
DY	DEFW	0
COLOUR	NOP
SX	NOP
SY	NOP

;-----	Graphics plot routine
PLOT	XOR	A
	CP	B
	RET	NZ
	CP	D
	RET	NZ
	BIT	7,C
	RET	NZ
	LD	A,E
	CP	48
	RET	NC
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	D,E
	LD	E,C
	LD	A,D
	LD	L,255
PLOT5	INC	L
	SUB	3
	JR	NC,PLOT5
	ADD	A,3
	SLA	A
	INC	A
	LD	B,A
	LD	A,128
PLOT6	RLCA
	DJNZ	PLOT6
	LD	H,0
	LD	B,6
PLOT7	ADD	HL,HL
	DJNZ	PLOT7
	LD	D,3CH
	SRL	E
	JR	NC,PLOT8
	RLCA
PLOT8	ADD	HL,DE
	BIT	7,(HL)
	JR	NZ,PLOT9
	LD	(HL),80H
PLOT9	LD	B,A
	LD	A,(COLOUR)
	AND	1
	LD	A,B
	JR	Z,RESET
	OR	(HL)
	JR	FPLOT

RESET	CPL
	AND	(HL)
FPLOT	LD	(HL),A
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET

;-----	stmt LINE INPUT [#len,]["prompt",][!]var$
;	Input a string from keyboard.
;	#len = max length of the string
;	! to reject and suppress display of control chars
LINE	LD	A,(HL)
	CP	89H		;INPUT token ?
	JP	NZ,RENUM	;if not, exec RENUM
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	LD	E,255
	CP	'#'
	JR	NZ,SVLGTH
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	CALL	2B1CH		;eval byte value to A
	RST	08H		;check next char
	DEFB	','
SVLGTH	PUSH	DE
	CALL	2828H		;check for illegal direct
	LD	A,(HL)
	CALL	21CDH		;do prompt if any
	LD	A,(HL)
	CP	'!'		;'!' to suppress CR after input ?
	JR	NZ,NOEXP
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	XOR	A
NOEXP	POP	BC
	LD	B,C
	PUSH	HL
	LD	HL,ENDINP	;push end input ret address
	PUSH	HL
	PUSH	BC
	LD	HL,0374H	;push ret addr to process input
	PUSH	HL
	LD	HL,(40A7H)	;input buffer pointer
	JP	NZ,05D9H	;original text input routine if no '!'
	PUSH	HL
	LD	A,0EH		;cursor on
	CALL	0033H		;DDISA: Display char
KEYSCN	CALL	0049H		;WAITKI: Wait key in
	CP	' '
	JR	C,CNTRL
	LD	(HL),A
	LD	A,B
	OR	A
	JR	Z,KEYSCN
	LD	A,(HL)
	INC	HL
	CALL	0033H		;DDISA: Display char
	DEC	B
	JR	KEYSCN

CNTRL	CP	0DH		;<ENTER> ?
	PUSH	AF
	JP	Z,0669H		;process ENTER without echoing it
	POP	AF
	CP	1		;<BREAK> ?
	JP	Z,0661H		;process BREAK key
	LD	DE,KEYSCN	;push KEYSCN ret address
	PUSH	DE
	CP	8		;<LEFT> ?
	JP	Z,0630H		;erase last char
	CP	18H		;<SH-LEFT> ?
	JP	Z,062BH		;erase whole line
	RET			;wait next char

ENDINP	POP	BC
	JP	C,1DBEH		;jump if <BREAK> was pressed, break program
	PUSH	BC
	EX	(SP),HL
	CALL	260DH		;locate variable
	CALL	0AF4H		;check that it's a string
	EX	DE,HL
	EX	(SP),HL
	PUSH	DE
	LD	B,0
	CALL	2868H		;quote routine (quote char=B,<NUL>)
	POP	HL
	XOR	A
	JP	1F32H		;jump into LET routine, assign string to variable

;-----	stmt LINE start[,inc]
;	Renumber the BASIC program.
RENUM	LD	DE,000AH
	DEC	HL
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	PUSH	DE
	JR	Z,RENUM1
	CALL	1E4FH		;get line number from ASCII into DE
	EX	DE,HL
	EX	(SP),HL
	JR	Z,RENUM2
	EX	DE,HL
	RST	08H		;check next char
	DEFB	','
	EX	DE,HL
	LD	HL,(40E4H)	;AUTO increment value
	EX	DE,HL
	JR	Z,RENUM1
	CALL	1E5AH		;parse line number @HL -> DE
	JP	NZ,1997H	;?SN Error
RENUM1	EX	DE,HL
RENUM2	LD	A,H
	OR	L
	JP	Z,1E4AH		;?FC Error
	LD	(40E4H),HL	;AUTO increment value
	LD	HL,2A2AH
	LD	(3C3EH),HL
	POP	HL
	LD	(40E2H),HL	;current line number
	EX	DE,HL
	LD	HL,(40A4H)	;start of BASIC program
RENUM3	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	JP	Z,DEL255
	CALL	022CH		;blink '*' in screen upper right corner
	LD	C,(HL)
	LD	(HL),E
	INC	HL
	LD	B,(HL)
	LD	(HL),D
	INC	HL
	LD	(MEM1),HL
	LD	HL,(40A4H)	;start of BASIC program
	DEC	HL
RENUM5	INC	HL
	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	INC	HL
	JR	NZ,NOBCH
	LD	HL,(MEM1)
RENUML	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	OR	A
	JR	NZ,RENUML
	INC	HL
	PUSH	HL
	LD	HL,(40E4H)	;AUTO increment value
	ADD	HL,DE
	EX	DE,HL
	POP	HL
	JR	RENUM3

NOBCH	XOR	A
	LD	(BCHFLG),A
	JR	RENUM6

RENUM6	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	JR	C,RENUM6
	INC	A
	JR	Z,RENUM6
	DEC	A
	JR	Z,RENUM5
	CP	0CAH
	JR	Z,BCH
	CP	0B8H
	JR	NC,NOBCH
	CP	0B4H
	JR	NC,BCH
	CP	9FH
	JR	Z,BCH
	CP	9DH
	JR	Z,BCH
	CP	95H
	JR	Z,BCH
	CP	91H
	JR	Z,BCH
	CP	90H
	JR	Z,BCH
	CP	8FH
	JR	NC,NOBCH
	CP	8DH
	JR	NC,BCH
	CP	','
	JR	NZ,NOBCH
	LD	A,(BCHFLG)
	OR	A
	JR	Z,RENUM6
BCH	LD	(BCHFLG),A
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	OR	A
	JR	Z,RENUM5
	INC	A
	JR	Z,RENUM6
	DEC	HL
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	DEC	HL
	JR	NC,NOBCH
	INC	HL
	PUSH	HL
	PUSH	DE
	CALL	1E5AH		;parse line number @HL -> DE
	LD	A,B
	SUB	D
	LD	D,A
	LD	A,C
	SUB	E
	OR	D
	POP	DE
	JR	Z,BCH0
	POP	HL
	JR	RENUM6

BCH0	EX	DE,HL
	EX	(SP),HL
	PUSH	BC
	PUSH	HL
	OR	A
	PUSH	DE
	PUSH	HL
	SBC	HL,DE
	EX	(SP),HL
	LD	DE,(MEM1)
	RST	18H		;Compare HL with DE
	EX	(SP),HL
	EX	DE,HL
	JR	C,$+3
	DEFB	3EH
	ADD	HL,DE
	LD	(MEM1),HL
	POP	HL
	POP	DE
CHG1	LD	B,3
CHG2	LD	A,(DE)
	LD	(HL),A
	INC	HL
	INC	DE
	OR	A
	JR	NZ,CHG1
	DJNZ	CHG2
	POP	HL
	POP	BC
	POP	DE
	LD	(4121H),DE	;WRA1
	PUSH	HL
	LD	HL,4130H	;ASCII buffer
	PUSH	BC
	LD	BC,0
	CALL	132FH		;conv INT number to ASCII in work area
	POP	BC
	POP	HL
	PUSH	DE
	LD	DE,4130H	;ASCII buffer
	LD	A,255
	CALL	INS
SKIP0	LD	A,(DE)
	INC	DE
	CP	'0'
	JR	Z,SKIP0
	DEC	DE
	OR	A
	JR	NZ,PUTLN
	DEC	DE
PUTLN	LD	A,(DE)
	INC	DE
	OR	A
	CALL	NZ,INS
	JR	NZ,PUTLN
	POP	DE
	DEC	HL
	JP	RENUM6

;-----	Insertion routine
INS	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD	C,A
	PUSH	DE
	EX	DE,HL
	LD	HL,(MEM1)
	RST	18H		;Compare HL with DE
	JR	NC,$+3
	DEFB	3EH
	INC	HL
	LD	(MEM1),HL
	EX	DE,HL
	POP	DE
INS0	LD	B,3
INS1	LD	A,(HL)
	LD	(HL),C
	INC	HL
	LD	C,A
	OR	A
	JR	NZ,INS0
	DJNZ	INS1
	LD	(HL),A
	POP	HL
	POP	BC
	POP	AF
	INC	HL
	RET

DEL255	LD	HL,(40A4H)	;start of BASIC program
	POP	BC
	DEC	HL
DEL0	LD	A,(HL)
	INC	HL
	INC	A
	JR	Z,DEL2
	DEC	A
	JR	NZ,DEL0
	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	LD	(40F9H),HL	;end of BASIC program
	JP	Z,2C83H		;end of CLOAD, begin execution?
	INC	HL
	INC	HL
	JR	DEL0

DEL2	PUSH	HL
	LD	D,H
	LD	E,L
	DEC	DE
DEL3	LD	B,3
DEL4	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	OR	A
	JR	NZ,DEL3
	DJNZ	DEL4
	POP	HL
	JR	DEL0

;-----	func ASN(x)
;	Get the arcsine of x.
ASN	CALL	CSNG
	CALL	SNGPSH
	CALL	GTBCDE
	CALL	SNGMUL
	LD	BC,8100H
	LD	DE,0
	CALL	SNGSUB
	CALL	SNGSQR
	CALL	CHKSGN
	POP	BC
	POP	DE
	PUSH	AF
	CALL	NZ,SNGDIV
	POP	AF
	JP	NZ,SNGATN
	CALL	PTBCDE
	LD	BC,8149H
	LD	DE,0FDBH
	JP	SNGMUL

;-----	func ACS(x)
;	Get the arccosine of x.
ACS	CALL	ASN
	LD	BC,8149H
	LD	DE,0FDBH
	JP	SNGSUB

;-----	GET routine for PLAY
GET	PUSH	HL
	PUSH	DE
	LD	HL,(4121H)	;WRA1
	LD	A,(HL)
	OR	A
	JR	NZ,GET1
	LD	A,'*'
	POP	DE
	POP	HL
	RET

GET1	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,(DE)
	POP	DE
	POP	HL
	RET

;-----	INC routine for PLAY
INC	PUSH	HL
	PUSH	DE
	LD	HL,(4121H)	;WRA1
	DEC	(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	DE
	LD	(HL),D
	DEC	HL
	LD	(HL),E
	POP	DE
	POP	HL
	RET

;-----	stmt PLAY music$
;	Duophonic music player
PLAY	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	PUSH	HL
	CALL	29D7H		;get addr of current string ptr into HL
	LD	(4040H),SP	;save SP (TODO: why?)
	;DB	0EDH,0F5H	;*BREAK*
PLAY1	LD	HL,PLAY1
	PUSH	HL
	LD	IY,FREQM1
PLAY2	CALL	GET
	CALL	INC
	CP	'A'
	JP	C,PLAYE
	CP	'W'+1
	JP	NC,PLAYE
	SUB	'A'
	SLA	A
	LD	B,A
	CALL	GET
	CP	'#'
	JR	NZ,PLAY3
	CALL	INC
	JR	PLAY4

PLAY3	INC	B
PLAY4	LD	A,B
	LD	(PLAY5+2),A
PLAY5	LD	A,(IY+2BH)
	LD	D,A
	LD	E,A
	CALL	GET
	CALL	INC
	CP	'A'
	JR	C,PLAY9
	CP	'W'+1
	JR	NC,PLAY9
	SUB	'A'
	SLA	A
	LD	B,A
	CALL	GET
	CP	'#'
	JR	NZ,PLAY6
	CALL	INC
	JR	PLAY7

PLAY6	INC	B
PLAY7	LD	A,B
	LD	(PLAY8+2),A
PLAY8	LD	A,(IY+2BH)
	LD	E,A
	CALL	GET
	CALL	INC
PLAY9	CP	'1'
	JP	C,TESTF
	CP	'6'
	JP	NC,TESTF
	SUB	'1'
	SLA	A
	ADD	A,2CH
	LD	(PLAYA+2),A
	INC	A
	LD	(PLAYB+2),A
PLAYA	LD	L,(IY+2EH)
PLAYB	LD	H,(IY+2FH)
	CALL	GET
	CP	'.'
	JR	NZ,PLAYC
	CALL	INC
	PUSH	HL
	POP	BC
	SRL	B
	RR	C
	ADD	HL,BC
PLAYC	LD	B,D
	LD	C,E
	LD	A,01H
PLAYD	DEC	C
	JP	NZ,PLAYD0
	LD	C,E
	XOR	01H
	OUT	(0FFH),A
PLAYD0	DJNZ	PLAYD1
	LD	B,D
	XOR	02H
	OUT	(0FFH),A
PLAYD1	DEC	L
	JP	NZ,PLAYD
	DEC	H
	JP	NZ,PLAYD
	JP	PLAY2

PLAYE	CP	'<'
	JR	NZ,TESTF
	CALL	GET
	CALL	INC
	CP	'1'
	JR	C,TESTF
	CP	'6'
	JR	NC,TESTF
	SUB	'1'
	SLA	A
	ADD	A,DURM1-FREQM1
	LD	(PLAYF+2),A
	INC	A
	LD	(PLAYG+2),A
PLAYF	LD	L,(IY+2CH)
PLAYG	LD	H,(IY+2DH)
	CALL	GET
	CP	'.'
	JR	NZ,PLAYH
	CALL	INC
	PUSH	HL
	POP	BC
	SRL	B
	RR	C
	ADD	HL,BC
PLAYH	LD	(0000H),HL
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,PLAYH
	JP	PLAY2

TESTF	CP	'*'
	RET	NZ
	POP	HL
	POP	HL
	RET

FREQM1:	; Frequencies for Model I
	DB	9CH,0A5H	;C1
	DB	8BH,93H		;D1
	DB	83H,83H		;E1
	DB	75H,7CH		;F1
	DB	68H,6EH		;G1
	DB	5DH,62H		;A2
	DB	57H,57H		;B2
	DB	4EH,53H		;C2
	DB	45H,4AH		;D2
	DB	42H,42H		;E2
	DB	3AH,3EH		;F2
	DB	34H,37H		;G2
	DB	2EH,31H		;A3
	DB	2CH,2CH		;B3
	DB	27H,29H		;C3
	DB	23H,25H		;D3
	DB	21H,21H		;E3
	DB	1DH,1FH		;F3
	DB	1AH,1CH		;G3
	DB	17H,19H		;A4
	DB	16H,16H		;B4
	DB	13H,14H		;C4
DURM1:	; Durations for Model I
	DW	0A8A3H		;whole note
	DW	05452H		;half note
	DW	02A29H		;quarter note
	DW	01514H		;eighth note
	DW	01C1BH		;sixth note

;-----	Extended error message builder
XERROR	POP	HL
	LD	HL,ERRMSG
	LD	A,E
	OR	A
	JR	Z,XERRZ
XERR0	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	JR	NZ,XERR0
	INC	HL
	DEC	E
	DEC	E
	JR	NZ,XERR0
XERRZ	JP	1A01H		;disp error message in HL

ERRMSG	DEFM	'NEXT without FOR'		;01=NF
	NOP
	DEFM	'Syntax Error'			;02=SN
	NOP
	DEFM	'RETURN without GOSUB'		;03=RG
	NOP
	DEFM	'Out of DATA'			;04=OD
	NOP
	DEFM	'Illegal Function Call'		;05=FC
	NOP
	DEFM	'Overflow'			;06=OV
	NOP
	DEFM	'Out of Memory'			;07=OM
	NOP
	DEFM	'Undefined Line'		;08=UL
	NOP
	DEFM	'Subscript Out of Range'	;09=BS
	NOP
	DEFM	'Redimensioned Array'		;0A=DD
	NOP
	DEFM	'Division by Zero'		;0B=/0
	NOP
	DEFM	'Illegal Direct'		;0C=ID
	NOP
	DEFM	'Type Mismatch'			;0D=TM
	NOP
	DEFM	'Out of String Space'		;0E=OS
	NOP
	DEFM	'String too Long'		;0F=LS
	NOP
	DEFM	'String Formula too Complex'	;10=ST
	NOP
	DEFM	'Can'
	DEFB	"'"
	DEFM	't CONTinue'			;11=CN
	NOP
	DEFM	'No RESUME'			;12=NR
	NOP
	DEFM	'RESUME without ERROR'		;13=RW
	NOP
	DEFM	'Unprintable ERROR'		;14=UE
	NOP
	DEFM	'Missing Operand'		;15=MO
	NOP
	DEFM	'Bad File Data'			;16=FD
	NOP
	DEFM	'Function Not Available'	;17=L3
	NOP
	DEFM	'Undefined Function'		;18=UE
	NOP

EXEC	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	CALL	2828H		;check for illegal direct
	LD	(4050H),HL	;EXEC save HL
	POP	HL
	LD	(4052H),SP	;EXEC save SP
	LD	(4054H),HL	;EXEC save RET
	CALL	29D7H		;get addr of current string ptr into HL
	LD	DE,(40A7H)	;input buffer pointer
	DEC	DE
	DEC	DE
	PUSH	DE
	CALL	29C8H		;move *HL chars from *(HL+1) to DE
	XOR	A
	LD	(DE),A
	POP	HL
	DEC	HL
L5116H	CALL	0358H		;scan keyboard
	OR	A
	CALL	NZ,1DA0H	;check for pause/break and save char typed
	LD	(40E6H),HL	;addr of last byte executed in current line
	LD	(40E8H),SP	;save CSP
	LD	A,(HL)
	CP	':'
	JR	Z,L5139H
	OR	A
	JP	NZ,1E4AH	;?FC Error
	LD	HL,(4054H)	;EXEC save RET
	LD	SP,(4052H)	;EXEC save SP
	PUSH	HL
	LD	HL,(4050H)	;EXEC save HL
	RET

L5139H	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	LD	DE,L5116H	;load return address after instr execution
	JP	1D5EH		;push return addrss in DE and exec next instr

;-----	TODO: DUPLICATE to remove
DEEK_	CALL	0A7FH		;CINT: convert value to INT into HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	JP	0A9AH		;return INT value in HL into WRA1 (4121H)

;-----	func HEX$(num)
HEX	CALL	0A7FH		;CINT: convert value to INT into HL
	PUSH	HL
	LD	A,04H
	CALL	2857H		;Allocate A bytes in string area
	POP	HL
	LD	A,H
	CALL	ATOHEX
	LD	A,L
	CALL	ATOHEX
XHEXBIN	POP	BC
	JP	2884H		;store and return string

;-----	func BIN$(num)
BIN	CALL	0A7FH		;CINT: convert value to INT into HL
	PUSH	HL
	LD	A,10H
	CALL	2857H		;Allocate A bytes in string area
	POP	HL
	LD	A,H
	CALL	ATOBIN
	LD	A,L
	CALL	ATOBIN
	JR	XHEXBIN

;-----	Convert A to hex string into *DE
ATOHEX	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	NTOHEX
	POP	AF
	AND	0FH
NTOHEX	AND	0FH
	ADD	A,90H
	DAA
	ADC	A,40H
	DAA
	LD	(DE),A
	INC	DE
	RET

;-----	Convert A to binary string into *DE
ATOBIN	LD	B,08H
LATOBIN	RLCA
	PUSH	AF
	LD	A,18H
	ADC	A,A
	LD	(DE),A
	INC	DE
	POP	AF
	DJNZ	LATOBIN
	RET

;-----	stmt ZAP
;	generate a ZAP noise (fire phasers)
ZAP	LD	C,01H
	LD	A,C
L519AH	LD	B,C
L519BH	LD	(0000H),A
	DJNZ	L519BH
	OUT	(0FFH),A
	XOR	03H
	INC	C
	JR	NZ,L519AH
	RET

;-----	stmt BEEP loops, pitch
;	generate a monotone beep
BEEP	CALL	2B1CH		;eval byte value to A
	PUSH	AF
	RST	08H		;check next char
	DEFB	','
	CALL	2B1CH		;eval byte value to A
	POP	AF
	LD	B,A
	LD	C,D
	INC	D
	LD	A,D
L51B6H	DEC	D
	JP	NZ,L51BDH
	XOR	03H
	LD	D,E
L51BDH	OUT	(0FFH),A
	DEC	BC
	EX	AF,AF'
	LD	A,B
	OR	C
	RET	Z
	EX	AF,AF'
	JR	L51B6H

;-----	stmt NOISE loops, pitch
;	generate some noise
NOISE	CALL	2B1CH		;eval byte value to A
	PUSH	AF
	RST	08H		;check next char
	DEFB	','
	CALL	2B1CH		;eval byte value to A
	POP	AF
	LD	B,A
	LD	C,D
	INC	D
	PUSH	HL
	LD	H,C
	LD	L,C
	LD	D,01H
L51D9H	DEC	D
	JP	NZ,L51DFH
	LD	D,E
	INC	HL
L51DFH	LD	A,(HL)
	RLCA
	AND	03H
	OUT	(0FFH),A
	DEC	BC
	LD	A,B
	OR	C
	JP	Z,2C1DH		;pop HL and return
	JR	L51D9H

;-----	stmt INVERSE
;	reverse the graphics on the screen
INVERS	PUSH	HL
	LD	HL,3C00H
L51F1H	LD	A,(HL)
	CP	20H
	JR	NZ,L51F8H
	LD	A,80H
L51F8H	BIT	7,A
	JR	Z,L51FFH
	XOR	3FH
	LD	(HL),A
L51FFH	INC	HL
	BIT	6,H
	JR	Z,L51F1H
	POP	HL
	RET

;-----	stmt MERGE "name"
;	merge a program from cassette
MERGE	LD	A,(HL)
	OR	A
	JR	Z,L5211H
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	CALL	2A13H		;get string addr into DE, 1st char in A
	LD	A,(DE)
L5211H	LD	L,A
	XOR	A
	LD	H,A
L5214H	LD	B,10H
	CALL	0215H		;start cassette motor
L5219H	CALL	0235H		;read one byte from cassette
	OR	A
	JR	NZ,L5214H
	DJNZ	L5219H
	CALL	0296H		;sync cassette
	LD	B,03H
L5226H	CALL	0235H		;read one byte from cassette
	CP	0D3H
	JR	NZ,L5214H
	DJNZ	L5226H
	CALL	0235H		;read one byte from cassette
	INC	L
	DEC	L
	JR	Z,L523EH
	CP	L
	JR	Z,L523EH
	LD	(3C3EH),A
	JR	L5214H
L523EH	EX	DE,HL
	LD	HL,(40F9H)	;end of BASIC program
	DEC	HL
	DEC	HL
	JP	2C5FH		;continue in CLOAD routine

;-----	func CAPS$(str$)
;	convert str$ to upper case
CAPS	CALL	29D7H		;get addr of current string ptr into HL
	LD	BC,0FF00H
	CALL	2A68H		;build another substring
	LD	HL,(4121H)	;WRA1
	LD	A,(HL)
	OR	A
	RET	Z
	LD	B,A
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
L525CH	LD	A,(HL)
	CP	61H
	JR	C,L5268H
	CP	7BH
	JR	NC,L5268H
	SUB	20H
	LD	(HL),A
L5268H	INC	HL
	DJNZ	L525CH
	RET

;-----
PR	CALL	05D1H		;get printer status
	CP	0F0H		;(4 low bits are masked)
	RET	Z		;return if no printer connected
	JP	058DH		;jump to *PR driver

;-----
TAB255	RST	20H		;Check NTF (Num Type Flag of ACC)
	JP	M,2B05H		;jump if NTF=2 (int): return as INT
	RET

;-----	Function LOC([addr,]str) -> num
;	Locate the address of str in memory, starting from addr or 0000.
LOC	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	RST	08H		;check next char
	DEFW	'('		;TODO: DEFB ?
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	RST	20H		;Check NTF (Num Type Flag of ACC)
	LD	DE,0000H	;start from 0000 by default
	JR	Z,SL0		;jump if string
	RST	08H		;check next char
	DEFB	','
	CALL	2B05H		;conv result to INT into DE, MSB in A, Z if A==0
	PUSH	DE
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	DEFB	3EH
SL0	PUSH	DE
	RST	08H		;check next char
	DEFB	')'
	PUSH	HL
	CALL	29D7H		;get addr of current string ptr into HL
	LD	C,(HL)
	LD	A,C
	OR	A
	JP	Z,1E4AH		;?FC Error
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	POP	HL
	EX	(SP),HL
L52A3H	INC	HL
	LD	A,H
	OR	L
	JR	Z,L52B6H
	DEC	HL
	LD	B,C
	PUSH	DE
	PUSH	HL
L52ACH	LD	A,(DE)
	CP	(HL)
	JR	NZ,L52BBH
	INC	DE
	INC	HL
	DJNZ	L52ACH
	POP	HL
	POP	DE
L52B6H	CALL	0A9AH		;return INT value in HL into WRA1 (4121H)
	POP	HL
	RET

L52BBH	POP	HL
	POP	DE
	INC	HL
	JR	L52A3H

;-----	MOVE src,dest,bytes
MOVE	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	LD	B,D
	LD	C,E
	POP	DE
	EX	(SP),HL
	RST	18H		;Compare HL with DE
	JR	NC,L52E0H
	DEC	DE
	DEC	HL
	ADD	HL,BC
	EX	DE,HL
	ADD	HL,BC
	EX	DE,HL
	LDDR
	POP	HL
	RET

L52E0H	LDIR
	POP	HL
	RET

;-----	Statement STORE addr,hexstr
;	store bytes from hexstr to addr
STORE	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	EX	(SP),HL
	PUSH	HL
	CALL	29D7H		;get addr of current string ptr into HL
	LD	B,(HL)
	LD	A,B
	OR	A
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	POP	HL
	JR	Z,L5317H
	INC	B
L52FDH	CALL	L5319H
	DEC	B
	JR	Z,L5317H
	JR	C,L52FDH
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	C,A
L530AH	CALL	L5319H
	DEC	B
	JR	Z,L5317H
	JR	C,L530AH
	ADD	A,C
	LD	(HL),A
	INC	HL
	JR	L52FDH
L5317H	POP	HL
	RET

L5319H	LD	A,(DE)
	INC	DE
	SUB	30H
	RET	C
	CP	0AH
	CCF
	RET	NC
	SUB	07H
	RET	C
	CP	10H
	CCF
	RET

;-----	stmt DOKE addr,word
;	store word at address addr
DOKE	CALL	2B02H		;parse int value to DE
	PUSH	DE
	RST	08H		;check next char
	DEFB	','
	CALL	2B02H		;parse int value to DE
	EX	(SP),HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
	POP	HL
	RET

;-----	stmt CALL addr
CALL	CALL	2B02H		;parse int value to DE
	EX	DE,HL
	PUSH	DE
	CALL	0329H		;JP (HL) and return
	POP	HL
	RET

;-----	stmt RENEW
;	recover BASIC program after crash
RENEW	LD	HL,(40A4H)	;start of BASIC program
	INC	HL
	LD	(HL),H
	CALL	1AF8H		;Fix BASIC line pointers in program
	INC	HL
	JP	2C77H		;save BASIC program end addr and go to BASIC READY

;-----	func FN name(params)
;	user-defined function
FN0	CALL	DF4
FN1	LD	A,(40AFH)	;data type flag
	OR	A
	PUSH	AF
	LD	(40F3H),HL	;address of next token in code string
	EX	DE,HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	OR	H
	JR	NZ,FN2
	LD	E,2EH		;???
	JP	19A2H		;raise error

FN2	LD	A,(HL)
	CP	'('
	JR	Z,FN3
	PUSH	DE
	JR	FN10

FN3	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	LD	(40D8H),HL	;current FN pos
	JR	FN5

DF1	LD	A,(40AFH)	;data type flag
	SUB	3
	SCF
	JR	Z,FN6
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	PUSH	BC
ABS1	JP	M,DF3
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	PUSH	BC
ABS2	JP	PO,DF3		;jump if not DP
	INC	HL
	JR	C,DF2
	LD	HL,411DH	;start of WRA1 DP value
DF2	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	PUSH	BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	PUSH	BC
DF3	JR	C,FN7
DF4	RST	08H		;check next char
	DEFB	0BEH		;'FN' token
	LD	A,80H		;set high bit of variable name
	LD	(40DCH),A	;set FOR statement flag
	OR	(HL)		;get 1st char of var name with high bit set
	LD	B,A		;save to B for further processing in ROM
	JP	2612H		;parse variable name

FN4	RST	08H		;check next char
	DEFB	','
FN5	LD	C,4		;8 bytes
	CALL	1963H		;check availability of 8 bytes
	LD	A,80H		;set high bit of variable name
	LD	(40DCH),A	;set FOR statement flag
	CALL	260DH		;locate variable
	EX	DE,HL
	JR	DF1

FN6	JP	NC,2423H	;???? TODO: seems wrong, maybe 0AF6, ?TM Error
	PUSH	DE
	EX	DE,HL
	CALL	2888H		;process string
	POP	DE
	XOR	A
FN7	PUSH	HL
	PUSH	AF
	EX	DE,HL
	LD	A,(HL)
	CP	')'
	JR	NZ,FN4
	LD	HL,(40F3H)	;address of next token in code string
	RST	08H		;check next char
	DEFB	'('
	PUSH	HL
	LD	HL,(40D8H)	;current FN pos
FN8	CALL	260DH		;locate variable
	EX	(SP),HL
	CALL	1F2BH		;TODO: TBD
	LD	A,(HL)
	CP	')'
	JR	Z,FN9
	RST	08H		;check next char
	DEFB	','
	EX	(SP),HL
	RST	08H		;check next char
	DEFB	','
	JR	FN8

FN9	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	EX	(SP),HL
	RST	08H		;check next char
	DEFB	')'
FN10	RST	08H		;check next char
	DEFB	0D5H		;'=' token
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	DEC	HL
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	JP	NZ,1997H	;?SN Error
	RST	20H		;Check NTF (Num Type Flag of ACC)
	JR	Z,FN15		;Jump if NTF-3 (String)
FN11	POP	DE
FN12	POP	AF
	JR	Z,FN17
	JR	NC,FN14
	POP	HL
	POP	BC
	LD	(HL),B
	DEC	HL
	LD	(HL),C
ABS5	JP	M,FN12
	DEC	HL
	POP	BC
	LD	(HL),B
	DEC	HL
	LD	(HL),C
ABS6	JP	PO,FN12
	DEC	HL
	POP	BC
	LD	(HL),B
	DEC	HL
	LD	(HL),C
	DEC	HL
	POP	BC
	LD	(HL),B
	DEC	HL
	LD	(HL),C
	JR	FN12

FN14	PUSH	DE
	PUSH	AF
	RST	20H		;Check NTF (Num Type Flag of ACC)
	LD	DE,40D3H	;pointer to (len, address) of string
	CALL	Z,2888H		;call if string, process it
	POP	AF
	JP	281AH		;convert expr result to proper destination type

FN15	LD	HL,(40B3H)	;string work area ptr
	EX	DE,HL
	LD	HL,(4121H)	;WRA1
	RST	18H		;Compare HL with DE
	JR	C,FN16
	CALL	2843H		;move string to permanent string area ?
	JR	FN11

FN16	POP	DE
	LD	HL,40D3H	;pointer to (len, address) of string
	PUSH	HL
FN17	CALL	29F5H		;"backspace to prior literal string pool entry"
	LD	A,(HL)
	LD	(40B3H),HL	;string work area ptr
	POP	HL
	LD	(HL),A
	INC	HL
	LD	(HL),C
	INC	HL
	LD	(HL),B
	JR	FN12

;-----	stmt DEF FN name(args)=expr
;	     DEF USR n = addr
;	Define a user-defined function
DEF0	CP	0C1H		;USR token ?
	JR	Z,DEF6
ABS7	CALL	DF4
DEF1	CALL	2828H		;check for illegal direct
	EX	DE,HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
	EX	DE,HL
	LD	A,(HL)
	CP	'('
	JP	NZ,1F05H	;skip until end of statement
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
DEF2	CALL	260DH		;locate variable
	LD	A,(HL)
	CP	')'
	JP	Z,1F05H		;skip until end of statement
	RST	08H		;check next char
	DEFB	','
	JR	DEF2

;-----	func USR0(...) to USR9(...)
;	call machine-language functions
;	defined with DEFUSRn = addr
US0	POP	AF
ABS8	CALL	DEF4
DEF3	PUSH	DE
	CALL	252CH		;evaluate expression (single variable param call)
	EX	(SP),HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	LD	HL,DEFF
	PUSH	HL
	PUSH	BC
	PUSH	AF
	CP	3
	CALL	Z,29DAH		;get addr of curr value into HL
	POP	AF
	EX	DE,HL
	LD	HL,4121H	;WRA1
	RET

DEF4	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	LD	BC,0
	JR	NC,DEF5
	SUB	'0'
	RLA
	LD	C,A
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
DEF5	EX	DE,HL
	LD	HL,TBUSR
	ADD	HL,BC
	EX	DE,HL
	RET

DEF6	CALL	DEF4
DEF7	PUSH	DE
	RST	08H		;check next char
	DEFB	0D5H		;'=' token
	CALL	2B02H		;parse int value to DE
	EX	(SP),HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
DEFF	POP	HL
	RET

;-----	func INSTR([pos,]str1,str2)
;	find str2 in str1 starting from pos or beginning
INS50	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	CALL	2335H		;open '(' and evaluate expression (2+ variable params call)
	RST	20H		;get Number Type Flag (NTF)
	LD	A,1
	PUSH	AF
	JR	Z,INS51		;jump if string
	POP	AF
	CALL	2B1FH		;convert value to integer into DE
	OR	A
	JP	Z,1E4AH		;?FC Error
	PUSH	AF
	RST	08H		;check next char
	DEFB	','
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	CALL	0AF4H		;check that it's a string
INS51	RST	08H		;check next char
	DEFB	','
	PUSH	HL
	LD	HL,(4121H)	;WRA1
	EX	(SP),HL
	CALL	2337H		;evaluate expression ACC := EVAL(*HL)
	RST	08H		;check next char
	DEFB	')'
	PUSH	HL
	CALL	29D7H		;get addr of current string ptr into HL
	EX	DE,HL
	POP	BC
	POP	HL
	POP	AF
	PUSH	BC
	LD	BC,26E7H
	PUSH	BC
	LD	BC,27F8H
	PUSH	BC
	PUSH	AF
	PUSH	DE
	CALL	29DDH		;get addr of string @HL into DE
	POP	DE
	POP	AF
	LD	B,A
	DEC	A
	LD	C,A
	CP	(HL)
	LD	A,0
	RET	NC
	LD	A,(HL)
	OR	A
	RET	Z
	LD	A,(DE)
	OR	A
	LD	A,B
	RET	Z
	LD	A,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,B
	LD	B,0
	ADD	HL,BC
	SUB	C
	LD	B,A
	PUSH	BC
	PUSH	DE
	EX	(SP),HL
	LD	C,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	POP	HL
INS52	PUSH	HL
	PUSH	DE
	PUSH	BC
INS53	LD	A,(DE)
	CP	(HL)
	JR	NZ,INS56
	INC	DE
	DEC	C
	JR	Z,INS55
	INC	HL
	DEC	B
	JR	NZ,INS53
	POP	DE
	POP	DE
	POP	BC
INS54	POP	DE
	XOR	A
	RET

INS55	POP	HL
	POP	DE
	POP	DE
	POP	BC
	LD	A,B
	SUB	H
	ADD	A,C
	INC	A
	RET

INS56	POP	BC
	POP	DE
	POP	HL
	INC	L
	DEC	B
	JR	Z,INS54
	JR	INS52

TBUSR	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error
	DEFW	1E4AH		;?FC Error

;-----	expr &[H]nnnn, &Onnnnnn, &Bnnnnnnnnnnnnnnnn
;	     &[H](expr$), &O(expr$), &B(expr$)
;	define hex, octal or binary literals
;	     or convert hex, octal or binary string to value
AMPERS	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	LD	BC,102H
	CP	'B'
	JR	Z,CONT
	LD	BC,308H
	CP	'O'
	JR	Z,CONT
	LD	BC,410H
	CP	'H'
	JR	Z,CONT
	DEC	HL
CONT	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	CP	'('
	JR	NZ,NOTEXP
	PUSH	BC
	CALL	252CH		;evaluate expression (single variable param call)
	PUSH	HL
	CALL	29D7H		;get addr of current string ptr into HL
	POP	HL
	POP	BC
	PUSH	HL
	LD	HL,(4121H)	;WRA1
	LD	E,(HL)
	LD	D,0
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	EX	DE,HL
	ADD	HL,DE
	EX	DE,HL
	CALL	CONT2
	POP	HL
	RET

NOTEXP	LD	DE,0FFFFH
CONT2	DEC	HL
	PUSH	HL
	LD	HL,0
	CALL	0A9AH		;return INT value in HL into WRA1 (4121H)
	EX	(SP),HL
NXTDGT	POP	IX
	RST	10H		;skip blanks, peek next char in A, Z=0 if end of stmt, C if digit
	EX	AF,AF'
	RST	18H		;Compare HL with DE
	RET	NC
	EX	AF,AF'
	JR	C,DIGIT
	CP	41H
	RET	C
	SUB	7
DIGIT	SUB	30H
	CP	C
	RET	NC
	PUSH	IX
	EX	(SP),HL
	PUSH	BC
TIMES2	ADD	HL,HL
	JP	C,07B2H		;?OV Error (overflow)
	DJNZ	TIMES2
	LD	C,A
	ADD	HL,BC
	LD	(4121H),HL	;WRA1
	POP	BC
	EX	(SP),HL
	JR	NXTDGT

END50	NOP

	ORG	40A4H		;Start of BASIC program location
	DEFW	END50+1

	ORG	41E2H		; SYSTEM DOS exit
	;DB	0EDH,0F5H	; *BREAK*
	JP	(HL)		; vector to autoexec

	ORG	4288H		; SYSTEM sets SP to 4288H
INIT	;DB	0EDH,0F5H	; *BREAK*
	LD	A,0C9H		; clear SYSTEM "/" vector
	LD	(41E2H),A	; SYSTEM DOS exit
	LD	HL,MVERS
	CALL	2B75H		; disp null-terminated string
	CALL	1B4DH		; call NEW routine
	JP	6CCH		; BASIC READY


MVERS	DEFVERS			; define version string

	ASSERT	$ < 42E5H

	END	INIT

;=====	END OF FILE
