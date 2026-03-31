# Fix garbled Chinese text using Unicode escape sequences
# This avoids encoding issues since all Chinese is encoded as hex
param()
$ErrorActionPreference = 'Stop'

$file = Join-Path $PSScriptRoot "GenP\GenP-3.8.0.au3"
$text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
Write-Host "Loaded: $($text.Length) chars"

function U([string]$hexCodes) {
    # Convert space-separated hex Unicode code points to string
    $chars = $hexCodes.Split(' ') | ForEach-Object { [char][int]("0x$_") }
    return -join $chars
}

$count = 0
function R([string]$old, [string]$new) {
    if ($script:text.Contains($old)) {
        $script:text = $script:text.Replace($old, $new)
        $script:count++
    }
}

# === Translations using Unicode hex codes ===
# Each U() call converts hex code points to the Chinese string

# "此功能仅支持 Windows 防火墙。" = 6B64 529F 80FD 4EC5 652F 6301 0020 0057 0069 006E 0064 006F 0077 0073 0020 9632 706B 5899 3002
$s_onlyWinFW = U("6B64 529F 80FD 4EC5 652F 6301") + " Windows " + U("9632 706B 5899 3002")

# "条规则:" = 6761 89C4 5219 003A
$s_rules = U("6761 89C4 5219") + ":"

# "config.ini 中未找到 [RuntimeInstallers] 段或该段为空" 
$s_rtNotFound = U("8B66 544A") + ": config.ini " + U("4E2D 672A 627E 5230") + " [RuntimeInstallers] " + U("6BB5 6216 8BE5 6BB5 4E3A 7A7A")

# "未选择要解包的文件。" 
$s_noFilesUnpack = U("672A 9009 62E9 8981 89E3 5305 7684 6587 4EF6 3002")

# "错误: 解压 upx.exe 失败: " and "错误: 解压 upx.exe 失败。"
$s_upxExtractFail1 = U("9519 8BEF") + ": " + U("89E3 538B") + " upx.exe " + U("5931 8D25") + ": "
$s_upxExtractFail2 = U("9519 8BEF") + ": " + U("89E3 538B") + " upx.exe " + U("5931 8D25 3002")

# "已跳过: " 
$s_skipped = U("5DF2 8DF3 8FC7") + ": "

# "不是 UPX 压缩文件。"
$s_notUPX = " " + U("4E0D 662F") + " UPX " + U("538B 7F29 6587 4EF6 3002")

# "UPX 头部修补失败: "
$s_upxPatchFail = "UPX " + U("5934 90E8 4FEE 8865 5931 8D25") + ": "

# "已从以下位置删除 upx.exe: "
$s_delUpx = U("5DF2 4ECE 4EE5 4E0B 4F4D 7F6E 5220 9664") + " upx.exe: "

# "错误: 无法打开文件进行 UPX 检查: "
$s_upxOpenErr = U("9519 8BEF") + ": " + U("65E0 6CD5 6253 5F00 6587 4EF6 8FDB 884C") + " UPX " + U("68C0 67E5") + ": "

# "错误: 无法读取文件进行 UPX 检查: "
$s_upxReadErr = U("9519 8BEF") + ": " + U("65E0 6CD5 8BFB 53D6 6587 4EF6 8FDB 884C") + " UPX " + U("68C0 67E5") + ": "

# "错误: 创建备份失败: "
$s_backupFail = U("9519 8BEF") + ": " + U("521B 5EFA 5907 4EFD 5931 8D25") + ": "

# "错误: 无法打开文件进行修补: "
$s_patchOpenErr = U("9519 8BEF") + ": " + U("65E0 6CD5 6253 5F00 6587 4EF6 8FDB 884C 4FEE 8865") + ": "

# "错误: 无法读取文件进行修补: "
$s_patchReadErr = U("9519 8BEF") + ": " + U("65E0 6CD5 8BFB 53D6 6587 4EF6 8FDB 884C 4FEE 8865") + ": "

# "错误: 无法打开文件进行写入: "
$s_writeOpenErr = U("9519 8BEF") + ": " + U("65E0 6CD5 6253 5F00 6587 4EF6 8FDB 884C 5199 5165") + ": "

# "错误: 写入修补数据失败: "
$s_writeDataErr = U("9519 8BEF") + ": " + U("5199 5165 4FEE 8865 6570 636E 5931 8D25") + ": "

