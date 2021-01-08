;COLOR.ASM	彩扩机主程序  1-14-95
bseg
pg2             bit 0e0h        ;冲纸检测开关
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
hot_motor       bit 0e4h;烘干电机
ends

Dseg	    ;:数据单元地址定义
_dly    data 12h
dly2    data 13h
dly3    data 14h
dly4    data 15h
number  data  16h   ;:冲印张数寄存器
size    data 17h   ;纸型规格寄存器
page_num        data    18h;相纸类型寄存器
photo_num       data    19h;底片类型寄存器
h data 20H       ;字符点阵地址高字节
l data 21H       ;字符点阵地址低字节
x data 22H       ;字符显示页地址
y data 23H       ;字符显示y地址
midu    data 08H ;密度寄存器
md_r    data 0aH ;红密度寄存器
md_g    data 0cH ;绿色密度寄存器
md_b    data 0eH ;蓝色密度寄存器
buf     data 10h ;显示缓冲区
red     data 1ah
green   data 1ch
blue    data 1eh
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
TEMP_LIP_H      EQU 38*2  ;药液最高温度
temp_lip_l      equ 32*2  ;药液最低温度
temp_paper_h    equ 60*2  ;烘干最高温度
temp_paper_l    equ 40*2  ;烘干最低温度

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
        MOV SP,#40H     ;置堆栈指针
        mov page_num,#1
        mov photo_num,#1
        lcall   tiaoshi ;:调试程序
        lcall   lcd_begin       ;:LCD初始化
        mov dptr,#msg0
        mov x,#0
        mov y,#0
        lcall lcd_str
        lcall   io_begin        ;:I/O口初始化
        lcall   test    ;: 调用测试程序
dy:
        mov dptr,#out_a
        movx a,@dptr
        clr 0e1h
        movx @dptr,a
        mov x,#0
        mov y,#0
        mov l,#128
        mov h,#4
        lcall lcd_cls
        mov x,#2
        mov y,#0
        mov dptr,#msg13
        lcall lcd_str
        lcall num_dis
        lcall   key_opr ;:进入键盘处理程序
	cjne r6,#0e7h,key_1	;?"F"
        mov r6,#0
	ljmp F_opr
key_1:
	cjne r6,#0d7h,key_2	;?1
	mov r6,#1
        lcall page
key_2:
	cjne r6,#0b7h,key_3	;?2
	mov r6,#2
        lcall page
key_3:
	cjne r6,#77h,key_4	;?3
	mov r6,#3
        lcall page
key_4:
	cjne r6,#0dbh,key_5
	mov r6,#4
        lcall   page
key_5:
	cjne r6,#0bbh,key_6	;?5
	mov r6,#5
        lcall page
key_6:
	cjne r6,#07bh,key_7
	mov r6,#6
        lcall page
key_7:
	cjne r6,#0ddh,key_8
	mov r6,#7
        lcall page
key_8:
	cjne r6,#0bdh,key_9
	mov r6,#8
        lcall page
key_9:
	cjne r6,#07dh,key_0
	mov r6,#9
        lcall page
key_0:
	cjne r6,#0beh,key_door
	mov r6,#0
        lcall page
key_door:	;:曝光
	cjne r6,#7eh,key_cls
        lcall door_OPEN
key_cls:
	cjne r6,#0eeh,key_up
        lcall page_cls
key_up:
 cjne r6,#0ebh,key_down
        lcall page_up
key_down:
	cjne r6,#0edh,key_feed
        lcall page_down
key_feed:
	cjne r6,#0deh,key_end
        lcall feed
key_end:
   ajmp dy





lcd_begin:	;:LCD初始化
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#40h
        lcall lcd_cls   ;LCD清屏
        mov dptr,#0a000h
        mov x,#0
        mov y,#40h
        mov h,#4
        mov l,#80h
        lcall lcd_cls   ;LCD清屏
        mov dptr,#0a000h
        mov a,#3fh
        movx @dptr,a
        CPL T1
        movx @dptr,a
	ret

io_begin:	;:I/O初始化
	mov r7,#77h   ;:键盘扫描缓冲区
	mov r6,#0	;键值缓冲区
        mov number,#0
        mov dptr,#0d000h        ;设置8155AB口为输出,C口为输入
        mov a,#3
        movx @dptr,a
	RET

TIAOSHI:
	RET

TEST:		;:机器自检子程序
	mov dptr,#msg1
        mov x,#2
        mov y,#0
        lcall lcd_str
	mov dptr,#inport	;输入口地址
	movx a,@dptr
	jnb cover,no_cov
	jnb no_paper,no_pg
	jnb height_lip,no_lip
	sjmp in_ok
no_cov:		;:前盖未关
        mov dptr,#msg9
        mov x,#2
        mov y,#64
        lcall lcd_str
        ljmp test
no_pg:		;:缺纸
        mov dptr,#msg7
        mov x,#2
        mov y,#64
        lcall lcd_str
        ljmp test
no_lip:		;:缺少药液
        mov dptr,#msg8
        mov x,#2
        mov y,#64
        lcall lcd_str
        ljmp test
in_ok:
;        mov dptr,#out_a
;        movx a,@dptr
;        setb light
;        setb door
;        movx @dptr,a
;        mov dptr,#bright
;        movx @dptr,a
;        lcall delay100
;test_dly3:
;        jnb p3.2,test_dly3
;        movx a,@dptr
;        cjne a,#rou,no_bri
;        sjmp rou_ok
;no_bri:
;        ljmp test
;rou_ok:
;        mov dptr,#out_a
;        movx a,@dptr
;        setb r_filter
;        movx @dptr,a
;        lcall get_bri
;        cjne a,#rou_r,no_r
;        sjmp r_ok
;no_r:
;        ljmp test
;r_ok:
;        mov dptr,#out_a
;        movx a,@dptr
;        setb g_filter
;        movx @dptr,a
;        lcall get_bri
;        cjne a,#rou_g,no_g
;        sjmp g_ok
;no_g:
;        ljmp test
;g_ok:
;        mov dptr,#out_a
;        movx a,@dptr
;        setb b_filter
;        movx @dptr,a
;        lcall get_bri
;        cjne a,#rou_b,no_b
;        sjmp b_ok
;no_b:
;        ljmp test
b_ok:
        RET




;红曝光量调整子程序
r_adj:
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
        mov dptr,#msg22
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov a,red
        mov r0,#buf
        lcall binbcd
        mov r1,#buf
        mov x,#2
        mov y,#0
        lcall md_dis
        lcall key_opr
        cjne r6,#0e7h,r_up        ;?"F"
        ret
r_up:
        cjne r6,#0ebh,r_down
        inc red
r_down:
        cjne r6,#0edh,r_f
        dec red
r_f:
        cjne r6,#0deh,r_end
        mov a,red
        cpl 0e7h
        mov red,a
r_end:
        ajmp r_adj


;绿曝光量调整子程序
g_adj:
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
        mov dptr,#msg23
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov a,green
        mov r0,#buf
        lcall binbcd
        mov r1,#buf
        mov x,#2
        mov y,#0
        lcall md_dis
        lcall key_opr
        cjne r6,#0e7h,g_up        ;?"F"
        ret
g_up:
        cjne r6,#0ebh,g_down
        inc green
g_down:
        cjne r6,#0edh,g_f
        dec green
g_f:
        cjne r6,#0deh,g_end
        mov a,green
        cpl 0e7h
        mov green,a
g_end:
        ajmp g_adj

;蓝曝光量调整子程序
b_adj:
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
        mov dptr,#msg24
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov a,blue
        mov r0,#buf
        lcall binbcd
        mov r1,#buf
        mov x,#2
        mov y,#0
        lcall md_dis
        lcall key_opr
        cjne r6,#0e7h,b_up        ;?"F"
        ret
b_up:
        cjne r6,#0ebh,b_down
        inc blue
b_down:
        cjne r6,#0edh,b_f
        dec blue
b_f:
        cjne r6,#0deh,b_end
        mov a,blue
        cpl 0e7h
        mov blue,a
b_end:
        ajmp b_adj

F_opr:  ;:特殊功能键处理程序
        mov dptr,#msg14;请按功能键
        mov x,#2
        mov y,#0
        lcall lcd_str
        mov dptr,#out_a
        movx a,@dptr
        setb 0e1h
        movx @dptr,a
        lcall key_opr   ;调用键盘处理程序
	cjne r6,#0e7h,f_key1
        mov dptr,#out_a
        movx a,@dptr
        clr 0e1h
        movx @dptr,a
        ljmp dy      ;“F”返回
f_key1:
	cjne r6,#0d7h,f_key2
        lcall r_adj
