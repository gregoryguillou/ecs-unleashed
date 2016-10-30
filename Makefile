SHELL = /bin/bash
MAKEFLAGS = "-s"

ifndef ENV
$(error ENV is undefined)
endif

ACCOUNT = oyst
AWS_PROFILE = $(ACCOUNT)-$(ENV)
BOLD_ENV = \033[1m\033[38;5;11m$(ENV)\033[0m
BUCKET_NAME = terraform-$(ENV)-ce171e4827ce8a33
CONFIG_DIR = $(abspath terraform/config/$(ACCOUNT)/$(ENV))
CONFIG_ENV = $(CONFIG_DIR)/env.tfvars
CONFIG_INFRA = $(abspath terraform/config/infra-params.tfvars)
CONFIG_SERVICE = $(CONFIG_DIR)/microservices.tfvars
CONFIG_NEWSERVICE = $(CONFIG_DIR)/microservices.tfvars
CONFIG_STATIC = $(CONFIG_DIR)/statics.tfvars
CONFIG_MONITORING = $(CONFIG_DIR)/monitoring.tfvars
CONFIRM = $(abspath bin/confirm)
S3_CONFIG_PATH = s3://$(BUCKET_NAME)/config/env.tfvars

MODEL_DIR = $(abspath terraform/model)
EXTERNALIZATION_DIR = $(MODEL_DIR)/externalization
INFRA_DIR = $(MODEL_DIR)/infrastructure
MANAGEMENT_DIR = $(MODEL_DIR)/management
REGISTRY_DIR = $(MODEL_DIR)/registry
SERVICE_DIR = $(MODEL_DIR)/microservices
NEWSERVICE_DIR = $(MODEL_DIR)/newservices
STATIC_DIR = $(MODEL_DIR)/static-content
MONITORING_DIR = $(MODEL_DIR)/monitoring
DOCKER_DIR = $(abspath docker)
DOCKER_REGISTRY = 022407599157.dkr.ecr.eu-west-1.amazonaws.com

export AWS_DEFAULT_REGION = eu-west-1
export TF_VAR_account = $(ACCOUNT)
export TF_VAR_shortname = $(ENV)

# allow to override terraform binary
ifndef TERRAFORM
TERRAFORM = terraform
endif

clean:
	@- cd $(FOLDER) && $(TERRAFORM) remote config -disable 2> /dev/null
	@- cd $(FOLDER) && rm -rf terraform.tfstate terraform.tfstate.backup .terraform/terraform.tfstate.backup .terraform/terraform.tfstate

config:
	@$(MAKE) download
	@$(MAKE) FOLDER=$(FOLDER) clean
	@cd $(FOLDER) && $(TERRAFORM) remote config \
		-backend=S3 \
		-backend-config="bucket=$(BUCKET_NAME)" \
		-backend-config="key=tf-state/$(STATE).state" \
		-backend-config="region=$(AWS_DEFAULT_REGION)" \
		-backend-config="profile=$(AWS_PROFILE)"

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
	@cd $(FOLDER) && $(TERRAFORM) get > /dev/null
	@cd $(FOLDER) && $(TERRAFORM) plan -var-file=$(CONFIG_ENV) $(if $(EXTRA_ENV), -var-file=$(EXTRA_ENV),)
	@$(MAKE) STATE=$(STATE) confirm
	@cd $(FOLDER) && $(TERRAFORM) apply -var-file=$(CONFIG_ENV) $(if $(EXTRA_ENV), -var-file=$(EXTRA_ENV),)
	@$(MAKE) FOLDER=$(FOLDER) clean

target:
	@$(MAKE) FOLDER=$(FOLDER) STATE=$(STATE) config
	@cd $(FOLDER) && $(TERRAFORM) get > /dev/null
	@cd $(FOLDER) && $(TERRAFORM) plan -target=$(TARGET) -var-file=$(CONFIG_ENV) $(if $(EXTRA_ENV), -var-file=$(EXTRA_ENV),)
	@$(MAKE) STATE=$(STATE) confirm
	@cd $(FOLDER) && $(TERRAFORM) apply -target=$(TARGET) -var-file=$(CONFIG_ENV) $(if $(EXTRA_ENV), -var-file=$(EXTRA_ENV),)
	@$(MAKE) FOLDER=$(FOLDER) clean

download:
	@$(eval TMP_FILE := $(shell mktemp))
	@aws s3 cp $(S3_CONFIG_PATH) $(TMP_FILE) --profile $(AWS_PROFILE) > /dev/null
	@if test -e $(CONFIG_ENV) && ! diff $(CONFIG_ENV) $(TMP_FILE); then \
		$(CONFIRM) "remote config is different, are you sure you want to continue?"; fi
	@cp $(TMP_FILE) $(CONFIG_ENV)

upload:
	@aws s3 cp $(CONFIG_ENV) $(S3_CONFIG_PATH) --profile $(AWS_PROFILE)

externalization:
	@$(MAKE) FOLDER=$(EXTERNALIZATION_DIR) STATE=$(@) deploy

infrastructure:
ifdef TARGET
	@$(MAKE) FOLDER=$(INFRA_DIR) STATE=$(@) EXTRA_ENV=$(CONFIG_INFRA) TARGET=$(TARGET) target
else
	@$(MAKE) FOLDER=$(INFRA_DIR) STATE=$(@) EXTRA_ENV=$(CONFIG_INFRA) deploy
endif

management:
	@$(MAKE) FOLDER=$(MANAGEMENT_DIR) STATE=$(@) deploy

monitoring:
ifdef TARGET
	@$(MAKE) FOLDER=$(MONITORING_DIR) STATE=$(@) EXTRA_ENV=$(CONFIG_MONITORING) TARGET=$(TARGET) target
else
	@$(MAKE) FOLDER=$(MONITORING_DIR) STATE=$(@) EXTRA_ENV=$(CONFIG_MONITORING) deploy
endif

registry:
ifdef TARGET
	@$(MAKE) FOLDER=$(REGISTRY_DIR) STATE=$(@) TARGET=$(TARGET) target
else
	@$(MAKE) FOLDER=$(REGISTRY_DIR) STATE=$(@) deploy
endif

microservices:
	@$(MAKE) FOLDER=$(SERVICE_DIR) STATE=$(@) config
	@cd $(SERVICE_DIR) && $(TERRAFORM) get > /dev/null
ifdef SERVICE
	@cd $(SERVICE_DIR) && $(TERRAFORM) plan -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_SERVICE) -target=module.$(SERVICE)
	@$(MAKE) STATE=$(SERVICE) confirm
	@cd $(SERVICE_DIR) && $(TERRAFORM) apply -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_SERVICE) -target=module.$(SERVICE)
	@cd $(SERVICE_DIR) && ./reload_pending.sh -e $(ENV) -s $(SERVICE)
else
	@cd $(SERVICE_DIR) && $(TERRAFORM) plan -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_SERVICE)
	@$(MAKE) STATE=$(@) confirm
	@cd $(SERVICE_DIR) && $(TERRAFORM) apply -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_SERVICE)
	@cd $(SERVICE_DIR) && ./reload_pending.sh -e $(ENV)
