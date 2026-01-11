provider "aws" {
  region = "ap-south-1"
}

# 1. This tells Terraform to find subnets inside your specific VPC
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = ["vpc-03332e8e0eda53a4f"] # Bash VPC ID
  }
}

# 2. Create the Security Group IN that specific VPC
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_new"
  description = "Allow SSH inbound traffic"
  vpc_id      = "vpc-03332e8e0eda53a4f" # <--- THIS IS THE FIX

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Create the Instance in that specific VPC/Subnet
resource "aws_instance" "my_ec2" {
  ami           = "ami-0e35ddab05955cf57"
  instance_type = "t2.micro"
  key_name      = "bas-key"

  # Link the security group created above
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  # Tell it which subnet to sit in (picks the first one found in your VPC)
  subnet_id = data.aws_subnets.available.ids[0]

  tags = {
    Name = "Terraform-EC2"
  }
}
