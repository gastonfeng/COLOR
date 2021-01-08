/*==============================*/
/*  傻瓜彩扩机电脑板程序        */
/*  冯建涛                      */
/*  1996.4.22                   */
/*------------------------------*/
/*  1997.6更改电路,程序改变     */
/*  原理图:SECCPU.SCH           */
/*==============================*/
/*  1997.10增加AD7715专用测光   */
/*==============================*/

#include <io51.h>
#include <ascii.h>
#include <hz.h>
#include <hz.c>
#include <msg.c>
#include <color.h>
#include <math.h>
#include <stdarg.h>

#define DELAY_SCALE 115     /*  延时子程序时间常数  */
#define FILTER_TIMES 10     /*  数字滤波缓冲区单元数    */
#define PRE_HOT_TIME    6000

/*数据寄存器定义*/
char x,y;                                   /*  显示坐标    */
char outa,outb;

#pragma memory=xdata
unsigned char page,MODE,time_ad,point_number;  /*曝光张数,加减模式*/
unsigned int r_time,g_time,b_time;   /*红.绿.蓝曝光时间,计时时钟*/
unsigned int time;
unsigned char r_scale,g_scale,b_scale,d_scale;   /*红.绿.蓝.密度手工补偿系数*/
unsigned char dev_temp,fix_temp,ac;
char AD;                                        /*AD7715通讯寄存器内容  */
bit AD_use,ISXI,ISXI_GO,ISXI_OK;                    /*冲洗,补偿操作标志*/
bit ad_BUSY=0xb3;
bit useable,ad_error;
char point;
char ad_count;
unsigned int result;
unsigned int white,red,green,blue;
unsigned int buffer[FILTER_TIMES];
unsigned long sum;
unsigned long white_const2,red_const2,green_const2,blue_const2;
unsigned int white_base,red_base,green_base,blue_base;
unsigned int r_delay,g_delay,b_delay;
unsigned int senr,seng,senb,fr,fb,fg;
#pragma memory=default

#pragma memory=no_init
char flag1;
char workmode;                              /*  校色方式    */
char useable_flag;
char auto_hot;
unsigned int white_const,red_const,green_const,blue_const;
unsigned char ch;                           /*通道号*/
unsigned char DEV_temp,FIX_temp,DRY_temp;
unsigned char size;                         /*镜头.片框位置:0-1";1-5";2-7"*/
unsigned char sum_h,sum_l;                  /*总张数累计*/
char white_agfa,red_agfa,green_agfa,blue_agfa;
char stability;      /*  AD稳定性判断因子的倒数  */
unsigned int mid_r,mid_g,mid_b,mid_w;             /*红,绿,蓝中间点密度*/
char flag2;
#pragma memory=default

set(char ch,bit flag);
lcd_cls(unsigned char x1,unsigned char y1,unsigned char x2,unsigned char y2);
lcd_asc(char x1,char y1,char dot);
lcd_str(unsigned char x1,unsigned char y1,unsigned char string[]);
delay(unsigned int time);
int printf (const char *format, ...);
gotoxy(char x1,char y1);
unsigned int abs(int number);

init()
{
    outporta=0;
    outportb=5;
    TL0=timer%256;
    TH0=timer/256;
    TMOD=1;
    ET0=1;
    PT0=1;
    EA=1;
    TR0=1;
    AD_use=0;
}

char flip (char a)
 {
    char b,i;
    for (i=0;i<8;i++) {
       b<<=1;
       b|= (a >>i ) &1;
    }
    return b;
}

write_ad(char command)
{
/*    char i;
    for(i=0;i<8;i++){
        set(sclk,0);
        if((command>>(7-i))&0x1)set(din,1);
        else set(din,0);
        set(sclk,1);
    }*/
    SBUF=flip (command);
    while(!TI);
    TI=0;
}

char read_ad_res()
{
    char i,j=0;
/*    for(i=0;i<8;i++){
        j=j<<1;
        set(sclk,0);
        if(dout)j|=1;
        else j&=0xfe;
        set(sclk,1);
    }*/

    REN=1;
    while (!RI);
    REN=0;
    RI=0;
    i=flip(SBUF);
    return i;
}

int read_ad_data()
{
    union{
        int j;
        char a[2];
    }c;
    char i;
/*    do{
        write_ad(AD|READ);
        i=read_ad_res();
    }while((i&0x80)!=0);*/
    write_ad(AD|0x30|READ);
    c.a[0]=read_ad_res();
    c.a[1]=read_ad_res();
    return c.j;
}

set_ad(char gain)
{
    char nn;
    AD=2;                       /*增益设置到32*/
    write_ad(AD|SETUP|W);
    write_ad(0x64);             /*写AD7715设置寄存器,自校准,最大更新速率,单极性工作,带输入缓冲*/
/*    do{
        delay(200);
        write_ad(AD|READ);
        nn=read_ad_res();
    }while((nn&0x80)!=0);*/       /*等待自校准完毕*/
    while(INT0==1);
    delay(200);
}


error(int no)
{
/*    EA=0;
    outporta=outportb=0;
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg48);
    lcd_asc(3,0,no/1000+'0');
    lcd_asc(3,8,(no/100)%10+'0');
    lcd_asc(3,16,(no/10)%10+'0');
    lcd_asc(3,24,no%10+'0');
    set(sound,0);*/
    exit();
}

ad_init()
{
    char i;
/*    set(din,1);
    for(i=0;i<32;i++){
        set(sclk,0);
        set(sclk,1);
    }*/
/*    write_ad(AD|READ);
    i=read_ad_res();
    if(i!=(AD|READ))error(AD_ERROR);*/
    set_ad(!COLOR);
    IT0=1;
    PX0=0;
}

delay(unsigned int time)
{
    int i;
    unsigned char j;
    for(i=0;i<time;i++)for(j=0;j<DELAY_SCALE;j++);
}

char wait_key()
{
    char k=INVAILD;
    while(key()!=INVAILD);
    while(k==INVAILD)k=key();
    return k;
}

unsigned int get_ad()
{
    int i;
    bit flag=0;
/*    sum=0;
    for(i=0;i<FLITER_TIMES;i++)buffer[i]=0;*/
    useable=0;
    EX0=1;
/*    for(i=0;i<2000;i++){
        delay(20);
        if(useable)flag=1;break;
    }*/
    while(!useable);
/*    useable=0;
    while(!useable);
    useable=0;
    while(!useable);*/
    EX0=0;
    return (int)(log10(result)*10000);
}

lcd_error()
{
    outporta=outportb=0;
    while(1){
        set(sound,0);
        delay(1000);
        set(sound,1);
        delay(1000);
    }
}

lcd_int()
{
    char i;
    for(i=0;i<200;i++){
        if(LCD_BUSY==0)return;
        delay(1);
    }
    lcd_error();
}

/*清屏*/
lcd_cls(unsigned char x1,unsigned char y1,unsigned char x2,unsigned char y2)
{
    unsigned char x,y;
    for(x=x1;x<x2;x++){
        for(y=y1;y<y2;y++){
            if(y>63)T1=1;
                else T1=0;
            lcd_int();
            lcd_set=x|0xb8;     /*页地址设置*/
            lcd_int();
            lcd_set=(y&0x3f)|0x40;
            lcd_int();
            lcd_data=0;
        }
    }
    lcd_int();
    lcd_set=0xc0;

}

