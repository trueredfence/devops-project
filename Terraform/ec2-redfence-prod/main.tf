# ==========================================
# 1. INPUT VARIABLES
# ==========================================
variable "is_password" {
  type        = bool
  default     = false
  description = "If true, uses password auth. If false, generates and uses SSH key."
}

variable "instance_config" {
  type = map(string)
  default = {
    instance_type = "t3a.medium"
    hdd_size_gb   = "20"
    username      = "ubuntu"
    instance_name = "bytesec-redfence-uat"
  }
}

variable "s3_config" {
  type = object({
    bucket_name   = string
    force_destroy = bool
  })
  default = {
    bucket_name   = "bytesec-redfence-uat"
    force_destroy = true
  }
}

variable "database_config" {
  type = object({
    create_db         = bool
    db_name           = string
    username          = string
    instance_class    = string
    allocated_storage = number
  })
  default = {
    create_db         = false
    db_name           = "appdb"
    username          = "dbadmin"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
  }
}

variable "network_config" {
  type = object({
    vpc_id      = string
    subnet_id   = string
    subnet_id_2 = string
    sg_id       = string
  })
  default = {
    vpc_id      = "vpc-03332e8e0eda53a4f"
    subnet_id   = "subnet-00912dccd96cb88b2"
    subnet_id_2 = "subnet-019db5aed3b71f944"
    sg_id       = "sg-09a160fd8b10a17d8"
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

data "aws_caller_identity" "current" {}

# ==========================================
# 3. AUTHENTICATION RESOURCES
# ==========================================
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

resource "random_password" "user_pass" {
  length           = 16
  special          = true
  override_special = "!@#$%"
}

# ==========================================
# 4. EC2 INSTANCE & NETWORKING
# ==========================================
data "aws_ec2_instance_type" "specs" {
  instance_type = var.instance_config["instance_type"]
}

resource "aws_instance" "my_ec2" {
  ami                  = "ami-02521d90e7410d9f0"
  instance_type        = var.instance_config["instance_type"]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  key_name = var.is_password ? null : aws_key_pair.deployer_key[0].key_name

  subnet_id              = var.network_config["subnet_id"]
  vpc_security_group_ids = [var.network_config["sg_id"]]

  root_block_device {
    volume_size = var.instance_config["hdd_size_gb"]
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y && apt-get upgrade -y

              %{if var.is_password}
              useradd -m -s /bin/bash ${var.instance_config["username"]}
              echo "${var.instance_config["username"]}:${random_password.user_pass.result}" | chpasswd
              echo "${var.instance_config["username"]} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${var.instance_config["username"]}
              
              sed -i 's/^Include /#Include /' /etc/ssh/sshd_config
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
              systemctl restart ssh
              %{endif}

              apt-get install -y ca-certificates fail2ban curl gnupg lsb-release git unzip dos2unix
              
              # Kali Terminal Installation
              sudo bash -c "$(curl -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/trueredfence/kali-linux-terminal/refs/heads/main/install.sh)"

              cat <<EOT > /etc/fail2ban/jail.d/sshd.conf
              [sshd]
              enabled = true
              port    = ssh
              filter  = sshd
              logpath = /var/log/auth.log
              maxretry = 5
              bantime  = 1h
              findtime = 10m
              EOT

              systemctl enable fail2ban && systemctl restart fail2ban

              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip && ./aws/install

              mkdir -p /opt/app
              usermod -aG docker ${var.instance_config["username"]}

              cat <<EOT > /etc/docker/daemon.json
              {
                "log-driver": "json-file",
                "log-opts": { "max-size": "10m", "max-file": "3" }
              }
              EOT
              systemctl restart docker 
              EOF

  tags = { Name = var.instance_config["instance_name"] }
}

resource "aws_eip" "my_eip" { domain = "vpc" }

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_ec2.id
  allocation_id = aws_eip.my_eip.id
}

# ==========================================
# 5. VPC GATEWAY ENDPOINT FOR S3
# ==========================================
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

data "aws_route_table" "selected" {
  subnet_id = var.network_config["subnet_id"]
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = var.network_config["vpc_id"]
  service_name = data.aws_vpc_endpoint_service.s3.service_name

  # Automatically add S3 private route to your existing subnet route table
  route_table_ids = [data.aws_route_table.selected.id]

  tags = { Name = "${var.instance_config["instance_name"]}-s3-endpoint" }
}

# ==========================================
# 6. IAM ROLES & DYNAMIC POLICIES
# ==========================================
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "${var.instance_config["instance_name"]}-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "s3_app_backup_policy" {
  name        = "${var.instance_config["instance_name"]}-policy"
  description = "Allow EC2 instance to access S3 bucket and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "S3Access"
          Effect = "Allow"
          Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
          Resource = [
            aws_s3_bucket.static_assets.arn,
            "${aws_s3_bucket.static_assets.arn}/*"
          ]
        }
      ],
      var.database_config["create_db"] ? [
        {
          Sid    = "RDSIAMAuth"
          Effect = "Allow"
          Action = ["rds-db:connect"]
          Resource = [
            "arn:aws:rds-db:ap-south-1:${data.aws_caller_identity.current.account_id}:dbuser:${one(aws_db_instance.postgres[*].resource_id)}/${var.database_config["username"]}"
          ]
        }
      ] : []
    )
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.s3_app_backup_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.instance_config["instance_name"]}-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

