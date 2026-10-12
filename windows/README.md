# windows/

Windows 側の初期化。**管理者権限なし**で通る範囲だけを扱う。

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1
```

| ファイル | 役割 |
|---|---|
| `bootstrap.ps1` | scoop → パッケージ → `.wslconfig` 配置 → WSL の状態確認 |
| `packages.scoop` | scoop で入れる一覧 |
| `.wslconfig` | WSL2 のメモリ上限・mirrored networking（VPN/DNS 対策） |
| `terminal-profile.json` | Windows Terminal のプロファイル断片 |

## 管理者に頼む 1 回

WSL の機能有効化だけは管理者が要る。

```
wsl --install --no-distribution
```

その後は一般ユーザーで `wsl --install -d Ubuntu` が通る。
