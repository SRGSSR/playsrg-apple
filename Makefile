#!/usr/bin/xcrun make -f

CONFIGURATION_FOLDER=Configuration
CONFIGURATION_COMMIT_SHA1=06b8ac4e0a9f7e9fd7f15279c02a74c42b8d0919

CARTHAGE_FOLDER=Carthage
CARTHAGE_RESOLUTION_FLAGS=--new-resolver --no-build
CARTHAGE_BUILD_FLAGS=--platform iOS,tvOS --cache-builds --configuration Release-static

CARTFILE_PRIVATE=Cartfile.private
CARTFILE_RESOLVED=Cartfile.resolved

# Restore Cartfile.private for the specified type
#   Syntax: $(call restore_cartfile_private,type)
define restore_cartfile_private
	@rm -f $(CARTFILE_PRIVATE); \
	if [ -f $(CARTFILE_PRIVATE).common ]; then \
		(cat $(CARTFILE_PRIVATE).common; echo) >> $(CARTFILE_PRIVATE); \
	fi; \
	if [ -f $(CARTFILE_PRIVATE).$(1) ]; then \
		cat $(CARTFILE_PRIVATE).$(1) >> $(CARTFILE_PRIVATE); \
	fi;
endef

# Save Cartfile.resolved for the specified type
#   Syntax: $(call save_cartfile,type)
define save_cartfile_resolved
	@if [ -f $(CARTFILE_RESOLVED) ]; then \
		cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED).$(1); \
	fi;
endef

# Restore Cartfile.resolved for the specified type
#   Syntax: $(call restore_cartfile_resolved,type)
define restore_cartfile_resolved
	@if [ -f $(CARTFILE_RESOLVED).$(1) ]; then \
		cp $(CARTFILE_RESOLVED).$(1) $(CARTFILE_RESOLVED); \
	fi;
endef

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

# Resolving dependencies without building the project

.PHONY: dependencies
dependencies: public.dependencies
	@echo "Updating proprietary dependencies..."
	$(call restore_cartfile_private,proprietary)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,proprietary)
	@echo "... done.\n"

.PHONY: public.dependencies
public.dependencies:
	@echo "Updating public dependencies..."
	$(call restore_cartfile_private,public)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,public)
	@echo "... done.\n"

# Dependency compilation with proprietary dependencies (keep public dependencies in sync)

.PHONY: bootstrap
bootstrap:
	@echo "Building proprietary dependencies..."
	$(call restore_cartfile_private,proprietary)
	$(call restore_cartfile_resolved,proprietary)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,proprietary)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

.PHONY: update
update: setup public.dependencies
	@echo "Updating and building proprietary dependencies..."
	$(call restore_cartfile_private,proprietary)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,proprietary)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

# Public dependency compilation

.PHONY: public.bootstrap
public.bootstrap: public.setup
	@echo "Building public dependencies..."
	$(call restore_cartfile_private,public)
	$(call restore_cartfile_resolved,public)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,public)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

.PHONY: public.update
public.update: public.setup
	@echo "Updating and building public dependencies..."
	$(call restore_cartfile_private,public)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(call save_cartfile_resolved,public)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo "... done.\n"

# Setup

.PHONY: setup
setup:
	@echo "Setting up proprietary project..."

	@if [ ! -d $(CONFIGURATION_FOLDER) ]; then \
		git clone https://github.com/SRGSSR/playsrg-ios-configuration.git $(CONFIGURATION_FOLDER); \
	else \
		echo "A $(CONFIGURATION_FOLDER) folder is already available."; \
	fi;
	$(call checkout_repository,$(CONFIGURATION_FOLDER),$(CONFIGURATION_COMMIT_SHA1))
	
	@ln -fs $(CONFIGURATION_FOLDER)/.env
	@mkdir -p Xcode/Links
	@pushd Xcode/Links > /dev/null; ln -fs ../../$(CONFIGURATION_FOLDER)/Xcode/*.xcconfig .

	@pod install

	@echo "... done.\n"

# Public setup

.PHONY: public.setup
public.setup:
	@echo "Setting up public project..."

	@rm -rf $(CONFIGURATION_FOLDER)
	@rm -rf .env
	@mkdir -p Xcode/Links
	@pushd Xcode/Links > /dev/null; ln -fs ../Public/*.xcconfig .

	@pod install
	
	@echo "... done.\n"

# Cleanup

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@rm -rf $(CARTHAGE_FOLDER)
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets must be used for proprietary builds:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   dependencies                Update dependencies without building them"
	@echo "   bootstrap                   Build previously resolved dependencies"
	@echo "   update                      Update and build dependencies"
	@echo "   setup                       Setup project"
	@echo ""
	@echo "The following targets must be used when building the public source code:"
	@echo "   public.dependencies         Update dependencies without building them"
	@echo "   public.bootstrap            Build previously resolved dependencies"
	@echo "   public.update               Update and build dependencies"
	@echo "   public.setup                Setup project"
	@echo ""
	@echo "The following targets are widely available:"
	@echo "   help                        Display this message"
	@echo "   clean                       Clean the project and its dependencies"