/*液晶显示器单个汉字字符显示*/
lcd_char(char x1,char y1,char dot)  /*页地址,Y地址,字符点阵数组*/
{
    unsigned char i;
    y=y1+16;
    if(y>=128){
        y=0;
        x=(x>=3)?0:x1+1;
    }
    if(y1>63){           /*若Y>64,在后64列操作*/
        T1=1;
        y1=y1&0x3f;
    }
    else T1=0;
    lcd_int();
    lcd_set=x1|0xb8;     /*页地址设置*/
    lcd_int();
    lcd_set=y1|0x40;
    for(i=0;i<16;i++){
        lcd_int();
        lcd_data=*(HZ+(dot-1)*32+i);
    }
    lcd_int();
    lcd_set=(x1+1)|0xb8;
    lcd_int();
    lcd_set=y1|0x40;
    for(i=16;i<32;i++){
        lcd_int();
        lcd_data=*(HZ+(dot-1)*32+i);
    }
    lcd_int();
    lcd_set=0xc0;
}

/*单个英文字符显示*/
lcd_asc(char x1,char y1,char dot)
{
    unsigned char i;
    y=y1+8;
    if(y>=128){
        y=0;
        x=(x>=3)?0:x1+1;
    }
    if(y1>63){           /*若Y>64,在后64列操作*/
        T1=1;
        y1=y1&0x3f;
    }
    else T1=0;
    lcd_int();
    lcd_set=x1|0xb8;     /*页地址设置*/
    lcd_int();
    lcd_set=y1|0x40;
    for(i=0;i<8;i++){
        lcd_int();
        lcd_data=*(ASCII+dot*8+i);
    }
    lcd_int();
    lcd_set=0xc0;
}

/*字符串显示子程序*/
lcd_str(unsigned char x1,unsigned char y1,unsigned char string[])
{
    unsigned char i;
    for(i=0;i<8;i++){
        if(string[i]==0)break;
        lcd_char(x1,y1+16*i,string[i]);
    }
}

gotoxy(char x1,char y1)
{
    x=x1;
    y=y1;
}

lcd_init()
{
    lcd_int();
    lcd_set=0x3f;
    lcd_int();
    lcd_set=0xc0;
    T1=~T1;
    lcd_int();
    lcd_set=0x3f;
    lcd_int();
    lcd_set=0xc0;
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg0);
    lcd_str(2,0,msg40);
    time=0;
    while((time<500)&&key()==INVAILD);
}

/*a/d转换*/
unsigned char ad(char ch)
{
    unsigned char i;
    AD_use=1;
    ad_port[ch]=0;
    delay(1);
    for(i=0;i<255;i++){
        if(ad_BUSY==1)goto ad_ok;
        delay(1);
    }
    error(AD_TIMEOUT);
ad_ok:
    i=ad_port[ch];
    AD_use=0;
    return i;
}

unsigned char ad_I(char ch)
{
    unsigned char i;
    AD_use=1;
    ad_port[ch]=0;
    for(i=0;i<255;i++);
    for(i=0;i<255;i++)if(ad_BUSY==1)goto ad_ok;
    error(AD_TIMEOUT);
ad_ok:
    i=ad_port[ch];
    AD_use=0;
    return i;
}

write(char *address,char byte)
{
    char dd;
    *address=byte;
    for(dd=0;dd<20;dd++)if(*address==byte)return;
    error(MEM_WRITE_FAULT);
}

write_int(unsigned int *address,int num)
{
    union{
        int n;
        char c[2];
    }a;
    char i,*p;
    p=(char *)address;
    a.n=num;
    write(p,a.c[0]);
    write(p+1,a.c[1]);
}

write_double(double *address,double num)
{
    union{
        double n;
        char c[4];
    }a;
    char i,*p;
    p=(char *)address;
    a.n=num;
    for(i=0;i<4;i++)write(p+i,a.c[i]);
}

vol()
{
    ac=ad(AC);
}

page_dis()
{
    lcd_asc(0,112,(page/10)%10+48);
    lcd_asc(0,120,page%10+48);
}

/*状态显示*/
display()
{
    unsigned int rr,gg,bb;
/*    if(r_scale>=10){
        if(d_scale>=10)rr=r_time+r_time*(r_scale-10)/10+r_time*(d_scale-10)/10; /*d_scale>=0,r_scale>=0*/
                  else rr=r_time+r_time*(r_scale-10)/10-r_time*(10-d_scale)/10; /*d_scale<0,r_scale>=0*/
        }
        else{
            if(d_scale>=10)rr=r_time-r_time*(10-r_scale)/10+r_time*(d_scale-10)/10; /*d_scale>=0,r_scale<0*/
                      else rr=r_time-r_time*(10-r_scale)/10-r_time*(10-d_scale)/10; /*d_scale<0,r_scale<0*/
            }*/
    rr=(double)r_time*(1+(double)(r_scale+d_scale-20)/10);
    lcd_asc(0,0,'R');
    lcd_asc(0,8,':');
    lcd_asc(0,16,(rr/1000)%10+48);
    lcd_asc(0,24,(rr/100)%10+48);
    lcd_asc(0,32,'.');
    lcd_asc(0,40,(rr/10)%10+48);
    lcd_asc(0,48,rr%10+48);
    lcd_asc(0,56,'S');
    if(r_scale<10){lcd_asc(0,64,'-');lcd_asc(0,72,(10-r_scale)%10+48);}
        else {lcd_asc(0,64,'+');lcd_asc(0,72,(r_scale-10)%10+48);}

/*    if(g_scale>=10){
        if(d_scale>=10)gg=g_time+g_time*(g_scale-10)/10+g_time*(d_scale-10)/10; /*d_scale>=0,r_scale>=0*/
                  else gg=g_time+g_time*(g_scale-10)/10-g_time*(10-d_scale)/10; /*d_scale<0,r_scale>=0*/
        }
        else{
            if(d_scale>=10)gg=g_time-g_time*(10-g_scale)/10+g_time*(d_scale-10)/10; /*d_scale>=0,r_scale<0*/
                      else gg=g_time-g_time*(10-g_scale)/10-g_time*(10-d_scale)/10; /*d_scale<0,r_scale<0*/
            }*/
    gg=(double)g_time*(1+(double)(g_scale+d_scale-20)/10);
    lcd_asc(1,0,'G');
    lcd_asc(1,8,':');
    lcd_asc(1,16,(gg/1000)%10+48);
    lcd_asc(1,24,(gg/100)%10+48);
    lcd_asc(1,32,'.');
    lcd_asc(1,40,(gg/10)%10+48);
    lcd_asc(1,48,gg%10+48);
    lcd_asc(1,56,'S');
    if(g_scale<10){lcd_asc(1,64,'-');lcd_asc(1,72,(10-g_scale)%10+48);}
        else {lcd_asc(1,64,'+');lcd_asc(1,72,(g_scale-10)%10+48);}

