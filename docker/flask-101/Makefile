SHELL = /bin/bash
MAKEFLAGS = "-s"
.DEFAULT_GOAL := build

PROJECT = $(shell pwd | sed 's:.*/::') 
VERSION = $(shell cat app/version.txt)
DOCKER = docker

clean:
	@$(DOCKER) rmi $(REGISTRY)/$(PROJECT):$(VERSION)

build:
	$(DOCKER) build -t $(PROJECT):$(VERSION) .

install:
	@aws ecr get-login --profile=oyst-staging | sh
	@$(DOCKER) push $(REGISTRY)/$(PROJECT):$(VERSION)

.PHONY: build clean install
