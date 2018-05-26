@echo off
set PATH=..\..\bin\;..\..\util\;%PATH%
cd progs\doompicdump
start /B wxlua .\script\doompicdump.lua 
