/*getdot.c    3-6-95*/
/*汉字字模提取程序*/
#include<stdio.h>
#include<conio.h>
  FILE *fpi,*fpo,*fphzk;
  unsigned char buf[32],a,c,zz[9999];
  int pi,i,h,num,j,flag=0;
  long l;

main(int argc,char *argv[])
{
 printf("汉字字模提取程序V1.0\n");
 printf("JTSOFT. 3/6/95\n");
 if (argc<2)
   {printf("输入文件名：");
    scanf("%s",argv[1]);
    }
 if (argc<3)
   {printf("输出文件名:");
    scanf("%s",argv[2]);
    }
 if((fpi=fopen(argv[1],"r"))==NULL)
   {printf("输入文件打不开!\n");
    exit(0);
    }
 if((fphzk=fopen("hzk16","rb"))==NULL)
   {printf("HZK16 汉字库不存在!!!\n");
    exit(0);
   }
 if((fpo=fopen(argv[2],"w"))==NULL)
   {printf("不能建立输出文件!!!");
    exit(0);
   }
 num=1;
 while(!feof(fpi))
   {if((a=getc(fpi))>=0xa0)
     {c=getc(fpi);
     if(feof(fpi))exit(0);
     for(j=1;j<=(num-1)*2;j+=2)
     {
      if(zz[j]==a)
	if(zz[j+1]==c)
	{flag=1;
	break;}
      }
      if(flag==0){
      zz[num*2-1]=a;zz[num*2]=c;
      l=((a-0xa1)&0x7f)*94+((c-0xa1)&0x7f);
      fseek(fphzk,l*32L,SEEK_SET);
      fread(buf,1,32,fphzk);
      fprintf(fpo,"HZ%d:  db ",num);
      for(i=0;i<31;i++)fprintf(fpo,"%03xH,",buf[i]);
      fprintf(fpo,"%03xH",buf[31]);
      fprintf(fpo,"    ;%c%c",a,c);
      putc(0x0a,fpo);
      num++;
     }
   }
   flag=0;
   }
       fclose(fpo);
       fclose(fphzk);
       fclose(fpi);
}

