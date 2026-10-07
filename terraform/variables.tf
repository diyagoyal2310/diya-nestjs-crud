variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use for the NestJS application"
  type        = string
  default     = "vpc-065bc760037b1e15d"
}

variable "existing_ssh_key_pair_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "main-key"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to access SSH"
  type        = string
}
