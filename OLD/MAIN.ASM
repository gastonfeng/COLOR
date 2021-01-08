
inport	equ 0d003h	;输入口地址
OUT_A	EQU 0D001H	;输出口地址
OUT_B	EQU 0D002H	;PB输出口地址
bright		equ 0f000h     ;:曝光量A/D口地址
light   bit 0e6h          ;:曝光灯
door		bit 0e7h	  ;:快门
r_filter	bit 0e1h	  ;:红色滤色片
g_filter	bit 0e2h	  ;:绿色滤色片
b_filter	bit 0e3h	  ;:蓝色滤色片
page_feed      bit 0e6h	 ;:走纸电机
camer_motor	bit 0e5h	;镜头电机
Dseg	    ;:数据单元地址定义
number	data  1   ;:冲印张数寄存器
size	data 1	 ;纸型规格寄存器
page_num	data 	1;相纸类型寄存器
photo_num	data	1;底片类型寄存器
midu	data 08	;密度寄存器
md_r	data 09	;红密度寄存器
md_g	data 10	;绿色密度寄存器
md_b	data 11	;蓝色密度寄存器
ends

rou	equ 0
rou_b	equ 0
rou_r	equ 0
rou_g	equ 0
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



UIJI:           ;:试机
        acall get_bri ;取密度
	mov midu,a
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb r_filter	;置位红输出口
	movx @dptr,a
        acall get_bri
	mov md_r,a	;取红色密度
	mov dptr,#out_B	;输出口地址
	movx a,@dptr
	setb g_filter	;置位绿输出口
	movx @dptr,a
        acall get_bri
	mov md_g,a	;保存绿色密度
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb b_filter	;置位蓝输出口
	movx @dptr,a
        acall get_bri
	mov md_b,a	;保存蓝色密度

	ret

door_OPEN:	;:曝光操作子程序
	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb r_filter	;置位红输出口
	movx @dptr,a
	mov dptr,#bright	;A/D口地址
	movx @dptr,a	;启动A/D
	acall delay
dly:
	jnb p3.2,dly
	movx a,@dptr	;取A/D结果
	mov dptr,#bri_R_address ;查表求曝光量
	movc a,@a+dptr
	add a,photo_type_r	;底片类型
	add a,page_type_r	;相纸类型
	add a,lip_r		;药液补偿
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;打开快门
dly1:
	acall delay100	;延时
	djnz r1,dly1
	clr door	;关闭快门
	movx @dptr,a
	acall delay100
	clr r_filter	;关闭滤色片
	movx @dptr,a

	mov dptr,#out_B	;输出口地址
	movx a,@dptr
	setb g_filter	;置位绿输出口
	movx @dptr,a
	mov dptr,#bright	;A/D口地址
	movx @dptr,a	;启动A/D
	acall delay
dly_g:
	jnb p3.2,dly_g
	movx a,@dptr	;取A/D结果
	mov dptr,#bri_g_address ;查表求曝光量
	movc a,@a+dptr
	add a,photo_type_g	;底片类型
	add a,page_type_g	;相纸类型
	add a,lip_g		;药液补偿
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;打开快门
dly1_g:
	 acall delay100	;延时
	djnz r1,dly1_g
	clr door	;关闭快门
	movx @dptr,a
	acall delay100
	clr g_filter	;关闭滤色片
	movx @dptr,a

	mov dptr,#out_b	;输出口地址
	movx a,@dptr
	setb b_filter	;置位蓝输出口
	movx @dptr,a
	mov dptr,#bright	;A/D口地址
	movx @dptr,a	;启动A/D
	acall delay
dly_b:
	jnb p3.2,dly_b
	movx a,@dptr	;取A/D结果
	mov dptr,#bri_b_address ;查表求曝光量
	movc a,@a+dptr
	add a,photo_type_b	;底片类型
	add a,page_type_b	;相纸类型
	add a,lip_b		;药液补偿
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;打开快门
dly1_b:
	 acall delay100	;延时
	djnz r1,dly1_b
	clr door	;关闭快门
	movx @dptr,a
	acall delay
	clr b_filter	;关闭滤色片
	movx @dptr,a
	acall feed	;走纸
	ret

get_bri:	;:取光通量子程序
	mov dptr,#bright
	movx @dptr,a
	acall delay100
g_dly:
	jnb p3.2,g_dly
	movx a,@dptr
	ret

feed:	;:走纸
	acall feed_s
	mov a,size
	cjne a,#0ffh,fEED_end
	acall feed_s
fEED_end:
        ret


feed_s: 	;:走纸
	mov dptr,#out_b
	movx a,@dptr
	setb page_feed
	movX @dptr,a
	acall delay100
	clr page_feed
	movX @dptr,a
	ret

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
