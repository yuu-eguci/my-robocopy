
: Western(Windows 1252)�ŕۑ����邱�ƁB
: �t�H���_�P�ʂŃo�b�N�A�b�v���܂��B
: ���₵�����Ƃ��͂������΂񉺂�robocopy�̃p���O���t���R�s�[���� NAME,�R�s�[���p�X ��ς��ĂˁB

@echo off
cd /d %~dp0
setlocal enabledelayedexpansion
powercfg -x -standby-timeout-ac 0
powercfg -x -standby-timeout-dc 0

: ##### ���[�U�ݒ� #####
: �o�b�N�A�b�v�t�H���_�̃p�X
set BKFOLDER=D:\01_Backup
: ���O�t�H���_�̃p�X
set LOGFOLDER=D:\02_BackupLogFolder
: �ێ����鐢�㐔
set GENERATION=14


: ���������O�t��HDD���Ȃ�������I��
if not exist "D:\���o�b�N�A�b�v�p��HDD�ł���" ( exit )

: ##############################
: �o�b�N�A�b�v��t�H���_���쐬����p�[�g
: ##############################

: �o�b�N�A�b�v�t�H���_�ɂ���uOLDEST�ŌẪo�b�N�A�b�v�v�uNOW���܂̓��t�����v���擾
set OLDEST=
for /f "usebackq delims=" %%i in (`dir "%BKFOLDER%" /ad /o-d /b`) do ( set OLDEST=%%i )
set T=%time: =0%
set NOW=%date:~0,4%.%date:~5,2%.%date:~8,2%_%T:~0,2%.%T:~3,2%.%T:~6,2%.

: ��������o�b�N�A�b�v�̐�
set COUNT=
for /f "usebackq" %%i in (`dir /ad /b "%BKFOLDER%" ^| find /c /v ""`) do ( set COUNT=%%i )
call :Foo !COUNT!

: �o�b�N�A�b�v���S����5������������
:     NOW�̖��O�̃o�b�N�A�b�v�t�H���_�����
if !COUNT! leq %GENERATION% ( mkdir "%BKFOLDER%\%NOW%" )

: �o�b�N�A�b�v���S����5�ȏゾ������
:     OLDEST�̖��O��NOW�֕ς��� ���̍ۂ����΂�Â��������̃t�H���_�̍X�V�������X�V����
if !COUNT! gtr %GENERATION% (
    move "%BKFOLDER%\%OLDEST%" "%BKFOLDER%\%NOW%"
    : �t�H���_�̍X�V���������X�V�����������񂾂��A���@���킩��񂩂����̂Œ��ɓK���ȃt�@�C�����쐬���폜���čX�V����
    echo aaa > "%BKFOLDER%\%NOW%\aaa.txt"
    del "%BKFOLDER%\%NOW%\aaa.txt"
)

: ##############################
: ���O�t�H���_���쐬����p�[�g
: ##############################

set LOG_T=%time: =0%
set LOG_NOW=%date:~0,4%.%date:~5,2%.%date:~8,2%_%LOG_T:~0,2%.%LOG_T:~3,2%.%LOG_T:~6,2%.
mkdir "%LOGFOLDER%\%LOG_NOW%"

: ##############################
: ��ł�������쐬�����t�H���_��robocopy�o�b�N�A�b�v����
: ##############################

set NAME=
: in ("�����Ƀt�H���_��������")
for /f "delims=" %%i in ("Desktop") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Desktop" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("�����Ƀt�H���_��������")
for /f "delims=" %%i in ("Dropbox") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Dropbox" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("�����Ƀt�H���_��������")
for /f "delims=" %%i in ("Downloads") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Downloads" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("�����Ƀt�H���_��������")
for /f "delims=" %%i in ("Documents") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\Users\username^!^!\Documents" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("�����Ƀt�H���_��������")
for /f "delims=" %%i in ("xampp") do ( set NAME=%%i )
call :Foo !NAME!
robocopy ^
    "C:\xampp" ^
    "%BKFOLDER%\%NOW%\!NAME!" ^
    /LOG:"%LOGFOLDER%\%LOG_NOW%\!NAME!.txt" ^
    /MIR /R:0 /W:0 /NP /NDL /TEE /XJD /XJF /FFT


set NAME=
: in ("�����Ƀt�H���_��������")
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

: �V���b�g�_�E�� �T���Ƃ��A������Ȃ��̂ɖ����o�b�N�A�b�v���Ă����傤���Ȃ�����B
: �P�\��60�b
shutdown.exe -s -t 60
exit

: �ϐ�����O��̃X�y�[�X����菜���֐� �c�c�֐����ČĂ�ł����̂�����?
: �g�������Ƃ���� call :Foo !A! ���Ċ����ŌĂԁB
:Foo
set COUNT=%*
