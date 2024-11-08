terraform {
  backend "s3" {
    bucket = "your-s3-bucket-name"
    key    = "path/to/your/terraform.tfstate"
    region = "eu-central-1"
  }
}