# ECS Deployment - No direct server access needed
# WordPress runs in ECS containers, managed through AWS APIs
# 
# ECS Cluster: ${cluster_name}
# Database Endpoint: ${db_endpoint}
# Database Name: ${db_name}
# 
# For ECS management, use:
# - AWS CLI: aws ecs list-tasks --cluster ${cluster_name}
# - AWS Console: https://console.aws.amazon.com/ecs/
# - Terraform: terraform apply

[localhost]
127.0.0.1 ansible_connection=local

[localhost:vars]
ecs_cluster=${cluster_name}
db_endpoint=${db_endpoint}
db_name=${db_name}
