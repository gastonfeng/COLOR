;COLOR.ASM	������������  1-14-95
include lcd.asm
include msg.asm
include hz.asm
INCLUDE MAIN.ASM
bseg
cover		bit 0e5h	  ;:�ǰ忪��
height_lip	bit 0e3h	  ;:Һλ����
no_paper	bit 0e4h	  ;:ȱֽ����
light	bit 0e6h	  ;:�ع��
door		bit 0e7h	  ;:����
r_filter	bit 0e1h	  ;:��ɫ��ɫƬ
g_filter	bit 0e2h	  ;:��ɫ��ɫƬ
b_filter	bit 0e3h	  ;:��ɫ��ɫƬ
page_feed      bit 0e6h	 ;:��ֽ���
size_motor		bit 0e7h	  ;:���ת�����
hot_lip 	bit 0e4h	  ;:Һ�������
HOT_PAPER	bit 0e5h	  ;:ֽ�����
camer_motor	bit 0e5h	;��ͷ���
ends

Dseg	    ;:���ݵ�Ԫ��ַ����
number	data  1   ;:��ӡ�����Ĵ���
size	data 1	 ;ֽ�͹��Ĵ���
page_num	data 	1;��ֽ���ͼĴ���
photo_num	data	1;��Ƭ���ͼĴ���
h data 20	;�ַ������ַ���ֽ�
l data 21	;�ַ������ַ���ֽ�
x data 22	;�ַ���ʾҳ��ַ
y data 23	;�ַ���ʾy��ַ
midu	data 08	;�ܶȼĴ���
md_r	data 09	;���ܶȼĴ���
md_g	data 10	;��ɫ�ܶȼĴ���
md_b	data 11	;��ɫ�ܶȼĴ���
ends

xseg
rou	equ 0
rou_b	equ 0
rou_r	equ 0
rou_g	equ 0
lcd_port	equ 0a000h	;Һ����ʾ���ڵ�ַ
bri_r_address	equ 0	;
bri_g_address	equ 100h
bri_b_address	equ 200h
photo_type_R:
	db 1	;��Ƭ���ͺ����
photo_type_G:
	db 1	;��Ƭ�����̲���
photo_type_b:
	db 1	;��Ƭ����������
page_type_R:
	db 1	;��ֽ���ͺ����
page_type_G:
	db 1	;��
page_type_B:
	db 1	;��
lip_R:
	db 1	;ҩҺ���������
lip_G:
	db 1	;ҩҺ�����̲���
lip_B:
	db 1	;ҩҺ����������
RED:
	DB 1
GREEN:
	DB 1
BLUE:
	DB 1
TEMP_LIP_H	EQU 38	;ҩҺ����¶�
temp_lip_l	equ 32	;ҩҺ����¶�
temp_paper_h	equ 60	;�������¶�
temp_paper_l	equ 40	;�������¶�

	;:����ڵ�ַ����
inport	equ 0d003h	;����ڵ�ַ
OUT_A	EQU 0D001H	;����ڵ�ַ
OUT_B	EQU 0D002H	;PB����ڵ�ַ
bright		equ 0f000h     ;:�ع���A/D�ڵ�ַ
TEMP_LIP	equ 0f001h     ;:ҩҺ�¶�A/D�ڵ�ַ
TEMP_PAPER	equ 0f002h     ;:����¶�A/D�ڵ�ַ

ENDS

Cseg
org 0h
;%S
begin:
    ljmp start	    ;:���������
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
	acall	tiaoshi ;:���Գ���
	acall	lcd_begin	;:LCD��ʼ��
	acall	io_begin	;:I/O�ڳ�ʼ��
	acall	test	;: ���ò��Գ���
    acall   key_opr ;:������̴�������
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
key_door:	;:�ع�
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





lcd_begin:	;:LCD��ʼ��
	ret

io_begin:	;:I/O��ʼ��
	mov r7,#77h   ;:����ɨ�軺����
	mov r6,#0	;��ֵ������
	RET

TIAOSHI:
	RET

TEST:		;:�����Լ��ӳ���
	mov dptr,#msg1
	mov x,0
	mov y,0
	acall lcd_str
	mov dptr,#inport	;����ڵ�ַ
	movx a,@dptr
	jnb cover,no_cov
	jnb no_paper,no_pg
	jnb height_lip,no_lip
	sjmp in_ok
