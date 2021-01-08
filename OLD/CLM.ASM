;COLOR.ASM	彩扩机主程序  1-14-95
include lcd.asm
include msg.asm
include hz.asm
INCLUDE MAIN.ASM
bseg
cover		bit 0e5h	  ;:盖板开关
height_lip	bit 0e3h	  ;:液位开关
no_paper	bit 0e4h	  ;:缺纸开关
light	bit 0e6h	  ;:曝光灯
door		bit 0e7h	  ;:快门
r_filter	bit 0e1h	  ;:红色滤色片
g_filter	bit 0e2h	  ;:绿色滤色片
b_filter	bit 0e3h	  ;:蓝色滤色片
page_feed      bit 0e6h	 ;:走纸电机
size_motor		bit 0e7h	  ;:规格转换电机
hot_lip 	bit 0e4h	  ;:液体加热器
HOT_PAPER	bit 0e5h	  ;:纸烘干器
camer_motor	bit 0e5h	;镜头电机
ends

Dseg	    ;:数据单元地址定义
number	data  1   ;:冲印张数寄存器
size	data 1	 ;纸型规格寄存器
page_num	data 	1;相纸类型寄存器
photo_num	data	1;底片类型寄存器
h data 20	;字符点阵地址高字节
l data 21	;字符点阵地址低字节
x data 22	;字符显示页地址
y data 23	;字符显示y地址
midu	data 08	;密度寄存器
md_r	data 09	;红密度寄存器
md_g	data 10	;绿色密度寄存器
md_b	data 11	;蓝色密度寄存器
ends

xseg
rou	equ 0
rou_b	equ 0
rou_r	equ 0
rou_g	equ 0
lcd_port	equ 0a000h	;液晶显示器口地址
bri_r_address	equ 0	;
bri_g_address	equ 100h
bri_b_address	equ 200h
photo_type_R:
	db 1	;胶片类型红参数
photo_type_G:
	db 1	;胶片类型绿参数
photo_type_b:
	db 1	;胶片类型蓝参数
page_type_R:
	db 1	;相纸类型红参数
page_type_G:
	db 1	;绿
page_type_B:
	db 1	;蓝
lip_R:
	db 1	;药液补偿红参数
lip_G:
	db 1	;药液补偿绿参数
lip_B:
	db 1	;药液补偿蓝参数
RED:
	DB 1
GREEN:
	DB 1
BLUE:
	DB 1
TEMP_LIP_H	EQU 38	;药液最高温度
temp_lip_l	equ 32	;药液最低温度
temp_paper_h	equ 60	;烘干最高温度
temp_paper_l	equ 40	;烘干最低温度

	;:输入口地址定义
inport	equ 0d003h	;输入口地址
OUT_A	EQU 0D001H	;输出口地址
OUT_B	EQU 0D002H	;PB输出口地址
bright		equ 0f000h     ;:曝光量A/D口地址
TEMP_LIP	equ 0f001h     ;:药液温度A/D口地址
TEMP_PAPER	equ 0f002h     ;:烘干温度A/D口地址

ENDS

Cseg
org 0h
;%S
begin:
    ljmp start	    ;:主程序入口
org 8
	reti
org 0bh
	ljmp temp
org 13h
	reti
org 1bh
	reti
org 23h
	reti
org 2bh
	reti


org 30h
start:
	acall	tiaoshi ;:调试程序
	acall	lcd_begin	;:LCD初始化
	acall	io_begin	;:I/O口初始化
	acall	test	;: 调用测试程序
    acall   key_opr ;:进入键盘处理程序
	cjne r6,#0e7h,key_1	;?"F"
	ljmp F_opr
key_1:
	cjne r6,#0d7h,key_2	;?1
	mov r6,#1
	acall page
key_2:
	cjne r6,#0b7h,key_3	;?2
	mov r6,#2
	acall page
key_3:
	cjne r6,#77h,key_4	;?3
	mov r6,#3
	acall page
key_4:
	cjne r6,#0dbh,key_5
	mov r6,#4
	acall	page
key_5:
	cjne r6,#0bbh,key_6	;?5
	mov r6,#5
	acall page
key_6:
	cjne r6,#07bh,key_7
	mov r6,#6
	acall page
key_7:
	cjne r6,#0ddh,key_8
	mov r6,#7
	acall page
key_8:
	cjne r6,#0bdh,key_9
	mov r6,#8
	acall page
key_9:
	cjne r6,#07dh,key_0
	mov r6,#9
	acall page
key_0:
	cjne r6,#0beh,key_door
	mov r6,#0
	acall page
key_door:	;:曝光
	cjne r6,#7eh,key_cls
	acall door_OPEN
key_cls:
	cjne r6,#0eeh,key_up
	acall page_cls
