# claude/

Claude Code の plugin。skill 2 つと、Terraform リポに置く CLAUDE.md の雛形。

```sh
# plugin として読む（このリポを clone した場所を指す）
claude --plugin-dir "$KDOTW_ROOT/claude"
# または ~/.claude/settings.json の plugins に足す
```

| skill | 使う時 |
|---|---|
| `/tf-plan-review` | plan 出力を貼って「apply していい？」 |
| `/aws-triage` | アラート・障害の一次切り分け。読み取り系しか実行しない |

`CLAUDE.md.template` は Terraform リポのルートに `CLAUDE.md` として置く。
