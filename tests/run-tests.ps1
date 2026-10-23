#Requires -Version 5.1
# my-robocopy のテストです。
# 静的チェックはどの OS でも実行します。backup_core.bat の動作テストは Windows でだけ実行します。
# 動作テストは %TEMP% 配下の使い捨てフォルダだけを使い、実ドライブ、ユーザデータ、電源設定、シャットダウンには触れません。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Core = Join-Path $RepoRoot 'backup_core.bat'
$Entry = Join-Path $RepoRoot 'robocopy_backup.bat'
$GenerationPattern = '^\d{4}\.\d{2}\.\d{2}_\d{2}\.\d{2}\.\d{2}$'
$script:Failures = 0
$script:LastOutput = ''

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Test-Case([string]$Name, [scriptblock]$Body) {
    try {
        & $Body
        Write-Host "ok   - $Name"
    }
    catch {
        $script:Failures++
        Write-Host "FAIL - $Name : $($_.Exception.Message)"
        if ($script:LastOutput) { Write-Host $script:LastOutput }
    }
    $script:LastOutput = ''
}

# ---------- 静的チェック ----------

Test-Case 'batch files and source list use CRLF' {
    foreach ($name in 'robocopy_backup.bat', 'backup_core.bat', 'backup_sources.txt') {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $RepoRoot $name))
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($bytes[$i] -eq 10) {
                Assert-True ($i -gt 0 -and $bytes[$i - 1] -eq 13) "$name has LF without CR"
            }
        }
    }
}

Test-Case 'README settings table matches robocopy_backup.bat' {
    # 既定値の比較に必要な部分は ASCII なので、文字コードに依存しない Latin1 で読みます。
    $entryText = [IO.File]::ReadAllText($Entry, [Text.Encoding]::GetEncoding(28591))
    $readme = [IO.File]::ReadAllText((Join-Path $RepoRoot 'README.md'), [Text.Encoding]::UTF8)
    # 変数名 = (バッチの既定値, README に書く既定値)
    $expected = @{
        'BKFOLDER'   = 'D:\01_Backup', 'D:\01_Backup'
        'LOGFOLDER'  = 'D:\02_BackupLogFolder', 'D:\02_BackupLogFolder'
        'GENERATION' = '14', '14'
        'SOURCES'    = '%~dp0backup_sources.txt', 'backup_sources.txt'
    }
    foreach ($key in $expected.Keys) {
        $batValue, $docValue = $expected[$key]
        Assert-True ($entryText -match "(?m)^set $key=$([regex]::Escape($batValue))\r?$") "robocopy_backup.bat does not set $key=$batValue"
        Assert-True ($readme -match "\| ``$key`` \|[^\r\n]*``$([regex]::Escape($docValue))`` \|") "README does not document $key=$docValue"
    }
    Assert-True ($entryText -match '(?m)^set FLAGFILE=D:\\') 'robocopy_backup.bat does not set FLAGFILE on D:'
    Assert-True ($entryText -match '(?m)^call "%~dp0backup_core\.bat"') 'robocopy_backup.bat does not call backup_core.bat'
}

# ---------- backup_core.bat の動作テスト ----------

function New-Fixture {
    # テストごとに、空白を含む使い捨てフォルダを %TEMP% 配下に作ります。
    $root = Join-Path ([IO.Path]::GetTempPath()) ("my robocopy test " + [guid]::NewGuid())
    $src = Join-Path $root 'src'
    $drive = Join-Path $root 'drive'
    New-Item -ItemType Directory -Path (Join-Path $src 'Docs'), (Join-Path $src 'Bang!!'), $drive | Out-Null
    Set-Content -Path (Join-Path $src 'Docs\a.txt') -Value 'a'
    Set-Content -Path (Join-Path $src 'Bang!!\b.txt') -Value 'b'
    $sources = Join-Path $root 'sources.txt'
    Set-Content -Path $sources -Encoding Ascii -Value @(
        '# comment line',
        "Docs|$src\Docs",
        "Bang|$src\Bang!!"
    )
    [pscustomobject]@{
        Root    = $root
        Src     = $src
        Flag    = Join-Path $drive 'flag'
        Backup  = Join-Path $drive '01_Backup'
        Log     = Join-Path $drive '02_BackupLogFolder'
        Sources = $sources
    }
}

