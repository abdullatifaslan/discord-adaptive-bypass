@echo off
title Discord Adaptive Bypass Engine
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0discord_fix.ps1"