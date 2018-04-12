
REGION ?= eu-west-1
PWD ?= $(shell pwd)
BUILD_DIR ?= out
VENV ?= $(PWD)/.venv
HIPPO_GIT ?= $(PWD)/../ps-hippo/.git

PATH := $(VENV)/bin:$(shell printenv PATH)
SHELL := env PATH=$(PATH) /bin/bash

export AWS_DEFAULT_REGION=$(REGION)
export AWS_REGION=$(REGION)
export PATH

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

## Builds
build: $(BUILD_DIR) build.env-version
	mkdir $(BUILD_DIR)/js
	cp -R src/main/js $(BUILD_DIR)
	mkdir $(BUILD_DIR)/css
	cp -R src/main/css $(BUILD_DIR)
	cp -R src/main/html/* $(BUILD_DIR)

build.env-version:
	git --git-dir=$(HIPPO_GIT) tag --points-at tst \
		| grep v2 | awk '{print "{ \"version\": \""$$1"\" }"}' > $(BUILD_DIR)/tst.json
	git --git-dir=$(HIPPO_GIT) tag --points-at uat \
		| grep v2 | awk '{print "{ \"version\": \""$$1"\" }"}' > $(BUILD_DIR)/uat.json
	git --git-dir=$(HIPPO_GIT) tag --points-at prd \
		| grep v2 | awk '{print "{ \"version\": \""$$1"\" }"}' > $(BUILD_DIR)/prd.json

## Deploy to S3 buckegt
deploy: $(VENV)
	aws s3 sync out/ s3://peek.nhsd.io/

## Clean up
clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

## Sudo for AWS Roles
# Usage:
#   $(make aws-sudo PROFILE=profile-name)
#   $(make aws-sudo PROFILE=profile-with-mfa TOKEN=123789)
aws-sudo: $(VENV)
	@(printenv TOKEN > /dev/null && aws-sudo -m $(TOKEN) $(PROFILE) ) || ( \
		aws-sudo $(PROFILE) \
	)

$(VENV):
	@which virtualenv > /dev/null || (\
		echo "please install virtualenv: http://docs.python-guide.org/en/latest/dev/virtualenvs/" \
		&& exit 1 \
	)
	virtualenv $(VENV)
	$(VENV)/bin/pip install -U "pip<9.0"
	$(VENV)/bin/pip install pyopenssl urllib3[secure] requests[security]
	$(VENV)/bin/pip install -r requirements.txt --ignore-installed
	virtualenv --relocatable $(VENV)
