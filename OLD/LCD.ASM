;液晶显示器字符显示驱动程序
;95-2-27


lcd_port	equ 0a000h	;液晶显示器口地址
h data 20	;字符点阵地址高字节
l data 21	;字符点阵地址低字节
x data 22	;字符显示页地址
y data 23	;字符显示y地址

;取lcd状态子程序
get_sta:
	push acc
	push dph
	push dpl
lcd_l:
        mov dptr,#0a001h        ;读LCD状态
	movx a,@dptr
	jb 0e7h,lcd_l
	pop dpl
	pop dph
	pop acc
        ret

;name:lcd_char
;单字符显示子程序
;子程序入口：
;h data 20	;字符点阵地址高字节
;l data 21	;字符点阵地址低字节
;x data 22	;字符显示页地址
;y data 23	;字符显示y地址
;占用寄存器：r0,a,
lcd_char:
	push dpl
	push dph
	mov a,#0b7h
        orl a,x     ;计算页地址命令码
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
	orl a,#40h	;计算y地址命令码
        acall get_sta
	movx @dptr,a
	mov r0,#0	;字符点阵偏移量
get_out:
	mov a,r0
	mov dph,h	;取字符点阵起始地址
	mov dpl,l
	movc a,@a+dptr	;取字符点阵
        mov dptr,#lcd_port+2
        acall get_sta
	movx @dptr,a
	inc r0
	cjne r0,#10h,get_out
	mov a,x		;置第二页地址，显示下半部字符
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
;液晶显示器字符串显示子程序
;程序入口:dptr=字符串起始地址，00为结束标志
;x data 22	;字符显示页地址
;y data 23	;字符显示y地址
;占用寄存器:
lcd_str:
        mov a,#0
        movc a,@a+dptr    ;取点阵地址高字节
	cjne a,#0,lcd_s
	ret
lcd_s:
	mov h,a
	inc dpl
        mov a,#0
        movc a,@a+dptr    ;取点阵地址低字节
	mov l,a
	acall lcd_char
	inc dpl
	mov a,y		;显示地址移到下一位置
	add a,#10h
	mov y,a
	sjmp lcd_str

;name:lcd_cls
;lcd清屏子程序	
;入口:x,y=左上角页地址,y地址
;     h,l=右下角页地址,y地址(不包括此地址)
;占用寄存器:a,dptr
lcd_cls:
	push y	;保存y地址
	mov a,x
	anl a,#7
	orl a,#0b8h
	mov dptr,#lcd_port
        acall get_sta
	movx @dptr,a		;设置页地址
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
	movx @dptr,a	;设置y地址
	inc dpl		;设置lcd数据口地址
lcd_cls2:
	mov a,#0
        acall get_sta
	movx @dptr,a	;清lcd
	inc y
	mov a,y
	cjne a,l,lcd_cls2
	pop y
	inc x
	mov a,x
	cjne a,h,lcd_cls
	ret
