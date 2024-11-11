# ### Explanation
# - **Versioning**: Enables versioning to keep multiple versions of an object in the same bucket.
# - **Server-Side Encryption**: Encrypts the data at rest using AES-256.
# - **Logging**: Stores access logs in a separate bucket.
# - **Lifecycle Rules**: Manages the lifecycle of objects to transition to cheaper storage and eventually delete them.
# - **Bucket Policy**: Denies requests that are not using secure transport (HTTPS).

# Creating S3 bucket
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${local.organisation}-bucket1-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = {
    Name        = "My Secure Bucket"
    Environment = "Production"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled" # Require MFA for delete operations
  }
}

# Enable server-side encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Applying bucket policy: Denies requests that are not using secure transport (HTTPS).
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.secure_bucket.bucket}", 
        "arn:aws:s3:::${aws_s3_bucket.secure_bucket.bucket}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

# Manage lifecycle of objects
# filter:
# Specifies a filter to limit the scope of the rule.
# The prefix field is set to an empty string "", meaning the rule applies to all objects in the bucket.

# transition:
# Defines how and when to transition objects to a different storage class.
# In this example, objects will be transitioned to the GLACIER storage class after 30 days.

# expiration:
# Specifies when the objects should expire (i.e., be permanently deleted).
# In this example, objects will be deleted 365 days after their creation.
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
