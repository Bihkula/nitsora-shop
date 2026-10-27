variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "Name used for the VPC, the EKS cluster and related resources"
}