f_key2:
	 cjne r6,#0b7h,f_key3
         lcall g_adj
f_key3:
	 cjne r6,#77h,f_key4
         lcall b_adj
f_key4:
	 cjne r6,#0dbh,f_key5
        lcall lip_sel
f_key5:
	 cjne r6,#0bbh,f_key6
        lcall photo_sel
f_key6:
	 cjne r6,#7bh,f_key7
        lcall page_sel
f_key7:
	 cjne r6,#0ddh,f_key8
        lcall size_sel
f_key8:
	 cjne r6,#0bdh,f_key9
        lcall tiaoshi   ;整机调试
f_key9:
	 cjne r6,#7dh,f_key_feed
        lcall dvjc      ;对焦操作
f_key_feed:
        cjne r6,#0deh,f_key0
        lcall feed      ;
f_key0:
         cjne r6,#0beh,f_clr
        lcall uiji      ;试机
f_clr:
        cjne r6,#0eeh,f_end
        lcall isvi      ;冲纸操作
f_end:
        mov dptr,#out_a
        movx a,@dptr
        clr 0e1h
        movx @dptr,a
        ljmp dy


PAGE_SEL:       ;:相纸类型选择
        mov dptr,#msg15;相纸类型选择
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov r1,#page_num
p_start:
        mov x,#2
        mov y,#0
        mov l,#128
        mov h,#4
        lcall lcd_cls
        lcall page_dis
        lcall key_opr
	cjne r6,#0ebh,p_d
        cjne @r1,#9,p_1
	mov page_num,#0
p_1:
	inc page_num
p_d:
	cjne r6,#0edh,p_c
        cjne @r1,#1,p_7
        mov page_num,#10
p_7:
	dec page_num
p_c:
        cjne r6,#0e7h,p_e
        ret
p_e:
	ajmp p_start

;象纸型号显示子程序
page_dis:
        mov a,page_num
        mov b,#14
        mul ab
        mov dptr,#type1-14
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        mov x,#2
        mov y,#0
        lcall lcd_str
        ret


;底片型号显示子程序
photo_dis:
        mov a,photo_num
        mov b,#16
        mul ab
        mov dptr,#ptype1-16
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        mov x,#2
        mov y,#0
        lcall lcd_str
        ret

PHOTO_SEL:	;:底片选择
        mov dptr,#msg16;底片类型选择
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov r1,#photo_num
ph_start:
        mov x,#2
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
        lcall photo_dis
        lcall key_opr
	cjne r6,#0ebh,ph_d
	cjne @r1,#0ah,ph_1	;代号为10否
	mov photo_num,#0
ph_1:
	inc photo_num
ph_d:
	cjne r6,#0edh,ph_c
        cjne @r1,#1,ph_10       ;代号为1否
	mov photo_num,#0bh
ph_10:
	dec photo_num
ph_C:
        cjne r6,#0e7h,ph_e
        ret
ph_E:	
	sjmp ph_start

LIP_SEL:	;:药液补偿
	ret

size_sel:	;:纸型规格转换
        mov dptr,#msg17;纸型规格转换中
        mov x,#0
        mov y,#0
        lcall lcd_str
	mov a,size
	cpl a
	mov size,a
	mov dptr,#out_b
	movx a,@dptr
	setb size_motor
	movx @dptr,a
        lcall delay1s
	clr size_motor
	movx @dptr,a
	ret


dvjc:	;:对焦操作
        mov dptr,#msg6
        mov x,#2
        mov y,#0
        lcall lcd_str
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movX @dptr,a
d_key:
        lcall key_opr
        cjne r6,#0e7h,d_key     ;?F键
	movx a,@dptr
	clr door
	movX @dptr,a
        ljmp dy

feed:	;:走纸
        mov dptr,#msg4
        mov x,#2
        mov y,#0
        lcall lcd_str
        lcall feed_s
	mov a,size
	cjne a,#0ffh,fEED_end
        lcall feed_s
fEED_end:
        ret


feed_s: 	;:走纸
	mov dptr,#out_b
	movx a,@dptr
	setb page_feed
	movX @dptr,a
        lcall delay100
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
        lcall num_dis
	ret

page_cls:	;:页数清除
	mov number,#1
        lcall num_dis
	ret

page_up:	;;页数递增
	mov a,number
	add a,#1
	da a
	mov number,a
        lcall num_dis
	ret

page_down:	;:页数递减
	mov a,number
	add a,#99h
	da a
	mov number,a
        lcall num_dis
	ret

key_opr:	;:键盘处理程序
        mov r6,#0
key_rd0:
        cjne r6,#4,key_rd
        ajmp key_opr1
key_rd:
        lcall dely20
    mov a,r7
    rl a
    mov r7,a
    inc r6
    orl a,#0fh	 ;:高四位作为扫描信号
    mov p1,a
    mov a,p1
    orl a,#0f0h ;:屏蔽高四位
    cjne a,#0ffh,key_opr       ;?扫描信号低电平有效
    ajmp key_rd0
key_opr1:
    mov a,r7
    rl a
    mov r7,a
    orl a,#0fh	 ;:高四位作为扫描信号
    mov p1,a
    mov a,p1
    orl a,#0f0h ;:屏蔽高四位
    cjne a,#0ffh,key_yes;?扫描信号低电平有效
    mov b,#0
    ajmp key_opr1
key_yes:
    anl a,#0fh
    mov b,a
    mov a,r7
    anl a,#0f0h
    orl b,a
    mov a,b
    cjne a,r6,key_nosame
    mov r6,b
    ret
key_nosame:	;:键值不相同
    mov r6,b
    lcall dely20
    ajmp key_opr1



temp:	;:定时中断温度处理子程序
	push acc
	push dpl
	push dph
	mov dptr,#temp_lip
	movx @dptr,a
        lcall delay
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
        lcall delay
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
        mov 12h,#11h
loop:
        djnz 12h,loop
	RET

dely20: ;:延时20ms
        mov 13h,#0c8h
loop20:
         lcall delay
        djnz 13h,loop20
	ret

delay100:	;:延时100ms
        mov 14h,#4
lop1:
        lcall dely20
        djnz 14h,lop1
	ret

delay1s:	;:延时1秒
        mov 15h,#0ah
loop10:
        lcall delay100
        djnz 15h,loop10
	ret
	nop

UIJI:           ;:试机
        mov dptr,#msg5
        mov x,#2
        mov y,#0
        lcall lcd_str
        lcall get_bri ;取密度
	mov midu,a
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb r_filter	;置位红输出口
	movx @dptr,a
        lcall get_bri
	mov md_r,a	;取红色密度
	mov dptr,#out_B	;输出口地址
	movx a,@dptr
	setb g_filter	;置位绿输出口
	movx @dptr,a
        lcall get_bri
	mov md_g,a	;保存绿色密度
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb b_filter	;置位蓝输出口
	movx @dptr,a
        lcall get_bri
	mov md_b,a	;保存蓝色密度

        mov x,#0
        mov y,#0
        mov l,#128
        mov h,#4
        lcall lcd_cls
        mov dptr,#msg19
        mov x,#2
        mov y,#0
        lcall lcd_str
        mov x,#2
        mov y,#40
        mov dptr,#msg20
        lcall lcd_str
        mov dptr,#msg21
        mov x,#2
        mov y,#80
        lcall lcd_str
        mov a,md_r
        mov r0,#md_r
        lcall binbcd
        mov r1,#md_r
        mov x,#2
        mov y,#17
        lcall md_dis

        mov a,md_g
        mov r0,#md_g
        lcall binbcd
        mov r1,#md_g
        mov x,#2
        mov y,#57
        lcall md_dis
        mov a,md_b
        mov r0,#md_b
        lcall binbcd
        mov r1,#md_b
        mov x,#2
        mov y,#97
        lcall md_dis
        LCALL KEY_OPR

	ret

;三位带符号BCD数显示子程序md_dis
;入口:r1=BCD数百位数地址,高四位=0为正数
;     X=页地址
;     Y=列地址
md_dis:
        mov a,@r1
        jnb 0e7h,md_dis1
        mov dptr,#a_d
        lcall lcd_asc
md_dis1:
        mov a,y
        add a,#8
        mov y,a
        mov a,@r1
        anl a,#0fh
        mov b,#8
        mul ab
        mov dptr,#a0
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        lcall lcd_asc
        inc r1
        mov a,y
        add a,#8
        mov y,a
        mov a,@r1
        anl a,#0f0h
        rl a
        rl a
        rl a
        rl a
        mov b,#8
        mul ab
        mov dptr,#a0
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        lcall lcd_asc
        mov a,y
        add a,#8
        mov y,a
        mov a,@r1
        anl a,#0fh
        mov b,#8
        mul ab
        mov dptr,#a0
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        lcall lcd_asc

        ret

