#!/usr/bin/env bash
# bin をユーザー領域にリンクする（冪等）。wsl/bootstrap.sh からも呼ばれる。
#   bash install.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
for f in "$ROOT"/aws/bin/* "$ROOT"/terraform/bin/*; do
  ln -sfn "$f" "$BIN/$(basename "$f")"
  echo "  $BIN/$(basename "$f") -> ${f#"$ROOT"/}"
done
case ":$PATH:" in *":$BIN:"*) ;; *) echo "!! $BIN が PATH に無い。wsl/shell/kdot-windows.sh を source すれば通る" >&2 ;; esac
