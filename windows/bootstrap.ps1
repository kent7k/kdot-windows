# kdot-windows: Windows 側の初期化（管理者権限なしで通る範囲）
#
#   実行:  powershell -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1
#
# やること
#   1. scoop（ユーザースコープのパッケージ管理）を入れる
#   2. 日常ツールを scoop で入れる
#   3. .wslconfig を %USERPROFILE% に置く（既存があれば退避）
#   4. WSL が使える状態か確認し、だめなら「情シスに頼む 1 行」を出す
#
# 管理者が要るもの（ここではやらない）
#   - WSL の機能有効化:  wsl --install --no-distribution
#   - Windows Terminal / VS Code を Store 以外から入れる場合

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# ---- 1. scoop -------------------------------------------------------------
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Step 'scoop を入れる'
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
} else {
    Step 'scoop は入っている'
}

# proxy 環境なら scoop にも教える（HTTPS_PROXY があれば流用）
if ($env:HTTPS_PROXY -and -not (scoop config proxy)) {
    Step "scoop に proxy を設定: $env:HTTPS_PROXY"
    scoop config proxy ($env:HTTPS_PROXY -replace '^https?://', '')
}

# ---- 2. packages ---------------------------------------------------------
Step 'scoop bucket'
scoop bucket add extras 2>$null | Out-Null

$pkgs = Get-Content (Join-Path $here 'packages.scoop') |
    Where-Object { $_ -and -not $_.StartsWith('#') }
Step "scoop install: $($pkgs -join ', ')"
scoop install @pkgs

# ---- 3. .wslconfig --------------------------------------------------------
$src = Join-Path $here '.wslconfig'
$dst = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path $dst) {
    $bak = "$dst.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    Warn ".wslconfig が既にある。$bak に退避して上書きする"
    Copy-Item $dst $bak
}
Copy-Item $src $dst -Force
Step ".wslconfig を置いた: $dst"

# ---- 4. WSL の状態 --------------------------------------------------------
Step 'WSL の状態'
$wslOk = $false
try {
    $status = wsl.exe --status 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { $wslOk = $true; Write-Host $status }
} catch {}

if (-not $wslOk) {
    Warn 'WSL が使えない。以下を管理者権限で実行してもらう（1 回だけ）:'
    Write-Host ''
    Write-Host '    wsl --install --no-distribution' -ForegroundColor White
    Write-Host ''
    Warn 'その後は一般ユーザーで:  wsl --install -d Ubuntu'
} else {
    $distros = wsl.exe --list --quiet 2>$null | ForEach-Object { $_ -replace "`0", '' } | Where-Object { $_ }
    if (-not $distros) {
        Warn 'ディストリが無い。一般ユーザーで:  wsl --install -d Ubuntu'
    } else {
        Step "ディストリ: $($distros -join ', ')"
        Write-Host ''
        Write-Host '次: WSL の中で  bash wsl/bootstrap.sh' -ForegroundColor Green
    }
}