;8位二进制数转换为BCD数
;入口:(A)=二进制数
;出口:(R0)=百位数地址指针
binbcd:
        mov @r0,#0
        jnb 0e7h,bin_z
        mov @r0,#0f0h
bin_z:
        clr 0e7h
        mov b,#100
        div ab
        orl a,@r0
        mov @r0,a
        inc r0
        mov a,#10
        xch a,b
        div ab
        swap a
        add a,b
        mov @r0,a
        ret


do      macro p1,p2,p3,p4,p5;r_filter,#bri_R_address,red,page_type_r,lip_r
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
        setb p1   ;置位红输出口
	movx @dptr,a
	mov dptr,#bright	;A/D口地址
	movx @dptr,a	;启动A/D
        lcall delay
dly:
	jnb p3.2,dly
	movx a,@dptr	;取A/D结果
        push acc
        mov a,photo_num
        mov b,#3
        mul ab
        mov b,#0ffh
        mul ab
        mov dptr,p2 ;查表求曝光量
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        pop acc
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        movx a,@dptr
        push acc
        mov a,p3
        jb 0e7h,d_r1
        pop b
        add a,b
        sjmp d_r2
d_r1:
        pop acc
        mov b,p3
        clr 0f7h
        subb a,b
d_r2:
        mov b,p4    ;相纸类型
        jb 0f7h,d_r3
        add a,b
        sjmp d_r4
d_r3:
        clr 0f7h
        subb a,b
d_r4:
        mov b,p5         ;药液补偿
        jb 0f7h,d_r5
        add a,b
        sjmp d_r6
d_r5:
        clr 0f7h
        subb a,b
d_r6:
        mov r1,a
        mov dptr,#out_a
        movx a,@dptr
        setb door
        movx @dptr,a    ;打开快门
dly1:
        lcall delay100  ;延时
        djnz r1,dly1
        clr door        ;关闭快门
        movx @dptr,a
        lcall delay100
        clr p1    ;关闭滤色片
        movx @dptr,a
        endm

door_OPEN:	;:曝光操作子程序
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
        mov dptr,#msg18
        mov x,#2
        mov y,#0
        lcall lcd_str
        lcall num_dis
        do r_filter,#bri_R_address,red,page_type_r,lip_r
        do g_filter,#bri_g_address,green,page_type_g,lip_g
        do b_filter,#bri_b_address,blue,page_type_b,lip_b
        lcall feed      ;走纸
        mov a,number
        add a,#99h
        da a
        mov number,a
        cjne a,#0,d_loop_b
	ret
d_loop_b:
        ljmp door_open




;液晶显示器字符显示驱动程序
;95-2-27



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
	mov a,y
        clr t1
	cjne a,#64,lcd_c1	;y>63?
lcd_c2:		;y>=63,cs=1
	setb t1
        sjmp lcd_c3
lcd_c1:
        jnc lcd_c2
lcd_c3:
        mov a,#0b8h
        orl a,x     ;计算页地址命令码
        lcall get_sta
        mov dptr,#0a000h
	movx @dptr,a
        mov a,y
	anl a,#3fh
	orl a,#40h	;计算y地址命令码
        lcall get_sta
	movx @dptr,a
	mov r0,#0	;字符点阵偏移量
get_out:
	mov a,r0
	mov dph,h	;取字符点阵起始地址
	mov dpl,l
	movc a,@a+dptr	;取字符点阵
        mov dptr,#lcd_port+2
        lcall get_sta
	movx @dptr,a
	inc r0
        cjne r0,#10h,get_out
	mov a,y
        clr t1
	cjne a,#64,lcd_cc1
lcd_cc2:
	setb t1
        sjmp lcd_cc3
lcd_cc1:
        jnc lcd_cc2
lcd_cc3:
        mov a,x
        inc a
        orl a,#0b8h     ;计算页地址命令码
        lcall get_sta
        mov dptr,#0a000h
	movx @dptr,a
	mov a,y
	anl a,#3fh
	orl a,#40h
        lcall get_sta
	movx @dptr,a
get_out2:
	mov a,r0
	mov dph,h
	mov dpl,l
	movc a,@a+dptr
        mov dptr,#lcd_port+2
        lcall get_sta
	movx @dptr,a
	inc r0
        cjne r0,#20h,get_out2
        pop dph
        pop dpl
	ret


;name:lcd_asc
;单半角字符显示子程序
;子程序入口：
;dptr=字符点阵地址
;x data 22	;字符显示页地址
;y data 23	;字符显示y地址
;占用寄存器：r0,a,
lcd_asc:
	push dpl
	push dph
	mov a,y
        clr t1
        cjne a,#64,lcd_a1       ;y>63?
lcd_a2:         ;y>=63,cs=1
	setb t1
        sjmp lcd_a3
lcd_a1:
        jnc lcd_a2
lcd_a3:
        mov a,#0b8h
        orl a,x     ;计算页地址命令码
        lcall get_sta
        mov dptr,#0a000h
	movx @dptr,a
        mov a,y
	anl a,#3fh
	orl a,#40h	;计算y地址命令码
        lcall get_sta
	movx @dptr,a
	mov r0,#0	;字符点阵偏移量
get_a:
	mov a,r0
        pop dph       ;取字符点阵起始地址
        pop dpl
        push dpl
        push dph
	movc a,@a+dptr	;取字符点阵
        mov dptr,#lcd_port+2
        lcall get_sta
	movx @dptr,a
	inc r0
        cjne r0,#8,get_a
        pop dph
        pop dpl
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
        inc dptr
        mov a,#0
        movc a,@a+dptr    ;取点阵地址低字节
	mov l,a
        lcall lcd_char
        inc dptr
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
        mov a,y
	anl a,#3fh
	orl a,#40h
        lcall get_sta
        mov dptr,#lcd_port
	movx @dptr,a	;设置y地址
lcd_cls2:
        clr t1
        mov a,y
	cjne a,#64,lcd_cl1
lcd_cl2:
	setb t1
        sjmp lcd_cl3
lcd_cl1:
        jnc lcd_cl2
lcd_cl3:
	mov a,x
	anl a,#7
	orl a,#0b8h
	mov dptr,#lcd_port
        lcall get_sta
	movx @dptr,a		;设置页地址
	mov a,#0
        lcall get_sta
        mov dptr,#lcd_port+2
	movx @dptr,a	;清lcd
	inc y
	mov a,y
	cjne a,l,lcd_cls2
	pop y
	inc x
	mov a,x
	cjne a,h,lcd_cls
        ret

num_dis:        ;:页数显示子程序
        mov a,number
        anl a,#0f0h
        rr a
        rr a
        rr a
        rr a
        mov b,#8
        mul ab
        mov dptr,#a0
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        mov x,#0
        mov y,#112
        lcall lcd_asc
        mov a,number
        anl a,#0fh
        mov b,#8
        mul ab
        mov dptr,#a0
        add a,dpl
        mov dpl,a
        mov a,b
        addc a,dph
        mov dph,a
        mov x,#0
        mov y,#120
        lcall lcd_asc
        ret




;冲纸子程序isvi
        mov x,#0
        mov y,#0
        mov h,#4
        mov l,#128
        lcall lcd_cls
isvi:
;        mov dptr,#temp_lip      ;取药液温度
;        movx @dptr,a
;        lcall delay100
;test_dly1:
;        jnb p3.2,test_dly1
;        movx a,@dptr
;        mov 21h,a       ;药液温度寄存器
        mov dptr,#out_b
	movx a,@dptr
	setb hot_lip
;        movx @dptr,a

;        mov dptr,#temp_paper
;        movx @dptr,a
;        lcall delay100
;test_dly2:
;        jnb p3.2,test_dly2
;        movx a,@dptr
;        mov 22h,a
;        mov dptr,#out_b
;        movx a,@dptr
	setb hot_paper
	movx @dptr,a	
i_loop:                 ;预热循环
        lcall temp_dis
        mov dptr,#msg25
        mov x,#0
        mov y,#0
        lcall lcd_str
        lcall get_temp_lip
        cjne a,#temp_lip_l,i_lp1
        sjmp i_lp2
i_lp1:
        jc i_loop
i_lp2:
        cjne a,#temp_lip_h,i_lp3
        sjmp i_lp4
i_lp3:
        jc i_lp5
i_lp4:
        mov dptr,#out_b
        movx a,@dptr
        clr hot_lip
        movx @dptr,a
        mov dptr,#msg28
        mov x,#0
        mov y,#0
        lcall lcd_str
        sjmp i_loop