/*    if(b_scale>=10){
        if(d_scale>=10)bb=b_time+b_time*(b_scale-10)/10+b_time*(d_scale-10)/10; /*d_scale>=0,r_scale>=0*/
                  else bb=b_time+b_time*(b_scale-10)/10-b_time*(10-d_scale)/10; /*d_scale<0,r_scale>=0*/
        }
        else{
            if(d_scale>=10)bb=b_time-b_time*(10-b_scale)/10+b_time*(d_scale-10)/10; /*d_scale>=0,r_scale<0*/
                      else bb=b_time-b_time*(10-b_scale)/10-b_time*(10-d_scale)/10; /*d_scale<0,r_scale<0*/
            }*/
    bb=(double)b_time*(1+(double)(b_scale+d_scale-20)/10);
    lcd_asc(2,0,'B');
    lcd_asc(2,8,':');
    lcd_asc(2,16,(bb/1000)%10+48);
    lcd_asc(2,24,(bb/100)%10+48);
    lcd_asc(2,32,'.');
    lcd_asc(2,40,(bb/10)%10+48);
    lcd_asc(2,48,bb%10+48);
    lcd_asc(2,56,'S');
    if(b_scale<10){lcd_asc(2,64,'-');lcd_asc(2,72,(10-b_scale)%10+48);}
        else {lcd_asc(2,64,'+');lcd_asc(2,72,(b_scale-10)%10+48);}

    lcd_asc(3,0,'D');
    lcd_asc(3,8,':');
    lcd_asc(3,16,'N');
    if(d_scale<10){lcd_asc(3,24,'-');lcd_asc(3,32,(10-d_scale)%10+48);}
        else {lcd_asc(3,24,'+');lcd_asc(3,32,(d_scale-10)%10+48);}

    lcd_asc(0,112,(page/10)%10+48);
    lcd_asc(0,120,page%10+48);

    if(size==ONE)lcd_asc(1,112,'1');
    if(size==TWO)lcd_asc(1,112,'2');
    if(size==THREE)lcd_asc(1,112,'3');
    if(size==FIVE)lcd_asc(1,112,'5');
    if(size==SEVEN)lcd_asc(1,112,'7');
    lcd_asc(1,120,'"');

    lcd_asc(2,88,'C');
    lcd_asc(2,96,'H');
    lcd_asc(2,104,':');
    lcd_asc(2,112,(ch+1)/10+48);
    lcd_asc(2,120,(ch+1)%10+48);

    lcd_asc(3,88,ac/100+48);
    lcd_asc(3,96,(ac/10)%10+48);
    lcd_asc(3,104,'.');
    lcd_asc(3,112,ac%10+48);
    lcd_asc(3,120,'V');
}

set(char ch,bit flag)
{
    if(ch<8){
        ch=1<<ch;
        if(flag)outa|=ch;else outa&=~ch;
        outporta=outa;
    }
    else{
        if(ch<16){
            ch=1<<(ch-8);
            if(flag)outb|=ch;else outb&=~ch;
            outportb=outb;
        }
        else error(OUT_ERROR);
    }
}

Iset(char ch,bit flag)
{
    if(ch<8){
        ch=1<<ch;
        if(flag)outa|=ch;else outa&=~ch;
        outporta=outa;
    }
    else{
        if(ch<16){
            ch=1<<(ch-8);
            if(flag)outb|=ch;else outb&=~ch;
            outportb=outb;
        }
        else error(OUT_ERROR);
    }
}
/*画幅转换*/
size_go()
{
    lcd_cls(0,0,4,128);
    lcd_str(2,0,msg25);
    if(size==ONE){
oo:
    while(up_camer_no!=OK){
        if(up_camer_no!=OK){
            set(motor1,ON);
        }
        else {
            delay(100);
            if(up_camer_no==OK){
                set(motor1,OFF);
            }
        }
    }
    set(motor1,OFF);
    while(box_close!=OK){
        if(box_close!=OK){
            set(box_m,ON);
        }
        else {
            delay(100);
            if(box_close==OK){
                set(box_m,OFF);
            }
        }
    }
    set(box_m,OFF);
        while(down_camer_one!=OK){
            if(down_camer_one!=OK){
                set(motor2,ON);
            }
                else {
                    delay(100);
                    if(down_camer_one==OK){
                        set(motor2,OFF);
                    }
                }
        }
        set(motor2,OFF);
        delay(300);
        if(up_camer_no!=OK)goto oo;
        if(down_camer_one!=OK)goto oo;
        if(box_close!=OK)goto oo;
    }
    if(size==TWO){
tt:
        while(box_close!=OK){
            if(box_close!=OK){
                set(box_m,ON);
            }
                else {
                    delay(150);
                    if(box_close==OK){
                        set(box_m,OFF);
                    }
                }
            }
            set(box_m,OFF);
        while(up_camer_no!=OK){
            if(up_camer_no!=OK){
                set(motor1,ON);
            }
                else {
                    delay(10);
                    if(up_camer_no==OK){
                        set(motor1,OFF);
                    }
                }
            }
            set(motor1,OFF);
        while(down_camer_two!=OK){
                   if(down_camer_two!=OK){
                    set(motor2,ON);
                }
                else        {
                           delay(10);
                    if(down_camer_two==OK){
                        set(motor2,OFF);
                    }
                }
            }
            set(motor2,OFF);
        delay(500);
        if(up_camer_no!=OK)goto tt;
        if(down_camer_two!=OK)goto tt;
        if(box_close!=OK)goto tt;
    }
    if(size==THREE){
hh:
        while(box_close!=OK){
            if(box_close!=OK){
                set(box_m,ON);
            }
                       else {
                           delay(150);
                           if(box_close==OK){
                            set(box_m,OFF);
                        }
                       }
            }
            set(box_m,OFF);
        while(up_camer_three!=OK){
                   if(up_camer_three!=OK){
                    set(motor1,ON);
                }
                       else {
                           delay(10);
                           if(up_camer_three==OK){
                            set(motor1,OFF);
                        }
                       }
                   }
                    set(motor1,OFF);
        while(down_camer_no!=OK){
                   if(down_camer_no!=OK){
                    set(motor2,ON);
                }
                else {
                    delay(10);
                    if(down_camer_no==OK){
                        set(motor2,OFF);
                    }
                }
            }
            set(motor2,OFF);
        delay(500);
        if(up_camer_three!=OK)goto hh;
        if(down_camer_no!=OK)goto hh;
        if(box_close!=OK)goto hh;
    }
    if(size==FIVE){
ff:
        while(up_camer_five!=OK){
            if(up_camer_five!=OK){
                set(motor1,ON);
            }
                else {
                    delay(10);
                    if(up_camer_five==OK){
                        set(motor1,OFF);
                    }
                }
            }
            set(motor1,OFF);
        while(box_close!=OK){
            if(box_close!=OK){
                set(box_m,ON);
            }
                else {
                    delay(150);
                    if(box_close==OK){
                        set(box_m,OFF);
                    }
                }
            }
            set(box_m,OFF);
        while(down_camer_no!=OK){
            if(down_camer_no!=OK){
                set(motor2,ON);
            }
                else {
                    delay(10);
                    if(down_camer_no==OK){
                        set(motor2,OFF);
                    }
                }
        }
        set(motor2,OFF);
        delay(500);
        if(up_camer_five!=OK)goto ff;
        if(down_camer_no!=OK)goto ff;
        if(box_close!=OK)goto ff;
    }
    if(size==SEVEN){
ss:
        while(box_open!=OK){
            if(box_open!=OK){
                set(box_m,ON);
            }
                else {
                    delay(150);
                    if(box_open==OK){
                        set(box_m,OFF);
                    }
                }
            }
            set(box_m,OFF);
        while(up_camer_seven!=OK){
            if(up_camer_seven!=OK){
                set(motor1,ON);
            }
                else {
                    delay(10);
                    if(up_camer_seven==OK){
                        set(motor1,OFF);
                    }
                }
            }
            set(motor1,OFF);
        while(down_camer_no!=OK){
            if(down_camer_no!=OK){
                set(motor2,ON);
            }
                else {
                    delay(10);
                    if(down_camer_no==OK){
                        set(motor2,OFF);
                    }
                }
            }
            set(motor2,OFF);
        delay(500);
        if(up_camer_seven!=OK)goto ss;
        if(down_camer_no!=OK)goto ss;
        if(box_open!=OK)goto ss;
    }
    set(motor1,OFF);
    set(motor2,OFF);
    set(box_m,OFF);
    lcd_cls(0,0,4,128);
}


