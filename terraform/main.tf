terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.15.0"
}

provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "nestjs-production-vpc"
  }
}
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "nestjs-production-igw"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "nestjs-public-subnet"
  }
}

resource "aws_route_table" "prod_public_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }

  tags = {
    Name = "nestjs-production-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.prod_public_route_table.id
}

resource "aws_security_group" "nestjs_security_group" {
  name        = "nestjs_security_group"
  description = "Security group for the NestJS application"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NestJS application"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from the authorized IP address"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["122.186.35.178/32"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nestjs_security_group"
  }
}

variable "existing_ssh_key_pair_name" {
  description = "Optional name of an existing EC2 key pair for SSH access. Do not provide private key material."
  type        = string
  default     = null
}

data "aws_ssm_parameter" "ubuntu_2404_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "nestjs_instance" {
  ami                         = data.aws_ssm_parameter.ubuntu_2404_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.nestjs_security_group.id]
  key_name                    = var.existing_ssh_key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "nestjs-application-instance"
  }
}
