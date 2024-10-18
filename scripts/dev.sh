#!/bin/sh

set -e

if [ ! -d "Packages" ] || [ ! -d "DevPackages" ]; then
    sh scripts/init.sh
fi

rojo serve test-build.project.json \
    & rojo sourcemap default.project.json -o sourcemap.json --watch \
    & rojo sourcemap test.project.json -o sourcemap.test.json --watch \
    & darklua process --config .darklua.json --watch src/ out/library \
    & darklua process --config .darklua.test.json --watch tests/ out/tests
