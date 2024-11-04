#!/bin/bash

set -euo pipefail  # Enable strict error handling

# Variables
TERRAFORM_VERSION="1.5.0"
S3_BUCKET="your-s3-bucket-name"
S3_KEY="path/to/your/terraform.tfstate"
REGION="your-aws-region"
TEMP_DIR="/tmp/terraform_install"

# Function to check and install specific Terraform version
install_terraform() {
    local current_version
    current_version=$(terraform version -json 2>/dev/null | jq -r .terraform_version || echo "")

    if [[ "$current_version" != "$TERRAFORM_VERSION" ]]; then
        echo "Installing Terraform version $TERRAFORM_VERSION..."
        
        # Create a temporary directory for the download
        mkdir -p $TEMP_DIR
        cd $TEMP_DIR

        # Download and install Terraform
        wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        unzip -q "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        sudo mv terraform /usr/local/bin/
        rm -f "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        
        cd - > /dev/null
        rm -rf $TEMP_DIR

        echo "Terraform version $TERRAFORM_VERSION installed successfully."
    else
        echo "Terraform version $TERRAFORM_VERSION is already installed."
    fi
}

# Install jq if not installed (used for parsing JSON)
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Installing jq..."
    sudo apt-get update -qq
    sudo apt-get install -y jq
fi

# Install the specified version of Terraform
install_terraform

# Prompt user for confirmation before applying the configuration
read -p "Are you sure you want to apply the Terraform configuration? (yes/no): " confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo "Terraform apply cancelled."
    exit 1
fi

# Initialize Terraform with S3 backend
terraform init \
    -backend-config="bucket=$S3_BUCKET" \
    -backend-config="key=$S3_KEY" \
    -backend-config="region=$REGION"

# Apply Terraform configurations
terraform apply -auto-approve
