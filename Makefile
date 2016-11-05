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

ifndef REGION
	REGION = $(shell grep region $(CONFIG_ENV) | awk '{print $$3}')
	ifndef REGION
		$(error REGION is undefined)
	endif
endif

export TF_VAR_region = $(REGION)
export TF_VAR_account = $(ACCOUNT)
export TF_VAR_shortname = $(ENV)

BOLD_ENV = \033[1m\033[38;5;11m$(ACCOUNT)($(ENV))\033[0m

TERRAFORM_DIR = $(DEPLOYMENTS)/terraform
INFRASTRUCTURE_DIR = $(DEPLOYMENTS)/infrastructure
CONFIRM = $(abspath bin/confirm)

init:
	@$(MAKE) FOLDER=$(TERRAFORM_DIR) clean
	@$(eval UNIQUEKEY := $(shell openssl rand -hex 8))
	@$(file > $(CONFIG_ENV),uniquekey = "$(UNIQUEKEY)")
	@$(file >> $(CONFIG_ENV),region = "$(REGION)")
	@- cd $(TERRAFORM_DIR) && terraform get && \
		TF_VAR_uniquekey=$(UNIQUEKEY) terraform apply && \
		terraform remote config \
		-backend=S3 \
		-backend-config="bucket=terraform-$(ENV)-$(UNIQUEKEY)" \
		-backend-config="key=tf-state/seed.state" \
		-backend-config="region=$(REGION)" \
		-backend-config="profile=$(ACCOUNT)-$(ENV)"
	@$(MAKE) FOLDER=$(TERRAFORM) clean

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

exit:
ifeq ($(CONTINUE),1)
	@$(MAKE) FOLDER=$(FOLDER) clean
	@false
endif

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
	@$(MAKE) STATE=$(STATE) confirm
	@cd $(INFRASTRUCTURE_DIR) && terraform destroy -var-file=$(CONFIG_ENV)
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) clean

infrastructure:
	@$(MAKE) FOLDER=$(INFRASTRUCTURE_DIR) STATE=$(@) deploy

.PHONY: init infrastructure
