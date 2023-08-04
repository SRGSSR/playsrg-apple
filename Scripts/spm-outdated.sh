#!/bin/bash

set -e

if which swift-outdated >/dev/null; then
  swift outdated
else
  echo "warning: swift-outdated not installed, download from https://github.com/kiliankoe/swift-outdated"
fi