no_cov:		;:ǰ��δ��
	ajmp test
no_pg:		;:ȱֽ
	sjmp test
no_lip:		;:ȱ��ҩҺ
	sjmp test
in_ok:
	mov dptr,#temp_lip	;ȡҩҺ�¶�
	movx @dptr,a
	acall delay100
test_dly1:	
	jnb p3.2,test_dly1
	movx a,@dptr
	mov 21h,a	;ҩҺ�¶ȼĴ���
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

get_bri:	;:ȡ��ͨ���ӳ���
	mov dptr,#bright
	movx @dptr,a
	acall delay100
g_dly:
	jnb p3.2,g_dly
	movx a,@dptr
	ret
tiaozheng	macro color	;�ع�������������
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


F_opr:	;:���⹦�ܼ���������
	acall key_opr	;���ü��̴�������
	cjne r6,#0e7h,f_key1
	ljmp start	;��F������
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
	acall tiaoshi	;��������
f_key9:
	 cjne r6,#7dh,f_key_feed
	acall dvjc	;�Խ�����
f_key_feed:
	cjne r6,#0dfh,f_key0
	acall feed	;
f_key0:
	 cjne r6,#0beh,f_end
	acall uiji	;�Ի�
f_end:
	ljmp start


PAGE_SEL:	;:��ֽ����ѡ��
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

PHOTO_SEL:	;:��Ƭѡ��
	mov r1,#page_num
ph_start:
	acall key_opr
	cjne r6,#0ebh,ph_d
	cjne @r1,#0ah,ph_1	;����Ϊ10��
	mov photo_num,#0
ph_1:
	inc photo_num
ph_d:
	cjne r6,#0edh,ph_c
	cjne @r1,#0,ph_10	;����Ϊ1��
	mov photo_num,#0bh
ph_10:
	dec photo_num
ph_C:
	cjne r6,#0eeh,ph_e
	ljmp start
ph_E:	
	sjmp ph_start
	ret

LIP_SEL:	;:ҩҺ����
	ret

size_sel:	;:ֽ�͹��ת��
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


dvjc:	;:�Խ�����
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movX @dptr,a
d_key:
	acall key_opr
	cjne r6,#0eeh,d_key	;?�����
	movx a,@dptr
	clr door
	movX @dptr,a
	ljmp start

feed:	;:��ֽ
	acall feed_s
	mov a,size
	cjne a,#0ffh,fEED_end
	acall feed_s
fEED_end:
	ljmp start



feed_s: 	;:��ֽ
	mov dptr,#out_b
	movx a,@dptr
	setb page_feed
	movX @dptr,a
	acall delay100
	clr page_feed
	movX @dptr,a
	ret


page:	;:ҳ����������
	mov a,number
	rl a
	rl a
	rl a
	rl a
	anl a,#0f0h
	orl a,r6
	mov number,a
	ret

page_cls:	;:ҳ�����
	mov number,#1
	ret

page_up:	;;ҳ������
	mov a,number
	add a,#1
	da a
	mov number,a
	ret

page_down:	;:ҳ���ݼ�
	mov a,number
	add a,#99h
	da a
	mov number,a
	ret

key_opr:	;:���̴�������
    mov a,r7
    rl a
    mov r7,a
    orl a,#0fh	 ;:����λ��Ϊɨ���ź�
    mov p1,a
    mov a,p1
    orl a,#0f0h ;:���θ���λ
    cjne a,#0ffh,key_yes;?ɨ���źŵ͵�ƽ��Ч
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
key_nosame:	;:��ֵ����ͬ
    mov r6,b
    acall dely20
    ajmp key_opr



temp:	;:��ʱ�ж��¶ȴ����ӳ���
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



DELAY:	;:��ʱ�ӳ���100us
	mov 40h,#11h
loop:
	djnz 40h,loop
	RET

dely20: ;:��ʱ20ms
	mov 41h,#0c8h
loop20:
	 acall delay
	djnz 41h,loop20
	ret

delay100:	;:��ʱ100ms
	mov 42h,#4
lop1:
	acall dely20
	djnz 42h,lop1
	ret

delay1s:	;:��ʱ1��
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