i_lp5:
        lcall get_temp_paper
        cjne a,#temp_paper_l,i_lp6
        sjmp i_lp7
i_lp6:
        jc i_loop
i_lp7:
        cjne a,#temp_paper_h,i_lp8
        sjmp i_lp9
i_lp8:
        jc i_lp10
i_lp9:
        mov dptr,#msg27
        mov x,#0
        mov y,#0
        lcall lcd_str
        sjmp i_loop
i_lp10:
        mov dptr,#msg26
        mov x,#0
        mov y,#0
        lcall lcd_str
        mov dptr,#out_a
        movx a,@dptr
        setb hot_motor
        movx @dptr,a
        mov dptr,#inport
        movx a,@dptr
        jnb pg2,i_lp10
        ret



get_bri:	;:取光通量子程序
	mov dptr,#bright
	movx @dptr,a
        lcall delay100
g_dly:
	jnb p3.2,g_dly
	movx a,@dptr
	ret


get_temp_lip:
        mov dptr,#temp_lip
        movx @dptr,a
        lcall delay100
l_dly:
        jnb p3.2,l_dly
        movx a,@dptr
        ret

get_temp_paper:
        mov dptr,#temp_paper
        movx @dptr,a
        lcall delay100
p_dly:
        jnb p3.2,p_dly
        movx a,@dptr
        ret

;温度显示子程序temp_dis
temp_dis:
        mov dptr,#msg29
        mov x,#2
        mov y,#0
        lcall lcd_str
        lcall get_temp_lip
        rr a
        mov r0,#buf
        lcall binbcd
        mov a,buf+1
        anl a,#0fh
        mov b,#20h
        mul ab
        mov dptr,#c_0
        add a,dpl
        mov l,a
        mov a,b
        addc a,dph
        mov h,a
        mov x,#2
        mov y,#20h
        lcall lcd_char
        mov a,buf+1
        anl a,#0f0h
        swap a
        mov b,#20h
        mul ab
        mov dptr,#c_0
        add a,dpl
        mov l,a
        mov a,b
        addc a,dph
        mov h,a
        mov x,#2
        mov y,#10h
        lcall lcd_char
        lcall get_temp_paper
        rr a
        mov r0,#buf
        lcall binbcd
        mov a,buf+1
        anl a,#0fh
        mov b,#20h
        mul ab
        mov dptr,#c_0
        add a,dpl
        mov l,a
        mov a,b
        addc a,dph
        mov h,a
        mov x,#2
        mov y,#60h
        lcall lcd_char
        mov a,buf+1
        anl a,#0f0h
        swap a
        mov b,#20h
        mul ab
        mov dptr,#c_0
        add a,dpl
        mov l,a
        mov a,b
        addc a,dph
        mov h,a
        mov x,#2
        mov y,#50h
        lcall lcd_char
        ret

a_d:
        db 0,0,10h,10h,10h,10h,0,0
a_R:
        db 0, 0fEH, 12H, 32H, 52H, 8cH, 0, 0
a_E:
        db 0, 0FEH, 92H, 92H, 92H, 82H, 0, 0
a_B:
        db 0, 0FEH, 92H, 92H, 92H, 6CH, 0, 0
a_G:
        db 0, 7CH, 82H, 0A2H, 0A2H, 0E4H, 0, 0
a_Y:
        db 0, 06H, 08H, 0F0H, 08H, 06H, 0, 0
a_m:
        db 0, 0, 6CH, 6cH, 0, 0, 0, 0
a_p:
        DB 0, 80H, 60H, 10H, 04H, 02H, 0, 0
a0:
        DB 0, 7CH, 82H, 82H, 82H, 7CH, 0, 0
a1:
        DB 0, 0, 84H, 0FEH, 80H, 0, 0, 0
a2:
        DB 0, 0C4H, 0A2H, 92H, 92H, 8CH, 0, 0
a3:
        DB 0, 42H, 82H, 92H, 9AH, 66H, 0, 0
a4:
        DB 0, 30H, 28H, 24H, 0FEH, 20H, 0, 0
a5:
        DB 0, 4EH, 8AH, 8AH, 5AH, 72H, 0, 0
a6:
        DB 0, 0, 78H, 94H, 92H, 62H, 0, 0
a7:
        DB 0, 02H, 0E2H, 12H, 0AH, 06H, 0, 0
a8:
        DB 0, 6CH, 92H, 92H, 92H, 6CH, 0, 0
a9:
        DB 0, 8CH, 92H, 92H, 52H, 3CH, 0, 0


c_0:  db 000H,000H,000H,000H,0f0H,0f8H,00cH,004H,004H,004H,00cH
      db 0f8H,0f0H,000H,000H,000H,000H,000H,000H,000H,00fH
      db 01fH,030H,020H,020H,020H,030H,01fH,00fH,000H,000H,000H    ;０
c_1:  db 000H,000H,000H,000H,000H,000H,008H,0f8H,0fcH,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,020H,03fH,03fH,020H,000H,000H,000H,000H,000H,000H    ;１
c_3:  db 000H,000H,000H,000H,030H,038H,00cH,004H,004H,00cH,0f8H
      db 0f0H,000H,000H,000H,000H,000H,000H,000H,000H,020H
      db 030H,038H,02cH,026H,023H,021H,038H,000H,000H,000H,000H    ;２
c_4:  db 000H,000H,000H,000H,010H,018H,00cH,084H,084H,0ccH,078H
      db 030H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 018H,030H,020H,020H,031H,01fH,00eH,000H,000H,000H,000H    ;３
c_5:  db 000H,000H,000H,000H,080H,0c0H,070H,018H,0fcH,0feH,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,006H,007H
      db 005H,004H,024H,03fH,03fH,024H,004H,000H,000H,000H,000H    ;４
c_6:  db 000H,000H,000H,000H,0fcH,0fcH,0c4H,044H,044H,0c4H,084H
      db 004H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 018H,030H,020H,020H,030H,01fH,00fH,000H,000H,000H,000H    ;５
c_7:  db 000H,000H,000H,000H,0f0H,0f8H,08cH,044H,044H,0ccH,098H
      db 010H,000H,000H,000H,000H,000H,000H,000H,000H,00fH
      db 01fH,030H,020H,020H,030H,01fH,00fH,000H,000H,000H,000H    ;６
c_8:  db 000H,000H,000H,000H,01cH,00cH,00cH,00cH,0ccH,0ecH,03cH
      db 01cH,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,03cH,03fH,003H,000H,000H,000H,000H,000H,000H,000H    ;７
c_9:  db 000H,000H,000H,000H,030H,078H,0ccH,084H,084H,0ccH,078H
      db 030H,000H,000H,000H,000H,000H,000H,000H,000H,00eH
      db 01fH,031H,020H,020H,031H,01fH,00eH,000H,000H,000H,000H    ;８
c_10:  db 000H,000H,000H,000H,0f0H,0f8H,00cH,004H,004H,00cH,0f8H
      db 0f0H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 019H,033H,022H,022H,033H,01fH,00fH,000H,000H,000H,000H    ;９



msg0:
        dw hz1,hz2,hz3,hz4,hz5,hz6,hz7,hz8,0;ＤＹ２电脑彩扩机
MSG1:	
        dw hz9,hz10,0;自检
msg2:
        dw hz11,hz12,0;光路
msg3:
        dw hz13,hz14,0;预热
msg4:
        dw hz15,hz16,0;走纸
msg5:
        dw hz17,hz8,0;试机
msg6:
        dw hz18,hz19,0;对焦
msg7:	
        dw hz20,hz16,0;缺纸
msg8:
        dw hz21,hz22,0;缺液
msg9:
        dw hz22,hz23,hz24,hz25,0;前盖未关 
msg10:
        dw hz26,hz27,hz28,hz29,0;密度调整
msg11:
        dw hz30,hz31,hz32,hz33,0;按清除键结束
msg12:
        dw hz11,hz12,hz36,hz37,0;光路故障
msg13:
        dw hz38,hz39,hz40,0;准备好
msg14:
        dw hz41,hz30,hz42,hz43,hz33,0;请按功能键
msg15:
        dw hz44,hz16,hz45,hz46,hz47,hz48,0;相纸类型选择
msg16:
        dw hz49,hz50,hz45,hz46,hz47,hz48,0;底片类型选择
msg17:
        dw hz16,hz46,hz51,hz52,hz53,hz54,hz55,0;纸型规格转换中
msg18:
        dw hz56,hz11,0;曝光
msg19:
        dw hz57,0;红
msg20:
        dw hz58,0;绿
msg21:
        dw hz59,0;蓝
type1:
        dw hz60,hz61,hz62,hz63,0,0,0;１、富士
