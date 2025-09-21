# Highly Available WordPress Deployment on AWS

This project deploys a production-ready, highly available WordPress application on AWS using modern cloud-native practices. The solution combines Terraform for Infrastructure as Code (IaC) and Ansible for configuration management and deployment automation.

## ⚡ Deployment Flow Overview

**Important**: Follow this exact order for successful deployment:

1. **Create Secrets** → Use `./scripts/manage-secrets.sh` to create database credentials
2. **Deploy Terraform** → Deploy infrastructure using `terraform apply` or `./scripts/deploy.sh`
3. **Activate Virtual Environment** → Use `source activate-venv.sh` for Python isolation
4. **Install Requirements** → Install dependencies with `pip` and `ansible-galaxy`
5. **Deploy with Ansible** → Deploy WordPress using `./scripts/ansible-deploy.sh`

## 🏗️ Architecture Overview

### Design Principles
- **High Availability**: Multi-AZ deployment
- **Scalability**: Auto-scaling ECS services  
- **Security**: VPC, security groups, secrets management
- **Cost Optimization**: Serverless containers with Fargate
- **Maintainability**: Infrastructure as Code

### Architecture Components

**Network Layer (VPC)**
- Custom VPC (10.0.0.0/16) with public/private subnets
- Internet Gateway and NAT Gateway for controlled access

**Application Layer (ECS)**  
- ECS Cluster with Fargate tasks
- Application Load Balancer with auto-scaling

**Database Layer (RDS)**
- RDS MySQL with Multi-AZ deployment
- AWS Secrets Manager for credential management

**Security & Monitoring**
- IAM roles, Security Groups, CloudWatch

## 📋 Prerequisites

