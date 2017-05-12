#!/usr/bin/env bash
cross-env NODE_ENV=production webpack -p --progress &&
cp -Rvf static/ app &&
#bash scripts/polymer-build.sh app &&
cd app &&
polymer --version &&
polymer build
cp -Rvf app/build/unbundled/ docs
