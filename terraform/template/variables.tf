variable "project" {
  description = "プロジェクト名（タグとリソース名の接頭辞）"
  type        = string
}

variable "environment" {
  description = "dev / stg / prod"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment は dev / stg / prod のどれか。"
  }
}

variable "account_id" {
  description = "この構成を適用する AWS アカウント ID（誤適用ガード）"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "12 桁の数字。"
  }
}

variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}
