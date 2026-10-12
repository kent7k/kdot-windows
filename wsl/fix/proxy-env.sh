#!/usr/bin/env bash
# Windows の proxy 設定（WinHTTP / IE 設定）を読み、WSL 用の export 行を出す。
#
#   eval "$(bash wsl/fix/proxy-env.sh)"
#
# 何も設定されていなければ何も出さない。shell 層から KDOTW_PROXY_AUTO=1 で自動呼び出し。
set -euo pipefail

reg="/mnt/c/Windows/System32/reg.exe"
[ -x "$reg" ] || exit 0

key='HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
out="$("$reg" query "$key" 2>/dev/null | tr -d '\r' || true)"

enable="$(printf '%s\n' "$out" | awk '/ProxyEnable/ {print $NF}')"
server="$(printf '%s\n' "$out" | awk '/ProxyServer/ {print $NF}')"
override="$(printf '%s\n' "$out" | awk '/ProxyOverride/ {print $NF}')"

[ "${enable:-0x0}" = "0x1" ] && [ -n "$server" ] || exit 0

# "host:port" か "http=host:port;https=host:port" の両形式
case "$server" in
  *=*) http="$(printf '%s' "$server" | tr ';' '\n' | awk -F= '$1=="http"{print $2}')"
       https="$(printf '%s' "$server" | tr ';' '\n' | awk -F= '$1=="https"{print $2}')" ;;
  *)   http="$server"; https="$server" ;;
esac
[ -n "$http" ]  && http="http://$http"
[ -n "$https" ] && https="http://$https"

# ProxyOverride は ; 区切り、<local> はおおむね localhost
noproxy="$(printf '%s' "${override:-}" | sed 's/<local>/localhost,127.0.0.1/; s/;/,/g')"

printf 'export HTTP_PROXY=%q http_proxy=%q\n'   "$http"  "$http"
printf 'export HTTPS_PROXY=%q https_proxy=%q\n' "$https" "$https"
[ -n "$noproxy" ] && printf 'export NO_PROXY=%q no_proxy=%q\n' "$noproxy" "$noproxy"
exit 0
