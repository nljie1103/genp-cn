# GenP v3.8.0 中文注释学习版

[![Language](https://img.shields.io/badge/Language-AutoIt_v3-blue)](https://www.autoitscript.com/)
[![Version](https://img.shields.io/badge/Version-3.8.0-green)]()
[![License](https://img.shields.io/badge/License-Study_Only-orange)]()

> ⚠️ **声明：本仓库仅供学习 AutoIt 编程语言、Windows 自动化脚本编写和软件本地化技术参考，不鼓励任何非法用途。**

## 📖 项目简介

本项目是 **GenP (Generic Patcher) v3.8.0** 的中文注释学习版。在原版英文源码基础上完成了：

- **🌐 全界面中文化** — 所有按钮、标签、提示框、状态信息均翻译为中文
- **📝 全代码中文注释** — 60+ 个函数全部添加功能说明注释，关键代码逐行注释
- **📚 配套学习文档** — 项目架构、技术栈、构建流程、代码结构完整说明

适合作为学习以下技术的参考项目：
- AutoIt v3 GUI 编程（窗口创建、事件循环、控件操作）
- Windows 系统编程（注册表、防火墙、hosts 文件、进程管理）
- 二进制文件分析（十六进制模式匹配、PE 文件结构、UPX 压缩）
- PowerShell 自动化构建脚本
- 软件国际化/本地化（i18n/L10n）实践

## 🗂️ 项目结构

```
genp-3.8.0-src/
├── README.md                    ← 本文件（项目说明）
├── ARCHITECTURE.md              ← 详细架构与教程文档
├── build_info.txt               ← 构建说明（已中文化）
├── build.ps1                    ← PowerShell 自动化构建脚本（已中文注释）
├── run_build.bat                ← 一键构建启动器（已中文化）
├── GenP/
│   ├── GenP-3.8.0.au3           ← ⭐ 主程序源码（已全面中文化+注释）
│   ├── GenP-3.8.0.au3.bak       ← 原版英文备份
│   ├── config.ini               ← 补丁配置文件（已中文注释）
│   └── Skull.ico                ← 程序图标
├── UPX/
│   └── upx-5.0.1-win64.zip     ← UPX 压缩工具包
├── WinTrust/
│   ├── patch_wintrust.ps1       ← WinTrust 补丁脚本（已中文注释）
│   └── wintrust.dll             ← 原版 wintrust.dll
└── 原版/
    ├── GenP-v3.8.0.exe          ← 已编译的原版可执行文件
    └── CGP.nfo                  ← 原版 NFO 信息文件
    └── source                  ← 原版 SOURCE 信息文件
```

## 🛠️ 技术栈

| 组件 | 语言/技术 | 用途 |
|------|-----------|------|
| `GenP-3.8.0.au3` | **AutoIt v3** | 主程序（GUI、文件搜索、十六进制补丁引擎） |
| `build.ps1` | **PowerShell** | 自动化构建（下载依赖、编译、打包） |
| `run_build.bat` | **Batch** | 以管理员权限启动构建 |
| `patch_wintrust.ps1` | **PowerShell** | 二进制 DLL 字节补丁 |
| `config.ini` | **INI** | 目标文件列表、十六进制特征码定义 |

## 🚀 快速开始

### 环境要求

- **操作系统**：Windows 10/11 64位
- **权限**：管理员权限（构建和运行都需要）
- **网络**：首次构建需要联网下载 AutoIt 编译器（~24MB）

### 阅读源码（推荐）

直接用任意文本编辑器打开 `GenP/GenP-3.8.0.au3`，所有代码都有详细中文注释：

```
推荐编辑器：
- VS Code（安装 AutoIt 语法高亮插件）
- SciTE4AutoIt3（官方编辑器，支持语法检查和调试）
- Notepad++（轻量级，安装 AutoIt 语言包）
```

### 构建编译（可选）

如果需要从源码编译为可执行文件：

```batch
# 1. 右键 run_build.bat → "以管理员身份运行"
#    或在管理员 PowerShell 中执行：
powershell.exe -ExecutionPolicy Bypass -File build.ps1
```

构建脚本会自动完成：
1. ✅ 下载 AutoIt v3 Portable 编译器
2. ✅ 下载 SciTE4AutoIt3 编译封装器
3. ✅ 解压 UPX 压缩工具
4. ✅ 补丁 wintrust.dll
5. ✅ 编译 `.au3` → `.exe`
6. ✅ 输出到 `Release/` 目录

## 📚 学习指南

### 入门路线（建议按顺序阅读）

| 步骤 | 文件 | 学习内容 |
|------|------|----------|
| 1️⃣ | `ARCHITECTURE.md` | 了解整体架构和代码组织 |
| 2️⃣ | `GenP-3.8.0.au3` 第1~140行 | AutoIt 基础：编译指令、库引入、全局变量 |
| 3️⃣ | `MainGui()` 函数 | GUI 编程：窗口创建、Tab页、按钮布局 |
| 4️⃣ | 主事件循环 `While 1...WEnd` | 事件驱动编程：消息循环模型 |
| 5️⃣ | `RecursiveFileSearch()` | 文件系统操作：递归目录遍历 |
| 6️⃣ | `MyRegExpGlobalPatternSearch()` | 核心引擎：正则+二进制特征码搜索 |
| 7️⃣ | `MyGlobalPatternPatch()` | 核心引擎：二进制文件补丁写入 |
| 8️⃣ | `config.ini` | 数据驱动设计：特征码配置 |
| 9️⃣ | `build.ps1` | 构建自动化：PowerShell 脚本 |
| 🔟 | `patch_wintrust.ps1` | 底层技术：DLL 二进制字节修改 |

### AutoIt v3 语法速查

```autoit
; 变量声明
Global $var = "全局变量"      ; Global = 全局作用域
Local $var = "局部变量"       ; Local = 函数内局部作用域

; 数组
Global $arr[3] = ["a", "b", "c"]   ; 固定大小数组
ReDim $arr[5]                       ; 调整数组大小

; 条件判断
If $x > 0 Then
    ; ...
ElseIf $x = 0 Then
    ; ...
Else
    ; ...
EndIf

; 循环
For $i = 0 To UBound($arr) - 1
    ; UBound() 返回数组大小
Next

While $condition
    ; ...
WEnd

; 函数定义
Func MyFunction($param1, $param2)
    Return $result
EndFunc

; GUI 创建
$hGUI = GUICreate("标题", 800, 600)     ; 创建窗口
$btn = GUICtrlCreateButton("按钮", 10, 10, 80, 30)  ; 创建按钮
GUISetState(@SW_SHOW)                    ; 显示窗口

; 事件循环
While 1
    $msg = GUIGetMsg()           ; 获取用户操作
    If $msg = $btn Then          ; 如果点击了按钮
        MsgBox(0, "标题", "内容")
    EndIf
WEnd

; 常用内置变量
@ScriptDir    ; 脚本所在目录
@WindowsDir   ; Windows 目录 (C:\Windows)
@CRLF         ; 换行符
@error        ; 上一个函数的错误码
```

## 🔍 核心功能模块说明

### 1. 文件搜索引擎
```
RecursiveFileSearch() → 递归扫描目录
    ↓ 找到目标文件
MyGlobalPatternSearch() → 读取二进制内容
    ↓ 正则匹配特征码
MyRegExpGlobalPatternSearch() → 记录匹配位置和字节
```

### 2. 补丁引擎
```
MyGlobalPatternPatch() → 备份原文件(.bak)
    ↓ 读取文件字节
按偏移位置替换字节 → 写入修改后的文件
```

### 3. 辅助工具
```
├── AGS 移除      → 停止/删除 Adobe 正版验证服务
├── Hosts 管理    → 屏蔽 Adobe 服务器域名
├── 防火墙规则    → 阻止 Adobe 程序联网
├── Runtime 解包  → UPX 解压 Adobe DLL
├── WinTrust 管理 → 跳过数字签名验证
└── DevOverride   → 注册表开发者覆盖
```

## ⚠️ 安全风险提示

本项目涉及以下高风险操作，**仅供技术学习理解原理**：

| 风险项 | 说明 |
|--------|------|
| 🔴 修改系统DLL | `patch_wintrust.ps1` 修改 Windows 签名验证核心组件 |
| 🔴 管理员权限 | 程序要求完整管理员权限运行 |
| 🟡 修改hosts | 可能影响系统网络解析 |
| 🟡 防火墙规则 | 修改 Windows 防火墙入站/出站规则 |
| 🟡 注册表修改 | DevOverride 写入注册表键值 |
| 🟡 进程操作 | 可能终止正在运行的 Adobe 进程 |

## 📋 中文化对照表（部分）

| 原版英文 | 中文翻译 | 位置 |
|----------|----------|------|
| Path | 路径 | 主页按钮 |
| Search | 搜索 | 主页按钮 |
| Stop | 停止 | 主页按钮 |
| Patch | 补丁 | 主页按钮 |
| Restore | 恢复 | 主页按钮 |
| Main | 主页 | Tab标签 |
| Options | 选项 | Tab标签 |
| Pop-up Tools | 弹窗工具 | Tab标签 |
| Log | 日志 | Tab标签 |
| GENUINE SERVICES | 正版验证服务 | 弹窗工具页 |
| FIREWALL | 防火墙 | 弹窗工具页 |
| HOSTS | HOSTS文件 | 弹窗工具页 |

## 🔗 相关链接

- **本仓库**：[github.com/nljie1103/genp-cn](https://github.com/nljie1103/genp-cn)
- **AutoIt 官网**：[autoitscript.com](https://www.autoitscript.com/)
- **AutoIt 文档**：[autoitscript.com/autoit3/docs](https://www.autoitscript.com/autoit3/docs/)

## 📝 致谢

- 原版作者：uncia / CGP 社区
- 中文化注释：学习用途

---

> 📌 **再次声明**：本项目所有内容仅用于学习 AutoIt 编程语言和 Windows 系统编程技术，了解软件逆向工程的基本原理。请遵守当地法律法规，支持正版软件。