dev_dis(unsigned char temp)
{
    unsigned int vv;
    vv=temp+250;
    lcd_asc(0,0,'D');
    lcd_asc(0,8,'E');
    lcd_asc(0,16,'V');
    lcd_asc(0,24,':');
    lcd_asc(0,32,vv/100+48);
    lcd_asc(0,40,(vv%100)/10+48);
    lcd_asc(0,48,'.');
    lcd_asc(0,56,vv%10+48);
    lcd_asc(0,64,248);
}

fix_dis(unsigned char temp)
{
    unsigned int vv;
    vv=temp+250;
    lcd_asc(1,0,'F');
    lcd_asc(1,8,'I');
    lcd_asc(1,16,'X');
    lcd_asc(1,24,':');
    lcd_asc(1,32,vv/100+48);
    lcd_asc(1,40,(vv%100)/10+48);
    lcd_asc(1,48,'.');
    lcd_asc(1,56,vv%10+48);
    lcd_asc(1,64,248);
}

/*dry_dis(unsigned char temp)
{
    unsigned int vv;
    vv=temp+600;
    lcd_asc(2,0,'D');
    lcd_asc(2,8,'R');
    lcd_asc(2,16,'Y');
    lcd_asc(2,24,':');
    lcd_asc(2,32,vv/100+48);
    lcd_asc(2,40,(vv%100)/10+48);
    lcd_asc(2,48,'.');
    lcd_asc(2,56,vv%10+48);
    lcd_asc(2,64,248);
} */

/*温度设定*/
temp_set()
{
    unsigned char jj,mm;
    unsigned int vv;
    lcd_cls(0,0,4,128);
    lcd_str(2,0,msg24);
    delay(500);
    lcd_cls(2,0,4,128);
    dev_dis(DEV_temp);
    fix_dis(FIX_temp);
/*    dry_dis(DRY_temp);*/
    jj=key();
    while(jj!=isxi_key){
        jj=key();
        switch(jj){
            case r_key:MODE=R;break;
            case g_key:MODE=G;break;
            case b_key:MODE=B;break;
            case plus_key:{
                if(MODE==R){
                    mm=DEV_temp+1;
                    dev_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=plus_key)goto dq;
                    while(key()==plus_key){
                        mm++;
                        dev_dis(mm);
                    }
dq:
                    DEV_temp=mm;
                    while(DEV_temp!=mm);
                }
                if(MODE==G){
                    mm=FIX_temp+1;
                    fix_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=plus_key)goto fq;
                    while(key()==plus_key){
                        mm++;
                        fix_dis(mm);
                    }
fq:
                    FIX_temp=mm;
                    while(FIX_temp!=mm);
                }
/*                if(MODE==B){
                    mm=DRY_temp+1;
                    dry_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=plus_key)goto rq;
                    while(key()==plus_key){
                        mm++;
                        dry_dis(mm);
                    }
rq:
                    DRY_temp=mm;
                    while(DRY_temp!=mm);
                }*/
                break;
            }
            case dec_key:{
                if(MODE==R){
                    mm=DEV_temp-1;
                    dev_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=dec_key)goto dh;
                    while(key()==dec_key){
                        mm--;
                        dev_dis(mm);
                    }
dh:
                    DEV_temp=mm;
                    while(DEV_temp!=mm);
                }
                if(MODE==G){
                    mm=FIX_temp-1;
                    fix_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=dec_key)goto fh;
                    while(key()==dec_key){
                        mm--;
                        fix_dis(mm);
                    }
fh:
                    FIX_temp=mm;
                    while(FIX_temp!=mm);
                }
/*                if(MODE==B){
                    mm=DRY_temp-1;
                    dry_dis(mm);
                    for(jj=0;jj<5;jj++)if(key()!=dec_key)goto rh;
                    while(key()==dec_key){
                        mm--;
                        dry_dis(mm);
                    }
rh:
                    DRY_temp=mm;
                    while(DRY_temp!=mm);
                }*/
                break;
            }
        }
    }
    lcd_cls(0,0,4,128);
}

/*对焦操作*/
dvjc()
{
    lcd_cls(0,0,4,128);
    lcd_str(2,0,msg5);
    while(key()==size_key);
    while(key()!=size_key){
        set(door,ON);
    }
    set(door,OFF);
    lcd_cls(0,0,4,128);
    while(key()==size_key);
}

