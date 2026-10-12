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

## 次にやること

初版（2026-10-13）は Mac 上で shellcheck・gitleaks・`tf plan` のパーサ確認までしか通していない。
**Windows 実機と WSL では一度も流していない。** 業務機で次の順に通し、落ちたところを issue にする。

1. **Windows 側を通す。** `windows/bootstrap.ps1` を一般ユーザーで実行する。
   特に見る所: WSL の検出（`wsl --status` の終了コード）と、proxy 環境での scoop の設定。
2. **proxy の方式を確かめる。** `bash wsl/fix/proxy-env.sh` が何も出さず、職場が PAC ファイル方式なら、
   PAC から proxy を引く処理を足す（今はレジストリの固定 proxy しか読めない）。
3. **WSL 側を通す。** `wsl/bootstrap.sh` → `exec bash`。mise install と session-manager-plugin の取得が
   proxy 越しに通るかを見る。
4. **AWS の認証を通す。** `aws/config.example` の形で `~/.aws/config` を書き、`awsp dev && aws-whoami`。
   assume-role 先の profile でも 1 回通す。
5. **既存の Terraform リポにガードを入れる。** 各ディレクトリに `.tf-account` を 1 枚置き、
   `tf plan` と（dev で）`tf apply` のアカウント照合が効くか確かめる。
6. **Claude plugin を読ませる。** `claude --plugin-dir ~/kdot-windows/claude` で `/tf-plan-review` に実際の plan を渡す。

### その後の候補

- IAM Identity Center（SSO）へ移行できたら、`aws/config.example` の SSO 例を正にして `aws-mfa` は互換用に残す。
- CI（GitHub Actions）で shellcheck と PowerShell の PSScriptAnalyzer を回す。

## 開発

```sh
pre-commit install   # gitleaks + shellcheck
pre-commit run -a
```

MIT License.
