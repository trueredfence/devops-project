# 🌍 Terraform Professional Guide & Cheat Sheet

Terraform is an open-source Infrastructure as Code (IaC) software tool created by HashiCorp. It allows users to define and provision a datacenter infrastructure using a high-level configuration language known as HashiCorp Configuration Language (HCL).

---

## 🚀 1. Installation

### **Windows (Chocolatey)**
```powershell
choco install terraform
```

### **macOS (Homebrew)**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### **Linux (Ubuntu/Debian)**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

---

## ☁️ 2. AWS Setup & Authentication

Before running Terraform, ensure you have the AWS CLI configured with appropriate credentials.

```bash
# Configure AWS CLI
aws configure
```

> [!IMPORTANT]
> Use IAM users with **Least Privilege** principle. For development, `AmazonEC2FullAccess` might be needed, but in production, scope it down.

---

## 🛠️ 3. Core Workflow (Cheat Sheet)

| Command | Description |
| :--- | :--- |
| `terraform init` | Initializes the working directory and downloads providers. |
| `terraform fmt` | Formats configuration files for consistency and readability. |
| `terraform validate` | Validates the syntax and internal consistency of the code. |
| `terraform plan` | Generates an execution plan (dry run). |
| `terraform apply` | Executes the plan to create/modify infrastructure. |
| `terraform destroy` | Removes all infrastructure managed by the configuration. |
| `terraform output` | Displays the output values defined in your code. |

---

## 📁 4. Project Structure

```text
Terraform/
├── ec2/
│   ├── main.tf          # Primary configuration file
│   ├── variables.tf     # Input variables (Best Practice)
│   ├── outputs.tf       # Output values (Best Practice)
│   └── terraform.tfvars # Variable values (Sensitive)
└── readme.md            # This documentation
```

---

## 🛡️ 5. Professional Best Practices

### **1. Remote State Management**
Storing `terraform.tfstate` locally is risky for teams. Use S3 as a backend with DynamoDB for state locking.
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dev/ec2/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}
```

### **2. Use Variables & Modules**
Avoid hardcoding values like VPC IDs or Instance Types. Use `variables.tf` and `terraform.tfvars`.

### **3. Protect Secrets**
Never commit `.tfvars` files containing secrets or your AWS credentials to Git. Add them to `.gitignore`.

```text
# .gitignore snippets
*.tfstate
*.tfstate.backup
.terraform/
terraform.tfvars
```

---

## 📈 6. Quick Start (Example EC2)

1. Navigate to the component directory:
   ```bash
   cd ec2
   ```
2. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform validate
   terraform refresh
   terraform apply -auto-approve
   terraform apply -refresh-only
   terraform output instance_summary
   terraform destroy -auto-approve
   ```