#!/bin/bash

# Deploy Application on AWS using ECS and Terraform
# This script automates the entire deployment process
# Usage: ./deploy.sh [environment]
# Example: ./deploy.sh dev (uses dev.tfvars)

set -e

# Get environment parameter (defaults to 'dev')
ENVIRONMENT=${1:-dev}

# Directory paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
TERRAFORM_DIR="$BASE_DIR/terraform"
TFVARS_FILE="$TERRAFORM_DIR/${ENVIRONMENT}.tfvars"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "${YELLOW}===== $1 =====${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_section "Checking prerequisites"

# Validate environment and tfvars file
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}Error: Environment file '$TFVARS_FILE' not found${NC}"
    echo -e "${YELLOW}Available environments:${NC}"
    ls -1 "$TERRAFORM_DIR"/*.tfvars 2>/dev/null | xargs -n1 basename | sed 's/.tfvars$//' | sed 's/^/  /' || echo "  No .tfvars files found"
    exit 1
fi

echo -e "${GREEN}Using environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}Variables file: $TFVARS_FILE${NC}"

if ! command_exists terraform; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

if ! command_exists aws; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Bootstrap secrets if they don't exist
print_section "Setting up application secrets"
SECRET_NAME="$ENVIRONMENT-app-secrets"
REGION="ap-northeast-1"
if ! aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
    echo -e "${YELLOW}Application secrets not found. Creating initial secret...${NC}"
    echo -e "${BLUE}Please use the manage-secrets.sh script to create your secrets:${NC}"
    echo -e "${YELLOW}  $BASE_DIR/scripts/manage-secrets.sh create -e $ENVIRONMENT -k DB_USERNAME -v wordpress${NC}"
    echo -e "${YELLOW}  $BASE_DIR/scripts/manage-secrets.sh update -e $ENVIRONMENT -k DB_PASSWORD -v your_password${NC}"
    exit 1
else
    echo -e "${GREEN}Application secrets already exist.${NC}"
fi

# Initialize Terraform
print_section "Initializing Terraform"
cd "$TERRAFORM_DIR"
terraform init

# Ask for confirmation
echo -e "${YELLOW}This will provision AWS resources that may incur costs.${NC}"
read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment canceled.${NC}"
    exit 0
fi

# Deploy with Terraform
print_section "Deploying ECS infrastructure with Terraform"
terraform apply -var-file="$TFVARS_FILE" -auto-approve

# Check if deployment was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Terraform deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}Infrastructure deployed successfully!${NC}"

# Wait for ECS service to stabilize
print_section "Waiting for ECS service to stabilize"
echo "Waiting for ECS service to reach desired state..."

# Get cluster and service names from Terraform output
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
REGION=$(terraform output -raw region || echo "ap-northeast-1")

# Wait for service to become stable
aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services my-app-service --region "$REGION"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}ECS service is stable and running!${NC}"
else
    echo -e "${YELLOW}Warning: ECS service may still be starting up. Check AWS console for details.${NC}"
fi

# Get output values
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)

# Print success message
print_section "Deployment Complete"
echo -e "${GREEN}Application ECS deployment successful!${NC}"
echo -e "Access your application at: ${GREEN}http://$ALB_DNS_NAME${NC}"
echo ""
echo -e "${YELLOW}ECS Cluster: ${NC}$CLUSTER_NAME"
echo -e "${YELLOW}Region: ${NC}$REGION"
echo ""
echo -e "To monitor your deployment:"
echo -e "  • AWS Console: https://console.aws.amazon.com/ecs/"
echo -e "  • Check service: aws ecs describe-services --cluster $CLUSTER_NAME --services my-app-service"
echo -e "  • View logs: aws logs tail /ecs/my-app --follow"
echo ""
echo -e "${GREEN}Complete the application setup by visiting the URL above.${NC}"

exit 0
