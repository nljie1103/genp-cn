; ============================================================
; GenP v3.8.0 - CGP 社区版 (中文注释学习版)
; 编程语言: AutoIt v3 (Windows 自动化脚本语言)
; 用途说明: Adobe 产品补丁工具，包含文件扫描、十六进制补丁、
;           hosts管理、防火墙规则、WinTrust管理等功能
; 原作者: uncia / CGP社区
; 中文注释: 仅供学习 AutoIt 编程和软件本地化参考
; ============================================================

#NoTrayIcon                ; 不在系统托盘显示图标
#RequireAdmin              ; 要求以管理员权限运行（因为需要修改系统文件）
#Region ;**** AutoIt3Wrapper 编译指令区域 ****
#AutoIt3Wrapper_Icon=Skull.ico                ; 设置编译后EXE的图标文件
#AutoIt3Wrapper_Outfile_x64=GenP-v3.8.0.exe   ; 64位输出文件名
#AutoIt3Wrapper_Res_Comment=GenP              ; EXE资源：注释
#AutoIt3Wrapper_Res_CompanyName=GenP           ; EXE资源：公司名
#AutoIt3Wrapper_Res_Description=GenP           ; EXE资源：描述
#AutoIt3Wrapper_Res_Fileversion=3.8.0.0        ; EXE资源：文件版本号
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2026   ; EXE资源：版权信息
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2026  ; EXE资源：商标信息
#AutoIt3Wrapper_Res_ProductName=GenP           ; EXE资源：产品名称
#AutoIt3Wrapper_Res_ProductVersion=3.8.0       ; EXE资源：产品版本
#AutoIt3Wrapper_Run_Au3Stripper=y              ; 编译时运行代码精简器（去除注释/空行）
#AutoIt3Wrapper_Run_Tidy=n                     ; 编译时不运行代码格式化
#AutoIt3Wrapper_UseUpx=y                       ; 编译后使用UPX压缩EXE
#AutoIt3Wrapper_UseX64=y                       ; 编译为64位EXE
#EndRegion ;**** AutoIt3Wrapper 编译指令区域结束 ****

; ============================================================
; 引入 AutoIt 标准库（UDF - User Defined Functions）
; AutoIt 通过 #include 导入内置功能库
; ============================================================
#include <Array.au3>               ; 数组操作函数（排序、扫描、去重等）
#include <ButtonConstants.au3>      ; 按钮控件常量定义
#include <Crypt.au3>               ; 加密/哈希函数（用于MD5校验）
#include <EditConstants.au3>        ; 编辑框控件常量
#include <File.au3>                ; 文件操作函数
#include <GUIConstantsEx.au3>      ; GUI扩展常量（事件、状态等）
#include <GuiEdit.au3>             ; 编辑框高级控制函数
#include <GuiListView.au3>         ; 列表视图控件函数
#include <GUITab.au3>              ; Tab选项卡控件函数
#include <GuiTreeView.au3>         ; 树形视图控件函数
#include <Inet.au3>                ; 网络操作函数（下载等）
#include <ListBoxConstants.au3>    ; 列表框常量
#include <Misc.au3>                ; 杂项函数（包含单例模式_Singleton）
#include <MsgBoxConstants.au3>     ; 消息框常量
#include <Process.au3>             ; 进程管理函数
#include <ProgressConstants.au3>   ; 进度条常量
#include <StaticConstants.au3>     ; 静态文本控件常量
#include <String.au3>              ; 字符串操作函数
#include <TreeViewConstants.au3>   ; 树形视图常量
#include <WindowsConstants.au3>    ; Windows消息/样式常量
#include <WinAPI.au3>              ; Windows API调用封装
#include <WinAPIProc.au3>          ; Windows进程API封装

AutoItSetOption("GUICloseOnESC", 0) ; 禁用ESC键关闭GUI窗口

; ============================================================
; 全局变量声明区域
; AutoIt 中 Global 声明全局变量，Local 声明局部变量
; 变量名以 $ 开头，数组用 [] 表示
; ============================================================
Global $g_Version = "3.8.0 - CGP"                                       ; 程序版本号字符串
Global $g_AppWndTitle = "GenP v" & $g_Version                            ; 主窗口标题（用于显示和单例检测）
Global $g_AppVersion = "CGP 社区版" & @CRLF & "原版作者 uncia" & @CRLF & "汉化: Jay Lean"

; 单例模式检测：确保同一时间只运行一个程序实例
If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit       ; 如果已有实例在运行，直接退出
EndIf

; --- 界面控件相关全局变量 ---
Global $MyLVGroupIsExpanded = True     ; ListView分组是否展开的状态标志
Global $g_aGroupIDs[0]                 ; 存储ListView分组ID的数组
Global $fInterrupt = 0                 ; 扫描中断标志（0=继续, 1=中断）
Global $FilesToPatch[0][1], $FilesToPatchNull[0][1]  ; 待补丁文件列表和空列表
Global $FilesToRestore[0][1], $fFilesListed = 0      ; 待恢复文件列表，文件是否已列出标志
; 主窗口和Tab页控件句柄变量
Global $MyhGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview, $idButtonSearch, $idButtonStop
; 按钮控件ID变量
Global $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag = 1
; 更多按钮和控件ID变量
Global $idBtnUpdateHosts, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAFolders, $idBtnSaveOptions, $idCustomDomainListLabel, $idCustomDomainListInput
; 弹出工具页控件变量
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF, $idBtnCreateFW, $idBtnRemoveFW, $idBtnToggleFW
Global $sRuntimeInstallerText, $idLabelRuntimeInstaller, $idBtnToggleRuntimeInstaller, $sWinTrustText, $idLabelWinTrust, $idBtnToggleWinTrust, $idBtnDevOverride
; 信息按钮和超链接控件变量
Global $idBtnAGSInfo, $idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkPopup, $g_idHyperlinkLog
Global $g_idHyperlinkGitHub  ; GitHub仓库超链接控件

; --- 配置文件读取 ---
Global $sINIPath = @ScriptDir & "\config.ini"   ; INI配置文件路径（@ScriptDir是脚本所在目录）
If Not FileExists($sINIPath) Then                 ; 如果配置文件不存在
	FileInstall("config.ini", @ScriptDir & "\config.ini")  ; 从编译资源中释放配置文件
EndIf
Global $ConfigVerVar = IniRead($sINIPath, "Info", "ConfigVer", "????")  ; 读取配置版本号

; 读取默认扫描路径，并处理多余的反斜杠
Global $MyDefPath = StringRegExpReplace(IniRead($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe"), "\\\\+", "\\")
If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	; 如果路径不存在或不是目录，重置为默认的 Adobe 安装目录
	IniWrite($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe")
	$MyDefPath = StringRegExpReplace(@ProgramFilesDir & "\Adobe", "\\\\+", "\\")
EndIf

; --- 补丁扫描相关变量 ---
Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar  ; 正则匹配计数器、总计数、进度条控件ID
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]  ; 输出十六进制数组、空数组、输入十六进制数组
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""  ; 待解析文件路径
Global $sz_type, $bFoundAcro32 = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"  ; PE类型、架构标志、特殊文件列表
Global $ProgressFileCountScale, $FileSearchedCount  ; 进度比例系数、已扫描文件计数

; --- 选项设置 ---
Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")           ; 是否始终扫描ACC（Adobe Creative Cloud）
Global $bEnableMD5 = IniRead($sINIPath, "Options", "EnableMD5", "1")       ; 是否启用MD5校验
Global $bOnlyAFolders = IniRead($sINIPath, "Options", "OnlyDefaultFolders", "1")  ; 是否只扫描名称含Adobe/Acrobat的文件夹

; --- 防火墙相关 ---
Global $g_sThirdPartyFirewall = ""     ; 第三方防火墙名称
Global $fwc = ""                       ; 防火墙命令字符串
Global $SelectedApps = []              ; 用户选中的应用程序列表

; --- Hosts文件相关 ---
Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"    ; 默认域名屏蔽列表URL
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)  ; 当前使用的域名列表URL

; --- 超链接点击防护 ---
Global $g_iHyperlinkClickTime = 0      ; 上次点击超链接的时间戳（防重复点击）
Global Const $STN_CLICKED = 0          ; 静态控件点击消息常量

; 读取配置文件中的目标文件列表（即需要补丁的Adobe文件名）
Local $tTargetFileList = IniReadSection($sINIPath, "TargetFiles")  ; 读取INI整个区段
Global $TargetFileList[0]  ; 初始化目标文件名数组
If Not @error Then
	ReDim $TargetFileList[$tTargetFileList[0][0]]
	For $i = 1 To $tTargetFileList[0][0]
		$TargetFileList[$i - 1] = StringReplace($tTargetFileList[$i][1], '"', "")
	Next
EndIf

$aSpecialFiles = IniReadSection($sINIPath, "CustomPatterns")
For $i = 1 To UBound($aSpecialFiles) - 1
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
Next
Global $g_aSignature = "r~~z}D99qox8zk|kwy|o8}"
;MsgBox(0, "", $sSpecialFiles)

; 命令行参数检查：如果传入 -updatehosts 参数则直接更新hosts文件并退出
If $CmdLine[0] = 1 And $CmdLine[1] = "-updatehosts" Then
	UpdateHostsFile()
	Exit
EndIf

; 注册Windows消息处理函数：当GUI收到WM_COMMAND消息时调用WM_COMMAND函数
GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

MainGui()

Local $bHostsbakExists = False
If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
	$bHostsbakExists = True
EndIf

; ============================================================
; 主事件循环 - 程序的核心循环
; AutoIt GUI采用消息循环模型：不断获取用户操作事件并处理
; GUIGetMsg()返回被操作的控件ID，通过Select/Case分发处理
; ============================================================
While 1
	; 动态检测hosts.bak文件状态
	Local $bHostsbakExistsNow
	If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
		$bHostsbakExistsNow = True
	Else
		$bHostsbakExistsNow = False
	EndIf

	If $bHostsbakExistsNow <> $bHostsbakExists Then
		If $bHostsbakExistsNow Then
			GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
		Else
			GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
		EndIf
		$bHostsbakExists = $bHostsbakExistsNow
	EndIf

	$idMsg = GUIGetMsg()

	Select
		; --- 事件: 窗口关闭 ---
		Case $idMsg = $GUI_EVENT_CLOSE
			GUIDelete($MyhGUI)
			_Exit()
		Case $idMsg = $GUI_EVENT_RESIZED
			ContinueCase
		Case $idMsg = $GUI_EVENT_RESTORE
			ContinueCase
		Case $idMsg = $GUI_EVENT_MAXIMIZE
			Local $iWidth
			Local $aGui = WinGetPos($MyhGUI)
			Local $aRect = _GUICtrlListView_GetViewRect($g_idListview)
			If ($aRect[2] > $aGui[2]) Then
				$iWidth = $aGui[2] - 75
			Else
				$iWidth = $aRect[2] - 25
			EndIf
			GUICtrlSendMsg($idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)

		; --- 事件: 点击停止按钮 - 中断扫描 ---
		Case $idMsg = $idButtonStop
			$ListViewSelectFlag = 0   ; Set Flag to Deselected State
			FillListViewWithInfo()
			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作。")
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)

		; --- 事件: 点击扫描按钮 - 开始扫描Adobe文件 ---
		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			;Search through all files and folders in directory and fill ListView
			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_AddItem($idListview, "", 0)
			_GUICtrlListView_AddItem($idListview, "", 1)
			_GUICtrlListView_AddItem($idListview, "", 2)
			_GUICtrlListView_AddItem($idListview, "", 2)

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 1, "准备中...", 1)
			_GUICtrlListView_AddSubItem($idListview, 2, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 3, "请耐心等待。", 1)
			_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 3, 1)

			_Expand_All_Click()
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			; Clear previous results
			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $sAppsPanelDir = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)     ; extended mode
				If UBound($aSize) >= 2 Then
					$FileCount = $aSize[1]
					RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)   ;Search through all files and folders
					ProgressWrite(0)
				EndIf
			EndIf

			$aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)     ; extended mode
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)   ;Search through all files and folders
				Sleep(100)
				ProgressWrite(0)
			EndIf

			FillListViewWithFiles()

			If _GUICtrlListView_GetItemCount($idListview) > 0 Then

				_Assign_Groups_To_Found_Files()

				$ListViewSelectFlag = 1   ; Set Flag to Selected State
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus

				If UBound($FilesToRestore) > 0 Then
					GUICtrlSetState($idBtnUpdateHosts, 128)
					GUICtrlSetState($idBtnCleanHosts, 128)
					GUICtrlSetState($idBtnEditHosts, 128)
					GUICtrlSetState($idBtnCreateFW, 128)
					GUICtrlSetState($idBtnToggleFW, 128)
					GUICtrlSetState($idBtnRemoveFW, 128)
					GUICtrlSetState($idBtnOpenWF, 128)
					GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
					GUICtrlSetState($idBtnToggleWinTrust, 128)
					GUICtrlSetState($idBtnDevOverride, 128)
					GUICtrlSetState($idBtnRemoveAGS, 128)
					GUICtrlSetState($idBtnRestoreHosts, 128)
					GUICtrlSetState($idBtnRestore, 64)
					GUICtrlSetState($idBtnAGSInfo, 128)
					GUICtrlSetState($idBtnFirewallInfo, 128)
					GUICtrlSetState($idBtnHostsInfo, 128)
					GUICtrlSetState($idBtnRuntimeInfo, 128)
					GUICtrlSetState($idBtnWintrustInfo, 128)
				EndIf
			Else
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			EndIf

			;_Collapse_All_Click()
			_Expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)

		Case $idMsg = $idButtonCustomFolder     ; Select Custom Path
			ToggleLog(0)
			MyFileOpenDialog()
			_Expand_All_Click()
			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			Else
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 64)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus
			EndIf

		Case $idMsg = $idBtnDeselectAll     ; Deselect-Select All
			ToggleLog(0)
			If $ListViewSelectFlag = 1 Then
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				Next
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
			Else
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
				Next
				$ListViewSelectFlag = 1   ; Set Flag to Selected State
			EndIf

		; --- 事件: 点击补丁按钮 - 对选中文件执行补丁 ---
		Case $idMsg = $idBtnCure
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)
					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

					MyGlobalPatternSearch($ItemFromList)
					ProgressWrite(0)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "正在处理 :)")
					LogWrite(1, $ItemFromList)
					Sleep(100)

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)


					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))


			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP 不支持 32 位版本的 Acrobat，请使用 64 位版本。")
				LogWrite(1, "GenP 不支持 32 位版本的 Acrobat，请使用 64 位版本。")
			EndIf
			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "此版本的 GenP 不支持 ARM 架构的二进制文件，仅支持 x64。")
				LogWrite(1, "此版本的 GenP 不支持 ARM 架构的二进制文件，仅支持 x64。")
			EndIf

			ToggleLog(1)
			GUICtrlSetState($hLogTab, $GUI_SHOW)

		; --- 事件: 点击恢复按钮 - 恢复已补丁文件 ---
		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "活动日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & "" & @CRLF & "配置版本: " & $ConfigVerVar & "" & @CRLF)
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList, $iCheckedItems, $iProgress
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)

					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
					$iCheckedItems = _GUICtrlListView_GetSelectedCount($idListview)
					$iProgress = 100 / $iCheckedItems
					ProgressWrite(0)
					RestoreFile($ItemFromList)

					ProgressWrite($iProgress)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "正在恢复 :)")
					Sleep(100)

					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			FillListViewWithInfo()

			ToggleLog(1)

		; --- 事件: 复制日志到剪贴板 ---
		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf

		Case $idMsg = $idEnableMD5
			If _IsChecked($idEnableMD5) Then
				$bEnableMD5 = 1
			Else
				$bEnableMD5 = 0
			EndIf

		Case $idMsg = $idOnlyAFolders
			If _IsChecked($idOnlyAFolders) Then
				$bOnlyAFolders = 1
			Else
				$bOnlyAFolders = 0
			EndIf

		; --- 事件: 保存选项设置到config.ini ---
		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		; --- 事件: 移除AGS(正版验证服务) ---
		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

		; --- 事件: 更新Hosts文件(屏蔽Adobe域名) ---
		Case $idMsg = $idBtnUpdateHosts
			ToggleLog(0)
			UpdateHostsFile()

		; --- 事件: 清除Hosts中的Adobe条目 ---
		Case $idMsg = $idBtnCleanHosts
			RemoveHostsEntries()

		; --- 事件: 手动编辑Hosts文件 ---
		Case $idMsg = $idBtnEditHosts
			EditHosts()

		; --- 事件: 从备份恢复Hosts文件 ---
		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		; --- 事件: 创建防火墙规则 ---
		Case $idMsg = $idBtnCreateFW
			ToggleLog(0)
			CreateFirewallRules()

		; --- 事件: 切换防火墙规则状态 ---
		Case $idMsg = $idBtnToggleFW
			ToggleLog(0)
			ShowToggleRulesGUI()

		; --- 事件: 删除防火墙规则 ---
		Case $idMsg = $idBtnRemoveFW
			ToggleLog(0)
			RemoveFirewallRules()

		; --- 事件: 打开Windows防火墙设置 ---
		Case $idMsg = $idBtnOpenWF
			OpenWF()

			;Case $idMsg = $idBtnCleanFirewall
			;	CleanFirewall()

			;Case $idMsg = $idBtnEnableDisableWF
			;	EnableDisableWFRules()

		; --- 事件: 运行时DLL解包 ---
		Case $idMsg = $idBtnToggleRuntimeInstaller
			ToggleLog(0)
			UnpackRuntimeInstallers()

		; --- 事件: 管理WinTrust信任 ---
		Case $idMsg = $idBtnToggleWinTrust
			ToggleLog(0)
			ManageWinTrust()

		; --- 事件: 管理DevOverride注册表 ---
		Case $idMsg = $idBtnDevOverride
			ToggleLog(0)
			ManageDevOverride()

		; --- 事件: 显示AGS功能说明弹窗 ---
		Case $idMsg = $idBtnAGSInfo
			ShowInfoPopup("移除正版验证服务及其相关文件，以消除弹出的「正版服务警告」弹窗。" & @CRLF & @CRLF & "移除操作仅会停止标题栏显示「正版服务警告」的弹窗。")

		; --- 事件: 显示防火墙功能说明弹窗 ---
		Case $idMsg = $idBtnFirewallInfo
			ShowInfoPopup("管理 Windows 防火墙规则以阻止应用访问互联网——阻止弹窗。可轻松为已安装应用添加出站规则、切换所有规则的启用/禁用、或删除所有规则。" & @CRLF & @CRLF & "注意：应用断网后某些功能可能无法使用。")

		; --- 事件: 显示Hosts功能说明弹窗 ---
		Case $idMsg = $idBtnHostsInfo
			ShowInfoPopup("管理 hosts 文件——专门针对用于弹窗的域名。可通过选项页的列表 URL 自动更新 hosts、用记事本手动编辑、移除所有条目或恢复备份。" & @CRLF & @CRLF & "hosts 文件需要定期更新才能保持有效。")

		; --- 事件: 显示运行时安装器说明弹窗 ---
		Case $idMsg = $idBtnRuntimeInfo
			ShowInfoPopup("部分应用可能使用 UPX 压缩了 RuntimeInstaller.dll 导致补丁失败。GenP 可以解包这些文件以便后续打补丁。" & @CRLF & @CRLF & @CRLF & @CRLF & _
					"UPX 5.0.1, Copyright (C) 1996-2025 Markus Oberhumer, Laszlo Molnar & John Reiser" & @CRLF & _
					"UPX is distributed under a modified GNU GPL v2. See https://github.com/upx/upx for license and source code.")

		; --- 事件: 显示WinTrust说明弹窗 ---
		Case $idMsg = $idBtnWintrustInfo
			ShowInfoPopup("通过「信任」每个应用来避免弹窗。使用修改过的 DLL + 注册表编辑来允许 DLL 重定向。可按需信任/取消信任应用或添加/移除注册表项。信任应用时注册表项会自动添加。" & @CRLF & @CRLF & "Shout out Team V.R !")
	EndSelect
