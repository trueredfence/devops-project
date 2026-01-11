# DevTech

## Install AWS CLI
1. Download and install AWS CLI
2. Configure AWS CLI

```bash
# Login to AWS SSO
aws configure sso
aws sso login

# Configure AWS CLI
aws configure
# Enter your information when prompted:
# AWS Access Key ID: (Paste your ID)
# AWS Secret Access Key: (Paste your Secret Key)
# Default region name: ap-south-1
# Default output format: json

aws ec2 describe-instances `
    --filters "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].{InstanceID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, PublicIP:PublicIpAddress, PrivateIP:PrivateIpAddress, Status:State.Name}" `
    --output table

aws ec2 describe-addresses `
    --query "Addresses[*].{Name:Tags[?Key=='Name']|[0].Value, IP:PublicIp, AllocationID:AllocationId, Instance:InstanceId}" `
    --output table
    
```