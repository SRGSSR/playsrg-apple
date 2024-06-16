#!/bin/bash

set -e

swiftlint --fix && swiftlint
swiftformat .
swiftlint
