#!/usr/bin/env bash
# VPN に繋いだら WSL で名前が引けなくなった時の対処。
# Windows 側の DNS サーバを拾って /etc/resolv.conf に書く。
#
#   bash wsl/fix/dns-vpn.sh
#
# 前提: /etc/wsl.conf の [network] generateResolvConf=false
# （mirrored networking が使える Windows ならそもそも不要。まずは .wslconfig を疑う）
set -euo pipefail

ps="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
[ -x "$ps" ] || { echo "powershell.exe が見つからない" >&2; exit 1; }

mapfile -t servers < <(
  "$ps" -NoProfile -Command \
    'Get-DnsClientServerAddress -AddressFamily IPv4 | ForEach-Object { $_.ServerAddresses } | Select-Object -Unique' \
    2>/dev/null | tr -d '\r' | grep -E '^[0-9.]+$' || true
)
[ "${#servers[@]}" -gt 0 ] || { echo "Windows から DNS サーバを拾えなかった" >&2; exit 1; }

if grep -qE '^[[:space:]]*generateResolvConf[[:space:]]*=[[:space:]]*true' /etc/wsl.conf 2>/dev/null; then
  echo "!! /etc/wsl.conf の generateResolvConf が true。false にして wsl --shutdown しないと次回起動で戻る" >&2
fi

{
  echo "# written by kdot-windows dns-vpn.sh $(date -Iseconds)"
  for s in "${servers[@]}"; do echo "nameserver $s"; done
} | sudo tee /etc/resolv.conf >/dev/null
sudo chattr -i /etc/resolv.conf 2>/dev/null || true
echo "resolv.conf: ${servers[*]}"
