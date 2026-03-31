# GenP v3.8.0 架构说明与学习教程

> 本文档详细介绍项目的技术架构、代码组织、核心算法和各模块工作原理。  
> 配合源码中的中文注释一起阅读效果最佳。

---

## 目录

- [一、技术架构总览](#一技术架构总览)
- [二、AutoIt v3 语言基础](#二autoit-v3-语言基础)
- [三、程序生命周期](#三程序生命周期)
- [四、主程序源码结构](#四主程序源码结构)
- [五、核心模块详解](#五核心模块详解)
  - [5.1 GUI 界面系统](#51-gui-界面系统)
  - [5.2 文件搜索引擎](#52-文件搜索引擎)
  - [5.3 特征码匹配引擎](#53-特征码匹配引擎)
  - [5.4 二进制补丁引擎](#54-二进制补丁引擎)
  - [5.5 配置系统](#55-配置系统)
- [六、辅助工具模块](#六辅助工具模块)
  - [6.1 AGS 移除](#61-ags-移除)
  - [6.2 Hosts 管理](#62-hosts-管理)
  - [6.3 防火墙管理](#63-防火墙管理)
  - [6.4 Runtime 安装器](#64-runtime-安装器)
  - [6.5 WinTrust 管理](#65-wintrust-管理)
  - [6.6 DevOverride 注册表](#66-devoverride-注册表)
- [七、构建系统](#七构建系统)
- [八、配置文件详解](#八配置文件详解)
- [九、关键数据流](#九关键数据流)
- [十、学习要点总结](#十学习要点总结)

---

## 一、技术架构总览

```
┌─────────────────────────────────────────────────────────┐
│                    GenP v3.8.0 架构图                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐  │
│  │   GUI 界面    │───→│  事件循环     │───→│  功能分发  │  │
│  │  (MainGui)   │    │ (While Loop) │    │ (Select)  │  │
│  └──────────────┘    └──────────────┘    └─────┬─────┘  │
│                                                │        │
│         ┌──────────────┬───────────┬───────────┤        │
│         ▼              ▼           ▼           ▼        │
│  ┌────────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐   │
│  │ 文件搜索    │ │ 补丁引擎  │ │ 恢复功能 │ │ 弹窗工具 │   │
│  │ 引擎       │ │          │ │         │ │         │   │
│  └─────┬──────┘ └────┬─────┘ └─────────┘ └────┬────┘   │
│        │             │                         │        │
│        ▼             ▼                         ▼        │
│  ┌────────────┐ ┌──────────┐  ┌─────────────────────┐  │
│  │ 正则匹配    │ │ 二进制    │  │  AGS │ Hosts │ FW   │  │
│  │ 引擎       │ │ 写入引擎  │  │  RT  │ Trust │ Dev  │  │
│  └─────┬──────┘ └──────────┘  └─────────────────────┘  │
│        │                                                │
│        ▼                                                │
│  ┌──────────────────────────┐                           │
│  │      config.ini          │                           │
│  │  (特征码 + 目标文件列表)  │                           │
│  └──────────────────────────┘                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**关键设计思想：**

1. **数据驱动** — 补丁逻辑不硬编码在程序中，而是通过 `config.ini` 配置特征码，方便更新
2. **事件驱动 GUI** — 采用 AutoIt 的消息循环模型，`GUIGetMsg()` 获取用户操作
3. **模块化设计** — 每个功能（搜索、补丁、防火墙等）封装为独立函数

---

## 二、AutoIt v3 语言基础

### 什么是 AutoIt？

AutoIt v3 是一款免费的 Windows 自动化脚本语言，特点：
- 语法类似 BASIC，上手简单
- 内置 GUI 创建能力，无需额外框架
- 可编译为独立 `.exe`，无需运行时环境
- 丰富的 Windows API 封装（注册表、文件、进程、网络）

### 核心语法对照

| 概念 | AutoIt 写法 | 等价的 Python/C# |
|------|-------------|------------------|
| 变量 | `$myVar = 10` | `myVar = 10` |
| 字符串 | `"Hello" & " World"` | `"Hello" + " World"` |
| 数组 | `$arr[3] = [1,2,3]` | `arr = [1,2,3]` |
| 函数 | `Func Foo($x)...EndFunc` | `def foo(x):` |
| 条件 | `If...Then...EndIf` | `if...then...end` |
| 循环 | `For $i=0 To 9...Next` | `for i in range(10):` |
| 注释 | `; 这是注释` | `# 这是注释` |
| 字符串连接 | `&` 运算符 | `+` 运算符 |
| 相等判断 | `=` | `==` |
| 不等判断 | `<>` | `!=` |

### AutoIt 特殊宏（内置变量）

```autoit
@ScriptDir      ; 脚本所在目录的完整路径
@WindowsDir     ; Windows 安装目录 (通常 C:\Windows)
@ProgramFilesDir ; Program Files 目录路径
@CRLF           ; 回车换行符 (Chr(13) & Chr(10))
@error          ; 上一个函数调用的错误码
@extended       ; 上一个函数的扩展返回值
@SW_SHOW        ; 窗口显示状态常量
@SW_HIDE        ; 窗口隐藏状态常量
```

---

## 三、程序生命周期

```
程序启动
  │
  ├─ 1. 预处理指令执行
  │     ├─ #NoTrayIcon          → 隐藏托盘图标
  │     ├─ #RequireAdmin        → 请求管理员权限(UAC弹窗)
  │     └─ #include <xxx.au3>   → 加载 22 个标准库
  │
  ├─ 2. 全局变量初始化 (第 65~140 行)
  │     ├─ 版本号、窗口标题
  │     ├─ _Singleton() 单例检测 → 防止重复运行
  │     ├─ GUI 控件变量声明
  │     ├─ 读取 config.ini 配置
  │     └─ 解析目标文件列表和特征码
  │
  ├─ 3. 命令行参数检查
  │     └─ 如果传入 "-updatehosts" → 直接更新hosts并退出
  │
  ├─ 4. 注册消息处理函数
  │     └─ GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")
  │
  ├─ 5. 构建 GUI 界面
  │     └─ MainGui() → 创建窗口、Tab页、按钮、列表
  │
  ├─ 6. 进入主事件循环 ← 程序在此持续运行
  │     └─ While 1
  │           ├─ 检测 hosts.bak 状态
  │           ├─ GUIGetMsg() 获取事件
  │           └─ Select/Case 分发到对应处理函数
  │
  └─ 7. 退出
        └─ _Exit() → GUIDelete() → Exit
```

---

## 四、主程序源码结构

`GenP-3.8.0.au3` 共约 **3900 行**，按代码区域划分：

| 行范围 | 内容 | 说明 |
|--------|------|------|
| 1~9 | 文件头注释 | 项目信息、版权 |
| 10~27 | 编译指令 | `#AutoIt3Wrapper_*` 系列指令 |
| 29~60 | 库引入 | 22 个 `#include` 标准库 |
| 62~140 | 全局变量 | 变量声明、配置读取 |
| 142~160 | 程序入口 | 单例检测、命令行检查、消息注册 |
| 160~700 | 主事件循环 | `While 1...WEnd` + 所有 Case 分支 |
| 705~950 | `MainGui()` | GUI 界面构建函数 |
| 950~1080 | 搜索函数 | `RecursiveFileSearch()`、`FillListView*()` |
| 1080~1130 | 工具函数 | `MemoWrite()`、`LogWrite()`、`ToggleLog()` 等 |
| 1130~1200 | 文件对话框 | `MyFileOpenDialog()` |
| 1200~1480 | **核心引擎** | 搜索引擎 + 补丁引擎 |
| 1485~1680 | ListView 交互 | 点击、分组、折叠/展开 |
| 1680~1730 | 消息处理 | `WM_COMMAND`、`WM_NOTIFY` 回调 |
| 1730~1820 | 配置/辅助 | INI 读写、选项保存、信息弹窗 |
| 1820~1970 | AGS 移除 | `RemoveAGS()` |
| 1970~2170 | Hosts 管理 | DNS扫描、更新、编辑、恢复 |
| 2170~2800 | 防火墙管理 | 检测、创建、删除、切换规则 |
| 2800~3200 | Runtime 解包 | UPX 检测、头部修补、解压 |
| 3200~3280 | DevOverride | 注册表添加/删除 |
| 3280~3660 | WinTrust | 信任/取消信任 EXE 文件 |
| 3660~3700 | 辅助函数 | `ManageDevOverride()`、`OpenWF()` |

---

## 五、核心模块详解

### 5.1 GUI 界面系统

**位置**：`MainGui()` 函数（约第 705 行）

AutoIt 的 GUI 采用过程式创建方式：

```autoit
; 1. 创建主窗口
$MyhGUI = GUICreate($g_AppWndTitle, 800, 600, -1, -1, $WS_OVERLAPPEDWINDOW)

; 2. 创建 Tab 控件（4个标签页）
$hTab = GUICtrlCreateTab(5, 5, 790, 560)

; 3. 在各 Tab 页上创建控件
GUICtrlCreateTabItem("主页")          ; 切换到"主页"标签
$idButtonSearch = GUICtrlCreateButton("搜索", 10, 30, 80, 30)  ; 创建搜索按钮
$idListview = GUICtrlCreateListView(...)                        ; 创建文件列表

GUICtrlCreateTabItem("选项")          ; 切换到"选项"标签
$idEnableMD5 = GUICtrlCreateCheckbox("启用MD5校验", ...)       ; 复选框

GUICtrlCreateTabItem("弹窗工具")      ; 切换到"弹窗工具"标签
$idBtnRemoveAGS = GUICtrlCreateButton("移除 AGS", ...)        ; AGS按钮

GUICtrlCreateTabItem("日志")          ; 切换到"日志"标签
$idLog = GUICtrlCreateEdit("", ...)                            ; 日志文本框

; 4. 显示窗口
GUISetState(@SW_SHOW, $MyhGUI)
```

**界面布局**：
```
┌──────────────────────────────────────────────┐
│ GenP v3.8.0 - CGP                            │
├──────┬──────┬──────────┬────┬────────────────┤
│ 主页 │ 选项 │ 弹窗工具  │ 日志│               │
├──────┴──────┴──────────┴────┘                │
│                                              │
│  [路径] [搜索] [停止] [补丁] [全选] [恢复]    │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │  文件列表 (ListView)                    │  │
│  │  ├─ Adobe Photoshop                    │  │
│  │  │  ├─ ☑ photoshop.exe                │  │
│  │  │  └─ ☑ public.dll                   │  │
│  │  ├─ Adobe Illustrator                  │  │
│  │  │  └─ ☑ illustrator.exe              │  │
│  │  └─ ...                                │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  状态: 搜索完成, 找到 15 个文件               │
│  ═══════════════════════ 100%                │
└──────────────────────────────────────────────┘
```

### 5.2 文件搜索引擎

**位置**：`RecursiveFileSearch()` 函数（约第 950 行）

```
用户点击"搜索"按钮
      │
      ▼
RecursiveFileSearch($StartDir, $Depth, $FileCount)
      │
      ├─ 遍历目录下所有文件
      │    └─ 对每个文件名与 $TargetFileList 比对
      │         └─ 匹配成功 → 添加到 $FilesToPatch 数组
      │
      ├─ 递归进入子目录（深度限制）
      │    └─ 可选：仅搜索默认 Adobe 文件夹
      │
      └─ 更新进度条和状态信息
```

**关键设计**：
- 使用 `FileFindFirstFile()` / `FileFindNextFile()` 原生 API 遍历
- 通过 `$fInterrupt` 全局标志支持用户中断搜索
- 搜索结果按 Adobe 产品自动分组显示

### 5.3 特征码匹配引擎

**位置**：`MyRegExpGlobalPatternSearch()` 函数（约第 1298 行）

这是整个程序最核心的函数，负责在二进制文件中查找特定字节序列：

```
输入: 文件路径, 搜索模式(十六进制), 替换模式(十六进制), 模式名称
      │
      ▼
1. 将文件读取为二进制字符串
   $hFile = FileOpen($FileToParse, 16)    ; 16 = 二进制模式
   $sFileContent = FileRead($hFile)
      │
      ▼
2. 构建正则表达式
   搜索模式: "85C075??B892010000E9"
   ↓ 转换
   正则: "85C075..B892010000E9"    ; ?? 变为 .. (匹配任意字节)
      │
      ▼
3. 执行正则搜索
   StringRegExp($sFileContent, $pattern, 3)   ; 3 = 返回所有匹配
      │
      ▼
4. 记录匹配结果
   - 匹配位置（偏移量）
   - 原始字节序列
   - 目标替换字节序列
   → 存入 $aOutHexGlobalArray 全局数组
```

**十六进制特征码格式说明** (`config.ini` 中的 `[Patches]` 区段)：

```ini
; 格式: 名称="搜索模式"|"替换模式"
; ?? 表示通配符（匹配任意一个字节）

ProfileExpired1="85C075??????????75??B892010000E9"|"31C075004883FF0F7500B800000000E9"
;                ↑ 搜索这个字节序列                  ↑ 替换为这个字节序列

; 解读示例:
; 85C0   = test eax, eax    (测试返回值)
; 75??   = jnz ??           (不为零则跳转, ??=偏移量)
; B8920100 = mov eax, 0x192 (设置错误码 = 许可证过期)
;
; 替换后:
; 31C0   = xor eax, eax     (清零返回值 = 成功)
; 7500   = jnz 0            (跳转偏移改为0 = 不跳转)
; B8000000 = mov eax, 0x0   (错误码改为0 = 无错误)
```

### 5.4 二进制补丁引擎

**位置**：`MyGlobalPatternPatch()` 函数（约第 1410 行）

```
输入: 文件路径, 匹配结果数组(包含偏移和替换字节)
      │
      ▼
1. 备份原文件
   FileCopy($file, $file & ".bak")    ; 创建 .bak 备份
      │
      ▼
2. 以二进制模式打开文件
   $hFile = FileOpen($file, 16+1)     ; 16=二进制, 1=写入
      │
      ▼
3. 逐个应用补丁
   For each match in $MyArrayToPatch
      FileSetPos($hFile, $offset, 0)  ; 跳转到匹配位置
      FileWrite($hFile, $newBytes)    ; 写入替换字节
   Next
      │
      ▼
4. 关闭文件并验证
   FileClose($hFile)
   ; 可选: MD5 校验确认修改成功
```

### 5.5 配置系统

`config.ini` 采用标准 INI 格式，AutoIt 内置完整的 INI 读写支持：

```autoit
; 读取单个值
$value = IniRead($sINIPath, "Options", "FindACC", "1")
; 参数: 文件路径, 区段名, 键名, 默认值

; 写入值
IniWrite($sINIPath, "Options", "FindACC", "1")

; 读取整个区段
$section = IniReadSection($sINIPath, "TargetFiles")
; 返回二维数组: $section[n][0]=键名, $section[n][1]=值
```

---

## 六、辅助工具模块

### 6.1 AGS 移除

**函数**：`RemoveAGS()` | **位置**：约第 1822 行

Adobe Genuine Software Service（正版验证服务）是一个后台服务，定期检查 Adobe 产品的许可证状态。

```
RemoveAGS() 执行流程:
  │
  ├─ 1. 停止 AGSService 服务
  │     RunWait('sc stop "AGSService"')
  │
  ├─ 2. 删除服务注册
  │     RunWait('sc delete "AGSService"')
  │
  ├─ 3. 终止相关进程
  │     _ProcessCloseEx("AGSService.exe")
  │     _ProcessCloseEx("AGS.exe")
  │
  └─ 4. 删除 AGS 文件目录
        DirRemove(@ProgramFilesDir & "\Common Files\Adobe\AdobeGCClient")
```

### 6.2 Hosts 管理

**函数**：`UpdateHostsFile()`、`RemoveHostsEntries()`、`ScanDNSCache()` 等

Hosts 文件（`C:\Windows\System32\drivers\etc\hosts`）可以将域名解析重定向到指定 IP。将 Adobe 服务器域名指向 `127.0.0.1`（本机回环地址）可以阻止程序联网验证。

```
Hosts 管理流程:
  │
  ├─ 更新 Hosts
  │    ├─ 备份当前 hosts → hosts.bak
  │    ├─ 从 URL 下载域名列表（或使用内置列表）
  │    ├─ 可选: ScanDNSCache() 扫描当前 DNS 缓存
  │    │   └─ ipconfig /displaydns → 提取 Adobe 域名
  │    └─ 将 "127.0.0.1 域名" 格式写入 hosts 文件
  │
  ├─ 清除 Hosts
  │    └─ 逐行读取 hosts，删除包含 Adobe 域名的行
  │
  ├─ 编辑 Hosts
  │    └─ ShellExecute("notepad.exe", hosts路径)
  │
  └─ 恢复 Hosts
       └─ FileCopy(hosts.bak → hosts)
```

### 6.3 防火墙管理

**函数**：`CreateFirewallRules()`、`RemoveFirewallRules()`、`ShowFirewallStatus()` 等

通过 Windows 自带的 `netsh advfirewall` 命令创建入站/出站阻止规则：

```
防火墙管理流程:
  │
  ├─ 检测第三方防火墙
  │    └─ WMI 查询: Get-CimInstance -Namespace root\SecurityCenter2
  │
  ├─ 搜索 Adobe EXE
  │    └─ FindApps() → 按 [FirewallTrust] 配置搜索
  │
  ├─ 用户选择应用
  │    └─ ShowAppSelectionGUI() → TreeView 复选框界面
  │
  ├─ 创建规则
  │    ├─ netsh advfirewall firewall add rule dir=in  action=block
  │    └─ netsh advfirewall firewall add rule dir=out action=block
  │
  ├─ 切换规则状态
  │    ├─ EnableAllFWRules()  → set rule ... new enable=yes
  │    └─ DisableAllFWRules() → set rule ... new enable=no
  │
  └─ 删除规则
       └─ netsh advfirewall firewall delete rule name="GenP_*"
```

### 6.4 Runtime 安装器

**函数**：`FindRuntimeInstallerFiles()`、`UnpackRuntimeInstallers()`、`IsUPXPacked()` 等

Adobe 的某些 DLL 被 UPX 压缩，补丁前需要先解压：

```
Runtime 解包流程:
  │
  ├─ 1. FindRuntimeInstallerFiles()
  │      └─ 按 [RuntimeInstallers] 配置搜索 DLL
  │
  ├─ 2. IsUPXPacked($filePath)
  │      └─ 读取 PE 头，检查是否包含 "UPX" 段名
  │
  ├─ 3. PatchUPXHeader($filePath)
  │      └─ Adobe 修改了 UPX 段名以阻止解压
  │         将段名恢复为标准 "UPX0"/"UPX1"
  │
  └─ 4. UnpackRuntimeInstallers()
         └─ 调用 upx.exe -d 执行解压
```

**UPX 头部修补原理**：

```
标准 UPX 压缩的 PE 文件段名:
  Section 1: "UPX0"  (解压后数据放置区)
  Section 2: "UPX1"  (压缩数据存储区)

Adobe 修改后:
  Section 1: "0PUX"  (名称被打乱)
  Section 2: "1PUX"

PatchUPXHeader() 做的事:
  把段名改回标准名称 → UPX 工具就能识别并解压了
```

### 6.5 WinTrust 管理

**函数**：`ManageWinTrust()`、`TrustEXEs()`、`UntrustEXEs()` 等

WinTrust 是 Windows 的数字签名验证机制。补丁后的 Adobe EXE 签名会失效，需要让系统跳过验证：

```
WinTrust 信任流程:
  │
  ├─ 补丁 wintrust.dll (构建时完成)
  │    └─ 偏移 0x1C86: 原始字节 → 0x33 0xC0
  │       即 xor eax, eax → 验证函数返回0(通过)
  │
  ├─ TrustEXEs()
  │    └─ 将补丁后的 wintrust.dll 复制到各 Adobe 目录
  │       Adobe 程序会优先加载本地的 wintrust.dll
  │
  └─ UntrustEXEs()
       └─ 删除各目录下的本地 wintrust.dll
          恢复使用系统原版
```

### 6.6 DevOverride 注册表

**函数**：`AddDevOverride()`、`RemoveDevOverride()`

通过在注册表中添加特定键值，让 Adobe 应用进入"开发者模式"，跳过部分许可检查：

```autoit
; 注册表路径
HKLM\SOFTWARE\Adobe\<产品名>\DevOverride

; AddDevOverride() 写入
RegWrite("HKLM\SOFTWARE\Adobe\...", "DevOverride", "REG_DWORD", 1)

; RemoveDevOverride() 删除
RegDelete("HKLM\SOFTWARE\Adobe\...", "DevOverride")
```

---

## 七、构建系统

### 构建工具链

```
run_build.bat  (入口：请求管理员权限)
      │
      ▼
build.ps1  (PowerShell 主构建脚本)
      │
      ├─ 1. 环境检查
      │     ├─ Test-Admin → 验证管理员权限
      │     └─ Test-ExecutionPolicy → 验证脚本执行策略
      │
      ├─ 2. 准备 UPX
      │     └─ 从 UPX/upx-5.0.1-win64.zip 解压 upx.exe
      │
      ├─ 3. 补丁 wintrust.dll
      │     └─ 调用 WinTrust/patch_wintrust.ps1
      │        ├─ 复制 wintrust.dll → wintrust.dll.patched
      │        ├─ 修改偏移 0x1C86 = 0x33, 0x1C87 = 0xC0
      │        └─ 移动到 GenP/ 目录
      │
      ├─ 4. 下载 AutoIt 编译器
      │     └─ autoit-v3.zip → C:\GenP-BuildEnv\AutoIt\
      │
      ├─ 5. 下载 SciTE
      │     └─ SciTE4AutoIt3_Portable.zip → AutoIt\install\SciTE\
      │
      └─ 6. 编译
            ├─ AutoIt3_x64.exe 运行 AutoIt3Wrapper.au3
            ├─ 输入: GenP/GenP-3.8.0.au3
            ├─ 编译: .au3 → .exe (内嵌所有资源)
            ├─ 精简: Au3Stripper 去除注释和空行
            ├─ 压缩: UPX 压缩可执行文件
            └─ 输出: Release/GenP-v3.8.0.exe
```

### AutoIt 编译原理

```
源码 (.au3)
    │
    ▼  Au3Stripper (去除注释/空行)
精简源码 (_stripped.au3)
    │
    ▼  Aut2Exe (AutoIt 编译器)
    │  将脚本嵌入 AutoIt 运行时
独立 EXE (含内嵌运行时 + 脚本)
    │
    ▼  UPX 压缩
最终 EXE (体积减小约 50-70%)
```

> **注意**：AutoIt "编译"本质上是将脚本打包进运行时——不是真正的机器码编译。
> EXE 内部仍然包含可反编译的 AutoIt 脚本。

---

## 八、配置文件详解

### config.ini 完整区段说明

```ini
[Info]
; 配置文件版本号，程序用于检测配置兼容性
ConfigVer="3.8.0 - CGP"

[Default]
; Adobe 产品的默认安装路径
; 程序启动时检查此路径是否存在
Path=C:\Program Files\Adobe

[TargetFiles]
; 需要搜索和补丁的 Adobe 文件名列表
; 格式1: 序号="文件名"
;   → 在 Adobe 目录下递归搜索此文件名
; 格式2: 序号="文件名$\子路径\文件名"
;   → $ 后面是额外的路径匹配条件
1="Acrobat.dll"
19="HDPIM.dll$\HDBox\HDPIM.dll"    ; 匹配路径中包含 \HDBox\ 的

[RuntimeInstallers]
; UPX 压缩的 DLL 文件路径模式
; * 通配符匹配版本号（如 "Adobe After Effects 2024"）
; 带 ; 开头表示已禁用
1="\Adobe After Effects *\Support Files\RuntimeInstaller.dll"

[FirewallTrust]
; 需要防火墙阻止的 Adobe 程序路径
; 路径相对于 Adobe 安装目录
1="\Acrobat DC\Acrobat\Acrobat.exe"

[DefaultPatterns]
; 默认特征码列表 — 对所有目标文件使用
; 值为逗号分隔的特征码名称
Values="Banner","CmpEax61",...

[CustomPatterns]
; 自定义特征码映射 — 指定文件使用特定模式
; 覆盖 DefaultPatterns 的配置
Acrobat.dll="Acrobat3","Acrobat5","RunningVulture3"

[Patches]
; 十六进制特征码定义（核心数据）
; 格式: 名称="搜索模式"|"替换模式"
; ?? = 通配符（匹配任意字节）
; # 开头 = 已禁用的旧模式
Banner="72656C6174696F6E..."|"78656C6174696F6E..."

[Options]
; 用户选项（GUI 中的复选框对应这里的值）
FindACC=1                 ; 始终搜索 ACC
EnableMD5=1               ; 启用 MD5 校验
OnlyDefaultFolders=1      ; 仅搜索默认文件夹
CustomDomainListURL=...   ; 自定义域名列表 URL
```

---

## 九、关键数据流

### 完整的"搜索→补丁"数据流

```
用户点击 [搜索]
    │
    ▼
① 从 config.ini 读取 [TargetFiles] 列表
    → $TargetFileList = ["Acrobat.dll", "photoshop.exe", ...]
    │
    ▼
② RecursiveFileSearch() 递归扫描 Adobe 目录
    → 找到匹配文件 → 存入 $FilesToPatch[]
    │
    ▼
③ FillListViewWithFiles() 在 ListView 中显示
    → _Assign_Groups_To_Found_Files() 按产品分组
    │
    ▼
④ 用户点击 [补丁]
    │
    ▼
⑤ 对每个选中的文件:
    │
    ├─ MyGlobalPatternSearch($file)
    │    │
    │    ├─ 读取 [DefaultPatterns] 或 [CustomPatterns]
    │    │   → 获取要搜索的特征码名称列表
    │    │
    │    ├─ 对每个特征码名称:
    │    │    ├─ 从 [Patches] 读取十六进制模式
    │    │    └─ MyRegExpGlobalPatternSearch()
    │    │         ├─ 文件内容 → 二进制字符串
    │    │         ├─ 十六进制模式 → 正则表达式
    │    │         ├─ 执行正则匹配
    │    │         └─ 记录: {偏移, 原字节, 替换字节}
    │    │
    │    └─ 汇总所有匹配结果 → $aOutHexGlobalArray
    │
    └─ MyGlobalPatternPatch($file, $matches)
         ├─ 创建 .bak 备份
         ├─ 在每个匹配偏移处写入替换字节
         └─ 验证修改结果

用户点击 [恢复]
    │
    └─ RestoreFile() → 用 .bak 覆盖回原文件
```

### 事件处理数据流

```
GUIGetMsg() 返回控件 ID
    │
    ├─ $idButtonSearch    → 开始搜索流程
    ├─ $idButtonStop      → 设置 $fInterrupt = 1
    ├─ $idBtnCure         → 开始补丁流程
    ├─ $idBtnRestore      → 恢复已补丁文件
    ├─ $idBtnDeselectAll  → 全选/取消 ListView
    ├─ $idBtnRemoveAGS    → RemoveAGS()
    ├─ $idBtnUpdateHosts  → UpdateHostsFile()
    ├─ $idBtnCreateFW     → CreateFirewallRules()
    ├─ $idBtnToggleFW     → ShowToggleRulesGUI()
    ├─ ...其他按钮...
    └─ $GUI_EVENT_CLOSE   → _Exit()
```

---

## 十、学习要点总结

### AutoIt 编程技巧

1. **GUI 消息循环** — AutoIt 的 GUI 不支持事件绑定（不像 C# 的 `button.Click += handler`），而是通过 `GUIGetMsg()` 轮询获取事件
2. **全局变量传递** — AutoIt 大量使用全局变量在函数间共享数据（这是一种简化设计，不是最佳实践）
3. **二进制文件操作** — `FileOpen($path, 16)` 以二进制模式读取，内容为十六进制字符串
4. **正则表达式** — `StringRegExp()` 返回匹配数组，模式3返回所有匹配
5. **进程和服务** — `Run()` / `RunWait()` / `ShellExecute()` 启动外部程序

### Windows 系统知识

1. **Hosts 文件** — `%WinDir%\System32\drivers\etc\hosts`，DNS 解析的本地覆盖
2. **Windows 防火墙** — `netsh advfirewall firewall` 命令行管理
3. **WMI 查询** — PowerShell `Get-CimInstance` 获取系统信息
4. **注册表操作** — `RegWrite()` / `RegRead()` / `RegDelete()`
5. **PE 文件结构** — 可执行文件的段头（Section Headers）和 UPX 压缩标记

### 软件工程实践

1. **数据驱动设计** — 将变化频繁的数据（特征码）外置到配置文件
2. **备份恢复机制** — 修改前自动创建 `.bak` 备份
3. **用户确认机制** — 危险操作前弹出确认对话框
4. **日志记录** — 所有操作写入日志，便于排查问题
5. **单例模式** — `_Singleton()` 防止多实例运行

---

> 📌 **本文档配合源码注释一起阅读效果最佳。建议用 VS Code 打开项目目录，安装 AutoIt 语法高亮插件后逐函数阅读学习。**
