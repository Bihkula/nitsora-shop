variable "aws_region" {
  type        = string
  description = "AWS region for everything"
}

variable "state_bucket" {
  type        = string
  description = "Name of the S3 bucket that holds Terraform state"
}