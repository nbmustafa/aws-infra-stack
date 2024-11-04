#### 1. Create Backup Vault
resource "aws_backup_vault" "example" {
  name        = "my-backup-vault"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/your-kms-key-id" # Optional
}

#### 2. Create Backup Plan
resource "aws_backup_plan" "example" {
  name = "my-backup-plan"

  rule {
    rule_name         = "my-backup-plan-rule"
    target_vault_name = aws_backup_vault.example.name
    schedule          = "cron(0 12 * * ? *)"
    start_window      = 360
    completion_window = 720
    lifecycle {
      delete_after = 30
    }
  }
}

#### 3. Tag Aurora RDS Instance for Backup
## Ensure your Aurora RDS instance is tagged appropriately for the backup plan to identify it.

resource "aws_rds_cluster_instance" "example" {
  count              = 2
  identifier         = "aurora-instance-${count.index}"
  cluster_identifier = "aurora-cluster-demo"
  instance_class     = "db.t3.medium"

  tags = {
    Backup = "true"
  }
}

#### 4. Assign Resource to Backup Plan
resource "aws_backup_selection" "example" {
  iam_role_arn = "arn:aws:iam::123456789012:role/AWSBackupDefaultServiceRole"
  name         = "aurora-backup-selection"
  plan_id      = aws_backup_plan.example.id

  resources = [
    "arn:aws:rds:us-east-1:123456789012:db:aurora-instance-0",
    "arn:aws:rds:us-east-1:123456789012:db:aurora-instance-1",
  ]
}