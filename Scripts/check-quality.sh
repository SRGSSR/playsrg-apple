#!/bin/bash

set -e

echo "... checking Swift code with SwiftLint..."
if [ $# -eq 0 ]; then
  swiftlint --quiet --strict
elif [[ "$1" == "only-changes" ]]; then
  git diff --staged --name-only | grep ".swift$" | xargs -I FILE swiftlint lint --quiet --strict "FILE"
fi
echo "... checking Swift code with SwiftFormat..."
if [ $# -eq 0 ]; then
  swiftformat --lint --quiet . 
elif [[ "$1" == "only-changes" ]]; then
  git diff --staged --name-only | grep ".swift$" | xargs -I FILE swiftformat --lint --quiet "FILE"
fi
echo "... checking Ruby scripts..."
bundle exec rubocop --format quiet
echo "... checking Shell scripts..."
shellcheck Scripts/*.sh hooks/*
echo "... checking YAML files..."
yamllint .*.yml .github .jira
