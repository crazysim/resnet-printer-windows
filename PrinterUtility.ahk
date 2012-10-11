
#SingleInstance force
FileCreateDir, DriversTemp
RunAsAdmin()
FileInstall, DriversTemp\dduout32.exe, DriversTemp\dduout32.exe, 1
FileInstall, DriversTemp\dduout32.cab, DriversTemp\dduout32.cab, 1
FileInstall, DriversTemp\dduout32.xml, DriversTemp\dduout32.xml, 1
FileInstall, DriversTemp\dduout64.exe, DriversTemp\dduout64.exe, 1
FileInstall, DriversTemp\dduout64.cab, DriversTemp\dduout64.cab, 1
FileInstall, DriversTemp\dduout64.xml, DriversTemp\dduout64.xml, 1
; Create these Driver Deployment Things with the HP CP4025 drivers from HP and the PARK toolkit.

Name := "UCSB ResNet Printer Setup Utility"

Gui, Add, Text,, Pick a printer to install from the list below.`nTo cancel, press ESCAPE or close this window.`n
Gui Add, ListBox, vSetupPrinterBox gSetupPrinter w300 r12
GuiControl,, SetupPrinterBox, Anacapa|Manzanita Village|San Miguel|San Nicholas|San Rafael|Santa Cruz|Santa Rosa|Santa Catalina North|Santa Catalina South|*Only Set Credentials*
Gui, Show,, %Name%
return

SetupPrinter:
GuiControlGet, SetupPrinterBox
Gui, Submit
;MsgBox, %SetupPrinterBox%

if (SetupPrinterBox = "Anacapa")
	PrinterName = ana
else if (SetupPrinterBox = "Manzanita Village")
	PrinterName = mz
else if (SetupPrinterBox = "San Miguel")
	PrinterName = sm
else if (SetupPrinterBox = "San Nicholas")
	PrinterName = sn
else if (SetupPrinterBox = "San Rafael")
	PrinterName = srt
else if (SetupPrinterBox = "Santa Cruz")
	PrinterName = sc
else if (SetupPrinterBox = "Santa Rosa")
	PrinterName = sr
else if (SetupPrinterBox = "Santa Catalina North")
	PrinterName = sct-n
else if (SetupPrinterBox = "Santa Catalina South")
	PrinterName = sct-s
else if (SetupPrinterBox = "*Only Set Credentials*")
	PrinterName = noop

InputBox, PermNumber, Perm Number, Enter your Perm Number:
if ErrorLevel
	GoSub Canceled
HRSUsername = HRS\%PermNumber%
InputBox, HRSPassword, ResNet Password, Enter your ResNet Password:, HIDE
if ErrorLevel
	GoSub Canceled

if (PrinterName = "noop")
	GoSub Canceled

try  ; Attempts to execute code.
{

; Check if 64 bit or not
ThisProcess := DllCall("GetCurrentProcess") 
; If IsWow64Process() fails or can not be found, 
; assume this process is not running under wow64. 
; Otherwise, use the value returned in IsWow64Process. 
if !DllCall("IsWow64Process", "uint", ThisProcess, "int*", IsWow64Process) 
    IsWow64Process := false 

DriverFileToRun = DriversTemp\dduout32.exe

if (IsWow64Process)
	DriverFileToRun = DriversTemp\dduout64.exe
 
RunWait, %DriverFileToRun%

; Add Credentials
RunWait, %comspec% /c cmdkey.exe /add:printer.resnet.ucsb.edu /user:%HRSUsername% /pass:%HRSPassword%

; Add Windows Port
RunWait, reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports" /v "\\printer.resnet.ucsb.edu\%PrinterName%" /t reg_sz /f

; Refresh Spooler
RunWait, net stop spooler
RunWait, net start spooler

; Add printer using drivers and port added earlier
RunWait, RunDll32.EXE printui.dll`,PrintUIEntry /if /f %windir%\inf\ntprint.inf /b "%SetupPrinterBox%" /m "HP Color LaserJet CP4020 Series PCL6" /r \\printer.resnet.ucsb.edu\%PrinterName%

MsgBox, The selected printer should now be properly installed. If not`, please contact ResNet for assistance on setting up your printer.

If A_IsCompiled
	FileRemoveDir, DriversTemp, 1

}
catch e  ; Handles the first error/exception raised by the block above.
{
    ; MsgBox, An exception was thrown!`nSpecifically: %e%
    ExitApp
}


GuiClose:
GuiEscape:
Canceled:
Gui, Destroy

ExitApp