
## README

# Terraform Infrastructure Stack

This Terraform code builds a comprehensive infrastructure stack on AWS, consisting of a VPC, subnets, ALB, EC2 instances, RDS Aurora, backup vault, S3 bucket, and KMS key for encryption. The stack is designed with security best practices, including HTTPS encryption, strict NACLs, and security group rules.

## Features

- **VPC and Subnets**: Creates a Virtual Private Cloud (VPC) with public subnets for the Application Load Balancer (ALB), private compute subnets for EC2 instances and Auto Scaling Groups (ASG), and database subnets for RDS Aurora. Includes routing tables, security groups, and NACLs to restrict traffic to the minimum necessary.

- **Application Load Balancer (ALB)**: Deploys an ALB with HTTPS encryption for secure traffic handling.

- **EC2 Instances and Auto Scaling**: Configures EC2 instances within private subnets with Auto Scaling Groups for high availability and resilience.

- **RDS Aurora**: Sets up an RDS Aurora cluster spanning three Availability Zones for high availability and fault tolerance.

- **Backup Vault**: Ensures data backup and recovery mechanisms.

- **S3 Bucket**: Creates an S3 bucket with versioning, server-side encryption, logging, and lifecycle policies for data management and security.

- **KMS Key**: Provides a KMS key for encryption of sensitive data.

## Prerequisites

- AWS account with appropriate permissions.
- Terraform installed on your local machine.
- AWS CLI configured with your credentials.
- make sure you have created ssl cert and uploaded to aws to use its arn in ALB listener
- make sure your db username and pass are created in aws secret manager

## Usage

1. **Clone the repository**:
   ```sh
   git clone https://github.com/your-repository/terraform-infrastructure-stack.git
   cd terraform-infrastructure-stack
   ```

2. **Initialize Terraform**:
   ```sh
   terraform init
   ```

3. **Plan the deployment**:
   ```sh
   terraform plan
   ```

4. **Apply the configuration**:
   ```sh
   terraform apply
   ```

## Resources

### VPC and Subnets
- Creates a VPC with CIDR block `10.0.0.0/16`.
- Public subnets for ALB, private compute subnets for EC2 and ASG, and database subnets for RDS Aurora.
- Routing tables and NACLs to restrict traffic.

### Application Load Balancer (ALB)
- ALB with HTTPS listener using a valid SSL certificate.
- ALB spans across multiple Availability Zones for high availability.

### EC2 Instances and Auto Scaling
- Launches EC2 instances in private subnets with user data to install and configure applications (e.g., Apache2).
- Auto Scaling Group to ensure desired capacity and high availability.

### RDS Aurora
- RDS Aurora cluster with MySQL engine.
- Spans three Availability Zones for high availability.
- Encrypted with KMS key.

### Backup Vault
- AWS Backup Vault for managing backups.

### S3 Bucket
- S3 bucket with versioning, server-side encryption (AES-256), logging, and lifecycle policies.
- Bucket policy to enforce HTTPS and restrict access.

### KMS Key
- AWS KMS key for encryption of data at rest.

## Security Considerations

- **HTTPS Encryption**: ALB is configured to handle HTTPS traffic for secure communication.
- **Network ACLs**: NACLs restrict traffic to the minimum required for each subnet.
- **Security Groups**: Security groups allow only necessary traffic to instances and services.
- **Server-Side Encryption**: S3 bucket and RDS Aurora data are encrypted at rest using AWS KMS keys.
- **Logging and Monitoring**: S3 access logs are stored in a separate bucket for audit purposes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

For any questions or issues, please contact [nashwan.bilal@engineer.com].

---
