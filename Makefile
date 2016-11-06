SHELL = /bin/bash
MAKEFLAGS = "-s"

ifndef ACCOUNT
	$(error ACCOUNT is undefined)
endif

ifndef ENV
	$(error ENV is undefined)
endif

DEPLOYMENTS = $(abspath terraform/deployments)
CONFIG_DIR = $(abspath terraform/configurations/$(ACCOUNT)/$(ENV))
CONFIG_ENV = $(CONFIG_DIR)/env.tfvars
ACCOUNTID = $(shell aws sts get-caller-identity --output text --query 'Account' --profile=$(ACCOUNT)-$(ENV))

ifndef REGION
	REGION = $(shell grep region $(CONFIG_ENV) | awk '{print $$3}')
	ifndef REGION
		$(error REGION is undefined)
	endif
endif

export TF_VAR_region = $(REGION)
export TF_VAR_account = $(ACCOUNT)
export TF_VAR_shortname = $(ENV)
export TF_VAR_accountid = $(ACCOUNTID)

BOLD_ENV = \033[1m\033[38;5;11m$(ACCOUNT)($(ENV))\033[0m

TERRAFORM_DIR = $(DEPLOYMENTS)/terraform
INFRASTRUCTURE_DIR = $(DEPLOYMENTS)/infrastructure
SERVICE_DIR = $(DEPLOYMENTS)/services
CONFIRM = $(abspath bin/confirm)

init:
	ifeq ("$(wildcard $(CONFIG_ENV))","")
		$(error environment is already defined)
	else
		@$(MAKE) FOLDER=$(TERRAFORM_DIR) clean
		@$(eval UNIQUEKEY := $(shell openssl rand -hex 8))
		@$(shell mkdir -p $(CONFIG_DIR))
		@$(file > $(CONFIG_ENV),uniquekey = "$(UNIQUEKEY)")
		@$(file >> $(CONFIG_ENV),region = "$(REGION)")
		@$(file >> $(CONFIG_ENV),netprefix = "10.1")
		@$(file >> $(CONFIG_ENV),keypair = "")
		@$(file >> $(CONFIG_ENV),ami-ec2 = "ami-9398d3e0")
		@$(file >> $(CONFIG_ENV),ami-ecs = "ami-e988c39a")
		@- cd $(TERRAFORM_DIR) && terraform get && \
			TF_VAR_uniquekey=$(UNIQUEKEY) terraform apply && \
			terraform remote config \
			-backend=S3 \
			-backend-config="bucket=terraform-$(ENV)-$(UNIQUEKEY)" \
			-backend-config="key=tf-state/seed.state" \
			-backend-config="region=$(REGION)" \
			-backend-config="profile=$(ACCOUNT)-$(ENV)"
		@$(MAKE) FOLDER=$(TERRAFORM_DIR) clean
	endif

clean:
	@- cd $(FOLDER) && terraform remote config -disable 2>/dev/null
	@- cd $(FOLDER) && rm -rf terraform.tfstate terraform.tfstate.backup .terraform

config:
	@$(eval UNIQUEKEY := $(shell grep uniquekey $(CONFIG_ENV) | awk '{print $$3}'))
	@$(MAKE) FOLDER=$(FOLDER) clean
	@cd $(FOLDER) && terraform remote config \
		-backend=S3 \
		-backend-config="bucket=terraform-$(ENV)-$(UNIQUEKEY)" \
		-backend-config="key=tf-state/$(STATE).state" \
		-backend-config="region=$(REGION)" \
		-backend-config="profile=$(ACCOUNT)-$(ENV)"

confirm:
	@echo; echo
	@$(eval CONTINUE := $(shell $(CONFIRM) "You are about to deploy \033[1;32m$(STATE)\033[0m on $(BOLD_ENV) environment, are you sure you want to proceed ?"; echo $$?))
	@$(MAKE) CONTINUE=$(CONTINUE) exit

deploy:
	@$(MAKE) FOLDER=$(FOLDER) STATE=$(STATE) config
	@cd $(FOLDER) && terraform get > /dev/null
	@cd $(FOLDER) && terraform plan -var-file=$(CONFIG_ENV)
	@$(MAKE) STATE=$(STATE) confirm
	@cd $(FOLDER) && terraform apply -var-file=$(CONFIG_ENV)
	@$(MAKE) FOLDER=$(FOLDER) clean

destroy:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=infrastructure config
	@cd $(INFRASTRUCTURE_DIR) && terraform get \
	    && terraform plan -destroy -var-file=$(CONFIG_ENV)
	@$(MAKE) STATE=infrastructure confirm
	@cd $(INFRASTRUCTURE_DIR) && terraform destroy -force -var-file=$(CONFIG_ENV)
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) clean

destroy_services:
	@$(MAKE) FOLDER=$(SERVICE_DIR) STATE=services config
	@cd $(SERVICE_DIR) && terraform get \
	    && terraform plan -destroy -var-file=$(CONFIG_ENV)
	@$(MAKE) STATE=services confirm
	@cd $(SERVICE_DIR) && terraform destroy -force -var-file=$(CONFIG_ENV)
	@$(MAKE) FOLDER=$(SERVICE_DIR) clean

exit:
ifeq ($(CONTINUE),1)
	@$(MAKE) FOLDER=$(FOLDER) clean
	@false
endif

infrastructure:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=$(@) deploy

list:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=infrastructure config
	@echo && echo "Infrastructure:" && \
		echo "---------------" && \
		cd $(INFRASTRUCTURE_DIR) && terraform state list && \
		echo
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) clean

output:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=infrastructure config
	@echo && echo "Infrastructure:" && \
		echo "---------------" && \
		cd $(INFRASTRUCTURE_DIR) && terraform output && \
		echo
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) clean

show:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=infrastructure config
	@cd $(INFRASTRUCTURE_DIR) && terraform state show $(RESOURCE)
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) clean

services:
	@$(MAKE) FOLDER=$(SERVICE_DIR) STATE=$(@) deploy

.PHONY: destroy destroy_services init infrastructure list output show services
