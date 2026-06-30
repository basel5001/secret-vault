.PHONY: help init plan apply destroy vault-init vault-status rotate backup fmt validate lint dev dev-down

TERRAFORM_DIR := terraform
SHELL := /bin/bash

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==============================================================================
# Terraform
# ==============================================================================
init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Plan Terraform changes
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan

apply: ## Apply Terraform changes
	cd $(TERRAFORM_DIR) && terraform apply tfplan

destroy: ## Destroy all Terraform resources (use with caution)
	cd $(TERRAFORM_DIR) && terraform destroy

fmt: ## Format Terraform files
	terraform fmt -recursive $(TERRAFORM_DIR)

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && terraform validate

lint: ## Run tfsec security scanner
	tfsec $(TERRAFORM_DIR)
	@echo "---"
	shellcheck scripts/*.sh

# ==============================================================================
# Vault Operations
# ==============================================================================
vault-init: ## Initialize Vault and store keys in Secrets Manager
	bash scripts/init-vault.sh

vault-status: ## Check Vault seal status
	vault status

rotate: ## Rotate all dynamic secrets
	bash scripts/rotate-secrets.sh

backup: ## Create Vault snapshot and upload to S3
	bash scripts/backup-vault.sh

# ==============================================================================
# Local Development
# ==============================================================================
dev: ## Start local Vault dev server (Docker)
	docker-compose up -d
	@echo ""
	@echo "Vault UI:    http://localhost:8200/ui"
	@echo "Root Token:  root"
	@echo "VAULT_ADDR:  http://localhost:8200"

dev-down: ## Stop local Vault dev server
	docker-compose down -v
