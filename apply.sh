#!/bin/bash

set -euo pipefail  # Enable strict error handling

# Navigate to Terraform directory
cd terraform/

# Initialize Terraform
terraform init -backend-config "bucket=<your-bucket>" --backend-config "prefix=/path/to/terraform-statefile/" --reconfigure

# Terraform Plan
terraform apply
