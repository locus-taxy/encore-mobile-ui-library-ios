#!/bin/bash

if ! which xcodegen &> /dev/null; then
    echo "Install xcodegen using Homebrew. Run - brew install xcodegen"
    exit 1
fi

xcodegen generate
