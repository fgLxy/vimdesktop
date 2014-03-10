﻿TotalCommander_Dialog:
;本插件尝试将TotalCommander作为文件打开对话框
; * 默认添加快捷键<lwin>o ,在文件对话框或任意文字编辑界面按下快捷键跳转至TC--TC中选定文件后再次按下快捷键可实现文件打开功能
; * 尝试在打开文件对话框时，自动跳转到TC进行文件选择
; * 增加select模式，按下回车可直接选定文件

vim.comment("<OpenTCDialog>","激活TC选择文件,需再次按下快捷键触发对话框打开事件")

;初始化设置：全局快捷键跳转到TC
IniWriteIfNull(ConfigPath,"Global","*<lwin>o","<OpenTCDialog>")

;初始化设置：自动跳转到TC作为文件选择对话框
IniWriteIfNull(ConfigPath,"TotalCommander_Config","AsOpenFileDialog","1")

;读取配置参数，禁用时直接跳过
IniRead,AsOpenFileDialog,%ConfigPath%,TotalCommander_Config,AsOpenFileDialog,1
if AsOpenFileDialog <> 1
	return

;用于记录文件打开对话框所属窗体
global CallerId := 0

;等待OpenFileDialog出现
SetTimer, <CheckFileDialog>, 1000

vim.mode("select","TTOTAL_CMD")
gosub,<TC_Normal_Map>
vim.map("<enter>","<TC_Selected>","TTOTAL_CMD")

vim.mode("normal","TTOTAL_CMD")
return


;===============================================


;发现标准打开文件对话框，未记录，焦点控件为Edit1=>记录，并激活TC
<CheckFileDialog>:
{
	WinGetClass, class, A
	if class <> #32770
		return
		
	ControlGetFocus,ct, ahk_class #32770
	if ct <> Edit1
		return
	
	id := WinExist("A")
	if id = 0
		return
	if id = %CallerId%
		return

	CallerId := id	
	gosub,<FocusTC>
	vim.mode("select","TTOTAL_CMD")
	return
}

; * 非TC窗口按下后激活TC窗口
; * TC窗口按下后复制当前选中文件返回原窗口后粘贴
<OpenTCDialog>:
{
	WinGetClass, class, A
	
	;在Total Commander按下快捷键时，激活调用窗体并执行粘贴操作
	if class = TTOTAL_CMD
	{
		gosub,<TC_Selected>
		return
	}

	if class <> TTOTAL_CMD
	{
		CallerId := WinExist("A")
		if CallerId = 0
			return

		gosub,<FocusTC>
		vim.mode("select","TTOTAL_CMD")
		return
	}

	return
}

<TC_Selected>:
{
	vim.mode("normal","TTOTAL_CMD")
	SendPos(2021)
	sleep 500
	files := ""
	Loop, parse, clipboard, `n, `r
		files .= " """ A_LoopField  """"
	clipboard := files

	;未发现可激活的调用窗体时，最小化TC
	if CallerId = 0
	{
		Winminimize,AHK_CLASS TTOTAL_CMD
		sleep,500
		CallerId := WinExist("A")
		if CallerId = 0
			return
	}

	WinActivate,ahk_id %CallerId%
	WinWait,ahk_id %CallerId%
	send, ^v
	send, {Enter}
	return
}
