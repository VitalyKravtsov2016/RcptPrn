@echo off
@set path="C:\Program Files (x86)\Borland\Delphi7\Bin";%path%
@set IncDir="C:\Program Files (x86)\Borland\Delphi7\Dcu"
@set BinDir="%CD%\Bin"
@set DcuDir="%CD%\Dcu"

del *.rsm /S /Q
del *.dcu /S /Q
del *.bak /S /Q
del %BinDir%\*.exe /Q
del %BinDir%\*.dll /Q

cd .\Source\RcptPrn
dcc32 -E%BinDir% -N%DcuDir% -Q RcptPrn.dpr
del %DcuDir%\*.dcu /Q
cd ..\..

ISCC Setup.iss
move .\Output\setup.exe RcptPrn_1.39.exe

rd Output
del *.dcu /S /Q
del %BinDir%\*.exe /Q
del %BinDir%\*.dll /Q