WEnd

; ============================================================
; 函数: MainGui()
; 功能: 创建主GUI窗口，包含所有Tab页面、按钮、列表视图等控件
; 说明: 这是程序的核心界面创建函数
;       - Main标签页: 文件列表视图 + 扫描/补丁/恢复按钮
;       - Options标签页: 扫描选项设置
;       - Pop-up Tools标签页: AGS移除、防火墙、Hosts、RuntimeInstaller、WinTrust工具
;       - Log标签页: 活动日志显示
; ============================================================
Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 510, -1, -1, BitOR($WS_MAXIMIZEBOX, $WS_MINIMIZEBOX, $WS_SIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 510)

	$hMainTab = GUICtrlCreateTabItem("主页")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 355)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview) ; get handle for use in the notify events
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
	$iStyles = _WinAPI_GetWindowLong($MyhGUI, $GWL_STYLE)
	_WinAPI_SetWindowLong($MyhGUI, $GWL_STYLE, BitXOR($iStyles, $WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX))

	; Add columns
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "[点击展开/折叠全部]", 532, 2)

	; Build groups
	_GUICtrlListView_EnableGroupView($idListview)
	_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1) ; Group 1
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	FillListViewWithInfo()

	$idButtonCustomFolder = GUICtrlCreateButton("路径", 10, 430, 80, 30)
	GUICtrlSetTip(-1, "设置自定义扫描路径")
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton("扫描", 134, 430, 80, 30)
	GUICtrlSetTip(-1, "扫描路径中已安装的应用")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton("停止", 134, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "停止扫描")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton("补丁", 258, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "对选中的文件执行补丁")
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateButton("全选/取消", 381, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "全选/取消选择所有文件")
	GUICtrlSetImage(-1, "imageres.dll", -76, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton("恢复", 505, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "恢复原始文件")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 397, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$g_idHyperlinkMain = GUICtrlCreateLabel("gen.paramore.su", 30, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	$g_idHyperlinkGitHub = GUICtrlCreateLabel("github.com/nljie1103/genp-cn", 310, 483, 250, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkGitHub, 9, 400, 4, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkGitHub, 0x0066CC)
	GUICtrlSetBkColor($g_idHyperlinkGitHub, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkGitHub, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("选项")

	$idFindACC = GUICtrlCreateCheckbox("始终扫描 ACC（Adobe Creative Cloud）", 10, 50, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then
		GUICtrlSetState($idFindACC, $GUI_CHECKED)
	Else
		GUICtrlSetState($idFindACC, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateCheckbox("启用 MD5 校验", 10, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableMD5 = 1 Then
		GUICtrlSetState($idEnableMD5, $GUI_CHECKED)
	Else
		GUICtrlSetState($idEnableMD5, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idOnlyAFolders = GUICtrlCreateCheckbox("仅扫描名称含 Adobe/Acrobat 的文件夹", 10, 130, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then
		GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idOnlyAFolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idCustomDomainListLabel = GUICtrlCreateLabel("域名列表 URL:", 10, 180, 110, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 115, 175, 465, 20, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)

	$idBtnSaveOptions = GUICtrlCreateButton("保存选项", 247, 430, 100, 30)
	GUICtrlSetTip(-1, "保存选项到 config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkOptions, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkOptions, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkOptions, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkOptions, 0)

	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("弹窗工具")

	; --- Genuine Services ---
	$idBtnAGSInfo = GUICtrlCreateButton("?", 560, 38, 20, 20)
	GUICtrlSetFont($idBtnAGSInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnAGSInfo, $GUI_DOCKAUTO)
	$sRemoveAGSText = "正版验证服务"
	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, 5, 40, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRemoveAGS = GUICtrlCreateButton("移除 AGS", 225, 65, 140, 30)
	GUICtrlSetTip(-1, "移除正版验证服务的文件和服务以消除弹窗")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Firewall ---
	$idBtnFirewallInfo = GUICtrlCreateButton("?", 560, 113, 20, 20)
	GUICtrlSetFont($idBtnFirewallInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnFirewallInfo, $GUI_DOCKAUTO)
	$sCleanFirewallText = "防火墙"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, 5, 115, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnCreateFW = GUICtrlCreateButton("添加规则", 10, 140, 140, 30)
	GUICtrlSetTip(-1, "添加新的防火墙规则")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleFW = GUICtrlCreateButton("切换规则", 155, 140, 140, 30)
	GUICtrlSetTip(-1, "启用/禁用所有 GenP 防火墙规则")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRemoveFW = GUICtrlCreateButton("移除规则", 300, 140, 140, 30)
	GUICtrlSetTip(-1, "移除所有 GenP 防火墙规则")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnOpenWF = GUICtrlCreateButton("打开Windows防火墙", 445, 140, 140, 30)
	GUICtrlSetTip(-1, "打开 Windows 高级安全防火墙控制台")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Hosts ---
	$idBtnHostsInfo = GUICtrlCreateButton("?", 560, 188, 20, 20)
	GUICtrlSetFont($idBtnHostsInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnHostsInfo, $GUI_DOCKAUTO)
	$sEditHostsText = "HOSTS 文件"
	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, 5, 190, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnUpdateHosts = GUICtrlCreateButton("更新 hosts", 10, 215, 140, 30)
	GUICtrlSetTip(-1, "使用域名列表 URL 更新 hosts 文件")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnEditHosts = GUICtrlCreateButton("编辑 hosts", 155, 215, 140, 30)
	GUICtrlSetTip(-1, "用记事本手动编辑 hosts 文件")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnCleanHosts = GUICtrlCreateButton("清理 hosts", 300, 215, 140, 30)
	GUICtrlSetTip(-1, "移除 GenP 添加的 hosts 条目")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnRestoreHosts = GUICtrlCreateButton("恢复 hosts", 445, 215, 140, 30)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "从 hosts.bak 备份恢复 hosts 文件")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- Runtime Installer ---
	$idBtnRuntimeInfo = GUICtrlCreateButton("?", 560, 263, 20, 20)
	GUICtrlSetFont($idBtnRuntimeInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnRuntimeInfo, $GUI_DOCKAUTO)
	$sRuntimeInstallerText = "运行时安装器"
	$idLabelRuntimeInstaller = GUICtrlCreateLabel($sRuntimeInstallerText, 5, 265, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRuntimeInstaller, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleRuntimeInstaller = GUICtrlCreateButton("解包", 225, 290, 140, 30)
	GUICtrlSetTip(-1, "解包 RuntimeInstaller.dll（UPX解压）")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	; --- WinTrust ---
	$idBtnWintrustInfo = GUICtrlCreateButton("?", 560, 338, 20, 20)
	GUICtrlSetFont($idBtnWintrustInfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idBtnWintrustInfo, $GUI_DOCKAUTO)
	$sWinTrustText = "WINTRUST 信任"
	$idLabelWinTrust = GUICtrlCreateLabel($sWinTrustText, 5, 340, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelWinTrust, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnToggleWinTrust = GUICtrlCreateButton("切换 WinTrust", 155, 365, 140, 30)
	GUICtrlSetTip(-1, "启用/禁用 wintrust.dll 重定向")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idBtnDevOverride = GUICtrlCreateButton("切换注册表项", 300, 365, 140, 30)
	GUICtrlSetTip(-1, "添加/移除 DevOverrideEnable 注册表项")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkPopup = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkPopup, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkPopup, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkPopup, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkPopup, 0)

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("日志")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 355, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "活动日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & "" & @CRLF & "配置版本: " & $ConfigVerVar & "" & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("复制", 257, 430, 80, 30)
	GUICtrlSetTip(-1, "复制日志到剪贴板")
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkLog = GUICtrlCreateLabel("gen.paramore.su", (595 - 160) / 2, 483, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作。")

	GUICtrlSetState($idButtonSearch, 256) ; Set focus
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>MainGui

; ============================================================
; 函数: RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
; 功能: 递归扫描指定目录，查找与目标文件列表匹配的Adobe文件
; 参数: $INSTARTDIR - 起始目录路径
;       $DEPTH - 当前递归深度（最大8层）
;       $FileCount - 总文件数（用于进度计算）
; 说明: 使用 FileFindFirstFile/FileFindNextFile 遍历文件系统
;       匹配的文件加入 $FilesToPatch 数组，.bak文件加入 $FilesToRestore
; ============================================================
Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	_GUICtrlListView_SetItemText($idListview, 1, "正在扫描文件...", 1)
	Local $RecursiveFileSearch_MaxDeep = 8
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

	Local $STARTDIR = $INSTARTDIR & "\"
	$FileSearchedCount += 1

	Local $HSEARCH = FileFindFirstFile($STARTDIR & "*.*")
	If @error Then Return

	Local $NEXT, $IPATH, $isDir

	While $fInterrupt = 0
		$NEXT = FileFindNextFile($HSEARCH)
		$FileSearchedCount += 1

		If @error Then ExitLoop
		$isDir = StringInStr(FileGetAttrib($STARTDIR & $NEXT), "D")

		If $isDir Then
			Local $targetDepth
			$targetDepth = RecursiveFileSearch($STARTDIR & $NEXT, $DEPTH + 1, $FileCount)
		Else
			$IPATH = $STARTDIR & $NEXT
			Local $FileNameCropped, $PathToCheck
			If (IsArray($TargetFileList)) Then
				For $FileTarget In $TargetFileList
					If StringInStr($FileTarget, "$") Then
						$FileTarget = StringSplit($FileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $FileTarget[2]
						$FileTarget = $FileTarget[1]
					EndIf
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($FileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") And Not StringInStr(StringLower($IPATH), "wintrust") Then
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAFolders = 0 Then
								If $PathToCheck = "" Then
									_ArrayAdd($FilesToPatch, $IPATH)
								Else
									If StringInStr($IPATH, $PathToCheck) Then
										_ArrayAdd($FilesToPatch, $IPATH)
									EndIf
								EndIf
							EndIf
						ElseIf StringInStr($IPATH, ".bak") Then
							_ArrayAdd($FilesToRestore, $IPATH)
						EndIf
					EndIf
					$PathToCheck = ""
				Next
			EndIf
		EndIf
	WEnd

	; Lazy screen updates
	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "扫描范围: " & $FileCount & " 个文件" & @TAB & @TAB & "已找到: " & UBound($FilesToPatch) & @CRLF & _
				"---" & @CRLF & _
				"层级: " & $DEPTH & "  已用时: " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒" & @TAB & @TAB & "已排除 *.bak 文件: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR _
				)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
	EndIf

	FileClose($HSEARCH)
EndFunc   ;==>RecursiveFileSearch

; ============================================================
; 函数: FillListViewWithInfo()
; 功能: 在ListView中显示初始欢迎信息和使用提示
; 说明: 清空列表后添加GenP名称、作者信息和操作指引
; ============================================================
Func FillListViewWithInfo()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

	_Expand_All_Click()
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	; Add items
	For $i = 0 To 7
		_GUICtrlListView_AddItem($idListview, "", $i)
		_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
	Next

	_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
	_GUICtrlListView_AddSubItem($idListview, 1, "GenP", 1)
	_GUICtrlListView_AddSubItem($idListview, 2, "原版作者 uncia", 1)
	_GUICtrlListView_AddSubItem($idListview, 3, "汉化: Jay Lean", 1)
	_GUICtrlListView_AddSubItem($idListview, 4, '---------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 5, "点击「扫描」查找已安装的产品；点击「补丁」修补选中的产品/文件", 1)
	_GUICtrlListView_AddSubItem($idListview, 6, "当前扫描路径: " & $MyDefPath & " -- 点击「路径」更换", 1)
	_GUICtrlListView_AddSubItem($idListview, 7, "", 1)

	$fFilesListed = 0

EndFunc   ;==>FillListViewWithInfo

; ============================================================
; 函数: FillListViewWithFiles()
; 功能: 将扫描到的文件填充到ListView中显示
; 说明: 从 $FilesToPatch 数组读取文件路径并显示在列表中
;       同时在状态栏显示文件数量和耗时
; ============================================================
Func FillListViewWithFiles()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	If UBound($FilesToPatch) > 0 Then
		Global $aItems[UBound($FilesToPatch)][2]
		For $i = 0 To UBound($aItems) - 1
			$aItems[$i][0] = $i
			$aItems[$i][1] = $FilesToPatch[$i][0]

		Next
		_GUICtrlListView_AddArray($idListview, $aItems)

		MemoWrite(@CRLF & UBound($FilesToPatch) & " 个文件已在 " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒内找到，位置:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "点击「补丁」按钮开始补丁")
		LogWrite(1, UBound($FilesToPatch) & " 个文件已在 " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒" & @CRLF)
		;_ArrayDisplay($FilesToPatch)
		$fFilesListed = 1
	Else
		MemoWrite(@CRLF & "未找到任何文件" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
		LogWrite(1, "在以下路径中未找到任何文件: " & $MyDefPath)
		$fFilesListed = 0
	EndIf

EndFunc   ;==>FillListViewWithFiles

; Write a line to the memo control
; 函数: MemoWrite - 向状态显示区写入一行信息
Func MemoWrite($sMessage)
	GUICtrlSetData($idMemo, $sMessage)
EndFunc   ;==>MemoWrite

; 函数: LogWrite - 向日志控件追加一行记录（带/不带时间戳）
Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc   ;==>LogWrite

; 函数: ToggleLog - 切换日志/状态显示区域的可见性
Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
EndFunc   ;==>ToggleLog

; 函数: SendToClipBoard - 复制当前显示内容到剪贴板
Func SendToClipBoard()
	If BitAND(GUICtrlGetState($idMemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idLog))
	Else
		ClipPut(GUICtrlRead($idMemo))
	EndIf
EndFunc   ;==>SendToClipBoard

; 函数: GUICtrlSetDataEx - 扩展版控件数据设置，可选带时间戳
Func GUICtrlSetDataEx($hWnd, $sText, $bTS)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iLength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0x000E, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xB1, "wparam", $iLength[0], "lparam", $iLength[0]) ; $EM_SETSEL
	If $bTS = 1 Then
		Local $iData = @CRLF & $sText
	Else
		Local $iData = $sText
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xC2, "wparam", True, "wstr", $iData) ; $EM_REPLACESEL
EndFunc   ;==>GUICtrlSetDataEx

; Send a message to the Progress control
; 函数: ProgressWrite - 更新进度条显示信息
Func ProgressWrite($msg_Progress)
	;_SendMessage($hWnd_Progress, $PBM_SETPOS, $msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc   ;==>ProgressWrite


; ============================================================
; 函数: MyFileOpenDialog()
; 功能: 打开文件夹选择对话框，让用户选择Adobe安装路径
; 说明: 同时检测路径有效性并启动文件扫描
; ============================================================
Func MyFileOpenDialog()
	; Create a constant variable in Local scope of the message to display in FileOpenDialog.
	Local Const $sMessage = "选择扫描路径"

	; Display an open dialog to select a file.
	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)


	If @error Then
		; Display the error message.
		;MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)
		_GUICtrlListView_DeleteAllItems($g_idListview)
		_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
		_GUICtrlListView_AddItem($idListview, "", 0)
		_GUICtrlListView_AddItem($idListview, "", 1)
		_GUICtrlListView_AddItem($idListview, "", 2)
		_GUICtrlListView_AddItem($idListview, "", 3)
		_GUICtrlListView_AddItem($idListview, "", 4)
		_GUICtrlListView_AddItem($idListview, "", 5)
		_GUICtrlListView_AddItem($idListview, "", 6)
		_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
		_GUICtrlListView_AddSubItem($idListview, 1, "路径:", 1)
		_GUICtrlListView_AddSubItem($idListview, 2, " " & $MyDefPath, 1)
		_GUICtrlListView_AddSubItem($idListview, 3, "步骤 1:", 1)
		_GUICtrlListView_AddSubItem($idListview, 4, " 点击「扫描」- 等待扫描完成", 1)
		_GUICtrlListView_AddSubItem($idListview, 5, "步骤 2:", 1)
		_GUICtrlListView_AddSubItem($idListview, 6, " 点击「补丁」- 等待补丁完成", 1)
		_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 3, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 4, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 5, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 6, 1)
		_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "请点击扫描按钮")
		; Display the selected folder.
		;MsgBox($MB_SYSTEMMODAL, "", "You chose the following folder:" & @CRLF & $MyDefPath)
		GUICtrlSetState($idBtnUpdateHosts, 64)
		GUICtrlSetState($idBtnCleanHosts, 64)
		GUICtrlSetState($idBtnEditHosts, 64)
		GUICtrlSetState($idBtnCreateFW, 64)
		GUICtrlSetState($idBtnToggleFW, 64)
		GUICtrlSetState($idBtnRemoveFW, 64)
		GUICtrlSetState($idBtnOpenWF, 64)
		GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
		GUICtrlSetState($idBtnToggleWinTrust, 64)
		GUICtrlSetState($idBtnDevOverride, 64)
		GUICtrlSetState($idBtnRemoveAGS, 64)
		GUICtrlSetState($idBtnRestoreHosts, 64)
		GUICtrlSetState($idBtnRestore, 128)
		GUICtrlSetState($idBtnAGSInfo, 64)
		GUICtrlSetState($idBtnFirewallInfo, 64)
		GUICtrlSetState($idBtnHostsInfo, 64)
		GUICtrlSetState($idBtnRuntimeInfo, 64)
		GUICtrlSetState($idBtnWintrustInfo, 64)
		$fFilesListed = 0

	EndIf

EndFunc   ;==>MyFileOpenDialog


; 函数: _ProcessCloseEx - 安全关闭指定进程
Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc   ;==>_ProcessCloseEx


; ============================================================
; 函数: MyGlobalPatternSearch($MyFileToParse)
; 功能: 对单个文件执行全局特征码扫描
; 说明: 读取文件二进制内容，依次匹配所有扫描模式
;       记录匹配结果到全局数组中
; ============================================================
Func MyGlobalPatternSearch($MyFileToParse)
	;ConsoleWrite($MyFileToParse & @CRLF)
	$aInHexArray = $aNullArray   ; Nullifay Array that will contain Hex later
	$aOutHexGlobalArray = $aNullArray     ; Nullifay Array that will contain Hex later

	ProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15

	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")

	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "准备分析中" & @CRLF & "---" & @CRLF & "*****")
	LogWrite(1, "检查文件: " & $sFileName & " ")
	;MsgBox($MB_SYSTEMMODAL,"","$sFileName = " & $sFileName & @CRLF & "$sExt = " & $sExt)

	If $sExt = "exe" Then
		_ProcessCloseEx("""" & $sFileName & """")
	EndIf

	If $sFileName = "Adobe Desktop Service.exe" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		Sleep(100)
	EndIf

	If $sFileName = "AppsPanelBL.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf

	If $sFileName = "HDPIM.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf

	If StringInStr($sSpecialFiles, $sFileName) Then
		;MsgBox($MB_SYSTEMMODAL, "", "Special File: " & $sFileName)
		LogWrite(0, " - 使用自定义补丁模式")
		ExecuteSearchPatterns($sFileName, 0, $MyFileToParse)
	Else
		LogWrite(0, " - 使用默认补丁模式")
		ExecuteSearchPatterns($sFileName, 1, $MyFileToParse)
		;MsgBox($MB_SYSTEMMODAL, "", "File: " & $sFileName & @CRLF & "Not in Special Files")
	EndIf
	Sleep(100)
EndFunc   ;==>MyGlobalPatternSearch

; ============================================================
; 函数: ExecuteSearchPatterns()
; 功能: 执行扫描特征码匹配逻辑
; 说明: 对给定文件内容执行默认+自定义模式的正则扫描
; ============================================================
Func ExecuteSearchPatterns($FileName, $DefaultPatterns, $MyFileToParse)

	Local $aPatterns, $sPattern, $sData, $aArray, $sSearch, $sReplace, $iPatternLength

	If $DefaultPatterns = 0 Then
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	;_ArrayDisplay($aPatterns, "Patterns for " & $FileName)

	For $i = 0 To UBound($aPatterns) - 1
		$sPattern = $aPatterns[$i]
		$sData = IniRead($sINIPath, "Patches", $sPattern, "")
		If StringInStr($sData, "|") Then
			$aArray = StringSplit($sData, "|")
			If UBound($aArray) = 3 Then

				$sSearch = StringReplace($aArray[1], '"', '')
				$sReplace = StringReplace($aArray[2], '"', '')

				$iPatternLength = StringLen($sSearch)
				If $iPatternLength <> StringLen($sReplace) Or Mod($iPatternLength, 2) <> 0 Then
					MsgBox($MB_SYSTEMMODAL, "Error", "config.ini 中的模式错误:" & $sPattern & @CRLF & $sSearch & @CRLF & $sReplace)
					Exit
				EndIf

				;MsgBox(0,0, $MyFileToParse & @CRLF & $sSearch & @CRLF  & $aReplace & @CRLF  & $sPattern )
				LogWrite(1, "正在扫描: " & $sPattern & ": " & $sSearch)

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

				;Exit ; STOP AT FIRST VALUE - COMMENT OUT TO CONTINUE
			EndIf
			;Exit
		EndIf

	Next

EndFunc   ;==>ExecuteSearchPatterns


; ============================================================
; 函数: MyRegExpGlobalPatternSearch()
; 功能: 使用正则表达式在文件中执行全局特征码扫描
; 说明: 核心扫描引擎 - 读取二进制文件内容并用正则匹配
;       找到匹配后记录位置、原始字节和替换字节
;       支持多次匹配和重叠检测
; ============================================================
Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)  ; Path to a file to parse
	;MsgBox($MB_SYSTEMMODAL, "Path", $FileToParse)
	;ConsoleWrite($FileToParse & @CRLF)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	FileSetPos($hFileOpen, 60, 0)

	$sz_type = FileRead($hFileOpen, 4)
	FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

	$sz_type = FileRead($hFileOpen, 2)

	If $sz_type = "0x4C01" And StringInStr($FileToParse, "Acrobat", 2) > 0 Then ; Acrobat x86 won't work with this script

		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "文件为 32 位版本，中止处理..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundAcro32 = True

	ElseIf $sz_type = "0x64AA" Then
		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "文件为 ARM 架构，中止处理..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundGenericARM = True

	Else

		FileSetPos($hFileOpen, 0, 0)

		Local $sFileRead = FileRead($hFileOpen)

		Local $GeneQuestionMark, $AnyNumOfBytes, $OutStringForRegExp
		For $i = 256 To 1 Step -2 ; limiting to 256 -?-
			$GeneQuestionMark = _StringRepeat("??", $i / 2) ; Repeat the string -??- $i/2 times.
			$AnyNumOfBytes = "(.{" & $i & "})"
			$OutStringForRegExp = StringReplace($PatternToSearch, $GeneQuestionMark, $AnyNumOfBytes)
			$PatternToSearch = $OutStringForRegExp
		Next

		Local $sSearchPattern = $OutStringForRegExp     ;string
		Local $aReplacePattern = $PatternToReplace     ;string
		Local $sWildcardSearchPattern = "", $sWildcardReplacePattern = "", $sFinalReplacePattern = ""
		Local $aInHexTempArray[0]
		Local $sSearchCharacter = "", $sReplaceCharacter = ""

		$aInHexTempArray = $aNullArray
		$aInHexTempArray = StringRegExp($sFileRead, $sSearchPattern, $STR_REGEXPARRAYGLOBALFULLMATCH, 1)

		For $i = 0 To UBound($aInHexTempArray) - 1

			$aInHexArray = $aNullArray
			$sSearchCharacter = ""
			$sReplaceCharacter = ""
			$sWildcardSearchPattern = ""
			$sWildcardReplacePattern = ""
			$sFinalReplacePattern = ""


			$aInHexArray = $aInHexTempArray[$i]
			;_ArrayDisplay($aInHexArray)

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]   ; full founded Search Pattern index 0
				$sWildcardReplacePattern = $aReplacePattern

				;MsgBox(-1,"",$sWildcardSearchPattern & @CRLF & $sWildcardReplacePattern) ; full search and full patch with ?? symbols

				If StringInStr($sWildcardReplacePattern, "?") Then
					;MsgBox($MB_SYSTEMMODAL, "Found ? symbol", "Constructing new Replace string")
					For $j = 1 To StringLen($sWildcardReplacePattern) + 1
						; Retrieve a characters from the $jth position in each string.
						$sSearchCharacter = StringMid($sWildcardSearchPattern, $j, 1)
						$sReplaceCharacter = StringMid($sWildcardReplacePattern, $j, 1)

						If $sReplaceCharacter <> "?" Then
							$sFinalReplacePattern &= $sReplaceCharacter
						Else
							$sFinalReplacePattern &= $sSearchCharacter
						EndIf

					Next
				Else
					$sFinalReplacePattern = $sWildcardReplacePattern
				EndIf

				_ArrayAdd($aOutHexGlobalArray, $sWildcardSearchPattern)
				_ArrayAdd($aOutHexGlobalArray, $sFinalReplacePattern)

				ConsoleWrite($PatternName & "---" & @TAB & $sWildcardSearchPattern & "	" & @CRLF)
				ConsoleWrite($PatternName & "R" & "--" & @TAB & $sFinalReplacePattern & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & @CRLF & "---" & @CRLF & $sWildcardSearchPattern & @CRLF & $sFinalReplacePattern)
				LogWrite(1, "替换为: " & $sFinalReplacePattern)

			Else
				ConsoleWrite($PatternName & "---" & @TAB & "鍚? & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & "---" & "鍚?)
			EndIf
			$MyRegExpGlobalPatternSearchCount += 1

		Next
		FileClose($hFileOpen)
		$sFileRead = ""
		ProgressWrite(Round($MyRegExpGlobalPatternSearchCount / $Count * 100))
		Sleep(100)

	EndIf      ;==>If $sz_type = "0x4C01"

EndFunc   ;==>MyRegExpGlobalPatternSearch


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
; 功能: 对文件执行全局特征码补丁（写入修改）
; 说明: 核心补丁引擎 - 先备份原文件，再将扫描到的
;       特征码位置替换为目标字节序列
; ============================================================
Func MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
	;MsgBox($MB_SYSTEMMODAL, "", $MyFileToPatch)
	;_ArrayDisplay($MyArrayToPatch)
	ProgressWrite(0)
	;MemoWrite("Current path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "正在处理 :)")
	Local $iRows = UBound($MyArrayToPatch) ; Total number of rows
	If $iRows > 0 Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "正在处理 :)")
		Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
		Local $sFileRead = FileRead($hFileOpen)
		Local $sStringOut

		For $i = 0 To $iRows - 1 Step 2
			$sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
			$sFileRead = $sStringOut
			$sStringOut = $sFileRead
			ProgressWrite(Round($i / $iRows * 100))
		Next

		;MsgBox($MB_SYSTEMMODAL, "", "binary: " & Binary($sStringOut))
		FileClose($hFileOpen)
		FileMove($MyFileToPatch, $MyFileToPatch & ".bak", $FC_OVERWRITE)
		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		FileWrite($hFileOpen1, Binary($sStringOut))
		FileClose($hFileOpen1)
		ProgressWrite(0)
		Sleep(100)
		;MemoWrite1(@CRLF & "---" & @CRLF & "Waitng for your command :)" & @CRLF & "---")

		LogWrite(1, "文件已由 GenP 补丁 " & $g_Version & " + config " & $ConfigVerVar)
		If $bEnableMD5 = 1 Then
			_Crypt_Startup()
			Local $sMD5Checksum = _Crypt_HashFile($MyFileToPatch, $CALG_MD5)
			If Not @error Then
				LogWrite(1, "MD5 校验值: " & $sMD5Checksum & @CRLF)
			EndIf
			_Crypt_Shutdown()
		EndIf

	Else
		;Empty array - > no search-replace patterns
		;File is already patched or no patterns were found .
		MemoWrite(@CRLF & "未找到匹配的模式" & @CRLF & "---" & @CRLF & "或" & @CRLF & "---" & @CRLF & "文件已被补丁过。")
		Sleep(100)

		LogWrite(1, "未找到匹配模式或文件已被补丁。" & @CRLF)

	EndIf
	;Sleep(100)
	;MemoWrite2("***")
EndFunc   ;==>MyGlobalPatternPatch

; ============================================================
; 函数: RestoreFile($MyFileToDelete)
; 功能: 恢复已补丁文件到原始状态
; 说明: 通过将 .bak 备份文件覆盖回原文件来撤销补丁
; ============================================================
Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		If $MyFileToDelete = "AppsPanelBL.dll" Or $MyFileToDelete = "Adobe Desktop Service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf
		FileDelete($MyFileToDelete)
		FileMove($MyFileToDelete & ".bak", $MyFileToDelete, $FC_OVERWRITE)
		Sleep(100)
		MemoWrite(@CRLF & "文件已恢复" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "文件已恢复。")
	Else
		Sleep(100)
		MemoWrite(@CRLF & "未找到备份文件" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "鏈壘鍒板浠芥枃浠躲€?)
	EndIf
EndFunc   ;==>RestoreFile

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; 函数: _ListView_LeftClick - ListView左键点击事件处理（选中/取消勾选）
Func _ListView_LeftClick($hListView, $lParam)
	Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)
	Local $iIndex = DllStructGetData($tInfo, "Index")

	If $iIndex <> -1 Then
		Local $iX = DllStructGetData($tInfo, "X")
		Local $aIconRect = _GUICtrlListView_GetItemRect($hListView, $iIndex, 1)
		If $iX < $aIconRect[0] And $iX >= 5 Then
			Return 0
		Else
			Local $aHit
			$aHit = _GUICtrlListView_HitTest($g_idListview)
			If $aHit[0] <> -1 Then
				Local $GroupIdOfHitItem = _GUICtrlListView_GetItemGroupID($idListview, $aHit[0])
				If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
						EndIf
					Next
				EndIf
				;$g_iIndex = $aHit[0]
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_ListView_LeftClick

; 函数: _ListView_RightClick - ListView右键点击事件处理（弹出上下文菜单）
Func _ListView_RightClick()
	Local $aHit
	$aHit = _GUICtrlListView_HitTest($g_idListview)
	If $aHit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 1)
		EndIf
		;$g_iIndex = $aHit[0]
	EndIf
EndFunc   ;==>_ListView_RightClick

; ============================================================
; 函数: _Assign_Groups_To_Found_Files()
; 功能: 将扫描到的文件按产品分组并显示在ListView中
; 说明: 根据文件路径识别Adobe产品名称，创建分组
;       为每个文件分配到对应产品组下显示
; ============================================================
Func _Assign_Groups_To_Found_Files()
	ConsoleWrite("Entering _Assign_Groups_To_Found_Files()" & @CRLF)
	Local $MyListItemCount = _GUICtrlListView_GetItemCount($idListview)
	ConsoleWrite("Item Count in ListView: " & $MyListItemCount & @CRLF)
	Local $ItemFromList
	Local $aGroups[0]
	Local $iGroupID = 1

	ReDim $g_aGroupIDs[0]

	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		ConsoleWrite("Item Text (Column 2): " & $ItemFromList & @CRLF)

		Local $sGroupName = ""
		Select
			Case StringInStr($ItemFromList, "AppsPanel") Or StringInStr($ItemFromList, "Adobe Desktop Service") Or StringInStr($ItemFromList, "HDPIM")
				$sGroupName = "Creative Cloud"
			Case StringInStr($ItemFromList, "Acrobat")
				$sGroupName = "Acrobat"
			Case StringInStr($ItemFromList, "Aero")
				$sGroupName = "Aero"
			Case StringInStr($ItemFromList, "After Effects")
				$sGroupName = "After Effects"
			Case StringInStr($ItemFromList, "Animate")
				$sGroupName = "Animate"
			Case StringInStr($ItemFromList, "Audition")
				$sGroupName = "Audition"
			Case StringInStr($ItemFromList, "Adobe Bridge")
				$sGroupName = "Bridge"
			Case StringInStr($ItemFromList, "Character Animator")
				$sGroupName = "Character Animator"
			Case StringInStr($ItemFromList, "Dimension")
				$sGroupName = "Dimension"
			Case StringInStr($ItemFromList, "Dreamweaver")
				$sGroupName = "Dreamweaver"
			Case StringInStr($ItemFromList, "Elements") And StringInStr($ItemFromList, "Organizer")
				$sGroupName = "Elements Organizer"
			Case StringInStr($ItemFromList, "Illustrator")
				$sGroupName = "Illustrator"
			Case StringInStr($ItemFromList, "InCopy")
				$sGroupName = "InCopy"
			Case StringInStr($ItemFromList, "InDesign")
				$sGroupName = "InDesign"
			Case StringInStr($ItemFromList, "Lightroom CC")
				$sGroupName = "Lightroom CC"
			Case StringInStr($ItemFromList, "Lightroom Classic")
				$sGroupName = "Lightroom Classic"
			Case StringInStr($ItemFromList, "Media Encoder")
				$sGroupName = "Media Encoder"
			Case StringInStr($ItemFromList, "Photoshop Elements")
				$sGroupName = "Photoshop Elements"
			Case StringInStr($ItemFromList, "Photoshop")
				$sGroupName = "Photoshop"
			Case StringInStr($ItemFromList, "Premiere Elements")
				$sGroupName = "Premiere Elements"
			Case StringInStr($ItemFromList, "Premiere Pro")
				$sGroupName = "Premiere Pro"
			Case StringInStr($ItemFromList, "Premiere Rush")
				$sGroupName = "Premiere Rush"
			Case StringInStr($ItemFromList, "Substance 3D Designer")
				$sGroupName = "Substance 3D Designer"
			Case StringInStr($ItemFromList, "Substance 3D Modeler")
				$sGroupName = "Substance 3D Modeler"
			Case StringInStr($ItemFromList, "Substance 3D Painter")
				$sGroupName = "Substance 3D Painter"
			Case StringInStr($ItemFromList, "Substance 3D Sampler")
				$sGroupName = "Substance 3D Sampler"
			Case StringInStr($ItemFromList, "Substance 3D Stager")
				$sGroupName = "Substance 3D Stager"
			Case StringInStr($ItemFromList, "Substance 3D Viewer")
				$sGroupName = "Substance 3D Viewer"
			Case Else
				$sGroupName = "Else"
		EndSelect

		ConsoleWrite("Group Name Assigned: " & $sGroupName & @CRLF)

		Local $iGroupIndex = _ArraySearch($aGroups, $sGroupName)
		If $iGroupIndex = -1 Then
			_ArrayAdd($aGroups, $sGroupName)
			_GUICtrlListView_InsertGroup($idListview, $i, $iGroupID, "", 1)
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupID)
			_GUICtrlListView_SetGroupInfo($idListview, $iGroupID, $sGroupName, 1, $LVGS_COLLAPSIBLE)
			_ArrayAdd($g_aGroupIDs, $iGroupID)
			ConsoleWrite("New Group Created - ID: " & $iGroupID & @CRLF)
			$iGroupID += 1
		Else
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupIndex + 1)
			ConsoleWrite("Assigned to Existing Group: " & $sGroupName & " (ID: " & $iGroupIndex + 1 & ")" & @CRLF)
		EndIf
	Next

	For $i = 0 To $MyListItemCount - 1
		_GUICtrlListView_SetItemChecked($idListview, $i, 1)
	Next

	ConsoleWrite("Exiting _Assign_Groups_To_Found_Files()" & @CRLF)
	ConsoleWrite("Number of Groups in $g_aGroupIDs: " & UBound($g_aGroupIDs) & @CRLF)
	For $i = 0 To UBound($g_aGroupIDs) - 1
		ConsoleWrite("Group ID in $g_aGroupIDs: " & $g_aGroupIDs[$i] & @CRLF)
	Next
EndFunc   ;==>_Assign_Groups_To_Found_Files

; 函数: _Collapse_All_Click - 折叠ListView中所有分组
Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

			For $i = 1 To 25
				$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
				If IsArray($aInfo) Then
					_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
			_RedrawWindow($idListview)
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
	EndIf
EndFunc   ;==>_Collapse_All_Click

; 函数: _Expand_All_Click - 展开ListView中所有分组
Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

		For $i = 1 To 25
			$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
			If IsArray($aInfo) Then
				_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
		_RedrawWindow($idListview)
	EndIf
EndFunc   ;==>_Expand_All_Click

; 函数: _SendMessageL - 发送Windows消息（Long参数版本）
Func _SendMessageL($hWnd, $Msg, $wParam, $lParam)
	Return DllCall("user32.dll", "LRESULT", "SendMessageW", "HWND", GUICtrlGetHandle($hWnd), "UINT", $Msg, "WPARAM", $wParam, "LPARAM", $lParam)[0]
EndFunc   ;==>_SendMessageL

; 函数: _RedrawWindow - 强制重绘指定窗口
Func _RedrawWindow($hWnd)
	DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", GUICtrlGetHandle($hWnd), "ptr", 0, "ptr", 0, "uint", 0x0100)
EndFunc   ;==>_RedrawWindow

; 函数: WM_COMMAND - Windows WM_COMMAND消息处理回调
Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) = $idButtonStop Then $fInterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND

; 函数: WM_NOTIFY - Windows WM_NOTIFY消息处理回调（ListView通知）
Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	Local $iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $g_idListview
			Switch $iCode
				Case $LVN_COLUMNCLICK
					_Collapse_All_Click()
				Case $NM_CLICK
					_ListView_LeftClick($g_idListview, $lParam)
				Case $NM_RCLICK
					_ListView_RightClick()
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

; 函数: hL_WM_COMMAND - 子控件WM_COMMAND消息处理
Func hL_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF)
	Local $iCode = BitShift($wParam, 16)

	If $iCode = $STN_CLICKED Then
		If $iIDFrom = $g_idHyperlinkGitHub Then
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute("https://github.com/nljie1103/genp-cn")
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
			Return $GUI_RUNDEFMSG
		EndIf
		If $iIDFrom = $g_idHyperlinkMain Or $iIDFrom = $g_idHyperlinkLog Or $iIDFrom = $g_idHyperlinkOptions Or $iIDFrom = $g_idHyperlinkPopup Then
			Local $sUrl = Deloader($g_aSignature)
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute($sUrl)
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
			Return $GUI_RUNDEFMSG
		EndIf
	EndIf

	Return WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>hL_WM_COMMAND

; 函数: _Exit - 程序退出清理（销毁GUI并退出）
Func _Exit()
	Exit
EndFunc   ;==>_Exit

; ============================================================
; 函数: IniReadArray($FileName, $section, $key, $default)
; 功能: 从INI文件读取逗号分隔值并转为数组
; 说明: 读取INI键值，按逗号分割成字符串数组返回
; ============================================================
Func IniReadArray($FileName, $section, $key, $default)
	Local $sINI = IniRead($FileName, $section, $key, $default)
	$sINI = StringReplace($sINI, '"', '')
	StringReplace($sINI, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sINI, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc   ;==>IniReadArray

; 函数: ReplaceToArray - 将逗号分隔字符串转换为数组
Func ReplaceToArray($sParam)
	Local $sString = StringReplace($sParam, '"', '')
	StringReplace($sString, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sString, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc   ;==>ReplaceToArray

; 函数: _IsChecked - 检查复选框控件是否被选中
Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked


; ============================================================
; 函数: SaveOptionsToConfig()
; 功能: 将当前所有选项设置保存到config.ini文件
; 说明: 读取GUI中各复选框状态并写入INI配置文件
; ============================================================
Func SaveOptionsToConfig()
	If _IsChecked($idFindACC) Then
		IniWrite($sINIPath, "Options", "FindACC", "1")
	Else
		IniWrite($sINIPath, "Options", "FindACC", "0")
	EndIf
	If _IsChecked($idEnableMD5) Then
		IniWrite($sINIPath, "Options", "EnableMD5", "1")
	Else
		IniWrite($sINIPath, "Options", "EnableMD5", "0")
	EndIf
	If _IsChecked($idOnlyAFolders) Then
		IniWrite($sINIPath, "Options", "OnlyDefaultFolders", "1")
	Else
		IniWrite($sINIPath, "Options", "OnlyDefaultFolders", "0")
	EndIf

	Local $sNewDomainListURL = StringStripWS(GUICtrlRead($idCustomDomainListInput), 1)

	If $sNewDomainListURL = "" Then
		$sNewDomainListURL = $sDefaultDomainListURL
		GUICtrlSetData($idCustomDomainListInput, $sNewDomainListURL)
		MsgBox(0, "URL为空", "自定义域名列表 URL 不能为空，已设置为默认 URL。")
	EndIf

	If $sNewDomainListURL <> $sCurrentDomainListURL Then
		IniWrite($sINIPath, "Options", "CustomDomainListURL", $sNewDomainListURL)
		$sCurrentDomainListURL = $sNewDomainListURL
	EndIf
EndFunc   ;==>SaveOptionsToConfig

; 函数: Deloader - 资源释放/卸载辅助函数
Func Deloader($sLoaded)
	Local $sDeloaded = ""
	For $i = 1 To StringLen($sLoaded)
		Local $iAscii = Asc(StringMid($sLoaded, $i, 1))
		$sDeloaded &= Chr($iAscii - 10)
	Next
	Return $sDeloaded
EndFunc   ;==>Deloader

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: ShowInfoPopup($sText)
; 功能: 显示信息弹窗（用于各功能的详细说明）
; 说明: 创建一个带滚动文本框的信息窗口
; ============================================================
Func ShowInfoPopup($sText)
	Local $aMainPos = WinGetPos($MyhGUI)
	If @error Then
		Local $iPopupX = -1
		Local $iPopupY = -1
	Else
		Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 450) / 2
		Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 250) / 2
	EndIf

	Local $hPopup = GUICreate("说明", 450, 250, $iPopupX, $iPopupY, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_BORDER), $WS_EX_TOPMOST)
	Local $idEdit = GUICtrlCreateEdit($sText, 10, 10, 425, 195, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL), 0)
	GUICtrlSetFont($idEdit, 9, 400, 0, "Microsoft YaHei UI")
	GUICtrlSetBkColor($idEdit, 0xF0F0F0)
	Local $idBtnClose = GUICtrlCreateButton("关闭", 185, 212, 80, 28)
	GUISetState(@SW_SHOW, $hPopup)
	_GUICtrlEdit_SetSel($idEdit, -1, -1)
	While 1
		Local $iMsg = GUIGetMsg()
		If $iMsg = $GUI_EVENT_CLOSE Or $iMsg = $idBtnClose Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc   ;==>ShowInfoPopup

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: RemoveAGS()
; 功能: 移除Adobe正版验证服务(AGS)
; 说明: 停止AGS服务/进程，删除相关文件和目录
;       阻止Adobe进行正版许可证验证
; ============================================================
Func RemoveAGS()
	GUICtrlSetState($idBtnRemoveAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "正在从此计算机移除 AGS" & @CRLF & "---" & @CRLF & "请稍候...")

	Local $aServices = ["AGMService", "AGSService"]
	Local $ProgramFilesX86 = EnvGet("ProgramFiles(x86)")
	Local $PublicDir = EnvGet("PUBLIC")
	Local $WinDir = @WindowsDir
	Local $LocalAppData = EnvGet("LOCALAPPDATA")
	Local $aPaths[9] = [ _
			$ProgramFilesX86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe", _
			$ProgramFilesX86 & "\Common Files\Adobe\AdobeGCClient", _
			$ProgramFilesX86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient", _
			$PublicDir & "\Documents\AdobeGCData", _
			$WinDir & "\System32\Tasks\AdobeGCInvoker-1.0", _
			$WinDir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0", _
			$ProgramFilesX86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe", _
			$WinDir & "\Temp\adobegc.log", _
			$LocalAppData & "\Temp\adobegc.log" _
			]

	Local $iServiceSuccess = 0
	For $sService In $aServices
		Local $iExistCode = RunWait("sc query " & $sService, "", @SW_HIDE)
		If $iExistCode = 1060 Then
			LogWrite(1, "未找到服务: " & $sService)
			ContinueLoop
		ElseIf $iExistCode <> 0 Then
			LogWrite(1, "妫€鏌ユ湇鍔″嚭閿?" & $sService & " (exit code: " & $iExistCode & ")")
			ContinueLoop
		EndIf
		LogWrite(1, "发现服务: " & $sService)

		Local $iStopPID = Run("sc stop " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iStopPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iStopPID)
			LogWrite(1, "璀﹀憡: 鍋滄鏈嶅姟澶辫触 " & $sService & " - timed out after " & $iTimeout & "ms")
		Else
			Local $iStopCode = @error ? 1 : 0
			If $iStopCode = 0 Or StringInStr(StderrRead($iStopPID), "1052") Then
				LogWrite(1, "服务已停止: " & $sService)
			Else
				LogWrite(1, "鍋滄鏈嶅姟澶辫触 " & $sService & " (possible error)")
			EndIf
		EndIf

		Local $iDeletePID = Run("sc delete " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		$iWaitResult = ProcessWaitClose($iDeletePID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iDeletePID)
			LogWrite(1, "璀﹀憡: 鍒犻櫎鏈嶅姟澶辫触 " & $sService & " - timed out after " & $iTimeout & "ms")
		Else
			Local $iDeleteCode = @error ? 1 : 0
			If $iDeleteCode = 0 Then
				LogWrite(1, "服务已删除: " & $sService)
				$iServiceSuccess += 1
			Else
				LogWrite(1, "鍒犻櫎鏈嶅姟澶辫触 " & $sService & " (possible error)")
			EndIf
		EndIf
	Next

	Local $iFileSuccess = 0
	For $sPath In $aPaths
		If FileExists($sPath) Then
			If StringInStr(FileGetAttrib($sPath), "D") Then
				If DirRemove($sPath, 1) Then
					LogWrite(1, "已删除目录: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "无法删除目录: " & $sPath)
				EndIf
			Else
				If FileDelete($sPath) Then
					LogWrite(1, "已删除文件: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "无法删除文件: " & $sPath)
				EndIf
			EndIf
		Else
			LogWrite(1, "未找到文件或目录: " & $sPath)
		EndIf
	Next

	MemoWrite("AGS 移除完成。成功处理 " & $iServiceSuccess & " / " & UBound($aServices) & " 个服务和 " & $iFileSuccess & " / " & UBound($aPaths) & " 个文件。")
	LogWrite(1, "AGS 移除完成。服务: " & $iServiceSuccess & "/" & UBound($aServices) & ", Files: " & $iFileSuccess & "/" & UBound($aPaths) & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnRemoveAGS, $GUI_ENABLE)
EndFunc   ;==>RemoveAGS

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: RemoveHostsEntries()
; 功能: 从hosts文件中移除Adobe相关屏蔽条目
; 说明: 读取hosts文件内容，删除包含Adobe域名的行
; ============================================================
Func RemoveHostsEntries()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sTempHosts = @TempDir & "\temp_hosts_remove.tmp"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	FileSetAttrib($sHostsPath, "-R")

	Local $sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("读取 hosts 文件失败。" & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf

	If Not StringInStr($sHostsContent, $sMarkerStart) Or Not StringInStr($sHostsContent, $sMarkerEnd) Then
		LogWrite(1, "没有需要移除的条目。" & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		ToggleLog(1)
		Return True
	EndIf

	$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)" & $sMarkerStart & ".*?" & $sMarkerEnd, "")

	Local $hTempFile = FileOpen($sTempHosts, 2)
	If $hTempFile = -1 Then
		MemoWrite("创建临时 hosts 文件失败。" & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileWrite($hTempFile, $sHostsContent)
	FileClose($hTempFile)

	If Not FileCopy($sTempHosts, $sHostsPath, 1) Then
		MemoWrite("写入更新后的 hosts 文件失败。" & @CRLF)
		MemoWrite("姝ｅ湪澶嶅埗: " & $sTempHosts & " 鍒? " & $sHostsPath & @CRLF)
		FileDelete($sTempHosts)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileDelete($sTempHosts)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "已清理 hosts 文件中的现有条目。" & @CRLF)
	ToggleLog(1)
	Return True
EndFunc   ;==>RemoveHostsEntries

; ============================================================
; 函数: ScanDNSCache(ByRef $sHostsContent)
; 功能: 扫描DNS缓存中的Adobe域名
; 说明: 运行ipconfig /displaydns获取缓存记录
;       将发现的Adobe域名添加到hosts屏蔽列表中
; ============================================================
Func ScanDNSCache(ByRef $sHostsContent)
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	Local $sBlockSection = StringRegExp($sHostsContent, "(?s)" & $sMarkerStart & "(.*?)" & $sMarkerEnd, 1)
	If @error Or UBound($sBlockSection) = 0 Then
		MemoWrite("解析 hosts 内容中的屏蔽列表时出错。" & @CRLF)
		Return 0
	EndIf
	Local $aCurrentDomains = StringSplit(StringStripWS($sBlockSection[0], 8), @CRLF, 2)
	Local $aHostsDomains[0]
	For $i = 0 To UBound($aCurrentDomains) - 1
		Local $sLine = StringStripWS($aCurrentDomains[$i], 3)
		If StringRegExp($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$") Then
			_ArrayAdd($aHostsDomains, StringRegExpReplace($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$", "$1"))
		EndIf
	Next
	_ArraySort($aHostsDomains)
	_ArrayUnique($aHostsDomains)

	Local $sTempDNS = @TempDir & "\dns_cache.txt"
	Local $iPID = Run(@ComSpec & " /c ipconfig /displaydns > " & $sTempDNS, "", @SW_HIDE)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: ipconfig /displaydns 超时 (" & $iTimeout & "ms." & @CRLF)
	EndIf

	Local $sDNSCache = FileRead($sTempDNS)
	If @error Then
		MemoWrite("读取 DNS 缓存出错。" & @CRLF)
		FileDelete($sTempDNS)
		Return 0
	EndIf
	FileDelete($sTempDNS)

	Local $aDNSDomains = StringRegExp($sDNSCache, "Record Name[^\n]*?\n\s*:\s*([^\n]*adobestats\.io[^\n]*)", 3)
	If UBound($aDNSDomains) = 0 Then
		Return 0
	EndIf
	_ArraySort($aDNSDomains)
	_ArrayUnique($aDNSDomains)

	Local $aNewDomains[0]
	For $i = 0 To UBound($aDNSDomains) - 1
		Local $sDomain = StringStripWS($aDNSDomains[$i], 3)
		If _ArraySearch($aHostsDomains, $sDomain) = -1 Then
			_ArrayAdd($aNewDomains, $sDomain)
		EndIf
	Next

	If UBound($aNewDomains) = 0 Then
		Return 0
	EndIf

	Local $sPrompt = "在 DNS 缓存中发现 " & UBound($aNewDomains) & " 个新域名:" & @CRLF & _
			_ArrayToString($aNewDomains, @CRLF) & @CRLF & "是否添加到 hosts 文件？"
	Local $iResponse = MsgBox($MB_YESNO + $MB_ICONQUESTION, "检测到新域名", $sPrompt)
	If $iResponse = $IDNO Then
		MemoWrite("用户拒绝添加新的 DNS 域名。" & @CRLF)
		Return 0
	EndIf

	Return $aNewDomains
EndFunc   ;==>ScanDNSCache

; ============================================================
; 函数: UpdateHostsFile()
; 功能: 更新hosts文件添加Adobe域名屏蔽条目
; 说明: 将预定义的Adobe服务器域名指向127.0.0.1
;       同时可选扫描DNS缓存添加额外域名
; ============================================================
Func UpdateHostsFile()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	RemoveHostsEntries()
	GUICtrlSetState($idBtnUpdateHosts, $GUI_DISABLE)
	MemoWrite(@CRLF & "开始更新 hosts 文件..." & @CRLF)

	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = $sHostsPath & ".bak"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"
	Local $sDomainListURL = $sCurrentDomainListURL
	Local $sTempFileDownload, $sDomainList, $sHostsContent, $hFile

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		If Not FileCopy($sHostsPath, $sBackupPath, 1) Then
			MemoWrite("创建 hosts 备份失败。" & @CRLF)
			GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
			FileSetAttrib($sHostsPath, "+R")
			Return
		EndIf
		MemoWrite("hosts 文件已备份。" & @CRLF)
	EndIf

	$sTempFileDownload = _TempFile(@TempDir & "\domain_list")
	Local $iInetResult = InetGet($sDomainListURL, $sTempFileDownload, 1)
	If @error Or $iInetResult = 0 Then
		MemoWrite("下载出错: " & @error & ", InetGet Result: " & $iInetResult & @CRLF)
		FileDelete($sTempFileDownload)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sDomainList = FileRead($sTempFileDownload)
	FileDelete($sTempFileDownload)
	MemoWrite("已下载远程列表:" & @CRLF & $sDomainList & @CRLF)

	$sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("读取 hosts 文件失败。" & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sHostsContent = StringStripWS($sHostsContent, 2)

	Local $sNewContent = $sMarkerStart & @CRLF & $sDomainList & @CRLF & $sMarkerEnd
	If StringLen($sHostsContent) > 0 Then
		$sHostsContent &= @CRLF & $sNewContent
	Else
		$sHostsContent = $sNewContent
	EndIf

	MemoWrite(@CRLF & "正在扫描 DNS 缓存中的额外（子）域名..." & @CRLF)
	Local $aDNSDomainsAdded = ScanDNSCache($sHostsContent)
	If IsArray($aDNSDomainsAdded) And UBound($aDNSDomainsAdded) > 0 Then
		Local $sDNSEntries = ""
		For $i = 0 To UBound($aDNSDomainsAdded) - 1
			$sDNSEntries &= "0.0.0.0 " & $aDNSDomainsAdded[$i] & @CRLF
		Next
		$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)(" & $sMarkerStart & ".*?)(" & $sMarkerEnd & ")", "$1" & $sDNSEntries & "$2")
		MemoWrite("已从 DNS 缓存添加:" & @CRLF & _ArrayToString($aDNSDomainsAdded, @CRLF) & @CRLF)
		LogWrite(1, "已从 DNS 缓存添加: " & _ArrayToString($aDNSDomainsAdded, ", ") & @CRLF)
	Else
		MemoWrite("DNS 缓存中未发现新域名。" & @CRLF)
	EndIf

	$hFile = FileOpen($sHostsPath, 2)
	If $hFile = -1 Then
		Local $iLastError = _WinAPI_GetLastError()
		MemoWrite("打开 hosts 文件写入失败，错误代码 = " & $iLastError & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	FileWrite($hFile, $sHostsContent)
	FileClose($hFile)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "hosts 文件更新成功。" & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
EndFunc   ;==>UpdateHostsFile

; 函数: EditHosts - 用记事本打开hosts文件进行手动编辑
Func EditHosts()
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		FileCopy($sHostsPath, $sBackupPath)
	EndIf

	Local $iPID = Run("notepad.exe " & $sHostsPath)
	If $iPID = 0 Then
		MemoWrite("启动记事本失败。" & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf

	Local $iTimeout = 300000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 记事本超时 (" & $iTimeout / 1000 & " seconds." & @CRLF)
	EndIf

	FileSetAttrib($sHostsPath, "+R")
EndFunc   ;==>EditHosts

; ============================================================
; 函数: RestoreHosts()
; 功能: 恢复hosts文件到备份状态
; 说明: 将之前创建的hosts.bak备份覆盖回原hosts文件
; ============================================================
Func RestoreHosts()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "正在从备份恢复 hosts 文件..." & @CRLF & "---" & @CRLF & "请稍候..." & @CRLF)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	If FileExists($sBackupPath) Then
		FileSetAttrib($sHostsPath, "-R")
		If FileCopy($sBackupPath, $sHostsPath, 1) Then
			FileSetAttrib($sHostsPath, "+R")
			FileDelete($sBackupPath)
			LogWrite(1, "从备份恢复 hosts 文件: 成功！" & @CRLF)
		Else
			MemoWrite("从备份恢复 hosts 文件失败。" & @CRLF)
			FileSetAttrib($sHostsPath, "+R")
			LogWrite(1, "从备份恢复 hosts 文件: 失败。" & @CRLF)
		EndIf
	Else
		LogWrite(1, "从备份恢复 hosts 文件: 未找到备份文件。" & @CRLF)
	EndIf
	ToggleLog(1)
EndFunc   ;==>RestoreHosts

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: CheckThirdPartyFirewall()
; 功能: 检测系统是否安装了第三方防火墙
; 说明: 查询WMI获取已安装的防火墙产品列表
; ============================================================
Func CheckThirdPartyFirewall()
	Local $sCmd = "powershell.exe -Command ""Get-CimInstance -ClassName FirewallProduct -Namespace 'root\SecurityCenter2' | Where-Object { $_.ProductName -notlike '*Windows*' } | Select-Object -Property ProductName"""
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 第三方防火墙检查超时 (" & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	$sOutput = StringStripWS($sOutput, 3)
	If $sOutput <> "" Then
		$g_sThirdPartyFirewall = $sOutput
		MemoWrite("检测到第三方防火墙: " & $g_sThirdPartyFirewall)
		Return True
	Else
		$g_sThirdPartyFirewall = ""
		MemoWrite("Windows 防火墙为默认防火墙。")
		Return False
	EndIf
EndFunc   ;==>CheckThirdPartyFirewall

; ============================================================
; 函数: FindApps($bForLocalDLL)
; 功能: 扫描Adobe应用程序的可执行文件
; 说明: 递归扫描Adobe安装目录，查找所有EXE文件
;       可选模式: 查找EXE或查找本地DLL文件
; ============================================================
Func FindApps($bForLocalDLL = False)
	Local $tFirewallPaths = IniReadSection($sINIPath, "FirewallTrust")
	If @error Then
		MemoWrite("读取 config.ini [FirewallTrust] 配置段出错。")
		LogWrite(1, "读取 config.ini [FirewallTrust] 配置段出错。")
		Local $empty[0]
		Return $empty
	EndIf

	Local $foundFiles[0]
	For $i = 1 To $tFirewallPaths[0][0]
		Local $relativePath = StringReplace($tFirewallPaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		Local $basePath = StringRegExpReplace($MyDefPath & "\" & $relativePath, "\\\\+", "\\")
		If StringStripWS($basePath, 3) = "" Then ContinueLoop

		If $bForLocalDLL And (StringInStr($basePath, "AcroCEF.exe", 0) Or StringInStr($basePath, "Acrobat.exe", 0)) Then
			ContinueLoop
		EndIf

		If StringInStr($basePath, "*") Then
			Local $pathParts = StringSplit($basePath, "\", 1)
			Local $searchDir = ""
			For $j = 1 To $pathParts[0] - 1
				If StringInStr($pathParts[$j], "*") Then
					$searchDir = StringTrimRight($searchDir, 1)
					Local $searchPattern = StringReplace($pathParts[$j], "*", "*")
					Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$j]) + StringLen($pathParts[$j]))
					Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
					If $HSEARCH = -1 Then ContinueLoop
					While 1
						Local $folder = FileFindNextFile($HSEARCH)
						If @error Then ExitLoop
						Local $fullPath = $searchDir & "\" & $folder & $subPath
						$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
						If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
							_ArrayAdd($foundFiles, $fullPath)
						EndIf
					WEnd
					FileClose($HSEARCH)
					ExitLoop
				Else
					$searchDir &= $pathParts[$j] & "\"
				EndIf
			Next
		Else
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
		Local $cleanedFiles[0]
		For $file In $foundFiles
			If StringStripWS($file, 3) <> "" And Not StringIsInt($file) Then
				_ArrayAdd($cleanedFiles, $file)
			EndIf
		Next
		$foundFiles = $cleanedFiles
	EndIf

	Return $foundFiles
EndFunc   ;==>FindApps

; 函数: RuleExists - 检查指定名称的防火墙规则是否已存在
Func RuleExists($ruleName)
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -DisplayName ''Adobe-Block - ' & $ruleName & ''' | Measure-Object | Select-Object -ExpandProperty Count"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		LogWrite(1, "Warning: Rule check for '" & $ruleName & "' timed out after " & $iTimeout & "ms.")
	EndIf
	Local $sOutput = StdoutRead($iPID)
	Return Number(StringStripWS($sOutput, 3)) > 0
EndFunc   ;==>RuleExists

; ============================================================
; 函数: ShowFirewallStatus()
; 功能: 显示当前防火墙规则状态
; 说明: 列出所有GenP创建的防火墙规则及其启用/禁用状态
; ============================================================
Func ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite("正在检查 Windows 防火墙状态...")
	LogWrite(1, "正在检查 Windows 防火墙状态...")

	MemoWrite("正在扫描防火墙配置文件...")
	Local $sProfileCmd = 'powershell.exe -Command "Get-NetFirewallProfile | Select-Object -Property Name,Enabled | Format-Table -HideTableHeaders"'
	Local $iPID = Run(@ComSpec & " /c " & $sProfileCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sProfileOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 防火墙配置检查超时 (" & $iTimeout & "ms.")
	EndIf
	$sProfileOutput = StdoutRead($iPID)

	Local $aProfiles = StringSplit(StringStripWS($sProfileOutput, 3), @CRLF, 1)
	Local $sProfileSummary = ""
	For $i = 1 To $aProfiles[0]
		Local $line = StringStripWS($aProfiles[$i], 3)
		If $line <> "" Then
			Local $aParts = StringRegExp($line, "^(\S+)\s+(\S+)$", 1)
			If @error = 0 Then
				Local $profileName = $aParts[0]
				Local $enabled = $aParts[1]
				$sProfileSummary &= $profileName & ": " & ($enabled = "True" ? "宸插惎鐢? : "宸茬鐢?) & @CRLF
			EndIf
		EndIf
	Next
	MemoWrite("防火墙配置:" & @CRLF & StringTrimRight($sProfileSummary, StringLen(@CRLF)))
	LogWrite(1, "防火墙配置 - " & StringReplace(StringTrimRight($sProfileSummary, StringLen(@CRLF)), @CRLF, " | "))

	MemoWrite("正在检查防火墙服务...")
	Local $sServiceCmd = 'powershell.exe -Command "Get-Service MpsSvc | Select-Object -Property Status,DisplayName | Format-List"'
	$iPID = Run(@ComSpec & " /c " & $sServiceCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sServiceOutput = ""
	$iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 防火墙服务检查超时 (" & $iTimeout & "ms.")
	EndIf
	$sServiceOutput = StdoutRead($iPID)

	Local $sServiceStatus = "Unknown"
	Local $aServiceLines = StringSplit(StringStripWS($sServiceOutput, 3), @CRLF, 1)
	For $line In $aServiceLines
		If StringInStr($line, "Status") Then
			Local $aStatus = StringSplit($line, ":", 1)
			If $aStatus[0] > 1 Then
				$sServiceStatus = StringStripWS($aStatus[2], 3)
			EndIf
			ExitLoop
		EndIf
	Next
	MemoWrite("防火墙服务 (MpsSvc): " & $sServiceStatus)
	LogWrite(1, "防火墙服务 (MpsSvc): " & $sServiceStatus)
EndFunc   ;==>ShowFirewallStatus

; ============================================================
; 函数: RemoveFirewallRules()
; 功能: 删除所有GenP创建的防火墙规则
; 说明: 遍历所有已创建的出入站规则并逐一删除
; ============================================================
Func RemoveFirewallRules()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite("开始移除防火墙规则...")
	LogWrite(1, "开始移除防火墙规则。")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙。无法移除规则。")
		LogWrite(1, "妫€娴嬪埌绗笁鏂归槻鐏" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "銆傛鍔熻兘浠呮敮鎸?Windows 闃茬伀澧欍€?)
		LogWrite(1, "防火墙规则移除流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在扫描防火墙规则...")
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 (" & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("未找到防火墙规则。")
		LogWrite(1, "未找到需要移除的防火墙规则。")
		LogWrite(1, "防火墙规则移除流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在移除 " & $iRuleCount & " 条规则...")
	LogWrite(1, "正在移除 " & $iRuleCount & " 鏉¤鍒?")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sRemoveCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Remove-NetFirewallRule"'
	Local $iPIDRemove = Run($sRemoveCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDRemove, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDRemove)
		MemoWrite("警告: 规则移除超时 (" & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则移除超时。")
	ElseIf @error Then
		MemoWrite("移除防火墙规则时出错。")
		LogWrite(1, "移除防火墙规则时出错。")
	Else
		MemoWrite("防火墙规则移除成功。")
		LogWrite(1, "防火墙规则移除成功。")
	EndIf

	LogWrite(1, "防火墙规则移除流程完成。" & @CRLF)
	ToggleLog(1)
EndFunc   ;==>RemoveFirewallRules

; ============================================================
; 函数: CreateFirewallRules()
; 功能: 为Adobe应用创建防火墙阻止规则
; 说明: 扫描Adobe EXE文件，让用户选择后
;       创建入站+出站阻止规则阻断网络连接
; ============================================================
Func CreateFirewallRules()
	MemoWrite("开始创建防火墙规则...")
	LogWrite(1, "开始创建防火墙规则。")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙。跳过 GUI，列出已找到的应用程序。")
		Local $foundApps = FindApps()
		If UBound($foundApps) = 0 Then
			LogWrite(1, "未找到可屏蔽的应用程序。")
		Else
			LogWrite(1, "找到 " & UBound($foundApps) & " 个应用程序:")
			For $app In $foundApps
				LogWrite(1, "- " & $app)
			Next
			LogWrite(1, "妫€娴嬪埌绗笁鏂归槻鐏" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "。请手动将这些路径添加到您的防火墙中。")
		EndIf
		LogWrite(1, "防火墙规则创建流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在扫描应用程序...")
	Local $foundApps = FindApps()
	Local $SelectedApps = ShowAppSelectionGUI($foundApps)

	If $SelectedApps = -1 Then
		Return
	ElseIf Not IsArray($SelectedApps) Then
		MemoWrite("用户取消了防火墙规则选择。")
		LogWrite(1, "用户取消了防火墙规则选择。" & @CRLF)
		Return
	EndIf

	ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, 3)

	If UBound($SelectedApps) = 0 Then
		MemoWrite("用户未选择任何应用程序。")
		LogWrite(1, "未选择应用程序。")
		LogWrite(1, "防火墙规则创建流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("用户选择了 " & UBound($SelectedApps) & " 个文件。")
	Local $psCmdComposite = ""
	Local $rulesAdded = 0
	Local $addedApps[0]
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Then
			MemoWrite("跳过空白或无效的路径。")
			ContinueLoop
		EndIf
		If FileExists($app) Then
			Local $ruleName = $app
			If Not RuleExists($ruleName) Then
				Local $ruleCmd = "New-NetFirewallRule -DisplayName 'Adobe-Block - " & $ruleName & "' -Direction Outbound -Program '" & $app & "' -Action Block;"
				$psCmdComposite &= $ruleCmd
				MemoWrite("正在添加防火墙规则: " & $app)
				_ArrayAdd($addedApps, $app)
				$rulesAdded += 1
			Else
				MemoWrite("规则已存在: " & $app & " - 跳过。")
			EndIf
		Else
			MemoWrite("未找到文件: " & $app)
			LogWrite(1, "未找到文件: " & $app)
		EndIf
	Next

	If $rulesAdded > 0 Then
		LogWrite(1, "已选择 " & $rulesAdded & " 个文件用于新建防火墙规则:")
		For $app In $addedApps
			LogWrite(1, "- " & $app)
		Next
		Local $iPID = Run('powershell.exe -Command "' & $psCmdComposite & '"', "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iPID)
			MemoWrite("警告: 规则创建超时 (" & $iTimeout & "ms.")
			LogWrite(1, "错误: 规则创建超时。")
		ElseIf @error Then
			MemoWrite("应用防火墙规则时出错。")
			LogWrite(1, "应用防火墙规则时出错。")
		Else
			MemoWrite("防火墙规则应用成功。")
			LogWrite(1, "防火墙规则应用成功。")
		EndIf
	Else
		MemoWrite("没有新的防火墙规则需要添加。")
		LogWrite(1, "没有添加新的防火墙规则（所有选中的规则已存在）。")
	EndIf

	LogWrite(1, "防火墙规则创建流程完成。" & @CRLF)
	ToggleLog(1)
EndFunc   ;==>CreateFirewallRules

; ============================================================
; 函数: ShowAppSelectionGUI($foundFiles)
; 功能: 显示应用程序选择GUI（防火墙规则目标选择）
; 说明: 创建带复选框的树形列表让用户选择要操作的EXE
; ============================================================
Func ShowAppSelectionGUI($foundFiles)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("错误: 无效路径: " & $MyDefPath)
		LogWrite(1, "错误: 无效路径: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("未找到文件: " & $MyDefPath)
		LogWrite(1, "未找到文件: " & $MyDefPath)
		ToggleLog(1)
		Return -1
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("选择要添加防火墙规则的文件", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileNoBak = StringRegExpReplace(StringReplace($file, ".bak", ""), "\\\\+", "\\")
		Local $fileParts = StringSplit($fileNoBak, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "璀﹀憡: 閰嶇疆浣跨敤浜嗙煭璺緞锛屾湭鐭ュ簲鐢? " & $fileNoBak)
		EndIf

		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($file, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next
	LogWrite(1, "找到 " & UBound($foundFiles) & " 个文件，分布在 " & $appNodes.Count & " 个应用程序中。")

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $SelectedApps[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("正在扫描选中的项目...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						Local $childCount = _GUICtrlTreeView_GetChildCount($hTreeView, $hItem)
						If $childCount = -1 And StringStripWS($itemText, 3) <> "" Then
							_ArrayAdd($SelectedApps, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, 3)
				MemoWrite("已选择 " & UBound($SelectedApps) & " 个文件用于防火墙规则。")
				GUIDelete($hGUI)
				Return $SelectedApps
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>ShowAppSelectionGUI

; 函数: CheckParentCheckboxes - 根据子项状态更新父级复选框
Func CheckParentCheckboxes()
	Local $hItem = _GUICtrlTreeView_GetFirstItem($ghTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($ghTreeView, $hItem)
		Local $childCount = _GUICtrlTreeView_GetChildCount($ghTreeView, $hItem)
		If $childCount > 0 Then
			Local $currentState = _GUICtrlTreeView_GetChecked($ghTreeView, $hItem)
			Local $prevState = $prevStates($itemText)
			If $currentState <> $prevState Then
				$prevStates($itemText) = $currentState
				Local $hChild = _GUICtrlTreeView_GetFirstChild($ghTreeView, $hItem)
				While $hChild <> 0
					_GUICtrlTreeView_SetChecked($ghTreeView, $hChild, $currentState)
					$hChild = _GUICtrlTreeView_GetNextChild($ghTreeView, $hChild)
				WEnd
			EndIf
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($ghTreeView, $hItem)
	WEnd
EndFunc   ;==>CheckParentCheckboxes

; ============================================================
; 函数: ShowToggleRulesGUI()
; 功能: 显示防火墙规则开关切换界面
; 说明: 列出所有已创建的规则，允许批量启用/禁用
; ============================================================
Func ShowToggleRulesGUI()
	MemoWrite("打开防火墙规则切换选项...")

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hToggleGUI = GUICreate("切换规则", 300, 150, $iPopupX, $iPopupY)
	Local $hEnableButton = GUICtrlCreateButton("全部启用", 50, 50, 100, 30)
	Local $hDisableButton = GUICtrlCreateButton("全部禁用", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("切换规则操作已取消。")
				GUIDelete($hToggleGUI)
				Return
			Case $hEnableButton
				_GUICtrlTab_SetCurFocus($hTab, 3)
				GUIDelete($hToggleGUI)
				EnableAllFWRules()
				Return
			Case $hDisableButton
				_GUICtrlTab_SetCurFocus($hTab, 3)
				GUIDelete($hToggleGUI)
				DisableAllFWRules()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>ShowToggleRulesGUI

; ============================================================
; 函数: EnableAllFWRules()
; 功能: 启用所有GenP创建的防火墙规则
; 说明: 遍历规则列表，将每条规则设为启用状态
; ============================================================
Func EnableAllFWRules()
	MemoWrite("正在启用所有 GenP 防火墙规则...")
	LogWrite(1, "开始启用所有 GenP 防火墙规则。")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙。无法修改规则。")
		LogWrite(1, "妫€娴嬪埌绗笁鏂归槻鐏" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "銆傛鍔熻兘浠呮敮鎸?Windows 闃茬伀澧欍€?)
		LogWrite(1, "启用规则流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 (" & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("未找到需要启用的 GenP 防火墙规则。")
		LogWrite(1, "未找到 GenP 防火墙规则。")
		LogWrite(1, "启用规则流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在启用 " & $iRuleCount & " 条 Adobe-Block 规则...")
	LogWrite(1, "正在启用 " & $iRuleCount & " 鏉¤鍒?")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sEnableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Enable-NetFirewallRule"'
	Local $iPIDEnable = Run($sEnableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDEnable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDEnable)
		MemoWrite("警告: 规则启用超时 (" & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则启用超时。")
	ElseIf @error Then
		MemoWrite("启用防火墙规则时出错。")
		LogWrite(1, "启用防火墙规则时出错。")
	Else
		MemoWrite("所有 GenP 防火墙规则已成功启用。")
		LogWrite(1, "所有 GenP 防火墙规则已成功启用。")
	EndIf

	LogWrite(1, "启用规则流程完成。" & @CRLF)
	ToggleLog(1)
EndFunc   ;==>EnableAllFWRules

; ============================================================
; 函数: DisableAllFWRules()
; 功能: 禁用所有GenP创建的防火墙规则
; 说明: 遍历规则列表，将每条规则设为禁用状态
; ============================================================
Func DisableAllFWRules()
	MemoWrite("正在禁用所有 GenP 防火墙规则...")
	LogWrite(1, "开始禁用所有 GenP 防火墙规则。")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙。无法修改规则。")
		LogWrite(1, "妫€娴嬪埌绗笁鏂归槻鐏" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "銆傛鍔熻兘浠呮敮鎸?Windows 闃茬伀澧欍€?)
		LogWrite(1, "禁用规则流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 (" & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("未找到需要禁用的 GenP 防火墙规则。")
		LogWrite(1, "未找到 GenP 防火墙规则。")
		LogWrite(1, "禁用规则流程完成。" & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在禁用 " & $iRuleCount & " 条 Adobe-Block 规则...")
	LogWrite(1, "正在禁用 " & $iRuleCount & " 鏉¤鍒?")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sDisableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Disable-NetFirewallRule"'
	Local $iPIDDisable = Run($sDisableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDDisable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDDisable)
		MemoWrite("警告: 规则禁用超时 (" & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则禁用超时。")
	ElseIf @error Then
		MemoWrite("禁用防火墙规则时出错。")
		LogWrite(1, "禁用防火墙规则时出错。")
	Else
		MemoWrite("所有 GenP 防火墙规则已成功禁用。")
		LogWrite(1, "所有 GenP 防火墙规则已成功禁用。")
	EndIf

	LogWrite(1, "禁用规则流程完成。" & @CRLF)
	ToggleLog(1)
EndFunc   ;==>DisableAllFWRules

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: FindRuntimeInstallerFiles()
; 功能: 扫描Adobe运行时安装器文件
; 说明: 在Adobe目录中递归查找runtime installer DLL文件
;       这些文件通常是UPX压缩的需要解包处理
; ============================================================
Func FindRuntimeInstallerFiles()
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("错误: 无效路径: " & $MyDefPath)
		LogWrite(1, "错误: 无效路径: " & $MyDefPath)
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	Local $tRuntimePaths = IniReadSection($sINIPath, "RuntimeInstallers")
	Local $dllPaths[0]

	If @error Or $tRuntimePaths[0][0] = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("璀﹀憡: config.ini 涓湭鎵惧埌 [RuntimeInstallers] 娈垫垨璇ユ涓虹┖")
		LogWrite(1, "璀﹀憡: config.ini 涓湭鎵惧埌 [RuntimeInstallers] 娈垫垨璇ユ涓虹┖")
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	ReDim $dllPaths[$tRuntimePaths[0][0]]
	For $i = 1 To $tRuntimePaths[0][0]
		Local $relativePath = StringReplace($tRuntimePaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		$dllPaths[$i - 1] = StringRegExpReplace($MyDefPath & "\" & $relativePath, "\\\\+", "\\")
	Next

	Local $foundFiles[0]
	For $basePath In $dllPaths
		If StringStripWS($basePath, 3) = "" Then ContinueLoop
		Local $pathParts = StringSplit($basePath, "\", 1)
		Local $searchDir = ""
		For $i = 1 To $pathParts[0] - 1
			If StringInStr($pathParts[$i], "*") Then
				$searchDir = StringTrimRight($searchDir, 1)
				Local $searchPattern = StringReplace($pathParts[$i], "*", "*")
				Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$i]) + StringLen($pathParts[$i]))
				Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
				If $HSEARCH = -1 Then
					ContinueLoop
				EndIf
				While 1
					Local $folder = FileFindNextFile($HSEARCH)
					If @error Then ExitLoop
					Local $fullPath = $searchDir & "\" & $folder & $subPath
					$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
					If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
						_ArrayAdd($foundFiles, $fullPath)
					EndIf
				WEnd
				FileClose($HSEARCH)
				ExitLoop
			Else
				$searchDir &= $pathParts[$i] & "\"
			EndIf
		Next

		If Not StringInStr($basePath, "*") Then
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
	EndIf

	Return $foundFiles
EndFunc   ;==>FindRuntimeInstallerFiles

; ============================================================
; 函数: UnpackRuntimeInstallers()
; 功能: 解包运行时安装器DLL文件
; 说明: 使用UPX工具解压缩DLL，先修补UPX头部
;       然后执行解压，使文件可被后续补丁修改
; ============================================================
Func UnpackRuntimeInstallers()
	MemoWrite("正在扫描 RuntimeInstaller.dll 文件...")
	Local $foundFiles = FindRuntimeInstallerFiles()

	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("未找到文件: " & $MyDefPath)
		LogWrite(1, "未找到文件: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $selectedFiles = RuntimeDllSelectionGUI($foundFiles, "Unpack")

	If Not IsArray($selectedFiles) Or UBound($selectedFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("未选择要解包的 RuntimeInstaller.dll 文件。")
		LogWrite(1, "鏈€夋嫨瑕佽В鍖呯殑鏂囦欢銆?)
		ToggleLog(1)
		Return
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			_GUICtrlTab_SetCurFocus($hTab, 3)
			MemoWrite("閿欒: 瑙ｅ帇 upx.exe 澶辫触: " & $upxPath)
			LogWrite(1, "閿欒: 瑙ｅ帇 upx.exe 澶辫触銆?)
			ToggleLog(1)
			Return
		EndIf
	EndIf

	MemoWrite("正在解包 " & UBound($selectedFiles) & " 个文件...")
	LogWrite(1, "正在解包 " & UBound($selectedFiles) & " 个文件:")
	Local $successCount = 0

	For $file In $selectedFiles
		$file = StringStripWS($file, 3)
		If $file = "" Or Not FileExists($file) Then
			MemoWrite("跳过无效或缺失的文件: " & $file)
			LogWrite(1, "跳过无效或缺失的文件: " & $file)
			ContinueLoop
		EndIf

		LogWrite(1, "姝ｅ湪澶勭悊: " & $file)

		If Not IsUPXPacked($file) Then
			MemoWrite("宸茶烦杩? " & $file & " 涓嶆槸 UPX 鍘嬬缉鏂囦欢銆?)
			LogWrite(1, "宸茶烦杩? " & $file & " 涓嶆槸 UPX 鍘嬬缉鏂囦欢銆?)
			ContinueLoop
		EndIf

		If Not PatchUPXHeader($file) Then
			MemoWrite("UPX 澶撮儴淇ˉ澶辫触: " & $file)
			LogWrite(1, "UPX 澶撮儴淇ˉ澶辫触: " & $file)
			ContinueLoop
		EndIf

		Local $iResult = RunWait('"' & $upxPath & '" -d "' & $file & '"', "", @SW_HIDE)
		If $iResult = 0 Then
			MemoWrite("解包成功: " & $file)
			LogWrite(1, "解包成功: " & $file)
			$successCount += 1
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileDelete($sBackupPath)
			EndIf
		Else
			MemoWrite("解包失败: " & $file & " (UPX error code: " & $iResult & ")")
			LogWrite(1, "解包失败: " & $file & " (UPX error code: " & $iResult & ")")
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileCopy($sBackupPath, $file, 1)
				FileDelete($sBackupPath)
				MemoWrite("已从备份恢复原始文件: " & $file)
				LogWrite(1, "已从备份恢复原始文件: " & $file)
			EndIf
		EndIf
	Next

	If FileExists($upxPath) Then
		If FileDelete($upxPath) Then
			MemoWrite("宸蹭粠浠ヤ笅浣嶇疆鍒犻櫎 upx.exe: " & $upxPath & ".")
		Else
			MemoWrite("璀﹀憡: 鍒犻櫎 upx.exe 澶辫触: " & $upxPath & ".")
			LogWrite(1, "璀﹀憡: 鍒犻櫎 upx.exe 澶辫触: " & $upxPath & ".")
		EndIf
	EndIf

	MemoWrite("解包完成。成功解包 " & $successCount & " 个文件。")
	LogWrite(1, "解包流程完成。")

	If $successCount > 0 Then
		LogWrite(1, $successCount & " 个文件已成功解包，现在可以进行补丁。")
	EndIf

	ToggleLog(1)
EndFunc   ;==>UnpackRuntimeInstallers

; ============================================================
; 函数: IsUPXPacked($sFilePath)
; 功能: 检测文件是否被UPX压缩
; 说明: 读取PE文件头部，检查是否包含UPX特征标记
; ============================================================
Func IsUPXPacked($sFilePath)
	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		LogWrite(1, "閿欒: 鏃犳硶鎵撳紑鏂囦欢杩涜 UPX 妫€鏌? " & $sFilePath)
		Return False
	EndIf

	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		LogWrite(1, "閿欒: 鏃犳硶璇诲彇鏂囦欢杩涜 UPX 妫€鏌? " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	If StringInStr($sHexData, "55505821") Or StringInStr($sHexData, "007465787400") Or StringInStr($sHexData, "746578743100") Then
		Return True
	EndIf

	Return False
EndFunc   ;==>IsUPXPacked

; ============================================================
; 函数: PatchUPXHeader($sFilePath)
; 功能: 修补UPX压缩头部以允许解压
; 说明: 修改UPX段名称标记使UPX工具能够识别并解压文件
;       Adobe对UPX头做了修改以阻止解压
; ============================================================
Func PatchUPXHeader($sFilePath)
	Local Const $sUPX0 = "005550583000"
	Local Const $sUPX1 = "555058310000"

	Local $aCustomHeaders1 = ["007465787400"]
	Local $aCustomHeaders2 = ["746578743100"]

	Local $sBackupPath = $sFilePath & ".bak"
	If Not FileCopy($sFilePath, $sBackupPath, 1) Then
		MemoWrite("閿欒: 鍒涘缓澶囦唤澶辫触: " & $sFilePath)
		LogWrite(1, "閿欒: 鍒涘缓澶囦唤澶辫触: " & $sFilePath)
		Return False
	EndIf

	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		MemoWrite("閿欒: 鏃犳硶鎵撳紑鏂囦欢杩涜淇ˉ: " & $sFilePath)
		LogWrite(1, "閿欒: 鏃犳硶鎵撳紑鏂囦欢杩涜淇ˉ: " & $sFilePath)
		Return False
	EndIf
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		MemoWrite("閿欒: 鏃犳硶璇诲彇鏂囦欢杩涜淇ˉ: " & $sFilePath)
		LogWrite(1, "閿欒: 鏃犳硶璇诲彇鏂囦欢杩涜淇ˉ: " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	Local $bModified = False

	For $sHeader In $aCustomHeaders1
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX0)
			$bModified = True
			ExitLoop
		EndIf
	Next

	For $sHeader In $aCustomHeaders2
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX1)
			$bModified = True
			ExitLoop
		EndIf
	Next

	If Not $bModified Then
		MemoWrite("未找到自定义 UPX 文件头: " & $sFilePath)
		FileDelete($sBackupPath)
		Return True
	EndIf

	Local $bModifiedData = Binary("0x" & StringMid($sHexData, 3))
	Local $hFileWrite = FileOpen($sFilePath, 18)
	If $hFileWrite = -1 Then
		MemoWrite("閿欒: 鏃犳硶鎵撳紑鏂囦欢杩涜鍐欏叆: " & $sFilePath)
		LogWrite(1, "閿欒: 鏃犳硶鎵撳紑鏂囦欢杩涜鍐欏叆: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf
	FileWrite($hFileWrite, $bModifiedData)
	FileClose($hFileWrite)
	If @error Then
		MemoWrite("閿欒: 鍐欏叆淇ˉ鏁版嵁澶辫触: " & $sFilePath)
		LogWrite(1, "閿欒: 鍐欏叆淇ˉ鏁版嵁澶辫触: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf

	MemoWrite("成功修补 UPX 文件头: " & $sFilePath)
	Return True
EndFunc   ;==>PatchUPXHeader

; ============================================================
; 函数: RuntimeDllSelectionGUI($foundFiles, $operation)
; 功能: 显示运行时DLL选择界面
; 说明: 创建带复选框列表让用户选择要操作的DLL文件
; ============================================================
Func RuntimeDllSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("错误: 无效路径: " & $MyDefPath)
		LogWrite(1, "错误: 无效路径: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("未找到需要解包的 RuntimeInstaller.dll 文件。")
		LogWrite(1, "未找到需要解包的 RuntimeInstaller.dll 文件。")
		ToggleLog(1)
		Return ""
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("解包 RuntimeInstaller", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")
		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "璀﹀憡: 閰嶇疆浣跨敤浜嗙煭璺緞锛屾湭鐭ュ簲鐢? " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite("RuntimeInstaller 解包已取消。")
				LogWrite(1, "RuntimeInstaller 解包已取消。")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					Local $isChecked = _GUICtrlTreeView_GetChecked($hTreeView, $hItem)
					If $isChecked And StringInStr($itemText, "RuntimeInstaller.dll") Then
						_ArrayAdd($selectedFiles, $itemText)
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					_GUICtrlTab_SetCurFocus($hTab, 3)
					MemoWrite("未选择要解包的 RuntimeInstaller.dll 文件。")
					LogWrite(1, "未选择要解包的 RuntimeInstaller.dll 文件。")
					ToggleLog(1)
					Return ""
				EndIf
				_GUICtrlTab_SetCurFocus($hTab, 3)
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>RuntimeDllSelectionGUI

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; ============================================================
; 函数: AddDevOverride()
; 功能: 添加开发者覆盖注册表项
; 说明: 在注册表中写入DevOverride键值
;       使Adobe应用跳过某些许可证检查
; ============================================================
Func AddDevOverride()
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1

	If Not IsAdmin() Then
		MemoWrite("错误: 需要管理员权限才能设置注册表项。")
		LogWrite(1, "错误: 需要管理员权限访问注册表。")
		Return False
	EndIf

	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error = 0 And $iCurrentValue = $iExpectedValue Then
		MemoWrite("娉ㄥ唽琛ㄩ」 " & $sValueName & " 宸插惎鐢ㄣ€?)
		LogWrite(1, "娉ㄥ唽琛ㄩ」 " & $sValueName & " 宸茶涓?" & $iExpectedValue & ".")
		Return True
	EndIf

	If RegWrite($sKey, $sValueName, "REG_DWORD", $iExpectedValue) Then
		MemoWrite("宸插惎鐢ㄦ敞鍐岃〃椤?" & $sValueName & " for WinTrust override.")
		LogWrite(1, "宸茶缃敞鍐岃〃椤?" & $sValueName & " = " & $iExpectedValue & ".")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("閿欒: 鍚敤娉ㄥ唽琛ㄩ」澶辫触 " & $sValueName & ".")
		LogWrite(1, "閿欒: 璁剧疆娉ㄥ唽琛ㄩ」澶辫触 " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>AddDevOverride

; ============================================================
; 函数: RemoveDevOverride()
; 功能: 移除开发者覆盖注册表项
; 说明: 删除之前添加的DevOverride注册表键值
; ============================================================
Func RemoveDevOverride()
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1

	If Not IsAdmin() Then
		MemoWrite("错误: 需要管理员权限才能移除注册表项。")
		LogWrite(1, "错误: 需要管理员权限访问注册表。")
		Return False
	EndIf

	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		MemoWrite("鏈壘鍒版敞鍐岃〃椤?" & $sValueName & " 鍙Щ闄ゃ€?)
		LogWrite(1, "鏈壘鍒版敞鍐岃〃椤?" & $sValueName & " found.")
		Return True
	EndIf

	If $iCurrentValue <> $iExpectedValue Then
		MemoWrite("娉ㄥ唽琛ㄩ」 " & $sValueName & " 鏈惎鐢紝鏃犻渶鎿嶄綔銆?)
		LogWrite(1, "娉ㄥ唽琛ㄩ」 " & $sValueName & " 鏈涓?" & $iExpectedValue & ".")
		Return True
	EndIf

	If RegDelete($sKey, $sValueName) Then
		MemoWrite("宸茬鐢ㄦ敞鍐岃〃椤?" & $sValueName & ".")
		LogWrite(1, "宸茬Щ闄ゆ敞鍐岃〃椤?" & $sValueName & ".")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("閿欒: 绂佺敤娉ㄥ唽琛ㄩ」澶辫触 " & $sValueName & ".")
		LogWrite(1, "閿欒: 绉婚櫎娉ㄥ唽琛ㄩ」澶辫触 " & $sValueName & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>RemoveDevOverride

; 函数: ShowRebootPopup - 显示重启提示弹窗
Func ShowRebootPopup()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 200) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 100) / 2
	Local $hPopup = GUICreate("", 200, 100, $iPopupX, $iPopupY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	GUICtrlCreateLabel("需要重启系统才能使更改生效。", 10, 10, 180, 40, $SS_CENTER)
	Local $idOk = GUICtrlCreateButton("确定", 50, 60, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		If GUIGetMsg() = $idOk Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc   ;==>ShowRebootPopup

; ============================================================
; 函数: ManageWinTrust()
; 功能: WinTrust信任管理主入口
; 说明: 管理Windows WinTrust数字签名验证
;       可信任/取消信任Adobe可执行文件
; ============================================================
Func ManageWinTrust()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("管理 WinTrust", 300, 150, $iPopupX, $iPopupY)
	Local $hTrustButton = GUICtrlCreateButton("信任", 50, 50, 100, 30)
	Local $hUntrustButton = GUICtrlCreateButton("取消信任", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("WinTrust 管理已取消。")
				GUIDelete($hGUI)
				Return
			Case $hTrustButton
				GUIDelete($hGUI)
				TrustEXEs()
				Return
			Case $hUntrustButton
				GUIDelete($hGUI)
				UntrustEXEs()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>ManageWinTrust

; ============================================================
; 函数: FindTrustEXEs()
; 功能: 扫描需要信任处理的Adobe EXE文件
; 说明: 在Adobe目录中查找所有可执行文件
; ============================================================
Func FindTrustEXEs()
	Local $foundApps = FindApps(True)
	Local $foundEXEs[0]

	For $app In $foundApps
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		If FileExists($dllPath) Then
			_ArrayAdd($foundEXEs, $app)
		EndIf
	Next

	Return $foundEXEs
EndFunc   ;==>FindTrustEXEs

; ============================================================
; 函数: TrustEXEs()
; 功能: 对选定的EXE文件执行信任操作
; 说明: 通过修补wintrust.dll使Windows跳过
;       对指定Adobe EXE文件的数字签名验证
; ============================================================
Func TrustEXEs()
	MemoWrite("正在扫描可信任的应用程序...")
	Local $foundApps = FindApps(True)

	If UBound($foundApps) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("未在以下路径找到可信任的应用: " & $MyDefPath)
		LogWrite(1, "未在以下路径找到可信任的应用: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $SelectedApps = TrustSelectionGUI($foundApps, "Trust")

	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("未选择要信任的应用程序。")
		LogWrite(1, "未选择要信任的应用程序。")
		Return
	EndIf

	If Not AddDevOverride() Then
		MemoWrite("由于注册表错误，WinTrust 操作已中止。")
		Return
	EndIf

	Local $dllSourcePath = @ScriptDir & "\wintrust.dll"
	If Not FileExists($dllSourcePath) Or FileGetSize($dllSourcePath) <> 382712 Then
		FileInstall("wintrust.dll", $dllSourcePath, 1)
		If Not FileExists($dllSourcePath) Then
			MemoWrite("閿欒: 瑙ｅ帇 wintrust.dll 澶辫触: " & $dllSourcePath)
			LogWrite(1, "閿欒: 瑙ｅ帇 wintrust.dll 澶辫触銆?)
			Return
		EndIf
	EndIf

	If FileGetSize($dllSourcePath) <> 382712 Then
		MemoWrite("閿欒: wintrust.dll 澶у皬涓嶅尮閰嶏紙搴斾负 382,712 瀛楄妭锛夈€?)
		LogWrite(1, "閿欒: wintrust.dll 澶у皬涓嶅尮閰嶏紙搴斾负 382,712 瀛楄妭锛夈€?)
		FileDelete($dllSourcePath)
		Return
	EndIf

	MemoWrite("正在信任 " & UBound($SelectedApps) & " 个应用程序...")
	LogWrite(1, "正在信任 " & UBound($SelectedApps) & " 个应用程序:")

	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("跳过无效或缺失的文件: " & $app)
			LogWrite(1, "跳过无效或缺失的文件: " & $app)
			ContinueLoop
		EndIf

		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"

		LogWrite(1, "- Processing: " & $app)

		If Not DirCreate($localDir) Then
			MemoWrite("鍒涘缓鐩綍澶辫触: " & $localDir)
			LogWrite(1, "鍒涘缓鐩綍澶辫触: " & $localDir)
			ContinueLoop
		EndIf

		If FileExists($dllPath) Then
			If FileGetSize($dllPath) = 382712 Then
				MemoWrite("wintrust.dll 宸插瓨鍦ㄤ簬: " & $dllPath & " - 跳过。")
				LogWrite(1, "wintrust.dll 宸插瓨鍦ㄤ簬: " & $dllPath & " - 跳过。")
				$successCount += 1
			Else
				FileDelete($dllPath)
				If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
					MemoWrite("宸叉浛鎹?wintrust.dll: " & $dllPath)
					LogWrite(1, "宸叉浛鎹?wintrust.dll: " & $dllPath)
					$successCount += 1
				Else
					MemoWrite("鏇挎崲 wintrust.dll 澶辫触: " & $dllPath)
					LogWrite(1, "鏇挎崲 wintrust.dll 澶辫触: " & $dllPath)
				EndIf
			EndIf
			ContinueLoop
		EndIf

		If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
			MemoWrite("已成功信任: " & $appName)
			LogWrite(1, "已成功信任: " & $appName)
			$successCount += 1
		Else
			MemoWrite("信任失败: " & $appName)
			LogWrite(1, "信任失败: " & $appName)
		EndIf
	Next

	If FileExists($dllSourcePath) Then
		If FileDelete($dllSourcePath) Then
			MemoWrite("宸蹭粠浠ヤ笅浣嶇疆鍒犻櫎 wintrust.dll: " & $dllSourcePath & ".")
		Else
			MemoWrite("璀﹀憡: 鍒犻櫎 wintrust.dll 澶辫触: " & $dllSourcePath & ".")
		EndIf
	EndIf

	MemoWrite("信任完成。成功处理 " & $successCount & " / " & UBound($SelectedApps) & " 个应用程序。")
	LogWrite(1, "信任完成。成功处理 " & $successCount & " / " & UBound($SelectedApps) & " 个应用程序。")
	ToggleLog(1)
EndFunc   ;==>TrustEXEs

; ============================================================
; 函数: UntrustEXEs()
; 功能: 取消对选定EXE文件的信任
; 说明: 恢复wintrust.dll的原始行为
;       重新启用对指定文件的签名验证
; ============================================================
Func UntrustEXEs()
	MemoWrite("正在扫描已信任的应用程序...")
	Local $foundEXEs = FindTrustEXEs()

	If UBound($foundEXEs) = 0 Then
		MemoWrite("未找到需要取消信任的应用程序。")
		LogWrite(1, "未找到需要取消信任的应用程序。")
		Return
	EndIf

	Local $SelectedApps = TrustSelectionGUI($foundEXEs, "Untrust")

	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("未选择要取消信任的应用程序。")
		LogWrite(1, "未选择要取消信任的应用程序。")
		Return
	EndIf

	MemoWrite("正在取消信任 " & UBound($SelectedApps) & " 个应用程序...")
	LogWrite(1, "正在取消信任 " & UBound($SelectedApps) & " 个应用程序:")

	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("跳过无效或缺失的文件: " & $app)
			LogWrite(1, "跳过无效或缺失的文件: " & $app)
			ContinueLoop
		EndIf

		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"

		LogWrite(1, "- Processing: " & $app)

		If Not FileExists($dllPath) Then
			MemoWrite("鏈壘鍒?wintrust.dll: " & $dllPath & " - 跳过。")
			LogWrite(1, "鏈壘鍒?wintrust.dll: " & $dllPath & " - 跳过。")
			ContinueLoop
		EndIf

		If DirRemove($localDir, 1) Then
			MemoWrite("已成功取消信任: " & $appName)
			LogWrite(1, "已成功取消信任: " & $appName)
			$successCount += 1
		Else
			MemoWrite("取消信任失败: " & $appName)
			LogWrite(1, "取消信任失败: " & $appName)
		EndIf
	Next

	MemoWrite("取消信任完成。成功处理 " & $successCount & " / " & UBound($SelectedApps) & " 个应用程序。")
	LogWrite(1, "取消信任完成。成功处理 " & $successCount & " / " & UBound($SelectedApps) & " 个应用程序。")
	ToggleLog(1)
EndFunc   ;==>UntrustEXEs

; ============================================================
; 函数: TrustSelectionGUI($foundFiles, $operation)
; 功能: 显示信任操作的文件选择界面
; 说明: 创建GUI让用户选择要信任/取消信任的EXE文件
; ============================================================
Func TrustSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		MemoWrite("错误: 无效路径: " & $MyDefPath)
		LogWrite(1, "错误: 无效路径: " & $MyDefPath)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, 3)
		MemoWrite("鏈壘鍒板彲澶勭悊鐨勫簲鐢ㄧ▼搴? " & StringLower($operation) & " at: " & $MyDefPath)
		LogWrite(1, "鏈壘鍒板彲澶勭悊鐨勫簲鐢ㄧ▼搴? " & StringLower($operation) & " at: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate($operation, 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")
		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "Unknown"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "璀﹀憡: 閰嶇疆浣跨敤浜嗙煭璺緞锛屾湭鐭ュ簲鐢? " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite(StringLower($operation) & " 已取消。")
				LogWrite(1, StringLower($operation) & " 已取消。")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("正在扫描选中的项目...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						If StringInStr($itemText, ".exe") Then
							_ArrayAdd($selectedFiles, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, 3)
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					MemoWrite("未选择要" & StringLower($operation) & ".")
					LogWrite(1, "未选择要" & StringLower($operation) & ".")
				EndIf
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>TrustSelectionGUI

; ============================================================
; 函数: ManageDevOverride()
; 功能: 管理开发者覆盖（DevOverride）功能入口
; 说明: 提供添加/删除DevOverride注册表项的操作入口
; ============================================================
Func ManageDevOverride()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("管理 DevOverride", 300, 150, $iPopupX, $iPopupY)

	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $sStatus
	Local $iValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		$sStatus = "未找到注册表项。"
	ElseIf $iValue = 1 Then
		$sStatus = "注册表项已启用。"
	Else
		$sStatus = "注册表项已禁用。"
	EndIf

	GUICtrlCreateLabel($sStatus, 10, 20, 280, 20, $SS_CENTER)

	Local $hAddButton = GUICtrlCreateButton("启用注册表项", 50, 50, 100, 30)
	Local $hRemoveButton = GUICtrlCreateButton("移除注册表项", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("DevOverride 注册表管理已取消。")
				GUIDelete($hGUI)
				Return
			Case $hAddButton
				GUIDelete($hGUI)
				AddDevOverride()
				Return
			Case $hRemoveButton
				GUIDelete($hGUI)
				RemoveDevOverride()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>ManageDevOverride

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; 函数: OpenWF - 在默认浏览器中打开Windows防火墙设置
Func OpenWF()
	Local $sWFPath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $sWFPath)
	ConsoleWrite("正在打开 Windows 防火墙...")
EndFunc   ;==>OpenWF
