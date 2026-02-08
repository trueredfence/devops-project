terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "startup-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "startup-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "startup-igw"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "startup-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "startup-web-sg"
  description = "Allow HTTP/HTTPS/SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from Cloudflare IPs (In reality, restrict to Cloudflare lists or 0.0.0.0/0)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to Admin IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "startup-db-sg"
  description = "Allow PostgreSQL access from Web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (us-east-1) - Verify AMI ID
  instance_type          = "t3a.small"             # Cost effective
  subnet_id              = aws_subnet.public.id
  key_name               = "startup-key" # Requires key pair to exist
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("${path.module}/userdata.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "startup-app-server"
  }
}

# Elastic IP
resource "aws_eip" "lb" {
  instance = aws_instance.app_server.id
  domain   = "vpc" # Updated from vpc = true
}

# RDS Postgres
resource "aws_db_instance" "default" {
  allocated_storage       = 20
  db_name                 = "startupdb"
  engine                  = "postgres"
  engine_version          = "15" # Check latest supported free tier
  instance_class          = "db.t4g.micro"
  username                = "dbadmin"      # Change in vars
  password                = "ChangeMe123!" # Use Secrets Manager in Prod
  parameter_group_name    = "default.postgres15"
  skip_final_snapshot     = true # For demo only, set false for prod
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  publicly_accessible     = false
  backup_retention_period = 7
}

resource "aws_db_subnet_group" "default" {
  name       = "startup-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.az2.id] # RDS needs 2 AZs

  tags = {
    Name = "My DB subnet group"
  }
}

# Secondary Subnet for RDS (Required)
resource "aws_subnet" "az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "startup-subnet-az2"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "static_assets" {
  bucket = "startup-assets-${random_id.bucket_id.hex}"

  tags = {
    Name = "Startup Assets"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 8
}
