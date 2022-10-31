	.equ ADDR_SWITCH = $27
	.equ ADDR_RIGHT8 = $25
	.equ ADDR_LEFT8 = $24
	.equ RotLED = $26
	.equ LCD = $20
	.equ SCL = PC5
	.equ SDA = PC4
	.equ SPEAKER = PB1
	.equ RGBLIGHTS = PB4
	jmp COLDSTART
	.dseg
LEVELAT:
	.byte 1
LIFECOUNT:
	.byte 1
LEVELAMOUNT:
	.byte 100
;--------------------------------------------------------------------------------------
	.cseg
LEVELS:
	.db 9
LIVES:
	.db 3
LEVEL0:
	.db $1,$2,$4,$FF
LEVEL1:
	.db $01,$08,$20,$10,$FF
LEVEL2:
	.db $10,$04,$02,$20,$04,$FF
LEVEL3:
	.db $01,$02,$04,$20,$08,$10,$FF
LEVEL4:
	.db $08,$20,$08,$10,$02,$01,$01,$FF
LEVEL5:
	.db $04,$02,$01,$10,$20,$10,$04,$20,$FF
LEVEL6:
	.db $04,$20,$08,$01,$02,$04,$02,$01,$10,$FF
LEVEL7:
	.db $08,$10,$01,$10,$01,$20,$04,$01,$10,$02,$20,$FF
LEVEL8:
	.db $08,$10,$08,$04,$20,$02,$02,$01,$10,$20,$08,$02,$01,$FF
LEVEL9:
	.db $02,$01,$08,$04,$10,$04,$10,$02,$20,$08,$01,$10,$04,$10,$FF
FOR8SEG:
	.db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$77,$7C,$39,$5E,$79,$71,-1 //SKA VISA LEVELS
COLDSTART:
	call LIGHTOFF
	call GETLEVEL
	call GETLIFE
	call COPYLEVEL
	call SHOWNEXTLEVEL
	jmp MAIN
MAIN:
	call LEVEL
	call GETBUTTONS
	call ISTHERENEXTLEVEL
	call SHOWNEXTLEVEL
	call TESTLEVEL
	call NEXTLEVEL
	call COPY
	jmp MAIN
;--------------------------------------------------------------------------------------
COPYLEVEL:
	clr r21
	ldi ZH,HIGH(LEVEL0 << 1)
	ldi ZL,LOW(LEVEL0 << 1)
COPY:
	push r17
	ldi XH,HIGH(LEVELAMOUNT)
	ldi XL,LOW(LEVELAMOUNT)
ae:
	clr r17
	lpm r17,Z+
	cpi r17,0
	breq ae
	cpi r17,$FF
	breq ef
	st X+,r17
	inc r21
	jmp ae
ef:
	ldi r17,0
	st X,r17
	pop r17
	ldi XH,HIGH(LEVELAMOUNT)
	ldi XL,LOW(LEVELAMOUNT)
	ret
;--------------------------------------------------------------------------------------
GETLEVEL:
	ldi r16,$FC
	ldi r17,RotLED
	call TWI_WRITE
	push r17
	ldi ZH,HIGH(LEVELS << 1)
	ldi ZL,LOW(LEVELS << 1)
	lpm r17,Z
	ldi YH,HIGH(LEVELAT)
	ldi YL,LOW(LEVELAT)
	st Y,r17
	pop r17
	ret
;--------------------------------------------------------------------------------------
GETLIFE:
	push r17
	ldi ZH,HIGH(LIVES << 1)
	ldi ZL,LOW(LIVES << 1)
	lpm r17,Z
	ldi YH,HIGH(LIFECOUNT)
	ldi YL,LOW(LIFECOUNT)
	st Y,r17
	pop r17
	CALL SHOWLIFE
	ret
;--------------------------------------------------------------------------------------
NEXTLIGHT:
	ld r16,X+
	ret
;--------------------------------------------------------------------------------------
LEVEL:
	push r17
	mov r17,r21
	inc r17
aa:
	cpi r17,0
	breq ab
	call NEXTLIGHT
	CALL DELAY
	call RGBLIGHT
	dec r17
	jmp aa
ab:
	pop r17
	ret
