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
        dw hz102,hz22,hz99,hz27,hz100,hz101,0;药液温度过高
msg29:
        dw hz103,hz104,hz104,hz105,hz106,hz104,hz104,hz105,0;ⅰⅲⅲ℃¤℃
msg30:
        dw ;调试程序
msg31:
        dw ;请输入张数
msg32:
        dw ;请输入步长
msg33:
        dw ;请输入预定量
