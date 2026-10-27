variable "aws_region" {
  type = string
}

variable "state_bucket" {
  type        = string
  description = "The S3 bucket from the bootstrap stack. Also stores the secrets file."
}