type2:
        dw hz3,hz61,hz64,hz65,hz66,0,0;２、柯尼卡
type3:
        dw hz67,hz61,hz68,hz69,0,0,0;３、三菱
type4:
        dw hz70,hz61,hz71,hz72,hz73,0,0;４、阿克法
type5:
        dw hz74,hz61,hz75,hz76,0,0,0;５、乐凯
type6:
        dw hz77,hz61,hz78,hz79,0,0,0;６、公元
type7:
        dw hz80,hz61,hz64,hz81,0,0,0;７、柯达
type8:
        dw hz82,hz61,hz83,hz84,hz85,hz86,0;８、用户定义
type9:
        dw hz87,hz61,hz83,hz84,hz85,hz86,0;９、用户定义

ptype1:
        dw hz60,hz61,hz62,hz63,0,0,0,0;１、富士
ptype2:
        dw hz3,hz61,hz64,hz65,hz66,0,0,0;２、柯尼卡
ptype3:
        dw hz67,hz61,hz68,hz69,0,0,0,0;３、三菱
ptype4:
        dw hz70,hz61,hz71,hz72,hz73,0,0,0;４、阿克法
ptype5:
        dw hz74,hz61,hz75,hz76,0,0,0,0;５、乐凯
ptype6:
        dw hz77,hz61,hz78,hz79,0,0,0,0;６、公元
ptype7:
        dw hz80,hz61,hz64,hz81,0,0,0,0;７、柯达
ptype8:
        dw hz82,hz61,hz62,hz81,0,0,0,0;８、富达
ptype9:
        dw hz87,hz61,hz83,hz84,hz85,hz86,0,0;９、用户定义
ptype10:
        dw hz60,hz88,hz61,hz83,hz84,hz85,hz86,0;１０、用户定义
msg22:
        dw hz57,hz89,hz56,hz11,hz90,hz28,hz29,0;红色曝光量调整
msg23:
        dw hz58,hz89,hz56,hz11,hz90,hz28,hz29,0;绿色曝光量调整
msg24:
        dw hz59,hz89,hz56,hz11,hz90,hz28,hz29,0;蓝色曝光量调整
msg25:
        dw hz91,hz16,hz8,hz92,hz13,hz14,0;冲纸机构预热
msg26:
        dw hz93,hz94,hz95,hz96,hz91,hz16,0;正在进行冲纸
msg27:
        dw hz97,hz98,hz99,hz27,hz100,hz101,0;烘干温度过高
msg28:
        dw hz102,hz21,hz99,hz27,hz100,hz101,0;药液温度过高
msg29:
        dw hz103,hz104,hz104,hz105,hz106,hz104,hz104,hz105,0;ⅰⅲⅲ℃¤℃

      

HZ1:  db 000H,000H,000H,004H,0fcH,0fcH,004H,004H,004H,00cH,008H
      db 018H,0f0H,0e0H,000H,000H,000H,000H,000H,020H,03fH
      db 03fH,020H,020H,020H,030H,010H,018H,00fH,007H,000H,000H    ;Ｄ
HZ2:  db 000H,004H,00cH,01cH,03cH,074H,0e0H,0c0H,080H,0c0H,060H
      db 034H,01cH,00cH,004H,000H,000H,000H,000H,000H,000H
      db 000H,020H,03fH,03fH,020H,000H,000H,000H,000H,000H,000H    ;Ｙ
HZ3:  db 000H,000H,000H,000H,030H,038H,00cH,004H,004H,00cH,0f8H
      db 0f0H,000H,000H,000H,000H,000H,000H,000H,000H,020H
      db 030H,038H,02cH,026H,023H,021H,038H,000H,000H,000H,000H    ;２
HZ4:  db 000H,0f8H,048H,048H,048H,048H,0ffH,048H,048H,048H,048H
      db 0fcH,008H,000H,000H,000H,000H,007H,002H,002H,002H
      db 002H,03fH,042H,042H,042H,042H,047H,040H,070H,000H,000H    ;电
HZ5:  db 000H,0feH,022H,022H,0ffH,00aH,0e8H,048H,089H,00aH,088H
      db 068H,008H,0ecH,008H,000H,080H,07fH,002H,082H,0ffH
      db 000H,0ffH,048H,045H,042H,045H,048H,058H,0ffH,000H,000H    ;脑
HZ6:  db 084H,08cH,0b4H,084H,0daH,082H,092H,08dH,020H,010H,008H
      db 084H,046H,060H,000H,000H,020H,010H,008H,006H,0ffH
      db 002H,004H,00cH,080H,042H,021H,010H,008H,00cH,000H,000H    ;彩
HZ7:  db 010H,010H,010H,0ffH,090H,050H,0f8H,008H,008H,009H,00eH
      db 008H,008H,00cH,008H,000H,002H,042H,081H,07fH,080H
      db 060H,01fH,000H,000H,000H,000H,000H,000H,000H,000H,000H    ;扩
HZ8:  db 010H,010H,0d0H,0ffH,090H,010H,000H,0fcH,004H,004H,004H
      db 0feH,004H,000H,000H,000H,004H,003H,000H,0ffH,080H
      db 041H,020H,01fH,000H,000H,000H,03fH,040H,040H,070H,000H    ;机
HZ9:  db 000H,000H,000H,0f8H,048H,04cH,04aH,049H,048H,048H,048H
      db 0fcH,008H,000H,000H,000H,000H,000H,000H,0ffH,044H
      db 044H,044H,044H,044H,044H,044H,0ffH,000H,000H,000H,000H    ;自
HZ10:  db 010H,010H,0d0H,0ffH,010H,050H,020H,050H,04cH,043H,04cH
      db 050H,020H,060H,020H,000H,004H,003H,000H,0ffH,041H
      db 042H,042H,05cH,040H,05fH,040H,050H,04eH,064H,040H,000H    ;检
HZ11:  db 040H,040H,042H,044H,058H,0c0H,040H,07fH,040H,0c0H,050H
      db 048H,046H,064H,040H,000H,000H,080H,040H,020H,018H
      db 007H,000H,000H,000H,03fH,040H,040H,040H,040H,070H,000H    ;光
HZ12:  db 000H,0feH,042H,0c2H,042H,07fH,012H,008H,08cH,057H,024H
      db 054H,08cH,084H,080H,000H,040H,07eH,040H,03fH,022H
      db 022H,001H,0ffH,042H,042H,042H,042H,042H,0ffH,002H,000H    ;路
HZ13:  db 040H,042H,052H,0e2H,05aH,0c6H,040H,0f2H,012H,01aH,0d6H
      db 012H,012H,0fbH,012H,000H,000H,040H,080H,07fH,000H
      db 000H,080H,09fH,040H,020H,01fH,020H,020H,05fH,080H,000H    ;预
HZ14:  db 000H,088H,088H,048H,0ffH,048H,028H,008H,048H,0ffH,008H
      db 008H,0fcH,008H,000H,000H,080H,060H,004H,008H,027H
      db 0c0H,008H,004H,023H,0c0H,001H,000H,027H,048H,0c6H,000H    ;热
HZ15:  db 040H,040H,048H,048H,048H,048H,048H,0ffH,048H,048H,048H
      db 04cH,048H,060H,040H,000H,000H,080H,040H,020H,01fH
      db 020H,040H,07fH,044H,044H,044H,046H,044H,060H,020H,000H    ;走
HZ16:  db 020H,030H,0acH,063H,020H,010H,0fcH,084H,084H,084H,0feH
      db 082H,0c2H,082H,000H,000H,022H,063H,022H,012H,012H
      db 012H,0ffH,040H,020H,000H,00fH,030H,040H,080H,0e0H,000H    ;纸
HZ17:  db 040H,042H,0ccH,000H,010H,090H,090H,090H,090H,090H,0ffH
      db 010H,012H,014H,010H,000H,000H,000H,07fH,020H,010H
      db 020H,060H,03fH,010H,010H,001H,03eH,040H,080H,070H,000H    ;试
HZ18:  db 008H,048H,088H,008H,0c8H,038H,010H,090H,010H,010H,010H
      db 0ffH,010H,018H,010H,000H,020H,010H,00cH,003H,004H
      db 018H,000H,000H,003H,040H,080H,07fH,000H,000H,000H,000H    ;对
HZ19:  db 080H,040H,020H,0f8H,027H,024H,024H,025H,0feH,024H,024H
      db 0b4H,026H,004H,000H,000H,000H,080H,060H,01fH,009H
      db 029H,049H,009H,02fH,049H,009H,029H,049H,0ccH,008H,000H    ;焦
