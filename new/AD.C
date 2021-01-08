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

#define DELAY_SCALE 115
#define MAX_POINT   30
/*数据寄存器定义*/
char outa,outb;
unsigned char page,MODE,time_ad,point_number;  /*曝光张数,加减模式*/
unsigned int r_time,g_time,b_time,point;   /*红.绿.蓝曝光时间,计时时钟*/
unsigned int time;
unsigned char dev_temp,fix_temp,ac;
char ADKEY;                                        /*AD7715通讯寄存器内容  */
bit AD,ISXI,ISXI_GO,ISXI_OK;   /*冲洗,补偿操作标志*/
bit ad_BUSY=0xb3;

#pragma memory=xdata
unsigned char ch;/*通道号*/
unsigned char DEV_temp,FIX_temp,DRY_temp;
unsigned char size;  /*镜头.片框位置:0-1";1-5";2-7"*/
unsigned char sum_h,sum_l;    /*总张数累计*/
unsigned char key_point[10][3][MAX_POINT]; /*关键点数据*/
unsigned char tab[10][3][512];
#pragma memory=default

error(int no);
lcd_asc(char x,char y,char dot);
delay(int time);

init()
{
    outporta=outportb=0;
    TL0=timer%256;
    TH0=timer/256;
    TMOD=1;
    ET0=1;
    PT0=1;
    EA=1;
    TR0=1;
    AD=0;
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

write_ad(char command)
{
    char i;
    for(i=0;i<8;i++){
        set(sclk,0);
        if((command>>(7-i))&0x1)set(din,1);
        else set(din,0);
        set(sclk,1);
    }
}

char read_ad_res()
{
    char i,j=0;
    for(i=0;i<8;i++){
        j=j<<1;
        set(sclk,0);
        if(dout)j|=1;
        else j&=0xfe;
        set(sclk,1);
    }
    return j;
}

int read_ad_data()
{
    union{
        int j;
        char a[2];
    }c;
    char i;
    do{
        write_ad(ADKEY|READ);
        i=read_ad_res();
    }while((i&0x80)!=0);
    write_ad(ADKEY|0x30|READ);
    c.a[0]=read_ad_res();
    c.a[1]=read_ad_res();
    return c.j;
}

int ad_filter()
{
    unsigned long sum=0;
    char i;
    for(i=0;i<1;i++){
        sum+=read_ad_data();
    }
    return sum/1;
}

set_ad(char gain)
{
    char nn;
    if(gain==COLOR){
        ADKEY=3;                       /*增益设置到128*/
    }
    else{
        ADKEY=2;                       /*增益设置到32*/
    }
    write_ad(ADKEY|SETUP|W);
    write_ad(0x44);             /*写AD7715设置寄存器,自校准,最大更新速率,单极性工作,带输入缓冲*/
    do{
        write_ad(ADKEY|READ);
        nn=read_ad_res();
    }while((nn&0x80)!=0);       /*等待自校准完毕*/
    delay(200);
}

delay(int time)
{
    int i;
    unsigned char j;
    for(i=0;i<time;i++)for(j=0;j<DELAY_SCALE;j++);
}

lcd_error()
{
    outporta=outportb=0;
    while(1){
        sound=~sound;
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
lcd_char(char x,char y,char dot)  /*页地址,Y地址,字符点阵数组*/
{
    unsigned char i;
    if(y>63){           /*若Y>64,在后64列操作*/
        T1=1;
        y=y&0x3f;
    }
    else T1=0;
    lcd_int();
    lcd_set=x|0xb8;     /*页地址设置*/
    lcd_int();
    lcd_set=y|0x40;
    for(i=0;i<16;i++){
        lcd_int();
        lcd_data=*(HZ+(dot-1)*32+i);
    }
    lcd_int();
    lcd_set=(x+1)|0xb8;
    lcd_int();
    lcd_set=y|0x40;
    for(i=16;i<32;i++){
        lcd_int();
        lcd_data=*(HZ+(dot-1)*32+i);
    }
    lcd_int();
    lcd_set=0xc0;
}

/*单个英文字符显示*/
lcd_asc(char x,char y,char dot)
{
    unsigned char i;
    if(y>63){           /*若Y>64,在后64列操作*/
        T1=1;
        y=y&0x3f;
    }
    else T1=0;
    lcd_int();
    lcd_set=x|0xb8;     /*页地址设置*/
    lcd_int();
    lcd_set=y|0x40;
    for(i=0;i<8;i++){
        lcd_int();
        lcd_data=*(ASCII+dot*8+i);
    }
    lcd_int();
    lcd_set=0xc0;
}

/*字符串显示子程序*/
lcd_str(unsigned char x,unsigned char y,unsigned char string[])
{
    unsigned char i;
    for(i=0;i<8;i++){
        if(string[i]==0)break;
        lcd_char(x,y+16*i,string[i]);
    }
}

error(int no)
{
    EA=0;
    outporta=outportb=0;
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg48);
    lcd_asc(3,0,no/1000+'0');
    lcd_asc(3,8,(no/100)%10+'0');
    lcd_asc(3,16,(no/10)%10+'0');
    lcd_asc(3,24,no%10+'0');
    sound=0;
    exit();
}

/*a/d转换*/
unsigned char ad(char ch)
{
    unsigned char i;
    AD=1;
    ad_port[ch]=0;
    delay(1);
    for(i=0;i<255;i++){
        if(ad_BUSY==1)goto ad_ok;
        delay(1);
    }
    error(AD_TIMEOUT);
ad_ok:
    i=ad_port[ch];
    AD=0;
    return i;
}

unsigned char ad_I(char ch)
{
    unsigned char i;
    AD=1;
    ad_port[ch]=0;
    for(i=0;i<255;i++);
    for(i=0;i<255;i++)if(ad_BUSY==1)goto ad_ok;
    error(AD_TIMEOUT);
ad_ok:
    i=ad_port[ch];
    AD=0;
    return i;
}

write(char *address,char byte)
{
    char dd;
    *address=byte;
    for(dd=0;dd<20;dd++)if(*address==byte)return;
    error(MEM_WRITE_FAULT);
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
    lcd_asc(0,0,'R');
    lcd_asc(0,8,':');
    lcd_asc(0,16,(r_time/1000)%10+48);
    lcd_asc(0,24,(r_time/100)%10+48);
    lcd_asc(0,32,'.');
    lcd_asc(0,40,(r_time/10)%10+48);
    lcd_asc(0,48,r_time%10+48);
    lcd_asc(0,56,'S');

    lcd_asc(1,0,'G');
    lcd_asc(1,8,':');
    lcd_asc(1,16,(g_time/1000)%10+48);
    lcd_asc(1,24,(g_time/100)%10+48);
    lcd_asc(1,32,'.');
    lcd_asc(1,40,(g_time/10)%10+48);
    lcd_asc(1,48, g_time%10+48);
    lcd_asc(1,56,'S');

    lcd_asc(2,0,'B');
    lcd_asc(2,8,':');
    lcd_asc(2,16,(b_time/1000)%10+48);
    lcd_asc(2,24,(b_time/100)%10+48);
    lcd_asc(2,32,'.');
    lcd_asc(2,40,(b_time/10)%10+48);
    lcd_asc(2,48, b_time%10+48);
    lcd_asc(2,56,'S');

    lcd_asc(3,0,'D');
    lcd_asc(3,8,':');
    lcd_asc(3,16,'N');

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

t_g_dis()
{
    lcd_asc(1,0,'G');
    lcd_asc(1,8,':');
    lcd_asc(1,64,(g_time/1000)%10+48);
    lcd_asc(1,72,(g_time/100)%10+48);
    lcd_asc(1,80,'.');
    lcd_asc(1,88,(g_time/10)%10+48);
    lcd_asc(1,96,g_time%10+48);
    lcd_asc(1,104,'S');
}

t_r_dis()
{
    lcd_asc(0,0,'R');
    lcd_asc(0,8,':');
    lcd_asc(0,64,(r_time/1000)%10+48);
    lcd_asc(0,72,(r_time/100)%10+48);
    lcd_asc(0,80,'.');
    lcd_asc(0,88,(r_time/10)%10+48);
    lcd_asc(0,96,r_time%10+48);
    lcd_asc(0,104,'S');
}

t_b_dis()
{
    lcd_asc(2,0,'B');
    lcd_asc(2,8,':');
    lcd_asc(2,64,(b_time/1000)%10+48);
    lcd_asc(2,72,(b_time/100)%10+48);
    lcd_asc(2,80,'.');
    lcd_asc(2,88,(b_time/10)%10+48);
    lcd_asc(2,96,b_time%10+48);
    lcd_asc(2,104,'S');
}

p_dis()
{
    lcd_asc(3,112,(point+1)/10+48);
    lcd_asc(3,120,(point+1)%10+48);
}

t_uiji()
{
    unsigned char r1,r2,r3,r4,r5;
    set(filter,ON);
    set(b_m,ON);
    delay(DELAY);
    r1=ad(b_light);
    r2=ad(b_light);
    r3=ad(b_light);
    r4=ad(b_light);
    r5=ad(b_light);
    t_b_dis();
    set(g_m,ON);
    delay(DELAY);
    set(b_m,OFF);

    delay(DELAY);
    r1=ad(g_light);
    r2=ad(g_light);
    r3=ad(g_light);
    r4=ad(g_light);
    r5=ad(g_light);
    t_g_dis();
    set(r_m,ON);
    delay(DELAY);
    set(g_m,OFF);
    set(filter,OFF);

    delay(DELAY);
    r1=ad(r_light);
    r2=ad(r_light);
    r3=ad(r_light);
    r4=ad(r_light);
    r5=ad(r_light);
    t_r_dis();
    delay(DELAY);
    set(r_m,OFF);

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
    set_ad(COLOR);
    while(key()==go_key);
    while(key()!=go_key){
        if(key()==r_key){
            set(filter,OFF);
            set(r_m,ON);
            while(key()==r_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg34);
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
            }
            set(r_m,OFF);
        }
        if(key()==g_key){
            set(filter,ON);
            set(g_m,ON);
            while(key()==g_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg35);
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
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
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
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
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
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
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
            }
            set(b_m,OFF);
            set(r_m,OFF);
        }
        if(key()==isxi_key){
            set(r_m,ON);
            set(g_m,ON);
            while(key()==isxi_key);
            while(key()==INVAILD){
                lcd_str(2,0,msg36);
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
            }
            set(r_m,OFF);
            set(g_m,OFF);
        }
        if(key()==uiji_key){
            lcd_cls(2,0,4,128);
            set_ad(!COLOR);
            set(r_m,OFF);
            set(g_m,OFF);
            set(b_m,OFF);
            set(filter,OFF);
            while(key()==uiji_key);
            while(key()==INVAILD){
                aa=ad_filter();
                lcd_asc(3,64,(aa/10000)+48);
                lcd_asc(3,72,((aa/1000)%10)+48);
                lcd_asc(3,80,((aa/100)%10)+48);
                lcd_asc(3,88,((aa/10)%10)+48);
                lcd_asc(3,96,(aa%10)+48);
            }
            set_ad(COLOR);
        }
    }
    while(key()==go_key);
}

/*加操作*/
plus()
{
    unsigned char i;
        switch(MODE){
            case R:if(r_time<9999)r_time++;break;
            case G:if(g_time<9999)g_time++;break;
            case B:if(b_time<9999)b_time++;break;
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
            case R:if(r_time>1)r_time--;break;
            case G:if(g_time>1)g_time--;break;
            case B:if(b_time>1)b_time--;break;
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


/*试机*/
uiji()
{
    unsigned char r1,r2,r3,r4,r5,r6;
    set(filter,ON);
    set(b_m,ON);
    delay(DELAY);
    r1=ad(b_light);
    r2=ad(b_light);
    r3=ad(b_light);
    r6=ad(b_light);
    r5=ad(b_light);
    r4=(r1+r2+r3+r6+r5)/5;
    b_time=tab[ch][B][r4*2]*256+tab[ch][B][r4*2+1];
    set(g_m,ON);
    delay(DELAY);
    set(b_m,OFF);
    display();

    delay(DELAY);
    r1=ad(g_light);
    r2=ad(g_light);
    r3=ad(g_light);
    r6=ad(g_light);
    r5=ad(g_light);
    r4=(r1+r2+r3+r6+r5)/5;
    g_time=tab[ch][G][r4*2]*256+tab[ch][G][r4*2+1];
    display();
    set(r_m,ON);
    delay(DELAY);
    set(g_m,OFF);
    set(filter,OFF);

    delay(DELAY);
    r1=ad(r_light);
    r2=ad(r_light);
    r3=ad(r_light);
    r6=ad(r_light);
    r5=ad(r_light);
    r4=(r1+r2+r3+r6+r5)/5;
    r_time=tab[ch][R][r4*2]*256+tab[ch][R][r4*2+1];
    display();
    set(r_m,OFF);

}

/*曝光操作*/
go()
{
    for(;page>=1;page--){
        display();
        set(b_m,ON);
        set(filter,ON);
        delay(DELAY);
        set(door,ON);
        time=0;
        while(time<b_time){
            lcd_asc(2,16,(b_time-time)/1000+48);
            lcd_asc(2,24,((b_time-time)/100)%10+48);
            lcd_asc(2,40,((b_time-time)/10)%10+48);
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
            lcd_asc(1,16,(g_time-time)/1000+48);
            lcd_asc(1,24,((g_time-time)/100)%10+48);
            lcd_asc(1,40,((g_time-time)/10)%10+48);
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
            lcd_asc(0,16,(r_time-time)/1000+48);
            lcd_asc(0,24,((r_time-time)/100)%10+48);
            lcd_asc(0,40,((r_time-time)/10)%10+48);
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
                sound=0;
                delay(10);
                sound=1;
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
        sound=0;
        delay(50);
        lcd_cls(0,0,4,128);
        if(i==0)lcd_str(0,0,msg49);
        if(j==0)lcd_str(2,0,msg50);
        sound=1;
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


main()
{
    unsigned char nn,xx;
    init();
    time=0;
    while(time<20);
    ISXI=0;
    ISXI_GO=ISXI_OK=0;
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
    while(time<500);
    r_time=g_time=b_time=1000;
    page=1;
    MODE=0xff;
    if(size>4){
        xx=size%5;
        size=xx;
        while(size!=xx);
    }
    if(ch>10){
        xx=ch%10;
        ch=xx;
        while(ch!=xx);
    }
    if(lip()){
        lcd_cls(0,0,4,128);
        lcd_str(0,0,msg46);
        lcd_str(2,0,msg47);
        time=0;
        while(time<500){
            if(key()==isxi_key){
                ISXI=0;
                break;
            }
        ISXI=1;
        }
    }
    lcd_cls(0,0,4,128);
    lcd_str(0,0,msg41);
    lcd_str(2,0,msg42);
    time=0;
    while(time<60000){
        lcd_asc(1,88,((60000-time)/6000)%10+48);
        lcd_asc(1,96,':');
        lcd_asc(1,104,((60000-time)%6000)/1000+48);
        lcd_asc(1,112,(((60000-time)%6000)/100)%10+48);
        if(key()==page_key)break;
    }
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
            case uiji_key:uiji();break;
            case feed_key:feed();break;
            case size_key:size_convert();break;
            case isxi_key:isxi();break;
        }
        display();
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
            if(AD==0)dev_temp=ad_I(DEV);
            if(AD==0)fix_temp=ad_I(FIX);
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
}
