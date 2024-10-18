#!/bin/sh

set -e

if [ ! -d "Packages" ] || [ ! -d "DevPackages" ]; then
    sh scripts/init.sh
fi

rojo serve build.project.json \
    & rojo sourcemap default.project.json -o sourcemap.json --watch \
    & rojo sourcemap modules/trail/default.project.json -o modules/trail/sourcemap.json --watch \
    & darklua process --config modules/trail/.darklua.json --watch modules/trail/src modules/trail/out \
    & darklua process --config .darklua.json --watch tests/ out/
