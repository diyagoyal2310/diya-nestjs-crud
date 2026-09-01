terraform {
  required_version = "~> 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =========================================================
# EXISTING VPC
# =========================================================

data "aws_vpc" "existing_vpc" {
  id = var.existing_vpc_id
}

# =========================================================
# EXISTING INTERNET GATEWAY
# =========================================================

data "aws_internet_gateway" "existing_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# =========================================================
# EXISTING SUBNET
# =========================================================

data "aws_subnet" "existing_subnet" {
  id = "subnet-0150785e9d0240347"
}

# =========================================================
# UBUNTU 24.04 AMI
# =========================================================

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# =========================================================
# ROUTE TABLE
# =========================================================

resource "aws_route_table" "nestjs_public_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing_igw.id
  }

  tags = {
    Name = "nestjs-public-route-table"
  }
}

# =========================================================
# SECURITY GROUP
# =========================================================

resource "aws_security_group" "nestjs_ec2_security_group" {
  name        = "nestjs-ec2-sg"
  description = "Security group for NestJS EC2 instance"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # SSH
  ingress {
    description = "SSH from authorized IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # NestJS application
  ingress {
    description = "NestJS application"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nestjs-ec2-sg"
  }
}

# =========================================================
# EC2 INSTANCE
# =========================================================

resource "aws_instance" "nestjs_ec2" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.existing_subnet.id
  vpc_security_group_ids      = [aws_security_group.nestjs_ec2_security_group.id]
  associate_public_ip_address = true

  key_name             = var.existing_ssh_key_pair_name
  iam_instance_profile = aws_iam_instance_profile.nestjs_ec2_ssm_profile.name

  tags = {
    Name = "nestjs-ec2"
  }
}

# =========================================================
# IAM ROLE FOR EC2 + SSM
# =========================================================
# IMPORTANT:
# This role belongs to EC2.
# EC2 must trust "ec2.amazonaws.com".
# DO NOT put GitHub OIDC here.

resource "aws_iam_role" "nestjs_ec2_ssm_role" {
  name = "nestjs-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "nestjs-ec2-ssm-role"
  }
}

# =========================================================
# EC2 SSM PERMISSION
# =========================================================

resource "aws_iam_role_policy_attachment" "nestjs_ec2_ssm_policy" {
  role       = aws_iam_role.nestjs_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =========================================================
# EC2 INSTANCE PROFILE
# =========================================================

resource "aws_iam_instance_profile" "nestjs_ec2_ssm_profile" {
  name = "nestjs-ec2-ssm-profile"
  role = aws_iam_role.nestjs_ec2_ssm_role.name
}

# =========================================================
# GITHUB ACTIONS OIDC PROVIDER
# =========================================================
# This allows GitHub Actions to authenticate to AWS
# without storing AWS access keys in GitHub.

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# =========================================================
# IAM ROLE FOR GITHUB ACTIONS
# =========================================================
# THIS role is for GitHub Actions.
#
# Only the new-setup branch of:
# diyagoyal2310/diya-nestjs-crud
#
# can assume this role.

resource "aws_iam_role" "github_actions_deploy_role" {
  name = "github-actions-nestjs-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:diyagoyal2310/diya-nestjs-crud:ref:refs/heads/new-setup"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-nestjs-deploy-role"
  }
}

# =========================================================
# GITHUB ACTIONS DEPLOYMENT PERMISSIONS
# =========================================================
# These permissions allow GitHub Actions to use SSM
# to deploy the application on EC2.

resource "aws_iam_role_policy" "github_actions_deploy_policy" {
  name = "github-actions-nestjs-deploy-policy"

  role = aws_iam_role.github_actions_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]

        Resource = "*"
      }
    ]
  })
}
