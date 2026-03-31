<#
构建 GenP - 中文注释学习版
需要管理员权限运行
运行方式: .\build.ps1 或通过 run_build.bat 启动
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- 默认路径配置 - 根据需要自定义 ---
$installBaseDir = Join-Path $env:SystemDrive "GenP-BuildEnv"    # 构建环境根目录（如 C:\GenP-BuildEnv）
$autoItInstallDir = Join-Path $installBaseDir "AutoIt"              # AutoIt安装目录
$autoItCoreExe = Join-Path $autoItInstallDir "install\AutoIt3_x64.exe"  # AutoIt主程序路径
$sciteInstallDir = Join-Path $autoItInstallDir "install\SciTE"    # SciTE编辑器目录
$wrapperScript = Join-Path $sciteInstallDir "AutoIt3Wrapper\AutoIt3Wrapper.au3"  # 编译封装脚本
$scriptDir = $PSScriptRoot                                          # 当前脚本所在目录
$genpDir = Join-Path $scriptDir "GenP"                            # GenP源码目录
$logsDir = Join-Path $scriptDir "Logs"                            # 日志输出目录
$releaseDir = Join-Path $scriptDir "Release"                      # 编译输出目录
$upxDir = Join-Path $scriptDir "UPX"                              # UPX压缩工具目录
$winTrustDir = Join-Path $scriptDir "WinTrust"                  # WinTrust补丁目录
$autoItZipPath = Join-Path $scriptDir "autoit-v3.zip"
$sciTEZipPath = Join-Path $scriptDir "SciTE4AutoIt3_Portable.zip"
$logPath = Join-Path $logsDir "build.log"                        # 构建日志文件路径
$upxExe = Join-Path $genpDir "upx.exe"
$winTrustDll = Join-Path $genpDir "wintrust.dll"

if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $releaseDir)) {
    New-Item -Path $releaseDir -ItemType Directory -Force | Out-Null
}

# --- 下载URL - 根据需要更新 ---
$autoItUrl = "https://www.autoitscript.com/files/autoit3/autoit-v3.zip"
$sciTEUrl = "https://www.autoitscript.com/autoit3/scite/download/SciTE4AutoIt3_Portable.zip"

$winTrustStockHash = "1B3BF770D4F59CA883391321A21923AE"      # 原版wintrust.dll的MD5哈希值
$winTrustPatchedHash = "B7A38368A52FF07D875E6465BD7EE26A"  # 补丁后wintrust.dll的MD5哈希值

Start-Transcript -Path $logPath -Append -NoClobber | Out-Null

# 函数: Test-Admin - 检查当前是否以管理员权限运行
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 函数: Test-ExecutionPolicy - 检查PowerShell执行策略是否允许运行脚本
function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Warning "当前执行策略 ($policy) 可能会阻止此脚本运行。"
        Write-Host "请在管理员PowerShell中运行以下命令:"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"  # 此命令无需翻译
        Write-Host "或者直接使用 run_build.bat 来运行此脚本。"
        Stop-Transcript | Out-Null
        exit 1
    }
}

# 函数: Get-MD5Hash - 计算文件的MD5哈希值（用于验证文件完整性）
function Get-MD5Hash {
    param ([string]$filePath)
    if (-not (Test-Path $filePath)) { return $null }
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath))).Replace("-", "").ToUpper()
    return $hash
}

# 函数: Get-UserConfirmation - 显示提示并获取用户确认(y/n)
function Get-UserConfirmation {
    param ([string]$Prompt)
    Write-Host $Prompt
    $response = Read-Host "输入 'y' 继续，'n' 取消"
    return $response -eq 'y' -or $response -eq 'Y'
}

