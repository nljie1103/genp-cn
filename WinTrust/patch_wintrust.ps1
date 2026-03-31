<#
  WinTrust DLL 补丁脚本 (patch_wintrust.ps1) - 中文注释学习版
  功能: 修改wintrust.dll中的特定字节，绕过Windows数字签名验证
  致谢: Team V.R

  原理说明:
  wintrust.dll 是Windows系统中负责验证文件数字签名的核心DLL
  通过修改偏移量0x1C86-0x1C87处的字节为 0x33 0xC0 (即x86汇编 xor eax,eax)
  使签名验证函数始终返回0(成功)，从而跳过签名检查
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot                                  # 当前脚本所在目录
$winTrustSource = Join-Path $scriptDir "wintrust.dll"      # 原版wintrust.dll路径
$winTrustPatched = Join-Path $scriptDir "wintrust.dll.patched"  # 补丁后输出文件路径

# 函数: Test-ExecutionPolicy - 检查PowerShell执行策略
function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Warning "Current execution policy ($policy) may prevent running this script."
        Write-Host "To allow running scripts, you can set the execution policy to RemoteSigned or Bypass."
        Write-Host "Run this command in an elevated PowerShell prompt:"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
        Write-Host "Alternatively, run this script with: powershell.exe -ExecutionPolicy Bypass -File .\patch.ps1"
        exit 1
    }
}

# 函数: Test-FileAccess - 检查文件是否存在且可写
function Test-FileAccess {
    param (
        [string]$Path,
        [string]$Description
    )
    if (-not (Test-Path $Path)) {
        Write-Error "$Description not found at $Path"
        exit 1
    }
    try {
        [System.IO.File]::OpenWrite($Path).Close()
    }
    catch {
        Write-Error "Cannot write to $Description at $Path. Ensure you have permissions or run as Administrator."
        exit 1
    }
}

Test-ExecutionPolicy

Test-FileAccess -Path $winTrustSource -Description "wintrust.dll"

try {
    # 复制原文件作为补丁基础（不修改原文件）
    Copy-Item -Path $winTrustSource -Destination $winTrustPatched -Force
}
catch {
    Write-Error "Failed to copy wintrust.dll to wintrust.dll.patched: $_"
    exit 1
}

try {
    # 读取DLL的全部字节到内存中
    $bytes = [System.IO.File]::ReadAllBytes($winTrustPatched)
    # 将偏移0x1C86处的字节改为0x33 (xor指令的操作码)
    $bytes[0x1C86] = 0x33
    # 将偏移0x1C87处的字节改为0xC0 (eax,eax操作数)
    # 合起来 0x33 0xC0 = "xor eax, eax" = 将返回值清零(表示验证通过)
    $bytes[0x1C87] = 0xC0
    [System.IO.File]::WriteAllBytes($winTrustPatched, $bytes)
}
catch {
    Write-Error "Failed to patch wintrust.dll.patched: $_"
    exit 1
}