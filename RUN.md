Sure! Here’s a script that will help you run your Terraform code locally and upload the state file to an S3 bucket.

### Prerequisites
Ensure you have:
1. Terraform installed on your local machine.
2. AWS CLI configured with the necessary permissions to access S3.

### Step-by-Step Script

1. **Create a backend configuration file**:
    - Create a file named `backend.tf` to configure the S3 backend.
    
    ```hcl
    terraform {
      backend "s3" {
        bucket         = "your-s3-bucket-name"
        key            = "path/to/your/terraform.tfstate"
        region         = "us-east-1"
      }
    }
    ```

2. **Initialize Terraform**:
    - Create a shell script to initialize Terraform and apply your configuration.
    
    ```bash
    #!/bin/bash

    # Navigate to your Terraform directory
    cd /path/to/your/terraform/code

    # Initialize Terraform
    terraform init -backend-config=backend.tf

    # Apply Terraform configuration
    terraform apply -auto-approve

    # Print a message upon completion
    echo "Terraform applied and state file uploaded to S3."
    ```

3. **Make the script executable**:
    ```bash
    chmod +x run_terraform.sh
    ```

4. **Run the script**:
    ```bash
    ./run_terraform.sh
    ```

### Explanation

- **backend.tf**: Configures the S3 backend for storing Terraform state files.
- **run_terraform.sh**: A script to initialize and apply your Terraform configuration, ensuring the state file is uploaded to the specified S3 bucket.

Feel like giving it a go?