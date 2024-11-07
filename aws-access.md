Here's a script to configure access to your AWS account using the AWS CLI.

### Prerequisites
- Ensure you have the AWS CLI installed on your local machine.

### Access Script

Create a bash script named `configure_aws_access.sh`:

```bash
#!/bin/bash

# Variables
AWS_ACCESS_KEY_ID="your-access-key-id"
AWS_SECRET_ACCESS_KEY="your-secret-access-key"
AWS_REGION="eu-central-1" # Change as necessary

# Configure AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

echo "AWS CLI configured successfully."
```

### How to Use
1. Save the script as `configure_aws_access.sh`.
2. Make it executable: `chmod +x configure_aws_access.sh`.
3. Run the script: `./configure_aws_access.sh`.

This will configure your AWS CLI with the provided access key, secret key, and region. Always make sure to keep your credentials secure. 

Ready to give it a spin?