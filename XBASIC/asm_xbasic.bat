@echo off
set NAME=XBASIC
ZMAC --zmac %NAME%.ASM -P0=4 --od . --oo .500.CAS,LST,BDS
if errorlevel 1 goto :eof
move XBASIC.500.CAS XBASIC.CAS
run_xbasic.bat