;--------------------------------------------------------------------------------------
NEXTLEVEL:
	push r18
	inc r21
ac:
	cpi r21,0
	breq ad
	ld r18,Z+
	dec r21
	jmp ac
ad:
	pop r18
	ret
;--------------------------------------------------------------------------------------
ISTHERENEXTLEVEL:
	ldi YH,HIGH(LEVELAT)
	ldi YL,LOW(LEVELAT)
	push r17
	ld r17,Y
	cpi r17,0
	breq END
	dec r17
	st Y,r17
	pop r17
	ret
;--------------------------------------------------------------------------------------
TESTLEVEL:
	push r18
	push r17
	push r22
	clr r22
	mov r17,r21
	inc r17
	ldi XH,HIGH(LEVELAMOUNT)
	ldi XL,LOW(LEVELAMOUNT)
ag:
	st X+,r22
	cpi r17,0
	breq ah
	ld r18,-Z
	dec r17
	jmp ag
ah:
	pop r22
	pop r17
	pop r18
	ret
;--------------------------------------------------------------------------------------
END:
	ldi r23,10
orio:
	ldi r16,$21
	call fireworks
	ldi r16,$12
	call fireworks
	ldi r16,$C
	call fireworks
	ldi r16,$12
	call fireworks
	dec r23
	brne orio
	ldi r16,$00
	call fireworks
aar:
	sbi DDRB,1
	sbi PORTB,SPEAKER
	call WAIT
	cbi PORTB,SPEAKER
	cbi DDRB,1
	ldi r16,$FE
	ldi r17,RotLED
	call TWI_WRITE
	jmp aar
fireworks:
	CALL DelayT
	call RGBLIGHT
	ret
DELAYT:
	push r16
	push r25
	push r24
	ldi r16,6
DELAYT_1T:
	adiw r24,1
	brne DELAYT_1T
	dec r16
	brne DELAYT_1T
	pop r24
	pop r25
	pop r16
	ret
;--------------------------------------------------------------------------------------
SHOWNEXTLEVEL:
	ldi r16,$FC
	ldi r17,RotLED
	call TWI_WRITE
	ldi YH,HIGH(LEVELAT)
	ldi YL,LOW(LEVELAT)
	ld r16,Y
	call CONVERT
	ldi r17,ADDR_LEFT8
	call TWI_WRITE
	ret
;--------------------------------------------------------------------------------------

SHOWLIFE:
	ldi YH,HIGH(LIFECOUNT)
	ldi YL,LOW(LIFECOUNT)
	ld r16,Y
	call CONVERT
	ldi r17,ADDR_RIGHT8
	call TWI_WRITE
	ret
;--------------------------------------------------------------------------------------
LIGHTOFF:
	push r16
	ldi r16,9
	ldi r17,LCD
	pop r16
	ret
TWI_READ:
	lsl r17
	ori r17,$01
	call START
	call TWI_SEND
	call TWI_READ_BYTE
	call STOP
	ret
; nu är den adresserad börja läs 8 bitar
TWI_READ_BYTE:
	push r18
	ldi r18,8
	clr r16
	CLR R17
KEY_1:
	call SDQ ; känner av varje bit
	or r16,r17 ; samla inkommande SDA-bitar i r16
	lsl r16
	dec r18
	brne KEY_1
	call SDH
	call STOP
	lsr r16
	andi r16,$3F
	;mov r19,r16
	pop r18
	ret
SDQ:
	cbi DDRC ,SCL
	call WAIT
	in r17,PINC
	swap r17 ; ty SDA är pinne 4
	andi r17,$01 ; skilj ut just SDA-biten
	sbi DDRC ,SCL
	call WAIT
	cbi DDRC ,SCL
	call WAIT ; ge en E-hög,vänta, E-låg.Klartecken för slav att lägga ut nästa
	ret
;--------------------------------------------------------------------------------------
TWI_SEND:
	push r18
	ldi r18,8
outputloop:
	lsl r17
	brcs cdhlauncher
	brcc cdllauncher
ak:
	dec r18
	cpi r18,0
	breq endit
	jmp outputloop
endit:
	call SDH
	pop r18
	ret
cdhlauncher:
	call SDH
	jmp ak
