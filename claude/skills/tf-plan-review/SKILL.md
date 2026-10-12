---
name: tf-plan-review
description: terraform plan の出力をレビューして、壊れるもの・意図しない差分・適用順の罠を表で返す。「plan をレビューして」「この差分だいじょうぶ？」「apply していい？」の時に使う。apply はしない。
---

# tf-plan-review

## 入力
- `tf plan -no-color` の出力（貼られたもの、または `.plan.*` ファイルを `terraform show -no-color` した結果）
- 可能なら差分の元になった `git diff`

## 手順
1. 要約行（`Plan: X to add, Y to change, Z to destroy`）を先頭に出す。
2. **destroy / replace を全部列挙**し、1 件ずつ「データが消えるか」「ダウンタイムが出るか」を判定する。
   - RDS / EBS / S3 / DynamoDB / EFS の destroy は赤。`deletion_protection` / `prevent_destroy` / `skip_final_snapshot` を確認する。
   - replace の原因（`# forces replacement` の行）を特定し、`lifecycle { ignore_changes }` や `moved {}` で回避できるかを書く。
3. **change** のうち、以下は個別に呼び出す。
   - IAM ポリシー・SG のインバウンドが広がる（`0.0.0.0/0`、`*` アクション）
   - 暗号化・ログ・バージョニングが OFF になる
   - タグだけの差分（`default_tags` のずれ）は「無害」として束ねる
4. plan に出ないリスクを 1 行ずつ。
   - provider / module のバージョン上げが混ざっていないか
   - state 操作（`moved` / `import` / `removed`）が必要な差分ではないか
   - 適用順: 先に別ディレクトリの apply が要るか
5. 最後に判定を 1 行: `apply 可` / `条件付き可（条件）` / `止める（理由）`。

## 出力の形
```
Plan: 3 to add, 1 to change, 2 to destroy

| 種別 | リソース | 影響 | 対処 |
|---|---|---|---|
| destroy | aws_db_instance.main | データ消失 | 止める。skip_final_snapshot=false を確認 |
| replace | aws_instance.web | 再作成・数分断 | ami 変更が原因。意図通りなら可 |

判定: 止める（RDS の destroy が含まれる）
```

## しないこと
- `terraform apply` を実行しない。
- アカウント ID・ARN をそのまま外部に出す提案をしない。
