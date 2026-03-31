@echo off
chcp 65001 >nul
REM ============================================================
REM GenP 构建启动脚本 (run_build.bat) - 中文注释学习版
REM 功能: 以管理员权限启动PowerShell构建脚本(build.ps1)
REM ============================================================

REM 通过 net session 命令检测是否拥有管理员权限
REM 非管理员执行此命令会返回错误码
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    ECHO 此脚本需要管理员权限才能运行。
    ECHO 请右键点击此文件并选择"以管理员身份运行"。
    ECHO 按任意键退出 . . .
    pause >nul
    exit /b 1
)

REM 以Bypass执行策略运行PowerShell构建脚本
REM %%~dp0 表示当前批处理文件所在的目录路径
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %ERRORLEVEL% neq 0 (
    ECHO 构建失败。请检查上方的错误信息。
    ECHO 按任意键退出 . . .
    pause >nul
    exit /b 1
)

ECHO 按任意键退出 . . .
pause >nul
exit /b 0