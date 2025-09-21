#!/bin/bash

# AWS Secrets Manager Management Script
# This script helps create, update, or delete any key-value secrets in AWS Secrets Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGION="ap-northeast-1"
ENVIRONMENT="dev"
SECRET_NAME=""  # Will be constructed as {environment}-app-secrets

# Function to display usage
usage() {
    echo -e "${BLUE}AWS Secrets Manager Management Script (Generic Key-Value Secrets)${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create       Create a new secret"
    echo "  update       Update an existing secret"
    echo "  delete       Delete a secret"
    echo "  get          Retrieve secret value"
    echo "  list         List all secrets"
    echo ""
    echo "Options:"
    echo "  -r, --region REGION          AWS region (default: $REGION)"
    echo "  -e, --environment ENV        Environment name (default: $ENVIRONMENT)"
    echo "  -n, --name NAME              Override secret name (default: {env}-app-secrets)"
    echo "  -k, --key KEY                Secret key name"
    echo "  -v, --value VALUE            Secret value"
    echo "  -f, --file FILE              JSON file containing secret key-value pairs"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create -e dev -k api_key -v secret123"
    echo "  $0 update -e staging -k db_password -v newpassword"
    echo "  $0 get -e prod"
    echo "  $0 delete -e dev"
    echo "  $0 create -e dev -f secrets.json"
    echo ""
    echo "Note: This script is designed to work with the Terraform secrets module."
    echo "Secret names follow the pattern: {environment}-app-secrets"
    echo "When adding individual keys, existing keys are preserved and merged."
}

# Function to check if AWS CLI is available
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed or not in PATH${NC}"
        exit 1
    fi
}

# Function to validate environment
validate_environment() {
    local valid_envs=("dev" "staging" "prod")
    local env_valid=false
    
    for valid_env in "${valid_envs[@]}"; do
        if [[ "$ENVIRONMENT" == "$valid_env" ]]; then
            env_valid=true
            break
        fi
    done
    
    if [[ "$env_valid" == false ]]; then
        echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'. Valid environments: ${valid_envs[*]}${NC}"
        exit 1
    fi
}

# Function to construct secret name
construct_secret_name() {
    if [[ -z "$SECRET_NAME" ]]; then
        SECRET_NAME="${ENVIRONMENT}-app-secrets"
    fi
}

# Function to merge secret values safely
merge_secret_values() {
    local existing_secret="$1"
    local new_key="$2"
    local new_value="$3"
    
    # If existing secret is empty or null, create new JSON
    if [[ -z "$existing_secret" || "$existing_secret" == "null" ]]; then
        echo "{\"$new_key\": \"$new_value\"}"
        return
    fi
    
    # Use jq to merge the new key-value pair with existing secret
    local merged_secret
    merged_secret=$(echo "$existing_secret" | jq --arg key "$new_key" --arg value "$new_value" '. + {($key): $value}')
    echo "$merged_secret"
}

# Function to create secret
create_secret() {
    validate_environment
    construct_secret_name
    
    echo -e "${BLUE}Creating/updating secret: $SECRET_NAME (Environment: $ENVIRONMENT)${NC}"
    
    local secret_value
    if [[ -n "$SECRET_FILE" ]]; then
        if [[ ! -f "$SECRET_FILE" ]]; then
            echo -e "${RED}Error: File $SECRET_FILE not found${NC}"
            exit 1
        fi
        secret_value=$(cat "$SECRET_FILE")
    elif [[ -n "$SECRET_KEY" && -n "$SECRET_VALUE" ]]; then
        # Check if secret already exists
        local existing_secret=""
        if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
            echo -e "${YELLOW}Secret $SECRET_NAME already exists. Merging with existing keys...${NC}"
            existing_secret=$(aws secretsmanager get-secret-value \
                --secret-id "$SECRET_NAME" \
                --region "$REGION" \
                --query SecretString \
                --output text 2>/dev/null)
            secret_value=$(merge_secret_values "$existing_secret" "$SECRET_KEY" "$SECRET_VALUE")
        else
            secret_value=$(cat <<EOF
{
  "$SECRET_KEY": "$SECRET_VALUE"
}
EOF
)
        fi
    else
        echo -e "${RED}Error: Either provide key/value or a JSON file${NC}"
        echo -e "${YELLOW}Example: $0 create -e $ENVIRONMENT -k api_key -v secret123${NC}"
        exit 1
    fi
    
    # Create or update the secret
    if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
        aws secretsmanager update-secret \
            --secret-id "$SECRET_NAME" \
            --secret-string "$secret_value" \
            --region "$REGION"
        echo -e "${GREEN}Secret updated successfully with new key!${NC}"
    else
        aws secretsmanager create-secret \
            --name "$SECRET_NAME" \
            --description "Application secrets for environment: $ENVIRONMENT" \
            --secret-string "$secret_value" \
            --region "$REGION" \
            --tags '[{"Key":"Environment","Value":"'$ENVIRONMENT'"},{"Key":"ManagedBy","Value":"terraform"}]'
        echo -e "${GREEN}Secret created successfully!${NC}"
    fi
    
    echo -e "${BLUE}Secret ARN can be referenced in Terraform outputs${NC}"
}

