#!/bin/bash

# ECS Application Deployment Script using Ansible
# This script provides a convenient wrapper for Ansible ECS deployments

set -e

# Directory paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
ANSIBLE_DIR="$BASE_DIR/ansible"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "${BLUE}===== $1 =====${NC}"
}

# Function to print usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy     Deploy new application container image"
    echo "  scale      Scale ECS service"
    echo "  monitor    Monitor ECS service status"
    echo "  rollback   Rollback to previous version"
    echo "  help       Show this help message"
    echo ""
    echo "Global Options:"
    echo "  --env ENV              Environment (development|staging|production, default: development)"
    echo ""
    echo "Deploy Options:"
    echo "  --image IMAGE          Docker image to deploy (default: from environment config)"
    echo "  --count COUNT          Desired task count (default: from environment config)"
    echo ""
    echo "Scale Options:"
    echo "  --to COUNT             Scale to this number of tasks"
    echo ""
    echo "Rollback Options:"
    echo "  --revision REV         Rollback to specific revision (default: previous)"
    echo ""
    echo "Examples:"
    echo "  $0 deploy --env production --image my-app:v1.0"
    echo "  $0 scale --env staging --to 5"
    echo "  $0 monitor --env development"
    echo "  $0 rollback --env production --revision 3"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking prerequisites"
    
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        echo -e "${RED}Error: Ansible is not installed${NC}"
        echo "Install with: pip install ansible"
        exit 1
    fi
    
    if ! command -v aws >/dev/null 2>&1; then
        echo -e "${RED}Error: AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}Error: AWS credentials not configured${NC}"
        exit 1
    fi
    
    # Check if requirements.yml exists and install collections if needed
    if [[ -f "$ANSIBLE_DIR/requirements.yml" ]]; then
        if ! ansible-galaxy collection list | grep -q "amazon.aws"; then
            echo -e "${YELLOW}Installing required Ansible collections...${NC}"
            cd "$ANSIBLE_DIR"
            ansible-galaxy collection install -r requirements.yml
        fi
    fi
    
    echo -e "${GREEN}Prerequisites check passed!${NC}"
}

# Deploy function
deploy() {
    local image=""
    local count=""
    local env="development"
    
    # Parse deploy arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --image)
                image="$2"
                shift 2
                ;;
            --count)
                count="$2"
                shift 2
                ;;
            --env)
                env="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown deploy option: $1${NC}"
                exit 1
                ;;
        esac
    done
    
    print_section "Deploying Application to ECS"
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Environment: $env"
    [[ -n "$image" ]] && echo "  Image Override: $image"
    [[ -n "$count" ]] && echo "  Count Override: $count"
    echo ""
    
    read -p "Continue with deployment? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deployment canceled.${NC}"
        exit 0
    fi
    
    cd "$ANSIBLE_DIR"
    local extra_vars=""
    [[ -n "$image" ]] && extra_vars="$extra_vars container_image=$image"
    [[ -n "$count" ]] && extra_vars="$extra_vars desired_count=$count"
    
    ansible-playbook -i "inventories/$env" deploy.yml --extra-vars "$extra_vars"
}

# Scale function
scale() {
    local to_count=""
    local env="development"
    
    # Parse scale arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --to)
                to_count="$2"
                shift 2
                ;;
            --env)
                env="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown scale option: $1${NC}"
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$to_count" ]]; then
        echo -e "${RED}Error: --to COUNT is required for scaling${NC}"
        exit 1
    fi
    
    print_section "Scaling ECS Service"
    echo -e "${YELLOW}Scaling ECS service in $env environment to $to_count tasks${NC}"
    
    cd "$ANSIBLE_DIR"
    ansible-playbook -i "inventories/$env" scale.yml --extra-vars "scale_to=$to_count"
}

# Monitor function
monitor() {
    local env="development"
    
    # Parse monitor arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env)
                env="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown monitor option: $1${NC}"
                exit 1
                ;;
        esac
    done
    
    print_section "Monitoring ECS Service"
    echo -e "${YELLOW}Monitoring ECS service in $env environment${NC}"
    
    cd "$ANSIBLE_DIR"
    ansible-playbook -i "inventories/$env" monitor.yml
}

# Rollback function
rollback() {
    local revision="previous"
    local env="development"
    
    # Parse rollback arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --revision)
                revision="$2"
                shift 2
                ;;
            --env)
                env="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown rollback option: $1${NC}"
                exit 1
                ;;
        esac
    done
    
    print_section "Rolling Back ECS Service"
    echo -e "${YELLOW}Rolling back ECS service in $env environment to revision: $revision${NC}"
    
    cd "$ANSIBLE_DIR"
    ansible-playbook -i "inventories/$env" rollback.yml --extra-vars "rollback_revision=$revision"
}

# Function to validate environment
validate_environment() {
    local env="$1"
    case $env in
        development|staging|production)
            return 0
            ;;
        *)
            echo -e "${RED}Error: Invalid environment '$env'. Must be one of: development, staging, production${NC}"
            exit 1
            ;;
    esac
}

# Main script logic
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi
    
    command="$1"
    shift
    
    # Check if environment is specified in arguments
    local env_arg=""
    local new_args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env)
                env_arg="$2"
                validate_environment "$env_arg"
                shift 2
                ;;
            *)
                new_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Add environment to arguments if specified
    if [[ -n "$env_arg" ]]; then
        new_args+=("--env" "$env_arg")
    fi
    
    case $command in
        deploy)
            check_prerequisites
            deploy "${new_args[@]}"
            ;;
        scale)
            check_prerequisites
            scale "${new_args[@]}"
            ;;
        monitor)
            check_prerequisites
            monitor "${new_args[@]}"
            ;;
        rollback)
            check_prerequisites
            rollback "${new_args[@]}"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
