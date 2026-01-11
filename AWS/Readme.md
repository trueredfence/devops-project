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

aws ec2 describe-instance-type-offerings `
  --region ap-south-1 `
  --filters "Name=instance-type,Values=t3a.small" `
  --output text        

aws ec2 describe-images `
  --region ap-south-1 `
  --owners amazon `
  --query "Images[*].[ImageId,Name,CreationDate]" `
  --filters "Name=architecture,Values=x86_64" `
  --output text


aws ec2 describe-images `
    --region ap-south-1 `
    --owners 099720109477 `
    --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" `
    "Name=state,Values=available" `
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' `
    --output text


    
```