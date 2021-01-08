@echo off
c:\c-51\bin\c-51 %1 -ml -r0 -L -q -I\c-51\include\ -C -z
if NOT EXIST %1.r03 goto end:
c:\c-51\bin\xlink -c8051 -FAOMF8051 %1 \c-51\lib\cl8051l -f LNK -l %1.map -o %1.hex -xsme
if NOT EXIST %1.hex goto end:
oh %1.hex to %1.bin
:end