HZ20:  db 0a0H,090H,08fH,0f8H,088H,0ccH,088H,010H,010H,0ffH,010H
      db 010H,0f8H,010H,000H,000H,000H,07eH,020H,03fH,020H
      db 0feH,041H,021H,019H,007H,019H,021H,041H,0c1H,041H,000H    ;缺
HZ21:  db 010H,022H,064H,00cH,080H,004H,0c4H,034H,005H,0c6H,0bcH
      db 024H,024H,0e6H,004H,000H,004H,004H,0feH,001H,002H
      db 001H,0ffH,042H,021H,016H,008H,015H,023H,060H,020H,000H    ;液
HZ22:  db 008H,008H,0e8H,029H,02aH,02eH,0e8H,008H,008H,0ccH,00aH
      db 00bH,0e8H,00cH,008H,000H,000H,000H,0ffH,009H,049H
      db 089H,07fH,000H,000H,00fH,040H,080H,07fH,000H,000H,000H    ;前
HZ23:  db 000H,004H,024H,024H,025H,026H,024H,0fcH,024H,026H,025H
      db 034H,0a6H,004H,000H,000H,040H,041H,07dH,045H,045H
      db 07dH,045H,045H,045H,07dH,045H,045H,07dH,041H,040H,000H    ;盖
HZ24:  db 080H,088H,088H,088H,088H,088H,088H,0ffH,088H,088H,088H
      db 088H,08cH,0c8H,080H,000H,000H,020H,010H,008H,004H
      db 002H,001H,0ffH,001H,002H,004H,008H,010H,030H,010H,000H    ;未
HZ25:  db 000H,010H,010H,011H,012H,01cH,010H,0f0H,010H,018H,014H
      db 013H,01aH,090H,000H,000H,081H,081H,041H,041H,021H
      db 011H,00dH,003H,00dH,011H,021H,021H,041H,0c1H,041H,000H    ;关
HZ26:  db 010H,04cH,024H,004H,0f4H,084H,04dH,056H,024H,024H,014H
      db 084H,024H,054H,00cH,000H,000H,001H,0fdH,041H,040H
      db 041H,041H,07fH,041H,041H,041H,041H,0fcH,000H,000H,000H    ;密
HZ27:  db 000H,000H,0fcH,024H,024H,024H,0fcH,0a5H,0a6H,0a4H,0fcH
      db 024H,034H,026H,004H,000H,040H,020H,09fH,080H,042H
      db 042H,026H,02aH,012H,02aH,026H,042H,040H,0c0H,040H,000H    ;度
HZ28:  db 020H,021H,0e6H,000H,000H,0feH,082H,092H,092H,0feH,092H
      db 0d2H,082H,0ffH,002H,000H,000H,000H,03fH,090H,048H
      db 03fH,000H,03eH,012H,012H,012H,05eH,080H,07fH,000H,000H    ;调
HZ29:  db 000H,03aH,0aaH,06aH,0ffH,06aH,0aaH,03aH,008H,0b7H,044H
      db 0a4H,01cH,006H,004H,000H,041H,041H,042H,042H,07bH
      db 042H,042H,07eH,04bH,04aH,04aH,04aH,043H,061H,041H,000H    ;整
HZ30:  db 010H,010H,090H,0ffH,090H,0a0H,098H,088H,088H,0e9H,08aH
      db 088H,088H,0a8H,098H,000H,001H,041H,080H,07fH,000H
      db 000H,080H,084H,04bH,030H,010H,028H,047H,0c0H,000H,000H    ;按
HZ31:  db 010H,022H,064H,00cH,0c0H,044H,054H,054H,054H,07fH,054H
      db 054H,0d6H,044H,040H,000H,004H,004H,0feH,001H,000H
      db 000H,0ffH,015H,015H,015H,055H,095H,07fH,001H,000H,000H    ;清
HZ32:  db 000H,0feH,022H,05aH,086H,040H,020H,050H,04cH,0c3H,04cH
      db 050H,020H,060H,020H,000H,000H,0ffH,004H,008H,007H
      db 022H,012H,04aH,082H,07fH,002H,00bH,012H,032H,000H,000H    ;除
HZ33:  db 010H,028H,0e7H,024H,024H,0c2H,0b2H,08eH,010H,054H,054H
      db 0ffH,054H,07cH,010H,000H,001H,001H,07fH,021H,051H
      db 024H,018H,027H,048H,089H,089H,0ffH,089H,0cdH,048H,000H    ;键
HZ34:  db 000H,030H,028H,0a4H,063H,010H,008H,048H,048H,048H,07fH
      db 048H,048H,04cH,008H,000H,000H,022H,063H,022H,012H
      db 012H,000H,0feH,042H,042H,042H,042H,042H,0ffH,002H,000H    ;结
HZ35:  db 004H,004H,0e4H,024H,024H,024H,024H,0ffH,024H,024H,024H
      db 024H,0f4H,026H,004H,000H,040H,040H,027H,022H,012H
      db 00aH,006H,0ffH,006H,00aH,012H,012H,027H,060H,020H,000H    ;束
HZ36:  db 010H,010H,010H,0ffH,010H,018H,050H,020H,0d0H,01fH,010H
      db 010H,0f0H,018H,010H,000H,000H,07fH,021H,021H,021H
      db 07fH,080H,080H,043H,024H,018H,024H,043H,0c0H,040H,000H    ;故
HZ37:  db 000H,0feH,022H,05aH,086H,010H,0d2H,056H,05aH,053H,05aH
      db 056H,0f2H,058H,010H,000H,000H,0ffH,004H,008H,017H
      db 010H,017H,015H,015H,0fdH,015H,015H,017H,010H,010H,000H    ;障
HZ38:  db 000H,002H,004H,0ecH,040H,020H,0f8H,04fH,048H,049H,0feH
      db 048H,068H,04cH,008H,000H,002H,002H,07fH,000H,000H
      db 000H,0ffH,022H,022H,022H,03fH,022H,023H,032H,020H,000H    ;准
HZ39:  db 000H,000H,090H,088H,044H,04bH,032H,012H,032H,04aH,046H
      db 082H,080H,080H,080H,000H,001H,001H,000H,0ffH,049H
      db 049H,049H,07fH,049H,049H,049H,0ffH,000H,001H,000H,000H    ;备
HZ40:  db 010H,010H,0f0H,01fH,010H,0f0H,080H,082H,082H,082H,0e2H
      db 092H,08aH,0c6H,080H,000H,040H,022H,015H,008H,014H
      db 063H,000H,000H,040H,080H,07fH,000H,000H,000H,000H,000H    ;好
HZ41:  db 020H,022H,0ecH,000H,020H,022H,0aaH,0aaH,0aaH,0bfH,0aaH
      db 0aaH,0ebH,0a2H,020H,000H,000H,000H,07fH,020H,010H
      db 000H,0ffH,00aH,00aH,00aH,04aH,08aH,07fH,000H,000H,000H    ;请
HZ42:  db 008H,008H,008H,0f8H,00cH,028H,020H,020H,0ffH,020H,020H
      db 020H,020H,0f0H,020H,000H,008H,018H,008H,00fH,084H
      db 044H,020H,01cH,003H,020H,040H,080H,040H,03fH,000H,000H    ;功
HZ43:  db 010H,0d8H,054H,053H,050H,0dcH,030H,000H,07fH,090H,088H
      db 084H,086H,0e0H,000H,000H,000H,0ffH,009H,049H,089H
      db 07fH,000H,000H,07eH,090H,088H,084H,086H,080H,0e0H,000H    ;能
HZ44:  db 010H,010H,0d0H,0ffH,090H,010H,000H,0feH,022H,022H,022H
      db 022H,022H,0ffH,002H,000H,004H,003H,000H,0ffH,000H
      db 001H,000H,0ffH,042H,042H,042H,042H,042H,0ffH,000H,000H    ;相
HZ45:  db 000H,010H,010H,012H,094H,050H,010H,0ffH,010H,050H,094H
      db 092H,018H,010H,000H,000H,004H,084H,084H,045H,024H
      db 014H,00cH,007H,00cH,014H,024H,045H,0c4H,046H,004H,000H    ;类
HZ46:  db 020H,022H,022H,0feH,022H,022H,0feH,023H,022H,000H,0fcH
      db 000H,000H,0ffH,000H,000H,040H,04cH,04aH,049H,048H
      db 048H,04bH,07eH,048H,048H,048H,04aH,04cH,06bH,040H,000H    ;型
HZ47:  db 040H,042H,044H,0ccH,000H,060H,05eH,048H,0c8H,07fH,0c8H
      db 048H,04cH,068H,040H,000H,000H,040H,020H,01fH,020H
      db 060H,090H,08cH,083H,080H,08fH,090H,090H,0d0H,05cH,000H    ;选