function Invoke-Core($Fixture, [string]$Generation = '3', [switch]$NoSettings) {
    # stderr を ErrorRecord として扱わないよう、この関数の中だけ Continue にします。
    $ErrorActionPreference = 'Continue'
    $names = 'FLAGFILE', 'BKFOLDER', 'LOGFOLDER', 'GENERATION', 'SOURCES'
    try {
        foreach ($name in $names) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
        if (-not $NoSettings) {
            $env:FLAGFILE = $Fixture.Flag
            $env:BKFOLDER = $Fixture.Backup
            $env:LOGFOLDER = $Fixture.Log
            $env:GENERATION = $Generation
            $env:SOURCES = $Fixture.Sources
        }
        Push-Location $Fixture.Root
        $script:LastOutput = & cmd.exe /d /c $Core 2>&1 | Out-String
        return $LASTEXITCODE
    }
    finally {
        Pop-Location
        foreach ($name in $names) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
    }
}

function Get-DirNames([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    @(Get-ChildItem -LiteralPath $Path -Directory | ForEach-Object Name | Sort-Object)
}

function Test-Fixture([string]$Name, [scriptblock]$Body) {
    Test-Case $Name {
        $fixture = New-Fixture
        try { & $Body $fixture }
        finally { Remove-Item -LiteralPath $fixture.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($env:OS -ne 'Windows_NT') {
    Write-Host 'skip - backup_core.bat behavior tests (Windows only)'
}
else {
    Test-Fixture 'does nothing when settings are missing' {
        param($f)
        New-Item -ItemType File -Path $f.Flag | Out-Null
        $before = @(Get-ChildItem -LiteralPath $f.Root -Recurse).Count
        $code = Invoke-Core $f -NoSettings
        Assert-True ($code -eq 1) "exit code was $code"
        Assert-True (@(Get-ChildItem -LiteralPath $f.Root -Recurse).Count -eq $before) 'files were created'
    }

    Test-Fixture 'does nothing when flag file is missing' {
        param($f)
        $code = Invoke-Core $f
        Assert-True ($code -eq 1) "exit code was $code"
        Assert-True (-not (Test-Path -LiteralPath $f.Backup)) 'backup folder was created'
        Assert-True (-not (Test-Path -LiteralPath $f.Log)) 'log folder was created'
    }

    Test-Fixture 'creates a generation and copies sources' {
        param($f)
        New-Item -ItemType File -Path $f.Flag | Out-Null
        $code = Invoke-Core $f
        Assert-True ($code -eq 0) "exit code was $code"
        $gens = @(Get-DirNames $f.Backup)
        Assert-True ($gens.Count -eq 1) "generation count was $($gens.Count)"
        Assert-True ($gens[0] -match $GenerationPattern) "unexpected generation name '$($gens[0])'"
        $gen = Join-Path $f.Backup $gens[0]
        Assert-True (Test-Path -LiteralPath (Join-Path $gen 'Docs\a.txt')) 'Docs\a.txt was not copied'
        Assert-True (Test-Path -LiteralPath (Join-Path $gen 'Bang\b.txt')) 'path with ! was not copied'
        $log = Join-Path $f.Log $gens[0]
        Assert-True (Test-Path -LiteralPath (Join-Path $log 'Docs.txt')) 'Docs.txt log was not written'
        Assert-True (Test-Path -LiteralPath (Join-Path $log 'Bang.txt')) 'Bang.txt log was not written'
    }

    Test-Fixture 'keeps exactly GENERATION generations and mirrors on reuse' {
        param($f)
        New-Item -ItemType File -Path $f.Flag | Out-Null
        for ($run = 1; $run -le 5; $run++) {
            if ($run -eq 5) {
                Remove-Item -LiteralPath (Join-Path $f.Src 'Docs\a.txt')
                Set-Content -Path (Join-Path $f.Src 'Docs\c.txt') -Value 'c'
            }
            $code = Invoke-Core $f -Generation '3'
            Assert-True ($code -eq 0) "run $run exit code was $code"
            # 世代フォルダ名は秒単位なので、実行ごとに 1 秒以上あけます。
            Start-Sleep -Milliseconds 1100
        }
        $gens = @(Get-DirNames $f.Backup)
        $logs = @(Get-DirNames $f.Log)
        Assert-True ($gens.Count -eq 3) "generation count was $($gens.Count): $($gens -join ', ')"
        Assert-True ($logs.Count -eq 5) "log count was $($logs.Count)"
        Assert-True (($gens -join ',') -eq (($logs | Select-Object -Last 3) -join ',')) 'oldest generations were not the ones reused'
        $newest = Join-Path $f.Backup $gens[-1]
        Assert-True (Test-Path -LiteralPath (Join-Path $newest 'Docs\c.txt')) 'new file was not copied'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $newest 'Docs\a.txt'))) 'deleted file was not mirrored'
    }
}

if ($script:Failures -gt 0) {
    Write-Host "$script:Failures test(s) failed"
    exit 1
}
Write-Host 'all tests passed'
exit 0
