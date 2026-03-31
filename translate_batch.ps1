$file = Join-Path $PSScriptRoot "GenP\GenP-3.8.0.au3"
$c = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
$origLen = $c.Length
Write-Host "Loaded: $origLen chars"

$count = 0
function DoReplace($old, $new) {
    if ($script:c.Contains($old)) {
        $script:c = $script:c.Replace($old, $new)
        $script:count++
        Write-Host "  OK: $($old.Substring(0, [Math]::Min(50, $old.Length)))..."
    } else {
        Write-Host "  MISS: $($old.Substring(0, [Math]::Min(50, $old.Length)))..."
    }
}

# === OK buttons ===
DoReplace 'CreateButton("OK"' 'CreateButton("确定"'

# === Search stats (RecursiveFileSearch) ===
DoReplace '" files" & @TAB & @TAB & "Found : "' '" 个文件" & @TAB & @TAB & "已找到: "'
DoReplace '"Level: " & $DEPTH & " Time elapsed : "' '"层级: " & $DEPTH & "  已用时: "'
DoReplace '" second(s)" & @TAB & @TAB & "Excluded because of *.bak: "' '" 秒" & @TAB & @TAB & "已排除 *.bak: "'
DoReplace '" second(s)" & @CRLF)' '" 秒" & @CRLF)'
DoReplace '"Nothing was found in "' '"在以下路径中未找到任何文件: "'

# === AGS messages ===
DoReplace '" services and " & $iFileSuccess & " / " & UBound($aPaths) & " files.")' '" 个服务和 " & $iFileSuccess & " / " & UBound($aPaths) & " 个文件。")'
DoReplace '"AGS removal completed. Services: "' '"AGS 移除完成。服务: "'

# === DNS/Hosts ===
DoReplace '"Found " & UBound($aNewDomains) & " new domain(s) in DNS cache:"' '"在 DNS 缓存中发现 " & UBound($aNewDomains) & " 个新域名:"'
DoReplace '"Error parsing blocklist from hosts content."' '"解析 hosts 屏蔽列表出错。"'
DoReplace '"Warning: ipconfig /displaydns timed out after "' '"警告: DNS 查询超时 ("'
DoReplace '"Error reading DNS cache."' '"读取 DNS 缓存出错。"'
DoReplace '"Download Error: "' '"下载出错: "'
DoReplace '"Added from DNS cache:"' '"已从 DNS 缓存添加:"'
DoReplace '"Added from DNS cache: "' '"已从 DNS 缓存添加: "'
DoReplace '"Error opening hosts file for writing: Last Error = "' '"打开 hosts 文件写入失败, 错误码 = "'
DoReplace '"Warning: Notepad timed out after "' '"警告: 记事本超时 ("'

# === Firewall messages ===
DoReplace '"Warning: Third-party firewall check timed out after "' '"警告: 第三方防火墙检查超时 ("'
DoReplace '"Error reading [FirewallTrust] section from config."' '"读取配置 [FirewallTrust] 段出错。"'
DoReplace '"Warning: Firewall profile check timed out after "' '"警告: 防火墙配置检查超时 ("'
DoReplace '"Firewall Profiles:"' '"防火墙配置:"'
DoReplace '"Firewall Profiles - "' '"防火墙配置 - "'
DoReplace '"Warning: Firewall service check timed out after "' '"警告: 防火墙服务检查超时 ("'
DoReplace '"Warning: Rule scan timed out after "' '"警告: 规则扫描超时 ("'
DoReplace '"Warning: Rule removal timed out after "' '"警告: 规则移除超时 ("'
DoReplace '"Warning: Rule creation timed out after "' '"警告: 规则创建超时 ("'
DoReplace '"Warning: Rule enabling timed out after "' '"警告: 规则启用超时 ("'
DoReplace '"Warning: Rule disabling timed out after "' '"警告: 规则禁用超时 ("'
DoReplace '"Error: Rule removal timed out."' '"错误: 规则移除超时。"'
DoReplace '"Error: Rule creation timed out."' '"错误: 规则创建超时。"'
DoReplace '"Error: Rule enabling timed out."' '"错误: 规则启用超时。"'
DoReplace '"Error: Rule disabling timed out."' '"错误: 规则禁用超时。"'
DoReplace '"No file(s) found at: "' '"未找到文件: "'
DoReplace '"No applications found to block."' '"未找到可屏蔽的应用程序。"'

