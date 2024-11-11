variable "ssl_cert_arn" {
  type        = string
  description = "The ARN of the SSL Cert"
  default     = ""
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