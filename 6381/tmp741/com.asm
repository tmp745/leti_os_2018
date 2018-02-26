;Шаблон текста программы на ассемблере дл€ модуля типа .COM
TESTPC	SEGMENT
;ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	JMP	BEGIN
;ДАННЫЕ
STRING		DB	'          ', 0DH, 0AH, '$' ;16 символов
TYPE_IBM_PC		DB	'Type IBM PC: ', '$'
;возможные типы IBM PC
;------------------------------------------------------------------------------
	PC 	DB 'PC', 0DH, 0AH, '$'
	PC_XT	DB 'PC/XT', 0DH, 0AH, '$'
	T_AT	DB 'AT', 0DH, 0AH, '$'
	PS2_30	DB 'PS2 модель 30', 0DH, 0AH, '$'
	PS2_50_60	DB 'PS2 модель 50 или 60', 0DH, 0AH, '$'
	PS2_80	DB 'PS2 модель 80', 0DH, 0AH, '$'
	PCJR 	DB 'PCjr', 0DH, 0AH, '$'
	PC_CONVERTIBLE	DB 'PC Convertible', 0DH, 0AH, '$'
;------------------------------------------------------------------------------

VERSION		DB	'Version:   .  ', 0DH, 0AH, '$'
OEM		DB	'OEM:      ', 0DH, 0AH, '$'
USER_SERIAL_NUMBER	DB	'User serial number:       ', 0DH, 0AH, '$'

;МАКРОСЫ
;------------------------------------------------------------------------------
;макрос на добавление всех регистров данных в стек (дл€ начала программы)
PUSH_REG macro 
	push AX
	push BX
	push CX
	push DX
	push ES
	push DI
	push SI
endm
;------------------------------------------------------------------------------
;макрос на изымание из стека всех регистров данных (в конце программы)
POP_REG macro 
	pop SI
	pop DI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
endm

;ПРОЦЕДУРЫ
;------------------------------------------------------------------------------
;вывод строки, типа db, объ€вленной в ДАННЫХ’, занесенной в DX
PRINT	PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT	ENDP
;------------------------------------------------------------------------------
;сравнение байта AL (тип IBM PC из GET_TYPE_IBM_PC) и вывод на экран результата
CHOOSE_AND_PRINT	PROC near
	PUSH_REG
	;выводим объ€вление, что выводитс€ тип IBM PC
	lea DX, TYPE_IBM_PC
	call PRINT
	;сравниваем AL-байт
	cmp AL, 0FFh		
    je L_PC
	cmp AL, 0FEh
	je L_PC_XT
	cmp AL, 0FBh
	je L_PC_XT
	cmp AL, 0FCh
	jz L_T_AT
	cmp AL, 0FAh
	je L_PS2_30
	cmp AL, 0F6h ;скорее всего ошибка в методичке, и надо F6, а не FC
	je L_PS2_50_60
	cmp AL, 0F8h
	je L_PS2_80
	cmp AL, 0FDh
	je L_PCJR
	cmp AL, 0F9h
	je L_PC_CONVERTIBLE
	;заносим в DX соответствующие типы
;L_OTHER:
	call BYTE_TO_HEX
	push BX
	mov BX, offset STRING
	mov [BX], AX
	pop BX
	lea DX, STRING
	jmp L_PRINT
L_PC:	
	lea DX, PC
	jmp L_PRINT
L_PC_XT:
	lea DX, PC_XT
	jmp L_PRINT
L_T_AT:
	lea DX, T_AT
	jmp L_PRINT
L_PS2_30:
	lea DX, PS2_30
	jmp L_PRINT
L_PS2_50_60:
	lea DX, PS2_50_60
	jmp L_PRINT
L_PS2_80:
	lea DX, PS2_80
	jmp L_PRINT
L_PCJR:
	lea DX, PCJR
	jmp L_PRINT
L_PC_CONVERTIBLE:
	lea DX, PC_CONVERTIBLE
	jmp L_PRINT
	
	;выводим ответ
L_PRINT:
	call PRINT
	POP_REG
	ret
