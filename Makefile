#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/playsrg-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=ce99ccc76c77ce34620de985bea5d93e49535be1
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup

.PHONY: setup
setup: rbenv-setup
	@echo "Setting up the project..."
	@echo "Running bundle install..."
	@bundle install > /dev/null
	@echo "Checkout configuration..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@echo "Running pod install..."
	@pod install > /dev/null
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@echo "... done.\n"

.PHONY: rbenv-setup
rbenv-setup:
	@echo "Installing needed ruby version if missing..."
	@Scripts/rbenv-install.sh "./"
	@echo "... done.\n"

.PHONY: check-quality
check-quality: setup
	@echo "Checking quality..."
	@Scripts/check-quality.sh
	@echo "... done.\n"

.PHONY: fix-quality
fix-quality: setup
	@echo "Fixing quality..."
	@Scripts/fix-quality.sh
	@echo "... done.\n"

.PHONY: git-hook-install
git-hook-install:
	@echo "Installing git hooks..."
	@git config core.hooksPath hooks
	@echo "... done.\n"

.PHONY: git-hook-uninstall
git-hook-uninstall:
	@echo "Uninstalling git hooks..."
	@git config --unset core.hooksPath
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo ""
	@echo "   all                 Run setup"
	@echo "   setup               Setup project"
	@echo "   rbenv-setup         Install needed ruby version if missing"
	@echo "   clean               Clean the project and its dependencies"
	@echo ""
	@echo "   check-quality       Run quality checks"
	@echo "   fix-quality         Fix quality automatically (if possible)"
	@echo ""
	@echo "   git-hook-install    Use hooks located in ./hooks"
	@echo "   git-hook-uninstall  Use default hooks located in .git/hooks"
	@echo ""
	@echo "   help                Display this message"
