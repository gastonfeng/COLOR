;Һ����ʾ���ַ���ʾ��������
;95-2-27


lcd_port	equ 0a000h	;Һ����ʾ���ڵ�ַ
h data 20	;�ַ������ַ���ֽ�
l data 21	;�ַ������ַ���ֽ�
x data 22	;�ַ���ʾҳ��ַ
y data 23	;�ַ���ʾy��ַ

;ȡlcd״̬�ӳ���
get_sta:
	push acc
	push dph
	push dpl
lcd_l:
        mov dptr,#0a001h        ;��LCD״̬
	movx a,@dptr
	jb 0e7h,lcd_l
	pop dpl
	pop dph
	pop acc
        ret

;name:lcd_char
;���ַ���ʾ�ӳ���
;�ӳ�����ڣ�
;h data 20	;�ַ������ַ���ֽ�
;l data 21	;�ַ������ַ���ֽ�
;x data 22	;�ַ���ʾҳ��ַ
;y data 23	;�ַ���ʾy��ַ
;ռ�üĴ�����r0,a,
lcd_char:
	push dpl
	push dph
	mov a,#0b7h
        orl a,x     ;����ҳ��ַ������
        acall get_sta
        mov dptr,#0a000h
	movx @dptr,a
	mov a,y
	cjne a,#64,lcd_c1	;y>63?
lcd_c2:		;y>=63,cs=1
	setb t1
	clr c
lcd_c1:
	jc lcd_c2
	mov a,y
	anl a,#3fh
	orl a,#40h	;����y��ַ������
        acall get_sta
	movx @dptr,a
	mov r0,#0	;�ַ�����ƫ����
get_out:
	mov a,r0
	mov dph,h	;ȡ�ַ�������ʼ��ַ
	mov dpl,l
	movc a,@a+dptr	;ȡ�ַ�����
        mov dptr,#lcd_port+2
        acall get_sta
	movx @dptr,a
	inc r0
	cjne r0,#10h,get_out
	mov a,x		;�õڶ�ҳ��ַ����ʾ�°벿�ַ�
	inc a
	anl a,#7
	orl a,0b8h
        mov dptr,#lcd_port+2
        acall get_sta
	movx @dptr,a
	mov a,y
	cjne a,#64,lcd_cc1
lcd_cc2:
	setb t1
	clr c
lcd_cc1:
	jc lcd_cc2
	mov a,y
	anl a,#3fh
	orl a,#40h
        acall get_sta
	movx @dptr,a
get_out2:
	mov a,r0
	mov dph,h
	mov dpl,l
	movc a,@a+dptr
        mov dptr,#lcd_port+2
        acall get_sta
	movx @dptr,a
	inc r0
	cjne r0,#20h,get_out2
	pop dpl
	pop dph
	ret

;name:lcd_str
;Һ����ʾ���ַ�����ʾ�ӳ���
;�������:dptr=�ַ�����ʼ��ַ��00Ϊ������־
;x data 22	;�ַ���ʾҳ��ַ
;y data 23	;�ַ���ʾy��ַ
;ռ�üĴ���:
lcd_str:
        mov a,#0
        movc a,@a+dptr    ;ȡ�����ַ���ֽ�
	cjne a,#0,lcd_s
	ret
lcd_s:
	mov h,a
	inc dpl
        mov a,#0
        movc a,@a+dptr    ;ȡ�����ַ���ֽ�
	mov l,a
	acall lcd_char
	inc dpl
	mov a,y		;��ʾ��ַ�Ƶ���һλ��
	add a,#10h
	mov y,a
	sjmp lcd_str

;name:lcd_cls
;lcd�����ӳ���	
;���:x,y=���Ͻ�ҳ��ַ,y��ַ
;     h,l=���½�ҳ��ַ,y��ַ(�������˵�ַ)
;ռ�üĴ���:a,dptr
lcd_cls:
	push y	;����y��ַ
	mov a,x
	anl a,#7
	orl a,#0b8h
	mov dptr,#lcd_port
        acall get_sta
	movx @dptr,a		;����ҳ��ַ
	mov a,y
	cjne a,#64,lcd_cl1
lcd_cl2:
	setb t1
	clr c
lcd_cl1:
	jc lcd_cl2
	mov a,y
	anl a,#3fh
	orl a,#40h
        acall get_sta
	movx @dptr,a	;����y��ַ
	inc dpl		;����lcd���ݿڵ�ַ
lcd_cls2:
	mov a,#0
        acall get_sta
	movx @dptr,a	;��lcd
	inc y
	mov a,y
	cjne a,l,lcd_cls2
	pop y
	inc x
	mov a,x
	cjne a,h,lcd_cls
	ret
