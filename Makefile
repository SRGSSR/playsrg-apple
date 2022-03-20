#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/playsrg-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=6dff0fb0a71938b9caef168734310f30a39e0b4a
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup

.PHONY: setup
setup:
	@echo "Setting up the project..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@pod install
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all       Build the project"
	@echo "   setup     Setup project"
	@echo "   help      Display this message"
	@echo "   clean     Clean the project and its dependencies"
