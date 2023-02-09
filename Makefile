#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/playsrg-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=ce99ccc76c77ce34620de985bea5d93e49535be1
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup

.PHONY: setup
setup:
	@echo "Setting up the project..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@pod install
	@echo "... done.\n"

.PHONY: lint
lint:
	@echo "Linting project..."
	@swiftlint --fix && swiftlint
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@echo "... done.\n"

.PHONY: rbenv
rbenv:
	@echo "Installing needed ruby version if missing..."
	@Scripts/rbenv-install.sh "./"
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all       Build the project"
	@echo "   setup     Setup project"
	@echo "   lint      Lint project and fix issues"
	@echo "   clean     Clean the project and its dependencies"
	@echo "   rbenv     Install needed ruby version if missing"
	@echo "   help      Display this message"