# 函数: Download-File - 下载文件（先尝试curl，失败后用WebClient）
function Download-File {
    param (
        [string]$Url,
        [string]$Destination
    )
    $success = $false
    $errorMessage = ""

    try {
        $curl = "curl.exe"
        if (Get-Command $curl -ErrorAction SilentlyContinue) {
            & $curl -L -o "$Destination" "$Url" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" --silent --show-error --connect-timeout 30
            if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) {
                $success = $true
            }
            else {
                $errorMessage = "curl下载失败，退出码: $LASTEXITCODE"
            }
        }
    }
    catch {
        $errorMessage = "curl错误: $_"
    }

    if (-not $success) {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
            $wc.DownloadFile($Url, $Destination)
            if (Test-Path $Destination) {
                $success = $true
            }
            else {
                $errorMessage = "WebClient下载完成但文件未找到"
            }
        }
        catch {
            $errorMessage = "WebClient错误: $_"
        }
    }

    if (-not $success) {
        Write-Error "下载失败: $Url -> $Destination - $errorMessage"
        Stop-Transcript | Out-Null
        exit 1
    }
}

# --- 步骤1: 环境检查 ---
Test-ExecutionPolicy    # 检查执行策略

# 检查管理员权限
if (-not (Test-Admin)) {
    Write-Error "此脚本必须以管理员身份运行。请右键点击 run_build.bat 并选择'以管理员身份运行'。"
    Stop-Transcript | Out-Null
    exit 1
}

if (-not (Test-Path $genpDir)) {
    Write-Error "未找到GenP目录: $genpDir"
    Stop-Transcript | Out-Null
    exit 1
}
if (-not (Test-Path $upxDir)) {
    Write-Error "未找到UPX目录: $upxDir"
    Stop-Transcript | Out-Null
    exit 1
}
if (-not (Test-Path $winTrustDir)) {
    Write-Error "未找到WinTrust目录: $winTrustDir"
    Stop-Transcript | Out-Null
    exit 1
}

# --- 检查各组件是否已就绪 ---
$hasAutoIt = Test-Path $autoItCoreExe       # AutoIt编译器是否存在
$hasSciTE = Test-Path $wrapperScript           # SciTE编译封装是否存在
$hasUpx = Test-Path $upxExe                     # UPX压缩工具是否存在
$hasWinTrust = Test-Path $winTrustDll           # wintrust.dll是否存在
$winTrustStatus = if ($hasWinTrust) {
    $hash = Get-MD5Hash $winTrustDll
    if ($hash -eq $winTrustPatchedHash) { "patched" }
    elseif ($hash -eq $winTrustStockHash) { "stock" }
    else { "unknown" }
} else { "missing" }

Write-Host "开始构建流程..." -ForegroundColor Magenta

if ($hasUpx) {
    Write-Host " - 已在 $genpDir\ 找到upx.exe，跳过UPX准备步骤" -ForegroundColor Green
}
if ($hasWinTrust -and $winTrustStatus -eq "patched") {
    Write-Host " - 已在 $genpDir\ 找到wintrust.dll（已补丁），跳过补丁步骤" -ForegroundColor Green
}
elseif ($hasWinTrust -and $winTrustStatus -eq "unknown") {
    Write-Warning "wintrust.dll 的MD5哈希值未知: $genpDir\" -ForegroundColor Yellow
    if (-not (Get-UserConfirmation -Prompt "是否继续使用当前的wintrust.dll？(y/n)")) {
        Write-Error "用户选择不使用未知的wintrust.dll，已取消。"
        Stop-Transcript | Out-Null
        exit 1
    }
}
if ($hasAutoIt) {
    Write-Host " - 已在 $autoItInstallDir\ 找到AutoIt，跳过下载" -ForegroundColor Green
}
if ($hasSciTE) {
    Write-Host " - 已在 $sciteInstallDir\ 找到SciTE，跳过下载" -ForegroundColor Green
}

$downloadsNeeded = @()
if (!$hasAutoIt) { $downloadsNeeded += "AutoIt Portable (~17MB)" }
if (!$hasSciTE) { $downloadsNeeded += "SciTE Portable (~7MB)" }

if ($downloadsNeeded.Count -gt 0) {
    Write-Host "以下组件缺失，需要下载:" -ForegroundColor Yellow
    $downloadsNeeded | ForEach-Object { Write-Host " - $_" }
    if (-not (Get-UserConfirmation -Prompt "是否下载以上组件？(y/n)")) {
        Write-Host "操作已被用户取消。"
        Stop-Transcript | Out-Null
        exit 0
    }
}

