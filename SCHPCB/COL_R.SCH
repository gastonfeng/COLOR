*version 1.0 1876999290
lib C:\MSIM\abm.slb 0
lib C:\MSIM\analog.slb 2367066693
lib C:\MSIM\anlg_dev.slb 0
lib C:\MSIM\bipolar.slb 0
lib C:\MSIM\breakout.slb 0
lib C:\MSIM\burr_brn.slb 0
lib C:\MSIM\cd4000.slb 0
lib C:\MSIM\dig_1.slb 1709796238
lib C:\MSIM\dig_2.slb 0
lib C:\MSIM\dig_3.slb 0
lib C:\MSIM\dig_4.slb 0
lib C:\MSIM\dig_ecl.slb 0
lib C:\MSIM\dig_gal.slb 0
lib C:\MSIM\dig_misc.slb 0
lib C:\MSIM\dig_pal.slb 0
lib C:\MSIM\diode.slb 0
lib C:\MSIM\europe.slb 0
lib C:\MSIM\global.slb 0
lib C:\MSIM\harris.slb 0
lib C:\MSIM\jfet.slb 0
lib C:\MSIM\lin_tech.slb 0
lib C:\MSIM\marker.slb 0
lib C:\MSIM\misc.slb 0
lib C:\MSIM\mosfet.slb 0
lib C:\MSIM\opamp.slb 0
lib C:\MSIM\opto.slb 0
lib C:\MSIM\pwrbjt.slb 0
lib C:\MSIM\source.slb 0
lib C:\MSIM\special.slb 0
lib C:\MSIM\swit_rav.slb 0
lib C:\MSIM\swit_reg.slb 0
lib C:\MSIM\tex_inst.slb 0
lib C:\MSIM\thyristr.slb 0
lib C:\MSIM\xtal.slb 0
u 171
U? 2
R? 14
V? 2
@analysis
.DC 1 0 0 3 0 1
+ 0 0 R1
+ 0 1 RES
+ 0 2 RMOD
+ 0 3 R
+ 0 4 100
+ 0 5 6K
+ 0 6 100
+ 1 4 1
+ 1 5 60
+ 1 6 10
@attributes
@index
pageloc 1 0 3462 
@status
n 0 96:07:14:09:44:24;840041064 e 
s 0 96:07:14:09:44:39;840041079 e 
*page 1 0 970 720 iA
@ports
port  11 AGND 360 220 h
port  13 AGND 210 280 h
port  15 AGND 150 280 h
port  17 AGND 70 210 h
port  19 BUBBLE 360 160 h
a 1 s 14 0 0 0 hcn 100 LABEL=12V
port  21 BUBBLE 70 170 h
a 1 s 14 0 0 0 hcn 100 LABEL=12V
port  23 BUBBLE 150 60 h
a 1 s 14 0 0 0 hcn 100 LABEL=12V
port  25 BUBBLE 210 100 h
a 1 s 14 0 0 0 hcn 100 LABEL=12V
@parts
part  1 LM324 320 170 h
a 0 s 13 0 50 60 hcn 100 PART=LM324
a 0 a 13 0 50 10 hcn 100 refdes=U1
part  3 R 150 280 v
a 0 u 13 0 15 25 hln 100 value=1
a 1 x 9 0 15 0 hln 100 REFDES=R2
part  4 R 210 140 v
a 1 a 9 0 15 0 hln 100 REFDES=R3
a 0 u 13 0 15 25 hln 100 value=10K
part  5 R 210 280 v
a 0 u 13 0 15 25 hln 100 value=10k
a 1 x 9 0 15 0 hln 100 REFDES=R4
part  6 R 360 270 u
a 1 x 9 0 15 0 hln 100 REFDES=R5
a 0 u 13 0 15 25 hln 100 value=39k
part  7 POT 360 270 U
a 1 x 9 0 15 0 hln 100 REFDES=R6
a 0 u 13 0 0 20 hln 100 VALUE=20K
a 0 u 0 0 0 20 hln 100 SET=1
part  10 VSRC 70 170 h
a 1 u 0 0 0 0 hcn 100 DC=12V
a 1 x 9 0 20 10 hcn 100 refdes=V1
part  94 R 280 170 h
a 0 u 13 0 15 25 hln 100 value=10k
a 1 x 9 0 15 0 hln 100 REFDES=R8
part  96 R 280 210 h
a 0 u 13 0 15 25 hln 100 value=10k
a 1 x 9 0 15 0 hln 100 REFDES=R9
part  116 pot 150 100 d
a 0 u 13 0 0 20 hln 100 VALUE=1K
a 1 x 9 0 15 0 hln 100 REFDES=R10
a 0 u 0 0 0 20 hln 100 SET=0.4
part  130 r 150 100 v
a 0 u 13 0 15 25 hln 100 value=510
a 1 x 9 0 15 0 hln 100 REFDES=R11
part  153 r 150 210 v
a 1 a 9 0 25 44 hln 100 REFDES=R12
part  159 r 130 210 v
a 0 u 13 0 33 -5 hln 100 value=1.5k
a 1 x 9 0 15 0 hln 100 REFDES=R13
part  0 titleblk 970 720 h
a 1 s 13 0 350 10 hcn 100 PageSize=A
a 1 s 13 0 180 60 hcn 100 PageTitle=
a 1 s 13 0 300 95 hrn 100 PageNO=1
a 1 s 13 0 340 95 hrn 100 PageCount=1
@conn
w 28
a 0 s 3 0 152 190 hln 100 LABEL=1
s 150 170 150 140 152
a 0 s 3 0 176 166 hln 100 LABEL=1
s 280 170 150 170 148
a 0 s 3 0 215 168 hln 100 LABEL=1
s 150 170 130 170 160
w 38
a 0 s 3 0 0 0 hln 100 LABEL=2
s 210 140 210 210 108
s 210 210 210 240 115
s 210 210 280 210 112
a 0 s 3 0 255 208 hln 100 LABEL=2
w 46
s 320 210 320 270 67
w 72
s 360 270 360 250 71
s 360 250 380 250 75
w 79
a 0 s 3 0 430 188 hln 100 LABEL=OUT
s 400 270 400 190 78
s 400 190 460 190 82
a 0 s 3 0 430 188 hln 100 LABEL=OUT
w 120
s 150 100 130 100 119
s 130 100 130 120 123
w 156
s 150 210 150 240 155
w 165
s 130 210 130 280 164
s 130 280 150 280 167
@junction
j 210 280
+ s 13
+ p 5 1
j 150 280
+ s 15
+ p 3 1
j 70 210
+ s 17
+ p 10 -
j 70 170
+ s 21
+ p 10 +
j 210 100
+ s 25
+ p 4 2
j 210 140
+ p 4 1
+ w 38
j 210 240
+ p 5 2
+ w 38
j 320 210
+ p 1 -
+ w 46
j 320 270
+ p 6 2
+ w 46
j 360 270
+ p 6 1
+ w 72
j 360 270
+ p 7 1
+ w 72
j 380 250
+ p 7 t
+ w 72
j 400 190
+ p 1 5
+ w 79
j 400 270
+ p 7 2
+ w 79
j 360 220
+ p 1 V-
+ s 11
j 360 160
+ p 1 V+
+ s 19
j 360 270
+ p 6 1
+ p 7 1
j 320 170
+ p 94 2
+ p 1 +
j 320 210
+ p 96 2
+ p 1 -
j 320 210
+ p 96 2
+ w 46
j 280 210
+ p 96 1
+ w 38
j 210 210
+ w 38
+ w 38
j 150 140
+ p 116 2
+ w 28
j 150 100
+ p 116 1
+ w 120
j 130 120
+ p 116 t
+ w 120
j 150 100
+ p 130 1
+ p 116 1
j 150 100
+ p 130 1
+ w 120
j 150 60
+ s 23
+ p 130 2
j 280 170
+ p 94 1
+ w 28
j 150 170
+ p 153 2
+ w 28
j 150 240
+ p 3 2
+ w 156
j 150 210
+ p 153 1
+ w 156
j 130 170
+ p 159 2
+ w 28
j 130 210
+ p 159 1
+ w 165
j 150 280
+ p 3 1
+ w 165
j 150 280
+ s 15
+ w 165
@attributes
a 0 s 15 0 0 0 hln 100 PAGETITLE=
a 0 s 15 0 0 0 hln 100 PAGENO=1
a 0 s 15 0 0 0 hln 100 PAGESIZE=A
a 0 s 15 0 0 0 hln 100 PAGECOUNT=1
@text
