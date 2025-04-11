#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/playsrg-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=377719a97b73b7627280720c9d7d2257e2e01cf4
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup

.PHONY: setup
setup:
	@echo "Setting up the project..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@echo "Running pod install..."
	@bundle exec pod install > /dev/null
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
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

.PHONY: generate-translations
generate-translations:
	@echo "Building source translation files..."
	@Scripts/generate-translations.sh
	@echo "... done.\n"

.PHONY: push-translations
push-translations:
	@echo "Pushing translations..."
	@Scripts/crowdin.sh push
	@echo "... done.\n"

.PHONY: pull-translations
pull-translations:
	@echo "Pulling translations..."
	@Scripts/crowdin.sh pull
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

.PHONY: ruby-setup
ruby-setup:
	@echo "Installing needed ruby version if missing..."
	@Scripts/rbenv-install.sh "./"
	@echo "Running bundle install..."
	@bundle install > /dev/null
	@echo "... done.\n"

.PHONY: appstore-status
appstore-status: ruby-setup
	@echo "Running fastlane ios appStoreAppStatus..."
	@bundle exec fastlane ios appStoreAppStatus
	@echo "... done.\n"

.PHONY: appstore-testflight-status
appstore-testflight-status: ruby-setup
	@echo "Running fastlane ios appStoreAppStatus..."
	@bundle exec fastlane ios appStoreTestFlightAppStatus
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo ""
	@echo "   all                        Run setup"
	@echo "   setup                      Setup project"
	@echo "   clean                      Clean the project and its dependencies"
	@echo ""
	@echo "   check-quality              Run quality checks"
	@echo "   fix-quality                Fix quality automatically (if possible)"
	@echo ""
	@echo "   generate-translations      Generate source translation files in Translations folder"
	@echo "   push-translations          Push new translations to Crowdin"
	@echo "   pull-translations          Pull latest translations from Crowdin"
	@echo ""
	@echo "   git-hook-install           Use hooks located in ./hooks"
	@echo "   git-hook-uninstall         Use default hooks located in .git/hooks"
	@echo ""
	@echo "   spm-outdated               Run outdated Swift package dependencies check"
	@echo ""
	@echo "   ruby-setup                 Install needed ruby version with rbenv if missing and run bundle install"
	@echo "   appstore-status            Get AppStore review status"
	@echo "   appstore-testflight-status Get public TestFlight review status"
	@echo ""
	@echo "   help                       Display this message"
