#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/playsrg-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=b191d9d0e0c46d4066447239060c541a9fae37ae
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup

.PHONY: setup
setup:
	@echo "Setting up the project..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@echo "Running pod install..."
	@pod install > /dev/null
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@echo "... done.\n"

.PHONY: ruby-setup
ruby-setup:
	@echo "Installing needed ruby version if missing..."
	@Scripts/rbenv-install.sh "./"
	@echo "Running bundle install..."
	@bundle install > /dev/null
	@echo "... done.\n"

.PHONY: check-quality
check-quality:
	@echo "Checking quality..."
	@Scripts/check-quality.sh
	@echo "... done.\n"

.PHONY: fix-quality
fix-quality:
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

.PHONY: spm-outdated
spm-outdated:
	@echo "Checking outdated Swift package dependencies..."
	@Scripts/spm-outdated.sh
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo ""
	@echo "   all                 Run setup"
	@echo "   setup               Setup project"
	@echo "   clean               Clean the project and its dependencies"
	@echo ""
	@echo "   ruby-setup          Install needed ruby version with rbenv if missing and run bundle install"
	@echo ""
	@echo "   check-quality       Run quality checks"
	@echo "   fix-quality         Fix quality automatically (if possible)"
	@echo ""
	@echo "   git-hook-install    Use hooks located in ./hooks"
	@echo "   git-hook-uninstall  Use default hooks located in .git/hooks"
	@echo ""
	@echo "   spm-outdated        Run outdated Swift package dependencies check"
	@echo ""
	@echo "   help                Display this message"
