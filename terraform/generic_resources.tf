# Define the KMS key
resource "aws_kms_key" "main" {
  description              = "${local.organisation} Generic KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = {
    Name = "${local.organisation}-kms-key"
  }
}

# Optionally define an alias for the KMS key
resource "aws_kms_alias" "main" {
  name          = "alias/${local.organisation}-kms-key"
  target_key_id = aws_kms_key.main.id
}
