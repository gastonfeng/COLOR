set C51INC=\pk51\inc
set C51LIB=\pk51\lib
\pk51\bin\c51 %1.c define(franklin) rom(large) large debug
\pk51\bin\l51 %1.obj
