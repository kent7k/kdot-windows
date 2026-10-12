# shellcheck shell=bash
# kdot-windows の shell 層。~/.bashrc から source される。
# ここは「薄く」保つ。重い処理は bin/ のスクリプトへ。

KDOTW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export KDOTW_ROOT

# ---- PATH -----------------------------------------------------------------
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# Windows 側の .exe は appendWindowsPath=false なので必要なものだけ
for d in /mnt/c/Windows/System32 /mnt/c/Windows/System32/WindowsPowerShell/v1.0; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$PATH:$d" ;; esac
done
export PATH

# ---- mise -----------------------------------------------------------------
command -v mise >/dev/null && eval "$(mise activate bash)"

# ---- proxy（Windows 設定を自動で拾う）----------------------------------
if [ "${KDOTW_PROXY_AUTO:-1}" = 1 ] && [ -z "${HTTPS_PROXY:-}" ]; then
  eval "$(bash "$KDOTW_ROOT/wsl/fix/proxy-env.sh" 2>/dev/null || true)"
fi

# ---- AWS ------------------------------------------------------------------
export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off

# awsp: fzf で profile を選んで export。引数があれば直接
awsp() {
  local p
  if [ $# -gt 0 ]; then p="$1"; else p="$(aws-profile)"; fi
  [ -n "$p" ] || return 1
  export AWS_PROFILE="$p"
  local r
  r="$(aws configure get region --profile "$p" 2>/dev/null || true)"
  [ -n "$r" ] && export AWS_DEFAULT_REGION="$r" AWS_REGION="$r"
  echo "AWS_PROFILE=$AWS_PROFILE ${r:+region=$r}"
}
awsx() { unset AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION; echo "AWS_PROFILE を外した"; }
alias aws-whoami='aws sts get-caller-identity --output table'

# ---- prompt: 今どのアカウントにいるかを常に見せる ---------------------
__kdotw_ps1() {
  [ -n "${AWS_PROFILE:-}" ] || return 0
  case "$AWS_PROFILE" in
    *prod*|*prd*|*honban*) printf '\001\033[1;31m\002[aws:%s]\001\033[0m\002 ' "$AWS_PROFILE" ;;
    *)                     printf '\001\033[1;33m\002[aws:%s]\001\033[0m\002 ' "$AWS_PROFILE" ;;
  esac
}
case "$PS1" in *__kdotw_ps1*) ;; *) PS1='$(__kdotw_ps1)'"$PS1" ;; esac

# ---- Terraform ----------------------------------------------------------
# tf は terraform/bin/tf（ガード付きラッパ）。素の terraform を呼びたい時は command terraform
alias tfp='tf plan'
alias tfa='tf apply'

# ---- WSL 小物 -----------------------------------------------------------
alias open='wslview'          # wslu: Windows 側で開く
alias clip='clip.exe'         # echo foo | clip
alias winhome='cd "$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d "\r")")"'
