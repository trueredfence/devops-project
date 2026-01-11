# ==========================================
# 1. INPUT VARIABLES
# ==========================================
variable "is_password" {
  type        = bool
  default     = false # Set to TRUE for Password, FALSE for SSH Key
  description = "If true, uses password auth. If false, generates and uses SSH key."
}

variable "instance_config" {
  type = map(string)
  default = {
    ami           = "ami-019715e0d74f695be"
    instance_type = "t3a.small"
    hdd_size_gb   = "10"
    username      = "ubuntu"
    instance_name = "bytesec-main"
  }
}

variable "network_config" {
  type = map(string)
  default = {
    vpc_id    = "vpc-03332e8e0eda53a4f"
    subnet_id = "subnet-00912dccd96cb88b2"
    sg_id     = "sg-0b69e840e37ab9b3f"
  }
}

# ==========================================
# 2. TERRAFORM & PROVIDER CONFIG
# ==========================================
terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    tls    = { source = "hashicorp/tls", version = "~> 4.0" }
    local  = { source = "hashicorp/local", version = "~> 2.0" }
  }
}

provider "aws" { region = "ap-south-1" }

# ==========================================
# 3. CONDITIONAL RESOURCES (Keys)
# ==========================================

# Only generates a key if is_password is FALSE
resource "tls_private_key" "generated_key" {
  count     = var.is_password ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_key" {
  count      = var.is_password ? 0 : 1
  key_name   = "${var.instance_config["instance_name"]}-key"
  public_key = tls_private_key.generated_key[0].public_key_openssh
}

resource "local_file" "ssh_key" {
  count           = var.is_password ? 0 : 1
  filename        = "${path.module}/${aws_key_pair.deployer_key[0].key_name}.pem"
  content         = tls_private_key.generated_key[0].private_key_pem
  file_permission = "0400"
}

# Generate Random Password (Always generated, but only used if is_password is true)
resource "random_password" "user_pass" {
  length           = 16
  special          = true
  override_special = "!@#$%"
}

# ==========================================
# 4. EC2 INSTANCE
# ==========================================
data "aws_ec2_instance_type" "specs" {
  instance_type = var.instance_config["instance_type"]
}

resource "aws_instance" "my_ec2" {
  ami           = var.instance_config["ami"]
  instance_type = var.instance_config["instance_type"]

  # Only attaches a key_name if is_password is FALSE
  key_name = var.is_password ? null : aws_key_pair.deployer_key[0].key_name

  subnet_id              = var.network_config["subnet_id"]
  vpc_security_group_ids = [var.network_config["sg_id"]]

  root_block_device {
    volume_size = var.instance_config["hdd_size_gb"]
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              useradd -m -s /bin/bash ${var.instance_config["username"]}
              echo "${var.instance_config["username"]}:${random_password.user_pass.result}" | chpasswd
              echo "${var.instance_config["username"]} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${var.instance_config["username"]}
              
              # Conditional SSH configuration script
              %{if var.is_password}
              sed -i 's/^Include /#Include /' /etc/ssh/sshd_config
              if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
                  sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
              else
                  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
              fi
              systemctl restart ssh
              %{endif}
              EOF

  tags = { Name = var.instance_config["instance_name"] }
}

resource "aws_eip" "my_eip" { domain = "vpc" }

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_ec2.id
  allocation_id = aws_eip.my_eip.id
}

# ==========================================
# 5. DYNAMIC OUTPUTS
# ==========================================
output "instance_summary" {
  sensitive = true
  value = {
    auth_method = var.is_password ? "Password" : "SSH Key"
    public_ip   = aws_eip.my_eip.public_ip
    username    = var.instance_config["username"]

    # Only show password if it's the chosen auth method
    password = var.is_password ? random_password.user_pass.result : "N/A (Key Auth)"

    # Build SSH command based on auth type
    ssh_command = var.is_password ? "ssh ${var.instance_config["username"]}@${aws_eip.my_eip.public_ip}" : "ssh -i ${aws_key_pair.deployer_key[0].key_name}.pem ${var.instance_config["username"]}@${aws_eip.my_eip.public_ip}"

    hardware_details = {
      vcpus   = data.aws_ec2_instance_type.specs.default_vcpus
      ram_mib = data.aws_ec2_instance_type.specs.memory_size
      storage = "${var.instance_config["hdd_size_gb"]} GB"
    }
  }
}
