#!/bin/bash

if ! which swiftformat &> /dev/null; then
    echo "Install swiftformat as described here: https://github.com/nicklockwood/SwiftFormat#command-line-tool"
    exit 1
fi

swiftformat EncoreSwiftUiKit EncoreSwiftUiKitTests

