#!/bin/sh

set -e

wally install

# Consider making Packages folder if we haven't required any
# dependencies into this library.
if [ ! -d "Packages" ]; then
    mkdir Packages
fi

# Patch the Wally package link modules to also export Luau type definitions.
rojo sourcemap default.project.json -o sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
