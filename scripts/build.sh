#!/usr/bin/env bash
cp -Rvf static/ app &&
cross-env NODE_ENV=production webpack -p --progress &&
#bash scripts/polymer-build.sh app &&
cd app &&
polymer --version &&
polymer build
cd .. &&
cp -Rvf app/build/unbundled/ docs