cdllauncher:
	call SDL
	jmp ak
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
START:
	sbi DDRC ,SDA
	call WAIT
	sbi DDRC ,SCL
	call WAIT
	ret
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
STOP:
	sbi DDRC ,SDA
	call WAIT
	cbi DDRC ,SCL
	call WAIT
	cbi DDRC ,SDA
	call WAIT
	ret
;-------------------------------------------------------------------
SDL:
	sbi DDRC ,SDA
	call WAIT
	cbi DDRC ,SCL
	call WAIT
	sbi DDRC ,SCL
	call WAIT
	ret
;-------------------------------------------------------------------
SDH:
	cbi DDRC ,SDA
	call WAIT
	cbi DDRC ,SCL
	call WAIT
	sbi DDRC ,SCL
	call WAIT
	ret
;-------------------------------------------------------------------
WAIT:
	subi r24,-1
	brne WAIT
	ret
;-------------------------------------------------------------------
TWI_WRITE:
	call START
	lsl r17
	call TWI_SEND
	mov r17,r16
	call TWI_SEND
	call STOP
	ret
RGBLIGHT:
	SBI DDRB,4
	PUSH R17
	PUSH R18
	push r19
	push r20
	push r22
	push r23
	LDI R18,6
	mov r19,r16
	cpi r19,$20
	brge loc
	cpi r19,$10
	brge lox
	cpi r19,$8
	brge los
	cpi r19,$4
	brge loc
	cpi r19,$2
	brge lox
	cpi r19,$1
	brge los
loc:
	ldi r20,1 ;grön
	ldi r19,0 ;gul
	ldi r22,0 ;röd
	jmp ll
lox:
	ldi r20,0 ;grön
	ldi r19,1 ;gul
	ldi r22,0 ;röd
	jmp ll
los:
	ldi r20,0 ;grön
	ldi r19,0 ;gul
	ldi r22,1 ;röd
	jmp ll
LL:
	clr r17
	CPI R18,0
	BREQ BACK
	DEC R18
	LDI R17,24
	LSR R16
	BRCS GETCOLOR;ON
	BRCC OFF
BACK:
	pop r23
	pop r22
	pop r20
	pop r19
	POP R18
	POP R17
	CBI DDRB,4
	RET
OFF:
	CPI R17,0
	BREQ LL
	CALL ZEROARGUMENTFORRGB
	DEC R17
	JMP OFF
GETCOLOR:
	cpi r20,1
	breq green
	cpi r19,1
	breq red
	cpi r22,1
	breq blue
green:
	ldi r23,8
orgd:
	CPI R23,0
	breq orgdd
	CALL ONEARGUMENTFORRGB
	DEC R17
	breq ll
	dec r23
	brne orgd
orgdd:
	ldi r23,16
orgddd:
	CALL ZEROARGUMENTFORRGB
	DEC R17
	breq ll
	dec r23
	brne orgddd
blue:
	ldi r23,8
orgf:
	CPI R23,0
	breq orgff
	CALL ZEROARGUMENTFORRGB
	DEC R17
	breq ll
	dec r23
	brne orgf
orgff:
	ldi r23,8
orgfff:
	CALL ONEARGUMENTFORRGB
	DEC R17
	breq ll
	dec r23
	brne orgfff
	jmp blue
sosal:
	jmp ll
red:
	ldi r23,16
orgtt:
	CPI R23,0
	breq orgttt
	CALL ZEROARGUMENTFORRGB
	DEC R17
	breq sosal
	dec r23
	brne orgtt
orgttt:
	ldi r23,8
orgtttt:
	CALL ONEARGUMENTFORRGB
	DEC R17
	breq sosal
	dec r23
	brne orgtttt
	ZEROARGUMENTFORRGB:
	SBI PORTB,RGBLIGHTS

	NOP
	NOP
	NOP
	NOP
	NOP
	CBI PORTB,RGBLIGHTS
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET
	ONEARGUMENTFORRGB:
	SBI PORTB,RGBLIGHTS
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CBI PORTB,RGBLIGHTS
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET
CONVERT:
	push r19
	push r30
	push r31
	mov r19,r16
	ldi ZH,HIGH(FOR8SEG << 1)
	ldi ZL,LOW(FOR8SEG << 1)
	add ZL,r19
	lpm r16,Z
	pop r31
	pop r30
	pop r19
	ret
