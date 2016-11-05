SHELL = /bin/bash
MAKEFLAGS = "-s"
.DEFAULT_GOAL := build

ifndef ACCOUNT
	$(error ACCOUNT is undefined)
endif

ifndef ENV
	$(error ENV is undefined)
endif

CONFIG_DIR = $(abspath ../../terraform/configurations/$(ACCOUNT)/$(ENV))
CONFIG_ENV = $(CONFIG_DIR)/env.tfvars

ifndef REGION
	REGION = $(shell grep region $(CONFIG_ENV) | awk '{print $$3}')
	ifndef REGION
		$(error REGION is undefined)
	endif
endif

ACCOUNTID = $(shell aws sts get-caller-identity --output text --query 'Account' --profile=$(ACCOUNT)-$(ENV))
REGISTRY = $(ACCOUNTID).dkr.ecr.$(REGION).amazonaws.com

PROJECT = $(shell pwd | sed 's:.*/::')
VERSION = $(shell cat app/version.txt)
DOCKER = docker

clean:
	@$(DOCKER) rmi $(REGISTRY)/$(ENV)-$(PROJECT):$(VERSION)

build:
	$(DOCKER) build -t $(REGISTRY)/$(ENV)-$(PROJECT):$(VERSION) .

install:
	@aws ecr get-login --profile=$(ACCOUNT)-$(ENV) | sh
	@$(DOCKER) push $(REGISTRY)/$(ENV)-$(PROJECT):$(VERSION)

.PHONY: build clean install