if (-not (Test-Path $installBaseDir)) {
    Write-Host ""
    Write-Host "正在创建安装目录: $installBaseDir..." -ForegroundColor Cyan
    New-Item -Path $installBaseDir -ItemType Directory -Force | Out-Null
}

if (!$hasUpx) {
    Write-Host ""
    Write-Host "--- 步骤2: 准备UPX压缩工具 ---" -ForegroundColor Cyan
    Write-Host "正在准备UPX..." -ForegroundColor Cyan
    try {
        $upxExtractedDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx-.*-win64$' } | Select-Object -First 1
        if (-not $upxExtractedDir) {
            $upxZip = Get-ChildItem -Path $upxDir -File | Where-Object { $_.Name -match '^upx-.*-win64\.zip$' } | Select-Object -First 1
            if (-not $upxZip) {
                Write-Error "在 $upxDir 中未找到UPX解压目录或zip文件。"
                Stop-Transcript | Out-Null
                exit 1
            }
            Write-Host " - 正在解压: $($upxZip.Name)"
            
            $tarExe = "tar.exe"
            $extracted = $false
            if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
                $tarOutLog = Join-Path $logsDir "tar_out.log"
                $tarErrLog = Join-Path $logsDir "tar_err.log"
                $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$($upxZip.FullName)`" -C `"$upxDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
                if ($process.ExitCode -eq 0) {
                    $extracted = $true
                }
                else {
                    Write-Warning "tar.exe解压 $($upxZip.Name) 失败，查看 $tarErrLog。回退使用Expand-Archive。"
                }
            }
            
            if (-not $extracted) {
                $unzipErrLog = Join-Path $logsDir "unzip_err.log"
                Expand-Archive -Path $upxZip.FullName -DestinationPath $upxDir -Force -ErrorAction Stop 2> $unzipErrLog
            }
            
            $upxExtractedDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx-.*-win64$' } | Select-Object -First 1
            if (-not $upxExtractedDir) {
                Write-Error "解压后在 $upxDir 中未找到UPX目录。"
                Stop-Transcript | Out-Null
                exit 1
            }
        }
        $upxExtractedDir = $upxExtractedDir.FullName
        Write-Host " - 找到UPX目录: $upxExtractedDir"
        
        $upxExe = Join-Path $upxExtractedDir "upx.exe"
        if (-not (Test-Path $upxExe)) {
            Write-Error "未找到UPX可执行文件: $upxExe"
            Stop-Transcript | Out-Null
            exit 1
        }
        
        Copy-Item -Path $upxExe -Destination $genpDir -Force
        Write-Host " - UPX已复制到 $genpDir" -ForegroundColor Green
    }
    catch {
        Write-Error "准备UPX失败: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if ($hasWinTrust -and $winTrustStatus -eq "patched") {
} elseif (!$hasWinTrust -or $winTrustStatus -eq "stock" -or $winTrustStatus -eq "unknown") {
    Write-Host ""
    Write-Host "--- 步骤3: 补丁wintrust.dll ---" -ForegroundColor Cyan
    Write-Host "正在补丁wintrust.dll..." -ForegroundColor Cyan
    try {
        $patchScript = Join-Path $winTrustDir "patch_wintrust.ps1"
        $winTrustSource = Join-Path $winTrustDir "wintrust.dll"
        if (-not (Test-Path $patchScript)) {
            Write-Error "在 $winTrustDir 中未找到 patch_wintrust.ps1"
            Stop-Transcript | Out-Null
            exit 1
        }
        if (-not (Test-Path $winTrustSource)) {
            Write-Error "在 $winTrustDir 中未找到 wintrust.dll"
            Stop-Transcript | Out-Null
            exit 1
        }
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$patchScript`"" -WorkingDirectory $winTrustDir -Wait -NoNewWindow
        $winTrustPatched = Join-Path $winTrustDir "wintrust.dll.patched"
        if (-not (Test-Path $winTrustPatched)) {
            Write-Error "补丁操作后在 $winTrustDir 中未找到 wintrust.dll.patched"
            Stop-Transcript | Out-Null
            exit 1
        }
        Move-Item -Path $winTrustPatched -Destination $winTrustDll -Force
        Write-Host " - wintrust.dll已补丁并移动到 $genpDir" -ForegroundColor Green
    }
    catch {
        Write-Error "补丁或移动wintrust.dll失败: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasAutoIt) {
    Write-Host ""
    Write-Host "--- 步骤4: 下载AutoIt编译器 ---" -ForegroundColor Cyan
    Write-Host "正在下载AutoIt便携版..." -ForegroundColor Cyan
    try {
        Download-File -Url $autoItUrl -Destination $autoItZipPath
        Write-Host " - 正在解压AutoIt便携版到 $autoItInstallDir"
        
        New-Item -Path $autoItInstallDir -ItemType Directory -Force | Out-Null
        Remove-Item -Path "$autoItInstallDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $tarExe = "tar.exe"
        $extracted = $false
        if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
            $tarOutLog = Join-Path $logsDir "tar_out.log"
            $tarErrLog = Join-Path $logsDir "tar_err.log"
            $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$autoItZipPath`" -C `"$autoItInstallDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
            if ($process.ExitCode -eq 0) {
                $extracted = $true
            }
            else {
                Write-Warning "tar.exe解压 $(Split-Path -Leaf $autoItZipPath) 失败，查看 $tarErrLog。回退使用Expand-Archive。"
            }
        }
        
        if (-not $extracted) {
            $unzipErrLog = Join-Path $logsDir "unzip_err.log"
            Expand-Archive -Path $autoItZipPath -DestinationPath $autoItInstallDir -Force -ErrorAction Stop 2> $unzipErrLog
        }
        
        Remove-Item $autoItZipPath -Force -ErrorAction SilentlyContinue
        Write-Host " - AutoIt已解压到 $autoItInstallDir" -ForegroundColor Green
    }
    catch {
        Write-Error "下载或解压AutoIt便携版失败: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasSciTE) {
    Write-Host ""
    Write-Host "--- 步骤5: 下载SciTE编辑器 ---" -ForegroundColor Cyan
    Write-Host "正在下载SciTE便携版..." -ForegroundColor Cyan
    try {
        Download-File -Url $sciTEUrl -Destination $sciTEZipPath
        $sciTEDestDir = Join-Path $autoItInstallDir "install\SciTE"
        Write-Host " - 正在解压SciTE便携版到 $sciTEDestDir"
        
        New-Item -Path $sciTEDestDir -ItemType Directory -Force | Out-Null
        Remove-Item -Path "$sciTEDestDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $tarExe = "tar.exe"
        $extracted = $false
        if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
            $tarOutLog = Join-Path $logsDir "tar_out.log"
            $tarErrLog = Join-Path $logsDir "tar_err.log"
            $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$sciTEZipPath`" -C `"$sciTEDestDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
            if ($process.ExitCode -eq 0) {
                $extracted = $true
            }
            else {
                Write-Warning "tar.exe解压 $(Split-Path -Leaf $sciTEZipPath) 失败，查看 $tarErrLog。回退使用Expand-Archive。"
            }
        }
        
        if (-not $extracted) {
            $unzipErrLog = Join-Path $logsDir "unzip_err.log"
            Expand-Archive -Path $sciTEZipPath -DestinationPath $sciTEDestDir -Force -ErrorAction Stop 2> $unzipErrLog
        }
        
        Remove-Item $sciTEZipPath -Force -ErrorAction SilentlyContinue
        Write-Host " - SciTE已解压到 $sciTEDestDir" -ForegroundColor Green
    }
    catch {
        Write-Error "下载或解压SciTE便携版失败: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

Write-Host ""
Write-Host "--- 步骤6: 编译GenP ---" -ForegroundColor Cyan
Write-Host "正在编译GenP..." -ForegroundColor Cyan
try {
    $au3Files = @(Get-ChildItem -Path $genpDir -Filter "*.au3" -File -ErrorAction Stop)
    if ($au3Files.Count -eq 0) {
        Write-Error "在 $genpDir 中未找到 .au3 文件。"
        Stop-Transcript | Out-Null
        exit 1
    }
    if ($au3Files.Count -gt 1) {
        $strippedFiles = @($au3Files | Where-Object { $_.Name -like "*_stripped.au3" })
        if ($strippedFiles) {
            Write-Host " - 发现已剥离的 .au3 文件: $($strippedFiles.Name -join ', ')。删除后继续构建。" -ForegroundColor Yellow
            $strippedFiles | ForEach-Object { Remove-Item $_.FullName -Force }
            $au3Files = @(Get-ChildItem -Path $genpDir -Filter "*.au3" -File -ErrorAction Stop)
        }
    }
    if ($au3Files.Count -ne 1) {
        Write-Error "清理后预期 $genpDir 中有1个 .au3 文件，实际找到 $($au3Files.Count) 个: $($au3Files.Name -join ', ')"
        Stop-Transcript | Out-Null
        exit 1
    }
    $au3File = $au3Files[0].FullName
    Write-Host " - 选定的 .au3 文件: $au3File"
    if (-not (Test-Path $autoItCoreExe)) {
        Write-Error "在 $autoItInstallDir\install 中未找到 AutoIt3_x64.exe。"
        Stop-Transcript | Out-Null
        exit 1
    }
    if (-not (Test-Path $wrapperScript)) {
        Write-Error "在 $autoItInstallDir\install\SciTE\AutoIt3Wrapper 中未找到 AutoIt3Wrapper.au3。"
        Stop-Transcript | Out-Null
        exit 1
    }
    $au3FileName = Split-Path $au3File -Leaf
    Write-Host " - 正在编译 $au3FileName"
    $autoItOutLog = Join-Path $logsDir "AutoIt_out.log"
    $autoItErrLog = Join-Path $logsDir "AutoIt_err.log"
    Remove-Item -Path (Join-Path $genpDir "GenP*.exe") -Force -ErrorAction SilentlyContinue
    $autoItArgs = "`"$wrapperScript`" /NoStatus /in `"$au3File`""
    Start-Process -FilePath $autoItCoreExe -ArgumentList $autoItArgs -WorkingDirectory $genpDir -RedirectStandardOutput $autoItOutLog -RedirectStandardError $autoItErrLog -Wait -ErrorAction Stop
    $exeFiles = @(Get-ChildItem -Path $genpDir -Filter "GenP*.exe" -File -ErrorAction Stop | Sort-Object LastWriteTime -Descending)
    if ($exeFiles.Count -eq 0) {
        Write-Error "AutoIt3Wrapper未能在 $genpDir 生成GenP*.exe。请查看 $autoItErrLog。"
        Write-Host " - 正在搜索可能放错位置的可执行文件" -ForegroundColor Yellow
        $misplacedExes = @(Get-ChildItem -Path $genpDir,$scriptDir,$installBaseDir,"C:\Windows\System32" -Filter "*.exe" -File -Recurse -ErrorAction SilentlyContinue)
        if ($misplacedExes.Count -gt 0) {
            Write-Host " - 在其他目录找到 $($misplacedExes.Count) 个可执行文件: $($misplacedExes.FullName -join ', ')" -ForegroundColor Yellow
        }
        Stop-Transcript | Out-Null
        exit 1
    }
    if ($exeFiles.Count -gt 1) {
        $exeNames = $exeFiles.Name -join ', '
        Write-Host " - 警告: 在 $genpDir 发现多个GenP*.exe文件 - $exeNames。使用最新的: $($exeFiles[0].Name)" -ForegroundColor Yellow
    }
    $genpExe = $exeFiles[0].FullName
    $releaseExe = Join-Path $releaseDir $exeFiles[0].Name
    Move-Item -Path $genpExe -Destination $releaseExe -Force -ErrorAction Stop
    if (-not (Test-Path $releaseExe)) {
        Write-Error "移动 $genpExe 到 $releaseExe 失败。"
        Stop-Transcript | Out-Null
        exit 1
    }
    Write-Host " - GenP可执行文件已构建到 $releaseExe" -ForegroundColor Green
    Remove-Item -Path (Join-Path $genpDir "GenP*_stripped.au3") -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "编译AutoIt脚本失败: $_" -ForegroundColor Red
    Stop-Transcript | Out-Null
    exit 1
}

Write-Host ""
Write-Host "构建流程已成功完成！" -ForegroundColor Magenta
Stop-Transcript | Out-Null
