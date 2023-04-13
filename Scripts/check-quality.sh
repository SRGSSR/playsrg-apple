#!/bin/bash

set -e

echo "... checking Swift code..."
if [ $# -eq 0 ]; then
  swiftlint --quiet --strict
elif [[ "$1" == "only-changes" ]]; then
  git diff --staged --name-only | grep ".swift$" | xargs swiftlint lint --quiet --strict
fi
echo "... checking Ruby scripts..."
bundle exec rubocop --format quiet
echo "... checking Shell scripts..."
shellcheck Scripts/*.sh hooks/*
echo "... checking YAML files..."
yamllint .*.yml .github
