# aws/

毎日触る AWS の小物。全部 bash + aws cli v2 + jq で完結（追加ツールなし）。

| コマンド | 役割 |
|---|---|
| `awsp [profile]` | fzf で profile を選んで `AWS_PROFILE` を export。プロンプトに `[aws:xxx]` が出る（prod を含むと赤） |
| `awsx` | profile を外す |
| `aws-whoami` | `sts get-caller-identity` |
| `aws-mfa` | `credential_process`。TOTP は 12h に 1 回、assume-role は 1h キャッシュ |
| `ssm` | Session Manager でシェル / ポートフォワード（RDS 経由も） |
| `cwl` | CloudWatch Logs の tail / grep / groups |

設定例は [`config.example`](config.example)。長期キーは `~/.aws/credentials` の `[xxx-keys]` に置き、
`aws-profile` の一覧からは `-keys` で終わる profile を隠している。

TOTP を 1Password から取るなら:

```sh
export AWS_MFA_TOTP_CMD='op item get "AWS dev" --otp'
```