endif
	@$(MAKE) FOLDER=$(SERVICE_DIR) clean

newservices:
	@$(MAKE) FOLDER=$(NEWSERVICE_DIR) STATE=$(@) config
	@cd $(NEWSERVICE_DIR) && $(TERRAFORM) get > /dev/null
ifdef SERVICE
	@cd $(NEWSERVICE_DIR) && $(TERRAFORM) plan -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_NEWSERVICE) -target=module.$(SERVICE)
	@$(MAKE) STATE=$(SERVICE) confirm
	@cd $(NEWSERVICE_DIR) && $(TERRAFORM) apply -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_NEWSERVICE) -target=module.$(SERVICE)
else
	@cd $(NEWSERVICE_DIR) && $(TERRAFORM) plan -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_NEWSERVICE)
	@$(MAKE) STATE=$(@) confirm
	@cd $(NEWSERVICE_DIR) && $(TERRAFORM) apply -var-file=$(CONFIG_ENV) -var-file=$(CONFIG_NEWSERVICE)
endif
	@$(MAKE) FOLDER=$(NEWSERVICE_DIR) clean

statics:
	@$(MAKE) FOLDER=$(STATIC_DIR) STATE=$(@) EXTRA_ENV=$(CONFIG_STATIC) deploy

docker:
	@aws ecr get-login --profile oyst-staging | sh
ifdef CONTAINER
	@export VERSION=`cat $(DOCKER_DIR)/$(CONTAINER)/version.txt` && \
		cd $(DOCKER_DIR)/$(CONTAINER) && \
		docker build -t $(DOCKER_REGISTRY)/$(CONTAINER):$$VERSION . && \
		docker push $(DOCKER_REGISTRY)/$(CONTAINER)
endif

output:
	@$(MAKE) FOLDER=$(INFRA_DIR) STATE=infrastructure EXTRA_ENV=$(CONFIG_INFRA) config
	@echo && echo "Infrastructure:" && \
		echo "---------------" && \
		cd $(INFRA_DIR) && $(TERRAFORM) output && \
		echo
	@$(MAKE) FOLDER=$(INFRA_DIR) clean
	@$(MAKE) FOLDER=$(SERVICE_DIR) STATE=microservices config
	@echo && echo "Services:" && \
		echo "---------" && \
		cd $(SERVICE_DIR) && $(TERRAFORM) output && \
		echo
	@$(MAKE) FOLDER=$(SERVICE_DIR) clean


.PHONY: 
