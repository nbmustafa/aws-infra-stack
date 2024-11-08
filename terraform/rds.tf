# Store Credentials in AWS Secrets Manager
# First, manually create a secret in AWS Secrets Manager with the username and password for the Aurora RDS database. 
# Here’s an example of the JSON structure:
# {
#   "username": "admin",
#   "password": "yourpassword"
#  }
#

resource "aws_db_subnet_group" "main" {
  name       = "${local.organisation}-aurora-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_subnet.id]

  tags = {
    Name = "AuroraDBSubnetGroup"
  }
}

## Retrive secrets from AWS secret managers:
data "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.organisation}-aurora-db-credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
}

## Create db cluster and db instance
# Create RDS Cluster and Instances
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = var.db_engine_version
  master_username         = local.db_username
  master_password         = local.db_password
  database_name           = "${local.organisation}-db"
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  skip_final_snapshot     = true

  tags = {
    Name        = "${local.organisation}-AuroraCluster"
    Environment = "production"
    Backup      = "true"
  }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count                   = 2
  identifier              = "aurora-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.aurora.id
  instance_class          = "db.r5.large"
  engine                  = aws_rds_cluster.aurora.engine
  engine_version          = aws_rds_cluster.aurora.engine_version
  publicly_accessible     = false

  tags = {
    Name        = "AuroraInstance${count.index}"
    Environment = "production"
  }
}

#### Create Backup Vault
resource "aws_backup_vault" "example" {
  name        = "${local.organisation}-backup-vault"
  kms_key_arn = aws_kms_key.main.id # Optional
}

#### Create Backup Plan
resource "aws_backup_plan" "example" {
  name = "${local.organisation}-backup-plan"

  rule {
    rule_name         = "${local.organisation}-backup-plan-rule"
    target_vault_name = aws_backup_vault.example.name
    schedule          = "cron(0 12 * * ? *)"
    start_window      = 360
    completion_window = 720
    lifecycle {
      delete_after = 30
    }
  }
}

#
#### Assign Resource to Backup Plan
resource "aws_backup_selection" "example" {
  iam_role_arn = "arn:aws:iam::123456789012:role/AWSBackupDefaultServiceRole"
  name         = "${local.organisation}-aurora-backup-selection"
  plan_id      = aws_backup_plan.example.id

  resources = [
    "arn:aws:rds:us-east-1:123456789012:db:aurora-instance-0",
    "arn:aws:rds:us-east-1:123456789012:db:aurora-instance-1",
  ]
}

# Define the KMS key
resource "aws_kms_key" "main" {
  description             = "Example KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
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

# Output the KMS key ID
output "kms_key_id" {
  value = aws_kms_key.main.id
}

# Output the KMS key ARN
output "kms_key_arn" {
  value = aws_kms_key.main.arn
}