# ==========================================
# 7. DATABASE (POSTGRESQL)
# ==========================================
resource "random_password" "db_pass" {
  count            = var.database_config["create_db"] ? 1 : 0
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "postgres" {
  count                               = var.database_config["create_db"] ? 1 : 0
  allocated_storage                   = var.database_config["allocated_storage"]
  engine                              = "postgres"
  engine_version                      = "16.1"
  instance_class                      = var.database_config["instance_class"]
  db_name                             = var.database_config["db_name"]
  username                            = var.database_config["username"]
  password                            = random_password.db_pass[0].result
  parameter_group_name                = "default.postgres16"
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  vpc_security_group_ids              = [aws_security_group.rds_sg[0].id]
  db_subnet_group_name                = aws_db_subnet_group.default[0].name
  iam_database_authentication_enabled = true

  tags = { Name = "${var.instance_config["instance_name"]}-db" }
}

resource "aws_security_group" "rds_sg" {
  count  = var.database_config["create_db"] ? 1 : 0
  name   = "${var.instance_config["instance_name"]}-rds-sg"
  vpc_id = var.network_config["vpc_id"]

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.network_config["sg_id"]]
  }
}

resource "aws_db_subnet_group" "default" {
  count      = var.database_config["create_db"] ? 1 : 0
  name       = "${var.instance_config["instance_name"]}-subnet-group"
  subnet_ids = [var.network_config["subnet_id"], var.network_config["subnet_id_2"]]
}

# ==========================================
# 8. S3 BUCKET
# ==========================================
resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "static_assets" {
  bucket        = "${var.s3_config["bucket_name"]}-${random_id.bucket_id.hex}"
  force_destroy = var.s3_config["force_destroy"]
  tags          = { Name = var.s3_config["bucket_name"] }
}

# ==========================================
# 9. OUTPUTS
# ==========================================
output "instance_summary" {
  sensitive = true
  value = {
    auth_method = var.is_password ? "Password" : "SSH Key"
    public_ip   = aws_eip.my_eip.public_ip
    username    = var.instance_config["username"]
    password    = var.is_password ? random_password.user_pass.result : "N/A (Key Auth)"
    ssh_command = var.is_password ? "ssh ${var.instance_config["username"]}@${aws_eip.my_eip.public_ip}" : "ssh -i ${one(aws_key_pair.deployer_key[*].key_name)}.pem ${var.instance_config["username"]}@${aws_eip.my_eip.public_ip}"

    database = var.database_config["create_db"] ? {
      endpoint = aws_db_instance.postgres[0].endpoint
      username = var.database_config["username"]
      password = random_password.db_pass[0].result
    } : null

    s3_bucket   = aws_s3_bucket.static_assets.id
    s3_endpoint = aws_vpc_endpoint.s3_gateway.id
  }
}
