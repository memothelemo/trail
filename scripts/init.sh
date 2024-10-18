#!/bin/sh

set -e

wally install

# Patch the Wally package link modules to also export Luau type definitions.
rojo sourcemap default.project.json -o sourcemap.json
rojo sourcemap test.project.json -o sourcemap.test.json

# Consider making Packages folder if we haven't required any
# dependencies into this library.
if [ ! -d "Packages" ]; then
    mkdir Packages
fi

wally-package-types --sourcemap sourcemap.json Packages/
wally-package-types --sourcemap sourcemap.test.json DevPackages/
