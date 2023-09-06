@echo off
@set path=C:\Program Files\Borland\Delphi7\Bin;%path%
@set IncDir="C:\Program Files\Borland\Delphi7\Dcu"
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

signtool sign /tr http://rfc3161timestamp.globalsign.com/advanced /td sha256 /fd sha256 /n "SHTRIH-M JSC" %BinDir%\RcptPrn.exe

ISCC Setup.iss
signtool sign /tr http://rfc3161timestamp.globalsign.com/advanced /td sha256 /fd sha256 /n "SHTRIH-M JSC" .\Output\setup.exe
move .\Output\setup.exe RcptPrn_1.37.exe

rd Output
del *.dcu /S /Q
del %BinDir%\*.exe /Q
del %BinDir%\*.dll /Q