Test()
{
    unsigned int aa;
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg37);
    while(key()==go_key);
    while(key()!=go_key){
        if(key()==r_key){
            set(filter,OFF);
            set(r_m,ON);
            while(key()==r_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg34);
                /*EX0=1;*/
                gotoxy(1,88);
                printf("%d    ",get_ad());
                aa= (unsigned int) (log10((double)red_base/(double)get_ad())*10000);
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
            }
            set(r_m,OFF);
        }
        if(key()==g_key){
            set(filter,ON);
            set(g_m,ON);
            while(key()==g_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg35);
                /*EX0=1;*/
                gotoxy(1,88);
                printf("%d    ",get_ad());
                aa= (unsigned int) (log10((double)green_base/(double)get_ad())*10000);
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
            }
            set(g_m,OFF);
            set(filter,OFF);
        }
        if(key()==b_key){
            set(filter,ON);
            set(b_m,ON);
            while(key()==b_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg36);
                /*EX0=1;*/
                gotoxy(1,88);
                printf("%d    ",get_ad());
                aa= (unsigned int) (log10((double)blue_base/(double)get_ad())*10000);
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
            }
            set(b_m,OFF);
            set(filter,OFF);
        }
        if(key()==ch_key){
            set(b_m,ON);
            set(g_m,ON);
            while(key()==ch_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg34);
                /*EX0=1;*/
                aa=result;
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
                gotoxy(1,88);
                printf("%d    ",get_ad());
            }
            set(b_m,OFF);
            set(g_m,OFF);
        }
        if(key()==size_key){
            set(b_m,ON);
            set(r_m,ON);
            while(key()==size_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg35);
                /*EX0=1;*/
                aa=result;
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
                gotoxy(1,88);
                printf("%d    ",get_ad());
            }
            set(b_m,OFF);
            set(g_m,OFF);
        }
        if(key()==isxi_key){
            set(r_m,ON);
            set(g_m,ON);
            while(key()==isxi_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg36);
                /*EX0=1;*/
                gotoxy(1,88);
                printf("%d    ",get_ad());
                aa=result;
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
            }
            set(r_m,OFF);
            set(g_m,OFF);
        }
        if(key()==uiji_key){
            while(key()==uiji_key);
                lcd_cls(2,0,4,128);
            while(key()==INVAILD){
                /*EX0=1;*/
                gotoxy(1,88);
                printf("%d    ",get_ad());
                aa= (unsigned int) (log10((double)white_base/(double)get_ad())*10000);
                lcd_asc(3,64,aa/10000+48);
                lcd_asc(3,72,(aa/1000)%10+48);
                lcd_asc(3,80,(aa/100)%10+48);
                lcd_asc(3,88,(aa/10)%10+48);
                lcd_asc(3,96,aa%10+48);
            }
        }
    }
   /*EX0=0;*/
    while(key()==go_key);
}

/*加操作*/
plus()
{
    unsigned char i;
        switch(MODE){
            case R:if(r_scale<19)r_scale++;break;
            case G:if(g_scale<19)g_scale++;break;
            case B:if(b_scale<19)b_scale++;break;
            case D:if(d_scale<19)d_scale++;break;
            case PAGE:{if(page<99)page++;
                page_dis();
                for(i=0;i<5;i++)if(key()!=plus_key)break;
                while(key()==plus_key){
                    if(page<99)page++;
                    page_dis();
                }
                break;
            }
        }
        display();
}

/*减操作*/
dec()
{
    unsigned char i;
        switch(MODE){
            case R:if(r_scale>1)r_scale--;break;
            case G:if(g_scale>1)g_scale--;break;
            case B:if(b_scale>1)b_scale--;break;
            case D:if(d_scale>1)d_scale--;break;
            case PAGE:{if(page>1)page--;
                page_dis();
                for(i=0;i<5;i++)if(key()!=dec_key)break;
                while(key()==dec_key){
                    if(page>1)page--;
                    page_dis();
                }
                break;
            }
        }
        display();
}

/*走纸*/
feed()
{
    char i;
    lcd_cls(0,0,4,128);
    lcd_str(2,0,msg3);
    i=1;
    if(size==SEVEN)i=4;
    if(size==FIVE)i=2;
    if(size==THREE)i=2;
    set(feed_m,ON);
    while(i>0){
        while(1){
            set(feed_m,ON);
            if(feed_pluse!=1){      /*NON Hole*/
                delay(10);
                if(feed_pluse!=1)break;
            }
        }
        while(1){
            set(feed_m,ON);
            if(feed_pluse==1){      /*Hole*/
                delay(10);
                if(feed_pluse==1)break;
            }
        }
        i--;
    }
    set(feed_m,OFF);
    lcd_cls(2,0,4,64);
}

detect()
{
    double sen_w,sen_r,sen_g,sen_b;
    if(workmode==0)return;
    /*EX0=1;*/
    white=get_ad();
    /*EX0=1;*/
    set(r_m,ON);
    sen_w=(double)log10((double)white_base/(double)white);
    delay(30*r_delay);
    red=get_ad();
    /*EX0=1;*/
    set(r_m,OFF);
    set(b_m,ON);
    set(filter,ON);
    sen_r=(double)log10((double)red_base/(double)red);
    delay(30*b_delay);
    blue=get_ad();
    set(b_m,OFF);
    set(g_m,ON);
    /*EX0=1;*/
    sen_b=(double)log10((double)blue_base/(double)blue);
    delay(30*g_delay);
    green=get_ad();
    set(g_m,OFF);
    set(filter,OFF);
    sen_g=(double)log10((double)green_base/(double)green);
    /*EX0=0;*/
    switch(workmode){
        case 1:{
/*            r_time=((double)red_const2/(pow(red,2)))*10000;
            g_time=((double)green_const2/(pow(green,2)))*10000;
            b_time=((double)blue_const2/(pow(blue,2)))*10000;
            gotoxy(0,0);
            lcd_cls(0,0,4,128);
            printf("g:%d,a:%d S:%d",green,green_agfa,(int)(sen_g*10000));
            printf("b:%d m:%d,c:%d",green_base,mid_g,green_const);
            wait_key();
            lcd_cls(0,0,4,128);*/
            r_time=(double)pow(10,red_agfa*(sen_r-(double)mid_r/10000)+(double)red_const/1000)/(double)red;
            g_time=(double)pow(10,green_agfa*(sen_g-(double)mid_g/10000)+(double)green_const/1000)/(double)green;
            b_time=(double)pow(10,blue_agfa*(sen_b-(double)mid_b/10000)+(double)blue_const/1000)/(double)blue;
            senr=sen_r*10000;
            seng=sen_g*10000;
            senb=sen_b*10000;
            fr=log10((double)pow(10,red_agfa*(sen_r-(double)mid_r/10000)+(double)red_const/1000))*1000;
            fg=log10((double)pow(10,green_agfa*(sen_g-(double)mid_g/10000)+(double)green_const/1000))*1000;
            fb=log10((double)pow(10,blue_agfa*(sen_b-(double)mid_b/10000)+(double)blue_const/1000))*1000;
        }
    }
}

/*曝光操作*/
go()
{
    int rr,gg,bb;
    detect();
    bb=(double)b_time*(1+(double)(b_scale+d_scale-20)/10);
    gg=(double)g_time*(1+(double)(g_scale+d_scale-20)/10);
    rr=(double)r_time*(1+(double)(r_scale+d_scale-20)/10);
    for(;page>=1;page--){
        display();
        set(b_m,ON);
        set(filter,ON);
        delay(DELAY);
        set(door,ON);
        time=0;
        while(time<bb){
            lcd_asc(2,16,(bb-time)/1000+48);
            lcd_asc(2,24,((bb-time)/100)%10+48);
            lcd_asc(2,40,((bb-time)/10)%10+48);
            lcd_asc(2,48,48);
            ac=ad(AC);
            lcd_asc(3,88,ac/100+48);
            lcd_asc(3,96,(ac/10)%10+48);
            lcd_asc(3,104,'.');
            lcd_asc(3,112,ac%10+48);
            lcd_asc(3,120,'V');
        }
        set(door,OFF);
        set(g_m,ON);
        delay(DELAY);
        set(b_m,OFF);

        delay(DELAY);
        set(door,ON);
        time=0;
        while(time<g_time){
            lcd_asc(1,16,(gg-time)/1000+48);
            lcd_asc(1,24,((gg-time)/100)%10+48);
            lcd_asc(1,40,((gg-time)/10)%10+48);
            lcd_asc(1,48,48);
            ac=ad(AC);
            lcd_asc(3,88,ac/100+48);
            lcd_asc(3,96,(ac/10)%10+48);
            lcd_asc(3,104,'.');
            lcd_asc(3,112,ac%10+48);
            lcd_asc(3,120,'V');
        }
        set(door,OFF);
        set(r_m,ON);
        delay(DELAY);
        set(filter,OFF);
        set(g_m,OFF);

        delay(DELAY);
        set(door,ON);
        time=0;
        while(time<r_time){
            lcd_asc(0,16,(rr-time)/1000+48);
            lcd_asc(0,24,((rr-time)/100)%10+48);
            lcd_asc(0,40,((rr-time)/10)%10+48);
            lcd_asc(0,48,48);
            ac=ad(AC);
            lcd_asc(3,88,ac/100+48);
            lcd_asc(3,96,(ac/10)%10+48);
            lcd_asc(3,104,'.');
            lcd_asc(3,112,ac%10+48);
            lcd_asc(3,120,'V');
        }
        set(door,OFF);
        delay(DELAY);
        set(r_m,OFF);

        feed();
    }
    page=1;
    d_scale=r_scale=g_scale=b_scale=10;
}