# "已启用注册表项 "
$s_regEnabled = U("5DF2 542F 7528 6CE8 518C 8868 9879") + " "

# "错误: 启用注册表项失败 "
$s_regEnableFail = U("9519 8BEF") + ": " + U("542F 7528 6CE8 518C 8868 9879 5931 8D25") + " "

# "未找到注册表项 "
$s_regNotFound = U("672A 627E 5230 6CE8 518C 8868 9879") + " "

# "注册表项 "
$s_regKey = U("6CE8 518C 8868 9879") + " "

# " 已启用。"
$s_alreadyEnabled = " " + U("5DF2 542F 7528 3002")

# " 已设为 "
$s_alreadySet = " " + U("5DF2 8BBE 4E3A") + " "

# "已设置注册表项 "
$s_regSet = U("5DF2 8BBE 7F6E 6CE8 518C 8868 9879") + " "

# "错误: 设置注册表项失败 "
$s_regSetFail = U("9519 8BEF") + ": " + U("8BBE 7F6E 6CE8 518C 8868 9879 5931 8D25") + " "

# " 未设为 "
$s_notSet = " " + U("672A 8BBE 4E3A") + " "

# "已移除注册表项 "
$s_regRemoved = U("5DF2 79FB 9664 6CE8 518C 8868 9879") + " "

# "错误: 移除注册表项失败 "
$s_regRemoveFail = U("9519 8BEF") + ": " + U("79FB 9664 6CE8 518C 8868 9879 5931 8D25") + " "

# " 未启用，无需操作。"
$s_notEnabledNoAction = " " + U("672A 542F 7528 FF0C 65E0 9700 64CD 4F5C 3002")

# " 可移除。"
$s_canRemove = " " + U("53EF 79FB 9664 3002")

# "已禁用注册表项 "
$s_regDisabled = U("5DF2 7981 7528 6CE8 518C 8868 9879") + " "

# "错误: 禁用注册表项失败 "
$s_regDisableFail = U("9519 8BEF") + ": " + U("7981 7528 6CE8 518C 8868 9879 5931 8D25") + " "

# "错误: 解压 wintrust.dll 失败: "
$s_wtExtract1 = U("9519 8BEF") + ": " + U("89E3 538B") + " wintrust.dll " + U("5931 8D25") + ": "
$s_wtExtract2 = U("9519 8BEF") + ": " + U("89E3 538B") + " wintrust.dll " + U("5931 8D25 3002")

# "错误: wintrust.dll 大小不匹配（应为 382,712 字节）。"
$s_wtSize = U("9519 8BEF") + ": wintrust.dll " + U("5927 5C0F 4E0D 5339 914D FF08 5E94 4E3A") + " 382,712 " + U("5B57 8282 FF09 3002")

# "创建目录失败: "
$s_mkdirFail = U("521B 5EFA 76EE 5F55 5931 8D25") + ": "

# "wintrust.dll 已存在于: "
$s_wtExists = "wintrust.dll " + U("5DF2 5B58 5728 4E8E") + ": "

# "已替换 wintrust.dll: "
$s_wtReplaced = U("5DF2 66FF 6362") + " wintrust.dll: "

# "替换 wintrust.dll 失败: "
$s_wtReplaceFail = U("66FF 6362") + " wintrust.dll " + U("5931 8D25") + ": "

# "已从以下位置删除 wintrust.dll: "
$s_wtDeleted = U("5DF2 4ECE 4EE5 4E0B 4F4D 7F6E 5220 9664") + " wintrust.dll: "

# "警告: 删除 wintrust.dll 失败: "
$s_wtDelFail = U("8B66 544A") + ": " + U("5220 9664") + " wintrust.dll " + U("5931 8D25") + ": "

# "未找到 wintrust.dll: "
$s_wtNotFound = U("672A 627E 5230") + " wintrust.dll: "

# "未找到可处理的应用程序: "
$s_noAppsFound = U("672A 627E 5230 53EF 5904 7406 7684 5E94 7528 7A0B 5E8F") + ": "

# "检查服务出错 "
$s_svcCheckErr = U("68C0 67E5 670D 52A1 51FA 9519") + " "

# "警告: 停止服务失败 "
$s_svcStopWarn = U("8B66 544A") + ": " + U("505C 6B62 670D 52A1 5931 8D25") + " "

