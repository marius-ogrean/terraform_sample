# ==============================================================================
# 1. TERRAFORM SETTINGS & PROVIDERS
# ==============================================================================
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configured to automatically isolate states by environment name
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "infrastructure/main.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
    }
  }
}

# ==============================================================================
# 2. LOCALS (WORKSPACE-SPECIFIC CONFIGURATION)
# ==============================================================================
locals {
  # Map config sets to specific workspaces (default fallback included)
  env = lookup(local.workspace_config, terraform.workspace, local.workspace_config["default"])

  workspace_config = {
    default = {
      instance_type = "t3.micro"
      vpc_cidr      = "10.0.0.0/16"
      node_count    = 1
    }
    dev = {
      instance_type = "t3.micro"
      vpc_cidr      = "10.10.0.0/16"
      node_count    = 1
    }
    staging = {
      instance_type = "t3.small"
      vpc_cidr      = "10.20.0.0/16"
      node_count    = 2
    }
    prod = {
      instance_type = "t3.medium"
      vpc_cidr      = "10.30.0.0/16"
      node_count    = 3
    }
  }
}

# ==============================================================================
# 3. GLOBAL VARIABLES
# ==============================================================================
variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources into"
  default     = "us-east-1"
}

# ==============================================================================
# 4. SUBMODULE CALLS (INFRASTRUCTURE COMPONENTS)
# ==============================================================================

# Networking Submodule
module "vpc" {
  source = "./modules/networking"

  environment = terraform.workspace
  vpc_cidr    = local.env.vpc_cidr
}

# Compute/Application Submodule
module "app_cluster" {
  source = "./modules/compute"

  environment   = terraform.workspace
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
  instance_type = local.env.instance_type
  node_count    = local.env.node_count
}

# ==============================================================================
# 5. ROOT OUTPUTS
# ==============================================================================
output "workspace_vpc_id" {
  description = "The ID of the VPC deployed in this workspace"
  value       = module.vpc.vpc_id
}

output "app_endpoint" {
  description = "The endpoint URL for the application cluster"
  value       = module.app_cluster.endpoint
}
