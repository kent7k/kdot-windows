---
name: aws-triage
description: AWS のアラート・障害の一次切り分け。「このアラート何」「503 が出てる」「ALB の 5xx が増えた」「RDS の CPU が張り付いてる」などの時に使う。読み取り系のコマンドだけ組み立てて実行し、事実→仮説→次の 1 手で返す。変更系は提案に留める。
---

# aws-triage

## 前提
- `AWS_PROFILE` が正しいか最初に `aws sts get-caller-identity` で確かめ、アカウントと profile 名を 1 行で出す。
- 使うのは読み取り系だけ: `describe-*` / `get-*` / `list-*` / `aws logs tail` / `cloudwatch get-metric-data`。
  `cwl` `ssm ls` が入っていればそれを使う。
- 変更系（再起動・スケール・SG 変更・ロールバック）は**コマンドを提示して止まる**。実行しない。

## 手順
1. **何が・いつから・どこで**を固定する。
   - アラート名 / メトリクス / しきい値 / 発火時刻（JST と UTC 両方）
   - 対象リソース（ARN か Name）とアカウント・リージョン
2. **直近の変更**を探す。障害の多くは変更起因。
   - CloudTrail: 発火前 2 時間の `Write` イベント（`lookup-events --lookup-attributes AttributeKey=ReadOnly,AttributeValue=false`）
   - デプロイ: CodeDeploy / ECS サービスのイベント / Lambda のバージョン
   - Terraform: `git log` の直近 apply
3. **層ごとに事実を集める**（上から順、当たったら深掘り）。
   - エッジ: ALB/CloudFront の 4xx/5xx・TargetResponseTime・HealthyHostCount
   - 計算: ECS タスクの停止理由 / EC2 ステータスチェック / Lambda のエラー・スロットル
   - データ: RDS の CPU・接続数・FreeStorage・ReadIOPS、ElastiCache の evictions
   - 依存: 外部 API のレイテンシ、AWS Health Dashboard
4. **仮説を 3 つまで**、確からしい順に。各仮説に「確かめるコマンド 1 本」を付ける。
5. **次の 1 手**を 1 行で。変更が要るなら、そのコマンドと戻し方をセットで出す。

## 出力の形
```
対象: <account>/<region> <resource>  発火: 2026-10-13 14:02 JST (05:02 UTC)
事実:
  - ALB 5xx が 14:00 から 2% → 18%
  - ECS サービス web のタスクが 14:01 に 3 → 1（OOMKilled）
  - 13:48 に taskdef :42 へ更新（CloudTrail）
仮説:
  1. :42 のメモリ上限が足りない（確認: aws ecs describe-task-definition ...）
  2. ...
次の 1 手: taskdef を :41 に戻す（コマンド）。戻し: :42 を再指定
```

## しないこと
- 変更系コマンドの実行。
- 「再起動すれば直る」のような根拠なしの助言。事実が足りなければ「足りない」と書く。
