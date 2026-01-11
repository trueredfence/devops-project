# DevTech

## Install AWS CLI
1. Download and install AWS CLI
2. Configure AWS CLI

```bash
# Start AWS SSO configuration wizard for profile setup
aws configure sso
# Launch browser to authenticate session via SSO
aws sso login

# Classic configuration for IAM User Access Keys (Access Key ID, Secret Key, Region)
aws configure
# Enter your information when prompted:
# AWS Access Key ID: (Paste your ID)
# AWS Secret Access Key: (Paste your Secret Key)
# Default region name: ap-south-1
# Default output format: json

# List all running instances showing InstanceID, Name Tag, and IP Addresses
aws ec2 describe-instances `
    --filters "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].{InstanceID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, PublicIP:PublicIpAddress, PrivateIP:PrivateIpAddress, Status:State.Name}" `
    --output table

# List all Elastic IP addresses and their current instance associations
aws ec2 describe-addresses `
    --query "Addresses[*].{Name:Tags[?Key=='Name']|[0].Value, IP:PublicIp, AllocationID:AllocationId, Instance:InstanceId}" `
    --output table

# Check if the 't3a.small' instance type is available in the Mumbai region
aws ec2 describe-instance-type-offerings `
  --region ap-south-1 `
  --filters "Name=instance-type,Values=t3a.small" `
  --output text        

# Search for x86_64 Amazon Machine Images (AMIs) owned by Amazon
aws ec2 describe-images `
  --region ap-south-1 `
  --owners amazon `
  --query "Images[*].[ImageId,Name,CreationDate]" `
  --filters "Name=architecture,Values=x86_64" `
  --output text


# Get the latest AMI ID for Ubuntu 24.04 (Noble) provided by Canonical
aws ec2 describe-images `
    --region ap-south-1 `
    --owners 099720109477 `
    --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" `
    "Name=state,Values=available" `
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' `
    --output text


    
```