
: Western(Windows 1252)で保存すること。
: フォルダ単位でバックアップします。
: 増やしたいときはいっちばん下のrobocopyのパラグラフをコピーして NAME,コピー元パス を変えてね。

@echo off
cd /d %~dp0
setlocal enabledelayedexpansion
powercfg -x -standby-timeout-ac 0
powercfg -x -standby-timeout-dc 0

: ##### ユーザ設定 #####
: バックアップフォルダのパス
set BKFOLDER=D:\01_Backup
: ログフォルダのパス
set LOGFOLDER=D:\02_BackupLogFolder
: 保持する世代数
set GENERATION=14


: そもそも外付けHDDがなかったら終了
if not exist "D:\★バックアップ用のHDDです★" ( exit )

: ##############################
: バックアップ先フォルダを作成するパート
: ##############################

: バックアップフォルダにある「OLDEST最古のバックアップ」「NOWいまの日付時刻」を取得
set OLDEST=
for /f "usebackq delims=" %%i in (`dir "%BKFOLDER%" /ad /o-d /b`) do ( set OLDEST=%%i )
set T=%time: =0%
set NOW=%date:~0,4%.%date:~5,2%.%date:~8,2%_%T:~0,2%.%T:~3,2%.%T:~6,2%.

: 現存するバックアップの数
set COUNT=
for /f "usebackq" %%i in (`dir /ad /b "%BKFOLDER%" ^| find /c /v ""`) do ( set COUNT=%%i )
call :Foo !COUNT!

: バックアップが全部で5つ未満だったら
:     NOWの名前のバックアップフォルダを作る
if !COUNT! leq %GENERATION% ( mkdir "%BKFOLDER%\%NOW%" )

: バックアップが全部で5つ以上だったら
:     OLDESTの名前をNOWへ変える その際いちばん古かったそのフォルダの更新日時を更新する
if !COUNT! gtr %GENERATION% (
    move "%BKFOLDER%\%OLDEST%" "%BKFOLDER%\%NOW%"
    : フォルダの更新日時だけ更新したかったんだが、方法がわからんかったので中に適当なファイルを作成即削除して更新する
    echo aaa > "%BKFOLDER%\%NOW%\aaa.txt"
    del "%BKFOLDER%\%NOW%\aaa.txt"
)

: ##############################
: ログフォルダを作成するパート
: ##############################

set LOG_T=%time: =0%
set LOG_NOW=%date:~0,4%.%date:~5,2%.%date:~8,2%_%LOG_T:~0,2%.%LOG_T:~3,2%.%LOG_T:~6,2%.
mkdir "%LOGFOLDER%\%LOG_NOW%"

: ##############################
: 上でせいこら作成したフォルダにrobocopyバックアップする
: ##############################

set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("Desktop") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Desktop" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("Dropbox") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Dropbox" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("Downloads") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Downloads" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("Documents") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Documents" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("xampp") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\xampp" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("ここにフォルダ名を書く")
for /f "delims=" %%i in ("Music") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\Public\Music\Sony MediaPlayerX\Shared\Music" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


powercfg -x -standby-timeout-ac 60
powercfg -x -standby-timeout-dc 60
endlocal

: シャットダウン 週末とか、いじらないのに毎日バックアップしてもしょうがないから。
: 猶予は60秒
shutdown.exe -s -t 60
exit

: 変数から前後のスペースを取り除く関数 ……関数って呼んでいいのかこれ?
: 使いたいところで call :Foo !A! って感じで呼ぶ。
:Foo
set COUNT=%*
