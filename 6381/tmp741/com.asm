;������ ������ ��������� �� ���������� ��� ������ ���� .COM
TESTPC	SEGMENT
;ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	JMP	BEGIN
;������
STRING		DB	'          ', 0DH, 0AH, '$' ;16 ��������
TYPE_IBM_PC		DB	'Type IBM PC: ', '$'
;��������� ���� IBM PC
;------------------------------------------------------------------------------
	PC 	DB 'PC', 0DH, 0AH, '$'
	PC_XT	DB 'PC/XT', 0DH, 0AH, '$'
	T_AT	DB 'AT', 0DH, 0AH, '$'
	PS2_30	DB 'PS2 ������ 30', 0DH, 0AH, '$'
	PS2_50_60	DB 'PS2 ������ 50 ��� 60', 0DH, 0AH, '$'
	PS2_80	DB 'PS2 ������ 80', 0DH, 0AH, '$'
	PCJR 	DB 'PCjr', 0DH, 0AH, '$'
	PC_CONVERTIBLE	DB 'PC Convertible', 0DH, 0AH, '$'
;------------------------------------------------------------------------------

VERSION		DB	'Version:   .  ', 0DH, 0AH, '$'
OEM		DB	'OEM:      ', 0DH, 0AH, '$'
USER_SERIAL_NUMBER	DB	'User serial number:       ', 0DH, 0AH, '$'

;�������
;------------------------------------------------------------------------------
;������ �� ���������� ���� ��������� ������ � ���� (��� ������ ���������)
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
;������ �� �������� �� ����� ���� ��������� ������ (� ����� ���������)
POP_REG macro 
	pop SI
	pop DI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
endm

;���������
;------------------------------------------------------------------------------
;����� ������, ���� db, ����������� � �������, ���������� � DX
PRINT	PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT	ENDP
;------------------------------------------------------------------------------
;��������� ����� AL (��� IBM PC �� GET_TYPE_IBM_PC) � ����� �� ����� ����������
CHOOSE_AND_PRINT	PROC near
	PUSH_REG
	;������� ����������, ��� ��������� ��� IBM PC
	lea DX, TYPE_IBM_PC
	call PRINT
	;���������� AL-����
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
	cmp AL, 0F6h ;������ ����� ������ � ���������, � ���� F6, � �� FC
	je L_PS2_50_60
	cmp AL, 0F8h
	je L_PS2_80
	cmp AL, 0FDh
	je L_PCJR
	cmp AL, 0F9h
	je L_PC_CONVERTIBLE
	;������� � DX ��������������� ����
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
	
	;������� �����
L_PRINT:
	call PRINT
	POP_REG
	ret
CHOOSE_AND_PRINT	ENDP
;------------------------------------------------------------------------------!!
;�������� ������������� ���� ROM BIOS
GET_TYPE_IBM_PC	PROC near
	PUSH_REG
	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh] ;������ ���� � AL
	call CHOOSE_AND_PRINT
	POP_REG
	ret
GET_TYPE_IBM_PC	ENDP
;------------------------------------------------------------------------------!!
;���������� ������ �������, OEM � �������� �����
GET_VER_OEM_NUM PROC near
	PUSH_REG
	;�������� �-�� ��� ��������� ������
	mov AH, 30h
	int 21h
	;������� ������ �������
	;-�������� ������
	push AX
	mov SI, offset VERSION
	add	SI, 10
	call BYTE_TO_DEC
	pop AX
	;-�����������
	xchg AL, AH
	mov SI, offset VERSION
	add	SI, 12
	call BYTE_TO_DEC
	lea DX, VERSION
	call PRINT
	;������� OEM
	mov AL, BH
	mov SI, offset OEM
	add	SI, 7
	call BYTE_TO_DEC
	lea DX, OEM
	call PRINT
	;������� Serial Number
	;������ 2 �����
	mov AL, BL
	call BYTE_TO_HEX
	lea BX, USER_SERIAL_NUMBER
	mov [BX + 20], AX
	;������
	mov AL, CL
	call BYTE_TO_HEX
	mov [BX + 22], AX
	;������
	mov AL, CH
	call BYTE_TO_HEX
	mov [BX + 24], AX
	;�������
	mov DX, BX
	call PRINT
	POP_REG
	ret
GET_VER_OEM_NUM	ENDP
;------------------------------------------------------------------------------
;������� �������� ����� (4 ����) � 16-�������� ����� � AL
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
;���� � AL ����������� � ��� ������� ������������������ ����� � AX
	push	CX
	mov	AH, AL
	call	TETR_TO_HEX
	xchg	AL, AH
	mov	CL, 4
	shr	AL, CL
	call	TETR_TO_HEX	;� AL ������� �����
	pop	CX	;� AH �������
	ret
BYTE_TO_HEX	ENDP
;------------------------------------------------------------------------------
WRD_TO_HEX	PROC near
;������� � 16 �/� 16-�� ���������� �����
; � AC - �����, DI - ����� ���������� �������
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
;������� � 10 �/�, SI - ����� ���� ������� �����
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
;����
BEGIN:
; . . . . . . .
	PUSH_REG
	call GET_TYPE_IBM_PC
	call GET_VER_OEM_NUM
	POP_REG
; . . . . . . .
;����� � DOS
	xor	AL, AL
	mov	AH, 4Ch
	int	21h

TESTPC	ENDS
	END	START	;����� ������, START - ����� �����