# === Firewall app discovery ===
DoReplace '"Found " & UBound($aApps) & " applications:"' '"找到 " & UBound($aApps) & " 个应用程序:"'
DoReplace '"Third-party firewall detected' '"检测到第三方防火墙'
DoReplace '". This option only supports Windows Firewall."' '"。此功能仅支持 Windows 防火墙。"'
# Firewall rule check warning - handled separately due to quoting

# === Firewall rule counts ===
DoReplace '" rule(s):"' '" 条规则:"'

# === Selected files ===
DoReplace '"Selected " & $iCount' '"已选择 " & $iCount'

# === Runtime Installer messages ===
DoReplace '"Warning: [RuntimeInstallers] section not found or empty in config.ini"' '"警告: config.ini 中未找到 [RuntimeInstallers] 段或该段为空"'
DoReplace '"No files selected to unpack."' '"未选择要解包的文件。"'
DoReplace '"Error: Failed to extract upx.exe to "' '"错误: 解压 upx.exe 失败: "'
DoReplace '"Error: Failed to extract upx.exe."' '"错误: 解压 upx.exe 失败。"'
DoReplace '"Unpacking " & $iTotal & " file(s)..."' '"正在解包 " & $iTotal & " 个文件..."'
DoReplace '"Unpacking " & $iTotal & " file(s):"' '"正在解包 " & $iTotal & " 个文件:"'
DoReplace '"Skipped: "' '"已跳过: "'
DoReplace '" is not a UPX-packed file."' '" 不是 UPX 压缩文件。"'
DoReplace '"Failed to patch UPX headers for: "' '"UPX 头部修补失败: "'
DoReplace '"Deleted upx.exe from "' '"已从以下位置删除 upx.exe: "'
DoReplace '"Warning: Failed to delete upx.exe from "' '"警告: 删除 upx.exe 失败: "'
DoReplace '"Processing: "' '"正在处理: "'

# === UPX check errors ===
DoReplace '"Error: Failed to open file for UPX check: "' '"错误: 无法打开文件进行 UPX 检查: "'
DoReplace '"Error: Failed to read file for UPX check: "' '"错误: 无法读取文件进行 UPX 检查: "'

# === UPX patch errors ===
DoReplace '"Error: Failed to create backup for: "' '"错误: 创建备份失败: "'
DoReplace '"Error: Failed to open file for patching: "' '"错误: 无法打开文件进行修补: "'
DoReplace '"Error: Failed to read file for patching: "' '"错误: 无法读取文件进行修补: "'
DoReplace '"Error: Failed to open file for writing: "' '"错误: 无法打开文件进行写入: "'
DoReplace '"Error: Failed to write patched data to: "' '"错误: 写入修补数据失败: "'

# === Registry key messages ===
DoReplace '" already enabled."' '" 已启用。"'
DoReplace '"Enabled registry key "' '"已启用注册表项 "'
DoReplace '"Error: Failed to enable registry key "' '"错误: 启用注册表项失败 "'
DoReplace '" found to remove."' '" 可移除。"'
DoReplace '" not enabled; no action taken."' '" 未启用，无需操作。"'
DoReplace '"Disabled registry key "' '"已禁用注册表项 "'
DoReplace '"Error: Failed to disable registry key "' '"错误: 禁用注册表项失败 "'
DoReplace '"No registry key "' '"未找到注册表项 "'
DoReplace '"Registry key "' '"注册表项 "'
DoReplace '" already set to "' '" 已设为 "'
DoReplace '"Set registry key "' '"已设置注册表项 "'
DoReplace '"Error: Failed to set registry key "' '"错误: 设置注册表项失败 "'
DoReplace '" not set to "' '" 未设为 "'
DoReplace '"Removed registry key "' '"已移除注册表项 "'
DoReplace '"Error: Failed to remove registry key "' '"错误: 移除注册表项失败 "'

