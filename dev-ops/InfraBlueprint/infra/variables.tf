variable "aws_region" {
  description = "AWS region to deploy all resources into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address in CIDR notation allowed to SSH into the EC2 instance (e.g. 102.22.45.10/32). Never use 0.0.0.0/0."
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance. Passed in via tfvars — never hardcoded."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance. Passed in via tfvars — never hardcoded. Minimum 8 characters."
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Globally unique name for the S3 static assets bucket. Must be lowercase, no spaces."
  type        = string
}

variable "ec2_ami" {
  description = "AMI ID for the EC2 instance. Must match the deployment region. Amazon Linux 2023 in eu-north-1: ami-0a0823e4ea064404d"
  type        = string
}

variable "environment" {
  description = "Deployment environment — used to namespace resources. Either 'staging' or 'production'."
  type        = string
  default     = "staging"
}