
inport	equ 0d003h	;����ڵ�ַ
OUT_A	EQU 0D001H	;����ڵ�ַ
OUT_B	EQU 0D002H	;PB����ڵ�ַ
bright		equ 0f000h     ;:�ع���A/D�ڵ�ַ
light   bit 0e6h          ;:�ع��
door		bit 0e7h	  ;:����
r_filter	bit 0e1h	  ;:��ɫ��ɫƬ
g_filter	bit 0e2h	  ;:��ɫ��ɫƬ
b_filter	bit 0e3h	  ;:��ɫ��ɫƬ
page_feed      bit 0e6h	 ;:��ֽ���
camer_motor	bit 0e5h	;��ͷ���
Dseg	    ;:���ݵ�Ԫ��ַ����
number	data  1   ;:��ӡ�����Ĵ���
size	data 1	 ;ֽ�͹��Ĵ���
page_num	data 	1;��ֽ���ͼĴ���
photo_num	data	1;��Ƭ���ͼĴ���
midu	data 08	;�ܶȼĴ���
md_r	data 09	;���ܶȼĴ���
md_g	data 10	;��ɫ�ܶȼĴ���
md_b	data 11	;��ɫ�ܶȼĴ���
ends

rou	equ 0
rou_b	equ 0
rou_r	equ 0
rou_g	equ 0
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



UIJI:           ;:�Ի�
        acall get_bri ;ȡ�ܶ�
	mov midu,a
	mov dptr,#out_b	;����ڵ�ַ
	movx a,@dptr
	setb r_filter	;��λ�������
	movx @dptr,a
        acall get_bri
	mov md_r,a	;ȡ��ɫ�ܶ�
	mov dptr,#out_B	;����ڵ�ַ
	movx a,@dptr
	setb g_filter	;��λ�������
	movx @dptr,a
        acall get_bri
	mov md_g,a	;������ɫ�ܶ�
	mov dptr,#out_b	;����ڵ�ַ
	movx a,@dptr
	setb b_filter	;��λ�������
	movx @dptr,a
        acall get_bri
	mov md_b,a	;������ɫ�ܶ�

	ret

door_OPEN:	;:�ع�����ӳ���
	mov dptr,#out_b	;����ڵ�ַ
	movx a,@dptr
	setb r_filter	;��λ�������
	movx @dptr,a
	mov dptr,#bright	;A/D�ڵ�ַ
	movx @dptr,a	;����A/D
	acall delay
dly:
	jnb p3.2,dly
	movx a,@dptr	;ȡA/D���
	mov dptr,#bri_R_address ;������ع���
	movc a,@a+dptr
	add a,photo_type_r	;��Ƭ����
	add a,page_type_r	;��ֽ����
	add a,lip_r		;ҩҺ����
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;�򿪿���
dly1:
	acall delay100	;��ʱ
	djnz r1,dly1
	clr door	;�رտ���
	movx @dptr,a
	acall delay100
	clr r_filter	;�ر���ɫƬ
	movx @dptr,a

	mov dptr,#out_B	;����ڵ�ַ
	movx a,@dptr
	setb g_filter	;��λ�������
	movx @dptr,a
	mov dptr,#bright	;A/D�ڵ�ַ
	movx @dptr,a	;����A/D
	acall delay
dly_g:
	jnb p3.2,dly_g
	movx a,@dptr	;ȡA/D���
	mov dptr,#bri_g_address ;������ع���
	movc a,@a+dptr
	add a,photo_type_g	;��Ƭ����
	add a,page_type_g	;��ֽ����
	add a,lip_g		;ҩҺ����
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;�򿪿���
dly1_g:
	 acall delay100	;��ʱ
	djnz r1,dly1_g
	clr door	;�رտ���
	movx @dptr,a
	acall delay100
	clr g_filter	;�ر���ɫƬ
	movx @dptr,a

	mov dptr,#out_b	;����ڵ�ַ
	movx a,@dptr
	setb b_filter	;��λ�������
	movx @dptr,a
	mov dptr,#bright	;A/D�ڵ�ַ
	movx @dptr,a	;����A/D
	acall delay
dly_b:
	jnb p3.2,dly_b
	movx a,@dptr	;ȡA/D���
	mov dptr,#bri_b_address ;������ع���
	movc a,@a+dptr
	add a,photo_type_b	;��Ƭ����
	add a,page_type_b	;��ֽ����
	add a,lip_b		;ҩҺ����
	mov r1,a
	mov dptr,#out_a
	movx a,@dptr
	setb door
	movx @dptr,a	;�򿪿���
dly1_b:
	 acall delay100	;��ʱ
	djnz r1,dly1_b
	clr door	;�رտ���
	movx @dptr,a
	acall delay
	clr b_filter	;�ر���ɫƬ
	movx @dptr,a
	acall feed	;��ֽ
	ret

get_bri:	;:ȡ��ͨ���ӳ���
	mov dptr,#bright
	movx @dptr,a
	acall delay100
g_dly:
	jnb p3.2,g_dly
	movx a,@dptr
	ret

feed:	;:��ֽ
	acall feed_s
	mov a,size
	cjne a,#0ffh,fEED_end
	acall feed_s
fEED_end:
        ret


feed_s: 	;:��ֽ
	mov dptr,#out_b
	movx a,@dptr
	setb page_feed
	movX @dptr,a
	acall delay100
	clr page_feed
	movX @dptr,a
	ret

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