- **AWS CLI**: [Install and configure](https://aws.amazon.com/cli/)
- **Terraform**: Version 1.0+ [Download](https://www.terraform.io/downloads.html)
- **Python**: Version 3.8+ for Ansible
- **AWS Permissions**: VPC, ECS, RDS, Secrets Manager, IAM, CloudWatch



## 🚀 Quick Start Deployment

### 1. Clone and Setup
```bash
git clone <your-repository-url>
cd sre-test
```

### 2. Configure AWS Credentials
```bash
aws configure
# OR
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

### 3. Create Secrets
Create necessary secrets in AWS Secrets Manager before infrastructure deployment:

```bash
# Create database credentials for development environment
./scripts/manage-secrets.sh create -e dev -k db_username -v wordpress_admin
./scripts/manage-secrets.sh create -e dev -k db_password -v "SecurePassword123!"

# Create database credentials for production environment
./scripts/manage-secrets.sh create -e prod -k db_username -v wordpress_admin
./scripts/manage-secrets.sh create -e prod -k db_password -v "ProductionSecurePassword456!"

# Alternatively, create secrets from a JSON file
# Create a secrets.json file with your credentials:
# {
#   "db_username": "wordpress_admin",
#   "db_password": "SecurePassword123!"
# }
# ./scripts/manage-secrets.sh create -e dev -f secrets.json
```

### 4. Deploy Terraform Infrastructure
Deploy the infrastructure using Terraform:

```bash
# Choose your environment configuration
# Available environments:
# - terraform/dev.tfvars (Development - default)
# - terraform/prod.tfvars (Production)
# - terraform/staging.tfvars (Staging - if created)

# Deploy development environment (default)
cd terraform
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# OR deploy production environment
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"

# OR use the automated script (combines all steps)
cd ..
./scripts/deploy.sh dev    # for development
./scripts/deploy.sh prod   # for production
```

### 5. Activate Virtual Environment
Set up and activate the Python virtual environment for Ansible:

```bash
# Quick activation (recommended - creates venv if needed)
source activate-venv.sh

# OR manual setup if first time
python3 -m venv venv
source venv/bin/activate
```

### 6. Install Requirements
Install Python dependencies and Ansible collections:

```bash
# Ensure virtual environment is activated first
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r ansible/requirements.yml
```

### 7. Deploy Using Ansible
Deploy and configure the WordPress application using Ansible:

```bash
# Deploy to development environment (default)
./scripts/ansible-deploy.sh deploy

# Deploy to production with custom image
./scripts/ansible-deploy.sh deploy --env production --image wordpress:6.3

# Deploy to staging with custom task count
./scripts/ansible-deploy.sh deploy --env staging --count 3

# OR use direct Ansible commands
ansible-playbook -i ansible/inventories/development ansible/deploy.yml
ansible-playbook -i ansible/inventories/production ansible/deploy.yml
```

### 8. Access Your WordPress Site
After deployment completes:
```bash
# Get the Load Balancer URL
cd terraform && terraform output alb_dns_name
```

Navigate to the ALB DNS name in your browser to complete WordPress setup.

## 🌍 Environment Management

Supported environments:
- **Development** (`dev.tfvars`) - Small instances, minimal scaling
- **Production** (`prod.tfvars`) - Production-grade instances, full scaling  

### Environment Operations

#### Infrastructure Deployment
```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to production
./scripts/deploy.sh prod

```

#### Cleanup
```bash
# Destroy development environment
./scripts/destroy.sh dev

# Destroy production environment
./scripts/destroy.sh prod
```

#### Manual Terraform Commands
```bash
cd terraform

# Plan deployment
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="prod.tfvars"

# Apply changes
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"

# Destroy infrastructure
terraform destroy -var-file="dev.tfvars"
terraform destroy -var-file="prod.tfvars"
```

## 📁 Project Structure

```
├── terraform/                 # Infrastructure as Code
│   ├── main.tf, variables.tf, versions.tf
│   ├── dev.tfvars, prod.tfvars # Environment configs
│   └── modules/               # VPC, ECS, RDS, ALB modules
├── ansible/                   # Configuration management
│   ├── deploy.yml, monitor.yml, scale.yml, rollback.yml
│   ├── roles/                 # Reusable automation roles
│   ├── inventories/           # Environment inventories
│   └── group_vars/            # Environment variables
├── scripts/                   # Deployment automation
│   ├── deploy.sh, destroy.sh
│   ├── ansible-deploy.sh      # Ansible wrapper
│   └── manage-secrets.sh      # Secrets management
├── requirements.txt           # Python dependencies
└── activate-venv.sh          # Virtual environment setup
```
## 🚀 Ansible Deployment Script

The `ansible-deploy.sh` script provides a user-friendly wrapper around Ansible operations with built-in environment support, validation, and error handling.

**Prerequisites**: Complete these steps in order:
1. ✅ Create secrets with `./scripts/manage-secrets.sh`
2. ✅ Deploy Terraform infrastructure  
3. ✅ Activate venv (`source activate-venv.sh`)
4. ✅ Install requirements

### Key Features
- **Environment Support**: Seamlessly switch between development, staging, and production
- **Built-in Validation**: Checks prerequisites and validates environments
- **User-Friendly Interface**: Clear help messages and interactive confirmations
- **Error Handling**: Comprehensive error checking and meaningful error messages
- **Flexible Configuration**: Override defaults with command-line options

### Using the Ansible Deployment Script
The `ansible-deploy.sh` script provides a convenient wrapper for Ansible operations with full environment support:

```bash
# Deploy to development (default environment)
./scripts/ansible-deploy.sh deploy

# Deploy to production with custom image
./scripts/ansible-deploy.sh deploy --env production --image wordpress:6.3


# Scale service up/down
./scripts/ansible-deploy.sh scale --env production --to 5
./scripts/ansible-deploy.sh scale --env development --to 1

```

#### Direct Ansible Playbook Usage
For advanced users who prefer direct Ansible commands:

```bash
# Deploy new WordPress image version
ansible-playbook -i inventories/production deploy.yml -e wordpress_image=wordpress:6.4

# Scale service up/down
ansible-playbook -i inventories/production scale.yml -e scale_to=5
```

### Monitoring & Logging
- **CloudWatch Logs**: Container logs available at `/ecs/wordpress`
- **ECS Console**: Real-time service and task status
- **ALB Health Checks**: Automatic unhealthy instance removal
- **Auto Scaling Metrics**: CPU and memory-based scaling

### Useful AWS CLI Commands
```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters wordpress-cluster

# List running tasks
aws ecs list-tasks --cluster wordpress-cluster

# View service events
aws ecs describe-services --cluster wordpress-cluster --services wordpress-service

# Check database connectivity
aws rds describe-db-instances --db-instance-identifier $(terraform output -raw rds_endpoint | cut -d. -f1)

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/wordpress"
```

## 🛡️ Security & Monitoring

**Security Features**
- Private subnets for ECS and RDS
- Security groups with restrictive rules
- Secrets Manager for encrypted credentials
- IAM roles with least privilege

**Monitoring**  
- CloudWatch logs at `/ecs/wordpress`
- Auto-scaling based on CPU/memory metrics
- ALB health checks with automatic failover

## 🔄 Backup & Recovery

- **RDS**: Automated daily backups with 7-day retention and point-in-time recovery
- **WordPress Content**: Database backed up via RDS, consider EFS for uploads

## 🧹 Cleanup

```bash
# Destroy specific environment
./scripts/destroy.sh dev
./scripts/destroy.sh prod

# Or manual cleanup
cd terraform
terraform destroy -var-file="dev.tfvars"
```

⚠️ **Warning**: This permanently deletes all resources including the database!

## 🚨 Troubleshooting

### Common Issues

#### Virtual Environment & Ansible Issues

**Error: "Failed to import the required Python library (botocore and boto3)"**
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Verify libraries are installed
python -c "import boto3, botocore; print('AWS libraries installed')"

# If not installed, reinstall dependencies
pip install -r requirements.txt
```

**Error: "ansible: command not found"**
```bash
# Activate virtual environment first
source venv/bin/activate

# Verify Ansible is installed
ansible --version

# If not installed
pip install ansible
```

**Error: "No module named 'ansible.module_utils'"**
```bash
# Reinstall Ansible collections
source venv/bin/activate
ansible-galaxy collection install -r ansible/requirements.yml --force
```

**Wrong Python Interpreter**
```bash
# Check which Python Ansible is using
ansible --version

# Verify ansible.cfg points to correct interpreter
grep ansible_python_interpreter ansible/ansible.cfg

# Should show: ansible_python_interpreter = /path/to/project/venv/bin/python
```

#### ECS Tasks Not Starting
```bash
# Check task definition
aws ecs describe-task-definition --task-definition wordpress

# Check service events
aws ecs describe-services --cluster wordpress-cluster --services wordpress-service
```

#### Database Connection Issues
```bash
# Verify RDS endpoint
terraform output rds_endpoint

# Check secrets
aws secretsmanager get-secret-value --secret-id wordpress-db-credentials
```

#### Load Balancer 503 Errors
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)
```

### Debug Mode
```bash
export TF_LOG=DEBUG
terraform apply

export ANSIBLE_VERBOSITY=3
ansible-playbook ansible/deploy.yml
```

## 🎯 Technology Stack

- **ECS Fargate**: Serverless containers
- **Application Load Balancer**: Layer 7 routing with health checks  
- **RDS MySQL**: Managed database
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management

## 📈 Future Enhancements

- SSL/HTTPS with ACM certificates
- EFS for persistent WordPress uploads
- Multi-region deployment  
- WAF integration
- CloudFront CDN
- CI/CD pipeline automation
