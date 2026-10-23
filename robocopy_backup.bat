
: Shift_JIS(CP932)・CRLFで保存してください。
: タスクスケジューラから実行する入口です。スリープ抑止とシャットダウンを担当します。
: バックアップ本体は backup_core.bat です。バックアップ対象は backup_sources.txt に書いてください。

@echo off
cd /d %~dp0
setlocal

: ##### ユーザ設定 #####
: バックアップ用HDDの存在フラグ
set FLAGFILE=D:\★バックアップ用のHDDです★
: バックアップフォルダのパス
set BKFOLDER=D:\01_Backup
: ログフォルダのパス
set LOGFOLDER=D:\02_BackupLogFolder
: 保持する世代数
set GENERATION=14
: バックアップ対象の一覧ファイル
set SOURCES=%~dp0backup_sources.txt

: バックアップ中はスリープしないようにします。
powercfg -x -standby-timeout-ac 0
powercfg -x -standby-timeout-dc 0

call "%~dp0backup_core.bat"
set RESULT=%errorlevel%

powercfg -x -standby-timeout-ac 60
powercfg -x -standby-timeout-dc 60

: HDDがないなど、バックアップしなかったときはシャットダウンしません。
if not "%RESULT%"=="0" exit /b %RESULT%

: 週末など、いじらないのに毎日バックアップしてもしょうがないのでシャットダウンします。
: 猶予は60秒です。
shutdown.exe -s -t 60
exit /b 0