HZ48:  db 010H,010H,010H,0ffH,090H,050H,082H,046H,02aH,092H,02aH
      db 046H,082H,080H,080H,000H,002H,042H,081H,07fH,000H
      db 009H,008H,009H,009H,0ffH,009H,009H,00cH,009H,000H,000H    ;择
HZ49:  db 000H,000H,0fcH,004H,0e4H,024H,025H,026H,0e4H,014H,014H
      db 014H,084H,006H,004H,000H,040H,030H,00fH,000H,07fH
      db 021H,011H,021H,067H,019H,021H,041H,081H,0e1H,000H,000H    ;底
HZ50:  db 000H,000H,0feH,020H,020H,020H,020H,020H,03fH,020H,020H
      db 020H,020H,030H,020H,000H,080H,040H,03fH,001H,001H
      db 001H,001H,001H,001H,0ffH,000H,000H,000H,000H,000H,000H    ;片
HZ51:  db 080H,090H,090H,0ffH,090H,0d0H,080H,0fcH,004H,084H,07cH
      db 004H,0feH,004H,000H,000H,040H,020H,018H,007H,008H
      db 090H,040H,023H,018H,007H,000H,078H,083H,080H,0e0H,000H    ;规
HZ52:  db 010H,010H,0d0H,0ffH,050H,0b0H,018H,017H,0a4H,044H,0a4H
      db 014H,00cH,000H,000H,000H,004H,003H,000H,0ffH,008H
      db 004H,0feH,045H,044H,044H,044H,045H,0feH,006H,002H,000H    ;格
HZ53:  db 008H,0c8H,0b8H,08fH,0e8H,088H,040H,048H,0c8H,07fH,048H
      db 048H,04cH,068H,040H,000H,008H,018H,008H,004H,0ffH
      db 004H,000H,002H,013H,022H,062H,09aH,006H,002H,000H,000H    ;转
HZ54:  db 010H,010H,010H,0ffH,090H,090H,0e8H,024H,027H,0f4H,02cH
      db 024H,0f0H,020H,000H,000H,002H,042H,081H,07fH,084H
      db 084H,047H,024H,014H,00fH,014H,024H,047H,0c4H,044H,000H    ;换
HZ55:  db 000H,0f8H,008H,008H,008H,008H,008H,0ffH,008H,008H,008H
      db 008H,008H,0fcH,008H,000H,000H,003H,001H,001H,001H
      db 001H,001H,0ffH,001H,001H,001H,001H,001H,003H,000H,000H    ;中
HZ56:  db 000H,0fcH,044H,044H,0feH,004H,05fH,0f5H,055H,055H,055H
      db 0f5H,05fH,000H,000H,000H,000H,01fH,008H,008H,01fH
      db 009H,045H,02bH,091H,0fdH,011H,02bH,065H,009H,009H,000H    ;曝
HZ57:  db 020H,030H,0acH,063H,020H,010H,004H,004H,004H,004H,0fcH
      db 004H,006H,004H,000H,000H,022H,067H,022H,012H,012H
      db 052H,040H,040H,040H,040H,07fH,040H,040H,060H,040H,000H    ;红
HZ58:  db 020H,030H,0acH,063H,020H,030H,0a2H,02aH,02aH,0eaH,02aH
      db 02aH,03fH,0a2H,020H,000H,022H,063H,022H,012H,012H
      db 020H,010H,04bH,084H,07fH,004H,00aH,031H,061H,020H,000H    ;绿
HZ59:  db 004H,004H,0e4H,004H,00fH,0f4H,084H,044H,034H,0a4H,02fH
      db 034H,024H,006H,004H,000H,040H,040H,07dH,044H,044H
      db 07fH,044H,044H,044H,07cH,045H,044H,07eH,044H,040H,000H    ;蓝
HZ60:  db 000H,000H,000H,000H,000H,000H,008H,0f8H,0fcH,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,020H,03fH,03fH,020H,000H,000H,000H,000H,000H,000H    ;１
HZ61:  db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,004H,00cH,018H
      db 038H,038H,030H,000H,000H,000H,000H,000H,000H,000H,000H    ;、
HZ62:  db 010H,00cH,004H,0d4H,054H,054H,055H,056H,054H,054H,05cH
      db 0d4H,004H,014H,00cH,000H,000H,000H,0fcH,055H,055H
      db 055H,055H,07dH,055H,055H,055H,055H,0feH,004H,000H,000H    ;富
HZ63:  db 040H,040H,040H,040H,040H,040H,040H,0ffH,040H,040H,040H
      db 040H,040H,060H,040H,000H,000H,000H,040H,040H,040H
      db 040H,040H,07fH,040H,040H,040H,060H,040H,000H,000H,000H    ;士
HZ64:  db 010H,010H,0d0H,0ffH,050H,094H,004H,0e4H,024H,024H,0e4H
      db 004H,0fcH,006H,004H,000H,004H,003H,000H,0ffH,000H
      db 000H,000H,01fH,008H,008H,05fH,080H,07fH,000H,000H,000H    ;柯
HZ65:  db 000H,000H,0feH,022H,022H,0e2H,022H,022H,022H,022H,022H
      db 0a2H,03fH,002H,000H,000H,080H,060H,01fH,000H,000H
      db 03fH,044H,044H,042H,042H,041H,041H,040H,040H,070H,000H    ;尼
HZ66:  db 040H,040H,040H,040H,040H,040H,0ffH,044H,044H,044H,046H
      db 044H,040H,060H,040H,000H,000H,000H,000H,000H,000H
      db 000H,0ffH,000H,002H,004H,00cH,018H,000H,000H,000H,000H    ;卡
HZ67:  db 000H,000H,000H,000H,010H,018H,00cH,084H,084H,0ccH,078H
      db 030H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 018H,030H,020H,020H,031H,01fH,00eH,000H,000H,000H,000H    ;３
HZ68:  db 000H,004H,084H,084H,084H,084H,084H,084H,084H,084H,084H
      db 0c4H,086H,004H,000H,000H,020H,020H,020H,020H,020H
      db 020H,020H,020H,020H,020H,020H,020H,020H,030H,020H,000H    ;三
HZ69:  db 042H,042H,052H,052H,0d7H,052H,052H,07eH,052H,052H,0d7H
      db 052H,052H,043H,042H,000H,000H,080H,084H,092H,049H
      db 04cH,053H,022H,022H,052H,04eH,041H,083H,080H,080H,000H    ;菱
HZ70:  db 000H,000H,000H,000H,080H,0c0H,070H,018H,0fcH,0feH,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,006H,007H
      db 005H,004H,024H,03fH,03fH,024H,004H,000H,000H,000H,000H    ;４
HZ71:  db 000H,0feH,002H,022H,0daH,006H,002H,0e2H,022H,022H,0f2H
      db 022H,0feH,003H,002H,000H,000H,0ffH,008H,010H,008H
      db 007H,000H,01fH,008H,008H,05fH,080H,07fH,000H,000H,000H    ;阿
HZ72:  db 004H,004H,004H,0e4H,024H,024H,024H,03fH,024H,024H,024H
      db 0f4H,024H,006H,004H,000H,000H,080H,080H,047H,022H
      db 01eH,002H,002H,002H,07eH,082H,087H,080H,080H,0e0H,000H    ;克
HZ73:  db 010H,022H,064H,00cH,080H,010H,010H,010H,010H,0ffH,010H
      db 010H,018H,090H,000H,000H,004H,004H,0feH,001H,000H
      db 041H,061H,051H,049H,047H,041H,051H,061H,0c1H,001H,000H    ;法
HZ74:  db 000H,000H,000H,000H,0fcH,0fcH,0c4H,044H,044H,0c4H,084H
      db 004H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 018H,030H,020H,020H,030H,01fH,00fH,000H,000H,000H,000H    ;５
HZ75:  db 000H,080H,0c0H,0bcH,084H,084H,084H,0f4H,082H,082H,083H
      db 082H,080H,0c0H,080H,000H,000H,040H,020H,010H,00cH
      db 040H,080H,07fH,000H,000H,004H,008H,030H,060H,000H,000H    ;乐
HZ76:  db 040H,05eH,050H,050H,05fH,050H,0f0H,05eH,000H,0feH,002H
      db 002H,0ffH,002H,000H,000H,000H,07eH,042H,022H,022H
      db 012H,097H,040H,030H,00fH,000H,000H,03fH,040H,070H,000H    ;凯
HZ77:  db 000H,000H,000H,000H,0f0H,0f8H,08cH,044H,044H,0ccH,098H
      db 010H,000H,000H,000H,000H,000H,000H,000H,000H,00fH
      db 01fH,030H,020H,020H,030H,01fH,00fH,000H,000H,000H,000H    ;６
