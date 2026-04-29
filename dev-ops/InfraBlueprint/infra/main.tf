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