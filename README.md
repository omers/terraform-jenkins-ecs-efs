# Terraform module for ECS
1. ECS cluster
2. Jenkins task
3. EFS filesystem

## How to use

Create a terraform.tfvars
```
aws_region = "us-east-1"
aws_key_pair_name = "**********"

availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.10.100.0/24", "10.10.101.0/24"]
private_subnets    = ["10.10.0.0/24", "10.10.1.0/24"]

app_name        = "workflow-manager"
app_environment = "production"
app_port = 8080
source_ip = "1.2.3.4/32"
healthcheck_path = "/login"
cert_arn = "arn:aws:acm:us-east-1:************:certificate/*******-d239-4f1f-b283-*******"
```