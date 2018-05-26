@echo off
set PATH=..\..\bin\;..\..\util\;%PATH%
cd progs\doomfontgen
wxlua .\script\doomfontgen.lua
