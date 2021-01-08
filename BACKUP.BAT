@echo off
arj u -r -gkeke c:\color.FFF \color
arj d c:\color.fff *.bak *.m51 *.hex *.obj *.lst *.map *.abk *.dft
:loop
if '%1'=='' goto end
copy c:\color.fff %1\/v
shift
goto loop
:end
echo BACKUP OK!!!
