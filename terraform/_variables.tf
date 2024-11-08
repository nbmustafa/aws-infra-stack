variable "ssl_cert_arn" {
  type        = string
  description = "The ARN of the SSL Cert"
  default     = ""
}


variable "allowed_cidr" {
  description = "CIDR block allowed for inbound RDS connections (e.g., office IP)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for backup encryption"
  type        = string
}

variable "iam_backup_role_arn" {
  description = "IAM role ARN for AWS Backup"
  type        = string
}

variable "db_engine_version" {
  description = "Engine version for Aurora MySQL"
  type        = string
  default     = "5.7.mysql_aurora.2.08.1"
}

# variable "db_name" {
#   description = "Database name"
#   type        = string
#   default     = "mydatabase"
# }