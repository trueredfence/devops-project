provider "aws" {
  region = "ap-south-1" 
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

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
  tags = {
    Name = "Allow SSH"
  }
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0e35ddab05955cf57" 
  instance_type = "t2.micro"
  key_name      = "bas-key"

  tags = {
    Name = "Terraform-EC2"
  }
}
