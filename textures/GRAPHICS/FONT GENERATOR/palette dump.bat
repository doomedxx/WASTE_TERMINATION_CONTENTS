@echo off
set PATH=..\..\bin\;%PATH%
cd progs\palettedump
wxlua .\script\palettedump.lua