CHOOSE_AND_PRINT	ENDP
;------------------------------------------------------------------------------!!
;получает предпоследний байт ROM BIOS
GET_TYPE_IBM_PC	PROC near
	PUSH_REG
	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh] ;нужный байт в AL
	call CHOOSE_AND_PRINT
	POP_REG
	ret
GET_TYPE_IBM_PC	ENDP
;------------------------------------------------------------------------------!!
;Определяет версиб системы, OEM и серийный номер
GET_VER_OEM_NUM PROC near
	PUSH_REG
	;вызываем ф-ию для получения данных
	mov AH, 30h
	int 21h
	;выводим версию системы
	;-основная версия
	push AX
	mov SI, offset VERSION
	add	SI, 10
	call BYTE_TO_DEC
	pop AX
	;-модификация
	xchg AL, AH
	mov SI, offset VERSION
	add	SI, 12
	call BYTE_TO_DEC
	lea DX, VERSION
	call PRINT
	;выводим OEM
	mov AL, BH
	mov SI, offset OEM
	add	SI, 7
	call BYTE_TO_DEC
	lea DX, OEM
	call PRINT
	;выводим Serial Number
	;первые 2 цифры
	mov AL, BL
	call BYTE_TO_HEX
	lea BX, USER_SERIAL_NUMBER
	mov [BX + 20], AX
	;вторые
	mov AL, CL
	call BYTE_TO_HEX
	mov [BX + 22], AX
	;третьи
	mov AL, CH
	call BYTE_TO_HEX
	mov [BX + 24], AX
	;вывести
	mov DX, BX
	call PRINT
	POP_REG
	ret
GET_VER_OEM_NUM	ENDP
;------------------------------------------------------------------------------
;перевод половины байта (4 бита) в 16-тиричное число в AL
TETR_TO_HEX	PROC near
;
	and	AL, 0Fh
	cmp	AL, 09
	jbe	NEXT
	add	AL, 07
NEXT:	add	AL, 30h
	ret
TETR_TO_HEX	ENDP
;------------------------------------------------------------------------------
BYTE_TO_HEX	PROC near
;байт в AL переводитс€ в два символа шестнадцатиричного числа в AX
	push	CX
	mov	AH, AL
	call	TETR_TO_HEX
	xchg	AL, AH
	mov	CL, 4
	shr	AL, CL
	call	TETR_TO_HEX	;в AL старша€ цифра
	pop	CX	;в AH младша€
	ret
BYTE_TO_HEX	ENDP
;------------------------------------------------------------------------------
WRD_TO_HEX	PROC near
;паревод в 16 с/с 16-ти разр€дного числа
; в AC - число, DI - адрес последнего символа
	push	BX
	mov	BH, AH
	call	BYTE_TO_HEX
	mov	[DI], AH
	dec	DI
	mov	[DI], AL
	dec	DI
	mov	AL, BH
	call	BYTE_TO_HEX
	mov	[DI], AH
	dec	DI
	mov	[DI], AL
	pop	BX
	ret
WRD_TO_HEX	ENDP
;------------------------------------------------------------------------------
BYTE_TO_DEC	PROC near
;перевод в 10 с/с, SI - адрес пол€ младшей цифры
	push	CX
	push	DX
	xor	AH, AH
	xor	DX, DX
	mov	CX, 10
loop_bd:	div	CX
	or	DL, 30h
	mov	[SI], DL
	dec	SI
	xor	DX, DX
	cmp	AX, 10
	jae	loop_bd
	cmp	AL, 00h
	je	end_l
	or	AL, 30h
	mov	[SI], AL
end_l:	pop	DX
	pop	CX
	ret
BYTE_TO_DEC	ENDP
;------------------------------------------------------------------------------
; код
BEGIN:
; . . . . . . .
	PUSH_REG
	call GET_TYPE_IBM_PC
	call GET_VER_OEM_NUM
	POP_REG
; . . . . . . .
;выход в DOS
	xor	AL, AL
	mov	AH, 4Ch
	int	21h

TESTPC	ENDS
	END	START	;конец модуля, START - точка входа