key_up:
 cjne r6,#0ebh,key_down
	acall page_up
key_down:
	cjne r6,#0edh,key_feed
	acall page_down
key_feed:
	cjne r6,#0deh,key_end
	acall feed
key_end:
   ajmp    start





lcd_begin:	;:LCD初始化
	ret

io_begin:	;:I/O初始化
	mov r7,#77h   ;:键盘扫描缓冲区
	mov r6,#0	;键值缓冲区
	RET

TIAOSHI:
	RET

TEST:		;:机器自检子程序
	mov dptr,#msg1
	mov x,0
	mov y,0
	acall lcd_str
	mov dptr,#inport	;输入口地址
	movx a,@dptr
	jnb cover,no_cov
	jnb no_paper,no_pg
	jnb height_lip,no_lip
	sjmp in_ok
no_cov:		;:前盖未关
	ajmp test
no_pg:		;:缺纸
	sjmp test
no_lip:		;:缺少药液
	sjmp test
in_ok:
	mov dptr,#temp_lip	;取药液温度
	movx @dptr,a
	acall delay100
test_dly1:	
	jnb p3.2,test_dly1
	movx a,@dptr
	mov 21h,a	;药液温度寄存器
	mov dptr,#out_b
	movx a,@dptr
	setb hot_lip
	movx @dptr,a

	mov dptr,#temp_paper
	movx @dptr,a
	acall delay100
test_dly2:
	jnb p3.2,test_dly2
	movx a,@dptr
	mov 22h,a
	mov dptr,#out_b
	movx a,@dptr
	setb hot_paper
	movx @dptr,a	
	
	mov dptr,#out_a
	movx a,@dptr
	setb light
	setb door
	movx @dptr,a
	mov dptr,#bright
	movx @dptr,a
	acall delay100
test_dly3:
	jnb p3.2,test_dly3
	movx a,@dptr
	cjne a,#rou,no_bri
	sjmp rou_ok
no_bri:
	sjmp test
rou_ok:
	mov dptr,#out_a
	movx a,@dptr
	setb r_filter
	movx @dptr,a
	acall get_bri
	cjne a,#rou_r,no_r
	sjmp r_ok
no_r:
	sjmp test
r_ok:
	mov dptr,#out_a
	movx a,@dptr
	setb g_filter
	movx @dptr,a
	acall get_bri
	cjne a,#rou_g,no_g
	sjmp g_ok
no_g:
	sjmp test	
g_ok:
	mov dptr,#out_a
	movx a,@dptr
	setb b_filter
	movx @dptr,a
	acall get_bri
	cjne a,#rou_b,no_b
	sjmp b_ok
no_b:
	ajmp test	
b_ok:
	RET

get_bri:	;:取光通量子程序
	mov dptr,#bright
	movx @dptr,a
	acall delay100
g_dly:
	jnb p3.2,g_dly
	movx a,@dptr
	ret
tiaozheng	macro color	;曝光量调整宏命令
t_begin:
	acall key_opr
	cjne r6,#0e7h,up	;?"F"
	ljmp start
up:
	cjne r6,#0ebh,down
	inc color
down:
	cjne r6,#0edh,t_end
	dec color
t_end:
	ajmp t_begin
	endm


F_opr:	;:特殊功能键处理程序
	acall key_opr	;调用键盘处理程序
	cjne r6,#0e7h,f_key1
	ljmp start	;“F”返回
f_key1:
	cjne r6,#0d7h,f_key2
	tiaozheng red
f_key2:
	 cjne r6,#0b7h,f_key3
	tiaozheng green
f_key3:
	 cjne r6,#77h,f_key4
	tiaozheng blue
f_key4:
	 cjne r6,#0dbh,f_key5
	acall lip_sel
f_key5:
	 cjne r6,#0bbh,f_key6
	acall photo_sel
f_key6:
	 cjne r6,#7bh,f_key7
	acall page_sel
f_key7:
	 cjne r6,#0ddh,f_key8
	acall size_sel
f_key8:
	 cjne r6,#0bdh,f_key9
	acall tiaoshi	;整机调试
f_key9:
	 cjne r6,#7dh,f_key_feed
	acall dvjc	;对焦操作
f_key_feed:
	cjne r6,#0dfh,f_key0
	acall feed	;
f_key0:
	 cjne r6,#0beh,f_end
	acall uiji	;试机
f_end:
	ljmp start


PAGE_SEL:	;:相纸类型选择
	mov r1,#page_num
p_start:
	ACALL key_opr
	cjne r6,#0ebh,p_d
	cjne @r1,#7,p_1
	mov page_num,#0
p_1:
	inc page_num
p_d:
	cjne r6,#0edh,p_c
	cjne @r1,#0,p_7
	mov page_num,#8
