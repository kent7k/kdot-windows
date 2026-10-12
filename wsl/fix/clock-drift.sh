#!/usr/bin/env bash
# スリープ復帰後に WSL の時計がずれて AWS API が署名エラー（RequestTimeTooSkewed）を出す時の対処。
#
#   bash wsl/fix/clock-drift.sh
set -euo pipefail

if command -v hwclock >/dev/null && sudo hwclock -s 2>/dev/null; then
  echo "hwclock から同期: $(date)"
  exit 0
fi

ps="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
now="$("$ps" -NoProfile -Command '(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")' | tr -d '\r')"
sudo date -u -s "$now" >/dev/null
echo "Windows から同期: $(date)"
