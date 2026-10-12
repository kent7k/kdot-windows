# kdot-windows

Windows + WSL で AWS / Terraform を触る SRE のための道具箱。
**管理者権限なしの業務機**で通ることを第一に、bash + aws cli + jq だけで完結させている。

```
windows/    Windows 側（scoop・.wslconfig・Terminal）       ← PowerShell、管理者不要
wsl/        WSL 側（apt・mise・SSM plugin・wsl.conf・shell 層・VPN/時計/proxy の直し）
aws/        awsp（profile 切替）・aws-mfa（credential_process）・ssm・cwl
terraform/  tf（誤アカウント apply を止めるラッパ）・pre-commit・雛形
claude/     Claude Code plugin（/tf-plan-review・/aws-triage）
```

## はじめ方（3 手）

```powershell
# 1. Windows（PowerShell、一般ユーザー）
git clone https://github.com/kent7k/kdot-windows.git
powershell -ExecutionPolicy Bypass -File .\kdot-windows\windows\bootstrap.ps1
```

WSL が無いと言われたら、管理者に `wsl --install --no-distribution` を 1 回だけ頼む。
その後は一般ユーザーで `wsl --install -d Ubuntu`。

```sh
# 2. WSL（Ubuntu）
git clone https://github.com/kent7k/kdot-windows.git ~/kdot-windows
bash ~/kdot-windows/wsl/bootstrap.sh
exec bash

# 3. AWS の profile を書く（aws/config.example を参考に）
cp ~/kdot-windows/aws/config.example ~/.aws/config   # 中身を自分のものに
awsp dev && aws-whoami
```

## 日常

| やりたい | 打つ |
|---|---|
| アカウントを切り替える | `awsp`（fzf）/ `awsp prod-admin` |
| 今どこにいるか | プロンプトの `[aws:xxx]`（prod は赤）/ `aws-whoami` |
| EC2 に入る | `ssm web-01` |
| RDS にポートを引く | `ssm fwd bastion mydb...rds.amazonaws.com:5432 15432` |
| ログを追う | `cwl tail /ecs/web ERROR` |
| plan | `tf plan`（destroy / replace を末尾に赤で列挙） |
| apply | `tf apply`（アカウント不一致なら止まる） |
| VPN で名前が引けない | まず `.wslconfig` の `networkingMode=mirrored`。だめなら `bash wsl/fix/dns-vpn.sh` |
| 時計がずれて署名エラー | `bash wsl/fix/clock-drift.sh` |
| proxy を WSL に通す | shell 層が Windows の設定を自動で拾う（`KDOTW_PROXY_AUTO=0` で止める） |

## 設計の約束

- **ユーザー領域だけ**。Windows は scoop、WSL は mise。`sudo` が要るのは apt と `/etc/wsl.conf` だけ。
- **秘密は書かない**。アカウント ID・ARN・ホスト名は example に入れず、`gitleaks` を pre-commit で回す。
  手元の設定は `~/.aws/` と `*.secret.*`（gitignore 済み）へ。
- **薄く**。shell 層は alias と関数だけ。ロジックは `*/bin/` の単体スクリプトに置き、どれも単独で動く。
- **認証方式が変わっても壊れない**。IAM user + MFA から IAM Identity Center に移っても `awsp` と `tf` はそのまま。

## 開発

```sh
pre-commit install   # gitleaks + shellcheck
pre-commit run -a
```

MIT License.