p_7:
	dec page_num
p_c:
	cjne r6,#0eeh,p_e
	ljmp start
p_e:
	ajmp p_start
	ret

PHOTO_SEL:	;:底片选择
	mov r1,#page_num
ph_start:
	acall key_opr
	cjne r6,#0ebh,ph_d
	cjne @r1,#0ah,ph_1	;代号为10否
	mov photo_num,#0
ph_1:
	inc photo_num
ph_d:
	cjne r6,#0edh,ph_c
	cjne @r1,#0,ph_10	;代号为1否
	mov photo_num,#0bh
ph_10:
	dec photo_num
ph_C:
	cjne r6,#0eeh,ph_e
	ljmp start
ph_E:	
	sjmp ph_start
	ret

LIP_SEL:	;:药液补偿
	ret

size_sel:	;:纸型规格转换
	mov a,size
	cpl a
	mov size,a
	mov dptr,#out_b
	movx a,@dptr
	setb size_motor
	movx @dptr,a
	acall delay1s
	clr size_motor
	movx @dptr,a
	ret


dvjc:	;:对焦操作
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movX @dptr,a
d_key:
	acall key_opr
	cjne r6,#0eeh,d_key	;?清除键
	movx a,@dptr
	clr door
	movX @dptr,a
	ljmp start

feed:	;:走纸
	acall feed_s
	mov a,size
	cjne a,#0ffh,fEED_end
	acall feed_s
fEED_end:
	ljmp start



feed_s: 	;:走纸
	mov dptr,#out_b
	movx a,@dptr
	setb page_feed
	movX @dptr,a
	acall delay100
	clr page_feed
	movX @dptr,a
	ret


page:	;:页数处理程序
	mov a,number
	rl a
	rl a
	rl a
	rl a
	anl a,#0f0h
	orl a,r6
	mov number,a
	ret

page_cls:	;:页数清除
	mov number,#1
	ret

page_up:	;;页数递增
	mov a,number
	add a,#1
	da a
	mov number,a
	ret

page_down:	;:页数递减
	mov a,number
	add a,#99h
	da a
	mov number,a
	ret

key_opr:	;:键盘处理程序
    mov a,r7
    rl a
    mov r7,a
    orl a,#0fh	 ;:高四位作为扫描信号
    mov p1,a
    mov a,p1
    orl a,#0f0h ;:屏蔽高四位
    cjne a,#0ffh,key_yes;?扫描信号低电平有效
    mov b,#0
    ajmp key_opr
key_yes:
    anl a,#0f0h
    mov b,a
    mov a,r7
    rr a
    anl a,#0fh
    orl b,a
    mov a,b
    cjne a,r6,key_nosame
    mov r6,b
    ret
key_nosame:	;:键值不相同
    mov r6,b
    acall dely20
    ajmp key_opr



temp:	;:定时中断温度处理子程序
	push acc
	push dpl
	push dph
	mov dptr,#temp_lip
	movx @dptr,a
	acall delay
dly_l:	
	jnb p3.2,dly_l
	movx a,@dptr
	cjne a,#temp_lip_h,t_h
t_h:
	jc lip_off
	cjne a,#temp_lip_l,t_l
t_l:
	jnc lip_on
	sjmp t_paper
lip_off:
	mov dptr,#out_b
	movx a,@dptr
	setb hot_lip
	movx @dptr,a
	sjmp t_paper
lip_on:
	mov dptr,#out_b
	movx a,@dptr
	clr hot_lip
	movx @dptr,a
t_paper:
	mov dptr,#temp_paper
	movx @dptr,a
	acall delay
dly_p:	
	jnb p3.2,dly_p
	movx a,@dptr
	cjne a,#temp_paper_h,t_ph
t_ph:
	jc paper_off
	cjne a,#temp_paper_l,t_pl
t_pl:
	jnc paper_on
	sjmp t_end
paper_off:
	mov dptr,#out_b
	movx a,@dptr
	setb hot_paper
	movx @dptr,a
	sjmp t_end
paper_on:
	mov dptr,#out_b
	movx a,@dptr
	clr hot_paper
	movx @dptr,a
t_end:
	pop dph
	pop dpl
	pop acc
	reti



DELAY:	;:延时子程序100us
	mov 40h,#11h
loop:
	djnz 40h,loop
	RET

dely20: ;:延时20ms
	mov 41h,#0c8h
loop20:
	 acall delay
	djnz 41h,loop20
	ret

delay100:	;:延时100ms
	mov 42h,#4
lop1:
	acall dely20
	djnz 42h,lop1
	ret

delay1s:	;:延时1秒
	mov 43h,#0ah
loop10:
	acall delay100
	djnz 43h,loop10
	ret
	nop
;%E
ENDS
end begin