FORMAT:
	push r20
	mov r20,r16
	andi r20,$C0
	ror r20
	ror r20
	andi r16,$F
	add r16,r20
	pop r20
	ret
FORMATT:
	push r20
	push r23
	mov r23,r16
	mov r20,r16
	clr r16
	andi r20,$04
	ldi r22,$02
	mov r20,r23
	call zz
	andi r20,$20
	ldi r22,$05
	mov r20,r23
	call zz
	andi r20,$08
	ldi r22,$03
	mov r20,r23
	call zz
	andi r20,$1
	ldi r22,$00
	mov r20,r23
	call zz
	andi r20,$10
	ldi r22,$04
	mov r20,r23
	call zz
	andi r20,$2
	ldi r22,$01
	mov r20,r23
	call zz
	pop r23
	pop r20
	ret
zz:
	cpi r22,0
	breq ppo
	lsr r20
	dec r22
	cpi r22,0
	brne zz
ppo:
	andi r20,$01
	lsl r16
	or r16,r20
	ret
REVERTING:
	push r18
	push r19
	ldi r18,8
	mov r19,r16
si:
	lsl r19
	brcc makeone
	brcs makezero
	jmp si
makeone:
	lsl r16
	ori r16,$1
	dec r18
	cpi r18,0
	breq done
	jmp si
makezero:
	lsl r16
	dec r18
	cpi r18,0
	breq done
	jmp si
done:
	andi r16,$3F
	pop r19
	pop r18
	ret
GETBUTTONS:
	ldi r16,$FF
	ldi r17,RotLED
	call TWI_WRITE
	push r18
	ldi XH,HIGH(LEVELAMOUNT)
	ldi XL,LOW(LEVELAMOUNT)
	mov r18,r21
am:
	CALL SHOWLIFE
	cpi r18,0
	breq mm
	ldi r17,ADDR_SWITCH
	call TWI_READ
	call LRREAD
	call FORMAT
	call FORMATT
	call REVERTING
	cpi r16,$00
	breq am
	mov r23,r16
oh:
	ldi r17,ADDR_SWITCH
	call TWI_READ
	call LRREAD
	call FORMAT
	call FORMATT
	call REVERTING
	cpi r16,$00
	brne oh
	mov r16,r23
om:
	ld r17,X+
	cp r17,r16
	brne LIFELEFT
	dec r18
	clr r16
	jmp am
mm:

	pop r18
	call niceround
	ret
;--------------------------------------------------------------------------------------
niceround:
	ldi r16,$FE
	ldi r17,RotLED
	call TWI_WRITE
	call DELAY
	ldi r16,$FF
	ldi r17,RotLED
	call TWI_WRITE
	ret
;-------------------------------------------------------------------
LIFELEFT:
	ldi r16,$FD
	ldi r17,RotLED
	call TWI_WRITE
	call DELAY
	ldi r16,$FF
	ldi r17,RotLED
	call TWI_WRITE
	push r17
	ldi YH,HIGH(LIFECOUNT)
	ldi YL,LOW(LIFECOUNT)
	ld r17,Y
	cpi r17,0
	breq LOST
	dec r17
	st Y,r17
	pop r17
	ld r17,-X
	jmp am
;-------------------------------------------------------------------
LOST:
	sbi DDRB,1
	sbi PORTB,SPEAKER
	call WAIT
	call WAIT
	call WAIT
	call WAIT
	call WAIT
	cbi PORTB,SPEAKER
	cbi DDRB,1
lose:
	ldi r16,$FD
	ldi r17,RotLED
	call TWI_WRITE
	jmp LOST
DELAY:
	push r16
	push r25
	push r24
	ldi r16,40
DELAYT_1:
	adiw r24,1
	brne DELAYT_1
	dec r16
	brne DELAYT_1
	pop r24
	pop r25
	pop r16
	ret
LRREAD:
	in r20,pind
	andi r20,3
	ROR r20
	ROR r20
	ROR r20
	or r16,r20
	ret