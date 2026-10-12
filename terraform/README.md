# terraform/

| ファイル | 役割 |
|---|---|
| `bin/tf` | `terraform` のガード付きラッパ。別アカウントへの apply を止め、plan の destroy を赤く列挙 |
| `.pre-commit-config.yaml` | fmt / validate / tflint / trivy / terraform-docs / gitleaks |
| `.tflint.hcl` `.terraform-docs.yml` | 上の設定 |
| `template/` | 新しい構成を切る時の雛形（`allowed_account_ids` でガードが効く形） |

## 新しい構成を切る

```sh
cp -r "$KDOTW_ROOT/terraform/template" ./infra/foo
cp "$KDOTW_ROOT/terraform/.pre-commit-config.yaml" "$KDOTW_ROOT/terraform/.tflint.hcl" "$KDOTW_ROOT/terraform/.terraform-docs.yml" ./
pre-commit install
```

バージョンは `.terraform-version` で固定（mise が読む。tfenv 互換）。

## ガードの仕組み

`tf apply` の前に `sts get-caller-identity` のアカウントと、`allowed_account_ids`（無ければ `.tf-account`）
を比べる。どちらも無いディレクトリでは警告のみ。厳格にするなら `TF_GUARD_STRICT=1`。
