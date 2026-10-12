provider "aws" {
  region = var.region

  # tf ラッパがここを読んで、違うアカウントへの apply を止める
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