/*键盘扫描*/
int key()
{
    #pragma memory=code
    const unsigned char i[4]={0xfe,0xfd,0xfb,0xf7};
    #pragma memory=default
    char j,k;
    char key;
    key=0xff;
    for(j=0;j<4;j++){
        P1=i[j];
        k=P1|0xf;
        if(k!=0xff){
            delay(20);
            if(k==P1|0xf){
                key=(k&0xf0)+j;
                set(sound,0);
                delay(10);
                set(sound,1);
            }
            break;
        }
    }
    return key;
}

lip()
{
    char i,j;
    i=j=1;
    if(ad(DEV_LIP)<100)i=0;
    if(ad(FIX_LIP)<100)j=0;
    if((i&j)!=1){
                set(sound,0);
        delay(50);
        lcd_cls(0,0,4,128);
        if(i==0)lcd_str(0,0,msg49);
        if(j==0)lcd_str(2,0,msg50);
                set(sound,1);
        while(key()==INVAILD);
        return 0;
    }
    return 1;
}


/*冲洗启动及温度显示*/
isxi()
{
    unsigned int vv;
    while(key()!=INVAILD);
    if(!ISXI){
        lcd_cls(0,0,4,128);
        lcd_str(0,0,msg38);
        lcd_str(2,0,msg29);
        while(key()==INVAILD);
        if(key()==uiji_key){
            if(lip())ISXI=1;
        }
    }
    else{
        lcd_cls(0,0,4,128);
        while(key()==INVAILD){
            vv=DEV_temp+250;
            lcd_asc(0,0,'D');
            lcd_asc(0,8,'E');
            lcd_asc(0,16,'V');
            lcd_asc(0,24,':');
            lcd_asc(0,32,vv/100+48);
            lcd_asc(0,40,(vv%100)/10+48);
            lcd_asc(0,48,'.');
            lcd_asc(0,56,vv%10+48);
            lcd_asc(0,64,248);
            vv=dev_temp+250;
            lcd_asc(0,80,vv/100+48);
            lcd_asc(0,88,(vv%100)/10+48);
            lcd_asc(0,96,'.');
            lcd_asc(0,104,vv%10+48);
            lcd_asc(0,112,248);

            vv=FIX_temp+250;
            lcd_asc(1,0,'F');
            lcd_asc(1,8,'I');
            lcd_asc(1,16,'X');
            lcd_asc(1,24,':');
            lcd_asc(1,32,vv/100+48);
            lcd_asc(1,40,(vv%100)/10+48);
            lcd_asc(1,48,'.');
            lcd_asc(1,56,vv%10+48);
            lcd_asc(1,64,248);
            vv=fix_temp+250;
            lcd_asc(1,80,vv/100+48);
            lcd_asc(1,88,(vv%100)/10+48);
            lcd_asc(1,96,'.');
            lcd_asc(1,104,vv%10+48);
            lcd_asc(1,112,248);

/*            vv=DRY_temp+600;
            lcd_asc(2,0,'D');
            lcd_asc(2,8,'R');
            lcd_asc(2,16,'Y');
            lcd_asc(2,24,':');
            lcd_asc(2,32,vv/100+48);
            lcd_asc(2,40,(vv%100)/10+48);
            lcd_asc(2,48,'.');
            lcd_asc(2,56,vv%10+48);
            lcd_asc(2,64,248);
            vv=dry_temp+600;
            lcd_asc(2,80,vv/100+48);
            lcd_asc(2,88,(vv%100)/10+48);
            lcd_asc(2,96,'.');
            lcd_asc(2,104,vv%10+48);
            lcd_asc(2,112,248);*/
        }
        if(key()==uiji_key)temp_set();
        if(dev_temp>=(DEV_temp-2)&&fix_temp>=(FIX_temp-10)){
            lcd_cls(0,0,4,128);
            lcd_str(0,0,msg39);
            lcd_str(2,0,msg29);
            while(key()==INVAILD);
            if(key()==uiji_key){
                set(isxi_m,ON);
                ISXI_GO=1;
              /*  DRY_GO=1;*/
            }
        }
    }
    while(key()==uiji_key);
    lcd_cls(0,0,4,128);
}

size_convert()
{
    char i;
    #pragma memory=code
    const char ASCII[]={'7','1','2','3','5'};
    #pragma memory=default
    char k=0;
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg32);
    lcd_str(2,0,msg33);
    while(key()==size_key);
    i=size;
    while(k!=size_key){
        k=key();
        if(k==plus_key){
            if(i==4)i=0;
            else i++;
        }
        if(k==dec_key){
            if(i==0)i=4;
            else i--;
        }
        lcd_asc(1,88,ASCII[i]);
        lcd_asc(1,96,'"');
        delay(400);
    }
    size=i;
    while(size!=i);
    size_go();
}

system_clipcation()
{
    unsigned int i;
    unsigned long ss=0;
    lcd_cls(0,0,4,128);
    delay (1000);
    ss=0;
    for(i=0;i<10;i++)ss+=get_ad();
    white_base=ss/10;
    set(r_m,ON);
    /*EX0=1;*/
    gotoxy(0,0);
    printf("W:%d    ",white_base);
    delay (1000);
    ss=0;
    for(i=0;i<10;i++)ss+=get_ad();
    red_base=ss/10;
    set(g_m,ON);
    set(r_m,OFF);
    set(filter,ON);
    /*EX0=1;*/
    gotoxy(1,0);
    printf("R:%d    ",red_base);
    delay (1000);
    ss=0;
    for(i=0;i<10;i++)ss+=get_ad();
    green_base=ss/10;
    set(g_m,OFF);
    set(b_m,ON);
    /*EX0=1;*/
    gotoxy(2,0);
    printf("G:%d    ",green_base);
    delay (1000);
    ss=0;
    for(i=0;i<10;i++)ss+=get_ad();
    blue_base=ss/10;
    set(b_m,OFF);
    set(filter,OFF);
    gotoxy(3,0);
    printf("B:%d    ",blue_base);
    wait_key();
}

