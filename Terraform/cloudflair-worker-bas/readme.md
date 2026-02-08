setx CLOUDFLARE_API_TOKEN V6LeFMqWAIy9c_TItg0Pun2S4MvPfsb2kkhoh4Jv


terraform init

terraform apply -var-file="secrets.tfvars" -auto-approve

terraform destroy -var-file="secrets.tfvars" -var="temp_subdomain=campaign-alpha" -auto-approve