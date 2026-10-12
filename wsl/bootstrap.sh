#!/usr/bin/env bash
# kdot-windows: WSL（Ubuntu/Debian 系）の初期化
#
#   bash wsl/bootstrap.sh
#
# 冪等。何度流しても壊れない。
#   1. apt パッケージ
#   2. mise（ユーザー領域の言語/ツール管理）とグローバルツール
#   3. session-manager-plugin（SSM）
#   4. /etc/wsl.conf
#   5. ~/.bashrc に shell 層を source する行
#   6. aws/ terraform/ の bin を ~/.local/bin へリンク
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m!!  %s\033[0m\n' "$*" >&2; }

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  warn "WSL ではなさそう（/proc/version に microsoft が無い）。続けるが自己責任"
fi

# proxy: Windows の設定を拾えるなら今のうちに環境へ
# shellcheck source=/dev/null
eval "$(bash "$ROOT/wsl/fix/proxy-env.sh" 2>/dev/null || true)"

# ---- 1. apt ---------------------------------------------------------------
step "apt"
sudo apt-get update -qq
mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$ROOT/wsl/packages.apt")
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${PKGS[@]}"
# Ubuntu は fd/bat の名前がずれるので別名を張る
mkdir -p "$HOME/.local/bin"
command -v fd  >/dev/null || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
command -v bat >/dev/null || ln -sf "$(command -v batcat)"  "$HOME/.local/bin/bat"

# ---- 2. mise --------------------------------------------------------------
if ! command -v mise >/dev/null; then
  step "mise を入れる"
  curl -fsSL https://mise.run | sh
fi
mkdir -p "$HOME/.config/mise"
if [ ! -e "$HOME/.config/mise/config.toml" ]; then
  cp "$ROOT/wsl/mise.toml" "$HOME/.config/mise/config.toml"
else
  warn "$HOME/.config/mise/config.toml は既にある。wsl/mise.toml と見比べて足す"
fi
step "mise install（初回は数分）"
mise install -y

# ---- 3. session-manager-plugin -------------------------------------------
if ! command -v session-manager-plugin >/dev/null; then
  step "session-manager-plugin"
  tmp="$(mktemp -d)"
  arch="$(dpkg --print-architecture)"   # amd64 / arm64
  curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${arch//amd64/64bit}/session-manager-plugin.deb" \
    -o "$tmp/smp.deb"
  sudo dpkg -i "$tmp/smp.deb"
  rm -rf "$tmp"
fi

# ---- 4. /etc/wsl.conf -----------------------------------------------------
if ! cmp -s "$ROOT/wsl/wsl.conf" /etc/wsl.conf 2>/dev/null; then
  step "/etc/wsl.conf を置く（反映は wsl --shutdown 後）"
  [ -e /etc/wsl.conf ] && sudo cp /etc/wsl.conf "/etc/wsl.conf.bak.$(date +%Y%m%d%H%M%S)"
  sudo cp "$ROOT/wsl/wsl.conf" /etc/wsl.conf
fi

# ---- 5. shell 層 ------------------------------------------------------------
LINE="[ -f \"$ROOT/wsl/shell/kdot-windows.sh\" ] && . \"$ROOT/wsl/shell/kdot-windows.sh\"  # kdot-windows"
if ! grep -qF '# kdot-windows' "$HOME/.bashrc" 2>/dev/null; then
  step "$HOME/.bashrc に source 行を足す"
  printf '\n%s\n' "$LINE" >> "$HOME/.bashrc"
fi

# ---- 6. bin link ----------------------------------------------------------
step "$HOME/.local/bin へリンク"
bash "$ROOT/install.sh"

step "完了。新しいシェルを開くか:  exec bash"
cat <<MSG

次にやること
  - AWS:  cp $ROOT/aws/config.example ~/.aws/config  を参考に profile を書く
  - 時計がずれたら:  bash $ROOT/wsl/fix/clock-drift.sh
  - VPN で名前が引けなくなったら:  bash $ROOT/wsl/fix/dns-vpn.sh
MSG