int printf (const char *format, ...)
{
    static const char hex[] = "0123456789ABCDEF";
    char format_flag;
    unsigned int u_val, div_val, base;
    char *ptr;
    va_list ap;
    va_start (ap, format);
    for (;;){    /* Until full format string read */
        while ((format_flag = *format++) != '%'){      /* Until '%' or '\0' */
            if (!format_flag){
                va_end (ap);
                return (0);
            }
            lcd_asc (x,y,format_flag);
        }
        switch (format_flag = *format++){
            case 'c':
                format_flag = va_arg(ap, int);
            default:
                lcd_asc (x,y,format_flag);
                continue;
            case 's':
                ptr = va_arg(ap,char *);
                while (format_flag = *ptr++){
                    lcd_char (x,y,format_flag);
                }
                continue;
            case 'o':
                base = 8;
                if (sizeof(int) == 2)
                    div_val = 0x8000;
                else
                    div_val = 0xC0000000;
                goto CONVERSION_LOOP;
            case 'd':
                base = 10;
                if (sizeof(int) == 2)
                    div_val = 10000;
                else
                    div_val = 1000000000;
                goto CONVERSION_LOOP;
            case 'x':
                base = 16;
                if (sizeof(int) == 2)
                    div_val = 0x1000;
                else
                    div_val = 0x10000000;
            CONVERSION_LOOP:
                u_val = va_arg(ap,int);
                if (format_flag == 'd'){
/*                    if (((int)u_val) < 0){
                        u_val = - u_val;
                        lcd_asc (x,y,'-');
                    }*/
                    while (div_val > 1 && div_val > u_val){
                        div_val /= 10;
                    }
                }
                do{
                    lcd_asc (x,y,hex[u_val / div_val]);
                    u_val %= div_val;
                    div_val /= base;
                }while (div_val);
        }
    }
}

/*  参数设定:       */
/*  白.红.绿.蓝常数:0-65535
    开机启动加热:ON.OFF
    光线稳定度:1-50
    白.红.绿.蓝斜率校正系数:0.1-1;  */

option()
{
    char k=INVAILD;
    int temp;
    temp=(int)white_const;
    lcd_cls(0,0,4,128);
    gotoxy(0,0);
    printf("%s",msg53);
    gotoxy(2,0);
    printf("%d    ",temp);
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&white_const,temp);
    temp=(int)red_const;
    gotoxy(0,0);
    printf("%s",msg54);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&red_const,temp);
    temp=(int)green_const;
    gotoxy(0,0);
    printf("%s",msg55);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&green_const,temp);
    temp=(int)blue_const;
    gotoxy(0,0);
    printf("%s",msg56);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&blue_const,temp);
    temp=(int)mid_w;
    gotoxy(0,0);
    printf("%s",msg66);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&mid_w,temp);
    temp=(int)white_agfa;
    gotoxy(0,0);
    printf("%s",msg57);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write(&white_agfa,temp);
    temp=(int)mid_r;
    gotoxy(0,0);
    printf("%s",msg67);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&mid_r,temp);
    temp=(int)red_agfa;
    gotoxy(0,0);
    printf("%s",msg58);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write(&red_agfa,temp);
    temp=(int)mid_g;
    gotoxy(0,0);
    printf("%s",msg68);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(200);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&mid_g,temp);
    temp=(int)green_agfa;
    gotoxy(0,0);
    printf("%s",msg59);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write(&green_agfa,temp);
    temp=(int)mid_b;
    gotoxy(0,0);
    printf("%s",msg69);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write_int(&mid_b,temp);
    temp=(int)blue_agfa;
    gotoxy(0,0);
    printf("%s",msg60);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp+=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp--;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==dec_key){
                temp-=10;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
    }
    write(&blue_agfa,temp);
    temp=(int)stability;
    gotoxy(0,0);
    printf("%s",msg61);
    gotoxy(2,0);
    printf("%d    ",temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp>=50?temp=0:temp++;
            gotoxy(2,0);
            printf("%d    ",temp);
            delay(1000);
            while(key()==plus_key){
                temp>=50?temp=0:temp++;
                gotoxy(2,0);
                printf("%d    ",temp);
            }
        }
        if(k==dec_key){
            temp<=1?50:temp--;
            gotoxy(2,0);
            printf("%d        ",temp);
            delay(1000);
            while(key()==dec_key){
                temp<=1?50:temp--;
                gotoxy(2,0);
                printf("%d        ",temp);
            }
        }
    }
    write(&stability,temp);
    temp=auto_hot;
    gotoxy(0,0);
    printf("%s    ",msg62);
    gotoxy(2,0);
    printf("%s    ",msg63+temp);
    k=INVAILD;
    while(k!=uiji_key){
        k=wait_key();
        if(k==plus_key){
            temp=1;
            gotoxy(2,0);
            printf("%s    ",msg63+temp);
        }
        if(k==dec_key){
            temp=0;
            gotoxy(2,0);
            printf("%s   ",msg63+temp);
        }
    }
    write(&auto_hot,temp);
}