# "停止服务失败 "
$s_svcStopFail = U("505C 6B62 670D 52A1 5931 8D25") + " "

# "警告: 删除服务失败 "
$s_svcDelWarn = U("8B66 544A") + ": " + U("5220 9664 670D 52A1 5931 8D25") + " "

# "删除服务失败 "
$s_svcDelFail = U("5220 9664 670D 52A1 5931 8D25") + " "

# "未找到备份文件。"
$s_noBackup = U("672A 627E 5230 5907 4EFD 6587 4EF6 3002")

# "警告: 配置使用了短路径，未知应用: "
$s_shortPath = U("8B66 544A") + ": " + U("914D 7F6E 4F7F 7528 4E86 77ED 8DEF 5F84 FF0C 672A 77E5 5E94 7528") + ": "

# "正在复制: "
$s_copying = U("6B63 5728 590D 5236") + ": "

# " 到: "
$s_to = " " + U("5230") + ": "

# "已启用"
$s_enabled = U("5DF2 542F 7528")

# "已禁用"  
$s_disabled = U("5DF2 7981 7528")

# "否"
$s_no = U("5426")

# "正在处理: " 
$s_processing = U("6B63 5728 5904 7406") + ": "

# "警告: 删除 upx.exe 失败: "
$s_upxDelFail = U("8B66 544A") + ": " + U("5220 9664") + " upx.exe " + U("5931 8D25") + ": "

# "已从以下位置删除 upx.exe: "
# Already defined as $s_delUpx

# Now find and replace each garbled line
# We'll search by finding lines with private-use Unicode chars

$lines = $text -split "`r?`n"
$fixCount = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '[\uE000-\uF8FF]') {
        $lineNum = $i + 1
        Write-Host "Garbled line $lineNum"
        $fixCount++
    }
}

Write-Host "`nTotal garbled lines: $fixCount"
Write-Host "Now applying fixes..."

# Now do the actual replacements on $text
# For each known translation, search for surrounding context

# The garbled translations came from the batch script which replaced 
# English text with garbled Chinese. We need to identify what English 
# was replaced and put the correct Chinese back.

# Strategy: search for garbled strings by their proximity to known 
# non-garbled text (like variable names, function calls, etc.)

# Let's use regex to find each garbled string and replace it
# Pattern: Find strings containing private-use chars between quotes

$fixedCount = 0

# Fix function - find line containing a unique context pattern and replace the garbled portion
function FixLine([string]$contextBefore, [string]$garbledAndAfter_pattern, [string]$replacement) {
    # Find the context, then replace the garbled portion on that line
    $idx = $script:text.IndexOf($contextBefore)
    if ($idx -lt 0) { 
        Write-Host "  Context not found: $contextBefore"
        return 
    }
    # Find the end of this line
    $lineEnd = $script:text.IndexOf("`n", $idx)
    if ($lineEnd -lt 0) { $lineEnd = $script:text.Length }
    $line = $script:text.Substring($idx, $lineEnd - $idx)
    
    # Now replace any private-use chars and surrounding garbled text in this line
    # We'll replace everything between the first " and the closing " that contains garbled chars
    # Actually, let's just replace the whole line portion from context to end
    
    Write-Host "  Found at $idx, fixing..."
    $script:fixedCount++
}

Write-Host "Applying direct text replacements..."

# Instead of complex line-by-line fixing, let me just search for known 
# English-to-Chinese mappings that failed, using unique patterns around them

# The approach: for each garbled replacement, find the garbled text by 
# searching for private-use chars near known unchanged text

# SIMPLER APPROACH: Collect all garbled segments and replace them
# A garbled segment is a run of chars that includes private-use chars

$garbledSegments = [regex]::Matches($text, '[^\x00-\x7F]*[\uE000-\uF8FF][^\x00-\x7F]*')
Write-Host "Found $($garbledSegments.Count) garbled segments"

# For each segment, show its context
foreach ($seg in $garbledSegments | Select-Object -First 5) {
    $ctx = $text.Substring([Math]::Max(0, $seg.Index - 30), [Math]::Min(80, $text.Length - [Math]::Max(0, $seg.Index - 30)))
    Write-Host "  Segment '$($seg.Value)' in: $ctx"
}

Write-Host "`nScript complete. Manual fixes needed."
