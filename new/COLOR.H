#define INVAILD 0xff
#define OK 1
#define timer 65536-9216
#define DELAY 30 /*动作延迟时间*/
#define ch_max 9 /*最大通道数*/
#define epm_delay 50

#define ON      1
#define OFF     0

#define r_light         3
#define g_light         1
#define b_light         0
#define DEV             6
#define FIX             5
#define AC              7
#define FIX_LIP         4
#define DEV_LIP         2

#define ONE 1
#define TWO 2
#define THREE 3
#define FIVE 4
#define SEVEN 0

#define ad_port ((char *)0x016000)    /*A/D口地址*/

/*液晶显示器口地址定义*/
#define lcd_set         (*(char *)0x014000)     /*液晶显示器状态输入口*/
#define lcd_data        (*(char *)0x014002)   /*液晶显示器数据输入口*/
#define lcd_state       (*(char *)0x014001)   /*液晶显示器状态口*/
#define lcd_read        (*(char *)0x014003)
#define LCD_BUSY        (lcd_state&0x90)         /*液晶显示器忙信号*/
#define lcd_off         lcd_state&0x20          /*液晶显示器关闭信号*/

/*======================*/
/*      输入口地址      */
/*======================*/
#define inporta         (*(char *)0x01c000)
#define inportb         (*(char *)0x01e000)

/*======================*/
/*      输出口地址      */
/*======================*/
#define outporta        (*(char *)0x018000)
#define outportb        (*(char *)0x01a000)

/*开关量输出地址*/
#define motor1          1     /*UP_Camer,Pa1*/
#define motor2          0      /*Down Camer,Pa0*/
#define box_m           7         /*Size,Pa3*/
#define r_m             12        /*R motor Pb5*/
#define g_m             13        /*G motor Pb7*/
#define b_m             14        /*B motor Pb6*/
#define door            15       /*door motor,Pa5*/
#define feed_m          3     /*Feed,Pa7*/
#define dev_m           4       /*Dev,pb1*/
#define fix_m           5       /*Fix,pb3*/
#define dry_m           6       /*Dry,pb2*/
#define isxi_m          2      /*CHongXi,pa2*/
#define fan             11
#define sound           8
#define filter          9
#define reset           T0
/*#define din             8             AD7715 串行数据输入     */
/*#define dout            ((inportb&4)>>2)
#define sclk            10            AD7715 串行时钟 */

/*开关量输入地址*/
#define box_open        (inportb&8)>>3
#define box_close       (inportb&1)
#define up_camer_no     ((~inporta&0x10)>>4)
#define up_camer_five   ((~inporta&0x80)>>7)
#define up_camer_seven  ((~inportb&0x2)>>1) /*充纸引带检测,0为引带*/
#define up_camer_three  ((~inporta&0x40)>>6)
#define down_camer_one  ((~inporta&0x20)>>5)
#define down_camer_no   ((~inporta&0x8)>>3)
#define down_camer_two  ((~inporta&0x4)>>2)
#define feed_pluse      (inporta&0x1)    /*走纸脉冲,0为光孔*/
#define paper           ((inporta&0x2)>>1)        /*充纸引带检测,0为引带*/

/*AD7715*/
#define READ       8
#define W       0
#define COLOR   1
#define SETUP   0x10

/*键值定义*/
#define plus_key 0x73
#define dec_key  0xe3
#define r_key 0xb3
#define g_key 0xb2
#define b_key 0xb1
#define d_key 0xb0
#define go_key 0xe2
#define uiji_key 0xe1
#define feed_key 0xd0
#define ch_key 0xd3
#define page_key 0xe0
#define size_key 0xd2
#define isxi_key  0xd1

/*加减模式定义*/
#define R 0
#define G 1
#define B 2
#define D 3
#define PAGE 4
#define CH 5
#define X 6
#define P 7


/*      错误代码        */
#define OUT_ERROR       100
#define MEM_WRITE_FAULT 200
#define AD_TIMEOUT      300
#define AD_ERROR        400
