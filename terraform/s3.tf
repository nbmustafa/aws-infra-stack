resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "my-logs-bucket"
    target_prefix = "log/"
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }

  tags = {
    Name        = "My Secure Bucket"
    Environment = "Production"
  }
}