HZ78:  db 000H,000H,080H,040H,030H,00cH,000H,0c0H,006H,018H,020H
      db 040H,080H,080H,080H,000H,001H,001H,000H,030H,028H
      db 024H,023H,020H,020H,028H,030H,060H,000H,001H,000H,000H    ;公
HZ79:  db 020H,020H,022H,022H,022H,0e2H,022H,022H,022H,0e2H,022H
      db 023H,022H,030H,020H,000H,080H,080H,040H,020H,018H
      db 007H,000H,000H,000H,03fH,040H,040H,040H,040H,070H,000H    ;元
HZ80:  db 000H,000H,000H,000H,01cH,00cH,00cH,00cH,0ccH,0ecH,03cH
      db 01cH,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,03cH,03fH,003H,000H,000H,000H,000H,000H,000H,000H    ;７
HZ81:  db 040H,042H,0ccH,000H,020H,020H,020H,0a0H,07fH,020H,020H
      db 020H,030H,020H,000H,000H,040H,020H,01fH,020H,050H
      db 048H,046H,041H,040H,041H,042H,04cH,058H,060H,020H,000H    ;达
HZ82:  db 000H,000H,000H,000H,030H,078H,0ccH,084H,084H,0ccH,078H
      db 030H,000H,000H,000H,000H,000H,000H,000H,000H,00eH
      db 01fH,031H,020H,020H,031H,01fH,00eH,000H,000H,000H,000H    ;８
HZ83:  db 000H,000H,0feH,022H,022H,022H,022H,0feH,022H,022H,022H
      db 022H,0ffH,002H,000H,000H,080H,060H,01fH,002H,002H
      db 002H,002H,07fH,002H,002H,042H,082H,07fH,000H,000H,000H    ;用
HZ84:  db 000H,000H,0f8H,088H,088H,088H,088H,089H,08eH,088H,088H
      db 088H,088H,0fcH,008H,000H,080H,060H,01fH,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,001H,000H,000H    ;户
HZ85:  db 010H,00cH,004H,024H,024H,024H,025H,0e6H,024H,024H,034H
      db 024H,004H,014H,00cH,000H,080H,040H,020H,01fH,020H
      db 040H,040H,07fH,042H,042H,043H,042H,040H,060H,020H,000H    ;定
HZ86:  db 000H,000H,00cH,030H,0c0H,000H,002H,00cH,000H,080H,060H
      db 018H,006H,000H,000H,000H,000H,080H,080H,040H,020H
      db 011H,00aH,004H,00aH,011H,010H,020H,060H,0c0H,040H,000H    ;义
HZ87:  db 000H,000H,000H,000H,0f0H,0f8H,00cH,004H,004H,00cH,0f8H
      db 0f0H,000H,000H,000H,000H,000H,000H,000H,000H,008H
      db 019H,033H,022H,022H,033H,01fH,00fH,000H,000H,000H,000H    ;９
HZ88:  db 000H,000H,000H,000H,0f0H,0f8H,00cH,004H,004H,004H,00cH
      db 0f8H,0f0H,000H,000H,000H,000H,000H,000H,000H,00fH
      db 01fH,030H,020H,020H,020H,030H,01fH,00fH,000H,000H,000H    ;０
HZ89:  db 000H,080H,040H,020H,0f8H,027H,024H,024H,0e4H,034H,02cH
      db 024H,0f0H,020H,000H,000H,000H,000H,000H,000H,03fH
      db 042H,042H,042H,043H,042H,042H,042H,047H,040H,070H,000H    ;色
HZ90:  db 020H,020H,020H,0beH,0aaH,0aaH,0aaH,0aaH,0aaH,0aaH,0aaH
      db 0bfH,022H,030H,020H,000H,000H,080H,080H,0afH,0aaH
      db 0aaH,0aaH,0ffH,0aaH,0aaH,0aaH,0afH,080H,080H,000H,000H    ;量
HZ91:  db 000H,002H,00cH,0e0H,000H,0f0H,010H,010H,010H,0ffH,010H
      db 010H,010H,0f8H,010H,000H,002H,002H,0ffH,000H,000H
      db 007H,002H,002H,002H,0ffH,002H,002H,002H,007H,000H,000H    ;冲
HZ92:  db 010H,010H,0d0H,0ffH,090H,010H,020H,010H,00fH,0c8H,008H
      db 008H,008H,0fcH,008H,000H,000H,003H,000H,0ffH,000H
      db 001H,000H,00cH,00bH,008H,04aH,09cH,040H,03fH,000H,000H    ;构
HZ93:  db 000H,002H,002H,0c2H,002H,002H,002H,0feH,082H,082H,082H
      db 0c2H,083H,002H,000H,000H,040H,040H,040H,07fH,040H
      db 040H,040H,07fH,040H,040H,040H,040H,040H,060H,040H,000H    ;正
HZ94:  db 008H,008H,008H,008H,0c8H,038H,00fH,008H,008H,0e8H,008H
      db 088H,008H,00cH,008H,000H,008H,004H,002H,0ffH,000H
      db 040H,041H,041H,041H,07fH,041H,041H,041H,060H,040H,000H    ;在
HZ95:  db 040H,042H,0ccH,000H,008H,008H,0ffH,008H,008H,008H,0ffH
      db 008H,08cH,008H,000H,000H,040H,020H,01fH,020H,041H
      db 051H,04fH,041H,041H,041H,07fH,041H,041H,061H,020H,000H    ;进
HZ96:  db 000H,010H,088H,0c4H,023H,040H,042H,042H,042H,042H,042H
      db 0c2H,043H,062H,040H,000H,002H,001H,000H,0ffH,000H
      db 000H,000H,000H,000H,040H,080H,07fH,000H,000H,000H,000H    ;行
HZ97:  db 080H,070H,000H,0ffH,020H,010H,010H,010H,0ffH,010H,010H
      db 0ffH,010H,010H,000H,000H,040H,020H,018H,007H,008H
      db 034H,084H,044H,037H,004H,004H,017H,064H,0c6H,004H,000H    ;烘
HZ98:  db 080H,080H,082H,082H,082H,082H,082H,0feH,082H,082H,082H
      db 083H,082H,0c0H,080H,000H,000H,000H,000H,000H,000H
      db 000H,000H,0ffH,000H,000H,000H,000H,000H,000H,000H,000H    ;干
HZ99:  db 010H,022H,064H,00cH,080H,000H,0feH,092H,092H,092H,092H
      db 092H,0ffH,002H,000H,000H,004H,004H,0feH,001H,040H
      db 07eH,042H,042H,07eH,042H,07eH,042H,042H,07eH,040H,000H    ;温
HZ100:  db 040H,042H,044H,0c8H,000H,008H,008H,048H,088H,008H,008H
      db 0ffH,008H,008H,000H,000H,000H,040H,020H,01fH,020H
      db 040H,040H,040H,041H,048H,050H,04fH,040H,060H,020H,000H    ;过
HZ101:  db 004H,004H,004H,0f4H,094H,094H,095H,096H,094H,094H,094H
      db 0f4H,004H,006H,004H,000H,000H,0feH,002H,002H,07aH
      db 04aH,04aH,04aH,04aH,04aH,07aH,002H,082H,0ffH,002H,000H    ;高
HZ102:  db 004H,084H,0c4H,0a4H,094H,08fH,044H,004H,084H,07fH,044H
      db 044H,044H,0e6H,044H,000H,000H,024H,064H,026H,015H
      db 014H,014H,001H,000H,002H,04cH,080H,040H,03fH,000H,000H    ;药
HZ103:  db 000H,0feH,008H,008H,008H,008H,008H,008H,008H,008H,008H
      db 008H,008H,008H,0feH,000H,000H,00fH,010H,020H,020H
      db 020H,020H,020H,020H,020H,020H,020H,020H,010H,00fH,000H    ;ⅰ
HZ104:  db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
      db 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H    ;ⅲ
HZ105:  db 000H,006H,009H,009H,0e6H,0f0H,018H,008H,008H,008H,018H
      db 030H,078H,000H,000H,000H,000H,000H,000H,000H,007H
      db 00fH,018H,030H,020H,020H,020H,010H,008H,000H,000H,000H    ;℃
HZ106:  db 000H,000H,084H,068H,010H,008H,008H,004H,004H,004H,008H
      db 008H,010H,068H,084H,000H,000H,000H,043H,02cH,010H
      db 020H,020H,040H,040H,040H,020H,020H,010H,02cH,043H,000H    ;¤



;%E
ENDS
end begin