# === WinTrust messages ===
DoReplace '"Error: Failed to extract wintrust.dll to "' '"错误: 解压 wintrust.dll 失败: "'
DoReplace '"Error: Failed to extract wintrust.dll."' '"错误: 解压 wintrust.dll 失败。"'
DoReplace '"Error: wintrust.dll size mismatch (expected 382,712 bytes)."' '"错误: wintrust.dll 大小不匹配（应为 382,712 字节）。"'
DoReplace '"Trusting " & $iTotal & " application(s)..."' '"正在信任 " & $iTotal & " 个应用程序..."'
DoReplace '"Trusting " & $iTotal & " application(s):"' '"正在信任 " & $iTotal & " 个应用程序:"'
DoReplace '"Failed to create directory: "' '"创建目录失败: "'
DoReplace '"wintrust.dll already exists at: "' '"wintrust.dll 已存在于: "'
DoReplace '"Replaced wintrust.dll at: "' '"已替换 wintrust.dll: "'
DoReplace '"Failed to replace wintrust.dll to: "' '"替换 wintrust.dll 失败: "'
DoReplace '"Deleted wintrust.dll from "' '"已从以下位置删除 wintrust.dll: "'
DoReplace '"Warning: Failed to delete wintrust.dll from "' '"警告: 删除 wintrust.dll 失败: "'
DoReplace '"Untrusting " & $iTotal & " application(s)..."' '"正在取消信任 " & $iTotal & " 个应用程序..."'
DoReplace '"Untrusting " & $iTotal & " application(s):"' '"正在取消信任 " & $iTotal & " 个应用程序:"'
DoReplace '"No wintrust.dll found at: "' '"未找到 wintrust.dll: "'
DoReplace '"No applications found to "' '"未找到可处理的应用程序: "'

# === Service messages ===
DoReplace '"Error checking service "' '"检查服务出错 "'
DoReplace '"Warning: Failed to stop "' '"警告: 停止服务失败 "'
DoReplace '"Failed to stop service "' '"停止服务失败 "'
DoReplace '"Warning: Failed to delete "' '"警告: 删除服务失败 "'
DoReplace '"Failed to delete service "' '"删除服务失败 "'
DoReplace '"No backup file found."' '"未找到备份文件。"'

# === Config short path warning ===
DoReplace '"Warning: Short path used in config, using Unknown for: "' '"警告: 配置使用了短路径，未知应用: "'

# === Misc ===
DoReplace '"Attempting to copy from: "' '"正在复制: "'
DoReplace '" to: "' '" 到: "'

# === Firewall enabled/disabled/unknown status ===
DoReplace '? "Enabled" : "Disabled"' '? "已启用" : "已禁用"'
DoReplace '$sFWStatus = "Unknown"' '$sFWStatus = "未知"'

# === "No" pattern match display ===
DoReplace '& "No"' '& "否"'

# === "or" connector ===
DoReplace ' & " or " &' ' & " 或 " &'

# === "Path" in MemoWrite ===
DoReplace 'MemoWrite("Path"' 'MemoWrite("路径"'

# === "Found " & file count in firewall ===
DoReplace '"Found " & $iTotal & " file(s) across "' '"找到 " & $iTotal & " 个文件，分布在 "'

Write-Host ""
Write-Host "Total replacements: $count"
Write-Host "New length: $($c.Length) (was $origLen)"

[System.IO.File]::WriteAllText($file, $c, [System.Text.Encoding]::UTF8)
Write-Host "File saved!"