main()
{
    unsigned char nn,xx;
    init();
    lcd_init();
    ISXI=0;
    ISXI_GO=ISXI_OK=0;
    r_scale=g_scale=b_scale=d_scale=10;
    r_time=g_time=b_time=1000;
    sum=0;
    for(nn=0;nn<FILTER_TIMES;nn++)buffer[nn]=0;
    page=1;
    MODE=0xff;
    if(flag1!=0x55||flag2!=0xaa){
        write(&size,FIVE);
        write(&ch,0);
        write(&workmode,1);
        write(&useable_flag,0);
        write(&auto_hot,0);
        write(&stability,20);
        write(&flag1,0x55);
        write(&flag2,0xaa);
    }
    if(lip()){
        ISXI=auto_hot;
    }
    ad_init();
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg41);
    lcd_str(2,0,msg42);
    time=0;
    EX0=1;
    while(time<PRE_HOT_TIME){
/*        lcd_asc(1,88,((PRE_HOT_TIME-time)/6000)%10+48);
        lcd_asc(1,96,':');
        lcd_asc(1,104,((PRE_HOT_TIME-time)%6000)/1000+48);
        lcd_asc(1,112,(((PRE_HOT_TIME-time)%6000)/100)%10+48);*/
        if(key()==page_key)break;
        gotoxy(1,88);
        printf("%d",(int)(log10(result)*10000));
        if(!useable)time=0;
    }
    EX0=0;
    system_clipcation();
    for(r_delay=1;r_delay<100;r_delay++){
        set(r_m,ON);
        delay(10*r_delay);
        if(abs((int)(get_ad()-red_base))<20){
            set(r_m,OFF);
            break;
        }
        set(r_m,OFF);
        delay(500);
    }
    lcd_cls(0,0,4,128);
    gotoxy(0,0);
    printf("red delay:%d",r_delay);
    for(g_delay=1;g_delay<100;g_delay++){
        set(g_m,ON);
        set(filter,ON);
        delay(10*g_delay);
        if(abs((int)(get_ad()-green_base))<20){
            set(g_m,OFF);
            set(filter,OFF);
            break;
        }
        set(g_m,OFF);
        set(filter,OFF);
        delay(500);
    }
    gotoxy(1,0);
    printf("green delay:%d",g_delay);
    for(b_delay=1;b_delay<100;b_delay++){
        set(b_m,ON);
        set(filter,ON);
        delay(10*b_delay);
        if(abs((int)(get_ad()-blue_base))<20){
            set(b_m,OFF);
            set(filter,OFF);
            break;
        }
        set(b_m,OFF);
        set(filter,OFF);
        delay(500);
    }
    gotoxy(2,0);
    printf("blue delay:%d",b_delay);
    wait_key();
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg43);
    lcd_asc(1,48,(ch+1)/10+48);
    lcd_asc(1,56,(ch+1)%10+48);
    lcd_str(0,64,msg44);
    if(size==ONE)lcd_asc(1,112,'1');
    if(size==TWO)lcd_asc(1,112,'2');
    if(size==THREE)lcd_asc(1,112,'3');
    if(size==FIVE)lcd_asc(1,112,'5');
    if(size==SEVEN)lcd_asc(1,112,'7');
    lcd_asc(1,120,'"');
    lcd_str(2,0,msg45);
    while(key()!=INVAILD);
    while(key()==INVAILD);
    while(key()!=INVAILD);
    lcd_cls(0,0,4,128);
    size_go();
    while(1){
        vol();
        switch(key()){
            case plus_key:plus();break;
            case dec_key:dec();break;
            case r_key:MODE=R;break;
            case g_key:MODE=G;break;
            case b_key:MODE=B;break;
            case d_key:MODE=D;break;
            case page_key:{MODE=PAGE;
                lcd_cls(0,0,4,128);
                lcd_str(0,0,msg22); /*页数设置*/
                lcd_str(2,0,msg23); /*总页数:*/
                nn=(sum_h*256+sum_l)/10000;
                lcd_asc(3,64,nn+48);
                nn=((sum_h*256+sum_l)/1000)%10;
                lcd_asc(3,72,nn+48);
                nn=((sum_h*256+sum_l)/100)%10;
                lcd_asc(3,80,nn+48);
                nn=((sum_h*256+sum_l)/10)%10;
                lcd_asc(3,88,nn+48);
                nn=(sum_h*256+sum_l)%10;
                lcd_asc(3,96,nn+48);
                while(key()==page_key);
                lcd_cls(0,0,4,128);
                break;
            }
            case ch_key:{
                lcd_cls(0,0,4,128);
                lcd_str(0,0,msg7);
                while(key()==ch_key);
                nn=key();
                while(nn!=ch_key){
                    if(ch==0){lcd_str(2,0,msg9);lcd_cls(2,64,4,128);}
                    if(ch==1){lcd_str(2,0,msg10);lcd_cls(2,64,4,128);}
                    if(ch==2){lcd_str(2,0,msg11);lcd_cls(2,64,4,128);}
                    if(ch==3)lcd_str(2,0,msg12);
                    if(ch==4){lcd_str(2,0,msg13);lcd_cls(2,80,4,128);}
                    if(ch==5){lcd_str(2,0,msg14);lcd_cls(2,64,4,128);}
                    if(ch==6){lcd_str(2,0,msg15);lcd_cls(2,64,4,128);}
                    if(ch==7){lcd_str(2,0,msg16);lcd_cls(2,64,4,128);}
                    if(ch==8){lcd_str(2,0,msg17);lcd_cls(2,96,4,128);}
                    if(ch==9)lcd_str(2,0,msg18);
                    delay(100);
                    nn=key();
                    if(nn==plus_key){
                        xx=ch;
                        if(xx<ch_max)xx++;
                        write(&ch,xx);
                    }
                    if(nn==dec_key){
                        xx=ch;
                        if(xx>0)xx--;
                        write(&ch,xx);
                    }
                    if(nn==uiji_key){
                        option();
                        break;
                    }
                    if(nn==d_key){
                        system_clipcation();
                        break;
                    }
                    if(nn==go_key){
                        Test();
                        break;
                    }
                    if(nn==size_key){
                        dvjc();
                        break;
                    }
                }
                lcd_cls(0,0,4,128);
                break;
            }
            case go_key:go();break;
            case uiji_key:{
                detect();
                lcd_cls(0,0,4,128);
                gotoxy(0,0);
                printf("RD:%d RF:%d",senr,fr);
                gotoxy(1,0);
                printf("GD:%d GF:%d",seng,fg);
                gotoxy(2,0);
                printf("BD:%d BF:%d",senb,fb);
                delay(500);
                while(key()!=INVAILD){};
                lcd_cls(0,0,4,128);
                break;
            }
            case feed_key:feed();break;
            case size_key:size_convert();break;
            case isxi_key:isxi();break;
        }
        display();
/*        if(ad_error)ad_init();*/
    }
}

/*中断服务程序
  1、时间累计
  2、A/D转换,判断上下限
  3、取键值,并累计次数*/
interrupt[0xb] void T0_int(void)
{
    TL0=timer%256;   /*重置定时器初值*/
    TH0=timer/256;
    time++;
    time_ad++;
    if(time_ad==0){
        if(ISXI){
            Iset(fan,ON);
            if(AD_use==0)dev_temp=ad_I(DEV);
            if(AD_use==0)fix_temp=ad_I(FIX);
            if(dev_temp<DEV_temp){
                Iset(dev_m,ON);
            }
                else {
                    Iset(dev_m,OFF);
                }
            if(fix_temp<FIX_temp){
                Iset(fix_m,ON);
            }
                else {
                    Iset(fix_m,OFF);
                }
            if(ISXI_GO){    /*充洗开始*/
                if(ISXI_OK){    /*已度过引带*/
                    if(paper){ /*到引带末端,冲洗结束*/
                        Iset(isxi_m,OFF);
                        Iset(fan,OFF);
                        ISXI=ISXI_GO=ISXI_OK=0;
                    }
                }
                else if(!paper)ISXI_OK=1;
            }
        }
        else{
            Iset(dev_m,OFF);
            Iset(fix_m,OFF);
        }
    }
    ad_count++;
    if(ad_count==100)ad_error=1;
}

unsigned int abs(int number)
{
    if(number<0)number=-number;
    return number;
}

/*  AD7715硬中断在INT0    */
/*  数字平均值滤波,然后进行稳定性判断   */
interrupt [0x3] void int0(void)
{
    unsigned char i;
    static char ff;
/*    if(ff>=5){*/
        result=read_ad_data();
        sum=sum+(unsigned long)result;
        sum=sum-(unsigned long)buffer[point];
        buffer[point]=result;
        point=(point==FILTER_TIMES-1)?0:point+1;
        result=sum/FILTER_TIMES;
        for(i=0;i<FILTER_TIMES;i++){
            if(abs((int)(result-buffer[i]))>20){
                useable=0;
                return;
            }
        }
        useable=1;
        ad_count=ad_error=0;
/*    }
    ff=(ff>=5)?0:ff+1;*/
}

