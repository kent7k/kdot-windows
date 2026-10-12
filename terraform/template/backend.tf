# state は S3。bucket / key は環境ごとに -backend-config で渡すか、ここに直書き。
# 例: tf init -backend-config=backend/dev.hcl
terraform {
  backend "s3" {
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true # S3 ネイティブロック（1.10+）。古い版なら dynamodb_table を使う
  }
}
