#!/bin/bash

# Clean up AWS resources provisioned by Terraform
# This script destroys all resources to avoid ongoing charges
# Usage: ./destroy.sh [environment]
# Example: ./destroy.sh dev (uses dev.tfvars)

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

if ! command -v terraform >/dev/null 2>&1; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

# Confirm destruction
echo -e "${RED}WARNING: This will destroy all AWS resources for the '$ENVIRONMENT' environment.${NC}"
echo -e "${RED}This action cannot be undone!${NC}"
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Destruction canceled.${NC}"
    exit 0
fi

# Destroy resources
print_section "Destroying infrastructure"
cd "$TERRAFORM_DIR"
terraform destroy -var-file="$TFVARS_FILE" -auto-approve

# Check if destruction was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Terraform destruction failed${NC}"
    exit 1
fi

echo -e "${GREEN}Infrastructure successfully destroyed!${NC}"
exit 0
