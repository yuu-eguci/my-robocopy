
: Shift_JIS(CP932)・CRLFで保存してください。
: バックアップ本体です。robocopy_backup.bat から呼び出します。
: 設定は環境変数 FLAGFILE, BKFOLDER, LOGFOLDER, GENERATION, SOURCES で受け取ります。
: 電源設定の変更やシャットダウンは行いません。
: 終了コードは 0 が実行済み、1 が何もせずに終了したことを表します。

@echo off
setlocal disabledelayedexpansion

: 設定が足りないときは何もせずに終了します。
for %%v in (FLAGFILE BKFOLDER LOGFOLDER GENERATION SOURCES) do (
    if not defined %%v (
        echo %%v is not set.
        exit /b 1
    )
)
set GEN=0
set /a GEN=GENERATION 2>nul
if %GEN% lss 1 exit /b 1

: そもそも外付けHDDがなかったら終了します。
if not exist "%FLAGFILE%" exit /b 1
if not exist "%SOURCES%" exit /b 1

: 世代フォルダ名に使う現在時刻を、地域設定に依存しない形式で取得します。
set NOW=
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Get-Date -Format yyyy.MM.dd_HH.mm.ss"`) do set NOW=%%i
if not defined NOW exit /b 1
if exist "%BKFOLDER%\%NOW%" exit /b 1

: 世代フォルダの数と、名前順でいちばん古い世代フォルダを取得します。
set COUNT=0
set OLDEST=
if exist "%BKFOLDER%\" (
    for /f "delims=" %%i in ('dir /ad /b /on "%BKFOLDER%"') do (
        if not defined OLDEST set "OLDEST=%%i"
        set /a COUNT+=1
    )
)

: 世代フォルダが GENERATION 個未満なら新しく作り、そうでなければいちばん古いものを NOW の名前に変えて再利用します。
if %COUNT% geq %GEN% (
    move "%BKFOLDER%\%OLDEST%" "%BKFOLDER%\%NOW%" >nul || exit /b 1
) else (
    mkdir "%BKFOLDER%\%NOW%" || exit /b 1
)
mkdir "%LOGFOLDER%\%NOW%" || exit /b 1

: backup_sources.txt の「名前|コピー元パス」ごとに robocopy でミラーします。
for /f "usebackq eol=# tokens=1,* delims=|" %%a in ("%SOURCES%") do (
    robocopy "%%b" "%BKFOLDER%\%NOW%\%%a" /LOG:"%LOGFOLDER%\%NOW%\%%a.txt" /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT
)
exit /b 0
