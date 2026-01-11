# AWS EC2 Deployment: Bytesec UAT Dhruv

This Terraform module automates the deployment of a high-performance **t3a.medium** EC2 instance in the **Mumbai (ap-south-1)** region. It features a unique "Dual Authentication" toggle, allowing you to choose between standard Password access or SSH Key-based access without modifying the core logic.

## 🚀 Key Features

* **Dynamic Authentication:** Toggle between Password and PEM key via a single variable.
* **Automated Storage:** Configures a **20GB gp3** root volume (customizable).
* **Static Connectivity:** Automatically attaches an **Elastic IP** for a permanent public address.
* **Hardware Audit:** Fetches real-time CPU/RAM specs directly from the AWS API for the output summary.

---

## 🛠 Prerequisites

* Terraform (v1.0+) installed.
* AWS CLI configured with appropriate permissions.
* Existing VPC and Subnet IDs (defined in `variables.tf`).

---

## ⚙️ Configuration Variables

| Variable | Description | Default |
| --- | --- | --- |
| `is_password` | `true`: Password Login / `false`: Generate `.pem` Key | `true` |
| `instance_type` | AWS Instance size (vCPUs/RAM) | `t3a.medium` |
| `hdd_size_gb` | Size of the OS disk | `20` |
| `username` | The OS-level user created on launch | `ubunut` |
| `instance_name` | Resource tag for AWS Console | `bytesec-uat-dhruv` |

---

## 📖 Deployment Steps

### 1. Initialize Project

Download the required providers (AWS, Random, TLS, Local):

```bash
terraform init

```

### 2. Choose Authentication Mode

Decide how you want to log in. You can override the default in your `terraform.tfvars` or via command line:

* **For Password Auth:** Keep `is_password = true`.
* **For SSH Key Auth:** Set `is_password = false`.

### 3. Deploy

```bash
terraform apply

```

### 4. Access Credentials

Because the output contains sensitive data (passwords/private keys), run the following command to view your login details:

```bash
terraform output instance_summary

```

---

## 🔑 Accessing the Instance

### If `is_password = true`

Use the random password provided in the `instance_summary` output:

```bash
ssh <username>@<public_ip>

```

### If `is_password = false`

Terraform will generate a `.pem` file in your local directory. Use it as follows:

```bash
ssh -i <instance_name>-key.pem <username>@<public_ip>

```

---

## ⚠️ Security Notes

* **Local Keys:** If using SSH keys, the `.pem` file is stored locally. **Do not commit this file to version control (Git).**
* **Sudo Access:** The created user has `NOPASSWD:ALL` sudo privileges by default for UAT speed. Adjust the `user_data` script for production hardening.

**Would you like me to add a "Troubleshooting" section to this README to help with common SSH connection issues?**