# Function to update secret
update_secret() {
    validate_environment
    construct_secret_name
    
    echo -e "${BLUE}Updating secret: $SECRET_NAME (Environment: $ENVIRONMENT)${NC}"
    
    local secret_value
    if [[ -n "$SECRET_FILE" ]]; then
        if [[ ! -f "$SECRET_FILE" ]]; then
            echo -e "${RED}Error: File $SECRET_FILE not found${NC}"
            exit 1
        fi
        secret_value=$(cat "$SECRET_FILE")
    elif [[ -n "$SECRET_KEY" && -n "$SECRET_VALUE" ]]; then
        # Get existing secret and merge with new key-value
        local existing_secret
        existing_secret=$(aws secretsmanager get-secret-value \
            --secret-id "$SECRET_NAME" \
            --region "$REGION" \
            --query SecretString \
            --output text 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error: Secret $SECRET_NAME not found. Use 'create' command instead.${NC}"
            exit 1
        fi
        
        secret_value=$(merge_secret_values "$existing_secret" "$SECRET_KEY" "$SECRET_VALUE")
        echo -e "${YELLOW}Merging key '$SECRET_KEY' with existing keys...${NC}"
    else
        echo -e "${RED}Error: Either provide key/value or a JSON file${NC}"
        echo -e "${YELLOW}Example: $0 update -e $ENVIRONMENT -k api_key -v newsecret123${NC}"
        exit 1
    fi
    
    aws secretsmanager update-secret \
        --secret-id "$SECRET_NAME" \
        --secret-string "$secret_value" \
        --region "$REGION"
    
    echo -e "${GREEN}Secret updated successfully!${NC}"
    echo -e "${BLUE}Note: Terraform lifecycle rule ignores secret_string changes to prevent drift${NC}"
}

# Function to delete secret
delete_secret() {
    validate_environment
    construct_secret_name
    
    echo -e "${YELLOW}Are you sure you want to delete secret '$SECRET_NAME' in environment '$ENVIRONMENT'? (y/N)${NC}"
    echo -e "${RED}WARNING: This will permanently delete the secret and cannot be undone!${NC}"
    read -r confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        aws secretsmanager delete-secret \
            --secret-id "$SECRET_NAME" \
            --force-delete-without-recovery \
            --region "$REGION"
        
        echo -e "${GREEN}Secret deleted successfully!${NC}"
        echo -e "${YELLOW}Remember to update your Terraform state if this secret was managed by Terraform${NC}"
    else
        echo -e "${BLUE}Operation cancelled.${NC}"
    fi
}

# Function to get secret value
get_secret() {
    validate_environment
    construct_secret_name
    
    echo -e "${BLUE}Retrieving secret: $SECRET_NAME (Environment: $ENVIRONMENT)${NC}"
    
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --region "$REGION" \
        --query SecretString \
        --output text 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Secret value:${NC}"
        echo "$secret_value" | jq .
        echo ""
        echo -e "${BLUE}ECS Task Definition References:${NC}"
        local secret_arn
        secret_arn=$(aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" --query ARN --output text)
        echo -e "For any key: ${secret_arn}:key_name::"
        echo -e "Example: ${secret_arn}:api_key::"
    else
        echo -e "${RED}Error: Secret $SECRET_NAME not found in region $REGION${NC}"
        echo -e "${YELLOW}Available secrets for environment $ENVIRONMENT:${NC}"
        aws secretsmanager list-secrets --region "$REGION" --query "SecretList[?contains(Name, '$ENVIRONMENT-')].Name" --output table
        exit 1
    fi
}

# Function to list secrets
list_secrets() {
    echo -e "${BLUE}Listing all secrets in region $REGION:${NC}"
    
    aws secretsmanager list-secrets \
        --region "$REGION" \
        --query 'SecretList[*].[Name,Description,LastChangedDate]' \
        --output table
}

# Parse command line arguments
COMMAND=""
SECRET_KEY=""
SECRET_VALUE=""
SECRET_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        create|update|delete|get|list)
            COMMAND="$1"
            shift
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--name)
            SECRET_NAME="$2"
            shift 2
            ;;
        -k|--key)
            SECRET_KEY="$2"
            shift 2
            ;;
        -v|--value)
            SECRET_VALUE="$2"
            shift 2
            ;;
        -f|--file)
            SECRET_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check if command is provided
if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}Error: No command specified${NC}"
    usage
    exit 1
fi

# Check AWS CLI availability
check_aws_cli

# Execute command
case $COMMAND in
    create)
        create_secret
        ;;
    update)
        update_secret
        ;;
    delete)
        delete_secret
        ;;
    get)
        get_secret
        ;;
    list)
        list_secrets
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        usage
        exit 1
        ;;
esac
