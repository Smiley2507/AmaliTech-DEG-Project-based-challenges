terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment after creating the backend bucket (see README setup instructions)
  # backend "s3" {
  #   bucket = "vela-terraform-state-YOUR_UNIQUE_SUFFIX"
  #   key    = "vela-payments/terraform.tfstate"
  #   region = "eu-north-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# PART 1 — NETWORKING
# ============================================================

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "vela-vpc"
    Project = "vela-payments"
  }
}

# --- Public Subnets (EC2 lives here) ---
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "vela-public-subnet-a"
    Project = "vela-payments"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "vela-public-subnet-b"
    Project = "vela-payments"
  }
}

# --- Private Subnets (RDS lives here — no internet access) ---
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name    = "vela-private-subnet-a"
    Project = "vela-payments"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name    = "vela-private-subnet-b"
    Project = "vela-payments"
  }
}

# --- Internet Gateway (connects the VPC to the internet) ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "vela-igw"
    Project = "vela-payments"
  }
}

# --- Public Route Table (routes internet traffic through the IGW) ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "vela-public-rt"
    Project = "vela-payments"
  }
}

# --- Associate both public subnets with the public route table ---
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# PART 2 — COMPUTE
# ============================================================

# --- Web Security Group ---
# Controls what traffic can reach the EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS and SSH inbound; all outbound"
  vpc_id      = aws_vpc.main.id

  # HTTP — open to the public
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — open to the public
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH — locked to your IP only (passed in as a variable)
  ingress {
    description = "SSH from operator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "vela-web-sg"
    Project = "vela-payments"
  }
}

# --- IAM Role for EC2 ---
# Allows the EC2 instance to assume this role
resource "aws_iam_role" "ec2_role" {
  name = "vela-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "vela-ec2-role"
    Project = "vela-payments"
  }
}

# --- IAM Policy ---
# Grants the EC2 instance read/write access to the S3 bucket only
# No other AWS services or actions are permitted
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "vela-ec2-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })
}

# --- IAM Instance Profile ---
# Wraps the IAM role so it can be attached to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "vela-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name    = "vela-ec2-profile"
    Project = "vela-payments"
  }
}

# --- EC2 Instance ---
resource "aws_instance" "web" {
  # Amazon Linux 2023 AMI for eu-north-1
  # If you use a different region, find the correct AMI ID at:
  # https://console.aws.amazon.com/ec2/v2/home#LaunchInstanceWizard
  ami                    = var.ec2_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name    = "vela-web-server"
    Project = "vela-payments"
  }
}