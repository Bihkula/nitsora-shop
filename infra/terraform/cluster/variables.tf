variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "Name used for the VPC, the EKS cluster and related resources"
}
variable "kubernetes_version" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "node_count" {
  type = number
}