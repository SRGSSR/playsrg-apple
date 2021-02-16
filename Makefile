#!/usr/bin/xcrun make -f

CONFIGURATION_FOLDER=Configuration
CONFIGURATION_COMMIT_SHA1=0c03c6be83db2bb897182ec96435596623dc049d

CARTHAGE_FOLDER=Carthage
CARTHAGE_RESOLUTION_FLAGS=--new-resolver --no-build
CARTHAGE_BUILD_FLAGS=--platform iOS --cache-builds --configuration Release-static

# Checkout a commit for a repository in the specified directory. Fails if the repository is dirty of if the
# commit does not exist.  
#   Syntax: $(call checkout_repository,directory,commit)
define checkout_repository
	@cd $(1); \
	if [[ `git status --porcelain` ]]; then \
		echo "The repository '$(1)' contains changes. Please commit or discard these changes and retry."; \
		exit 1; \
	elif `git fetch; git checkout -q $(2)`; then \
		exit 0; \
	else \
		echo "The repository '$(1)' could not be switched to commit $(2). Does this commit exist?"; \
		exit 1; \
	fi;
endef

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo "... done.\n"

.PHONY: bootstrap
bootstrap:
	@echo "Building dependencies..."
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	@Scripts/carthage.sh build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

.PHONY: update
update:
	@echo "Updating and building proprietary dependencies..."
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	@Scripts/carthage.sh build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

.PHONY: setup
setup:
	@echo "Setting up the project..."

	@if [ ! -d $(CONFIGURATION_FOLDER) ]; then \
		git clone https://github.com/SRGSSR/playsrg-apple-configuration.git $(CONFIGURATION_FOLDER); \
	else \
		echo "A $(CONFIGURATION_FOLDER) folder is already available."; \
	fi;
	$(call checkout_repository,$(CONFIGURATION_FOLDER),$(CONFIGURATION_COMMIT_SHA1))
	
	@ln -fs $(CONFIGURATION_FOLDER)/.env
	@mkdir -p Xcode/Links
	@pushd Xcode/Links > /dev/null; ln -fs ../../$(CONFIGURATION_FOLDER)/Xcode/*.xcconfig .

	@pod install

	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@rm -rf $(CARTHAGE_FOLDER)
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   bootstrap                   Build previously resolved dependencies"
	@echo "   update                      Update and build dependencies"
	@echo "   setup                       Setup project"
	@echo "   help                        Display this message"
	@echo "   clean                       Clean the project and its dependencies"
